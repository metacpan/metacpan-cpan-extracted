
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Remove multiple slashes in your paths automatically',
  'dist_author' => [
    'Sawyer X <xsawyerx@cpan.org>'
  ],
  'dist_name' => 'Plack-Middleware-NoMultipleSlashes',
  'dist_version' => '0.001',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::NoMultipleSlashes',
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
