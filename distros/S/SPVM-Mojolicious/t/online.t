use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'Fn';
use SPVM 'TestCase::Online';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count();

ok(SPVM::TestCase::Online->one_get_request);

ok(SPVM::TestCase::Online->one_get_request_https);

ok(SPVM::TestCase::Online->one_get_request_redirect);

ok(SPVM::TestCase::Online->test_keep_alive_no_redirect);

ok(SPVM::TestCase::Online->test_https_tiny);

ok(SPVM::TestCase::Online->test_http_tiny);

ok(SPVM::TestCase::Online->go);

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
