use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::HTTP::Server',
   requires => {
      'perl' => '5.014',

      'HTTP::Request' => 0,
      'IO::Async' => '0.54',
      'IO::Async::Listener' => '0.61',
      'Metrics::Any' => '0.05',
   },
   test_requires => {
      'HTTP::Response' => 0,
      'IO::Async::Test' => 0,
      'Test::Metrics::Any' => 0,
      'Test2::V0' => '0.000147',
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
