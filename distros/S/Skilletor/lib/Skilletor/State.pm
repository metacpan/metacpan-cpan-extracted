package Skilletor::State;
# ABSTRACT: Instance state under ~/.claude/skilletor – trust, the sync lock and the records a sync keeps

use Moo;
use Errno ();
use Fcntl ();
use POSIX ();
use Path::Tiny qw( path );
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::Error::LockTimeout;
use Skilletor::FSUtil qw( read_text write_text path_join );
use Skilletor::JSON qw( js_parse js_stringify js_ordered js_sort_keys js_type );
use namespace::clean;

our $VERSION = '0.001';

has root => (
  is       => 'ro',
  required => 1,
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

# A state file as an object; anything unreadable or no object reads as an empty one.
sub _read_json {
  my ( $self, $name ) = @_;
  my $value = eval { js_parse( read_text( $self->_file($name) ) ) };
  return ( defined $value && js_type($value) eq 'object' ) ? $value : js_ordered();
}

sub _write_json {
  my ( $self, $name, $value ) = @_;
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

sub _now_ms_number { 0 + int( Time::HiRes::time() * 1000 ) }

sub is_due {
  my ( $self, $scope_key, $interval_seconds ) = @_;
  my $last = $self->_read_json('last-check.json')->{$scope_key};
  return 1 unless js_type($last) eq 'number';
  return _now_ms_number() - $last >= $interval_seconds * 1000 ? 1 : 0;
}

sub mark_checked {
  my ( $self, $scope_key ) = @_;
  my $checks = $self->_read_json('last-check.json');
  $checks->{$scope_key} = _now_ms_number();
  $self->_write_json( 'last-check.json', $checks );
}

sub clear_checked {
  my ( $self, $scope_key ) = @_;
  my $checks = $self->_read_json('last-check.json');
  return unless exists $checks->{$scope_key};
  delete $checks->{$scope_key};
  $self->_write_json( 'last-check.json', $checks );
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

sub put_unreached {
  my ( $self, $scope_key, $ids ) = @_;
  my $all = $self->_read_json('unreached.json');
  my %seen;
  my $next = [ js_sort_keys( grep { !$seen{$_}++ } @$ids ) ];
  return if js_stringify( $all->{$scope_key} // [] ) eq js_stringify($next);
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

sub put_sources_read {
  my ( $self, $scope_key, $record ) = @_;
  my $all  = $self->_read_json('sources-read.json');
  my $next = js_ordered();
  $next->{$_} = _source_read( $record->{$_} ) for js_sort_keys( keys %$record );
  return if js_stringify( $all->{$scope_key} // {} ) eq js_stringify($next);
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

# Replace a scope's render-inputs hash, or drop it (undef); written only when it changes.
sub put_render_inputs {
  my ( $self, $scope_key, $hash ) = @_;
  my $all = $self->_read_json('render-inputs.json');
  if ( defined $hash ) {
    return if exists $all->{$scope_key} && js_type( $all->{$scope_key} ) eq 'string' && $all->{$scope_key} eq $hash;
    $all->{$scope_key} = $hash;
  }
  else {
    return unless exists $all->{$scope_key};
    delete $all->{$scope_key};
  }
  $self->_write_json( 'render-inputs.json', $all );
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
  if ( defined $home ) { $self->_write_json( 'hermes-home.json', js_ordered( home => $home ) ) }
  else                 { unlink Skilletor::FSUtil::encode_text( $self->_file('hermes-home.json') ) }
}

#### The sync lock (spec §6.5) #########################################

use constant LOCK_NAME => 'sync.lock';

# What a lock leaves beside it: a broken lock's tombstone, a released lock on its way out.
use constant LEFTOVER => LOCK_NAME.'.';

sub _now_ms { int( Time::HiRes::time() * 1000 ) }

# Run $code holding `sync.lock/`, the one mutex over the locks, the target dirs and the source
# cache – shared with the reference, which takes the same directory the same way: mkdir, then
# `owner.json` created exclusively; a holder refreshes the record's mtime; a record not
# refreshed for the stale age – or for two refreshes when its pid on this host is gone – is a
# dead run's, an owner-less dir older than the grace time one that died before writing it.
sub with_lock {
  my ( $self, $code, %opts ) = @_;
  my $timeout_ms = $opts{timeout_ms} // 5_000;
  my $stale_ms   = $opts{stale_ms}   // 300_000;
  my $refresh_ms = $opts{refresh_ms} // ( $stale_ms / 3 < 10_000 ? int( $stale_ms / 3 ) : 10_000 );
  $refresh_ms = 1 if $refresh_ms < 1;
  my $grace_ms = $opts{grace_ms} // 2_000;
  my $poll_ms  = $opts{poll_ms}  // 25;
  my $lock_dir = $self->_file(LOCK_NAME);
  my $owner    = path_join( $lock_dir, 'owner.json' );
  my $token    = join '', map { sprintf '%02x', int rand 256 } 1 .. 8;
  my $deadline = _now_ms() + $timeout_ms;

  for ( ;; ) {
    last if $self->_acquire( $lock_dir, $owner, $token, $refresh_ms );
    if ( my $stale = $self->_judge( $lock_dir, $owner, $stale_ms, $grace_ms ) ) {
      next if $self->_break_lock( $lock_dir, $owner, $stale );
    }
    Skilletor::Error::LockTimeout->throw( 'timed out acquiring sync lock at '.$lock_dir ) if _now_ms() >= $deadline;
    Time::HiRes::sleep( $poll_ms / 1000 );
  }

  my $heartbeat = $self->_heartbeat( $owner, $refresh_ms );
  my $want = wantarray;
  my @result;
  my $ok = eval {
    $self->_sweep_leftovers($stale_ms);
    if    ($want)         { @result = $code->() }
    elsif ( defined $want ) { $result[0] = $code->() }
    else                  { $code->() }
    1;
  };
  my $err = $@;
  $self->_stop_heartbeat($heartbeat);
  $self->_release( $lock_dir, $owner, $token );
  die $err unless $ok;
  return $want ? @result : $result[0];
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

sub _touch {
  my ( $path ) = @_;
  my $now = Time::HiRes::time();
  Time::HiRes::utime( $now, $now, $path );
}

# The refreshes: Perl runs a resolve synchronously, so a child process stamps the owner record
# while the holder works, and stops when told or when the holder is gone. None on Windows.
sub _heartbeat {
  my ( $self, $owner, $refresh_ms ) = @_;
  return undef if $^O eq 'MSWin32';
  my $parent = $$;
  my $pid = fork;
  return undef unless defined $pid;
  return $pid if $pid;
  local $SIG{TERM} = sub { POSIX::_exit(0) };
  while ( getppid() == $parent && -e $owner ) {
    Time::HiRes::sleep( $refresh_ms / 1000 );
    _touch($owner);
  }
  POSIX::_exit(0);
}

sub _stop_heartbeat {
  my ( $self, $pid ) = @_;
  return unless $pid;
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

version 0.001

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

=item * C<hermes-home.json>: the Hermes home the user scope was synced under;
the port, which never targets Hermes, only ever drops it as the reference does.

=back

Pending reports belong to the reference's hooks and are not ported.

=head2 root

The state directory; created when the object is.

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

=head2 sources_read

  my $read = $state->sources_read($lock_path);
  # { shared => { kind, address, version, ref?, path? } } – malformed entries left out

=head2 put_sources_read

  $state->put_sources_read( $lock_path, \%read );   # names sorted; none drops the key

=head2 render_inputs

  my $hash = $state->render_inputs($lock_path);   # 'sha256:…' or undef

=head2 put_render_inputs

  $state->put_render_inputs( $lock_path, $hash );   # undef drops it

=head2 is_due

  $state->is_due( $key, $interval_seconds );

True when no check was marked for the key, or the interval has passed.

=head2 mark_checked

=head2 clear_checked

=head2 hermes_home

=head2 put_hermes_home

  $state->put_hermes_home(undef);   # drop the record

=head2 with_lock

  my $result = $state->with_lock( sub { ... }, timeout_ms => 5000 );

Runs the code holding C<< <root>/sync.lock/ >>, the mutex the reference takes
around every resolve, sync and read of the source cache – the same directory,
taken the same way, so the two implementations exclude each other. It waits
for another holder up to C<timeout_ms> (default 5000), breaking a lock a dead
run left (no refresh for C<stale_ms>, default 300000; an owner-less directory
after C<grace_ms>, default 2000), then throws
L<Skilletor::Error::LockTimeout>. While the code runs, a forked child refreshes
the owner record every C<refresh_ms> (default 10000; none on Windows). The
lock is released however the code ends; its result (in the caller's context)
is returned and its exception rethrown.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
