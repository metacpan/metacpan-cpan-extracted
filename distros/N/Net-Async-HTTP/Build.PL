use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::HTTP',
   requires => {
      'perl' => '5.014',

      'Future' => '0.28', # ->set_label
      'Future::Utils' => '0.16',
      'HTTP::Request' => 0,
      'HTTP::Request::Common' => 0,
      'HTTP::Response' => 0,
      'IO::Async::Loop' => '0.59',
      'IO::Async::Stream' => '0.59',
      'IO::Async::Timer::Countdown' => 0,
      'List::Util' => "1.29", # pairs()
      'Metrics::Any' => '0.05',
      'Socket' => '2.010',
      'Struct::Dumb' => '0.07',
      'Time::HiRes' => 0,
      'URI' => 0,
   },
   recommends => {
      'Compress::Raw::Zlib' => '2.057', # Fails with Compress::Raw::Zlib 2.056 or before
   },
   build_requires => {
      'HTTP::Cookies' => 0,
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
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.perl.org/#io-async",
      },
   },
);

$build->create_build_script;
