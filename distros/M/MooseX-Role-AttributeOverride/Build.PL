
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Moose::Util' => '0',
    'Test::More' => '0.88',
    'Try::Tiny' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Allow roles to modify attributes',
  'dist_author' => [
    'Edward Allen <ealleniii_at_cpan_dot_org>'
  ],
  'dist_name' => 'MooseX-Role-AttributeOverride',
  'dist_version' => '0.0.9',
  'license' => 'perl',
  'module_name' => 'MooseX::Role::AttributeOverride',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '1.9900',
    'perl' => '5.008'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
