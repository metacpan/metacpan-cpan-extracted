
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'MooseX::Attribute::ValidateWithException' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Create composite types where all subtypes must be satisfied',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'MooseX-TypeArray',
  'dist_version' => '0.1.0',
  'license' => 'perl',
  'module_name' => 'MooseX::TypeArray',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Devel::StackTrace' => '0',
    'Moose' => '0',
    'Moose::Meta::TypeConstraint' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'Sub::Exporter' => '0',
    'Try::Tiny' => '0',
    'metaclass' => '0',
    'overload' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
