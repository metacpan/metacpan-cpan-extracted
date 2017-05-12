use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::FastCGI',
   requires => {
      'Encode' => 0,
      'Exporter' => '5.57',
      'HTTP::Request' => 0,
      'HTTP::Response' => 0,
      'IO::Async::Listener' => '0.35',
      'IO::Async::Loop' => '0.16',
      'IO::Async::Protocol::Stream' => '0.33',
      'IO::Async::Test' => 0,
      'Net::FastCGI::Constant' => '0.10',
      'Net::FastCGI::Protocol' => '0.10',
      'Tie::Handle' => 0,
   },
   build_requires => {
      'Test::HexString' => 0,
      'Test::More' => 0,
      'Test::Refcount' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;
