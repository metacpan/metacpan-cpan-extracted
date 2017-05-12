
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
  'dist_abstract' => 'Reformats your text within Padre',
  'dist_author' => [
    'Jerome Quelin <jquelin@gmail.com>',
    'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>'
  ],
  'dist_name' => 'Padre-Plugin-Autoformat',
  'dist_version' => '1.22',
  'license' => 'perl',
  'module_name' => 'Padre::Plugin::Autoformat',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'File::Basename' => '0',
    'File::Spec::Functions' => '0',
    'Padre' => '0.57',
    'Text::Autoformat' => '0'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
