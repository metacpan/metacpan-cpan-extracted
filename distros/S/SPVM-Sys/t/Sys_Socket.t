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
use TestUtil::Socket;

use SPVM 'Sys::Socket';
use SPVM 'TestCase::Sys::Socket';
use SPVM 'Sys::Socket::Constant';

my $localhost = "127.0.0.1";

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# Port
my $port = TestUtil::Socket::search_available_port;

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
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->connect($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# close
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->close($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# shutdown
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->shutdown($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# send and recv
{
  
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->send_and_recv($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
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
    TestUtil::Socket::wait_port_prepared($port);
    
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
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# getpeername
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->getpeername($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# getsockname
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Socket->getsockname($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
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

unless ($^O eq 'MSWin32') {
  ok(SPVM::TestCase::Sys::Socket->sockaddr_un);
}

ok(SPVM::TestCase::Sys::Socket->sockaddr_strage);

ok(SPVM::TestCase::Sys::Socket->getaddrinfo);

ok(SPVM::TestCase::Sys::Socket->getnameinfo);

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
