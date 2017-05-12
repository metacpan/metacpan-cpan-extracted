
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
  'dist_abstract' => 'Create error traps for methods.',
  'dist_author' => [
    'NOTBENH <NOTBENH@cpan.org>'
  ],
  'dist_name' => 'MooseX-Error-Trap',
  'dist_version' => '0.021',
  'license' => 'perl',
  'module_name' => 'MooseX::Error::Trap',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '0',
    'Test::More' => '0',
    'Test::Most' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
