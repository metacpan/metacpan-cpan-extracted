use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Net::Async::WebSocket::JSON',
   configure_requires => {
      'Module::Build' => '0.4004',
   },
   requires => {
      'JSON::MaybeXS' => 0,
      'Net::Async::WebSocket' => '0.11',
      'Net::Async::WebSocket::Server' => '0.11',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
