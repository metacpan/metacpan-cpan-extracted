use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Float';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Float->c);
ok(SPVM::TestCase::R::OP::Float->add);
ok(SPVM::TestCase::R::OP::Float->sub);
ok(SPVM::TestCase::R::OP::Float->mul);
ok(SPVM::TestCase::R::OP::Float->scamul);
ok(SPVM::TestCase::R::OP::Float->div);
ok(SPVM::TestCase::R::OP::Float->scadiv);
ok(SPVM::TestCase::R::OP::Float->neg);
ok(SPVM::TestCase::R::OP::Float->abs);
ok(SPVM::TestCase::R::OP::Float->eq);
ok(SPVM::TestCase::R::OP::Float->ne);
ok(SPVM::TestCase::R::OP::Float->gt);
ok(SPVM::TestCase::R::OP::Float->ge);
ok(SPVM::TestCase::R::OP::Float->lt);
ok(SPVM::TestCase::R::OP::Float->le);
ok(SPVM::TestCase::R::OP::Float->rep);
ok(SPVM::TestCase::R::OP::Float->rep_length);
ok(SPVM::TestCase::R::OP::Float->seq);
ok(SPVM::TestCase::R::OP::Float->seq_length);
ok(SPVM::TestCase::R::OP::Float->sin);
ok(SPVM::TestCase::R::OP::Float->cos);
ok(SPVM::TestCase::R::OP::Float->tan);
ok(SPVM::TestCase::R::OP::Float->sinh);
ok(SPVM::TestCase::R::OP::Float->cosh);
ok(SPVM::TestCase::R::OP::Float->tanh);
ok(SPVM::TestCase::R::OP::Float->acos);
ok(SPVM::TestCase::R::OP::Float->asin);
ok(SPVM::TestCase::R::OP::Float->atan);
ok(SPVM::TestCase::R::OP::Float->asinh);
ok(SPVM::TestCase::R::OP::Float->acosh);
ok(SPVM::TestCase::R::OP::Float->atanh);
ok(SPVM::TestCase::R::OP::Float->exp);
ok(SPVM::TestCase::R::OP::Float->expm1);
ok(SPVM::TestCase::R::OP::Float->log);
ok(SPVM::TestCase::R::OP::Float->logb);
ok(SPVM::TestCase::R::OP::Float->log2);
ok(SPVM::TestCase::R::OP::Float->log10);
ok(SPVM::TestCase::R::OP::Float->sqrt);
ok(SPVM::TestCase::R::OP::Float->isinf);
ok(SPVM::TestCase::R::OP::Float->is_infinite);
ok(SPVM::TestCase::R::OP::Float->is_finite);
ok(SPVM::TestCase::R::OP::Float->isnan);
ok(SPVM::TestCase::R::OP::Float->is_nan);
ok(SPVM::TestCase::R::OP::Float->pow);
ok(SPVM::TestCase::R::OP::Float->atan2);
ok(SPVM::TestCase::R::OP::Float->modf);
ok(SPVM::TestCase::R::OP::Float->ceil);
ok(SPVM::TestCase::R::OP::Float->ceiling);
ok(SPVM::TestCase::R::OP::Float->floor);
ok(SPVM::TestCase::R::OP::Float->round);
ok(SPVM::TestCase::R::OP::Float->lround);
ok(SPVM::TestCase::R::OP::Float->remainder);
ok(SPVM::TestCase::R::OP::Float->fmod);
ok(SPVM::TestCase::R::OP::Float->sum);
ok(SPVM::TestCase::R::OP::Float->cumsum);
ok(SPVM::TestCase::R::OP::Float->prod);
ok(SPVM::TestCase::R::OP::Float->cumprod);
ok(SPVM::TestCase::R::OP::Float->diff);
ok(SPVM::TestCase::R::OP::Float->max);
ok(SPVM::TestCase::R::OP::Float->min);
ok(SPVM::TestCase::R::OP::Float->mean);
ok(SPVM::TestCase::R::OP::Float->dot);
ok(SPVM::TestCase::R::OP::Float->cross);
ok(SPVM::TestCase::R::OP::Float->outer);
ok(SPVM::TestCase::R::OP::Float->pi);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
