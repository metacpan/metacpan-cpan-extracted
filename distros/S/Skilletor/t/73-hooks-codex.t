#!/usr/bin/env perl
# The hooks under `--harness codex` (k184) as the reference's hooks.test.ts (k50, k87) and
# prompt-move.test.ts (k149) hold them, black box through run_hook against temp dirs: SessionStart
# puts the Codex rules files first in a new session's context – the last good ones when the sync
# fails, none of a scope Codex is not a target of, none on resume – and names a file it cannot
# read; the prompt hook syncs the checkout a session moved into since its last turn, and a pending
# report joins that answer. The CLI's bytes are conformance/'s (cases 106-108).
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

sub out { js_stringify( $_[0] ) }

sub slurp { path( $_[0] )->slurp_utf8 }

# A machine for Codex's hooks, as hooks.test.ts's env() with its Codex context: a home and a
# project with `.claude/`, a state dir of their own, Codex alone in use (detected by its home),
# no git work tree, the background trigger recorded instead of started.
sub machine {
  my $tmp = tempdir;
  my $dir = Cwd::realpath("$tmp");
  my $m   = { tmp => $tmp, dir => $dir, home => "$dir/home", project => "$dir/proj", calls => [] };
  path("$m->{$_}/.claude")->mkpath for qw( home project );
  $m->{ctx} = {
    home        => $m->{home},
    project_dir => $m->{project},
    state_root  => "$dir/state",
    harness     => 'codex',
    engine      => {
      markers          => { claude => [], codex => [ $m->{home} ] },
      codex_home       => "$m->{home}/.codex",
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

sub ctx_with {
  my ( $m, %more ) = @_;
  my %engine = %{ delete $more{engine} // {} };
  return { %{ $m->{ctx} }, %more, engine => { %{ $m->{ctx}{engine} }, %engine } };
}

# ---- the rules context (k50, spec §14.8) ------------------------------------------------------

# hooks.test.ts's codexRules(): one user rule and one project rule, synced by a first
# SessionStart; that answer and both rules files.
sub codex_rules {
  my ( $m ) = @_;
  my $src = "$m->{dir}/rsrc";
  path("$src/rules")->mkpath;
  path("$src/rules/urule.md")->spew_utf8("User rule.\n");
  path("$src/rules/prule.md")->spew_utf8("Project rule.\n");
  user_config( $m, { sources => { mine => { local => $src } }, install => { rules => ['urule@mine'] } } );
  write_json( "$m->{project}/.claude/skilletor.json", { install => { rules => ['prule@mine'] } } );
  my $first = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  return {
    first   => $first,
    user    => slurp("$m->{home}/.codex/skilletor-rules.md"),
    project => slurp("$m->{project}/.codex/skilletor-rules.md"),
    src     => $src,
  };
}

subtest 'session-start puts the user, then the project rules file first, the sync report after' => sub {
  my $m = machine();
  my $r = codex_rules($m);
  like( $r->{user},    qr/\A<!-- skilletor:rules scope=user -->\n[\s\S]*User rule\.\n\z/,       'the user rules file' );
  like( $r->{project}, qr/\A<!-- skilletor:rules scope=project -->\n[\s\S]*Project rule\.\n\z/, 'the project rules file' );
  my $text = $r->{first}{hookSpecificOutput}{additionalContext} // '';
  my $head = "$r->{user}\n$r->{project}\nskilletor synced items:\n";
  is( substr( $text, 0, length $head ), $head, 'the context begins with the marker the pointer names, the report after' );
  is( $r->{first}{hookSpecificOutput}{hookEventName}, 'SessionStart', 'under its event' );
  like( $r->{first}{systemMessage} // '', qr/\Askilletor: 2 item\(s\) updated/, 'the line counts both' );
};

subtest 'a sync with warnings: rules first, the warnings after them' => sub {
  my $m = machine();
  my $r = codex_rules($m);
  user_config( $m, { sources => { mine => { local => $r->{src} } }, install => { rules => [ 'urule@mine', 'nope@mine' ] } } );
  my $text = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} )->{hookSpecificOutput}{additionalContext} // '';
  is( substr( $text, 0, length "$r->{user}\n$r->{project}\n" ), "$r->{user}\n$r->{project}\n", 'the rules first' );
  like( substr( $text, length "$r->{user}$r->{project}" ), qr/- warning: item not found in source mine: rule nope/, 'the warning after' );
};

subtest 'nothing changed: startup, clear, a missing or null source get exactly the rules; resume gets none' => sub {
  my $m = machine();
  my $r = codex_rules($m);
  my $want = out( js_ordered( hookSpecificOutput => js_ordered( hookEventName => 'SessionStart', additionalContext => "$r->{user}\n$r->{project}" ) ) );
  is( out( run_hook( 'session-start', $_, $m->{ctx} ) ), $want, js_stringify($_) )
    for { source => 'startup' }, { source => 'clear' }, {}, { source => undef };
  is( out( run_hook( 'session-start', $_, $m->{ctx} ) ), '{}', js_stringify($_) ) for { source => 'resume' }, { source => 7 }, { source => 'compact' };
};

subtest 'the prompt never appends the rules; without --harness codex session-start does not either' => sub {
  my $m = machine();
  codex_rules($m);
  is( out( run_hook( 'user-prompt-submit', {}, $m->{ctx} ) ), '{}', 'the prompt' );
  is( out( run_hook( 'session-start', { source => 'startup' }, ctx_with( $m, harness => undef ) ) ), '{}', 'no harness named' );
};

subtest 'a failed sync still gives the last good rules as the whole context; the warning is the line' => sub {
  my $m = machine();
  my $r = codex_rules($m);
  path("$m->{home}/.claude/skilletor.json")->spew_raw('{ broken');
  my $out = run_hook( 'session-start', { source => 'startup' }, $m->{ctx} );
  like( $out->{systemMessage} // '', qr/\Askilletor: /, 'the warning' );
  is( $out->{hookSpecificOutput}{additionalContext}, "$r->{user}\n$r->{project}", 'the rules alone' );
};

subtest 'a scope Codex is not a target of gives no rules, even with a stale file' => sub {
  my $m = machine();
  my $r = codex_rules($m);
  path("$m->{home}/marker-claude")->spew_raw('');
  my $both = ctx_with( $m, engine => { markers => { claude => ["$m->{home}/marker-claude"], codex => [ $m->{home} ] } } );
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['claude'] } );
  run_hook( 'session-start', { source => 'startup' }, $both );
  ok( !-e "$m->{project}/.codex/skilletor-rules.md", "the sync removed the project's file" );
  path("$m->{project}/.codex/skilletor-rules.md")->spew_raw("stale\n");
  is( run_hook( 'session-start', { source => 'startup' }, $both )->{hookSpecificOutput}{additionalContext}, $r->{user}, 'the user\'s rules alone' );
};

subtest 'a rules file that cannot be read is named in the line, escaped, in Node\'s words' => sub {
  my $m = machine();
  user_config( $m, {} );
  my $project = "$m->{dir}/proj\x{1b}[31mred\x{07}\x{202e}evil\nnext";
  path("$project/.codex/skilletor-rules.md")->mkpath;    # a directory: unreadable
  my $out = run_hook( 'session-start', { source => 'startup' }, ctx_with( $m, project_dir => $project ) );
  is( $out->{systemMessage},
    "skilletor: cannot read $m->{dir}/proj\\u001b[31mred\\u0007\\u202eevil\\nnext/.codex/skilletor-rules.md (EISDIR: illegal operation on a directory, read)",
    'one line, the name escaped' );
  ok( !exists $out->{hookSpecificOutput}, 'no context: no rules to give' );
  # A file the user may not read is drift the sync rewrites before the hook reads it, so its
  # message is pinned on the reader itself.
  SKIP: {
    skip 'root reads any file', 1 if $> == 0;
    my $file = "$m->{dir}/denied.md";
    path($file)->spew_raw("x\n");
    chmod 0, $file;
    is( ${ Skilletor::Hooks::_read_rules($file) }, "EACCES: permission denied, open '$file'", 'a file the user may not read: Node\'s words' );
    chmod 0644, $file;
  }
};

subtest 'without a project dir: the git top level of the cwd is the project' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  path("$m->{dir}/s/skills/bar")->mkpath;
  path("$m->{dir}/s/skills/bar/SKILL.md")->spew_utf8( skill('bar') );
  user_config( $m, { sources => { mine => { local => "$m->{dir}/s" } } } );
  my $repo = "$m->{dir}/repo";
  my $sub  = "$repo/src/deep";
  path($sub)->mkpath;
  write_json( "$repo/.claude/skilletor.json", { install => { skills => ['bar@mine'] } } );
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  my $out = run_hook( 'session-start', { hook_event_name => 'SessionStart', source => 'startup', cwd => $sub, session_id => 'x', model => 'gpt' },
    ctx_with( $m, project_dir => undef ) );
  is( $out->{hookSpecificOutput}{hookEventName}, 'SessionStart', 'under its event' );
  like( $out->{hookSpecificOutput}{additionalContext} // '', qr/skill bar\@mine \(codex\)/, 'the skill, for Codex' );
  ok( -f "$repo/.agents/skills/bar/SKILL.md", 'installed at the top level' );
  ok( !-e "$sub/.agents" && !-e "$sub/.claude", 'nothing in the cwd' );
};

# ---- the prompt follows a move (k149, spec §8, §14.5) ------------------------------------------

# prompt-move.test.ts's env: no project dir – Codex sets no CLAUDE_PROJECT_DIR – so the project
# is the git top level of the input's cwd.
sub prompt {
  my ( $m, $cwd, $session, $ctx ) = @_;
  return run_hook( 'user-prompt-submit',
    { hook_event_name => 'UserPromptSubmit', session_id => $session // 's1', ( defined $cwd ? ( cwd => $cwd ) : () ) },
    $ctx // ctx_with( $m, project_dir => undef ) );
}

sub local_source {
  my ( $m ) = @_;
  path("$m->{dir}/src/skills/foo")->mkpath;
  path("$m->{dir}/src/skills/foo/SKILL.md")->spew_utf8( skill('foo') );
  user_config( $m, { sources => { mine => { local => "$m->{dir}/src" } } } );
}

# `main` (the machine's project): a git checkout whose committed config installs `foo@mine`, where
# session `s1` started – its SessionStart synced main and recorded where it looked – with what that
# sync wrote and git tracks committed too. Then a plain `git worktree add`: the config, no lock,
# no items.
sub main_with_worktree {
  my ( $m ) = @_;
  local_source($m);
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['codex'], install => { skills => ['foo@mine'] } } );
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

subtest 'a prompt in a worktree without a lock syncs it first; line and context name it' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $wt = main_with_worktree($m);
  is( state($m)->session_cwd('s1'), $m->{project}, 'SessionStart recorded where it looked' );
  my $main_lock = slurp("$m->{project}/.claude/skilletor.lock.json");

  is( out( prompt( $m, $wt, 's1', ctx_with( $m, harness => undef ) ) ), '{}', 'Claude Code\'s prompt notices no move' );
  ok( !-e "$wt/.claude/skilletor.lock.json", 'and syncs nothing' );

  is( out( prompt( $m, $wt ) ),
    out( js_ordered(
      systemMessage      => "skilletor: 1 item(s) updated in $wt",
      hookSpecificOutput => js_ordered(
        hookEventName     => 'UserPromptSubmit',
        additionalContext => join( "\n", "skilletor: in $wt:", 'skilletor synced items:', '- skill foo@mine (codex): active from the next Codex session' ),
      ),
    ) ),
    'the one line and the context' );
  is( slurp("$wt/.agents/skills/foo/SKILL.md"), skill('foo'), 'the skill in the worktree' );
  is_deeply( [ keys %{ js_parse( slurp("$wt/.claude/skilletor.lock.json") ) } ], ['codex:skills/foo'], 'its own lock' );
  is( slurp("$m->{project}/.claude/skilletor.lock.json"), $main_lock, 'main as it was' );
  is( state($m)->session_cwd('s1'), $wt, 'the record follows' );

  is( out( prompt( $m, $wt, 's2' ) ), '{}', 'a session without a record looks once: the lock matches' );
  is( state($m)->session_cwd('s2'), $wt, 'and is recorded' );
};

subtest 'prompts within the same checkout sync nothing' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  local_source($m);
  write_json( "$m->{project}/.claude/skilletor.json", { targets => ['codex'], install => { skills => ['foo@mine'] } } );
  git_ok( $m->{project}, 'init', '-q', '-b', 'main' );
  state($m)->put_session_cwd( 's1', $m->{project} );
  my $sub = "$m->{project}/src/deep";
  path($sub)->mkpath;
  is( out( prompt( $m, $_ ) ), '{}', $_ ) for $m->{project}, $sub;
  is( state($m)->session_cwd('s1'), $sub, 'the record follows the cwd' );
  is( out( prompt( $m, $m->{project} ) ), '{}', 'and back' );
  ok( !-e "$m->{project}/.claude/skilletor.lock.json" && !-e "$m->{project}/.agents", 'no lock, no item' );
};

subtest 'a prompt in a directory without a skilletor project is a no-op' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  local_source($m);
  user_config( $m, { sources => { mine => { local => "$m->{dir}/src" } }, install => { skills => ['foo@mine'] } } );
  state($m)->put_session_cwd( 's1', $m->{project} );
  my ( $repo, $plain ) = ( "$m->{dir}/repo", "$m->{dir}/plain" );
  path($_)->mkpath for $repo, $plain;
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  is( out( prompt( $m, $_ ) ), '{}', $_ ) for $repo, $plain, $m->{home};
  ok( !-e "$repo/.claude" && !-e "$plain/.claude", 'no .claude made' );
  ok( !-e "$m->{home}/.agents", 'the user scope never syncs on a move' );
  is( out( prompt( $m, undef ) ), '{}', 'no cwd in the input' );
};

subtest 'one sync per move, none in the background beside it; a pending report joins its answer' => sub {
  my $m = machine();
  local $ENV{GIT_CEILING_DIRECTORIES} = $m->{dir};
  my $wt = main_with_worktree($m);
  ok( state($m)->is_due( $wt, 600 ), 'the worktree is due' );
  state($m)->put_pending_report( $wt, { systemMessage => 'skilletor: cannot reach source x' } );

  my $out = prompt( $m, $wt );
  is_deeply( $m->{calls}, [], 'no background sync' );
  ok( !state($m)->is_due( $wt, 600 ), 'the move marked it checked' );
  is( $out->{systemMessage}, "skilletor: cannot reach source x; skilletor: 1 item(s) updated in $wt", 'both lines' );
  is_deeply( [ split /\n/, $out->{hookSpecificOutput}{additionalContext} ],
    [ 'skilletor: cannot reach source x', "skilletor: in $wt:", 'skilletor synced items:', '- skill foo@mine (codex): active from the next Codex session' ],
    'both in the context, the line standing in for the report\'s' );
  is( state($m)->take_pending_report($wt), undef, 'the report taken' );

  state($m)->clear_checked($wt);
  is( out( prompt( $m, $m->{project} ) ), '{}', 'back to main' );
  is( out( prompt( $m, $wt ) ), '{}', 'into the worktree again: the lock matches' );
  is_deeply( $m->{calls}, [$wt], 'so the interval check starts its background sync' );
};

done_testing;
