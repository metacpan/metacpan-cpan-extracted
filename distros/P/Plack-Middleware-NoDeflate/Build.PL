
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Prevent content from being deflated',
  'dist_author' => [
    'Olaf Alders <olaf@wundercounter.com>'
  ],
  'dist_name' => 'Plack-Middleware-NoDeflate',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::NoDeflate',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Plack::Middleware' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
