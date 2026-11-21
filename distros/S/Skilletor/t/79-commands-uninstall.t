#!/usr/bin/env perl
# Skilletor::Commands::uninstall's config planning and cover diagnostics: explicit entries,
# type-restricted and bare removal, wildcard and bundle cover, other scopes, all-or-nothing
# validation, and the sync after an edit. Shared CLI cases 200+ pin streams and exit codes.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Cwd ();
use Path::Tiny qw( path tempdir );
use Skilletor::Commands;
use Skilletor::Engine;
use Skilletor::JSON qw( js_parse );

sub machine {
  my ( $install, %opts ) = @_;
  my $tmp     = Cwd::realpath( tempdir() );
  my $home    = "$tmp/home";
  my $project = "$tmp/project";
  my $source  = "$tmp/source";
  path("$home/.claude")->mkpath;
  path("$project/.claude")->mkpath;
  path("$home/.claude.json")->spew_raw('{}') unless $opts{no_harness};
  path("$source/skills/dup/SKILL.md")->touchpath->spew_raw("---\ndescription: dup skill\n---\nDup.\n");
  path("$source/skills/foo/SKILL.md")->touchpath->spew_raw("---\ndescription: foo skill\n---\nFoo.\n");
  path("$source/agents/dup.md")->touchpath->spew_raw("---\ndescription: dup agent\n---\nDup.\n");
  path("$source/rules/r1.md")->touchpath->spew_raw("---\ndescription: r1 rule\n---\nR1.\n");
  path("$source/rules/r2.md")->touchpath->spew_raw("---\ndescription: r2 rule\n---\nR2.\n");
  path("$source/rules/perl.md")->touchpath->spew_raw("---\ndescription: perl rule\n---\nPerl.\n");
  path("$source/bundles/perl.yaml")->touchpath->spew_raw("description: Perl\nrules: [r1]\n");
  my $user = write_json( "$home/.claude/skilletor.json", {
    sources => { mine => { local => $source } },
    ( $install ? ( install => $install ) : () ),
  } );
  my $project_cfg = "$project/.claude/skilletor.json";
  my $engine = Skilletor::Engine->new(
    home => $home, project_dir => $project, claude_config_dir => '', codex_home => "$home/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] },
  );
  return {
    tmp => $tmp, home => $home, project => $project, source => $source,
    user => $user, project_cfg => $project_cfg, engine => $engine,
  };
}

sub json_of { js_parse( path( $_[0] )->slurp_raw ) }
sub command_error {
  my ( $code ) = @_;
  my $ok = eval { $code->(); 1 };
  my $err = $ok ? undef : $@;
  isa_ok( $err, 'Skilletor::Error::Command' );
  return $err;
}

subtest 'explicit entries: a type prefix removes one list; a bare name removes every type' => sub {
  my $m = machine({ skills => ['dup@mine'], agents => ['dup@mine'], rules => ['r2@mine'] });
  $m->{engine}->sync;
  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['skill:dup@mine'] );
  is_deeply( $r->{hints}, [], 'no covering entry: no hint' );
  is_deeply( json_of( $m->{user} )->{install}, { agents => ['dup@mine'], rules => ['r2@mine'] }, 'only the skill entry removed' );
  ok( !-e "$m->{home}/.claude/skills/dup", 'the skill removed' );
  ok( -e "$m->{home}/.claude/agents/.local.dup.md", 'the agent kept' );

  Skilletor::Commands::uninstall( $m->{engine}, items => ['dup@mine'] );
  is_deeply( json_of( $m->{user} )->{install}, { rules => ['r2@mine'] }, 'bare name removed it from every remaining type' );
  ok( !-e "$m->{home}/.claude/agents/.local.dup.md", 'the agent removed' );
};

subtest 'wildcards: explicit removal warns; wildcard removal is type-restricted' => sub {
  my $m = machine({ rules => [ 'r1@mine', '*@mine' ], skills => ['*@mine'] });
  $m->{engine}->sync;
  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['r1@mine'] );
  is_deeply( $r->{hints}, [
    "r1\@mine removed, but the wildcard rule:*\@mine in the user config still installs it on the next sync. To drop it, "
      ."uninstall the wildcard (skilletor uninstall 'rule:*\@mine'), or keep it and gate the item via vars "
      ."if its template renders empty for some value (an empty render is skipped).",
  ], 'the exact warning names the matching wildcard and way out' );
  is_deeply( json_of( $m->{user} )->{install}, { rules => ['*@mine'], skills => ['*@mine'] }, 'explicit entry alone removed' );
  ok( -e "$m->{home}/.claude/rules/.local.r1.md", 'the wildcard keeps the rule installed' );

  Skilletor::Commands::uninstall( $m->{engine}, items => ['rule:*@mine'] );
  is_deeply( json_of( $m->{user} )->{install}, { skills => ['*@mine'] }, 'only the rule wildcard removed' );
  ok( !-e "$m->{home}/.claude/rules/.local.r1.md", 'the wildcard items removed' );
  ok( -e "$m->{home}/.claude/skills/foo/SKILL.md", 'the other type remains installed' );
};

subtest 'wildcard-only and absent names get the confirmed and conditional diagnostics' => sub {
  my $m = machine({ skills => ['*@mine'], rules => ['*@mine'] });
  $m->{engine}->sync;
  my $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['r1@mine'] ) } );
  is( $err->message,
    "r1\@mine is not declared explicitly; it is installed by the wildcard rule:*\@mine in the user config. To drop it, "
      ."uninstall the wildcard (skilletor uninstall 'rule:*\@mine'), or keep it and gate the item via vars "
      ."if its template renders empty for some value (an empty render is skipped).",
    'the lock confirms the item and its type, so only that wildcard is named' );

  $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['nope@mine'] ) } );
  is( $err->message,
    "nope\@mine is not declared in the user config ($m->{user}); the wildcards skill:*\@mine, rule:*\@mine there installs every matching item of its type "
      ."from mine, so if mine offers it: uninstall the wildcard (skilletor uninstall 'skill:*\@mine' or skilletor uninstall 'rule:*\@mine'), "
      ."or keep it and gate the item via vars if its template renders empty for some value (an empty render is skipped).",
    'without a lock item every matching wildcard is conditional' );
};

subtest 'bundles cover items; bare bundle removal works; item-and-bundle names are ambiguous' => sub {
  my $m = machine({ bundles => ['perl@mine'] });
  $m->{engine}->sync;
  my $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['r1@mine'] ) } );
  is( $err->message,
    "r1\@mine is not declared explicitly; it is installed by the bundle bundle:perl\@mine in the user config. To drop it, "
      ."uninstall the bundle (skilletor uninstall 'bundle:perl\@mine'), or keep it and gate the item via vars "
      ."if its template renders empty for some value (an empty render is skipped).",
    'bundle-only item names its bundle' );

  my $cfg = json_of( $m->{user} );
  $cfg->{install}{rules} = ['r1@mine'];
  write_json( $m->{user}, $cfg );
  $m->{engine}->sync;
  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['rule:r1@mine'] );
  like( $r->{hints}[0], qr/bundle bundle:perl\@mine .* still installs it/, 'explicit plus bundle returns a hint' );
  ok( -e "$m->{home}/.claude/rules/.local.r1.md", 'the bundle keeps the item installed' );
  Skilletor::Commands::uninstall( $m->{engine}, items => ['perl@mine'] );
  ok( !exists json_of( $m->{user} )->{install}, 'bare bundle name removes the bundle entry' );

  $m = machine({ rules => ['perl@mine'], bundles => ['perl@mine'] });
  my $raw = path( $m->{user} )->slurp_raw;
  $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['perl@mine'] ) } );
  is( $err->message,
    'perl@mine is ambiguous in the user config: it names a bundle and rule:perl@mine; use a prefix (bundle:perl@mine)',
    'bare item and bundle name is ambiguous' );
  is( path( $m->{user} )->slurp_raw, $raw, 'ambiguous removal leaves the config byte-identical' );
};

subtest 'a wildcard and bundle together are named as two kinds with both commands' => sub {
  my $m = machine({ rules => [ 'r1@mine', '*@mine' ], bundles => ['perl@mine'] });
  $m->{engine}->sync;
  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['r1@mine'] );
  is_deeply( $r->{hints}, [
    "r1\@mine removed, but the wildcard rule:*\@mine and bundle bundle:perl\@mine in the user config still installs it on the next sync. "
      ."To drop it, uninstall them (skilletor uninstall 'rule:*\@mine' or skilletor uninstall 'bundle:perl\@mine'), or keep it and gate "
      ."the item via vars if its template renders empty for some value (an empty render is skipped).",
  ], 'cover text and way out preserve wildcard then bundle order' );
};

subtest 'other declarations are named and every item is validated before any edit' => sub {
  my $m = machine({ skills => ['foo@mine'] });
  write_json( $m->{project_cfg}, { install => { rules => ['r2@mine'], bundles => ['perl@mine'] } } );
  my $raw = path( $m->{user} )->slurp_raw;
  my $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['agent:foo@mine'] ) } );
  is( $err->message, 'agent:foo@mine is not declared in the user config ('.$m->{user}.'); it is declared as skill:foo@mine',
    'another type in this config is named' );
  $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['r2@mine'] ) } );
  like( $err->message, qr/the project config declares it \(use --project\)\z/, 'the other scope is named' );
  $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => ['bundle:perl@mine'] ) } );
  like( $err->message, qr/the project config declares it \(use --project\)\z/, 'a bundle in the other scope is named' );
  $err = command_error( sub { Skilletor::Commands::uninstall( $m->{engine}, items => [ 'foo@mine', 'nope@mine' ] ) } );
  like( $err->message, qr/nope\@mine is not declared/, 'the bad item is reported' );
  is( path( $m->{user} )->slurp_raw, $raw, 'all refusals leave the config byte-identical' );

  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['r2@mine'], project => 1 );
  ok( !exists json_of( $m->{project_cfg} )->{install}{rules}, '--project removes the project entry' );
  ok( !defined $r->{report}{error}, 'its sync succeeds' );
};

subtest 'the config edit stays when the following sync reports an error' => sub {
  my $m = machine( { skills => ['foo@mine'] }, no_harness => 1 );
  my $r = Skilletor::Commands::uninstall( $m->{engine}, items => ['foo@mine'] );
  like( $r->{report}{error}, qr/no agent harness detected/, 'the post-edit sync error is returned' );
  ok( !exists json_of( $m->{user} )->{install}, 'the uninstall edit is not rolled back' );
  is_deeply( $r->{hints}, [], 'no hint' );
};

done_testing;
