
use strict;
use warnings;

use Module::Build 0.3601;
use lib 'inc'; use MyBuilder;

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Config::AutoConf' => '0.14',
    'ExtUtils::CBuilder' => '0.27',
    'File::Copy' => '0',
    'File::Path' => '2.08',
    'List::MoreUtils' => '0',
    'Mildew' => '0.05',
    'Module::Build' => '0.3601',
    'String::Escape' => '0'
  },
  'dist_abstract' => 'Simple Meta Object Programming',
  'dist_author' => [
    'Pawel Murias <pawelmurias@gmail.com>',
    'Daniel Ruoso <daniel@ruoso.com>'
  ],
  'dist_name' => 'SMOP',
  'dist_version' => '0.6',
  'license' => 'artistic_2',
  'module_name' => 'SMOP',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {},
  'script_files' => []
);


my $build = MyBuilder->new(%module_build_args);

$build->create_build_script;
