
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'use data objects to clean strings',
  'dist_author' => [
    'NOTBENH <NOTBENH@cpan.org>'
  ],
  'dist_name' => 'String-Clean',
  'dist_version' => '0.031',
  'license' => 'perl',
  'module_name' => 'String::Clean',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp::Assert::More' => '0',
    'Test::More' => '0',
    'YAML::Any' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
