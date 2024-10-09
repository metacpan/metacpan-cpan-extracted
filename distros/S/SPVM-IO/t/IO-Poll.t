use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'TestCase::IO::Poll';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# Poll
{
  ok(SPVM::TestCase::IO::Poll->new);
  ok(SPVM::TestCase::IO::Poll->set_mask);
  ok(SPVM::TestCase::IO::Poll->mask);
  ok(SPVM::TestCase::IO::Poll->fds);
  ok(SPVM::TestCase::IO::Poll->remove);
  
  if ($^O ne 'MSWin32') {
    ok(SPVM::TestCase::IO::Poll->poll);
    ok(SPVM::TestCase::IO::Poll->events);
  }
}

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
