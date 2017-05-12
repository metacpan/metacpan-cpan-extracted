
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Data::Dump' => '0',
    'English' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Transform a non-html page into html.  ',
  'dist_author' => [
    'Mark Jubenville <ioncache@gmail.com>'
  ],
  'dist_name' => 'Plack-Middleware-HTMLify',
  'dist_version' => '0.1.1',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::HTMLify',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Plack::Middleware' => '0',
    'Plack::Util' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
