#!/usr/bin/env perl
# The Claude Code hooks (k181) as the reference's hooks.test.ts holds them, where a shared
# conformance case cannot: what turns on the clock (the in-session interval, against an injected
# clock), the sync lock held by another run (a lock timeout of 0, no waiting), the background
# trigger (injected, and the real detached spawn), what the prompt hook leaves unloaded, and the
# hook command's exit 0 from a removed cwd or a failed setup (k164). The output a session sees
# is the reference's – conformance/'s hook steps hold both CLIs to the same bytes.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( git_ok write_json );

use Config ();
use Cwd ();
use Encode ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::CLI ();
use Skilletor::Engine ();
use Skilletor::FSUtil qw( encode_text );
use Skilletor::Hooks qw( run_hook default_background MOVE_DEADLINE_MS );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::Process qw( run_command spawn_detached );
use Skilletor::State;

delete $ENV{CLAUDE_CONFIG_DIR};

my $LIB = path( $FindBin::Bin, '..', 'lib' )->realpath;
my $BIN = path( $FindBin::Bin, '..', 'script', 'skilletor' )->realpath;

sub skill { "---\nname: $_[0]\ndescription: $_[0]\n---\nBODY\n" }

# A machine for the hooks, as hooks.test.ts's env(): a home and a project with `.claude/`, a
# state dir of its own, Claude Code alone in use, no git work tree, the background trigger
# recorded instead of started.
sub machine {
  my $tmp  = tempdir;
  my $root = Cwd::realpath("$tmp");
  my $m    = { tmp => $tmp, root => $root, home => "$root/home", project => "$root/proj", calls => [] };
  path("$m->{$_}/.claude")->mkpath for qw( home project );
  $m->{ctx} = {
    home        => $m->{home},
    project_dir => $m->{project},
    state_root  => "$root/state",
    engine      => {
      markers          => { claude => [ $m->{home} ], codex => [] },
      is_git_work_tree => sub { 0 },
      git_tracked      => sub { [] },
      host             => { name => 'box', os => 'linux' },
      user             => { name => 'getty', home => $m->{home} },
    },
    background => sub { push @{ $m->{calls} }, $_[0] },
  };
  return $m;
}

sub user_config { write_json( "$_[0]{home}/.claude/skilletor.json", $_[1] ) }

# A local source `s` with the skills given; its path.
sub local_source {
  my ( $m, @skills ) = @_;
  write_json( "$m->{root}/src/skills/$_/SKILL.md", skill($_) ) for @skills;
  return "$m->{root}/src";
}

sub state { Skilletor::State->new( root => $_[0]{ctx}{state_root} ) }

# The context with more engine arguments.
sub with_engine {
  my ( $m, %engine ) = @_;
  return { %{ $m->{ctx} }, engine => { %{ $m->{ctx}{engine} }, %engine } };
}

sub out { js_stringify( $_[0] ) }

# A clock in ms the state's marks and due tests read.
our $NOW;
{
  no warnings 'redefine';
  my $real = \&Skilletor::State::_now_ms_number;
  *Skilletor::State::_now_ms_number = sub { defined $NOW ? $NOW : $real->() };
}

# ---- session-start -------------------------------------------------------------------------

subtest 'session-start: silent with nothing declared; a change synced and reported' => sub {
  my $m = machine();
  user_config( $m, {} );
  is( out( run_hook( 'session-start', {}, $m->{ctx} ) ), '{}', 'nothing declared: nothing to say' );
  my $src = local_source( $m, 'foo' );
  user_config( $m, { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  is( out( run_hook( 'session-start', { source => 'startup' }, $m->{ctx} ) ),
    '{"systemMessage":"skilletor: 1 item(s) updated","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"skilletor synced items:\n- skill foo@mine: active now"}}',
    'the line, and the context with the activation hint' );
  ok( -f "$m->{home}/.claude/skills/foo/SKILL.md", 'installed' );
};

# k151: the hook clock is read before check; the engine clock stands after check, lock acquisition
# and source resolution. Past the default or a stricter supplied deadline, no target or ownership
# write of the affected scope may begin.
subtest 'session-start: a late scope writes neither files nor an ownership lock' => sub {
  no warnings 'redefine';
  my ( $hook_now, $engine_now ) = ( 1_000_000, 1_000_000 + MOVE_DEADLINE_MS + 1 );
  local *Skilletor::Hooks::_now_ms  = sub { $hook_now };
  local *Skilletor::Engine::_now_ms = sub { $engine_now };

  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  is( out( run_hook( 'session-start', { source => 'startup' }, $m->{ctx} ) ),
    '{"systemMessage":"skilletor: sync stopped before applying the user scope: its sources took too long"}',
    'the 20 s SessionStart budget is measured from before check' );
  ok( !-e "$m->{home}/.claude/skills" && !-e "$m->{home}/.claude/skilletor.lock.json" && !-e "$m->{home}/.claude/.gitignore",
    'no installed file, incomplete ownership or adjacent scope write' );

  my $strict = machine();
  user_config( $strict,
    { sources => { mine => { local => local_source( $strict, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  $engine_now = $hook_now + 101;
  is( out( run_hook( 'session-start', { source => 'startup' }, { %{ $strict->{ctx} }, deadline => $hook_now + 100 } ) ),
    '{"systemMessage":"skilletor: sync stopped before applying the user scope: its sources took too long"}',
    'a stricter caller deadline is not relaxed to 20 s' );
  ok( !-e "$strict->{home}/.claude/skills" && !-e "$strict->{home}/.claude/skilletor.lock.json", 'nothing owned or installed' );
};

# Once the first scope's ownership lock exists, make only the next scope late. The earlier scope
# remains committed, and the diagnostic must not claim that the whole sync wrote nothing.
subtest 'session-start: a late project scope is named after the user scope was applied' => sub {
  no warnings 'redefine';
  my $m = machine();
  my $src = local_source( $m, qw( foo bar ) );
  user_config( $m, { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  write_json( "$m->{project}/.claude/skilletor.json", { install => { skills => ['bar@mine'] } } );
  my $user_lock = "$m->{home}/.claude/skilletor.lock.json";
  my $started = 1_000_000;
  local *Skilletor::Hooks::_now_ms = sub { $started };
  local *Skilletor::Engine::_now_ms = sub { $started + ( -e $user_lock ? MOVE_DEADLINE_MS + 1 : 0 ) };

  is( out( run_hook( 'session-start', { source => 'startup' }, $m->{ctx} ) ),
    '{"systemMessage":"skilletor: sync stopped before applying the project scope: its sources took too long"}',
    'only the late project scope is named' );
  ok( -f "$m->{home}/.claude/skills/foo/SKILL.md", 'the user file persists' );
  is( js_parse( path($user_lock)->slurp_utf8 )->{'skills/foo'}{source}, 'mine', 'the user ownership persists' );
  ok( !-e "$m->{project}/.claude/skills" && !-e "$m->{project}/.claude/skilletor.lock.json",
    'project files and ownership are untouched' );
};

subtest 'session-start marks the project checked and records the session cwd' => sub {
  my $m = machine();
  user_config( $m, {} );
  local $NOW = 1_000_000;
  run_hook( 'session-start', { cwd => "$m->{project}/sub", session_id => 's1' }, $m->{ctx} );
  ok( !state($m)->is_due( $m->{project}, 1 ), 'checked: not due right after' );
  is( state($m)->session_cwd('s1'), "$m->{project}/sub", "the session's cwd, as the input names it" );
  run_hook( 'session-start', { cwd => 7 }, $m->{ctx} );
  is( state($m)->session_cwd(''), undef, 'a cwd that is no string is not recorded' );
};

subtest 'session-start: an untrusted project source is the trust request, a sync not asked for' => sub {
  my $m = machine();
  user_config( $m, {} );
  write_json( "$m->{project}/.claude/skilletor.json",
    { sources => { team => { local => "$m->{root}/team" } }, install => { skills => ['foo@team'] } } );
  my $out = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  is( $out->{systemMessage}, 'skilletor: 1 warning(s)', 'counted as a warning' );
  is( $out->{hookSpecificOutput}{additionalContext}, "- untrusted source team (local $m->{root}/team); run: skilletor trust team",
    'named in the context with the command' );
};

subtest 'session-start: no harness detected is one warning line' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  my $out = run_hook( 'session-start', {}, with_engine( $m, markers => { claude => [], codex => [] } ) );
  like( $out->{systemMessage}, qr/\Askilletor: no agent harness detected/, 'the error' );
  is_deeply( [ sort keys %$out ], ['systemMessage'], 'nothing else' );
  unlike( $out->{systemMessage}, qr/\n/, 'on one line' );
};

subtest 'session-start: a write error is one warning line, as it will be at the next prompt' => sub {
  my $m = machine();
  my $src = local_source( $m, 'foo' );
  write_json( "$src/rules/r.md", "R\n" );
  user_config( $m, { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'], rules => ['r@mine'] } } );
  write_json( "$m->{home}/.claude/rules", 'a file where the rules dir goes' );
  my $start = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  like( $start->{systemMessage}, qr{\Askilletor: [^\n]*rules[^\n]*\z}, "the error, on one line" );
  is( out( run_hook( '__sync-background', {}, $m->{ctx} ) ), '{}', 'the background sync answers nothing' );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), out( js_ordered( systemMessage => $start->{systemMessage} ) ),
    "the next prompt: the same line, no context (k89)" );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), '{}', 'then nothing' );
};

# ---- user-prompt-submit: the interval, on an injected clock ---------------------------------

subtest 'user-prompt-submit starts a background sync only when due' => sub {
  my $m = machine();
  user_config( $m, {} );    # checkInterval: the config's default, 1800 s
  local $NOW = 5_000_000;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 1, 'never checked: due' );
  is( $m->{calls}[0]{project_dir}, $m->{project}, 'the trigger gets the context' );
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 1, 'right after: not due' );
  $NOW += 1_800_000 - 1;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 1, 'a ms before the interval is up: not due' );
  $NOW += 1;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 2, 'at 1800 s: due again' );
};

subtest 'checkInterval 0 or less: never a background sync' => sub {
  for my $interval ( 0, -5 ) {
    my $m = machine();
    user_config( $m, { checkInterval => $interval } );
    run_hook( 'user-prompt-submit', {}, $m->{ctx} ) for 1 .. 2;
    is( scalar @{ $m->{calls} }, 0, "checkInterval $interval" );
  }
};

subtest 'a config that fails to load: the 600 s fallback' => sub {
  my $m = machine();
  user_config( $m, {} );
  write_json( "$m->{project}/.claude/skilletor.json", '{ not json' );
  local $NOW = 9_000_000;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 1, 'due at first' );
  $NOW += 600_000 - 1;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 1, 'not before 600 s' );
  $NOW += 1;
  run_hook( 'user-prompt-submit', {}, $m->{ctx} );
  is( scalar @{ $m->{calls} }, 2, 'at 600 s' );
};

# The fast path's claim (the reference's <100 ms): a prompt with nothing due does no work – no
# engine loaded, no git run, no trigger, nothing said. Asserted in a fresh perl, whose %INC holds
# only what the prompt loaded.
subtest 'the prompt with nothing due loads no engine and runs no git' => sub {
  my $m = machine();
  user_config( $m, {} );
  state($m)->mark_checked( $m->{project} );
  my $bin = "$m->{root}/bin";
  path($bin)->mkpath;
  path("$bin/git")->spew_raw("#!/bin/sh\nprintf '%s\\n' \"\$*\" >> '$m->{root}/git.log'\nexit 1\n");
  chmod 0755, "$bin/git";
  my $script = <<'END';
use Skilletor::Hooks qw( run_hook );
use Skilletor::JSON qw( js_stringify );
my ( $home, $project, $state ) = @ARGV;
my $called = 0;
my $out = run_hook( 'user-prompt-submit', {}, { home => $home, project_dir => $project, state_root => $state, background => sub { $called++ } } );
print js_stringify($out), ' ', $called, ' ', join( ',', grep { m{\ASkilletor/(?:Engine|Resolver|Render|Apply)\.pm\z} } sort keys %INC ), "\n";
END
  local $ENV{PATH} = "$bin:$ENV{PATH}";
  my $r = run_command( cmd => [ $^X, ( map { "-I$_" } grep { !ref } @INC ), '-e', $script, $m->{home}, $m->{project}, $m->{ctx}{state_root} ], env => {%ENV} );
  is( $r->{stdout}, "{} 0 \n", 'nothing said, no trigger, none of the engine loaded' ) or diag $r->{stderr};
  ok( !-e "$m->{root}/git.log", 'no git run: the project was known' );
};

# The same prompt as Claude Code runs it, `skilletor hook user-prompt-submit`, pinned to the
# modules of the dist it loads (k199): the hook, its state and config, what they stand on – no
# report module, no engine. Every prompt pays for each one; a module that joins this list must
# be one the fast path cannot do without.
subtest 'the CLI prompt hook with nothing due loads the hook, state and config modules alone' => sub {
  my $m = machine();
  claude_marker($m);
  user_config( $m, {} );
  Skilletor::State->new( root => "$m->{home}/.claude/skilletor" )->mark_checked( $m->{project} );
  my $script = <<'END';
require Skilletor::CLI;
my $code = Skilletor::CLI::run( 'hook', 'user-prompt-submit' );
print "\n", $code, ' ', join( ',', sort grep { m{\ASkilletor/} } keys %INC ), "\n";
END
  my %env = ( %ENV, HOME => $m->{home}, CODEX_HOME => "$m->{home}/.no-codex", CLAUDE_PROJECT_DIR => $m->{project} );
  delete $env{SKILLETOR_PROJECT_DIR};    # it would name another project, one that is due
  my $r = run_command( cmd => [ $^X, ( map { "-I$_" } grep { !ref } @INC ), '-e', $script ], stdin => '{"session_id":"s","cwd":"x"}', env => \%env );
  my @loaded = map { "Skilletor/$_.pm" }
    qw( CLI Config Entry Error Error/Config Error/JSON Error/LockTimeout FSUtil GitEnv Hooks JSON JSON/OrderedHash JSString Process State );
  is( $r->{stdout}, "\n0 ".join( ',', sort @loaded )."\n", 'nothing said, exit 0, and these modules alone' ) or diag $r->{stderr};
};

# ---- pending reports ---------------------------------------------------------------------------

subtest 'a pending report is delivered once, on the next prompt' => sub {
  my $m = machine();
  user_config( $m, { checkInterval => 0 } );
  my $pending = js_ordered( systemMessage => 'skilletor: 1 item updated',
    hookSpecificOutput => js_ordered( hookEventName => 'UserPromptSubmit', additionalContext => '- skill foo@mine: active now' ) );
  state($m)->put_pending_report( $m->{project}, $pending );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), out($pending), 'as stored, keys in order' );
  is( state($m)->take_pending_report( $m->{project} ), undef, 'and taken' );
};

subtest 'the background sync leaves its report for the next prompt' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] }, checkInterval => 0 } );
  is( out( run_hook( '__sync-background', {}, $m->{ctx} ) ), '{}', 'it answers nothing' );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ),
    '{"systemMessage":"skilletor: 1 item(s) updated","hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"skilletor synced items:\n- skill foo@mine: active now"}}',
    'the next prompt shows it under its own event' );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), '{}', 'once' );
};

subtest 'without a project dir: the git top level of the cwd, else the cwd itself' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{root};
  my $repo = "$m->{root}/repo";
  path("$repo/src/deep")->mkpath;
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  my $pending = js_ordered( systemMessage => 'skilletor: 1 item(s) updated' );
  state($m)->put_pending_report( $repo, $pending );
  user_config( $m, { checkInterval => 0 } );
  my $ctx = { %{ $m->{ctx} }, project_dir => undef };
  is( out( run_hook( 'user-prompt-submit', { cwd => "$repo/src/deep" }, $ctx ) ), out($pending), "a subdir: the repo root's report" );
  my $plain = "$m->{root}/plain";
  path("$plain/.claude")->mkpath;
  user_config( $m, { sources => { mine => { local => local_source( $m, 'bar' ) } } } );
  write_json( "$plain/.claude/skilletor.json", { install => { skills => ['bar@mine'] } } );
  run_hook( 'session-start', { cwd => $plain }, $ctx );
  ok( -f "$plain/.claude/skills/bar/SKILL.md", 'outside git: the cwd is the project' );
};

# ---- the sync lock held by another run (lock timeout 0: no waiting) -------------------------

sub held {
  my ( $m, $code ) = @_;
  return state($m)->with_lock( $code, refresh_ms => 60_000 );
}

subtest 'a lock timeout: session-start warns in one line, the background sync leaves no report' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  my $ctx = with_engine( $m, lock_timeout_ms => 0 );
  held(
    $m,
    sub {
      is( out( run_hook( 'session-start', { source => 'startup' }, $ctx ) ),
        out( js_ordered( systemMessage => "skilletor: timed out acquiring sync lock at $m->{ctx}{state_root}/sync.lock" ) ), 'the timeout' );
      is( out( run_hook( '__sync-background', {}, $ctx ) ), '{}', 'the background sync: nothing' );
    }
  );
  is( state($m)->take_pending_report( $m->{project} ), undef, 'and no report left' );
  ok( !-e "$m->{home}/.claude/skills/foo", 'nothing synced' );
};

subtest "a lock timeout leaves the project due; the next due prompt's sync installs" => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  my $runs = 0;
  my $ctx = with_engine( $m, lock_timeout_ms => 0 );
  $ctx->{background} = sub { $runs++; run_hook( '__sync-background', {}, $_[0] ) };    # as the detached child runs it
  held( $m, sub { is( out( run_hook( 'user-prompt-submit', {}, $ctx ) ), '{}', 'a due prompt, the lock held' ) } );
  is( $runs, 1, 'one background sync' );
  ok( !-e "$m->{home}/.claude/skills/foo", 'which synced nothing' );
  is( out( run_hook( 'user-prompt-submit', {}, $ctx ) ), '{}', 'the next prompt' );
  is( $runs, 2, 'is due again after the timeout' );
  ok( -f "$m->{home}/.claude/skills/foo/SKILL.md", 'and its sync installs' );
  is( run_hook( 'user-prompt-submit', {}, $ctx )->{systemMessage}, 'skilletor: 1 item(s) updated', 'its report comes with the prompt after' );
  is( $runs, 2, 'which is not due: checked' );
};

subtest 'a session-start that timed out on the lock leaves the project due for the first prompt' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  my $ctx = with_engine( $m, lock_timeout_ms => 0 );
  held( $m, sub { like( run_hook( 'session-start', { source => 'startup' }, $ctx )->{systemMessage}, qr/timed out acquiring sync lock/, 'timed out' ) } );
  run_hook( 'user-prompt-submit', {}, $ctx );
  is( scalar @{ $m->{calls} }, 1, 'due after the timeout' );
  is( run_hook( 'session-start', { source => 'startup' }, $ctx )->{systemMessage}, 'skilletor: 1 item(s) updated', 'a session-start that syncs' );
  run_hook( 'user-prompt-submit', {}, $ctx );
  is( scalar @{ $m->{calls} }, 1, 'leaves it checked' );
};

# ---- events not known; other harnesses (the move hooks: t/71-hooks-move.t) ----------------

subtest 'an unknown event: one warning line, never a die' => sub {
  my $m = machine();
  is( out( run_hook( 'bogus', {}, $m->{ctx} ) ), '{"systemMessage":"skilletor: unknown hook event: bogus"}', 'unknown' );
  is( out( run_hook( 'bogus', {}, { %{ $m->{ctx} }, project_dir => undef } ) ), '{"systemMessage":"skilletor: unknown hook event: bogus"}',
    'unknown, without a project dir' );
};

# Codex's rules context and prompt move: t/73-hooks-codex.t; Hermes' opt-in line and prompt move:
# t/75-hooks-hermes.t.
subtest '--harness codex without Codex as a target: answered as Claude Code' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] }, checkInterval => 0 } );
  my $claude = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  path("$m->{home}/.claude/skills")->remove_tree;
  unlink "$m->{home}/.claude/skilletor.lock.json";
  my $codex = run_hook( 'session-start', { source => 'startup' }, { %{ $m->{ctx} }, harness => 'codex' } );
  is( out($codex), out($claude), 'codex: the same answer, no rules context' );
};

# ---- the background trigger ---------------------------------------------------------------

subtest 'the default background: this CLI once more, detached, with the project' => sub {
  my @calls;
  my $spawn = sub { push @calls, {@_} };
  default_background( { project_dir => '/p/proj', self_command => [ '/usr/bin/perl', '-I/lib', '/bin/skilletor' ] }, $spawn );
  is( scalar @calls, 1, 'one spawn' );
  is_deeply( $calls[0]{cmd}, [ '/usr/bin/perl', '-I/lib', '/bin/skilletor', 'hook', '__sync-background' ], 'hook __sync-background' );
  is( $calls[0]{env}{SKILLETOR_PROJECT_DIR}, '/p/proj', 'SKILLETOR_PROJECT_DIR' );
  is( $calls[0]{env}{PATH}, $ENV{PATH}, 'the rest of the environment as it is' );
  default_background( { project_dir => '/p/ü' }, $spawn );
  is( scalar @calls, 1, 'without a self command: nothing' );
  default_background( { project_dir => '/p/ü', self_command => ['/bin/skilletor'] }, $spawn );
  is( $calls[1]{env}{SKILLETOR_PROJECT_DIR}, encode_text('/p/ü'), 'the project as UTF-8 bytes' );
};

subtest 'self_command: a packed binary runs itself; plain perl, $^X with the script and its module dirs' => sub {
  is_deeply( Skilletor::CLI::self_command( packed => 1, progname => '/opt/skilletor' ), ['/opt/skilletor'], 'packed: PAR_PROGNAME' );
  is_deeply( Skilletor::CLI::self_command( packed => 0, perl => '/usr/bin/perl', inc => [ '/a', sub { }, '/b' ], script => '/x/bin/skilletor' ),
    [ '/usr/bin/perl', '-I/a', '-I/b', '/x/bin/skilletor' ], 'plain: -I per @INC dir, hooks left out' );
  is_deeply( Skilletor::CLI::self_command(), [ $^X, ( map { "-I$_" } grep { !ref } @INC ), $0 ], 'this run: plain perl' );
  ok( !Skilletor::CLI::is_packed(), 'not packed here' );
  {
    local $ENV{PAR_PROGNAME} = '/opt/skilletor';
    ok( !Skilletor::CLI::is_packed(), "PAR_PROGNAME inherited by a plain perl: no PAR loader, not packed" );
    local $INC{'PAR.pm'} = '/loader/0x1/PAR.pm';
    ok( Skilletor::CLI::is_packed(), "PAR's loader and PAR_PROGNAME: packed" );
    is_deeply( Skilletor::CLI::self_command(), ['/opt/skilletor'], 'and the binary runs itself' );
  }
};

# The child reports what it got – then waits for the go, so the spawn can only have returned
# without waiting for it.
subtest 'spawn_detached: returns at once; the program runs in its own session, stdio on /dev/null' => sub {
  my $tmp = tempdir;
  my ( $go, $report ) = ( "$tmp/go", "$tmp/report" );
  my $child = <<'END';
my ( $report, $go ) = @ARGV;
my @fd = map { my $l = readlink "/proc/self/fd/$_"; defined $l ? $l : '?' } 0 .. 2;
my $sid = -r '/proc/self/stat' ? ( split ' ', do { open my $f, '<', '/proc/self/stat'; local $/; <$f> } =~ s/\A.*\) //sr )[3] : '?';
open my $out, '>', "$report.tmp" or die;
print {$out} join( "\n", getpgrp(), $sid, @fd, $ENV{SKILLETOR_PROJECT_DIR} // '' ), "\n";
close $out;
for ( 1 .. 600 ) { last if -e $go; select undef, undef, undef, 0.05 }
rename "$report.tmp", $report;
END
  my $ok = spawn_detached( cmd => [ $^X, '-e', $child, $report, $go ], env => { %ENV, SKILLETOR_PROJECT_DIR => '/p' } );
  ok( $ok, 'started' );
  ok( !-e $report, 'and returned while the program waits' );
  path($go)->touch;
  my $deadline = Time::HiRes::time() + 30;
  Time::HiRes::sleep(0.05) until -e $report || Time::HiRes::time() > $deadline;
  my ( $pgrp, $sid, @rest ) = split /\n/, path($report)->slurp_raw;
  my $env = pop @rest;
  isnt( $pgrp, getpgrp(), 'a process group of its own: a kill of ours spares it' );
  SKIP: {
    skip 'no /proc', 1 if $sid eq '?';
    my $mine = ( split ' ', path('/proc/self/stat')->slurp_raw =~ s/\A.*\) //sr )[3];
    isnt( $sid, $mine, 'a session of its own' );
  }
  SKIP: {
    skip 'no /proc', 1 if $rest[0] eq '?';
    is_deeply( \@rest, [ ('/dev/null') x 3 ], 'stdin, stdout and stderr on /dev/null' );
  }
  is( $env, '/p', 'the given environment' );
};

# ---- the hook command, through bin/skilletor ---------------------------------------------------

# Run bin/skilletor with $stdin: { exit, stdout, stderr }. %opt: env (on top of a Claude-only
# HOME), cwd, removed (run from that directory, removed first), inc (the module dirs as -I:
# default this perl's, so the CLI loads what this test loads).
sub run_cli {
  my ( $m, $args, $stdin, %opt ) = @_;
  my %env = ( %ENV, HOME => $m->{home}, CODEX_HOME => "$m->{home}/.no-codex", %{ $opt{env} // {} } );
  delete @env{ grep { !defined $env{$_} } keys %env };
  my @perl = ( $^X, ( map { "-I$_" } @{ $opt{inc} // [ grep { !ref } @INC ] } ), "$BIN" );
  my @cmd = $opt{removed} ? ( 'sh', '-c', 'cd "$1" && rmdir "$1" && shift && exec "$@"', 'sh', $opt{removed}, @perl, @$args ) : ( @perl, @$args );
  path( $opt{removed} )->mkpath if $opt{removed};
  my $r = run_command( cmd => \@cmd, env => \%env, stdin => encode_text( $stdin // '' ), cwd => $opt{cwd} // $m->{root}, timeout_ms => 60_000 );
  return { exit => $r->{code}, stdout => Encode::decode( 'UTF-8', $r->{stdout} ), stderr => $r->{stderr} };
}

sub claude_marker { write_json( "$_[0]{home}/.claude.json", "{}\n" ) }

subtest 'bin/skilletor hook: a due prompt starts the real background sync, whose report the next prompt shows' => sub {
  my $m = machine();
  claude_marker($m);
  user_config( $m, { sources => { mine => { local => local_source( $m, 'foo' ) } }, install => { skills => ['foo@mine'] } } );
  # No PERL5LIB, every module dir as -I: the background child gets them from self_command alone.
  my %opt = ( env => { CLAUDE_PROJECT_DIR => $m->{project}, PERL5LIB => undef } );
  my $r = run_cli( $m, [ 'hook', 'user-prompt-submit' ], '{"cwd":"x"}', %opt );
  is_deeply( [ @$r{qw( exit stdout stderr )} ], [ 0, '', '' ], 'the prompt: nothing to say yet, exit 0' );
  my $pending = "$m->{home}/.claude/skilletor/pending-report.json";
  my $deadline = Time::HiRes::time() + 60;
  Time::HiRes::sleep(0.1) until ( -e $pending && path($pending)->slurp_raw =~ /\Q$m->{project}\E/ ) || Time::HiRes::time() > $deadline;
  ok( -f "$m->{home}/.claude/skills/foo/SKILL.md", 'the background sync installed' );
  $r = run_cli( $m, [ 'hook', 'user-prompt-submit' ], '{}', %opt );
  is( $r->{stdout},
    qq({"systemMessage":"skilletor: 1 item(s) updated","hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"skilletor synced items:\\n- skill foo\@mine: active now"}}\n),
    'the next prompt shows its report' );
  is( $r->{exit}, 0, 'exit 0' );
};

subtest 'bin/skilletor hook from a removed cwd exits 0 and still syncs (k164)' => sub {
  plan skip_all => 'Windows cannot remove a process cwd' if $^O eq 'MSWin32';
  my $m = machine();
  claude_marker($m);
  write_json( "$m->{root}/src/rules/house.md", "HOUSE\n" );
  user_config( $m, { sources => { s => { local => "$m->{root}/src" } }, install => { rules => ['house@s'] }, checkInterval => 0 } );
  my $gone = sub { "$m->{root}/gone-$_[0]" };
  my $r = run_cli( $m, [ 'hook', 'session-start' ], js_stringify( { source => 'startup', cwd => $m->{project} } ), removed => $gone->(1) );
  is_deeply( [ @$r{qw( exit stderr )} ], [ 0, '' ], 'exit 0, nothing on stderr' );
  like( $r->{stdout}, qr/\A\{"systemMessage":"skilletor: 1 item\(s\) updated/, 'the project from the input: synced' );
  is( path("$m->{home}/.claude/rules/.local.house.md")->slurp_raw, "HOUSE\n", 'installed' );
  for my $n ( [ 2, 'session-start' ], [ 3, 'user-prompt-submit' ] ) {
    my $r = run_cli( $m, [ 'hook', $n->[1] ], js_stringify( { cwd => $gone->( $n->[0] ) } ), removed => $gone->( $n->[0] ),
      env => { CLAUDE_PROJECT_DIR => $gone->( $n->[0] ) } );
    is_deeply( [ @$r{qw( exit stderr stdout )} ], [ 0, '', '' ], "$n->[1], CLAUDE_PROJECT_DIR the removed cwd: nothing to say" );
  }
  $r = run_cli( $m, [ 'hook', 'session-start' ], '{}', removed => $gone->(4) );
  is_deeply( [ @$r{qw( exit stderr )} ], [ 0, '' ], 'no project to go by: exit 0' );
  is( $r->{stdout}, qq({"systemMessage":"skilletor: ENOENT: process.cwd failed with error no such file or directory, uv_cwd"}\n),
    'and the one line that says the cwd is gone' );
};

subtest 'bin/skilletor hook whose project is known runs no git rev-parse (k164)' => sub {
  my $m = machine();
  claude_marker($m);
  user_config( $m, { checkInterval => 0 } );
  my $bin = "$m->{root}/bin";
  path($bin)->mkpath;
  path("$bin/git")->spew_raw("#!/bin/sh\nprintf '%s\\n' \"\$*\" >> '$m->{root}/git.log'\nexit 1\n");
  chmod 0755, "$bin/git";
  my $r = run_cli( $m, [ 'hook', 'user-prompt-submit' ], js_stringify( { cwd => $m->{project} } ),
    env => { CLAUDE_PROJECT_DIR => $m->{project}, PATH => "$bin:$ENV{PATH}" } );
  is_deeply( [ @$r{qw( exit stderr stdout )} ], [ 0, '', '' ], 'silent, exit 0' );
  ok( !-e "$m->{root}/git.log", 'git never called' );
};

subtest 'a hook whose own setup dies exits 0 with one warning line (k164)' => sub {
  no warnings 'redefine';
  local *Skilletor::CLI::_home = sub { die "no home directory (test fault)\n" };
  for my $event (qw( session-start user-prompt-submit )) {
    my $stdout = '';
    my $exit;
    {
      local *STDOUT;
      open( STDOUT, '>', \$stdout ) or die "stdout to a buffer: $!";
      local *STDIN;
      open( STDIN, '<', \'{}' ) or die "stdin from a buffer: $!";
      $exit = Skilletor::CLI::run( 'hook', $event );
    }
    is( $exit, 0, "$event: exit 0" );
    is( $stdout, qq({"systemMessage":"skilletor: no home directory (test fault)"}\n), "$event: the one line" );
  }
};

done_testing;
