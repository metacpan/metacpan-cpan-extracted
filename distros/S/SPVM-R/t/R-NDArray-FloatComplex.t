use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::FloatComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::FloatComplex->data);
ok(SPVM::TestCase::R::NDArray::FloatComplex->new);
ok(SPVM::TestCase::R::NDArray::FloatComplex->create_default_data);
ok(SPVM::TestCase::R::NDArray::FloatComplex->elem_to_string);
ok(SPVM::TestCase::R::NDArray::FloatComplex->elem_assign);
ok(SPVM::TestCase::R::NDArray::FloatComplex->elem_assign);
ok(SPVM::TestCase::R::NDArray::FloatComplex->elem_clone);
ok(SPVM::TestCase::R::NDArray::FloatComplex->elem_cmp);
ok(SPVM::TestCase::R::NDArray::FloatComplex->clone);
ok(SPVM::TestCase::R::NDArray::FloatComplex->slice);
ok(SPVM::TestCase::R::NDArray::FloatComplex->to_double_complex_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
