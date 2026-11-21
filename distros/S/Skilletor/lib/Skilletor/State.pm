package Skilletor::State;
# ABSTRACT: Instance state under ~/.claude/skilletor – trust, the sync lock and the records a sync keeps

use Moo;
use Errno ();
use Fcntl ();
use File::Basename ();
use POSIX ();
use Path::Tiny qw( path );
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::Error::LockTimeout;
use Skilletor::Process ();
use Skilletor::FSUtil qw( encode_text is_absolute path_join read_text real_or_resolved write_text );
use Skilletor::JSON qw( js_parse js_stringify js_ordered js_sort_keys js_type );
use namespace::clean;

our $VERSION = '0.008000';

has root => (
  is       => 'ro',
  required => 1,
);

# One run's view of the files (k250): a check, which only reads, or the holder of the sync lock,
# the one writer of the records a sync keeps, parses each file once.
has read_once => (
  is => 'ro',
);

# What a read_once state parsed, by file name. A write drops the file, so the next read parses
# what was written; with_lock empties it as it takes the lock and as it gives it up.
has _view => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { {} },
);

sub BUILD {
  my ( $self ) = @_;
  path( $self->root )->mkpath;
}

sub for_home {
  my ( $class, $home ) = @_;
  return $class->new( root => $class->default_root($home) );
}

sub default_root {
  my ( $class, $home, $claude_config_dir ) = @_;
  return path_join( ( defined $claude_config_dir && length $claude_config_dir ) ? $claude_config_dir : path_join( $home, '.claude' ), 'skilletor' );
}

sub _file { path_join( $_[0]->root, $_[1] ) }

# A state file as an object; anything unreadable or no object reads as an empty one. A read_once
# state hands out the object it parsed first: what a caller changes of it, it writes.
sub _read_json {
  my ( $self, $name ) = @_;
  my $view = $self->_view;
  return $view->{$name} if exists $view->{$name};
  my $value = eval { js_parse( read_text( $self->_file($name) ) ) };
  $value = js_ordered() unless defined $value && js_type($value) eq 'object';
  $view->{$name} = $value if $self->read_once;
  return $value;
}

sub _write_json {
  my ( $self, $name, $value ) = @_;
  delete $self->_view->{$name};
  write_text( $self->_file($name), js_stringify( $value, 2 )."\n" );
}

#### Trust #############################################################

sub trust {
  my ( $self, $name, $backend ) = @_;
  my $trust = $self->_read_json('trust.json');
  $trust->{$name} = js_ordered( kind => $backend->{kind}, address => $backend->{address} );
  $self->_write_json( 'trust.json', $trust );
}

# A user-origin backend is trusted as is; a project-origin one needs an entry for exactly its
# kind and address. An entry written before k66 is the URL alone: it counts for a git or url
# backend at exactly that URL, never for a local one.
sub is_trusted {
  my ( $self, $name, $backend ) = @_;
  return 1 if ( $backend->{origin} // '' ) eq 'user';
  my $trust = $self->_read_json('trust.json');
  return 0 unless exists $trust->{$name};
  my $entry = $trust->{$name};
  my $type  = js_type($entry);
  if ( $type eq 'string' ) {
    return ( $backend->{kind} ne 'local' && $entry eq $backend->{address} ) ? 1 : 0;
  }
  return 0 unless $type eq 'object';
  return ( js_type( $entry->{kind} ) eq 'string' && $entry->{kind} eq $backend->{kind}
      && js_type( $entry->{address} ) eq 'string' && $entry->{address} eq $backend->{address} ) ? 1 : 0;
}

#### Last check (the in-session check's clock) #########################

# Absolute project keys are canonical only on Windows, where an 8.3 alias and the long path
# Git reports must share hook state. POSIX keeps persisted raw and symlink-spelled keys.
sub _project_state_key {
  my ( $key ) = @_;
  return $^O eq 'MSWin32' && is_absolute($key) ? real_or_resolved($key) : $key;
}

sub _now_ms_number { 0 + int( Time::HiRes::time() * 1000 ) }

sub is_due {
  my ( $self, $scope_key, $interval_seconds ) = @_;
  $scope_key = _project_state_key($scope_key);
  my $last = $self->_read_json('last-check.json')->{$scope_key};
  return 1 unless js_type($last) eq 'number';
  return _now_ms_number() - $last >= $interval_seconds * 1000 ? 1 : 0;
}

# Mark a check now, dropping the marks of projects that are gone (k255): a key that is no absolute
# path, or whose directory – the project dir itself, .claude or not – no longer exists. The file is
# written anyway; is_due only reads it, and clear_checked follows a mark.
sub mark_checked {
  my ( $self, $scope_key ) = @_;
  $scope_key = _project_state_key($scope_key);
  my $checks = $self->_read_json('last-check.json');
  _drop_gone_scopes( $checks, $scope_key, sub { $_[0] } );
  $checks->{$scope_key} = _now_ms_number();
  $self->_write_json( 'last-check.json', $checks );
}

sub clear_checked {
  my ( $self, $scope_key ) = @_;
  $scope_key = _project_state_key($scope_key);
  my $checks = $self->_read_json('last-check.json');
  return unless exists $checks->{$scope_key};
  delete $checks->{$scope_key};
  $self->_write_json( 'last-check.json', $checks );
}

# A sync that timed out on the sync lock synced nothing: drop the key's mark, so the next prompt is
# due and its background sync retries (k89). Best effort: never throws.
sub due_again {
  my ( $self, $key ) = @_;
  eval { $self->clear_checked($key); 1 };
  return;
}

#### Unreached drift (spec §14.3, k70) #################################

# The drift ids the last sync of a scope (keyed by its lock path) left in place although every
# source it needed was at hand: `check` does not count them again.
sub unreached {
  my ( $self, $scope_key ) = @_;
  my $ids = $self->_read_json('unreached.json')->{$scope_key};
  return [] unless js_type($ids) eq 'array';
  return [ grep { js_type($_) eq 'string' } @$ids ];
}

# Replace a scope's unreached drift, dropping the records of scopes that are gone (k255, as
# put_sources_read); written only when the file changes.
sub put_unreached {
  my ( $self, $scope_key, $ids ) = @_;
  my $all = $self->_read_json('unreached.json');
  my %seen;
  my $next = [ js_sort_keys( grep { !$seen{$_}++ } @$ids ) ];
  my $dropped = _drop_gone_scopes( $all, $scope_key );
  return if !$dropped && js_stringify( $all->{$scope_key} // [] ) eq js_stringify($next);
  if   (@$next) { $all->{$scope_key} = $next }
  else          { delete $all->{$scope_key} }
  $self->_write_json( 'unreached.json', $all );
}

#### Sources read (spec §14.3, k80) ####################################

sub _source_read {
  my ( $r ) = @_;
  my $out = js_ordered( kind => $r->{kind}, address => $r->{address}, version => $r->{version} );
  $out->{ref}  = $r->{ref}  if defined $r->{ref};
  $out->{path} = $r->{path} if defined $r->{path};
  return $out;
}

# What the last sync of a scope read of each source, and through which backend: `check`
# compares a source with it. A malformed entry counts as none.
sub sources_read {
  my ( $self, $scope_key ) = @_;
  my $record = $self->_read_json('sources-read.json')->{$scope_key};
  my $out = js_ordered();
  return $out unless js_type($record) eq 'object';
  for my $name ( keys %$record ) {
    my $v = $record->{$name};
    next unless js_type($v) eq 'object';
    next unless js_type( $v->{kind} ) eq 'string' && $v->{kind} =~ /\A(?:git|url|local)\z/;
    next unless js_type( $v->{address} ) eq 'string' && js_type( $v->{version} ) eq 'string';
    next if exists $v->{ref} && js_type( $v->{ref} ) ne 'string';
    next if exists $v->{path} && !( js_type( $v->{path} ) eq 'array' && !grep { js_type($_) ne 'string' } @{ $v->{path} } );
    $out->{$name} = _source_read($v);
  }
  return $out;
}

# Drop the keys of scopes that are gone (k254) from a state file keyed by lock path, but $keep's: a
# key that is no absolute path – it names a checkout only from a cwd long changed – or whose lock's
# directory, the scope's .claude, no longer exists. The directory, not the lock: a sync that
# installed nothing leaves no lock, and its record still holds. A file keyed by another path names
# its directory with $dir_of (last-check.json: the project dir itself, k255). True when one was
# dropped. File::Basename's dirname, as Node's, takes either separator on Windows; a key with a NUL
# exists nowhere, silently, as for existsSync.
sub _drop_gone_scopes {
  my ( $all, $keep, $dir_of ) = @_;
  $dir_of //= \&File::Basename::dirname;
  no warnings 'syscalls';
  my @gone = grep { $_ ne $keep && !( is_absolute($_) && -e encode_text( $dir_of->($_) ) ) } keys %$all;
  delete $all->{$_} for @gone;
  return @gone ? 1 : 0;
}

# Replace a scope's record of sources read, dropping the records of scopes that are gone (k254);
# written only when the file changes.
sub put_sources_read {
  my ( $self, $scope_key, $record ) = @_;
  my $all  = $self->_read_json('sources-read.json');
  my $next = js_ordered();
  $next->{$_} = _source_read( $record->{$_} ) for js_sort_keys( keys %$record );
  my $dropped = _drop_gone_scopes( $all, $scope_key );
  return if !$dropped && js_stringify( $all->{$scope_key} // {} ) eq js_stringify($next);
  if   (%$next) { $all->{$scope_key} = $next }
  else          { delete $all->{$scope_key} }
  $self->_write_json( 'sources-read.json', $all );
}

#### Render inputs (spec §14.3, k76) ###################################

sub render_inputs {
  my ( $self, $scope_key ) = @_;
  my $hash = $self->_read_json('render-inputs.json')->{$scope_key};
  return js_type($hash) eq 'string' ? $hash : undef;
}

# Replace a scope's render-inputs hash, or drop it (undef), dropping the records of scopes that are
# gone (k255, as put_sources_read); written only when the file changes.
sub put_render_inputs {
  my ( $self, $scope_key, $hash ) = @_;
  my $all = $self->_read_json('render-inputs.json');
  my $dropped = _drop_gone_scopes( $all, $scope_key );
  if ( defined $hash ) {
    return if !$dropped && exists $all->{$scope_key} && js_type( $all->{$scope_key} ) eq 'string' && $all->{$scope_key} eq $hash;
    $all->{$scope_key} = $hash;
  }
  else {
    return if !$dropped && !exists $all->{$scope_key};
    delete $all->{$scope_key};
  }
  $self->_write_json( 'render-inputs.json', $all );
}

#### Pending report (spec §8) #########################################

# A background sync's hook output for a project, for one of its next prompts to show.
sub put_pending_report {
  my ( $self, $project_key, $report ) = @_;
  $project_key = _project_state_key($project_key);
  my $pending = $self->_read_json('pending-report.json');
  $pending->{$project_key} = $report;
  $self->_write_json( 'pending-report.json', $pending );
}

# A project's pending report, taken out (undef: none); the file is written only when it held one.
sub take_pending_report {
  my ( $self, $project_key ) = @_;
  $project_key = _project_state_key($project_key);
  my $pending = $self->_read_json('pending-report.json');
  return undef unless exists $pending->{$project_key};
  my $report = delete $pending->{$project_key};
  $self->_write_json( 'pending-report.json', $pending );
  return $report;
}

#### Session cwd (spec §8, k149) #######################################

# Sessions `session-cwd.json` keeps (a Hermes gateway runs for days).
use constant SESSION_CWDS => 256;

# A field of a session's entry; undef for an entry that is no object.
sub _entry_field {
  my ( $entry, $field ) = @_;
  return js_type($entry) eq 'object' ? $entry->{$field} : undef;
}

# Where a session's hook last looked: the cwd of its last SessionStart or prompt. A malformed
# entry counts as none.
sub session_cwd {
  my ( $self, $session_id ) = @_;
  my $cwd = _entry_field( $self->_read_json('session-cwd.json')->{$session_id}, 'cwd' );
  return js_type($cwd) eq 'string' ? $cwd : undef;
}

# Record a session's cwd; written only when it changes, keeping the SESSION_CWDS sessions recorded
# last (by `at`, newest first; equal ones in the file's order) – one that lost its entry is looked
# at once more.
sub put_session_cwd {
  my ( $self, $session_id, $cwd ) = @_;
  my $have = $self->session_cwd($session_id);
  return if defined $have && $have eq $cwd;
  my $all = $self->_read_json('session-cwd.json');
  my @others = grep { $_ ne $session_id } keys %$all;
  my @at = map { my $t = _entry_field( $all->{$_}, 'at' ); js_type($t) eq 'number' ? $t : 0 } @others;
  my @newest = map { $others[$_] } sort { $at[$b] <=> $at[$a] || $a <=> $b } 0 .. $#others;
  delete $all->{$_} for @newest[ SESSION_CWDS - 1 .. $#newest ];
  $all->{$session_id} = js_ordered( cwd => $cwd, at => _now_ms_number() );
  $self->_write_json( 'session-cwd.json', $all );
}

#### Hermes home (spec §16.2) ##########################################

sub hermes_home {
  my ( $self ) = @_;
  my $home = $self->_read_json('hermes-home.json')->{home};
  return ( js_type($home) eq 'string' && length $home ) ? $home : undef;
}

# Record the Hermes home, or drop the record (undef); written only when it changes.
sub put_hermes_home {
  my ( $self, $home ) = @_;
  my $have = $self->hermes_home;
  return if ( !defined $have && !defined $home ) || ( defined $have && defined $home && $have eq $home );
  delete $self->_view->{'hermes-home.json'};    # written or removed: read again
  if ( defined $home ) { $self->_write_json( 'hermes-home.json', js_ordered( home => $home ) ) }
  else                 { unlink Skilletor::FSUtil::encode_text( $self->_file('hermes-home.json') ) }
}

#### The sync lock (spec §6.5) #########################################

use constant LOCK_NAME => 'sync.lock';

# What a lock leaves beside it: a broken lock's tombstone, a released lock on its way out.
use constant LEFTOVER => LOCK_NAME.'.';

sub _now_ms { int( Time::HiRes::time() * 1000 ) }

# The stops a process can catch (k251): a harness cancelling a hook – Claude Code sends SIGTERM to
# the hook's process group, SIGKILL 1.5 s later –, Ctrl+C, a closed terminal. By name: _stopped
# looks a number up only when one comes, since a POSIX macro the platform lacks dies wherever it
# is evaluated – Windows' POSIX has no SIGHUP, and loading this module there must not die (k261).
use constant STOPS => qw( TERM INT HUP );

# The release of each sync lock this process takes or holds, by token, with the pid that took it: a
# child forked under the lock – the heartbeat, a spawn before its exec – holds none.
my %held;

# Run $code holding `sync.lock/`, the one mutex over the locks, the target dirs and the source
# cache – shared with the reference, which takes the same directory the same way: mkdir, then
# `owner.json` created exclusively; a holder refreshes the record's mtime; a record not
# refreshed for the stale age – or for two refreshes when its pid on this host is gone – is a
# dead run's, an owner-less dir older than the grace time one that died before writing it. A stop
# the process can catch releases the lock before it ends the process (k251).
sub with_lock {
  my ( $self, $code, %opts ) = @_;
  my $timeout_ms = $opts{timeout_ms} // 5_000;
  my $stale_ms   = $opts{stale_ms}   // 300_000;
  my $refresh_ms = $opts{refresh_ms} // ( $stale_ms / 3 < 10_000 ? int( $stale_ms / 3 ) : 10_000 );
  $refresh_ms = 1 if $refresh_ms < 1;
  my $grace_ms = $opts{grace_ms} // 2_000;
  my $poll_ms  = $opts{poll_ms}  // 25;
  my $win32    = $opts{win32}    // $^O eq 'MSWin32';
  my $lock_dir = $self->_file(LOCK_NAME);
  my $owner    = path_join( $lock_dir, 'owner.json' );
  my $token    = join '', map { sprintf '%02x', int rand 256 } 1 .. 8;
  my $deadline = _now_ms() + $timeout_ms;

  # While this process takes or holds the lock, a stop that would end it – no handler of the
  # program's own, not ignored; not on Windows, where a process is ended without a signal it can
  # catch – gives every lock it holds up first (the reference's releaseOnStop). In place before
  # the owner record is written, so a stop that comes once it is finds the handler; until then,
  # the release gives nothing up – the token check. A lock taken inside another finds the outer
  # one's handlers and adds none. A stop can never release a lock it was only waiting for, nor a
  # SIGKILL any: the next run breaks a lock a dead owner left (_dead_owner).
  local $held{$token} = [ $$, sub { $self->_release( $lock_dir, $owner, $token ) } ];
  my @stops = $^O eq 'MSWin32' ? () : grep { ( $SIG{$_} // '' ) =~ /\A(?:DEFAULT)?\z/ } STOPS;
  local @SIG{@stops} = map { my $name = $_; sub { _stopped($name) } } @stops;

  for ( ;; ) {
    last if $self->_acquire( $lock_dir, $owner, $token, $refresh_ms );
    if ( my $stale = $self->_judge( $lock_dir, $owner, $stale_ms, $grace_ms ) ) {
      next if $self->_break_lock( $lock_dir, $owner, $stale );
    }
    Skilletor::Error::LockTimeout->throw( 'timed out acquiring sync lock at '.$lock_dir ) if _now_ms() >= $deadline;
    Time::HiRes::sleep( $poll_ms / 1000 );
  }

  %{ $self->_view } = ();    # what was read before the lock is not what holds under it
  my $heartbeat = $self->_heartbeat( $owner, $refresh_ms, $win32 );
  my $want = wantarray;
  my @result;
  my $ok = eval {
    local $Skilletor::Process::ON_WAIT = $heartbeat if ref $heartbeat eq 'CODE';
    $self->_sweep_leftovers($stale_ms);
    if    ($want)         { @result = $code->() }
    elsif ( defined $want ) { $result[0] = $code->() }
    else                  { $code->() }
    1;
  };
  my $err = $@;
  $self->_stop_heartbeat($heartbeat);
  $self->_release( $lock_dir, $owner, $token );
  %{ $self->_view } = ();    # nor what was read under it once another run may write
  die $err unless $ok;
  return $want ? @result : $result[0];
}

# A stop while this process takes or holds a lock: every lock it holds given up, then the end the
# signal would have brought – by the signal itself, its default action back and Perl's block of it
# while its handler runs lifted; by its conventional status should that not end the process, which
# must not run on without its lock.
sub _stopped {
  my ($name) = @_;
  $_->[0] == $$ and $_->[1]->() for values %held;
  %held = ();
  my $number = POSIX->can( 'SIG'.$name )->();
  $SIG{$name} = 'DEFAULT';
  kill $name, $$;
  POSIX::sigprocmask( POSIX::SIG_UNBLOCK(), POSIX::SigSet->new($number) );
  POSIX::_exit( 128 + $number );
}

sub _acquire {
  my ( $self, $lock_dir, $owner, $token, $refresh_ms ) = @_;
  unless ( mkdir $lock_dir ) {
    return 0 if $!{EEXIST};
    die 'mkdir '.$lock_dir.': '.$!."\n";
  }
  my $record = js_ordered( pid => 0 + $$, host => Sys::Hostname::hostname(), token => $token, at => _now_ms(), refreshMs => 0 + $refresh_ms );
  my $fh;
  unless ( sysopen $fh, $owner, Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL() ) {
    return 0 if $!{EEXIST} || $!{ENOENT};
    my $why = "$!";
    unlink $owner;
    rmdir $lock_dir;
    die 'open '.$owner.': '.$why."\n";
  }
  binmode $fh;
  print {$fh} Skilletor::FSUtil::encode_text( js_stringify($record) );
  close $fh;
  _touch($owner);
  return 1;
}

# Is the lock stale? What the waiter saw of it when it is, else undef.
sub _judge {
  my ( $self, $lock_dir, $owner, $stale_ms, $grace_ms ) = @_;
  my @st = Time::HiRes::stat($owner);
  unless (@st) {
    my @dir = Time::HiRes::stat($lock_dir) or return undef;    # released meanwhile
    return undef if _now_ms() - $dir[9] * 1000 <= $grace_ms;
    return { ownerless => 1, ino => $dir[1], mtime_ms => $dir[9] * 1000 };
  }
  my $age = _now_ms() - $st[9] * 1000;
  return undef if $age <= $stale_ms && !$self->_dead_owner( $owner, $age );
  return { ownerless => 0, ino => $st[1], mtime_ms => $st[9] * 1000 };
}

# Did the lock's owner die? Only for a record of this host whose pid is gone and that missed two
# of its own refreshes.
sub _dead_owner {
  my ( $self, $owner, $age ) = @_;
  my $record = eval { js_parse( read_text($owner) ) };
  return 0 unless defined $record && js_type($record) eq 'object';
  my ( $pid, $host, $refresh ) = @{$record}{qw( pid host refreshMs )};
  return 0 unless js_type($host) eq 'string' && $host eq Sys::Hostname::hostname();
  return 0 unless js_type($pid) eq 'number' && $pid == int($pid) && $pid > 0;
  return 0 unless js_type($refresh) eq 'number' && $refresh > 0 && $age > 2 * $refresh;
  return 0 if kill 0, $pid;
  return $!{ESRCH} ? 1 : 0;    # EPERM: alive, another user's
}

# Break a lock judged stale; true when it is gone, so taking it is worth a try at once.
sub _break_lock {
  my ( $self, $lock_dir, $owner, $stale ) = @_;
  if ( $stale->{ownerless} ) {
    return 1 if rmdir $lock_dir;
    return 1 if $!{ENOENT};
    return 0 if -e $owner;    # its run wrote the record meanwhile: live
  }
  my $tomb = $self->_file( LEFTOVER.'broken-'.$stale->{ino}.'-'.int( $stale->{mtime_ms} ) );
  _touch($lock_dir);
  return 1 if rename $lock_dir, $tomb;
  return 1 if $!{ENOENT};
  return 0 if $!{ENOTEMPTY} || $!{EEXIST};    # another waiter broke it
  return 0 if $^O eq 'MSWin32' && $!{EACCES};
  die 'rename '.$lock_dir.': '.$!."\n";
}

# Give the lock up – only this run's own; renamed away first, so no waiter sees it half removed.
sub _release {
  my ( $self, $lock_dir, $owner, $token ) = @_;
  my $record = eval { js_parse( read_text($owner) ) };
  return unless defined $record && js_type($record) eq 'object' && ( $record->{token} // '' ) eq $token;
  my $gone = $self->_file( LEFTOVER.'released-'.$token );
  rename $lock_dir, $gone or return;
  eval { path($gone)->remove_tree( { safe => 0 } ) };
}

# Remove what earlier locks left beside `sync.lock/` once older than the stale age.
sub _sweep_leftovers {
  my ( $self, $stale_ms ) = @_;
  opendir( my $dh, $self->root ) or return;
  my @names = grep { index( $_, LEFTOVER ) == 0 } readdir $dh;
  closedir $dh;
  for my $name (@names) {
    my $p = $self->_file($name);
    my @st = Time::HiRes::lstat($p) or next;
    next unless _now_ms() - $st[9] * 1000 > $stale_ms;
    if   ( -l $p || !-d $p ) { unlink $p }
    else                     { eval { path($p)->remove_tree( { safe => 0 } ) } }
  }
}

# Stamp a path's times with now. Time::HiRes has no utime on Windows (it dies there): the core's,
# which takes now from the system when given no times.
sub _touch {
  my ( $path, $hires ) = @_;
  return utime undef, undef, $path unless $hires // Time::HiRes::d_hires_utime();
  my $now = Time::HiRes::time();
  Time::HiRes::utime( $now, $now, $path );
}

# The refreshes: Perl runs a resolve synchronously, so a child process stamps the owner record
# while the holder works, and stops when told or when the holder is gone. Windows has no fork to
# spare – Perl emulates one, as threads, with a clone of the interpreter whose end runs every
# object's DESTROY once more – so there the holder stamps the record itself, at most once a
# refresh, each time it waits on a program: a code ref for Skilletor::Process's ON_WAIT, which
# the caller installs while its code runs (a resolve's git runs; not an HTTP download).
sub _heartbeat {
  my ( $self, $owner, $refresh_ms, $win32 ) = @_;
  return _wait_tick( $owner, $refresh_ms ) if $win32;
  my $parent = $$;
  my $pid = fork;
  return undef unless defined $pid;
  return $pid if $pid;
  local $SIG{TERM} = sub { POSIX::_exit(0) };
  for ( ;; ) {
    Time::HiRes::sleep( $refresh_ms / 1000 );
    last unless getppid() == $parent && -e $owner;    # no refresh once the holder is gone (k251)
    _touch($owner);
  }
  POSIX::_exit(0);
}

sub _wait_tick {
  my ( $owner, $refresh_ms ) = @_;
  my $outer = $Skilletor::Process::ON_WAIT;    # a lock held inside another's: refresh that one too
  my $last  = Time::HiRes::time();
  return sub {
    my $now = Time::HiRes::time();
    if ( ( $now - $last ) * 1000 >= $refresh_ms ) {
      $last = $now;
      _touch($owner);
    }
    $outer->() if $outer;
  };
}

sub _stop_heartbeat {
  my ( $self, $pid ) = @_;
  return if !$pid || ref $pid;    # none, or the Windows tick (gone with the code's scope)
  kill 'TERM', $pid;
  waitpid $pid, 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::State - Instance state under ~/.claude/skilletor – trust, the sync lock and the records a sync keeps

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::State;

  my $state = Skilletor::State->for_home( $ENV{HOME} );     # ~/.claude/skilletor
  $state->trust( team => { kind => 'git', address => 'https://example.com/team/skills' } );

  my $ok = $state->is_trusted( team => { kind => 'git', address => '…', origin => 'project' } );

=head1 DESCRIPTION

The reference's C<state.ts>: trust (spec §4.3), the sync lock (spec §6.5) and
the records a sync keeps for C<check> (spec §14.3). Both implementations read
and write the same files, the same bytes: entries keep their order, a new key
is appended, a file is written only when its content changes, and an
unreadable file counts as empty.

=over 4

=item * C<trust.json>: a source only a project config declares is not fetched
until the user trusts it – name, backend kind and address.

=item * C<unreached.json>, C<sources-read.json>, C<render-inputs.json>: per
scope, keyed by its lock path – the drift the last sync left in place with
every source at hand (k70), what it read of each source and through which
backend (k80), the hash of what it rendered with (k76). L<Skilletor::Engine>
writes and reads them.

=item * C<last-check.json>: when the in-session check last ran per key.

=item * C<pending-report.json>: per project, the hook output a background sync
left for one of its next prompts to show.

=item * C<session-cwd.json>: per session id, the cwd its hook last looked at
and when (C<{ cwd, at }>), for the 256 sessions recorded last.

=item * C<hermes-home.json>: the Hermes home the user scope was synced under
(C<{ home }>), while Hermes is a target and the home is not Hermes' default.

=back

=head2 root

The state directory; created when the object is.

=head2 read_once

True: the object parses each file once and hands out that object from then on
(k250) – one run's view, for a C<check>, which only reads, and for the holder
of the sync lock, the one writer of the records a sync keeps. A write, or the
removal of F<hermes-home.json>, drops the file from the view, so the next read
parses what was written; L</with_lock> empties the view as it takes the lock
and as it gives it up. Off by default: a hook's records (F<last-check.json>,
F<pending-report.json>, F<session-cwd.json>) are written outside the lock, and
each read sees what another run wrote.

=head2 for_home

  Skilletor::State->for_home($home);

=head2 default_root

C<< <home>/.claude/skilletor >>.

=head2 trust

  $state->trust( $name, { kind => 'git', address => $url } );

Replaces an earlier entry of the name.

=head2 is_trusted

  $state->is_trusted( $name, { kind => ..., address => ..., origin => 'user' | 'project' } );

=head2 unreached

  my $ids = $state->unreached($lock_path);   # [ 'missing:skills/x@shared', ... ]

=head2 put_unreached

  $state->put_unreached( $lock_path, \@ids );   # sorted, deduplicated; none drops the key

It drops the records of scopes that are gone, as L</put_sources_read> does
(k255).

=head2 sources_read

  my $read = $state->sources_read($lock_path);
  # { shared => { kind, address, version, ref?, path? } } – malformed entries left out

=head2 put_sources_read

  $state->put_sources_read( $lock_path, \%read );   # names sorted; none drops the key

It drops the records of scopes that are gone, too: a key that is no absolute
path, or whose lock's directory no longer exists (k254). The scope written
stays, and so does one whose directory holds no lock.

=head2 render_inputs

  my $hash = $state->render_inputs($lock_path);   # 'sha256:…' or undef

=head2 put_render_inputs

  $state->put_render_inputs( $lock_path, $hash );   # undef drops it

It drops the records of scopes that are gone, as L</put_sources_read> does
(k255).

=head2 is_due

  $state->is_due( $key, $interval_seconds );

True when no check was marked for the key, or the interval has passed.

=head2 mark_checked

  $state->mark_checked($key);   # the project dir; is_due is false for the interval

It drops the marks of projects that are gone, too: a key that is no absolute
path, or whose directory itself no longer exists (k255) – a project without
F<.claude> keeps its mark. The key marked stays. L</is_due> and
L</clear_checked> drop nothing.

=head2 clear_checked

  $state->clear_checked($key);   # the next is_due is true; nothing written for a key not marked

=head2 due_again

  $state->due_again($key);

L</clear_checked>, best effort: a sync that timed out on the sync lock synced
nothing, so the next prompt is due and retries. Never throws.

=head2 put_pending_report

  $state->put_pending_report( $project_dir, { systemMessage => '…' } );

=head2 take_pending_report

  my $output = $state->take_pending_report($project_dir);   # undef: none

Returns the project's pending report and removes it from the file.

=head2 session_cwd

  my $cwd = $state->session_cwd($session_id);   # undef: none recorded

=head2 put_session_cwd

  $state->put_session_cwd( $session_id, $cwd );

Records the session's cwd with the time in ms; writes nothing when it is the
recorded one. Keeps the 256 sessions recorded last: the others are dropped,
oldest first.

=head2 hermes_home

=head2 put_hermes_home

  my $home = $state->hermes_home;                    # undef: none recorded
  $state->put_hermes_home('/home/me/hermes-b');      # record it
  $state->put_hermes_home(undef);                    # drop the record

The Hermes home the user scope's C<hermes:> entries were synced under (spec
§16.2). A record that is no non-empty string is none. The file is written, or
removed, only when the record changes.

=head2 with_lock

  my $result = $state->with_lock( sub { ... }, timeout_ms => 5000 );

Runs the code holding C<< <root>/sync.lock/ >>, the mutex the reference takes
around every resolve, sync and read of the source cache – the same directory,
taken the same way, so the two implementations exclude each other. It waits
for another holder up to C<timeout_ms> (default 5000), breaking a lock a dead
run left (no refresh for C<stale_ms>, default 300000; an owner-less directory
after C<grace_ms>, default 2000), then throws
L<Skilletor::Error::LockTimeout>. While the code runs, a forked child refreshes
the owner record every C<refresh_ms> (default 10000). On Windows, which has no
fork to spare, the holder refreshes it itself, at most every C<refresh_ms>,
each time it waits on a program through L<Skilletor::Process> – a resolve's git
runs, not an HTTP download; C<< win32 => 1 >> takes this way on any system,
for a test. The lock is released however the code ends; its result (in the
caller's context) is returned and its exception rethrown. A L</read_once>
object reads every file afresh under the lock, and once more after it.

A stop the process can catch while it takes or holds the lock – C<SIGTERM>,
C<SIGINT>, C<SIGHUP>, each where it would end the process: no handler of the
program's own, not ignored – releases every lock the process holds, then ends
it by that signal (k251). Not on Windows, where a process is ended without a
signal it can catch. A C<SIGKILL> leaves the lock: the next run breaks it once
its record, of this host and a pid that is gone, missed two refreshes.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
