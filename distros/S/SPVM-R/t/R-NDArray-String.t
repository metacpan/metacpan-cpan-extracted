use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::String';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::String->data);
ok(SPVM::TestCase::R::NDArray::String->new);
ok(SPVM::TestCase::R::NDArray::String->create_default_data);
ok(SPVM::TestCase::R::NDArray::String->elem_to_string);
ok(SPVM::TestCase::R::NDArray::String->elem_assign);
ok(SPVM::TestCase::R::NDArray::String->elem_assign);
ok(SPVM::TestCase::R::NDArray::String->elem_clone);
ok(SPVM::TestCase::R::NDArray::String->elem_cmp);
ok(SPVM::TestCase::R::NDArray::String->clone);
ok(SPVM::TestCase::R::NDArray::String->slice);
ok(SPVM::TestCase::R::NDArray::String->to_string_buffer_ndarray);
ok(SPVM::TestCase::R::NDArray::String->to_time_piece_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
