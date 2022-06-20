use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'TestCase::IO::FileHandle';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
