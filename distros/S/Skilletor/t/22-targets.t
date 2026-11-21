#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( tempdir );
use Skilletor::Gitignore qw( SKILL_GITIGNORE );
use Skilletor::Targets qw( default_markers detect_harnesses detect_project_harnesses select_targets default_hermes_home );

# Expected values: the reference's targets.ts, run once with Node.
my $m = default_markers('/H');
is_deeply( $m, {
  claude => [ '/H/.claude.json', '/H/.claude/settings.json', '/H/.claude/projects' ],
  codex  => [ '/H/.codex/config.toml', '/H/.codex/auth.json', '/H/.codex/sessions', '/H/.codex/installation_id' ],
}, 'default markers' );
is_deeply( default_markers( '/H', '/CX' )->{codex}, [ '/CX/config.toml', '/CX/auth.json', '/CX/sessions', '/CX/installation_id' ], '$CODEX_HOME' );
is_deeply( default_markers( '/H', '' )->{codex}[0], '/H/.codex/config.toml', 'an empty $CODEX_HOME is unset' );

is( error_of( sub { select_targets( {}, [], $m ) } ),
  'no agent harness detected (looked for claude: /H/.claude.json, /H/.claude/settings.json, /H/.claude/projects; '
  .'codex: /H/.codex/config.toml, /H/.codex/auth.json, /H/.codex/sessions, /H/.codex/installation_id); '
  .'set "targets": ["claude"], "codex" and/or "hermes" in ~/.claude/skilletor.json', 'nothing detected, markers named' );
is( error_of( sub { select_targets( {}, [] ) } ),
  'no agent harness detected; set "targets": ["claude"], "codex" and/or "hermes" in ~/.claude/skilletor.json', 'without markers' );
is_deeply( select_targets( {}, ['claude'], $m ), { user => ['claude'], project => ['claude'], warnings => [] }, 'detected' );
is_deeply( select_targets( { user => ['codex'] }, ['claude'], $m ), { user => ['codex'], project => ['codex'], warnings => [] }, 'user targets win' );
is_deeply( select_targets( { project => ['codex'] }, ['claude'], $m ), {
  user => ['claude'], project => [],
  warnings => ['project targets (codex) are not in use on this machine (claude); nothing is installed for the project'],
}, 'a project narrows, never widens' );
is_deeply( select_targets( { user => [qw( claude hermes )], project => [qw( hermes codex )] }, [], $m ),
  { user => [qw( claude hermes )], project => ['hermes'], warnings => [] }, 'machine order kept' );

is_deeply( select_targets( { user => [qw( claude codex )], project_evidence => ['claude'] }, [] ),
  { user => [qw( claude codex )], project => ['claude'], warnings => [] }, 'explicit global both is filtered by Claude project evidence' );
is_deeply( select_targets( { project_evidence => ['codex'] }, [qw( claude codex )] )->{project}, ['codex'], 'Codex evidence' );
is_deeply( select_targets( { project_evidence => [qw( claude codex )] }, [qw( claude codex )] )->{project},
  [qw( claude codex )], 'both kinds of evidence' );
is_deeply( select_targets( { project => ['codex'], project_evidence => ['claude'] }, [qw( claude codex )] )->{project},
  ['codex'], 'explicit project targets beat evidence' );
is_deeply( select_targets( { project_evidence => [] }, ['codex'] ),
  { user => ['codex'], project => ['codex'], warnings => [] }, 'one machine target bootstraps without evidence' );
my $ambiguous = select_targets( { project_evidence => [] }, [qw( claude codex )] );
is_deeply( $ambiguous->{project}, [qw( claude codex )], 'an ambiguous project carries the machine set without making it desired' );
ok( $ambiguous->{project_unresolved}, 'ambiguity is explicit' );
like( $ambiguous->{warnings}[0], qr/ambiguous.*set "targets".*left unchanged/i, 'ambiguity warning is actionable' );

{
  my $p = tempdir;
  $p->child('CLAUDE.md')->spew("Use Claude.\n");
  is_deeply( detect_project_harnesses( "$p", {} ), ['claude'], 'CLAUDE.md is Claude evidence' );
  $p->child('.codex')->mkpath;
  $p->child( '.codex', 'config.toml' )->spew("model = 'x'\n");
  is_deeply( detect_project_harnesses( "$p", {} ), [qw( claude codex )], 'Claude and Codex evidence' );
}

{
  my $p = tempdir;
  $p->child('.claude')->mkpath;
  $p->child('.codex')->mkpath;
  $p->child( '.claude', 'settings.json' )->spew("{}\n");
  $p->child( '.codex', 'config.toml' )->spew("model = 'x'\n");
  is_deeply( detect_project_harnesses( "$p", {} ), ['codex'], 'empty settings are not Claude evidence' );
  $p->child( '.claude', 'settings.json' )->spew(
    '{"enabledPlugins":{"skilletor@getty":true},"extraKnownMarketplaces":{"getty":{"source":{"source":"github","repo":"example/marketplace"}}}}' );
  is_deeply( detect_project_harnesses( "$p", {} ), ['codex'], 'generated declarations do not change selection' );
  $p->child( '.claude', 'settings.json' )->spew(
    '{"extraKnownMarketplaces":{"team":{"source":{"source":"github","repo":"example/team"}}}}' );
  is_deeply( detect_project_harnesses( "$p", {} ), [qw( claude codex )], 'marketplace-only user config is evidence' );
  $p->child( '.claude', 'settings.json' )->spew('{"enabledPlugins":{"skilletor@getty":false}}');
  is_deeply( detect_project_harnesses( "$p", {} ), [qw( claude codex )], 'an explicit false value is user evidence' );
  for my $key (qw( enabledPlugins extraKnownMarketplaces )) {
    $p->child( '.claude', 'settings.json' )->spew('{"'.$key.'":null}');
    is_deeply( detect_project_harnesses( "$p", {} ), [qw( claude codex )], "$key: explicit null is evidence" );
  }
  $p->child( '.claude', 'settings.json' )->spew('{"permissions":{"allow":["Read"]}}');
  is_deeply( detect_project_harnesses( "$p", {} ), [qw( claude codex )], 'genuine settings remain Claude evidence' );
}

{
  my @roots = ( [ '.claude', 'claude' ], [ '.agents', 'codex' ], [ '.hermes', 'hermes' ] );
  for my $case (@roots) {
    my ( $root, $harness ) = @$case;
    my $p = tempdir;
    $p->child( $root, 'skills', 'foo' )->mkpath;
    $p->child( $root, 'skills', 'foo', 'MINE.txt' )->spew("foreign\n");
    is_deeply( detect_project_harnesses( "$p", {} ), [], "$harness: a residual foreign file is no skill" );
    $p->child( $root, 'skills', 'foo', 'SKILL.md' )->spew("owned\n");
    is_deeply( detect_project_harnesses( "$p", {} ), [$harness], "$harness: a complete skill is evidence" );
  }
}

{
  my $p = tempdir;
  for my $dir ( '.claude/agents', '.claude/skills/foo', '.agents/skills/foo', '.codex/agents', '.hermes/skills/foo' ) {
    $p->child($dir)->mkpath;
  }
  $p->child( '.claude', 'skilletor.json' )->spew("{}\n");
  $p->child( '.claude', 'skilletor.local.json' )->spew("{}\n");
  $p->child( '.claude', '.gitignore' )->spew("# >>> skilletor >>>\n# <<< skilletor <<<\n");
  $p->child( '.claude', 'agents', '.local.helper.md' )->spew("generated\n");
  $p->child( '.codex', 'agents', '.local.helper.toml' )->spew("generated\n");
  $p->child( '.codex', 'skilletor-rules.md' )->spew("<!-- skilletor:rules scope=project -->\n");
  for my $root (qw( .claude .agents .hermes )) {
    $p->child( $root, 'skills', 'foo', 'SKILL.md' )->spew("generated\n");
    $p->child( $root, 'skills', 'foo', '.gitignore' )->spew(SKILL_GITIGNORE);
  }
  $p->child( '.claude', 'settings.json' )->spew(
    '{"enabledPlugins":{"skilletor@getty":true},"extraKnownMarketplaces":{"getty":{"source":{"source":"github","repo":"example/marketplace"}}}}' );
  my $lock = {
    'skills/foo'         => { source => 's', version => 'v', files => { 'skills/foo/SKILL.md' => 'h' } },
    'agents/legacy'      => { source => 's', version => 'v', files => { 'agents/legacy.md' => 'h' } },
    'codex:skills/foo'   => { source => 's', version => 'v', files => { 'skills/foo/SKILL.md' => 'h' } },
    'codex:agents/legacy'=> { source => 's', version => 'v', files => { 'agents/legacy.toml' => 'h' } },
    'hermes:skills/foo'  => { source => 's', version => 'v', files => { 'skills/foo/SKILL.md' => 'h' } },
  };
  is_deeply( detect_project_harnesses( "$p", {} ), [], 'markers exclude generated artifacts without a lock' );
  $p->child( '.claude', 'agents', 'legacy.md' )->spew("old generated layout\n");
  $p->child( '.codex', 'agents', 'legacy.toml' )->spew("old_generated = true\n");
  is_deeply( detect_project_harnesses( "$p", $lock ), [], 'generated-only roots are not evidence' );
}

{
  my $p = tempdir;
  $p->child('.claude')->mkpath;
  $p->child( '.claude', 'settings.json' )->spew('{"permissions":{"allow":["Read"]}}');
  is_deeply( detect_project_harnesses( "$p", {} ), ['claude'], 'genuine project settings are Claude evidence' );
}

my $home = tempdir;
is_deeply( detect_harnesses( default_markers("$home") ), [], 'nothing there' );
$home->child( '.codex', 'sessions' )->mkpath;
$home->child('.claude.json')->spew('{}');
is_deeply( detect_harnesses( default_markers("$home") ), [qw( claude codex )], 'both detected, in order' );

is( default_hermes_home('/H'), '/H/.hermes', 'hermes home' );
is( default_hermes_home( 'C:\\Users\\u', 'MSWin32', { LOCALAPPDATA => '  ' } ), 'C:\\Users\\u\\AppData\\Local\\hermes', 'windows, blank LOCALAPPDATA' );
is( default_hermes_home( 'C:\\Users\\u', 'MSWin32', { LOCALAPPDATA => 'D:\\L\\' } ), 'D:\\L\\hermes', 'windows LOCALAPPDATA' );

done_testing;
