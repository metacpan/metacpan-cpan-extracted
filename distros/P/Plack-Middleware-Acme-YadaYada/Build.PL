
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Middleware that handles the Yada Yada operator',
  'dist_author' => [
    'Rob Hoelz <rob@hoelz.ro>'
  ],
  'dist_name' => 'Plack-Middleware-Acme-YadaYada',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::Acme::YadaYada',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Plack' => '0',
    'Try::Tiny' => '0',
    'parent' => '0',
    'perl' => '5.12.0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
