
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
  'dist_abstract' => 'Name your accessors foo(), set_foo(), and has_foo()',
  'dist_author' => [
    'Edward Allen <ealleniii@cpan.org>'
  ],
  'dist_name' => 'MooseX-EasyAcc',
  'dist_version' => '0.001',
  'license' => 'artistic_2',
  'module_name' => 'MooseX::EasyAcc',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '1.9900',
    'Moose::Exporter' => '0',
    'Moose::Role' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
