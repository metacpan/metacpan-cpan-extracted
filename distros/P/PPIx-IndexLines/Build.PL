
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Path::Class' => '0',
    'Test::More' => '0.94',
    'Test::Perl::Critic::Progressive' => '0',
    'Try::Tiny' => '0',
    'perl' => '5.004'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Given a line number, returns some basic information about where in the perl document you are',
  'dist_author' => [
    'Alan Young <harleypig@gmail.com>'
  ],
  'dist_name' => 'PPIx-IndexLines',
  'dist_version' => '0.05',
  'license' => 'perl',
  'module_name' => 'PPIx::IndexLines',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'PPI' => '0',
    'Scalar::Util' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
