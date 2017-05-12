
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Use Markapl as Tatsumaki\'s template system.',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Tatsumaki-Template-Markapl',
  'dist_version' => '0.3',
  'license' => 'bsd',
  'module_name' => 'Tatsumaki::Template::Markapl',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Any::Moose' => '0',
    'Plack::Util' => '0',
    'Sub::Install' => '0',
    'Tatsumaki::Template' => '0',
    'namespace::autoclean' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
