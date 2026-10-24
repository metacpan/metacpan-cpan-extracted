#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( tempdir );
use Skilletor::Targets qw( default_markers detect_harnesses select_targets default_hermes_home );

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

my $home = tempdir;
is_deeply( detect_harnesses( default_markers("$home") ), [], 'nothing there' );
$home->child( '.codex', 'sessions' )->mkpath;
$home->child('.claude.json')->spew('{}');
is_deeply( detect_harnesses( default_markers("$home") ), [qw( claude codex )], 'both detected, in order' );

is( default_hermes_home('/H'), '/H/.hermes', 'hermes home' );
is( default_hermes_home( 'C:\\Users\\u', 'MSWin32', { LOCALAPPDATA => '  ' } ), 'C:\\Users\\u\\AppData\\Local\\hermes', 'windows, blank LOCALAPPDATA' );
is( default_hermes_home( 'C:\\Users\\u', 'MSWin32', { LOCALAPPDATA => 'D:\\L\\' } ), 'D:\\L\\hermes', 'windows LOCALAPPDATA' );

done_testing;
