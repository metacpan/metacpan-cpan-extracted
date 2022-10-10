use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes 'usleep';

use Socket;
use IO::Socket;
use IO::Socket::INET;

use SPVM 'Sys::Socket';
use SPVM 'TestCase::Sys::Socket';

my $localhost = "127.0.0.1";

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
      LocalAddr => $localhost,
      LocalPort => $port,
      Listen    => SOMAXCONN,
      Proto     => 'tcp',
      Timeout => 5,
      Reuse => 1,
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
      PeerAddr => $localhost,
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
    LocalAddr => $localhost,
    LocalPort => $port,
    Listen    => SOMAXCONN,
    Proto     => 'tcp',
    Reuse => 1,
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

sub kill_term_and_wait {
  my ($process_id) = @_;
  
  kill 'TERM', $process_id;
  
  # On Windows, waitpid never return. I don't understan yet this reason(maybe IO blocking).
  unless ($^O eq 'MSWin32') {
    waitpid $process_id, 0;
  }
}

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Port
my $port = &search_available_port;

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
  ok(SPVM::TestCase::Sys::Socket->sockaddr($port));
}

# connect
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->connect($port));
    
    kill_term_and_wait $process_id;
  }
}

# close
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->close($port));
    
    kill_term_and_wait $process_id;
  }
}

# shutdown
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->shutdown($port));
    
    kill_term_and_wait $process_id;
  }
}

# send and recv
{
  
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->send_and_recv($port));
    
    kill_term_and_wait $process_id;
  }
}

ok(SPVM::TestCase::Sys::Socket->bind($port));

ok(SPVM::TestCase::Sys::Socket->listen($port));

# accept
# TODO : Windows
unless ($^O eq 'MSWin32') {
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    SPVM::TestCase::Sys::Socket->start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    my $sock = IO::Socket::INET->new(
      Proto    => 'tcp',
      PeerAddr => $localhost,
      PeerPort => $port,
    );

    ok($sock);
    
    $sock->autoflush(1);
    
    $sock->send("abc");
    
    $sock->shutdown(IO::Socket::SHUT_WR);
    
    my $buffer;
    $sock->recv($buffer, 3);
    
    is($buffer, "abc");
    
    $sock->close;
    
    kill_term_and_wait $process_id;
  }
}

# getpeername
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->getpeername($port));
    
    kill_term_and_wait $process_id;
  }
}

# getsockname
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->getsockname($port));
    
    kill_term_and_wait $process_id;
  }
}

if ($^O eq 'MSWin32') {
  eval { SPVM::Sys::Socket->socketpair(0, 0, 0, undef) };
  like($@, qr/not supported/);
}
else {
  ok(SPVM::TestCase::Sys::Socket->socketpair);
}

ok(SPVM::TestCase::Sys::Socket->setsockopt_int($port));
ok(SPVM::TestCase::Sys::Socket->getsockopt_int($port));

if ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::Socket->ioctlsocket($port));
}
else {
  my $num = 0;
  eval { SPVM::Sys::Socket->ioctlsocket(0, 0, \$num) };
  like($@, qr/not supported/);
}

unless ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::Socket->sockaddr_un);
}

ok(SPVM::TestCase::Sys::Socket->sockaddr_strage);

ok(SPVM::TestCase::Sys::Socket->getaddrinfo);

ok(SPVM::TestCase::Sys::Socket->getnameinfo);

# poll
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    &start_echo_server($port);
  }
  else {
    &wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->poll($port));
    
    kill_term_and_wait $process_id;
  }
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
