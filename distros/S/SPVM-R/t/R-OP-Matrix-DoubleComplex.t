use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Matrix::DoubleComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->matrix);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->matrix_byrow);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->cbind);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->rbind);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->diag);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->slice_diag);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->identity);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->mul);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->t);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->det);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->solve);
ok(SPVM::TestCase::R::OP::Matrix::DoubleComplex->eigen);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
