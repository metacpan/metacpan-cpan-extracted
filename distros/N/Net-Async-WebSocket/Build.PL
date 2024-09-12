use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::WebSocket',
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   requires => {
      'perl' => '5.014',
      'meta' => '0.008',

      'IO::Async::Listener' => '0.61', # handle_class
      'IO::Async::Notifier' => '0.63', # ->adopt_future
      'IO::Async::Stream' => '0.34',
      'Protocol::WebSocket' => '0.22', # Frame->masked accessor
      'Protocol::WebSocket::Frame' => 0,
      'Protocol::WebSocket::Handshake::Client' => 0,
      'Protocol::WebSocket::Handshake::Server' => 0,
      'URI' => 0,
      'URI::wss' => 0,
   },
   test_requires => {
      'IO::Async::OS' => 0,
      'Test2::V0' => 0,
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
