#!/usr/bin/env perl
# Skilletor::Commands::available's pieces no conformance case reaches (cases 93 to 97 hold its
# listing, marks, errors and refusals to the reference's bytes): the sync lock another run holds
# (k74, spec §6.5) – available waits for it before it fetches or sweeps the cache, then sweeps,
# lists and frees it, or gives up with the lock's own error – and invalid lock entries.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of make_repo write_json );

use Cwd ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::Commands;
use Skilletor::Engine;
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::State;

# A machine with one git source of one rule, declared in the user config; a dead run's leftovers
# in the cache.
sub machine {
  my $tmp  = Cwd::realpath( tempdir() );
  my $home = "$tmp/home";
  my $repo = make_repo( "$tmp/peter", 'rules/p-one.md' => "---\ndescription: one\n---\nOne.\n" );
  write_json( "$home/.claude/skilletor.json", { sources => { peter => { git => 'file://'.$repo } } } );
  my $engine = Skilletor::Engine->new( home => $home, project_dir => "$tmp/project", claude_config_dir => '', codex_home => "$home/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] }, @_ );
  my $cache = $engine->cache_root;
  my @leftovers = ( '0123456789abcdef.backup-Ef34Gh', '0123456789abcdef.stage-Ab12Cd' );
  path( $cache, $_ )->mkpath for @leftovers;
  return { engine => $engine, cache => $cache, leftovers => \@leftovers, state => $engine->state_root };
}

sub cache_entries { [ sort map { $_->basename } path( $_[0] )->children ] }

subtest 'another run holds the sync lock: available waits, then sweeps, lists and frees it' => sub {
  plan skip_all => 'needs fork' if $^O eq 'MSWin32';
  my $m = machine();
  my $out = path( $m->{state} )->parent->child('available.json');
  my ( $pid, $waited, $untouched );
  Skilletor::State->new( root => $m->{state} )->with_lock(
    sub {
      $pid = fork // die "fork: $!";
      if ( !$pid ) {
        my $ok = eval {
          my $items = Skilletor::Commands::available( $m->{engine} );
          path("$out.tmp")->spew_raw( js_stringify( [ map { "$_->{type}:$_->{name}\@$_->{source}" } @$items ] ) );
          rename "$out.tmp", "$out" or die "rename: $!";
          1;
        };
        POSIX::_exit( $ok ? 0 : 1 );
      }
      Time::HiRes::sleep(0.3);
      $waited    = !-e "$out";
      $untouched = cache_entries( $m->{cache} );
    }
  );
  waitpid $pid, 0;
  is( $?, 0, 'available ran' );
  ok( $waited, 'it had not returned while the lock was held' );
  is_deeply( $untouched, $m->{leftovers}, 'nothing fetched, nothing swept meanwhile' );
  is_deeply( js_parse( $out->slurp_raw ), ['rule:p-one@peter'], 'once free: the source listed' );
  is_deeply( [ grep { /\.(?:stage|backup)-/ } @{ cache_entries( $m->{cache} ) } ], [], "the dead run's leftovers swept" );
  ok( !-e "$m->{state}/sync.lock", 'the lock freed again' );
};

subtest 'a holder that keeps it: the lock timeout, nothing fetched or swept' => sub {
  my $m = machine( lock_timeout_ms => 150 );
  my $lock = path( $m->{state}, 'sync.lock' );
  $lock->mkpath;
  my $record = js_stringify( { pid => $$, host => Sys::Hostname::hostname(), token => 'x', at => int( Time::HiRes::time() * 1000 ), refreshMs => 10_000 } );
  $lock->child('owner.json')->spew_raw($record);
  my $err = eval { Skilletor::Commands::available( $m->{engine} ); 1 } ? undef : $@;
  isa_ok( $err, 'Skilletor::Error::LockTimeout' );
  is( $err && $err->message, "timed out acquiring sync lock at $lock", "the lock's message" );
  is_deeply( cache_entries( $m->{cache} ), $m->{leftovers}, 'the cache as it was' );
  is( $lock->child('owner.json')->slurp_raw, $record, "the holder's lock untouched" );
};

subtest 'a lock entry that is no object is refused' => sub {
  my $m = machine();
  my $file = path( $m->{engine}->claude_dir, 'skilletor.lock.json' );
  write_json( $file, qq({\n  "rules/p-one": null,\n  "rules/p-two": "x"\n}\n) );
  my $err = eval { Skilletor::Commands::available( $m->{engine}, source => 'peter' ); 1 } ? undef : $@;
  isa_ok( $err, 'Skilletor::Error::Lock' );
  is( $err && $err->message, $file.': invalid lock JSON (rules/p-one: expected an object)', 'the invalid entry and key named' );
};

subtest 'a lock entry name matches available ignoring case' => sub {
  my $m = machine();
  write_json( path( $m->{engine}->claude_dir, 'skilletor.lock.json' ),
    qq({\n  "rules/P-ONE": { "source": "peter", "version": "v", "files": {} }\n}\n) );
  my $items = Skilletor::Commands::available( $m->{engine}, source => 'peter' );
  is_deeply( [ map { [ $_->{name}, $_->{installed} ? 1 : 0 ] } @$items ], [ [ 'p-one', 1 ] ], 'listed as installed' );
};

done_testing;
