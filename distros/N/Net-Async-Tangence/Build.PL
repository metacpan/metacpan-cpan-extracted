use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::Tangence',
   requires => {
      'Encode' => 0,
      'Exporter' => '5.57',
      'Future' => 0,
      'IO::Async::Listener' => '0.36',
      'IO::Async::Loop' => '0.16',
      'IO::Async::Stream' => 0,
      'IO::Async::Test' => 0,
      'Tangence::Client' => '0.25', # ->get_registry
      'Tangence::Server' => '0.19',
      'URI' => 0,
   },
   build_requires => {
      'Test::Fatal' => '0.006',
      'Test::HexString' => 0,
      'Test::Identity' => 0,
      'Test::Memory::Cycle' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
