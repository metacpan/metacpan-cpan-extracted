use strict;
use warnings;

use Test::More 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lib";

use SPVM 'SPVMAIUtilTest';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

ok(SPVMAIUtilTest->matrix_float);

ok(SPVMAIUtilTest->matrix_add_float);

ok(SPVMAIUtilTest->matrix_sub_float);

ok(SPVMAIUtilTest->matrix_scamul_float);

ok(SPVMAIUtilTest->matrix_new_zero_float);

ok(SPVMAIUtilTest->matrix_new_ident_float);

ok(SPVMAIUtilTest->matrix_mul_float);

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);


