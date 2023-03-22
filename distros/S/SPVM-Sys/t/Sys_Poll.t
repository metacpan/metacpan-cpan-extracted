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

use SPVM 'Sys::Poll';
use SPVM 'TestCase::Sys::Poll';
use SPVM 'Sys::Poll::Constant';

my $localhost = "127.0.0.1";

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# Port
my $port = TestUtil::Socket::search_available_port;

warn "[Test Output]$port";

# poll
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Poll->poll($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

# poll constant values
unless ($^O eq 'MSWin32') {
  is(SPVM::Sys::Poll::Constant->POLLERR, IO::Poll::POLLERR());
  is(SPVM::Sys::Poll::Constant->POLLHUP, IO::Poll::POLLHUP());
  is(SPVM::Sys::Poll::Constant->POLLIN, IO::Poll::POLLIN());
  is(SPVM::Sys::Poll::Constant->POLLNVAL, IO::Poll::POLLNVAL());
  is(SPVM::Sys::Poll::Constant->POLLOUT, IO::Poll::POLLOUT());
  is(SPVM::Sys::Poll::Constant->POLLPRI, IO::Poll::POLLPRI());
  is(SPVM::Sys::Poll::Constant->POLLRDBAND, IO::Poll::POLLRDBAND());
  is(SPVM::Sys::Poll::Constant->POLLRDNORM, IO::Poll::POLLRDNORM());
  is(SPVM::Sys::Poll::Constant->POLLWRBAND, IO::Poll::POLLWRBAND());
  is(SPVM::Sys::Poll::Constant->POLLWRNORM, IO::Poll::POLLWRNORM());
}


SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
