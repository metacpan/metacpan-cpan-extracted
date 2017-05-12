
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Merging HashRef attribute',
  'dist_author' => [
    'Moritz Onken'
  ],
  'dist_name' => 'MooseX-Traits-Attribute-MergeHashRef',
  'dist_version' => '1.002',
  'license' => 'bsd',
  'module_name' => 'MooseX::Traits::Attribute::MergeHashRef',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Hash::Merge' => '0',
    'Moose' => '0',
    'Moose::Meta::Method::Accessor' => '0',
    'Moose::Role' => '0',
    'Try::Tiny' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
