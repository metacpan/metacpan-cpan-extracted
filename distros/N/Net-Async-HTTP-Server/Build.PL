use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::HTTP::Server',
   requires => {
      'HTTP::Request' => 0,
      'IO::Async' => '0.54',
      'IO::Async::Listener' => '0.61',
      'Metrics::Any' => 0,
   },
   test_requires => {
      'HTTP::Response' => 0,
      'IO::Async::Test' => 0,
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
