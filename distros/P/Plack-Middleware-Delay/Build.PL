
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'AnyEvent::HTTP' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0',
    'Test::TCP' => '0',
    'Time::HiRes' => '0',
    'Twiggy' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Put delays on your requests',
  'dist_author' => [
    'Rob Hoelz <rob@hoelz.ro>'
  ],
  'dist_name' => 'Plack-Middleware-Delay',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::Delay',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Plack::Middleware' => '0',
    'perl' => '5.8.8'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
