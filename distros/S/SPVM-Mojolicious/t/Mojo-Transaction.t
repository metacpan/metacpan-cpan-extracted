use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Mojo::Transaction';

use SPVM 'Mojolicious';
use SPVM::Mojolicious;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::Mojo::Transaction->basic);

ok(SPVM::TestCase::Mojo::Transaction->server_read);

ok(SPVM::TestCase::Mojo::Transaction->server_write);

ok(SPVM::TestCase::Mojo::Transaction->keep_alive);

SPVM::Fn->destroy_runtime_permanent_vars;

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
