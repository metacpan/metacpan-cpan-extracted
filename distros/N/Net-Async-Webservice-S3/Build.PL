use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::Webservice::S3',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'Digest::HMAC_SHA1' => 0,
      'Digest::MD5' => 0,
      'Future' => '0.26',
      'IO::Async::Stream' => '0.57',
      'IO::Async::Timer::Countdown' => 0,
      'HTTP::Date' => 0,
      'HTTP::Request' => 0,
      'MIME::Base64' => 0,
      'Net::Async::HTTP' => '0.33',
      'URI::Escape' => 0,
      'XML::LibXML' => 0,
      'perl' => '5.010', # //
   },
   recommends => {
      'IO::Async::SSL' => 0,
   },
   test_requires => {
      'IO::Async::Test' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Async::HTTP' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
