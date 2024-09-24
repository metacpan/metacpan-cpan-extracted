use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::NDArray';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::NDArray->data);
ok(SPVM::TestCase::R::NDArray->set_data);
ok(SPVM::TestCase::R::NDArray->dim);
ok(SPVM::TestCase::R::NDArray->set_dim);
ok(SPVM::TestCase::R::NDArray->is_dim_read_only);
ok(SPVM::TestCase::R::NDArray->make_dim_read_only);
ok(SPVM::TestCase::R::NDArray->nrow);
ok(SPVM::TestCase::R::NDArray->ncol);
ok(SPVM::TestCase::R::NDArray->length);
ok(SPVM::TestCase::R::NDArray->is_empty);
ok(SPVM::TestCase::R::NDArray->is_scalar);
ok(SPVM::TestCase::R::NDArray->is_vector);
ok(SPVM::TestCase::R::NDArray->is_matrix);
ok(SPVM::TestCase::R::NDArray->is_square_matrix);
ok(SPVM::TestCase::R::NDArray->drop_dim);
ok(SPVM::TestCase::R::NDArray->expand_dim);
ok(SPVM::TestCase::R::NDArray->create_default_data);
ok(SPVM::TestCase::R::NDArray->elem_to_string);
ok(SPVM::TestCase::R::NDArray->elem_assign);
ok(SPVM::TestCase::R::NDArray->elem_clone);
ok(SPVM::TestCase::R::NDArray->elem_cmp);
ok(SPVM::TestCase::R::NDArray->to_string_ndarray);
ok(SPVM::TestCase::R::NDArray->elem_size);
ok(SPVM::TestCase::R::NDArray->elem_type_name);
ok(SPVM::TestCase::R::NDArray->is_numeric_ndarray);
ok(SPVM::TestCase::R::NDArray->is_mulnum_ndarray);
ok(SPVM::TestCase::R::NDArray->is_any_numeric_ndarray);
ok(SPVM::TestCase::R::NDArray->is_object_ndarray);
ok(SPVM::TestCase::R::NDArray->clone);
ok(SPVM::TestCase::R::NDArray->slice);
ok(SPVM::TestCase::R::NDArray->slice_set);
ok(SPVM::TestCase::R::NDArray->to_string);
ok(SPVM::TestCase::R::NDArray->order);
ok(SPVM::TestCase::R::NDArray->set_order);
ok(SPVM::TestCase::R::NDArray->sort_asc);
ok(SPVM::TestCase::R::NDArray->sort_desc);


my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
