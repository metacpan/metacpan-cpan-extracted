
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
  'dist_abstract' => 'Markapl template plugin for Mojolicious',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Mojolicious-Plugin-MarkaplRenderer',
  'dist_version' => '0.2.0',
  'license' => 'bsd',
  'module_name' => 'Mojolicious::Plugin::MarkaplRenderer',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Mojo::Base' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
