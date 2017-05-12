
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Moose::Util::TypeConstraints' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.88',
    'overload' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Make your Moose instances as unique as you are',
  'dist_author' => [
    'Edward Allen <ealleniii@cpan.org>'
  ],
  'dist_name' => 'MooseX-Unique',
  'dist_version' => '0.005',
  'license' => 'perl',
  'module_name' => 'MooseX::Unique',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'List::MoreUtils' => '0',
    'Moose' => '1.9900',
    'MooseX::InstanceTracking' => '0.06',
    'perl' => '5.10.0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
