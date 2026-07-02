use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::Resource::Coro';

use SPVM 'Resource::Coro';
use SPVM::Resource::Coro;

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Resource::Coro->test);

# Version check
is($SPVM::Resource::Coro::VERSION, $api->get_version_string("Resource::Coro"));

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
