
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Plack middleware to insert Firebug Lite code into HTML.',
  'dist_author' => [
    'Gea-Suan Lin <gslin@gslin.org>'
  ],
  'dist_name' => 'Plack-Middleware-Firebug-Lite',
  'dist_version' => '0.2.3',
  'license' => 'bsd',
  'module_name' => 'Plack::Middleware::Firebug::Lite',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'HTML::Entities' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
