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
use TestUtil::ServerRunner;

use SPVM 'Sys::Select';
use SPVM 'TestCase::Sys::Select';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# FD_ZERO
# FD_SET
# FD_CLR
# FD_ISSET
ok(SPVM::TestCase::Sys::Select->select_utils);

# select
{
  my $server = TestUtil::ServerRunner->new(
    code => sub {
      my ($port) = @_;
      
      TestUtil::ServerRunner->run_echo_server($port);
    },
  );
  
  ok(SPVM::TestCase::Sys::Select->select($server->port));
}

SPVM::api->set_exception(undef);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
