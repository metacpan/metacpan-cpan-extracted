use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::DoubleComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::DoubleComplex->data);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->new);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->create_default_data);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->elem_to_string);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->elem_assign);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->elem_assign);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->elem_clone);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->elem_cmp);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->clone);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->slice);
ok(SPVM::TestCase::R::NDArray::DoubleComplex->to_float_complex_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
