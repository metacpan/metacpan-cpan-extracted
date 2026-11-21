#!/usr/bin/env perl
# The Hermes target (k185, spec §16) as the reference's hermes.test.ts holds it, against temp
# dirs: skills only, in the Hermes home's `skills` for the user scope and `<repo>/.hermes/skills`
# for a project, which gets no managed `.gitignore` block; what Hermes gets no copy of as a run
# note; the Codex copy serving it in a project; and the one Hermes home a user-scope lock serves –
# recorded, moved, dropped once Hermes is no target. The CLI's bytes are conformance/'s (cases
# 110-116).
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Cwd ();
use Path::Tiny qw( path tempdir );
use Skilletor::Engine;
use Skilletor::Gitignore qw( SKILL_GITIGNORE );
use Skilletor::JSON qw( js_parse );
use Skilletor::Lock qw( read_lock );
use Skilletor::Report qw( report_hook report_text );
use Skilletor::State;
use Skilletor::Targets qw( default_hermes_home );

delete $ENV{CLAUDE_CONFIG_DIR};

sub skill { my ( $n, $body ) = @_; "---\nname: $n\ndescription: $n\n---\n".( $body // 'BODY' )."\n" }
sub agent { "---\nname: $_[0]\ndescription: $_[0]\n---\nYou are $_[0].\n" }
sub slurp { path( $_[0] )->slurp_utf8 }

# hermes.test.ts's env(): a home and a project with `.claude/`, a state dir and a Hermes home of
# their own, a marker per harness in use – Hermes never is detected, so the user config names the
# harnesses in `targets` unless a test sets them itself.
sub env_of {
  my ( @harnesses ) = @_;
  my $tmp = tempdir;
  my $dir = Cwd::realpath("$tmp");
  my $e   = { tmp => $tmp, dir => $dir, home => "$dir/home", project => "$dir/proj", hermes => "$dir/hermes-home", harnesses => \@harnesses };
  path($_)->mkpath for "$e->{home}/.claude", "$e->{project}/.claude", $e->{hermes};
  path("$dir/marker-$_")->spew_raw('') for @harnesses;
  $e->{args} = {
    home             => $e->{home},
    project_dir      => $e->{project},
    state_root       => "$dir/state",
    host             => { name => 'box', os => 'linux' },
    user             => { name => 'getty', home => $e->{home} },
    markers          => { claude => ["$dir/marker-claude"], codex => ["$dir/marker-codex"] },
    codex_home       => "$e->{home}/.codex",
    hermes_home      => $e->{hermes},
    is_git_work_tree => sub { 0 },
    git_tracked      => sub { [] },
  };
  return $e;
}

sub engine { my ( $e, %more ) = @_; Skilletor::Engine->new( %{ $e->{args} }, %more ) }

sub write_cfg {
  my ( $e, $which, $obj, $declare_project_targets ) = @_;
  $declare_project_targets //= 1;
  my $opt_in = $which eq 'user' && ( grep { $_ eq 'hermes' } @{ $e->{harnesses} } ) && !exists $obj->{targets};
  my $config = $which eq 'project' && $declare_project_targets ? { targets => $e->{harnesses}, %$obj } : $obj;
  write_json( ( $which eq 'user' ? $e->{home} : $e->{project} ).'/.claude/skilletor.json', $opt_in ? { targets => $e->{harnesses}, %$obj } : $config );
}

sub source {
  my ( $e, $name, %files ) = @_;
  my $dir = "$e->{dir}/$name";
  for ( keys %files ) { path("$dir/$_")->parent->mkpath; path("$dir/$_")->spew_utf8( $files{$_} ) }
  return $dir;
}

# The drift a check found, per kind – a local source itself always counts as changed (spec §4.4).
sub drift_of {
  my ( $engine, %opts ) = @_;
  my $c = $engine->check(%opts);
  is( $c->{error}, undef, 'the check has no error' );
  return { map { ( $_ => $c->{"${_}Changed"} ) } qw( targets layout declared vars ) };
}
my $NONE = { targets => undef, layout => undef, declared => undef, vars => undef };
sub drifts { my $d = drift_of(@_); return scalar grep { defined } values %$d }

sub keys_of { [ sort keys %{ read_lock( $_[0] ) } ] }
sub user_lock    { keys_of("$_[0]{home}/.claude/skilletor.lock.json") }
sub project_lock { keys_of("$_[0]{project}/.claude/skilletor.lock.json") }
sub keys_in { [ map { $_->{key} } @{ $_[0] } ] }

# ---- sync: the layout -----------------------------------------------------------------------

subtest 'hermes only: a user skill goes to <Hermes home>/skills, nothing to ~/.claude/skills' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo'), 'skills/foo/references/a.md' => "A\n" );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  my $r = engine($e)->sync( scope => 'user' );
  is( $r->{error}, undef, 'no error' );
  is( slurp("$e->{hermes}/skills/foo/SKILL.md"),         skill('foo'),     'the skill' );
  is( slurp("$e->{hermes}/skills/foo/references/a.md"),  "A\n",            'its files' );
  is( slurp("$e->{hermes}/skills/foo/.gitignore"),       SKILL_GITIGNORE, 'its .gitignore' );
  ok( !-e "$e->{home}/.claude/skills", 'nothing for Claude Code' );
  ok( !-e "$e->{home}/.hermes",        'the given home, not the default' );
  is_deeply( user_lock($e), ['hermes:skills/foo'], 'the lock' );
  is_deeply( [ sort keys %{ read_lock("$e->{home}/.claude/skilletor.lock.json")->{'hermes:skills/foo'}{files} } ],
    [ 'skills/foo/.gitignore', 'skills/foo/SKILL.md', 'skills/foo/references/a.md' ], 'its files' );
  is_deeply( keys_in( $r->{scopes}[0]{added} ), ['hermes:skills/foo'], 'added' );
  like( report_text($r), qr/\+ hermes:skills\/foo \(active from the next Hermes session\)/, 'the report text' );
  is( report_hook($r)->{additionalContext}, "skilletor synced items:\n- skill foo\@mine (hermes): active from the next Hermes session", 'the hook context' );
  ok( !exists $r->{notes}, 'no note' );
  is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'no drift' );
};

subtest 'a project skill goes to <repo>/.hermes/skills; the .hermes root gets no .gitignore block' => sub {
  my $e = env_of( 'claude', 'hermes' );
  my $src = source( $e, 's', 'skills/foo/SKILL.md.njk' => skill( 'foo', 'for {{ harness }} in {{ target.dir }}' ) );
  write_cfg( $e, user    => { sources => { mine => { local => $src } } } );
  write_cfg( $e, project => { install => { skills => ['foo@mine'] } } );
  my $r = engine($e)->sync;
  is( $r->{error}, undef, 'no error' );
  my $root = "$e->{project}/.hermes";
  is( slurp("$root/skills/foo/SKILL.md"),   skill( 'foo', "for hermes in $root" ), 'rendered for Hermes' );
  is( slurp("$root/skills/foo/.gitignore"), SKILL_GITIGNORE,                       'its .gitignore' );
  ok( !-e "$root/.gitignore", 'no block in the root' );
  like( slurp("$e->{project}/.claude/skills/foo/SKILL.md"), qr/for claude in /, 'and for Claude Code' );
  is_deeply( project_lock($e), [ 'hermes:skills/foo', 'skills/foo' ], 'the lock' );
  is_deeply( keys_in( $r->{scopes}[1]{added} ), [ 'skills/foo', 'hermes:skills/foo' ], 'added, in order' );
};

subtest 'project-local Hermes evidence selects Hermes inside the machine allowlist' => sub {
  my $e = env_of( 'claude', 'hermes' );
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user => { sources => { mine => { local => $src } } } );
  write_cfg( $e, project => { install => { skills => ['foo@mine'] } }, 0 );
  path("$e->{project}/.hermes")->mkpath;
  path("$e->{project}/.hermes/config.yaml")->spew("model: test\n");
  my $engine = engine($e);
  my $r = $engine->sync( scope => 'project' );
  is( $r->{error}, undef, 'no error' );
  is_deeply( project_lock($e), ['hermes:skills/foo'], 'only the Hermes copy is locked' );
  ok( -e "$e->{project}/.hermes/skills/foo/SKILL.md", 'the Hermes copy exists' );
  ok( !-e "$e->{project}/.claude/skills/foo", 'there is no Claude copy' );
  is_deeply( $engine->status( scope => 'project' )->{scopes}[0]{targets}, ['hermes'], 'status names Hermes' );
};

subtest 'a .gitignore of the user\'s in a Hermes root is left byte for byte' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user    => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  write_cfg( $e, project => { install => { skills => ['foo@mine'] } } );
  path("$e->{project}/.hermes")->mkpath;
  my $mine = "notes/\n\n\n# no newline at the end";
  path("$_/.gitignore")->spew_raw($mine) for $e->{hermes}, "$e->{project}/.hermes";
  is( engine( $e, is_git_work_tree => sub { 1 } )->sync->{error}, undef, 'no error' );
  is( path("$e->{hermes}/.gitignore")->slurp_raw,           $mine, 'the home\'s' );
  is( path("$e->{project}/.hermes/.gitignore")->slurp_raw, $mine, 'the project\'s' );
};

subtest 'uninstalling removes the Hermes copy and its directory; a foreign skill beside it stays' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  path("$e->{hermes}/skills/own")->mkpath;
  path("$e->{hermes}/skills/own/SKILL.md")->spew_utf8( skill('own') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  engine($e)->sync( scope => 'user' );
  write_cfg( $e, user => { sources => { mine => { local => $src } } } );
  my $r = engine($e)->sync( scope => 'user' );
  is_deeply( keys_in( $r->{scopes}[0]{removed} ), ['hermes:skills/foo'], 'removed' );
  ok( !-e "$e->{hermes}/skills/foo", 'its directory gone' );
  is( slurp("$e->{hermes}/skills/own/SKILL.md"), skill('own'), 'the foreign skill stays' );
  is_deeply( user_lock($e), [], 'the lock is empty' );
};

subtest 'a skill directory skilletor did not install is a conflict and is not touched' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  path("$e->{hermes}/skills/foo")->mkpath;
  path("$e->{hermes}/skills/foo/SKILL.md")->spew_utf8("MINE\n");
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  my $r = engine($e)->sync( scope => 'user' );
  is_deeply( $r->{scopes}[0]{conflicts}, [ { path => "$e->{hermes}/skills/foo/SKILL.md" } ], 'a conflict' );
  is( slurp("$e->{hermes}/skills/foo/SKILL.md"), "MINE\n", 'untouched' );
  ok( !-e "$e->{hermes}/skills/foo/.gitignore", 'no .gitignore put beside it' );
  is_deeply( user_lock($e), [], 'nothing locked' );
};

# ---- what Hermes gets no copy of -------------------------------------------------------------

subtest 'agents and rules install for Claude only; one note names what Hermes does not get' => sub {
  my $e = env_of( 'claude', 'hermes' );
  my $src = source( $e, 's',
    'skills/foo/SKILL.md' => skill('foo'), 'agents/helper.md' => agent('helper'), 'agents/other.md' => agent('other'), 'rules/style.md' => "Be terse.\n" );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'], agents => ['*@mine'], rules => ['style@mine'] } } );
  my $r = engine($e)->sync( scope => 'user' );
  is( $r->{error}, undef, 'no error' );
  my @all = ( 'agents/helper', 'agents/other', 'hermes:skills/foo', 'rules/style', 'skills/foo' );
  is_deeply( user_lock($e), \@all, 'the lock' );
  ok( !-e "$e->{hermes}/agents" && !-e "$e->{hermes}/rules", 'no agents or rules for Hermes' );
  my $note = '2 agent(s) and 1 rule(s) not installed for Hermes (Hermes has no agent files and no rules directory)';
  is_deeply( $r->{notes}, [$note], 'the note' );
  like( report_text($r), qr/^skilletor: note: 2 agent\(s\) and 1 rule\(s\) not installed for Hermes/m, 'in the report text' );
  my $hook = report_hook($r);
  unlike( ( $hook->{systemMessage} // '' )."\n".( $hook->{additionalContext} // '' ), qr/not installed for Hermes|warning/, 'the hooks stay quiet' );
  is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'no drift' );
  my $again = engine($e)->sync( scope => 'user' );
  is_deeply( $again->{notes}, [$note], 'a sync that changes nothing says it again' );
  is( report_hook($again)->{systemMessage}, undef, 'and the hooks still do not' );
  is_deeply( [ sort map { $_->{key} } @{ engine($e)->status( scope => 'user' )->{scopes}[0]{declared} } ], \@all, 'status: a row per harness' );
};

subtest 'hermes only: an agent is not installed anywhere, and that is no drift' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'agents/helper.md' => agent('helper') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { agents => ['helper@mine'] } } );
  my $r = engine($e)->sync( scope => 'user' );
  is_deeply( user_lock($e), [], 'nothing locked' );
  is_deeply( $r->{notes}, ['1 agent(s) not installed for Hermes (Hermes has no agent files and no rules directory)'], 'the note' );
  is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'no drift' );
};

subtest 'Claude and Codex without Hermes: no note, no Hermes root' => sub {
  my $e = env_of( 'claude', 'codex' );
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo'), 'agents/helper.md' => agent('helper') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'], agents => ['helper@mine'] } } );
  my $r = engine($e)->sync( scope => 'user' );
  ok( !exists $r->{notes}, 'no note' );
  ok( !-e "$e->{hermes}/skills", 'nothing for Hermes' );
  is_deeply( user_lock($e), [ 'agents/helper', 'codex:agents/helper', 'codex:skills/foo', 'skills/foo' ], 'the lock' );
};

# ---- project skills where Codex is active too ------------------------------------------------

subtest 'a project with Codex active: Hermes gets no copy of its own, the Codex copy serves it' => sub {
  my $e = env_of( 'codex', 'hermes' );
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo'), 'skills/bar/SKILL.md' => skill('bar') );
  write_cfg( $e, user    => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  write_cfg( $e, project => { install => { skills => [ 'foo@mine', 'bar@mine' ] } } );
  my $r = engine($e)->sync;
  is( $r->{error}, undef, 'no error' );
  is_deeply( user_lock($e),    [ 'codex:skills/foo', 'hermes:skills/foo' ], 'the user scope: Hermes gets its copy' );
  is_deeply( project_lock($e), [ 'codex:skills/bar', 'codex:skills/foo' ],  'the project: the Codex copies alone' );
  ok( !-e "$e->{project}/.hermes", 'no Hermes root in the project' );
  is_deeply( $r->{notes}, ['2 skill(s) not installed for Hermes in the project scope (Hermes reads the Codex copy in .agents/skills)'], 'the note' );
  is_deeply( drift_of( engine($e) ), $NONE, 'no drift' );
  is_deeply( [ map { $_->{key} } @{ engine($e)->status( scope => 'project' )->{scopes}[0]{declared} } ], [ 'codex:skills/foo', 'codex:skills/bar' ],
    'status' );
};

subtest 'Codex becomes active in a project: check reports it, the sync removes Hermes\' own copy' => sub {
  my $e = env_of('hermes');
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user    => { sources => { mine => { local => $src } } } );
  write_cfg( $e, project => { install => { skills => ['foo@mine'] } } );
  engine($e)->sync;
  ok( -e "$e->{project}/.hermes/skills/foo/SKILL.md", 'Hermes\' own copy' );

  write_cfg( $e, user => { targets => [ 'codex', 'hermes' ], sources => { mine => { local => $src } } } );
  write_cfg( $e, project => { targets => [ 'codex', 'hermes' ], install => { skills => ['foo@mine'] } } );
  my $chk = engine($e)->check;
  ok( $chk->{changed}, 'changed' );
  is_deeply( $chk->{targetsChanged}, ['project'], 'the project\'s targets' );
  my $r = engine($e)->sync;
  is_deeply( keys_in( $r->{scopes}[1]{removed} ), ['hermes:skills/foo'], 'Hermes\' copy removed' );
  is_deeply( keys_in( $r->{scopes}[1]{added} ),   ['codex:skills/foo'],  'the Codex copy added' );
  ok( !-e "$e->{project}/.hermes/skills", 'its skills dir gone' );
  ok( -e "$e->{project}/.agents/skills/foo/SKILL.md", 'the Codex copy there' );
  is_deeply( drift_of( engine($e) ), $NONE, 'no drift' );

  write_cfg( $e, user => { sources => { mine => { local => $src } } } );
  ok( drifts( engine($e) ), 'Codex gone: drift' );
  engine($e)->sync;
  is_deeply( project_lock($e), ['hermes:skills/foo'], 'Hermes gets its own again' );
  ok( !-e "$e->{project}/.agents/skills", 'the Codex copy gone' );
  ok( -e "$e->{project}/.hermes/skills/foo/SKILL.md", 'Hermes\' own back' );
};

# ---- the Hermes home -------------------------------------------------------------------------

# hermes.test.ts's homes(): Claude Code in use by its default marker, Hermes a target by the user
# config, no Hermes home given – `make` gives one of its own.
sub homes {
  my $e = env_of( 'claude', 'hermes' );
  delete @{ $e->{args} }{qw( markers hermes_home )};
  path("$e->{home}/.claude.json")->spew_raw('{}');
  $e->{make} = sub {
    my $dir = "$e->{dir}/$_[0]";
    path($dir)->mkpath;
    path("$dir/config.yaml")->spew_raw('');
    return $dir;
  };
  $e->{state} = sub { Skilletor::State->new( root => $e->{args}{state_root} ) };
  return $e;
}

subtest 'a Hermes home in use is no target until the user\'s targets name hermes; a project cannot add it' => sub {
  my $e = homes();
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  my $a = $e->{make}->('home-a');
  path("$a/$_")->spew_raw('') for 'SOUL.md', '.env';
  path("$a/sessions")->mkpath;
  my %declared = ( sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } );
  write_json( "$e->{home}/.claude/skilletor.json", {%declared} );    # no targets: detection alone
  write_cfg( $e, project => { targets => ['hermes'], install => { skills => ['foo@mine'] } } );
  my $in_hermes = sub { engine( $e, hermes_home => $a ) };
  my $r = $in_hermes->()->sync;
  is( $r->{error}, undef, 'no error' );
  is_deeply( user_lock($e),    ['skills/foo'], 'the user scope: Claude Code alone' );
  is_deeply( project_lock($e), [],             'the project: nothing' );
  like( join( "\n", @{ $r->{scopes}[1]{warnings} } ), qr/project targets \(hermes\) are not in use on this machine \(claude\)/, 'the warning' );
  ok( !-e "$a/skills", 'nothing in the Hermes home' );
  is( $e->{state}->()->hermes_home, undef, 'nothing recorded' );
  is_deeply( $in_hermes->()->status( scope => 'user' )->{scopes}[0]{targets}, ['claude'], 'status: Claude Code\'s' );
  is_deeply( drift_of( $in_hermes->() ), $NONE, 'no drift' );

  write_json( "$e->{home}/.claude/skilletor.json", { targets => [ 'claude', 'hermes' ], %declared } );
  ok( drifts( $in_hermes->() ), 'opted in: drift' );
  $in_hermes->()->sync;
  ok( -e "$a/skills/foo/SKILL.md", 'the user scope\'s Hermes copy' );
  is_deeply( project_lock($e), ['hermes:skills/foo'], 'the project\'s' );
  is( $e->{state}->()->hermes_home, $a, 'the home recorded' );
};

subtest 'a sync under a Hermes home of its own records it; a run without one serves the same home' => sub {
  my $e = homes();
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  my $a = $e->{make}->('home-a');
  engine( $e, hermes_home => $a )->sync( scope => 'user' );
  ok( -e "$a/skills/foo/SKILL.md", 'installed under it' );
  is( $e->{state}->()->hermes_home, $a, 'recorded' );

  is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'a run without one: no drift' );
  my $r = engine($e)->sync( scope => 'user' );
  is_deeply( [ sort map { $_->{key} } @{ $r->{scopes}[0]{unchanged} } ], [ 'hermes:skills/foo', 'skills/foo' ], 'nothing to do' );
  is_deeply( engine($e)->status( scope => 'user' )->{scopes}[0]{targets}, [ 'claude', 'hermes' ], 'status' );
  ok( !-e "$e->{home}/.hermes", 'the default home untouched' );

  path("$src/skills/foo/SKILL.md")->spew_utf8( skill( 'foo', 'NEW' ) );
  engine($e)->sync( scope => 'user' );
  is( slurp("$a/skills/foo/SKILL.md"), skill( 'foo', 'NEW' ), 'a source that moves is brought to the recorded home' );
};

subtest 'the default home needs no record; $HERMES_HOME is read when none is given' => sub {
  my $e = homes();
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  engine($e)->sync( scope => 'user' );
  ok( -e default_hermes_home( $e->{home} ).'/skills/foo/SKILL.md', 'the default home' );
  is( $e->{state}->()->hermes_home, undef, 'no record' );
  is_deeply( drift_of( engine( $e, hermes_home => default_hermes_home( $e->{home} ) ), scope => 'user' ), $NONE, 'named, the same home' );

  my $b = $e->{make}->('home-b');
  {
    local $ENV{HERMES_HOME} = $b;
    is_deeply( engine($e)->check( scope => 'user' )->{targetsChanged}, ['user'], '$HERMES_HOME: another home' );
  }
  {
    local $ENV{HERMES_HOME} = '';
    is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'an empty one: the recorded home' );
  }
  {
    local $ENV{HERMES_HOME} = '~/.hermes';
    is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'a leading ~ is the home' );
  }
};

subtest 'another Hermes home: check reports it, the sync moves the items and takes nothing there for its own' => sub {
  my $e = homes();
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo'), 'skills/bar/SKILL.md' => skill('bar') );
  write_cfg( $e, user => { sources => { mine => { local => $src } }, install => { skills => [ 'foo@mine', 'bar@mine' ] } } );
  my $a = $e->{make}->('home-a');
  my $b = $e->{make}->('home-b');
  engine( $e, hermes_home => $a )->sync( scope => 'user' );
  path("$b/skills/bar")->mkpath;
  path("$b/skills/bar/SKILL.md")->spew_utf8("MINE\n");

  my $in_b = sub { engine( $e, hermes_home => $b ) };
  my $chk = $in_b->()->check( scope => 'user' );
  ok( $chk->{changed}, 'changed' );
  is_deeply( $chk->{targetsChanged}, ['user'], 'the user scope\'s targets' );
  my $r = $in_b->()->sync( scope => 'user' );
  ok( !-e "$a/skills", 'nothing left behind' );
  is( slurp("$b/skills/foo/SKILL.md"), skill('foo'), 'installed anew' );
  is( slurp("$b/skills/bar/SKILL.md"), "MINE\n",     'the user\'s own untouched' );
  is_deeply( $r->{scopes}[0]{conflicts}, [ { path => "$b/skills/bar/SKILL.md" } ], 'a conflict' );
  is_deeply( keys_in( $r->{scopes}[0]{added} ), ['hermes:skills/foo'], 'added' );
  is( $r->{scopes}[0]{warnings}[0],
    "Hermes home changed from $a to $b: 2 item(s) removed from the old home; what is declared installs anew under the new one", 'the warning first' );
  is( $e->{state}->()->hermes_home, $b, 'the new home recorded' );
  is_deeply( user_lock($e), [ 'hermes:skills/foo', 'skills/bar', 'skills/foo' ], 'the lock' );
  is_deeply( drift_of( $in_b->(), scope => 'user' ), $NONE, 'settled: the conflict is what the sync could not reach' );
  is_deeply( drift_of( engine($e), scope => 'user' ), $NONE, 'and for a run without a home' );
};

subtest 'upgrade from auto-detection: without hermes in targets the next sync removes the Hermes items and the record' => sub {
  for my $first (qw( claude hermes )) {
    my $e = homes();
    my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
    my %declared = ( sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } );
    write_cfg( $e, user => {%declared} );
    my $a = $e->{make}->('home-a');
    engine( $e, hermes_home => $a )->sync( scope => 'user' );
    is_deeply( user_lock($e), [ 'hermes:skills/foo', 'skills/foo' ], "$first: what the auto-detecting build left" );
    is( $e->{state}->()->hermes_home, $a, "$first: the home recorded" );

    write_json( "$e->{home}/.claude/skilletor.json", {%declared} );    # no targets: detection alone
    my $b = $e->{make}->('home-b');
    my $ctx = sub { $first eq 'claude' ? engine($e) : engine( $e, hermes_home => $b ) };
    ok( drifts( $ctx->(), scope => 'user' ), "$first: drift" );
    my $r = $ctx->()->sync( scope => 'user' );
    is( $r->{error}, undef, "$first: no error" );
    is_deeply( keys_in( $r->{scopes}[0]{removed} ), ['hermes:skills/foo'], "$first: removed" );
    is_deeply( $r->{scopes}[0]{warnings}, [], "$first: no warning" );
    is_deeply( user_lock($e), ['skills/foo'], "$first: the lock" );
    ok( !-e "$a/skills",      "$first: removed from the recorded home" );
    ok( -e "$a/config.yaml",  "$first: Hermes' own files stay" );
    ok( !-e "$b/skills",      "$first: nothing in the new one" );
    ok( !-e "$e->{home}/.hermes", "$first: nor in the default" );
    is( $e->{state}->()->hermes_home, undef, "$first: the record dropped" );
    is_deeply( drift_of( $ctx->(), scope => 'user' ), $NONE, "$first: no drift" );
  }
};

subtest 'a project-scope sync leaves the home record to the user scope' => sub {
  my $e = homes();
  my $src = source( $e, 's', 'skills/foo/SKILL.md' => skill('foo') );
  write_cfg( $e, user    => { sources => { mine => { local => $src } }, install => { skills => ['foo@mine'] } } );
  write_cfg( $e, project => { install => { skills => ['foo@mine'] } } );
  my $a = $e->{make}->('home-a');
  my $b = $e->{make}->('home-b');
  engine( $e, hermes_home => $a )->sync;
  engine( $e, hermes_home => $b )->sync( scope => 'project' );
  is( $e->{state}->()->hermes_home, $a, 'the record stays' );
  ok( -e "$a/skills/foo/SKILL.md", 'the user copy stays' );
  ok( !-e "$b/skills", 'nothing in the other home' );
  ok( drifts( engine( $e, hermes_home => $b ), scope => 'user' ), 'the user scope still owes the move' );
};

# ---- the opt-in line (spec §16.4) ------------------------------------------------------------

subtest 'hermes_opt_in_hint: the targets in use plus hermes; none when Hermes is one or the config is broken' => sub {
  my $e = env_of( 'claude', 'codex' );
  write_cfg( $e, user => {} );
  is( engine($e)->hermes_opt_in_hint,
    'Hermes gets no skills: "hermes" is not in "targets"; to opt in, set "targets": ["claude", "codex", "hermes"] in ~/.claude/skilletor.json',
    'detected: Claude Code and Codex' );
  write_cfg( $e, user => { targets => ['codex'] } );
  like( engine($e)->hermes_opt_in_hint, qr/set "targets": \["codex", "hermes"\] in/, 'configured: Codex alone' );
  write_cfg( $e, user => { targets => [ 'codex', 'hermes' ] } );
  is( engine($e)->hermes_opt_in_hint, undef, 'opted in' );
  path("$e->{home}/.claude/skilletor.json")->spew_raw('{ broken');
  is( engine($e)->hermes_opt_in_hint, undef, 'a broken config: none' );
  my $none = env_of();
  write_cfg( $none, user => {} );
  is( engine($none)->hermes_opt_in_hint, undef, 'no harness: none (the error is its own)' );
};

done_testing;
