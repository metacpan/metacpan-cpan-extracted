
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::MockObject::Extends' => '0',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'A POE::Component::IRC plugin that keeps track of karma',
  'dist_author' => [
    'Apocalypse <APOCAL@cpan.org>'
  ],
  'dist_name' => 'POE-Component-IRC-Plugin-Karma',
  'dist_version' => '0.003',
  'license' => 'perl',
  'module_name' => 'POE::Component::IRC::Plugin::Karma',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'DBD::SQLite' => '0',
    'DBI' => '0',
    'Moose' => '0',
    'POE::Component::IRC::Common' => '0',
    'POE::Component::IRC::Plugin' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
