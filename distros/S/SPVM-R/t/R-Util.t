use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::Util';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::Util->calc_data_length);
ok(SPVM::TestCase::R::Util->normalize_dim);
ok(SPVM::TestCase::R::Util->is_normalized_dim);
ok(SPVM::TestCase::R::Util->check_length);
ok(SPVM::TestCase::R::Util->drop_dim);
ok(SPVM::TestCase::R::Util->expand_dim);
ok(SPVM::TestCase::R::Util->equals_dim);
ok(SPVM::TestCase::R::Util->equals_dropped_dim);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
