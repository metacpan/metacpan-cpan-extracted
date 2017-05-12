
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
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
  'dist_abstract' => 'Plack middleware to minify HTML on-the-fly',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Plack-Middleware-HTMLMinify',
  'dist_version' => '1.0.0',
  'license' => 'bsd',
  'module_name' => 'Plack::Middleware::HTMLMinify',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'HTML::Packer' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
