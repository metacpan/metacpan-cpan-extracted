use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::FloatComplex';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::FloatComplex->c);
ok(SPVM::TestCase::R::OP::FloatComplex->add);
ok(SPVM::TestCase::R::OP::FloatComplex->sub);
ok(SPVM::TestCase::R::OP::FloatComplex->mul);
ok(SPVM::TestCase::R::OP::FloatComplex->div);
ok(SPVM::TestCase::R::OP::FloatComplex->neg);
ok(SPVM::TestCase::R::OP::FloatComplex->abs);
ok(SPVM::TestCase::R::OP::FloatComplex->re);
ok(SPVM::TestCase::R::OP::FloatComplex->im);
ok(SPVM::TestCase::R::OP::FloatComplex->conj);
ok(SPVM::TestCase::R::OP::FloatComplex->arg);
ok(SPVM::TestCase::R::OP::FloatComplex->eq);
ok(SPVM::TestCase::R::OP::FloatComplex->ne);
ok(SPVM::TestCase::R::OP::FloatComplex->rep);
ok(SPVM::TestCase::R::OP::FloatComplex->rep_length);
ok(SPVM::TestCase::R::OP::FloatComplex->sin);
ok(SPVM::TestCase::R::OP::FloatComplex->cos);
ok(SPVM::TestCase::R::OP::FloatComplex->tan);
ok(SPVM::TestCase::R::OP::FloatComplex->sinh);
ok(SPVM::TestCase::R::OP::FloatComplex->cosh);
ok(SPVM::TestCase::R::OP::FloatComplex->tanh);
ok(SPVM::TestCase::R::OP::FloatComplex->acos);
ok(SPVM::TestCase::R::OP::FloatComplex->asin);
ok(SPVM::TestCase::R::OP::FloatComplex->atan);
ok(SPVM::TestCase::R::OP::FloatComplex->asinh);
ok(SPVM::TestCase::R::OP::FloatComplex->acosh);
ok(SPVM::TestCase::R::OP::FloatComplex->atanh);
ok(SPVM::TestCase::R::OP::FloatComplex->exp);
ok(SPVM::TestCase::R::OP::FloatComplex->log);
ok(SPVM::TestCase::R::OP::FloatComplex->sqrt);
ok(SPVM::TestCase::R::OP::FloatComplex->pow);
ok(SPVM::TestCase::R::OP::FloatComplex->sum);
ok(SPVM::TestCase::R::OP::FloatComplex->cumsum);
ok(SPVM::TestCase::R::OP::FloatComplex->prod);
ok(SPVM::TestCase::R::OP::FloatComplex->cumprod);
ok(SPVM::TestCase::R::OP::FloatComplex->diff);
ok(SPVM::TestCase::R::OP::FloatComplex->mean);
ok(SPVM::TestCase::R::OP::FloatComplex->dot);
ok(SPVM::TestCase::R::OP::FloatComplex->outer);
ok(SPVM::TestCase::R::OP::FloatComplex->pi);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
