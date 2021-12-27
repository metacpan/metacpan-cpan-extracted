use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::IRC',
   requires => {
      'Future::AsyncAwait' => '0.47', # toplevel await
      'IO::Async::Loop' => '0.54', # ->connect Future
      'IO::Async::Stream' => '0.59', # Protocol deprecation
      'List::Util' => '1.33',
      'MIME::Base64' => 0,
      'Protocol::IRC::Client' => '0.13',
      'Time::HiRes' => 0,

      'perl' => '5.014',
   },
   test_requires => {
      'IO::Async::OS' => 0,
      'IO::Async::Test' => 0.14,
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
