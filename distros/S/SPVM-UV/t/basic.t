use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'TestCase::UV';

use SPVM 'UV';
use SPVM::UV;

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::UV->test);
ok(SPVM::TestCase::UV->poll);
ok(SPVM::TestCase::UV->timer);
ok(SPVM::TestCase::UV->idle);
ok(SPVM::TestCase::UV->async);
ok(SPVM::TestCase::UV->pipe);


# Version check
is($SPVM::UV::VERSION, $api->get_version_string("UV"));

$api->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
