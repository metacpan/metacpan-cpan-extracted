
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  'build_requires' => {
    'ExtUtils::CBuilder' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.28',
    'PerlIO::Layers' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'dist_abstract' => 'Push layers conditionally',
  'dist_author' => [
    'Leon Timmermans <fawaka@gmail.com>'
  ],
  'dist_name' => 'PerlIO-if',
  'dist_version' => '0.003',
  'license' => 'perl',
  'module_name' => 'PerlIO::if',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'XSLoader' => '0',
    'perl' => '5.008'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
