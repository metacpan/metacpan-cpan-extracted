
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'DBD::SQLite' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'A template provider that uses DBIC for database access and exhibits fallback functionality',
  'dist_author' => [
    'Rob Hoelz <rhoelz@inoc.com>'
  ],
  'dist_name' => 'Template-Provider-PrefixDBIC',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Template::Provider::PrefixDBIC',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'DBIx::Class' => '0',
    'Template' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
