use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Matrix::Double';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Matrix::Double->matrix);
ok(SPVM::TestCase::R::OP::Matrix::Double->matrix_byrow);
ok(SPVM::TestCase::R::OP::Matrix::Double->cbind);
ok(SPVM::TestCase::R::OP::Matrix::Double->rbind);
ok(SPVM::TestCase::R::OP::Matrix::Double->diag);
ok(SPVM::TestCase::R::OP::Matrix::Double->slice_diag);
ok(SPVM::TestCase::R::OP::Matrix::Double->identity);
ok(SPVM::TestCase::R::OP::Matrix::Double->mul);
ok(SPVM::TestCase::R::OP::Matrix::Double->t);
ok(SPVM::TestCase::R::OP::Matrix::Double->det);
ok(SPVM::TestCase::R::OP::Matrix::Double->solve);
ok(SPVM::TestCase::R::OP::Matrix::Double->eigen);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
