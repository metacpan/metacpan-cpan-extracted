use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::SPVM::Sys::Socket::ServerManager::UNIX;
use Test::SPVM::Sys::Socket::ServerManager::IP;
use Test::SPVM::Sys::Socket::Util;
use Test::SPVM::Sys::Socket::Server;

# Port
my $port = Test::SPVM::Sys::Socket::Util::get_available_port;

warn "[Test Output]Port:$port";

ok($port >= 20000);

{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
}

{
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
}

ok(1);

done_testing;
