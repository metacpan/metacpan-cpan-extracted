use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes 'usleep';

use Socket;
use IO::Socket;
use IO::Socket::IP;
use Test::SPVM::Sys::Socket::ServerManager::IP;
use Test::SPVM::Sys::Socket::Util;
use Test::SPVM::Sys::Socket::Server;

use SPVM 'Sys::Socket';
use SPVM 'TestCase::Sys::Socket';
use SPVM 'Sys::Socket::Constant';

my $ipv6_available = Test::SPVM::Sys::Socket::Util::can_bind('::1');

unless ($ipv6_available) {
  plan skip_all => "IPv6 not available";
}

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# connect
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv6_tcp(port => $port);
      
      $server->start;
    },
    host => '::1'
  );
  
  ok(SPVM::TestCase::Sys::Socket->connect_ipv6($server->port));
}

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
