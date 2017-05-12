
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
  'dist_abstract' => 'Collection of mojolicious plugins',
  'dist_author' => [
    'Siddhartha Basu <biosidd@gmail.com>'
  ],
  'dist_name' => 'Mojolicious-Plugin-Bundle',
  'dist_version' => '0.004',
  'license' => 'perl',
  'module_name' => 'Mojolicious::Plugin::Bundle',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Bio::Chado::Schema' => '0.05703',
    'Mojolicious' => '1.21',
    'Regexp::Common' => '2010010201',
    'YAML' => '0.71'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
