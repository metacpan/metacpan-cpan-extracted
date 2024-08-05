use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Matrix::Float';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Matrix::Float->matrix);
ok(SPVM::TestCase::R::OP::Matrix::Float->matrix_byrow);
ok(SPVM::TestCase::R::OP::Matrix::Float->cbind);
ok(SPVM::TestCase::R::OP::Matrix::Float->rbind);
ok(SPVM::TestCase::R::OP::Matrix::Float->diag);
ok(SPVM::TestCase::R::OP::Matrix::Float->slice_diag);
ok(SPVM::TestCase::R::OP::Matrix::Float->identity);
ok(SPVM::TestCase::R::OP::Matrix::Float->mul);
ok(SPVM::TestCase::R::OP::Matrix::Float->t);
ok(SPVM::TestCase::R::OP::Matrix::Float->det);
ok(SPVM::TestCase::R::OP::Matrix::Float->solve);
ok(SPVM::TestCase::R::OP::Matrix::Float->eigen);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
