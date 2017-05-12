use strict;
use warnings;

use Module::Build 0.38;


my %module_build_args = (
  'build_requires' => {
    'DBD::AnyData' => '0',
    'English' => '0',
    'Module::Build' => '0.38',
    'Mojolicious::Lite' => '0',
    'Test::Mojo' => '0',
    'Test::More' => '0',
    'Try::Tiny' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.38'
  },
  'dist_abstract' => 'Use and handle any data like a database source in test mode',
  'dist_author' => [
    'Alexander Ponomarev <shootnix@cpan.org>'
  ],
  'dist_name' => 'Mojolicious-Plugin-AnyData',
  'dist_version' => '1.20',
  'license' => 'perl',
  'module_name' => 'Mojolicious::Plugin::AnyData',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'DBI' => '0',
    'DBD::AnyData' => '0',
    'Mojo::Base' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
