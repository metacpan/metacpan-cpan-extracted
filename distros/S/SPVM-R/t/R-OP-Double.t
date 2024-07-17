use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Double';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Double->c);
ok(SPVM::TestCase::R::OP::Double->add);
ok(SPVM::TestCase::R::OP::Double->sub);
ok(SPVM::TestCase::R::OP::Double->mul);
ok(SPVM::TestCase::R::OP::Double->scamul);
ok(SPVM::TestCase::R::OP::Double->div);
ok(SPVM::TestCase::R::OP::Double->scadiv);
ok(SPVM::TestCase::R::OP::Double->neg);
ok(SPVM::TestCase::R::OP::Double->abs);
ok(SPVM::TestCase::R::OP::Double->eq);
ok(SPVM::TestCase::R::OP::Double->ne);
ok(SPVM::TestCase::R::OP::Double->gt);
ok(SPVM::TestCase::R::OP::Double->ge);
ok(SPVM::TestCase::R::OP::Double->lt);
ok(SPVM::TestCase::R::OP::Double->le);
ok(SPVM::TestCase::R::OP::Double->rep);
ok(SPVM::TestCase::R::OP::Double->rep_length);
ok(SPVM::TestCase::R::OP::Double->seq);
ok(SPVM::TestCase::R::OP::Double->seq_length);
ok(SPVM::TestCase::R::OP::Double->sin);
ok(SPVM::TestCase::R::OP::Double->cos);
ok(SPVM::TestCase::R::OP::Double->tan);
ok(SPVM::TestCase::R::OP::Double->sinh);
ok(SPVM::TestCase::R::OP::Double->cosh);
ok(SPVM::TestCase::R::OP::Double->tanh);
ok(SPVM::TestCase::R::OP::Double->acos);
ok(SPVM::TestCase::R::OP::Double->asin);
ok(SPVM::TestCase::R::OP::Double->atan);
ok(SPVM::TestCase::R::OP::Double->asinh);
ok(SPVM::TestCase::R::OP::Double->acosh);
ok(SPVM::TestCase::R::OP::Double->atanh);
ok(SPVM::TestCase::R::OP::Double->exp);
ok(SPVM::TestCase::R::OP::Double->expm1);
ok(SPVM::TestCase::R::OP::Double->log);
ok(SPVM::TestCase::R::OP::Double->logb);
ok(SPVM::TestCase::R::OP::Double->log2);
ok(SPVM::TestCase::R::OP::Double->log10);
ok(SPVM::TestCase::R::OP::Double->sqrt);
ok(SPVM::TestCase::R::OP::Double->isinf);
ok(SPVM::TestCase::R::OP::Double->is_infinite);
ok(SPVM::TestCase::R::OP::Double->is_finite);
ok(SPVM::TestCase::R::OP::Double->isnan);
ok(SPVM::TestCase::R::OP::Double->is_nan);
ok(SPVM::TestCase::R::OP::Double->pow);
ok(SPVM::TestCase::R::OP::Double->atan2);
ok(SPVM::TestCase::R::OP::Double->modf);
ok(SPVM::TestCase::R::OP::Double->ceil);
ok(SPVM::TestCase::R::OP::Double->ceiling);
ok(SPVM::TestCase::R::OP::Double->floor);
ok(SPVM::TestCase::R::OP::Double->round);
ok(SPVM::TestCase::R::OP::Double->lround);
ok(SPVM::TestCase::R::OP::Double->remainder);
ok(SPVM::TestCase::R::OP::Double->fmod);
ok(SPVM::TestCase::R::OP::Double->sum);
ok(SPVM::TestCase::R::OP::Double->cumsum);
ok(SPVM::TestCase::R::OP::Double->prod);
ok(SPVM::TestCase::R::OP::Double->cumprod);
ok(SPVM::TestCase::R::OP::Double->diff);
ok(SPVM::TestCase::R::OP::Double->max);
ok(SPVM::TestCase::R::OP::Double->min);
ok(SPVM::TestCase::R::OP::Double->mean);
ok(SPVM::TestCase::R::OP::Double->inner);
ok(SPVM::TestCase::R::OP::Double->cross);
ok(SPVM::TestCase::R::OP::Double->outer);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
