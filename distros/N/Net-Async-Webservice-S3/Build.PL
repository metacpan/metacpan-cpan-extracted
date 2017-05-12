use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::Webservice::S3',
   requires => {
      'Digest::HMAC_SHA1' => 0,
      'Digest::MD5' => 0,
      'Future' => '0.21',
      'IO::Async::Stream' => '0.57',
      'IO::Async::Timer::Countdown' => 0,
      'HTTP::Date' => 0,
      'HTTP::Request' => 0,
      'MIME::Base64' => 0,
      'Net::Async::HTTP' => '0.33',
      'URI::Escape' => 0,
      'XML::LibXML' => 0,
   },
   recommends => {
      'IO::Async::SSL' => 0,
   },
   build_requires => {
      'IO::Async::Test' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
