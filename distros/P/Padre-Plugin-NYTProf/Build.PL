
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Locale::Msgfmt' => '0.15',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Integrated profiling for Padre.',
  'dist_author' => [
    'Peter Lavender <peter.lavender@gmail.com>',
    'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>'
  ],
  'dist_name' => 'Padre-Plugin-NYTProf',
  'dist_version' => '0.04',
  'license' => 'perl',
  'module_name' => 'Padre::Plugin::NYTProf',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Devel::NYTProf' => '0',
    'Padre' => '0.72'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
