use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Matrix::FloatComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->matrix);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->matrix_byrow);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->cbind);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->rbind);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->diag);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->slice_diag);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->identity);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->mul);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->t);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->det);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->solve);
ok(SPVM::TestCase::R::OP::Matrix::FloatComplex->eigen);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
