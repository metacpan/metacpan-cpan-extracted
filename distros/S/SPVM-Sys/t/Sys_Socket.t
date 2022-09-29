use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes;

use Socket;
use IO::Socket::INET;

use SPVM 'Sys::Socket';
use SPVM 'TestCase::Sys::Socket';

sub search_available_port {
  my $retry_port = 20000;
  
  my $port;
  my $retry_max = 10;
  my $retry_count = 0;
  while (1) {
    if ($retry_count > 0) {
      warn "[Test Output]Perform the ${retry_count} retry to search an available port $retry_port";
    }
    
    if ($retry_count > $retry_max) {
      die "Can't find an available port";
    }
    
    my $server_socket = IO::Socket::INET->new(
      LocalPort => $port,
      Listen    => SOMAXCONN,
      Proto     => 'tcp',
      Timeout => 5,
      ReuseAddr => 1,
    );
    
    if ($server_socket) {
      $port = $retry_port;
      last;
    }

    $retry_port++;
    $retry_count++;
  }
  
  return $port;
}

sub wait_port_prepared {
  my ($port) = @_;
  
  my $max_wait = 3;
  my $wait_time = 0.1;
  my $wait_total = 0;
  while (1) {
    if ($wait_total > $max_wait) {
      last;
    }
    
    sleep $wait_time;
    
    my $sock = IO::Socket::INET->new(
      Proto    => 'tcp',
      PeerAddr => "127.0.0.1",
      PeerPort => $port,
    );
    
    if ($sock) {
      last;
    }
    $wait_total += $wait_time;
    $wait_time *= 2;
  }
}

# Starts a echo server
# if "\0" is sent, the server will stop.
sub start_echo_server {
  my ($port) = @_;
  
  my $server_socket = IO::Socket::INET->new(
    LocalPort => $port,
    Listen    => SOMAXCONN,
    Proto     => 'tcp',
    ReuseAddr => 1,
  );
  unless ($server_socket) {
    die "Can't create a server socket:$@";
  }
  
  my $server_close;
  while (1) {
    my $client_socket = $server_socket->accept;
    
    $client_socket->autoflush(1);
    
    my $data;
    while ($data = <$client_socket>) {
      print $client_socket $data;
    }
  }
}

my $port = 20000;

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

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

if ($^O eq 'MSWin32') {
  
}
else {
  
}

ok(SPVM::TestCase::Sys::Socket->socket);

# Sys::Socket::Sockaddr
{
  my $port = &search_available_port;
  ok(SPVM::TestCase::Sys::Socket->sockaddr($port));
}

# connect
{
  my $process_id = fork;

  my $port = &search_available_port;
  
  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->connect($port));
    
    kill 'TERM', $process_id;
  }
}

# close
{
  my $process_id = fork;

  my $port = &search_available_port;
  
  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->close($port));
    
    kill 'TERM', $process_id;
  }
}

# shutdown
{
  my $process_id = fork;

  my $port = &search_available_port;
  
  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->shutdown($port));
    
    kill 'TERM', $process_id;
  }
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
