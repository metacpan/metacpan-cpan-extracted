use strict;
use warnings;
use lib "t/lib";

use Test::More;

use SPVM 'TestCase::Lib::IO::FileHandle';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
