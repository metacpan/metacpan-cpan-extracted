use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::DoubleComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::DoubleComplex->c);
ok(SPVM::TestCase::R::OP::DoubleComplex->add);
ok(SPVM::TestCase::R::OP::DoubleComplex->sub);
ok(SPVM::TestCase::R::OP::DoubleComplex->mul);
ok(SPVM::TestCase::R::OP::DoubleComplex->div);
ok(SPVM::TestCase::R::OP::DoubleComplex->neg);
ok(SPVM::TestCase::R::OP::DoubleComplex->abs);
ok(SPVM::TestCase::R::OP::DoubleComplex->re);
ok(SPVM::TestCase::R::OP::DoubleComplex->im);
ok(SPVM::TestCase::R::OP::DoubleComplex->conj);
ok(SPVM::TestCase::R::OP::DoubleComplex->arg);
ok(SPVM::TestCase::R::OP::DoubleComplex->eq);
ok(SPVM::TestCase::R::OP::DoubleComplex->ne);
ok(SPVM::TestCase::R::OP::DoubleComplex->rep);
ok(SPVM::TestCase::R::OP::DoubleComplex->rep_length);
ok(SPVM::TestCase::R::OP::DoubleComplex->sin);
ok(SPVM::TestCase::R::OP::DoubleComplex->cos);
ok(SPVM::TestCase::R::OP::DoubleComplex->tan);
ok(SPVM::TestCase::R::OP::DoubleComplex->sinh);
ok(SPVM::TestCase::R::OP::DoubleComplex->cosh);
ok(SPVM::TestCase::R::OP::DoubleComplex->tanh);
ok(SPVM::TestCase::R::OP::DoubleComplex->acos);
ok(SPVM::TestCase::R::OP::DoubleComplex->asin);
ok(SPVM::TestCase::R::OP::DoubleComplex->atan);
ok(SPVM::TestCase::R::OP::DoubleComplex->asinh);
ok(SPVM::TestCase::R::OP::DoubleComplex->acosh);
ok(SPVM::TestCase::R::OP::DoubleComplex->atanh);
ok(SPVM::TestCase::R::OP::DoubleComplex->exp);
ok(SPVM::TestCase::R::OP::DoubleComplex->log);
ok(SPVM::TestCase::R::OP::DoubleComplex->sqrt);
ok(SPVM::TestCase::R::OP::DoubleComplex->pow);
ok(SPVM::TestCase::R::OP::DoubleComplex->sum);
ok(SPVM::TestCase::R::OP::DoubleComplex->cumsum);
ok(SPVM::TestCase::R::OP::DoubleComplex->prod);
ok(SPVM::TestCase::R::OP::DoubleComplex->cumprod);
ok(SPVM::TestCase::R::OP::DoubleComplex->diff);
ok(SPVM::TestCase::R::OP::DoubleComplex->mean);
ok(SPVM::TestCase::R::OP::DoubleComplex->dot);
ok(SPVM::TestCase::R::OP::DoubleComplex->outer);
ok(SPVM::TestCase::R::OP::DoubleComplex->pi);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
