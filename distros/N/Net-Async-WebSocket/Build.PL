use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::WebSocket',
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   requires => {
      'IO::Async::Listener' => '0.61', # handle_class
      'IO::Async::Notifier' => '0.63', # ->adopt_future
      'IO::Async::Stream' => '0.34',
      'Protocol::WebSocket' => '0.22', # Frame->masked accessor
      'Protocol::WebSocket::Frame' => 0,
      'Protocol::WebSocket::Handshake::Client' => 0,
      'Protocol::WebSocket::Handshake::Server' => 0,
      'Sub::Util' => '1.40', # set_subname
      'URI' => 0,
      'perl' => '5.010', # //
   },
   test_requires => {
      'IO::Async::OS' => 0,
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
