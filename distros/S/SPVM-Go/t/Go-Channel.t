use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Go::Channel';

# Start objects count
my $api = SPVM::api();
my $start_memory_blocks_count = $api->get_memory_blocks_count();

ok(SPVM::TestCase::Go::Channel->unbuffered_minimal);

ok(SPVM::TestCase::Go::Channel->unbuffered);

ok(SPVM::TestCase::Go::Channel->buffered_minimal);

ok(SPVM::TestCase::Go::Channel->buffered);

ok(SPVM::TestCase::Go::Channel->cap);

ok(SPVM::TestCase::Go::Channel->len);

ok(SPVM::TestCase::Go::Channel->close);

ok(SPVM::TestCase::Go::Channel->extra);

ok(SPVM::TestCase::Go::Channel->exception);

# All object is freed
$api->set_exception(undef);
my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
