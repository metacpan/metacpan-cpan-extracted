use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'TestCase::IO::Select';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Select
{
  ok(SPVM::TestCase::IO::Select->add);
  ok(SPVM::TestCase::IO::Select->remove);
  ok(SPVM::TestCase::IO::Select->exists);
  if ($^O ne 'MSWin32') {
    ok(SPVM::TestCase::IO::Select->can_read);
    ok(SPVM::TestCase::IO::Select->can_write);
    ok(SPVM::TestCase::IO::Select->has_exception);
  }
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
