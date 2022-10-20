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

use SPVM 'Sys::Select';
use SPVM 'TestCase::Sys::Select';

my $localhost = "127.0.0.1";

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Port
my $port = TestUtil::Socket::search_available_port;

# FD_ZERO
# FD_SET
# FD_CLR
# FD_ISSET
ok(SPVM::TestCase::Sys::Select->select_utils);

# select
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    ok(SPVM::TestCase::Sys::Select->select($port));
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

SPVM::set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
