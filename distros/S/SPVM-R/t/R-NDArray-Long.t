use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray::Long';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray::Long->data);
ok(SPVM::TestCase::R::NDArray::Long->new);
ok(SPVM::TestCase::R::NDArray::Long->create_default_data);
ok(SPVM::TestCase::R::NDArray::Long->elem_to_string);
ok(SPVM::TestCase::R::NDArray::Long->elem_assign);
ok(SPVM::TestCase::R::NDArray::Long->elem_assign);
ok(SPVM::TestCase::R::NDArray::Long->elem_clone);
ok(SPVM::TestCase::R::NDArray::Long->elem_cmp);
ok(SPVM::TestCase::R::NDArray::Long->clone);
ok(SPVM::TestCase::R::NDArray::Long->slice);
ok(SPVM::TestCase::R::NDArray::Long->to_int_ndarray);
ok(SPVM::TestCase::R::NDArray::Long->to_float_ndarray);
ok(SPVM::TestCase::R::NDArray::Long->to_double_ndarray);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
