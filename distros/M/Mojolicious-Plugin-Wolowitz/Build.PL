
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Mojo I18n with Locale::Wolowitz',
  'dist_author' => [
    'Kang-min Liu <gugod@gugod.org>'
  ],
  'dist_name' => 'Mojolicious-Plugin-Wolowitz',
  'dist_version' => '1.0.1',
  'license' => 'mit',
  'module_name' => 'Mojolicious::Plugin::Wolowitz',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Locale::Wolowitz' => '0',
    'Mojo::Base' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
