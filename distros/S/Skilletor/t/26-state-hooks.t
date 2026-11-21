#!/usr/bin/env perl
# The state the hooks keep (k180), as the reference's State (state.ts) keeps it: the pending report
# a background sync leaves for a project (`pending-report.json`), the cwd a session's hook last
# looked at (`session-cwd.json`, the 256 sessions recorded last), and the check mark a sync that
# timed out on the lock drops again (dueAgain, clearChecked). The same files, the same bytes: with
# node, every sequence below runs in the reference too, on its own state dir with the same clock,
# and must leave the same files and give the same answers.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;

use IPC::Open2 qw( open2 );
use JSON::MaybeXS ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::State;

my %PERL = (
  putPendingReport => 'put_pending_report', takePendingReport => 'take_pending_report', sessionCwd => 'session_cwd',
  putSessionCwd => 'put_session_cwd', markChecked => 'mark_checked', clearChecked => 'clear_checked', isDue => 'is_due',
);
my %ANSWERS = map { ( $_ => 1 ) } qw( takePendingReport sessionCwd isDue );

# Each call on one State, as the reference's `state` op makes them: [ method, \@args, now ].
sub perl_calls {
  my ( $root, @calls ) = @_;
  my $state = Skilletor::State->new( root => "$root" );
  return [
    map {
      my ( $method, $args, $now ) = @$_;
      no warnings 'redefine';
      local *Skilletor::State::_now_ms_number = sub { $now } if defined $now;
      my $answer = $state->${ \$PERL{$method} }(@$args);
      !$ANSWERS{$method} ? undef : $method eq 'isDue' ? ( $answer ? JSON::MaybeXS::true() : JSON::MaybeXS::false() ) : $answer;
    } @calls
  ];
}

# Every file of the state dir: { name => bytes }.
sub files_of {
  my ( $root ) = @_;
  return { map { ( $_->basename => $_->slurp_raw ) } grep { $_->is_file } path($root)->children };
}

sub prepared {
  my ( %files ) = @_;
  my $root = tempdir;
  $root->child($_)->spew_raw( encode_text( $files{$_} ) ) for keys %files;
  return $root;
}

my $report_a = js_ordered( systemMessage => 'skilletor: 1 item(s) updated',
  hookSpecificOutput => js_ordered( hookEventName => 'UserPromptSubmit', additionalContext => "skilletor synced items:\n- skill foo\@s: active now" ) );
my $report_b = js_ordered( systemMessage => 'skilletor: cannot sync: \\u001b' );

# ---- pending-report.json ---------------------------------------------------------------------

subtest 'a pending report per project, taken once' => sub {
  my $root = tempdir;
  my $s = Skilletor::State->new( root => "$root" );
  is( $s->take_pending_report('/p'), undef, 'none at first' );
  ok( !$root->child('pending-report.json')->exists, 'and taking none writes no file' );
  $s->put_pending_report( '/p', $report_a );
  $s->put_pending_report( '/q', $report_b );
  $s->put_pending_report( '/p', $report_b );
  is( $root->child('pending-report.json')->slurp_utf8,
    qq({\n  "/p": {\n    "systemMessage": "skilletor: cannot sync: \\\\u001b"\n  },\n  "/q": {\n    "systemMessage": "skilletor: cannot sync: \\\\u001b"\n  }\n}\n),
    'one per project key, the last put wins and keeps its place' );
  $s->put_pending_report( '/p', $report_a );
  my $got = $s->take_pending_report('/p');
  is( js_stringify($got), js_stringify($report_a), 'taken with its keys in their order' );
  is( $s->take_pending_report('/p'), undef, 'and gone after' );
  is( $root->child('pending-report.json')->slurp_utf8, qq({\n  "/q": {\n    "systemMessage": "skilletor: cannot sync: \\\\u001b"\n  }\n}\n), 'the other stays' );
  $root->child('pending-report.json')->spew_raw('{"/q":1}');
  is( $s->take_pending_report('/p'), undef, 'a key not there' );
  is( $root->child('pending-report.json')->slurp_raw, '{"/q":1}', 'leaves the file as it was' );
  $root->child('pending-report.json')->spew_raw('[1,2]');
  is( $s->take_pending_report('/q'), undef, 'a file that is no object holds none' );
  $root->child('pending-report.json')->spew_raw('{"": null}');
  is( $s->take_pending_report(''), undef, 'a null report is taken as none' );
  is( $root->child('pending-report.json')->slurp_raw, "{}\n", 'but taken: the file is written' );
};

subtest 'POSIX persisted symlink-spelled pending and check keys retain their raw identity' => sub {
  SKIP: {
    skip 'POSIX state keys intentionally remain raw', 3 if $^O eq 'MSWin32';
    my $tmp     = tempdir;
    my $root    = $tmp->child('state');
    my $project = $tmp->child('project');
    my $alias   = $tmp->child('project-link');
    $root->mkpath;
    $project->mkpath;
    symlink "$project", "$alias" or skip "symlinks unavailable: $!", 3;
    my $pending = js_ordered( systemMessage => 'raw POSIX alias' );
    $root->child('pending-report.json')->spew_utf8( js_stringify( js_ordered( "$alias" => $pending ) ) );
    $root->child('last-check.json')->spew_utf8( js_stringify( js_ordered( "$alias" => 100 ) ) );

    my $s = Skilletor::State->new( root => "$root" );
    {
      no warnings 'redefine';
      local *Skilletor::State::_now_ms_number = sub { 200 };
      ok( !$s->is_due( "$alias", 600 ), 'the persisted raw check key is found' );
    }
    is_deeply( $s->take_pending_report("$alias"), $pending, 'the persisted raw pending key is found' );
    is_deeply( [ keys %{ js_parse( $root->child('last-check.json')->slurp_utf8 ) } ], ["$alias"], 'the raw key remains stored' );
  }
};

subtest 'prototype-named hook state keys are ordinary data' => sub {
  my $root = tempdir;
  my $s = Skilletor::State->new( root => "$root" );
  is( $s->take_pending_report($_), undef, "no inherited pending report $_" ) for qw( constructor toString );
  ok( !$root->child('pending-report.json')->exists, 'taking inherited names writes no file' );
  for my $key (qw( __proto__ constructor toString )) {
    $s->put_pending_report( $key, js_ordered( key => $key ) );
  }
  my $pending = js_parse( $root->child('pending-report.json')->slurp_utf8 );
  ok( exists $pending->{$_}, "pending report owns $_" ) for qw( __proto__ constructor toString );
  is( $s->take_pending_report($_)->{key}, $_, "pending report round-trips $_" ) for qw( __proto__ constructor toString );

  for my $key (qw( __proto__ constructor toString )) {
    no warnings 'redefine';
    local *Skilletor::State::_now_ms_number = sub { 100 };
    $s->put_session_cwd( $key, "/cwd/$key" );
  }
  my $sessions = js_parse( $root->child('session-cwd.json')->slurp_utf8 );
  ok( exists $sessions->{$_}, "session cwd owns $_" ) for qw( __proto__ constructor toString );
  is( $s->session_cwd($_), "/cwd/$_", "session cwd round-trips $_" ) for qw( __proto__ constructor toString );
};

# ---- session-cwd.json ------------------------------------------------------------------------

subtest 'the cwd a session last looked at' => sub {
  my $root = tempdir;
  my $s = Skilletor::State->new( root => "$root" );
  is( $s->session_cwd('s1'), undef, 'none at first' );
  {
    no warnings 'redefine';
    local *Skilletor::State::_now_ms_number = sub { 1700000000123 };
    $s->put_session_cwd( 's1', '/work/a' );
  }
  is( $s->session_cwd('s1'), '/work/a', 'recorded' );
  is( $root->child('session-cwd.json')->slurp_utf8, qq({\n  "s1": {\n    "cwd": "/work/a",\n    "at": 1700000000123\n  }\n}\n), '{ cwd, at } with the clock in ms' );
  $root->child('session-cwd.json')->spew_raw('{"s1":{"cwd":"/work/a","at":1}}');
  $s->put_session_cwd( 's1', '/work/a' );
  is( $root->child('session-cwd.json')->slurp_raw, '{"s1":{"cwd":"/work/a","at":1}}', 'the same cwd again writes nothing' );
  my $before = int( Time::HiRes::time() * 1000 );
  $s->put_session_cwd( 's1', '/work/b' );
  my $entry = js_parse( $root->child('session-cwd.json')->slurp_utf8 )->{s1};
  is( $entry->{cwd}, '/work/b', 'another cwd replaces it' );
  ok( $entry->{at} >= $before && $entry->{at} <= int( Time::HiRes::time() * 1000 ), 'stamped with the real clock' );
  like( $root->child('session-cwd.json')->slurp_raw, qr/"at": \d+\n/, 'a whole number' );

  $root->child('session-cwd.json')->spew_raw('{"str":"/x","arr":["/x"],"num":{"cwd":5},"null":null,"ok":{"cwd":"/y","at":"soon"}}');
  is( $s->session_cwd($_), undef, "malformed entry $_ counts as none" ) for qw( str arr num null missing );
  is( $s->session_cwd('ok'), '/y', 'a cwd beside a malformed at' );
  $root->child('session-cwd.json')->spew_raw('not json');
  is( $s->session_cwd('ok'), undef, 'an unreadable file holds none' );
};

subtest 'at most 256 sessions: the ones recorded last' => sub {
  my $all = js_ordered( map { ( "s$_" => js_ordered( cwd => "/w/$_", at => 1000 + $_ ) ) } 1 .. 300 );
  my $root = prepared( 'session-cwd.json' => js_stringify( $all, 2 )."\n" );
  my $s = Skilletor::State->new( root => "$root" );
  {
    no warnings 'redefine';
    local *Skilletor::State::_now_ms_number = sub { 5000 };
    $s->put_session_cwd( 'new', '/w/new' );
  }
  my $kept = js_parse( $root->child('session-cwd.json')->slurp_utf8 );
  is( scalar( keys %$kept ), 256, '256 kept' );
  is_deeply( [ keys %$kept ], [ ( map {"s$_"} 46 .. 300 ), 'new' ], 'the 255 others recorded last, in their place, and the new one last' );
  {
    no warnings 'redefine';
    local *Skilletor::State::_now_ms_number = sub { 6000 };
    $s->put_session_cwd( 's46', '/w/moved' );
  }
  $kept = js_parse( $root->child('session-cwd.json')->slurp_utf8 );
  is_deeply( [ ( keys %$kept )[ 0, -1 ] ], [ 's46', 'new' ], 'a session already there keeps its place: none dropped for it' );
  is( scalar( keys %$kept ), 256, 'still 256' );
};

# ---- dueAgain, clearChecked ------------------------------------------------------------------

# The keys are project dirs that exist: a mark drops the marks of the ones that are gone (k255).
subtest 'a check mark dropped: the next check is due at once' => sub {
  my $root = tempdir;
  my $dirs = tempdir;
  my ( $p, $q ) = map { path( $dirs, $_ )->mkpath; "$dirs/$_" } qw( p q );
  my $s = Skilletor::State->new( root => "$root" );
  $s->mark_checked($p);
  $s->mark_checked($q);
  ok( !$s->is_due( $p, 600 ), 'marked: not due' );
  $s->due_again($p);
  ok( $s->is_due( $p, 600 ), 'due again' );
  ok( !$s->is_due( $q, 600 ), 'the other key keeps its mark' );
  my $one = js_stringify( js_ordered( $q => 1 ) );
  $root->child('last-check.json')->spew_raw($one);
  $s->clear_checked($p);
  is( $root->child('last-check.json')->slurp_raw, $one, 'a key not marked: nothing written' );
  SKIP: {
    skip 'root ignores the mode', 2 if $> == 0;
    skip 'no mode bits on Windows', 2 if $^O eq 'MSWin32';
    $s->mark_checked($p);
    chmod 0500, "$root";
    my $ok = eval { $s->due_again($p); 1 };
    my $err = $@;
    chmod 0700, "$root";
    ok( $ok, 'a state dir that cannot be written: due_again does not throw' ) or diag $err;
    chmod 0500, "$root";
    $ok = eval { $s->clear_checked($p); 1 };
    chmod 0700, "$root";
    ok( !$ok, 'where clear_checked does' );
  }
};

# ---- the reference, byte for byte ------------------------------------------------------------

# Project dirs that exist, for the check marks: a mark drops the marks of gone ones (k255).
my $dirs = tempdir;
my ( $P, $Q, $LIVE ) = map { path( $dirs, $_ )->mkpath; "$dirs/$_" } qw( p q live );
my $GONE = "$dirs/gone";

my @sequences = (
  [ 'prototype-named keys from empty stores' => {}, [
      [ takePendingReport => ['constructor'] ],
      [ takePendingReport => ['toString'] ],
      [ putPendingReport  => [ '__proto__', js_ordered( key => '__proto__' ) ] ],
      [ putPendingReport  => [ 'constructor', js_ordered( key => 'constructor' ) ] ],
      [ putPendingReport  => [ 'toString', js_ordered( key => 'toString' ) ] ],
      [ takePendingReport => ['__proto__'] ],
      [ takePendingReport => ['constructor'] ],
      [ takePendingReport => ['toString'] ],
      [ putSessionCwd     => [ '__proto__', '/cwd/__proto__' ], 100 ],
      [ putSessionCwd     => [ 'constructor', '/cwd/constructor' ], 101 ],
      [ putSessionCwd     => [ 'toString', '/cwd/toString' ], 102 ],
      [ sessionCwd        => ['__proto__'] ],
      [ sessionCwd        => ['constructor'] ],
      [ sessionCwd        => ['toString'] ],
    ] ],
  [ 'pending reports: put, replace, take, take again' => {}, [
      [ takePendingReport => ['/p'] ],
      [ putPendingReport  => [ '/p', $report_a ] ],
      [ putPendingReport  => [ '/q', $report_b ] ],
      [ putPendingReport  => [ '/p', $report_b ] ],
      [ putPendingReport  => [ '', $report_a ] ],
      [ takePendingReport => ['/q'] ],
      [ takePendingReport => ['/q'] ],
      [ putPendingReport  => [ '10', $report_a ] ],
      [ putPendingReport  => [ '2', $report_b ] ],
    ] ],
  [ 'pending reports in a malformed file' => { 'pending-report.json' => '[1]' }, [
      [ takePendingReport => ['/p'] ],
      [ putPendingReport  => [ '/p', $report_b ] ],
    ] ],
  [ 'pending report: a null one' => { 'pending-report.json' => '{"/p":null,"/q":{"systemMessage":"x"}}' }, [
      [ takePendingReport => ['/p'] ],
      [ takePendingReport => ['/q'] ],
    ] ],
  [ 'session cwds: put, same again, another, read' => {}, [
      [ sessionCwd    => ['s1'] ],
      [ putSessionCwd => [ 's1', '/a' ], 100 ],
      [ putSessionCwd => [ 's1', '/a' ], 200 ],
      [ putSessionCwd => [ '', '/home/ü' ], 300 ],
      [ putSessionCwd => [ '7', '/n' ], 300 ],
      [ putSessionCwd => [ 's1', '/b' ], 400 ],
      [ sessionCwd    => ['s1'] ],
      [ sessionCwd    => [''] ],
      [ sessionCwd    => ['7'] ],
    ] ],
  [ 'session cwds: malformed entries' => { 'session-cwd.json' => '{"str":"/x","arr":["/x"],"num":{"cwd":5,"at":9},"ok":{"cwd":"/y","at":"soon"}}' }, [
      ( map { [ sessionCwd => [$_] ] } qw( str arr num ok none ) ),
      [ putSessionCwd => [ 'ok', '/y' ], 10 ],
      [ putSessionCwd => [ 'arr', '/x' ], 11 ],
    ] ],
  [ 'session cwds: 300 recorded, ties and malformed ones among them' => {
      'session-cwd.json' => js_stringify( js_ordered(
        ( map { ( "s$_" => js_ordered( cwd => "/w/$_", at => 1000 + ( $_ % 7 ) ) ) } 1 .. 150 ),
        ( map { ( "$_" => js_ordered( cwd => "/n/$_", at => 1000 + ( $_ % 5 ) ) ) } 1 .. 100 ),
        ( map { ( "bad$_" => ( $_ % 2 ? ["/b/$_"] : js_ordered( cwd => "/b/$_", at => ( 9000 + $_ ).q{} ) ) ) } 1 .. 40 ),
        ( map { ( "late$_" => js_ordered( cwd => "/l/$_", at => 2000.5 + $_ ) ) } 1 .. 10 ),
      ), 2 ) }, [
      [ putSessionCwd => [ 'new', '/w/new' ], 5000 ],
      [ putSessionCwd => [ 'bad1', '/b/again' ], 5001 ],
      [ putSessionCwd => [ '42', '/n/again' ], 5002 ],
      [ sessionCwd    => ['s1'] ],
      [ sessionCwd    => ['late3'] ],
    ] ],
  [ 'check marks: mark, clear, clear again, due' => { 'last-check.json' => js_stringify( js_ordered( $Q => 1 ) ) }, [
      [ markChecked  => [$P], 10_000 ],
      [ isDue        => [ $P, 600 ], 600_000 ],
      [ isDue        => [ $P, 600 ], 610_000 ],
      [ clearChecked => [$P] ],
      [ clearChecked => [$P] ],
      [ isDue        => [ $P, 600 ], 10_001 ],
      [ isDue        => [ $Q, 1 ], 1_000 ],
      [ isDue        => [ $Q, 1 ], 1_001 ],
    ] ],
  [ 'check marks of gone projects: a due test and a clear keep them, a mark drops them (k255)' => {
      'last-check.json' => js_stringify( js_ordered( $GONE => 1, $LIVE => 2, 'rel/proj' => 3, '' => 4, "$GONE/sub" => 5 ), 2 )."\n" }, [
      [ isDue        => [ $GONE, 600 ], 10_000 ],
      [ clearChecked => [$P] ],
      [ markChecked  => ["$dirs/removed"], 20_000 ],
      [ isDue        => [ $LIVE, 600 ], 30_000 ],
      [ isDue        => [ $GONE, 600 ], 30_000 ],
      [ markChecked  => [$P], 40_000 ],
    ] ],
);

my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'state.ts' );
my $why_not =
    !$runner->exists || !$src_ts->exists                                   ? 'needs the skilletor checkout (src/) and maint/ts-run.mjs'
  : !grep( { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '' )         ? 'needs node'
  : !path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists ? "needs the reference's node_modules"
  :                                                                          undef;

sub ts {
  my ( $req ) = @_;
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text( js_stringify($req) );
  close $in;
  my $text = do { local $/; <$out> };
  waitpid $pid, 0;
  my $answer = js_parse( decode_utf8_lossy( $text // '' ) );
  die 'ts-run: '.( $answer->{error} // $text ) if defined $answer->{error};
  return $answer->{result};
}

SKIP: {
  skip $why_not, scalar @sequences if defined $why_not;
  for my $seq (@sequences) {
    my ( $name, $files, $calls ) = @$seq;
    subtest "the reference: $name" => sub {
      my ( $perl_root, $ts_root ) = ( prepared(%$files), prepared(%$files) );
      my $perl = perl_calls( $perl_root, @$calls );
      my $ts = ts( js_ordered( op => 'state', root => "$ts_root",
        calls => [ map { js_ordered( method => $_->[0], args => $_->[1], ( defined $_->[2] ? ( now => $_->[2] ) : () ) ) } @$calls ] ) );
      is( js_stringify( $perl, 2 ), js_stringify( $ts, 2 ), 'the same answers' );
      is_deeply( files_of($perl_root), files_of($ts_root), 'the same files, byte for byte' );
    };
  }
}

done_testing;
