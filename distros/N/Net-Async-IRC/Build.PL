use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::IRC',
   requires => {
      'IO::Async::Loop' => '0.54', # ->connect Future
      'IO::Async::Stream' => '0.59', # Protocol deprecation
      'Protocol::IRC::Client' => '0.12',
      'Time::HiRes' => 0,
      'perl' => '5.010', # //, mro c3
   },
   test_requires => {
      'IO::Async::OS' => 0,
      'IO::Async::Test' => 0.14,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
