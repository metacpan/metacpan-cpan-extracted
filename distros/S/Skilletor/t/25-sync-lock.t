#!/usr/bin/env perl
# The sync lock (spec §6.5): Skilletor::State->with_lock takes sync.lock/ as the reference does.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );
use SkilletorTest::Win32 qw( win32_os );

use Path::Tiny qw( path tempdir );
use POSIX ();
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Process qw( run_command );
use Skilletor::State;

sub state { Skilletor::State->new( root => "$_[0]" ) }

sub leftovers { [ sort grep { /\Async\.lock/ } map { $_->basename } path( $_[0] )->children ] }

sub owner_record {
  my ( $root, %r ) = @_;
  my $dir = path( $root, 'sync.lock' );
  $dir->mkpath;
  $dir->child('owner.json')->spew_raw( js_stringify( { pid => $$, host => Sys::Hostname::hostname(), token => 'x', at => 0, refreshMs => 10_000, %r } ) );
  return $dir->child('owner.json');
}

subtest 'runs the code, returns its result, releases' => sub {
  my $root = tempdir;
  my $s = state($root);
  my $seen;
  is( $s->with_lock( sub { $seen = -d "$root/sync.lock" && -f "$root/sync.lock/owner.json"; 42 } ), 42, 'scalar result' );
  ok( $seen, 'the lock dir and owner record exist while it runs' );
  my $record;
  $s->with_lock( sub { $record = js_parse( path( $root, 'sync.lock', 'owner.json' )->slurp_raw ) } );
  is_deeply( [ keys %$record ], [qw( pid host token at refreshMs )], 'the reference\'s owner record' );
  is( $record->{pid}, $$, 'our pid' );
  is_deeply( [ $s->with_lock( sub { ( 1, 2, 3 ) } ) ], [ 1, 2, 3 ], 'list result' );
  ok( !-e "$root/sync.lock", 'released' );
  is( error_of( sub { $s->with_lock( sub { die "boom\n" } ) } ), "boom\n", 'an exception is rethrown' );
  ok( !-e "$root/sync.lock", 'and the lock released' );
  is_deeply( leftovers($root), [], 'nothing left beside it' );
};

subtest 'a live holder: wait, then time out' => sub {
  my $root = tempdir;
  owner_record($root);
  my $t0 = Time::HiRes::time();
  my $err;
  eval { state($root)->with_lock( sub { fail('must not run') }, timeout_ms => 150 ); 1 } or $err = $@;
  isa_ok( $err, 'Skilletor::Error::LockTimeout' );
  is( $err->message, 'timed out acquiring sync lock at '.path( $root, 'sync.lock' ), 'the reference\'s message' );
  cmp_ok( Time::HiRes::time() - $t0, '>=', 0.14, 'after the timeout' );
  ok( -f "$root/sync.lock/owner.json", 'the holder\'s lock untouched' );
};

subtest 'a stale lock is broken' => sub {
  my $root = tempdir;
  my $owner = owner_record($root);
  utime time - 400, time - 400, "$owner";
  my $ran;
  state($root)->with_lock( sub { $ran = 1 }, timeout_ms => 1000 );
  ok( $ran, 'not refreshed for the stale age: broken' );
  is( scalar( grep { /\Async\.lock\.broken-/ } @{ leftovers($root) } ), 1, 'moved to a tombstone' );
};

subtest 'an owner-less lock dir past the grace time is removed' => sub {
  my $root = tempdir;
  path( $root, 'sync.lock' )->mkpath;
  utime time - 10, time - 10, "$root/sync.lock";
  my $ran;
  state($root)->with_lock( sub { $ran = 1 }, timeout_ms => 1000 );
  ok( $ran, 'taken' );
  is_deeply( leftovers($root), [], 'no tombstone for an empty dir' );
};

subtest 'a dead owner on this host is broken before the stale age' => sub {
  my $root = tempdir;
  my $pid = fork // die "fork: $!";
  POSIX::_exit(0) unless $pid;
  waitpid $pid, 0;
  my $owner = owner_record( $root, pid => $pid, refreshMs => 10 );
  utime time - 2, time - 2, "$owner";
  my $ran;
  state($root)->with_lock( sub { $ran = 1 }, timeout_ms => 1000 );
  ok( $ran, 'its pid is gone and it missed two refreshes' );
  my $other = tempdir;
  my $live  = owner_record( $other, pid => $$, refreshMs => 10 );
  utime time - 2, time - 2, "$live";
  like( error_of( sub { state($other)->with_lock( sub { }, timeout_ms => 100 ) } ), qr/timed out/, 'a live pid is never dead' );
};

subtest 'the holder refreshes its record' => sub {
  plan skip_all => 'the refreshing child is POSIX\'s; Windows: the next subtest' if $^O eq 'MSWin32';
  my $root = tempdir;
  my ( $before, $after );
  state($root)->with_lock(
    sub {
      my $owner = "$root/sync.lock/owner.json";
      $before = ( Time::HiRes::stat($owner) )[9];
      Time::HiRes::sleep(0.4);
      $after = ( Time::HiRes::stat($owner) )[9];
    },
    refresh_ms => 50,
  );
  cmp_ok( $after - $before, '>', 0.1, 'the mtime moved while the code ran' );
  ok( !-e "$root/sync.lock", 'released' );
};

sub mtime { ( Time::HiRes::stat( $_[0] ) )[9] }

# Windows has no fork to spare: the holder stamps its record itself while it waits on a program.
subtest 'win32: the holder refreshes its record while it waits on a program, and only then' => sub {
  my $root = tempdir;
  my $other = tempdir;
  # Elsewhere the Windows path, its spawn done the POSIX way, and a perl named as a Windows program.
  my $bin = tempdir;
  my $exe = $^O eq 'MSWin32' ? $^X : $bin->child('perl.exe');
  symlink $^X, "$exe" or die "symlink: $!" unless $^O eq 'MSWin32';
  my @os = $^O eq 'MSWin32' ? () : ( win32 => win32_os() );
  my $wait = [ "$exe", '-e', 'select undef, undef, undef, 0.4' ];
  my %m;
  state($root)->with_lock(
    sub {
      my $owner = "$root/sync.lock/owner.json";
      $m{start} = mtime($owner);
      Time::HiRes::sleep(0.3);
      $m{slept} = mtime($owner);
      state($other)->with_lock(
        sub {
          my $inner = "$other/sync.lock/owner.json";
          $m{inner_start} = mtime($inner);
          $m{outer_before} = mtime($owner);
          my $r = run_command( @os, cmd => $wait );
          die "the program did not run: ".( $r->{spawn_error} // {} )->{message}."\n" unless defined $r->{code} && $r->{code} == 0;
          $m{inner_end} = mtime($inner);
          $m{outer_after} = mtime($owner);
        },
        refresh_ms => 50,
        win32      => 1,
      );
      $m{nested_done} = mtime($owner);
      my $r = run_command( @os, cmd => $wait );
      $m{waited} = mtime($owner);
    },
    refresh_ms => 50,
    win32      => 1,
  );
  is( $m{slept}, $m{start}, 'no refresh while the code does not wait on a program: no child process stamps it' );
  cmp_ok( $m{inner_end} - $m{inner_start}, '>', 0.1, 'a lock taken inside another: its record refreshed while the program ran' );
  cmp_ok( $m{outer_after} - $m{outer_before}, '>', 0.1, 'and the outer one too' );
  cmp_ok( $m{waited} - $m{nested_done}, '>', 0.1, 'the outer refreshes on its own once the inner is released' );
  ok( !-e "$root/sync.lock" && !-e "$other/sync.lock", 'both released' );
  is( $Skilletor::Process::ON_WAIT, undef, 'and nothing left waiting' );
};

subtest 'win32: the touch takes the core utime there (Time::HiRes has none on Windows)' => sub {
  my $dir  = tempdir;
  my $file = $dir->child('f');
  $file->touch;
  utime 1, 1, "$file";
  Skilletor::State::_touch( "$file", 0 );
  cmp_ok( abs( mtime("$file") - time ), '<', 5, 'stamped with now' );
};

# A stopped holder (k251). Claude Code starts a hook in a process group of its own and cancels it
# with SIGTERM to that group, SIGKILL 1.5 s later; Ctrl+C sends SIGINT to the terminal's group, a
# closed terminal SIGHUP. The holder runs in a child of its own – with group, as the leader of a
# process group, its heartbeat child in it – that says when it holds the lock (with after_refresh,
# once its heartbeat has just stamped the record), then sleeps until it is stopped.
sub start_holder {
  my ( $root, %opts ) = @_;
  my ( $group, $after_refresh ) = delete @opts{qw( group after_refresh )};
  pipe( my $r, my $w ) or die "pipe: $!";
  my $pid = fork // die "fork: $!";
  if ( !$pid ) {
    close $r;
    setpgrp( 0, 0 ) if $group;
    $SIG{$_} = 'DEFAULT' for qw( TERM INT HUP );    # as a run starts, whatever runs the tests
    eval {
      state($root)->with_lock(
        sub {
          my $owner = "$root/sync.lock/owner.json";
          my $m0 = mtime($owner);
          Time::HiRes::sleep(0.005) while $after_refresh && mtime($owner) == $m0;
          syswrite $w, "held\n";
          sleep 60;
        },
        %opts,
      );
    };
    POSIX::_exit(1);    # the lock given up the normal way: not what a test stops
  }
  close $w;
  my $said = <$r> // '';
  close $r;
  die "the holder never took the lock\n" unless $said eq "held\n";
  return $pid;
}

for my $signal (qw( TERM INT HUP )) {
  subtest "k251: a holder stopped by $signal releases the lock and dies of $signal" => sub {
    plan skip_all => 'POSIX signals: Windows ends a process without a signal it can catch' if $^O eq 'MSWin32';
    my $root = tempdir;
    my $pid = start_holder( $root, group => 1 );
    kill $signal, -$pid;    # the holder and its heartbeat child
    waitpid $pid, 0;
    is( $? & 127, POSIX->can("SIG$signal")->(), "ended by $signal, as without the lock" );
    ok( !-e "$root/sync.lock", 'the lock released' );
    is_deeply( leftovers($root), [], 'nothing left beside it' );
  };
}

subtest 'k251: with_lock handles a stop only while it takes or holds the lock, and only where it would end the process' => sub {
  plan skip_all => 'POSIX signals: Windows ends a process without a signal it can catch' if $^O eq 'MSWin32';
  my $root = tempdir;
  local @SIG{qw( TERM INT HUP )} = qw( DEFAULT IGNORE DEFAULT );
  my %inside;
  state($root)->with_lock(
    sub {
      state( tempdir() )->with_lock( sub { %inside = map { ( $_ => ref $SIG{$_} || $SIG{$_} ) } qw( TERM INT HUP ) } );
    }
  );
  is_deeply( \%inside, { TERM => 'CODE', INT => 'IGNORE', HUP => 'CODE' }, 'held, nested too: a handler where the stop would end it, an ignored stop left so' );
  is_deeply( { map { ( $_ => $SIG{$_} ) } qw( TERM INT HUP ) }, { TERM => 'DEFAULT', INT => 'IGNORE', HUP => 'DEFAULT' }, 'none once given up' );
};

subtest 'k251: a run stopped while it waits for the lock leaves the holder\'s lock alone' => sub {
  plan skip_all => 'POSIX signals: Windows ends a process without a signal it can catch' if $^O eq 'MSWin32';
  # Its handler is in place while it waits, but its release checks its token and gives nothing up.
  my $root = tempdir;
  my $record = owner_record( $root, at => 0 )->slurp_raw;    # a live holder: this test's pid
  my $pid = fork // die "fork: $!";
  if ( !$pid ) {
    $SIG{$_} = 'DEFAULT' for qw( TERM INT HUP );
    eval { state($root)->with_lock( sub { }, timeout_ms => 5000 ) };
    POSIX::_exit(1);
  }
  Time::HiRes::sleep(0.3);    # well inside its wait
  kill 'TERM', $pid;
  waitpid $pid, 0;
  is( $? & 127, POSIX::SIGTERM(), 'ended by the stop, as before' );
  is( path( $root, 'sync.lock', 'owner.json' )->slurp_raw, $record, 'the holder\'s lock untouched' );
};

subtest 'k251: a child the holder forks holds no lock: a stop ends it and leaves the lock alone' => sub {
  plan skip_all => 'POSIX signals: Windows ends a process without a signal it can catch' if $^O eq 'MSWin32';
  my $root = tempdir;
  local @SIG{qw( TERM INT HUP )} = qw( DEFAULT DEFAULT DEFAULT );
  my %seen;
  state($root)->with_lock(
    sub {
      my $pid = fork // die "fork: $!";
      if ( !$pid ) { kill 'INT', $$; Time::HiRes::sleep(5); POSIX::_exit(0) }    # a spawn before its exec, say
      waitpid $pid, 0;
      %seen = ( signal => $? & 127, held => !!-f "$root/sync.lock/owner.json" );
    }
  );
  is_deeply( \%seen, { signal => POSIX::SIGINT(), held => 1 }, 'the child died of the stop, the holder kept its lock' );
  ok( !-e "$root/sync.lock", 'which the holder released as it ended' );
};

subtest 'k251: a holder killed with KILL leaves the lock, never refreshed again; the next run breaks it' => sub {
  plan skip_all => 'POSIX signals: Windows ends a process without a signal it can catch' if $^O eq 'MSWin32';
  # The contract for a stop no process can catch (spec §6.5): the lock stays, its record naming
  # this host and a pid that is gone. The holder alone is killed, as an OOM killer does: its
  # heartbeat child, orphaned, must not refresh the record again – the holder is killed right
  # after a refresh, and three refresh intervals pass. Once the record is older than two of them,
  # the next run breaks it at once, far below the stale age.
  my $root = tempdir;
  my $owner = "$root/sync.lock/owner.json";
  my $pid = start_holder( $root, refresh_ms => 100, after_refresh => 1 );
  kill 'KILL', $pid;
  waitpid $pid, 0;
  is( $? & 127, 9, 'killed' );
  my $stamped = mtime($owner);
  Time::HiRes::sleep(0.35);
  is( js_parse( path($owner)->slurp_raw )->{pid}, $pid, 'the lock left, its record the dead holder\'s' );
  is( mtime($owner), $stamped, 'not refreshed after the holder died' );
  my $ran;
  state($root)->with_lock( sub { $ran = 1 }, timeout_ms => 1000 );
  ok( $ran, 'the next run broke it: this host, its pid gone, two refreshes missed' );
  is( scalar( grep { /\Async\.lock\.broken-/ } @{ leftovers($root) } ), 1, 'one tombstone' );
};

subtest 'old leftovers are swept' => sub {
  my $root = tempdir;
  path( $root, 'sync.lock.broken-1-2' )->mkpath;
  path( $root, 'sync.lock.released-x' )->mkpath;
  path( $root, 'sync.lock.broken-3-4' )->mkpath;
  utime time - 400, time - 400, "$root/$_" for qw( sync.lock.broken-1-2 sync.lock.released-x );
  state($root)->with_lock( sub { } );
  is_deeply( leftovers($root), ['sync.lock.broken-3-4'], 'older than the stale age: gone; a fresh one stays' );
};

done_testing;
