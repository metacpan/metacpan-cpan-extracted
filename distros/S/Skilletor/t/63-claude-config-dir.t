#!/usr/bin/env perl
# k145: CLAUDE_CONFIG_DIR is the user scope's `.claude` – config, lock, roots, state, detection
# and the briefing lookup – as for Claude Code itself; an empty value is unset.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Path::Tiny qw( path tempdir );
use Skilletor::Briefing qw( skill_roots );
use Skilletor::Config;
use Skilletor::Engine;
use Skilletor::State;
use Skilletor::Targets qw( default_markers );

my $root = tempdir->realpath;
my ( $home, $alt, $src ) = ( "$root/home", "$root/alt-config", "$root/src" );
path( $src, 'skills/demo' )->mkpath;
path( $src, 'skills/demo/SKILL.md' )->spew_raw("---\nname: demo\ndescription: Demo\n---\nbody\n");
path( $home, '.claude' )->mkpath;
write_json( "$home/.claude/skilletor.json", { install => { skills => ['decoy@nowhere'] } } );
path($alt)->mkpath;
path( $alt, '.claude.json' )->spew_raw("{}\n");    # Claude Code's marker inside a custom config dir
write_json( "$alt/skilletor.json", { sources => { s => { local => $src } }, install => { skills => ['demo@s'] } } );

my $engine = sub {
  Skilletor::Engine->new( home => $home, codex_home => "$home/.no-codex", is_git_work_tree => sub { 0 },
    git_tracked => sub { [] }, @_ );
};

subtest 'a sync lives under the config dir, detection included' => sub {
  my $sk = $engine->( claude_config_dir => $alt );
  is $sk->state_root, "$alt/skilletor", 'the state dir lies in it';
  my $rep = $sk->sync;
  is_deeply [ map { $_->{key} } @{ $rep->{scopes}[0]{added} } ], ['skills/demo'], 'the skill from the config dir\'s config';
  ok -f "$alt/skills/demo/SKILL.md", 'installed there';
  ok -f "$alt/skilletor.lock.json",  'the lock is there';
  ok !-e "$home/.claude/skilletor.lock.json", 'none under ~/.claude';
  ok !-e "$home/.claude/skills", 'no skills under ~/.claude';
};

subtest 'an empty value is unset, the default is ~/.claude' => sub {
  my $sk = $engine->( claude_config_dir => '' );
  is $sk->claude_dir, "$home/.claude";
  is $sk->state_root, "$home/.claude/skilletor";
};

subtest 'pieces' => sub {
  is( Skilletor::State->default_root( $home, $alt ), "$alt/skilletor" );
  is( Skilletor::State->default_root($home), "$home/.claude/skilletor" );
  is_deeply default_markers( $home, undef, $alt )->{claude}, [ "$alt/.claude.json", "$alt/settings.json", "$alt/projects" ];
  is default_markers( $home, undef )->{claude}[0], "$home/.claude.json";
  my $cfg = Skilletor::Config->new( home => $home, claude_config_dir => $alt );
  is $cfg->user_path, "$alt/skilletor.json";
  path( $alt, 'plugins/cache/m/p/skills' )->mkpath;
  my $roots = skill_roots( claude => user => { home => $home, claude_dir => $alt } );
  is $roots->[0], "$alt/skills";
  ok( ( grep { $_ eq "$alt/plugins/cache/m/p/skills" } @$roots ), 'plugin cache of the config dir' );
  ok( !( grep { index( $_, "$home/.claude" ) == 0 } @$roots ), 'nothing under ~/.claude' );
};

done_testing;
