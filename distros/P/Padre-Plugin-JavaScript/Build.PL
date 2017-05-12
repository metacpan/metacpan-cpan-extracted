
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
  'dist_abstract' => 'JavaScript Support for Padre',
  'dist_author' => [
    'Fayland Lam <fayland@gmail.com>',
    'Adam Kennedy <adamk@cpan.org>',
    'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>'
  ],
  'dist_name' => 'Padre-Plugin-JavaScript',
  'dist_version' => '0.29',
  'license' => 'perl',
  'module_name' => 'Padre::Plugin::JavaScript',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Exporter' => '0',
    'JE' => '0',
    'JavaScript::Beautifier' => '0.03',
    'JavaScript::Minifier::XS' => '0',
    'Padre' => '0.57'
  },
  'script_files' => [],
  'share_dir' => {
    'dist' => 'share'
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
