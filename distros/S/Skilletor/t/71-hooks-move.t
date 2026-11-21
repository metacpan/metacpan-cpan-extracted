#!/usr/bin/env perl
# The checkout-move hooks (k182, the reference's k147, spec §8) as cwd-changed.test.ts holds them:
# CwdChanged and PostToolUse sync the checkout a session moves into – its git top level, never
# the session's own project (`project_dir` plays CLAUDE_PROJECT_DIR) – black box through
# run_hook, against temp dirs. What only this engine's own test can pin: the deadline (injected),
# the sync lock held by another run, and the two hooks of one `cd` racing for it. The CLI's bytes
# are conformance/'s (cases 60-64).
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( bare_remote git_ok write_json );

use Cwd ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::Hooks qw( run_hook );
use Skilletor::JSON qw( js_ordered js_parse js_stringify );
use Skilletor::State;

delete $ENV{CLAUDE_CONFIG_DIR};

sub skill { "---\nname: $_[0]\ndescription: $_[0]\n---\nBODY\n" }

sub out { js_stringify( $_[0] ) }

# The machine of cwd-changed.test.ts's env(): a home and the session's project `main`, both with
# `.claude/`, a state dir of their own, Claude Code alone in use, no work tree for the user scope,
# and a background trigger that must never run.
sub machine {
  my $tmp = tempdir;
  my $dir = Cwd::realpath("$tmp");
  my $m = { tmp => $tmp, dir => $dir, home => "$dir/home", main => "$dir/main" };
  path("$m->{$_}/.claude")->mkpath for qw( home main );
  $m->{ctx} = {
    home        => $m->{home},
    project_dir => $m->{main},    # CLAUDE_PROJECT_DIR: the session started in `main`
    state_root  => "$dir/state",
    engine      => {
      markers          => { claude => [ $m->{home} ], codex => [] },
      is_git_work_tree => sub { 0 },    # never the real location of the temp dir
      host             => { name => 'box', os => 'linux' },
      user             => { name => 'getty', home => $m->{home} },
    },
    background => sub { fail('a move never starts a background sync') },
  };
  return $m;
}

sub user_config { write_json( "$_[0]{home}/.claude/skilletor.json", $_[1] ) }

sub state { Skilletor::State->new( root => $_[0]{ctx}{state_root} ) }

sub slurp { path( $_[0] )->slurp_raw }

# A local source with skills `foo` and `bar`; its path.
sub local_source {
  my ( $m ) = @_;
  write_json( "$m->{dir}/src/skills/$_/SKILL.md", skill($_) ) for qw( foo bar );
  return "$m->{dir}/src";
}

# A bare git repo serving skill `foo`: { url, gone }.
sub git_source {
  my ( $m ) = @_;
  path("$m->{dir}/git")->mkpath;
  my $r = bare_remote("$m->{dir}/git");
  $r->{commit}->( { 'skills/foo/SKILL.md' => skill('foo') }, 'init' );
  return $r;
}

# `main`: a git checkout whose committed config declares `install`, synced by its SessionStart,
# with the blocks that sync wrote committed too; then a plain `git worktree add` under
# `.claude/worktrees/`: the config, no lock, no items.
sub main_with_worktree {
  my ( $m, $install ) = @_;
  write_json( "$m->{main}/.claude/skilletor.json", { install => $install } );
  git_ok( $m->{main}, 'init', '-q', '-b', 'main' );
  git_ok( $m->{main}, 'add', '.claude/skilletor.json' );
  git_ok( $m->{main}, 'commit', '-qm', 'config' );
  my $started = run_hook( 'session-start', { source => 'startup', cwd => $m->{main}, session_id => 's1' }, $m->{ctx} );
  like( $started->{systemMessage} // '', qr/item\(s\) updated/, "main's SessionStart syncs it" );
  git_ok( $m->{main}, 'add', '.claude/.gitignore', '.worktreeinclude' );
  git_ok( $m->{main}, 'commit', '-qm', 'blocks' );
  return add_worktree( $m, 'backlog' );
}

sub add_worktree {
  my ( $m, $name ) = @_;
  my $wt = "$m->{main}/.claude/worktrees/$name";
  git_ok( $m->{main}, 'worktree', 'add', '-q', '-b', $name, $wt );
  ok( -e "$wt/.claude/skilletor.json" && !-e "$wt/.claude/skilletor.lock.json", "worktree $name: the config, no lock" );
  return $wt;
}

sub move { { hook_event_name => 'CwdChanged', old_cwd => $_[0], new_cwd => $_[1], cwd => $_[1], session_id => 's1' } }

# PostToolUse after a Bash `cd`: `cwd` is where the command left the session; no old cwd.
sub bash_cd {
  my ( $cwd, $session ) = @_;
  return { hook_event_name => 'PostToolUse', tool_name => 'Bash', tool_input => { command => "cd $cwd" }, cwd => $cwd, session_id => $session // 's1' };
}

sub lock_keys { [ sort keys %{ js_parse( slurp( "$_[0]/.claude/skilletor.lock.json" ) ) } ] }

# ---- CwdChanged ----------------------------------------------------------------------------

# A `cd` into a worktree that has the config but no lock syncs the worktree's project scope –
# both items land there, with its own lock – and answers with the one line naming the worktree,
# no context (CwdChanged takes none). The session's project and its cwd record stay as they were.
subtest 'a move into a worktree without a lock syncs it, one line names the worktree' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => [ 'foo@mine', 'bar@mine' ] } );
  my $main_lock = slurp("$m->{main}/.claude/skilletor.lock.json");

  is( out( run_hook( 'cwd-changed', move( $m->{main}, $wt ), $m->{ctx} ) ), out( js_ordered( systemMessage => "skilletor: 2 item(s) updated in $wt" ) ),
    'the line alone' );
  is( slurp("$wt/.claude/skills/$_/SKILL.md"), skill($_), "$_ installed in the worktree" ) for qw( foo bar );
  is_deeply( lock_keys($wt), [ 'skills/bar', 'skills/foo' ], 'its own lock' );
  is( slurp("$m->{main}/.claude/skilletor.lock.json"), $main_lock, "the session's project untouched" );
  is( state($m)->session_cwd('s1'), $m->{main}, 'no session record written' );
};

# A move within one checkout – into a subdirectory and back – syncs nothing, though the checkout
# has no lock and a sync would install there.
subtest 'a move within the same checkout syncs nothing' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  write_json( "$m->{main}/.claude/skilletor.json", { install => { skills => ['foo@mine'] } } );
  git_ok( $m->{main}, 'init', '-q', '-b', 'main' );
  my $sub = "$m->{main}/src/deep";
  path($sub)->mkpath;
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $sub ), $m->{ctx} ) ), '{}', 'into a subdirectory' );
  is( out( run_hook( 'cwd-changed', move( $sub, $m->{main} ), $m->{ctx} ) ), '{}', 'and back' );
  ok( !-e "$m->{main}/.claude/skilletor.lock.json", 'no lock' );
  ok( !-e "$m->{main}/.claude/skills", 'no items' );
};

# A move into a directory that is no skilletor project – a git checkout without a config, a plain
# directory, the home dir (whose `.claude/skilletor.json` is the user config) – is silent and
# writes nothing there; nor does input without a usable cwd.
subtest 'a move into a directory without a skilletor project is a no-op' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } }, install => { skills => ['foo@mine'] } } );
  my ( $repo, $plain ) = ( "$m->{dir}/repo", "$m->{dir}/plain" );
  path($_)->mkpath for $repo, $plain;
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $_ ), $m->{ctx} ) ), '{}', $_ ) for $repo, $plain, $m->{home};
  ok( !-e "$repo/.claude",  'nothing in the checkout' );
  ok( !-e "$plain/.claude", 'nothing in the plain dir' );
  ok( !-e "$m->{home}/.claude/skills", 'the user scope never syncs on a move' );
  is( out( run_hook( 'cwd-changed', { hook_event_name => 'CwdChanged' }, $m->{ctx} ) ), '{}', 'no cwd' );
  is( out( run_hook( 'cwd-changed', { new_cwd => 42 }, $m->{ctx} ) ), '{}', 'a cwd that is no string' );
};

# A checkout whose project config declares its own, untrusted source gets the one line naming the
# checkout and the `skilletor trust` to run there; nothing is fetched or installed. Once trusted,
# the next move into it installs.
subtest 'a move into a checkout with an untrusted source warns and fetches nothing' => sub {
  my $m = machine();
  user_config( $m, {} );
  my $url = git_source($m)->{url};
  my $other = "$m->{dir}/other";
  write_json( "$other/.claude/skilletor.json", { sources => { team => { git => $url } }, install => { skills => ['foo@team'] } } );
  git_ok( $other, 'init', '-q', '-b', 'main' );

  is( out( run_hook( 'cwd-changed', move( $m->{main}, $other ), $m->{ctx} ) ),
    out( js_ordered( systemMessage => "skilletor: 1 warning(s) in $other — run there: skilletor trust team" ) ), 'the line with the command' );
  ok( !-e "$m->{ctx}{state_root}/cache", 'nothing fetched' );
  ok( !-e "$other/.claude/skills" && !-e "$other/.claude/skilletor.lock.json", 'nothing installed, no lock' );

  state($m)->trust( team => { kind => 'git', address => $url } );
  like( run_hook( 'cwd-changed', move( $m->{main}, $other ), $m->{ctx} )->{systemMessage} // '',
    qr/\Askilletor: 1 item\(s\) updated, .* in \Q$other\E\z/, 'trusted: the next move installs' );
  is( slurp("$other/.claude/skills/foo/SKILL.md"), skill('foo'), 'foo there' );
};

# Once a worktree's lock matches its config, a move into it leaves it alone and asks no source –
# its git remote is gone, and a move that asked would warn, as SessionStart there does (the
# control) – so the move is silent and the lock unchanged.
subtest "a move into a checkout whose lock matches its config: no sync, no source asked" => sub {
  my $m = machine();
  my $remote = git_source($m);
  user_config( $m, { sources => { team => { git => $remote->{url} } } } );
  my $wt = main_with_worktree( $m, { skills => ['foo@team'] } );
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $wt ), $m->{ctx} ) ), out( js_ordered( systemMessage => "skilletor: 1 item(s) updated in $wt" ) ),
    'the first move syncs' );
  my $lock = slurp("$wt/.claude/skilletor.lock.json");

  $remote->{gone}->();
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $wt ), $m->{ctx} ) ), '{}', 'the next: silent' );
  is( slurp("$wt/.claude/skilletor.lock.json"), $lock, 'lock unchanged' );
  like( run_hook( 'session-start', { source => 'startup', cwd => $wt }, { %{ $m->{ctx} }, project_dir => $wt } )->{systemMessage} // '',
    qr/\Askilletor: source team: git ls-remote -- /, "control: SessionStart there asks the source" );
};

# A config error in the checkout moved into is the one line naming the checkout, the error and
# `skilletor sync` to run there; nothing is written.
subtest 'a config error in the checkout moved into: one line with the fix, nothing written' => sub {
  my $m = machine();
  user_config( $m, {} );
  my $other = "$m->{dir}/other";
  write_json( "$other/.claude/skilletor.json", { install => { skills => ['foo'] } } );    # no @source
  git_ok( $other, 'init', '-q', '-b', 'main' );
  my $out = run_hook( 'cwd-changed', move( $m->{main}, $other ), $m->{ctx} );
  like( $out->{systemMessage} // '', qr/\Askilletor: cannot sync \Q$other\E: .*skilletor\.json.* — run there: skilletor sync\z/, 'the line' );
  ok( !exists $out->{hookSpecificOutput}, 'no context' );
  is_deeply( [ map { $_->basename } path("$other/.claude")->children ], ['skilletor.json'], 'nothing written' );
};

# A move whose sources are resolved only after its deadline writes nothing – no lock, no item, no
# block – so the hook's own timeout can never kill it midway; the line says so.
subtest "past its deadline a move's sync writes nothing and says so" => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => ['foo@mine'] } );
  my $past = int( Time::HiRes::time() * 1000 ) - 1;
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $wt ), { %{ $m->{ctx} }, deadline => $past } ) ),
    out( js_ordered( systemMessage => "skilletor: cannot sync $wt: sync stopped before applying the project scope: its sources took too long — run there: skilletor sync" ) ),
    'the line' );
  ok( !-e "$wt/.claude/skilletor.lock.json" && !-e "$wt/.claude/skills", 'nothing written' );
  is( out( run_hook( 'cwd-changed', move( $m->{main}, $wt ), $m->{ctx} ) ), out( js_ordered( systemMessage => "skilletor: 1 item(s) updated in $wt" ) ),
    'the next move, in time, installs' );
};

# ---- PostToolUse: the awaited move hook, on a Bash call with a `cd` --------------------------

# A `cd` into a worktree without a lock syncs it before the hook returns, and answers with the line
# for the user and a context for the model, its first line naming the worktree. The session's
# record moves to the worktree, which is marked checked; the session's own project is left alone.
subtest 'PostToolUse after a cd into a worktree without a lock syncs it, with a context for the model' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => [ 'foo@mine', 'bar@mine' ] } );
  my $main_lock = slurp("$m->{main}/.claude/skilletor.lock.json");

  is( out( run_hook( 'post-tool-use', bash_cd($wt), $m->{ctx} ) ),
    out( js_ordered(
      systemMessage      => "skilletor: 2 item(s) updated in $wt",
      hookSpecificOutput => js_ordered(
        hookEventName     => 'PostToolUse',
        additionalContext => join( "\n", "skilletor: in $wt:", 'skilletor synced items:', '- skill foo@mine: active now', '- skill bar@mine: active now' ),
      ),
    ) ),
    'the line and the context' );
  is( slurp("$wt/.claude/skills/$_/SKILL.md"), skill($_), "$_ installed" ) for qw( foo bar );
  is( slurp("$m->{main}/.claude/skilletor.lock.json"), $main_lock, "the session's project untouched" );
  is( state($m)->session_cwd('s1'), $wt, 'the record moved' );
  ok( !state($m)->is_due( $wt, 3600 ), 'the worktree is marked checked' );
};

# Within the checkout its SessionStart looked at, a `cd` asks nothing – not even when the lock lags
# its config (a skill added since): the session's record says it is the same checkout. A `cd`
# into another checkout still syncs it.
subtest 'PostToolUse after a cd within the same checkout syncs nothing' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => ['foo@mine'] } );
  write_json( "$m->{main}/.claude/skilletor.json", { install => { skills => [ 'foo@mine', 'bar@mine' ] } } );
  my $sub = "$m->{main}/src/deep";
  path($sub)->mkpath;
  is( out( run_hook( 'post-tool-use', bash_cd($sub), $m->{ctx} ) ), '{}', 'into a subdirectory' );
  is( out( run_hook( 'post-tool-use', bash_cd( $m->{main} ), $m->{ctx} ) ), '{}', 'back' );
  is( out( run_hook( 'post-tool-use', bash_cd( $m->{main} ), $m->{ctx} ) ), '{}', '`cd . && …`: the same cwd' );
  ok( !-e "$m->{main}/.claude/skills/bar", 'bar not installed' );
  is( run_hook( 'post-tool-use', bash_cd($wt), $m->{ctx} )->{systemMessage}, "skilletor: 1 item(s) updated in $wt", 'control: the worktree syncs' );
};

subtest 'PostToolUse after a cd into a directory without a skilletor project is a no-op' => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } }, install => { skills => ['foo@mine'] } } );
  my ( $repo, $plain ) = ( "$m->{dir}/repo", "$m->{dir}/plain" );
  path($_)->mkpath for $repo, $plain;
  git_ok( $repo, 'init', '-q', '-b', 'main' );
  is( out( run_hook( 'post-tool-use', bash_cd( $_, "s-$_" ), $m->{ctx} ) ), '{}', $_ ) for $repo, $plain, $m->{home};
  ok( !-e "$repo/.claude" && !-e "$plain/.claude", 'nothing written there' );
  ok( !-e "$m->{home}/.claude/skills", 'the user scope never syncs on a move' );
  is( out( run_hook( 'post-tool-use', { hook_event_name => 'PostToolUse', session_id => 's1' }, $m->{ctx} ) ), '{}', 'no cwd' );
  is( out( run_hook( 'post-tool-use', { cwd => 42 }, $m->{ctx} ) ), '{}', 'a cwd that is no string' );
};

# A `cd` into a checkout whose own source is untrusted: the line naming the checkout and the
# `skilletor trust` to run there, the model the same in its context; nothing fetched or installed.
# A further `cd … && …` there says it no more.
subtest 'PostToolUse after a cd into a checkout with an untrusted source warns once, fetches nothing' => sub {
  my $m = machine();
  user_config( $m, {} );
  my $url = git_source($m)->{url};
  my $other = "$m->{dir}/other";
  write_json( "$other/.claude/skilletor.json", { sources => { team => { git => $url } }, install => { skills => ['foo@team'] } } );
  git_ok( $other, 'init', '-q', '-b', 'main' );

  is( out( run_hook( 'post-tool-use', bash_cd($other), $m->{ctx} ) ),
    out( js_ordered(
      systemMessage      => "skilletor: 1 warning(s) in $other — run there: skilletor trust team",
      hookSpecificOutput => js_ordered(
        hookEventName     => 'PostToolUse',
        additionalContext => "skilletor: in $other:\n- untrusted source team (git $url); run: skilletor trust team",
      ),
    ) ),
    'the line and the context' );
  ok( !-e "$m->{ctx}{state_root}/cache", 'nothing fetched' );
  ok( !-e "$other/.claude/skills" && !-e "$other/.claude/skilletor.lock.json", 'nothing installed' );
  is( out( run_hook( 'post-tool-use', bash_cd($other), $m->{ctx} ) ), '{}', 'said once' );
};

# ---- the sync lock -------------------------------------------------------------------------

# Run a hook in a child process; its output lands in $file as JSON. Returns the pid. $then runs
# in the child after the hook returned, with the output.
sub hook_in_child {
  my ( $event, $input, $ctx, $file, $then ) = @_;
  my $pid = fork // die "fork: $!";
  return $pid if $pid;
  my $ok = eval {
    my $out = run_hook( $event, $input, $ctx );
    $then->($out) if $then;
    path("$file.tmp")->spew_raw( js_stringify($out) );
    rename "$file.tmp", $file or die "rename: $!";
    1;
  };
  POSIX::_exit( $ok ? 0 : 1 );
}

sub reap { waitpid $_[0], 0; return $? }

# Claude Code fires CwdChanged and PostToolUse together for one `cd`: both find the worktree's lock
# missing, one syncs while the other waits on the sync lock (held here at first, so both are
# waiting when it frees). Whichever gets it: the update line comes once, the PostToolUse returns
# only with the items on disk, and the hook that waited syncs nothing again – the source changes
# the moment the first hook returns, which a second sync would install.
subtest 'CwdChanged and PostToolUse of one cd: one syncs, PostToolUse returns with the items there' => sub {
  plan skip_all => 'needs fork' if $^O eq 'MSWin32';
  for my $first (qw( cwd-changed post-tool-use )) {
    my $m = machine();
    my $src = local_source($m);
    user_config( $m, { sources => { mine => { local => $src } } } );
    my $wt = main_with_worktree( $m, { skills => [ 'foo@mine', 'bar@mine' ] } );
    my $foo_at = "$wt/.claude/skills/foo/SKILL.md";
    my $returned = sub {
      my ( $event ) = @_;
      return sub {
        # The first to return changes the source; a later sync would install that.
        path("$src/skills/foo/SKILL.md")->spew_raw( skill('foo')."CHANGED\n" ) if mkdir "$m->{dir}/first-returned";
        return unless $event eq 'post-tool-use';
        my $there = -f $foo_at && slurp($foo_at) eq skill('foo') && -f "$wt/.claude/skills/bar/SKILL.md" && -f "$wt/.claude/skilletor.lock.json";
        path("$m->{dir}/post-saw")->spew_raw( $there ? 'items' : 'none' );
      };
    };
    my %input = ( 'cwd-changed' => move( $m->{main}, $wt ), 'post-tool-use' => bash_cd($wt) );
    my $second = $first eq 'cwd-changed' ? 'post-tool-use' : 'cwd-changed';
    my %pid;
    state($m)->with_lock(
      sub {
        for my $event ( $first, $second ) {
          $pid{$event} = hook_in_child( $event, $input{$event}, $m->{ctx}, "$m->{dir}/$event.json", $returned->($event) );
          Time::HiRes::sleep(0.3);    # waiting on the lock
        }
      },
      refresh_ms => 60_000,
    );
    is( reap( $pid{$_} ), 0, "$first first: $_ ran" ) for $first, $second;
    my %out = map { ( $_ => slurp("$m->{dir}/$_.json") ) } $first, $second;
    my $line = out( js_ordered( systemMessage => "skilletor: 2 item(s) updated in $wt" ) );
    my @said = grep { $out{$_} ne '{}' } keys %out;
    is( scalar @said, 1, "$first first: one hook answers" );
    my $synced = $said[0] // '';
    if ( $synced eq 'cwd-changed' ) {
      is( $out{'cwd-changed'}, $line, "$first first: CwdChanged's line" );
    }
    else {
      like( $out{'post-tool-use'}, qr/\A\Q{"systemMessage":"skilletor: 2 item(s) updated in $wt","hookSpecificOutput":{"hookEventName":"PostToolUse",\E/,
        "$first first: PostToolUse's line and context" );
    }
    is( slurp("$m->{dir}/post-saw"), 'items', "$first first: PostToolUse returned with the items on disk" );
    is( slurp($foo_at), skill('foo'), "$first first: no second sync" );
  }
};

# A PostToolUse while another run holds the sync lock waits for it instead of returning early, and
# syncs once it is free; the wait ends at the move's deadline, past which its sync would write
# nothing – then the line says so, nothing is written, and the checkout is not marked checked.
subtest 'PostToolUse waits on the sync lock up to its deadline' => sub {
  plan skip_all => 'needs fork' if $^O eq 'MSWin32';
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => ['foo@mine'] } );
  my $pid;
  state($m)->with_lock(
    sub {
      $pid = hook_in_child( 'post-tool-use', bash_cd($wt), $m->{ctx}, "$m->{dir}/post.json" );
      Time::HiRes::sleep(0.3);
      is( waitpid( $pid, POSIX::WNOHANG() ), 0, 'still waiting while the lock is held' );
    },
    refresh_ms => 60_000,
  );
  is( reap($pid), 0, 'then it returns' );
  is( js_parse( slurp("$m->{dir}/post.json") )->{systemMessage}, "skilletor: 1 item(s) updated in $wt", 'having synced' );
  ok( -f "$wt/.claude/skills/foo/SKILL.md", 'foo there' );

  my $wt2 = add_worktree( $m, 'other' );
  my $started = Time::HiRes::time();
  my $out = state($m)->with_lock(
    sub { run_hook( 'post-tool-use', bash_cd($wt2), { %{ $m->{ctx} }, deadline => int( Time::HiRes::time() * 1000 ) + 300 } ) },
    refresh_ms => 60_000,
  );
  my $waited = Time::HiRes::time() - $started;
  ok( $waited < 3, sprintf( 'waited %.1f s: up to the deadline', $waited ) );
  like( $out->{systemMessage} // '', qr/\Askilletor: cannot sync \Q$wt2\E: timed out acquiring sync lock at .* — run there: skilletor sync\z/, 'the line' );
  ok( !-e "$wt2/.claude/skilletor.lock.json" && !-e "$wt2/.claude/skills", 'nothing written' );
  ok( state($m)->is_due( $wt2, 3600 ), 'a lock timeout leaves the checkout unchecked (k89)' );
};

# A lock_timeout_ms of the context wins over the wait until the deadline.
subtest "the context's lock_timeout_ms over the deadline's wait" => sub {
  my $m = machine();
  user_config( $m, { sources => { mine => { local => local_source($m) } } } );
  my $wt = main_with_worktree( $m, { skills => ['foo@mine'] } );
  my $started = Time::HiRes::time();
  my $out = state($m)->with_lock(
    sub { run_hook( 'cwd-changed', move( $m->{main}, $wt ), { %{ $m->{ctx} }, engine => { %{ $m->{ctx}{engine} }, lock_timeout_ms => 0 } } ) },
    refresh_ms => 60_000,
  );
  ok( Time::HiRes::time() - $started < 3, 'no wait' );
  like( $out->{systemMessage} // '', qr/\Askilletor: cannot sync \Q$wt\E: timed out acquiring sync lock at /, 'timed out at once' );
};

done_testing;
