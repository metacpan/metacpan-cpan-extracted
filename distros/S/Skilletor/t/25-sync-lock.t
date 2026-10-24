#!/usr/bin/env perl
# The sync lock (spec §6.5): Skilletor::State->with_lock takes sync.lock/ as the reference does.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( path tempdir );
use POSIX ();
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::JSON qw( js_parse js_stringify );
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
  plan skip_all => 'no refreshes on Windows' if $^O eq 'MSWin32';
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
