
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Data::Dumper' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::XML' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Sets the Accept header based on the suffix or query params of a request',
  'dist_author' => [
    'Rob Hoelz <rob@hoelz.ro>'
  ],
  'dist_name' => 'Plack-Middleware-SetAccept',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::SetAccept',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'List::MoreUtils' => '0',
    'Plack' => '0',
    'URI' => '0',
    'parent' => '0',
    'perl' => '5.8.9'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
