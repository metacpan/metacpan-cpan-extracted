use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build" };

use SPVM 'TestCase::IO::Dir';

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

ok(SPVM::TestCase::IO::Dir->new);

ok(SPVM::TestCase::IO::Dir->open);

ok(SPVM::TestCase::IO::Dir->read);

ok(SPVM::TestCase::IO::Dir->seek);

ok(SPVM::TestCase::IO::Dir->tell);

ok(SPVM::TestCase::IO::Dir->rewind);

ok(SPVM::TestCase::IO::Dir->close);

ok(SPVM::TestCase::IO::Dir->opened);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
