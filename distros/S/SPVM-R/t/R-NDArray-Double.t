use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::Double';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::Double->data);
ok(SPVM::TestCase::R::NDArray::Double->new);
ok(SPVM::TestCase::R::NDArray::Double->create_default_data);
ok(SPVM::TestCase::R::NDArray::Double->elem_to_string);
ok(SPVM::TestCase::R::NDArray::Double->elem_assign);
ok(SPVM::TestCase::R::NDArray::Double->elem_assign);
ok(SPVM::TestCase::R::NDArray::Double->elem_clone);
ok(SPVM::TestCase::R::NDArray::Double->elem_cmp);
ok(SPVM::TestCase::R::NDArray::Double->clone);
ok(SPVM::TestCase::R::NDArray::Double->slice);
ok(SPVM::TestCase::R::NDArray::Double->to_int_ndarray);
ok(SPVM::TestCase::R::NDArray::Double->to_long_ndarray);
ok(SPVM::TestCase::R::NDArray::Double->to_float_ndarray);
ok(SPVM::TestCase::R::NDArray::Double->to_double_complex_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
