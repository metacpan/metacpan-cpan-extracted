
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Cwd' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Builder' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Syntactic sugar for running a method while in a directory',
  'dist_author' => [
    'Rob Hoelz <rob@hoelz.ro>'
  ],
  'dist_name' => 'MooseX-Role-WithWorkingDirectory',
  'dist_version' => '0.02',
  'license' => 'perl',
  'module_name' => 'MooseX::Role::WithWorkingDirectory',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '2'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
