
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Mojolicious plugin for caching',
  'dist_author' => [
    'Siddhartha Basu <biosidd@gmail.com>'
  ],
  'dist_name' => 'Mojolicious-Plugin-Cache',
  'dist_version' => '0.0015',
  'license' => 'perl',
  'module_name' => 'Mojolicious::Plugin::Cache',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'CHI' => '0.36',
    'File::Path' => '2.08',
    'Mojolicious' => '1.21'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
