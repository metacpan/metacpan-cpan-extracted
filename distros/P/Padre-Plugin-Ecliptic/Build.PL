
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
  'dist_abstract' => 'Padre plugin that provides Eclipse-like useful features',
  'dist_author' => [
    'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>'
  ],
  'dist_name' => 'Padre-Plugin-Ecliptic',
  'dist_version' => '0.23',
  'license' => 'perl',
  'module_name' => 'Padre::Plugin::Ecliptic',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Class::XSAccessor' => '1.02',
    'File::Which' => '0.05',
    'Padre' => '0.72'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
