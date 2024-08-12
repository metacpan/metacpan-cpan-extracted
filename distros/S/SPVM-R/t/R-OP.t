use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP->equals_dim);
ok(SPVM::TestCase::R::OP->equals_dropped_dim);
ok(SPVM::TestCase::R::OP->rep);
ok(SPVM::TestCase::R::OP->rep_length);
ok(SPVM::TestCase::R::OP->is_na);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
