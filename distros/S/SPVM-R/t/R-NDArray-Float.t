use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::Float';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::Float->data);
ok(SPVM::TestCase::R::NDArray::Float->new);
ok(SPVM::TestCase::R::NDArray::Float->create_default_data);
ok(SPVM::TestCase::R::NDArray::Float->elem_to_string);
ok(SPVM::TestCase::R::NDArray::Float->elem_assign);
ok(SPVM::TestCase::R::NDArray::Float->elem_assign);
ok(SPVM::TestCase::R::NDArray::Float->elem_clone);
ok(SPVM::TestCase::R::NDArray::Float->elem_cmp);
ok(SPVM::TestCase::R::NDArray::Float->clone);
ok(SPVM::TestCase::R::NDArray::Float->slice);
ok(SPVM::TestCase::R::NDArray::Float->to_int_ndarray);
ok(SPVM::TestCase::R::NDArray::Float->to_long_ndarray);
ok(SPVM::TestCase::R::NDArray::Float->to_double_ndarray);
ok(SPVM::TestCase::R::NDArray::Float->to_float_complex_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
