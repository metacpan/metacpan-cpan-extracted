
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
  'dist_abstract' => 'Encrypt/decrypt files in Padre',
  'dist_author' => [
    'Fayland Lam <fayland@gmail.com>',
    'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>'
  ],
  'dist_name' => 'Padre-Plugin-Encrypt',
  'dist_version' => '0.12',
  'license' => 'perl',
  'module_name' => 'Padre::Plugin::Encrypt',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Crypt::Blowfish' => '0',
    'Crypt::CBC' => '0',
    'Padre' => '0.57'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
