#!/usr/bin/env perl
# The hooks under `--harness hermes` (k185) as the reference's hermes.test.ts and
# prompt-move.test.ts (k149, k152) hold them, black box through run_hook against temp dirs:
# SessionStart syncs for Hermes and, while `hermes` is no target, ends its answer with the line
# that says how to opt in; the prompt hook syncs the checkout a session moved into since its last
# turn, and names `hermes skills trust` once a skill Hermes loads landed there. The CLI's bytes
# are conformance/'s (cases 117-125).
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( git_ok write_json );

use Cwd ();
use Path::Tiny qw( path tempdir );
use Skilletor::Hooks qw( run_hook );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::State;

delete $ENV{CLAUDE_CONFIG_DIR};

sub skill { "---\nname: $_[0]\ndescription: $_[0]\n---\nBODY\n" }
sub out   { js_stringify( $_[0] ) }
sub slurp { path( $_[0] )->slurp_utf8 }

my $ACTIVE = 'active from the next Hermes session';
sub opt_in { 'skilletor: Hermes gets no skills: "hermes" is not in "targets"; to opt in, set "targets": '.$_[0].' in ~/.claude/skilletor.json' }
sub trust_line    { " — if Hermes does not trust this project yet: hermes skills trust $_[0]" }
sub trust_context { "- Hermes loads project skills only from a project it trusts; if this one is not yet, the user can run: hermes skills trust $_[0]" }

# A machine for Hermes' hooks, as hermes.test.ts's and prompt-move.test.ts's env(): a home and a
# project with `.claude/`, a state dir and a Hermes home of their own, the harnesses given in use
# by their markers (Hermes never is detected: the user config names it), no git work tree, the
# background trigger recorded instead of started.
sub machine {
  my ( @in_use ) = @_;
  my $tmp = tempdir;
  my $dir = Cwd::realpath("$tmp");
  my $m   = { tmp => $tmp, dir => $dir, home => "$dir/home", project => "$dir/proj", hermes => "$dir/hermes-home", calls => [] };
  path("$m->{$_}/.claude")->mkpath for qw( home project );
  path("$dir/marker-$_")->spew_raw('') for @in_use;
  $m->{ctx} = {
    home        => $m->{home},
    project_dir => $m->{project},
    state_root  => "$dir/state",
    harness     => 'hermes',
    engine      => {
      markers          => { claude => ["$dir/marker-claude"], codex => ["$dir/marker-codex"] },
      codex_home       => "$m->{home}/.codex",
      hermes_home      => $m->{hermes},
      is_git_work_tree => sub { 0 },
      git_tracked      => sub { [] },
      host             => { name => 'box', os => 'linux' },
      user             => { name => 'getty', home => $m->{home} },
    },
    background => sub { push @{ $m->{calls} }, $_[0]{project_dir} // '' },
  };
  return $m;
}

sub user_config { write_json( "$_[0]{home}/.claude/skilletor.json", $_[1] ) }

sub state { Skilletor::State->new( root => $_[0]{ctx}{state_root} ) }

sub ctx_with { my ( $m, %more ) = @_; return { %{ $m->{ctx} }, %more } }

sub local_source {
  my ( $m ) = @_;
  path("$m->{dir}/src/skills/foo")->mkpath;
  path("$m->{dir}/src/skills/foo/SKILL.md")->spew_utf8( skill('foo') );
  return "$m->{dir}/src";
}

# ---- SessionStart (spec §16.2, §16.4) ----------------------------------------------------------

subtest 'session-start for Hermes: the sync, and the report the plugin hands to the model' => sub {
  my $m = machine();
  user_config( $m, { targets => ['hermes'], sources => { mine => { local => local_source($m) } }, install => { skills => ['foo@mine'] } } );
  my $out = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  is( out($out),
    out( js_ordered(
      systemMessage      => 'skilletor: 1 item(s) updated',
      hookSpecificOutput => js_ordered( hookEventName => 'SessionStart', additionalContext => "skilletor synced items:\n- skill foo\@mine (hermes): $ACTIVE" ),
    ) ),
    'the line and the context' );
  ok( -e "$m->{hermes}/skills/foo/SKILL.md", 'installed in the Hermes home' );
  is( out( run_hook( 'session-start', { source => 'startup' }, $m->{ctx} ) ), '{}', 'nothing changed: silent' );
};

subtest 'session-start under Hermes while hermes is no target: one line says how to opt in' => sub {
  my $m = machine('claude');
  my %declared = ( sources => { mine => { local => local_source($m) } }, install => { skills => ['foo@mine'] } );
  user_config( $m, {%declared} );
  my $hint = opt_in('["claude", "hermes"]');
  my $out = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  is( out($out),
    out( js_ordered(
      systemMessage      => "skilletor: 1 item(s) updated; $hint",
      hookSpecificOutput => js_ordered( hookEventName => 'SessionStart', additionalContext => "skilletor synced items:\n- skill foo\@mine: active now\n$hint" ),
    ) ),
    'after the line, and after the context' );
  ok( !-e "$m->{hermes}/skills", 'nothing for Hermes' );
  is( out( run_hook( 'session-start', { source => 'resume' }, $m->{ctx} ) ), out( { systemMessage => $hint } ), 'nothing changed: the line alone, once' );
  is( out( run_hook( 'session-start', { source => 'startup' }, ctx_with( $m, harness => undef ) ) ), '{}', 'not under Claude Code' );
  is( out( run_hook( 'session-start', { source => 'startup' }, ctx_with( $m, harness => 'codex' ) ) ), '{}', 'nor under Codex' );
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), '{}', 'nor on a turn' );

  path("$m->{home}/.claude/skilletor.json")->spew_raw('{ broken');
  my $broken = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  like( $broken->{systemMessage}, qr/\Askilletor: /, 'a config error is its own line' );
  unlike( $broken->{systemMessage}, qr/to opt in/, 'without the hint' );
  ok( !exists $broken->{hookSpecificOutput}, 'and no context' );

  user_config( $m, { targets => [ 'claude', 'hermes' ], %declared } );
  is( run_hook( 'session-start', { source => 'startup' }, $m->{ctx} )->{systemMessage}, 'skilletor: 1 item(s) updated', 'opted in: no line' );
  ok( -e "$m->{hermes}/skills/foo/SKILL.md", 'and Hermes gets its copy' );
};

subtest 'after a sync\'s warning: the opt-in line ends the line and the context' => sub {
  my $m = machine('claude');
  user_config( $m, { sources => { mine => { local => "$m->{dir}/nowhere" } }, install => { skills => ['foo@mine'] } } );
  my $out = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  like( $out->{systemMessage}, qr/\Askilletor: 1 warning\(s\); \Q${\ opt_in('["claude", "hermes"]')}\E\z/, 'joined with "; "' );
  like( $out->{hookSpecificOutput}{additionalContext}, qr/\n\Q${\ opt_in('["claude", "hermes"]')}\E\z/, 'the context ends with it' );
};

# ---- the prompt follows a move (k149, k152, spec §8, §16.4) -------------------------------------

# prompt-move.test.ts's env under Hermes: no project dir – the Hermes plugin drops
# CLAUDE_PROJECT_DIR – so the project is the git top level of the input's cwd.
sub prompt {
  my ( $m, $cwd, $session, $ctx ) = @_;
  return run_hook( 'user-prompt-submit',
    { hook_event_name => 'UserPromptSubmit', session_id => $session // 's1', ( defined $cwd ? ( cwd => $cwd ) : () ) },
    $ctx // ctx_with( $m, project_dir => undef ) );
}

# `main` (the machine's project): a git checkout whose committed config installs `foo@mine`, where
# session `s1` started; then a plain `git worktree add`: the config, no lock, no items.
sub main_with_worktree {
  my ( $m ) = @_;
  user_config( $m, { targets => ['hermes'], sources => { mine => { local => local_source($m) } } } );
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['hermes'], install => { skills => ['foo@mine'] } } );
  git_ok( $m->{project}, 'init', '-q', '-b', 'main' );
  my $started = run_hook( 'session-start', { source => 'startup', cwd => $m->{project}, session_id => 's1' }, ctx_with( $m, project_dir => undef ) );
  like( $started->{systemMessage} // '', qr/item\(s\) updated/, "main's SessionStart syncs it" );
  git_ok( $m->{project}, 'add', '-A' );
  git_ok( $m->{project}, 'commit', '-qm', 'config and blocks' );
  my $wt = "$m->{project}/.claude/worktrees/backlog";
  git_ok( $m->{project}, 'worktree', 'add', '-q', '-b', 'backlog', $wt );
  ok( -e "$wt/.claude/skilletor.json" && !-e "$wt/.claude/skilletor.lock.json", 'the worktree: the config, no lock' );
  return $wt;
}

subtest 'a prompt in a worktree without a lock syncs it first; line and context name it and the trust' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $wt = main_with_worktree($m);
  is( state($m)->session_cwd('s1'), $m->{project}, 'SessionStart recorded where it looked' );
  my $main_lock = slurp("$m->{project}/.claude/skilletor.lock.json");

  is( out( prompt( $m, $wt, 's1', ctx_with( $m, harness => undef, project_dir => $m->{project} ) ) ), '{}', 'Claude Code\'s prompt notices no move' );
  ok( !-e "$wt/.claude/skilletor.lock.json", 'and syncs nothing' );

  is( out( prompt( $m, $wt ) ),
    out( js_ordered(
      systemMessage      => "skilletor: 1 item(s) updated in $wt".trust_line($wt),
      hookSpecificOutput => js_ordered(
        hookEventName     => 'UserPromptSubmit',
        additionalContext => join( "\n", "skilletor: in $wt:", 'skilletor synced items:', "- skill foo\@mine (hermes): $ACTIVE", trust_context($wt) ),
      ),
    ) ),
    'the one line and the context, both with the trust' );
  is( slurp("$wt/.hermes/skills/foo/SKILL.md"), skill('foo'), 'the skill in the worktree' );
  is_deeply( [ keys %{ js_parse( slurp("$wt/.claude/skilletor.lock.json") ) } ], ['hermes:skills/foo'], 'its own lock' );
  is( slurp("$m->{project}/.claude/skilletor.lock.json"), $main_lock, 'main as it was' );
  is( state($m)->session_cwd('s1'), $wt, 'the record follows' );
  is( out( prompt( $m, $wt, 's2' ) ), '{}', 'a session without a record looks once: the lock matches' );
};

subtest 'prompts within the same checkout, or outside any project, sync nothing' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  user_config( $m, { targets => ['hermes'], sources => { mine => { local => local_source($m) } }, install => { skills => ['foo@mine'] } } );
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['hermes'], install => { skills => ['foo@mine'] } } );
  git_ok( $m->{project}, 'init', '-q', '-b', 'main' );
  state($m)->put_session_cwd( 's1', $m->{project} );
  my $sub = "$m->{project}/src/deep";
  path($sub)->mkpath;
  is( out( prompt( $m, $_ ) ), '{}', $_ ) for $m->{project}, $sub;
  ok( !-e "$m->{project}/.claude/skilletor.lock.json" && !-e "$m->{project}/.hermes", 'no lock, no item' );
  my ( $repo, $plain ) = ( "$m->{dir}/repo", "$m->{dir}/plain" );
  path($_)->mkpath for $repo, $plain;
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  is( out( prompt( $m, $_ ) ), '{}', $_ ) for $repo, $plain, $m->{home};
  ok( !-e "$repo/.claude" && !-e "$plain/.claude", 'no .claude made' );
  ok( !-e "$m->{hermes}/skills", 'the user scope never syncs on a move' );
};

subtest 'one sync per move, none in the background beside it; a pending report joins its answer' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $wt = main_with_worktree($m);
  state($m)->put_pending_report( $wt, { systemMessage => 'skilletor: cannot reach source x' } );
  my $out = prompt( $m, $wt );
  is_deeply( $m->{calls}, [], 'no background sync' );
  is( $out->{systemMessage}, "skilletor: cannot reach source x; skilletor: 1 item(s) updated in $wt".trust_line($wt), 'both lines' );
  is_deeply( [ split /\n/, $out->{hookSpecificOutput}{additionalContext} ],
    [ 'skilletor: cannot reach source x', "skilletor: in $wt:", 'skilletor synced items:', "- skill foo\@mine (hermes): $ACTIVE", trust_context($wt) ],
    'both in the context, the line standing in for the report\'s' );
};

# k152: the trust hint comes with a move that added or updated a skill Hermes loads from that
# checkout – its own copy, or the Codex copy it reads while `codex` is a target too – and with
# nothing else: a move that installed only a Claude Code agent or only removed a skill says so
# without it.
subtest 'the trust hint comes with a skill Hermes loads, not with an agent or a removal' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $src = local_source($m);
  path("$src/agents")->mkpath;
  path("$src/agents/bar.md")->spew_utf8("---\ndescription: bar\n---\nBODY\n");
  my $sources = { mine => { local => $src } };
  my $checkout = sub {
    my ( $name, $install, $targets ) = @_;
    my $dir = "$m->{dir}/$name";
    write_json( "$dir/.claude/skilletor.json", { targets => $targets, install => $install } );
    git_ok( $dir, 'init', '-q', '-b', 'main' );
    return $dir;
  };
  state($m)->put_session_cwd( 's1', $m->{project} );

  user_config( $m, { targets => [ 'codex', 'hermes' ], sources => $sources } );
  my $via_codex = $checkout->( 'via-codex', { skills => ['foo@mine'] }, [ 'codex', 'hermes' ] );
  my $codex_copy = prompt( $m, $via_codex );
  ok( -e "$via_codex/.agents/skills/foo/SKILL.md" && !-e "$via_codex/.hermes", 'the Codex copy serves Hermes' );
  is( $codex_copy->{systemMessage},
    "skilletor: 1 item(s) updated, .claude/.gitignore, .worktreeinclude updated — commit them in $via_codex".trust_line($via_codex), 'the line names the trust' );
  is_deeply( [ split /\n/, $codex_copy->{hookSpecificOutput}{additionalContext} ],
    [ "skilletor: in $via_codex:", 'skilletor synced items:', '- skill foo@mine (codex): active from the next Codex session',
      '- .claude/.gitignore updated — commit it', '- .worktreeinclude updated — commit it', trust_context($via_codex) ],
    'and so does the context' );

  user_config( $m, { targets => [ 'claude', 'hermes' ], sources => $sources } );
  my $agent_only = $checkout->( 'agent-only', { agents => ['bar@mine'] }, [ 'claude', 'hermes' ] );
  my $agent = prompt( $m, $agent_only );
  ok( -e "$agent_only/.claude/agents/.local.bar.md", 'the agent for Claude Code' );
  like( $agent->{systemMessage} // '', qr/\Askilletor: 1 item\(s\) updated\b/, 'synced' );
  unlike( out($agent), qr/hermes skills trust/, 'no trust hint' );

  user_config( $m, { targets => ['hermes'], sources => $sources } );
  my $removal = $checkout->( 'removal', { skills => ['foo@mine'] }, ['hermes'] );
  like( prompt( $m, $removal )->{systemMessage} // '', qr/hermes skills trust/, 'a skill landed: the hint' );
  write_json( "$removal/.claude/skilletor.json", { install => {} } );
  is( out( prompt( $m, $m->{project} ) ), '{}', 'back to main' );
  is( out( prompt( $m, $removal ) ), out( { systemMessage => "skilletor: 1 removed in $removal" } ), 'a removal: no hint' );
  ok( !-e "$removal/.hermes/skills/foo/SKILL.md", 'removed' );
};

subtest 'Claude Code\'s move hooks name no Hermes trust, even with Hermes a target' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $wt = main_with_worktree($m);
  my $claude = ctx_with( $m, harness => undef, project_dir => undef );
  is( out( run_hook( 'post-tool-use', { cwd => $wt, session_id => 's1', hook_event_name => 'PostToolUse', tool_name => 'Bash' }, $claude ) ),
    out( js_ordered(
      systemMessage      => "skilletor: 1 item(s) updated in $wt",
      hookSpecificOutput => js_ordered( hookEventName => 'PostToolUse', additionalContext => "skilletor: in $wt:\nskilletor synced items:\n- skill foo\@mine (hermes): $ACTIVE" ),
    ) ),
    'PostToolUse: line and context, no hint' );
  my $wt2 = "$m->{project}/.claude/worktrees/second";
  git_ok( $m->{project}, 'worktree', 'add', '-q', '-b', 'second', $wt2 );
  is( out( run_hook( 'cwd-changed', { cwd => $wt, old_cwd => $wt, new_cwd => $wt2, hook_event_name => 'CwdChanged' }, $claude ) ),
    out( { systemMessage => "skilletor: 1 item(s) updated in $wt2" } ), 'CwdChanged: the line, no hint' );
  is( slurp("$wt2/.hermes/skills/foo/SKILL.md"), skill('foo'), 'the Hermes copy in it' );
};

done_testing;
