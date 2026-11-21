#!/usr/bin/env perl
# The engine options the hooks set (k180), as engine.ts has them: check's `local` (each scope's
# lock against its config, no source asked), the sync's `if_changed` (that local check once more,
# under the sync lock: nothing left, nothing runs) and `deadline` (past it, the sync stops before
# its first write of a scope), and `lock_timeout_ms` per call. With node, one sequence of steps
# runs on a machine with the reference (src/ through maint/ts-run.mjs), then on the same machine
# built anew at the same path with the port: each step must print the same --json bytes (or stop
# with the same error), and every file but the source cache must have the same bytes at each
# snapshot.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( bare_remote write_json );

use IPC::Open2 qw( open2 );
use JSON::MaybeXS ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Sys::Hostname ();
use Time::HiRes ();
use Skilletor::Engine;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::Report qw( report_json );

delete $ENV{CLAUDE_CONFIG_DIR};

my $DEADLINE_ERROR = 'sync stopped before applying the user scope: its sources took too long';

sub skill { "---\ndescription: $_[0]\n---\n$_[0]\n" }

# A machine at $root, built the same way every time (the git commits with a fixed date, so their
# SHAs are the same): a home whose user config installs from a local and a git source, a project
# whose own source awaits trust.
sub build_machine {
  my ( $root ) = @_;
  path($root)->remove_tree( { safe => 0 } );
  path( $root, 'remote' )->mkpath;
  my $m = { root => $root, home => "$root/home", project => "$root/project" };
  local @ENV{qw( GIT_AUTHOR_DATE GIT_COMMITTER_DATE )} = ('2026-01-01T00:00:00+0000') x 2;
  $m->{remote} = bare_remote("$root/remote");
  $m->{remote}{commit}->( { 'skills/gs/SKILL.md' => skill('gs') }, 'gs' );
  write_json( "$m->{home}/.claude.json", "{}\n" );
  write_json( "$root/src/skills/$_/SKILL.md", skill($_) ) for qw( a b c );
  write_json( "$root/team/skills/t/SKILL.md", skill('t') );
  user_config( $m, qw( a@s gs@g ) );
  write_json( "$m->{project}/.claude/skilletor.json", { sources => { team => { local => "$root/team" } }, install => { skills => ['t@team'] } } );
  return $m;
}

# A machine in a temp dir of its own, which lives as long as the machine.
sub fresh_machine {
  my $tmp = tempdir;
  my $m = build_machine( $tmp->realpath->child('m')->stringify );
  $m->{tempdir} = $tmp;
  return $m;
}

sub user_config {
  my ( $m, @skills ) = @_;
  write_json( "$m->{home}/.claude/skilletor.json",
    js_ordered( sources => js_ordered( s => { local => "$m->{root}/src" }, g => { git => $m->{remote}{url} } ), install => { skills => \@skills } ) );
}

sub lock_dir { "$_[0]{home}/.claude/skilletor/sync.lock" }

# Another run holds the sync lock: a live owner record (this process, this host, fresh).
sub hold_lock {
  my ( $m ) = @_;
  path( lock_dir($m) )->mkpath;
  write_json( lock_dir($m).'/owner.json',
    js_stringify( js_ordered( pid => 0 + $$, host => Sys::Hostname::hostname(), token => 'held', at => int( Time::HiRes::time() * 1000 ), refreshMs => 10_000 ) ) );
}

my %MUTATE = (
  add_b        => sub { user_config( $_[0], qw( a@s b@s gs@g ) ) },
  add_c        => sub { user_config( $_[0], qw( a@s b@s c@s gs@g ) ) },
  hold_lock    => \&hold_lock,
  release_lock => sub { path( lock_dir( $_[0] ) )->remove_tree( { safe => 0 } ) },
  remote_gone  => sub { $_[0]{remote}{gone}->() },
  break_config => sub { write_json( "$_[0]{home}/.claude/skilletor.json", '{ broken' ) },
);

# Every file of the machine but the remote and the source cache: { rel => bytes }.
sub snapshot {
  my ( $m ) = @_;
  my %out;
  my $iter = path( $m->{root} )->iterator( { recurse => 1 } );
  while ( my $p = $iter->() ) {
    next unless $p->is_file;
    my $rel = $p->relative( $m->{root} )->stringify;
    next if $rel =~ m{\A(?:remote/|home/\.claude/skilletor/cache/)};
    $out{$rel} = $p->slurp_raw;
  }
  return \%out;
}

sub message_of {
  my ( $err ) = @_;
  return $err->message if ref $err && $err->can('message');
  return "$err" =~ s/ at \S+ line \d+\.?\n?\z//r =~ s/\n\z//r;
}

sub perl_engine {
  my ( $m, %attrs ) = @_;
  return Skilletor::Engine->new( home => $m->{home}, project_dir => $m->{project}, codex_home => "$m->{home}/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] }, %attrs );
}

# One step with the port: what `--json` prints, or the error it stopped with.
sub perl_step {
  my ( $m, $step ) = @_;
  my $e = perl_engine($m);
  my %opts = ( scope => $step->{scope} // 'all' );
  $opts{local}           = 1                       if $step->{local};
  $opts{if_changed}      = 1                       if $step->{ifChanged};
  $opts{deadline}        = $step->{deadline}       if defined $step->{deadline};
  $opts{lock_timeout_ms} = $step->{lockTimeoutMs} if defined $step->{lockTimeoutMs};
  my $r = eval { $step->{op} eq 'sync' ? $e->sync(%opts) : $e->check(%opts) };
  return defined $r ? report_json($r) : 'error: '.message_of($@);
}

#### What the port does, pinned without node ##################################

subtest 'check local: no source asked; trust requests still named' => sub {
  my $m = fresh_machine();
  my $e = perl_engine($m);
  $e->sync;
  my $full = $e->check;
  is_deeply( [ map { "$_->{name}:".( $_->{changed} ? 1 : 0 ) } @{ $full->{sources} } ], [ 's:1', 'g:0' ], 'a full check asks each source' );
  my $local = $e->check( local => 1 );
  is( report_json($local), join( "\n",
      '{', '  "changed": false,', '  "sources": [],', '  "warnings": [],', '  "trustRequests": [', '    {', '      "scope": "project",',
      '      "name": "team",', '      "kind": "local",', '      "url": "'.$m->{root}.'/team"', '    }', '  ]', '}' ),
    'a local one asks none: the lock matches, the untrusted source is named' );
  $m->{remote}{gone}->();
  like( join( ' ', @{ $e->check->{warnings} } ), qr/\Asource g: /, 'the remote gone: a full check says so' );
  is_deeply( $e->check( local => 1 )->{warnings}, [], 'a local one does not ask it' );
  user_config( $m, qw( a@s b@s gs@g ) );
  my $drift = $e->check( local => 1, scope => 'user' );
  ok( $drift->{changed}, 'a declaration added: changed' );
  is_deeply( $drift->{declaredChanged}, ['user'], 'in the user scope' );
  is_deeply( $drift->{sources}, [], 'still no source asked' );
};

subtest 'sync if_changed: nothing left to do, nothing runs' => sub {
  my $m = fresh_machine();
  my $e = perl_engine($m);
  $e->sync;
  my $before = snapshot($m);
  is( report_json( $e->sync( if_changed => 1 ) ), qq({\n  "scopes": []\n}), 'no scopes' );
  is_deeply( snapshot($m), $before, 'nothing written' );
  user_config( $m, qw( a@s b@s gs@g ) );
  my $r = $e->sync( if_changed => 1, scope => 'user' );
  is_deeply( [ map { $_->{scope} } @{ $r->{scopes} } ], ['user'], 'a change: the scope syncs' );
  is_deeply( [ map { $_->{key} } @{ $r->{scopes}[0]{added} } ], ['skills/b'], 'with what changed' );
  write_json( "$m->{home}/.claude/skilletor.json", '{ broken' );
  my $err = $e->sync( if_changed => 1 );
  is_deeply( $err->{scopes}, [], 'a config error: the sync reports it' );
  like( $err->{error}, qr/skilletor\.json/, 'with its error' );
};

subtest 'sync if_changed: the check runs once the sync lock is held' => sub {
  my $m = fresh_machine();
  my $e = perl_engine( $m, lock_timeout_ms => 20_000 );
  $e->sync;
  for my $if_changed ( 1, 0 ) {
    user_config( $m, qw( a@s b@s gs@g ) );    # a change to sync ...
    pipe( my $from_child, my $to_parent ) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if ( !$pid ) {
      close $from_child;
      # ... which another run, holding the lock, takes back before it lets go.
      Skilletor::State->new( root => "$m->{home}/.claude/skilletor" )->with_lock( sub {
        syswrite $to_parent, "held\n";
        Time::HiRes::sleep(0.5);
        user_config( $m, qw( a@s gs@g ) );
      } );
      POSIX::_exit(0);
    }
    close $to_parent;
    my $held = <$from_child>;
    my $r = $e->sync( $if_changed ? ( if_changed => 1 ) : () );
    waitpid $pid, 0;
    is( $held, "held\n", 'the other run held the lock' );
    if ($if_changed) { is( report_json($r), qq({\n  "scopes": []\n}), 'if_changed: nothing left once the lock was ours' ) }
    else             { is( scalar @{ $r->{scopes} }, 2, 'without it the sync runs anyway' ) }
  }
};

subtest 'sync deadline: past it, nothing of the scope is written' => sub {
  my $m = fresh_machine();
  my $e = perl_engine($m);
  $e->sync;
  user_config( $m, qw( a@s b@s gs@g ) );
  my $records = sub { [ map { scalar keys %{ js_parse( path( $m->{home}, '.claude/skilletor', $_ )->slurp_utf8 ) } } qw( sources-read.json render-inputs.json ) ] };
  is_deeply( $records->(), [ 1, 2 ], 'records of the last sync' );
  my $before = snapshot($m);
  no warnings 'redefine';
  local *Skilletor::Engine::_now_ms = sub { 1_000_000 };
  ok( !eval { $e->sync( deadline => 999_999 ); 1 }, 'a ms past the deadline: the sync stops' );
  is( message_of($@), $DEADLINE_ERROR, 'with the reference\'s words' );
  ok( !-e "$m->{home}/.claude/skills/b", 'nothing installed' );
  is_deeply( $records->(), [ 0, 1 ], "the user scope's records dropped: check counts its drift again" );
  my $after = snapshot($m);
  delete @{$_}{qw( home/.claude/skilletor/sources-read.json home/.claude/skilletor/render-inputs.json )} for $before, $after;
  is_deeply( $after, $before, 'no other file touched' );
  ok( eval { $e->sync( deadline => 1_000_000 ); 1 }, 'at the deadline: not past it' ) or diag $@;
  ok( -e "$m->{home}/.claude/skills/b/SKILL.md", 'synced' );
};

subtest 'lock_timeout_ms per call' => sub {
  my $m = fresh_machine();
  hold_lock($m);
  my $e = perl_engine( $m, lock_timeout_ms => 60_000 );
  my $t0 = Time::HiRes::time();
  my $err = eval { $e->sync( lock_timeout_ms => 0 ); 1 } ? undef : $@;
  ok( Time::HiRes::time() - $t0 < 10, 'the call\'s 0 over the engine\'s minute' );
  isa_ok( $err, 'Skilletor::Error::LockTimeout' );
  is( message_of($err), 'timed out acquiring sync lock at '.lock_dir($m), 'the lock it waited for' );
  $t0 = Time::HiRes::time();
  ok( !eval { $e->sync( lock_timeout_ms => 300 ); 1 }, 'the call\'s 300 ms' );
  ok( Time::HiRes::time() - $t0 >= 0.25, 'waited for (ms clock: a ms short at most)' );
  $t0 = Time::HiRes::time();
  ok( !eval { perl_engine( $m, lock_timeout_ms => 200 )->sync; 1 }, 'without one, the engine\'s' );
  ok( Time::HiRes::time() - $t0 >= 0.15, 'waited for too' );
  ok( eval { $e->check( local => 1 ); 1 }, 'a check takes no lock' );
};

#### The reference, step by step #############################################

my $FUTURE = int( Time::HiRes::time() * 1000 ) + 3_600_000;
my @STEPS = (
  { op => 'sync' },
  { snapshot => 'after the first sync' },
  { op => 'check' },
  { op => 'check', local => 1 },
  { op => 'check', local => 1, scope => 'project' },
  { op => 'sync', ifChanged => 1 },
  { snapshot => 'after an if-changed sync with nothing to do' },
  { mutate => 'add_b' },
  { op => 'check', local => 1 },
  { op => 'sync', ifChanged => 1, scope => 'user' },
  { snapshot => 'after an if-changed sync with a change' },
  { mutate => 'add_c' },
  { op => 'sync', deadline => 1 },
  { snapshot => 'after a sync past its deadline' },
  { op => 'check', local => 1 },
  { op => 'sync', deadline => $FUTURE },
  { snapshot => 'after a sync within its deadline' },
  { mutate => 'hold_lock' },
  { op => 'sync', lockTimeoutMs => 0 },
  { op => 'check', local => 1 },
  { mutate => 'release_lock' },
  { mutate => 'remote_gone' },
  { op => 'check' },
  { op => 'check', local => 1 },
  { mutate => 'break_config' },
  { op => 'check', local => 1 },
  { op => 'sync', ifChanged => 1 },
  { snapshot => 'at the end' },
);

my $runner = path( $FindBin::Bin, '..', 'maint', 'ts-run.mjs' );
my $src_ts = path( $FindBin::Bin, '..', 'src', 'engine.ts' );
my $why_not =
    !$runner->exists || !$src_ts->exists                                     ? 'needs the skilletor checkout (src/) and maint/ts-run.mjs'
  : !grep( { -x path( $_, 'node' ) } split /:/, $ENV{PATH} // '' )          ? 'needs node'
  : !path( $FindBin::Bin, '..', 'node_modules', 'nunjucks' )->exists  ? "needs the reference's node_modules"
  :                                                                          undef;

sub ts_step {
  my ( $m, $step ) = @_;
  my $req = js_ordered( op => $step->{op}, home => $m->{home}, projectDir => $m->{project}, scope => $step->{scope} // 'all', json => JSON::MaybeXS::true() );
  $req->{local}         = JSON::MaybeXS::true() if $step->{local};
  $req->{ifChanged}     = JSON::MaybeXS::true() if $step->{ifChanged};
  $req->{deadline}      = $step->{deadline}      if defined $step->{deadline};
  $req->{lockTimeoutMs} = $step->{lockTimeoutMs} if defined $step->{lockTimeoutMs};
  my $pid = open2( my $out, my $in, 'node', "$runner" );
  binmode $in, ':raw';
  print {$in} encode_text( js_stringify($req) );
  close $in;
  my $text = do { local $/; <$out> };
  waitpid $pid, 0;
  my $answer = js_parse( decode_utf8_lossy( $text // '' ) );
  return defined $answer->{error} ? 'error: '.$answer->{error} : $answer->{result};
}

# The steps on a machine built at $root: each step's output or snapshot, in turn.
sub run_steps {
  my ( $root, $run ) = @_;
  my $m = build_machine($root);
  return [ map {
    $_->{mutate} ? do { $MUTATE{ $_->{mutate} }->($m); () }
      : $_->{snapshot} ? [ $_->{snapshot}, snapshot($m) ]
      : [ $_->{op}, $run->( $m, $_ ) ];
  } @STEPS ];
}

SKIP: {
  skip $why_not, 1 if defined $why_not;
  my $tmp  = tempdir;
  my $root = $tmp->realpath->child('m')->stringify;
  my $ts   = run_steps( $root, \&ts_step );
  my $perl = run_steps( $root, \&perl_step );
  my @ops = grep { !$_->{mutate} } @STEPS;
  subtest 'the reference, step by step' => sub {
    for my $i ( 0 .. $#ops ) {
      my $s = $ops[$i];
      if ( $s->{snapshot} ) {
        is_deeply( $perl->[$i][1], $ts->[$i][1], "snapshot $s->{snapshot}: the same files" );
        next;
      }
      my $name = join ' ', $s->{op}, map { "$_=$s->{$_}" } grep { $_ ne 'op' } sort keys %$s;
      is( $perl->[$i][1], $ts->[$i][1], "$name: the same output" );
    }
    like( $perl->[ ( grep { ( $ops[$_]{deadline} // 0 ) == 1 } 0 .. $#ops )[0] ][1], qr/\Aerror: \Q$DEADLINE_ERROR\E\z/, 'the deadline step stopped' );
    like( $perl->[ ( grep { defined $ops[$_]{lockTimeoutMs} } 0 .. $#ops )[0] ][1], qr/\Aerror: timed out acquiring sync lock at /, 'the lock step timed out' );
  };
}

done_testing;
