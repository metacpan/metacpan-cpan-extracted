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

my $localhost = "127.0.0.1";

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# The constant values
{
  is(SPVM::Sys::Socket::Constant->AF_INET, Socket::AF_INET);
  is(SPVM::Sys::Socket::Constant->AF_INET6, Socket::AF_INET6);
  
  eval { SPVM::Sys::Socket::Constant->AF_UNIX };
  if ($@) {
    warn "[Test Output]AF_UNIX is not supported";
  }
  else {
    is(SPVM::Sys::Socket::Constant->AF_INET6, Socket::AF_INET6);
  }
  is(SPVM::Sys::Socket::Constant->SOCK_STREAM, Socket::SOCK_STREAM);
  is(SPVM::Sys::Socket::Constant->SOCK_DGRAM, Socket::SOCK_DGRAM);
  is(SPVM::Sys::Socket::Constant->SOCK_RAW, Socket::SOCK_RAW);

  is(SPVM::Sys::Socket::Constant->SHUT_RD, Socket::SHUT_RD);
  is(SPVM::Sys::Socket::Constant->SHUT_RD, 0);
  is(SPVM::Sys::Socket::Constant->SHUT_WR, Socket::SHUT_WR);
  is(SPVM::Sys::Socket::Constant->SHUT_WR, 1);
  is(SPVM::Sys::Socket::Constant->SHUT_RDWR, Socket::SHUT_RDWR);
  is(SPVM::Sys::Socket::Constant->SHUT_RDWR, 2);
}

# The endian methods
{
  # htonl
  {
    ok(SPVM::TestCase::Sys::Socket->htonl);
    ok(SPVM::TestCase::Sys::Socket->ntohl);
    ok(SPVM::TestCase::Sys::Socket->htons);
    ok(SPVM::TestCase::Sys::Socket->ntohs);
  }
}

ok(SPVM::TestCase::Sys::Socket->inet_aton);
ok(SPVM::TestCase::Sys::Socket->inet_pton);
ok(SPVM::TestCase::Sys::Socket->inet_ntoa);
ok(SPVM::TestCase::Sys::Socket->inet_ntop);

ok(SPVM::TestCase::Sys::Socket->socket);

# Sys::Socket::Sockaddr
{
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  ok(SPVM::TestCase::Sys::Socket->sockaddr($port));
}

# connect
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->connect($server->port));
}

# close
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->close($server->port));
}

# shutdown
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->shutdown($server->port));
}

# send and recv
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->send_and_recv($server->port));
}

# sendto and recvfrom
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->sendto_and_recvfrom($server->port));
}

{
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  ok(SPVM::TestCase::Sys::Socket->bind($port));
}

{
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  ok(SPVM::TestCase::Sys::Socket->listen($port));
}
# accept
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  my $sock = IO::Socket::IP->new(
    Proto    => 'tcp',
    PeerAddr => $localhost,
    PeerPort => $server->port,
  );
  
  ok($sock);
  
  $sock->autoflush(1);
  
  $sock->send("abc");
  
  $sock->shutdown(IO::Socket::SHUT_WR);
  
  my $buffer;
  $sock->recv($buffer, 3);
  
  is($buffer, "abc");
  
  $sock->close;
}

# getpeername
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->getpeername($server->port));
}

# getsockname
{
  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );
  
  ok(SPVM::TestCase::Sys::Socket->getsockname($server ->port));
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Socket->socketpair(0, 0, 0, undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Socket->socketpair);
}

{
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  ok(SPVM::TestCase::Sys::Socket->setsockopt_int($port));
}
{
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  ok(SPVM::TestCase::Sys::Socket->getsockopt_int($port));
}

ok(SPVM::TestCase::Sys::Socket->sockaddr_un);

ok(SPVM::TestCase::Sys::Socket->sockaddr_strage);

ok(SPVM::TestCase::Sys::Socket->getaddrinfo);

ok(SPVM::TestCase::Sys::Socket->getnameinfo);

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
