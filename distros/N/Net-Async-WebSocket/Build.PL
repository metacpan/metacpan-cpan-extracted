use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::WebSocket',
   requires => {
      'IO::Async::Listener' => '0.61', # handle_class
      'IO::Async::Notifier' => '0.63', # ->adopt_future
      'IO::Async::Stream' => '0.34',
      'Protocol::WebSocket' => '0.00902',
      'Protocol::WebSocket::Frame' => 0,
      'Protocol::WebSocket::Handshake::Client' => 0,
      'Protocol::WebSocket::Handshake::Server' => 0,
      'URI' => 0,
   },
   build_requires => {
      'IO::Async::OS' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
