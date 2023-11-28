use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Go::Coroutine';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

ok(SPVM::TestCase::Go::Coroutine->transfer_minimal);

ok(SPVM::TestCase::Go::Coroutine->transfer_create_many_objects);

ok(SPVM::TestCase::Go::Coroutine->transfer);

ok(SPVM::TestCase::Go::Coroutine->die);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
