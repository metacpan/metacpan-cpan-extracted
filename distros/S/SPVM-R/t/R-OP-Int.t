use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Int';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Int->c);
ok(SPVM::TestCase::R::OP::Int->add);
ok(SPVM::TestCase::R::OP::Int->sub);
ok(SPVM::TestCase::R::OP::Int->mul);
ok(SPVM::TestCase::R::OP::Int->div);
ok(SPVM::TestCase::R::OP::Int->div_u);
ok(SPVM::TestCase::R::OP::Int->mod);
ok(SPVM::TestCase::R::OP::Int->mod_u);
ok(SPVM::TestCase::R::OP::Int->neg);
ok(SPVM::TestCase::R::OP::Int->abs);
ok(SPVM::TestCase::R::OP::Int->eq);
ok(SPVM::TestCase::R::OP::Int->ne);
ok(SPVM::TestCase::R::OP::Int->gt);
ok(SPVM::TestCase::R::OP::Int->ge);
ok(SPVM::TestCase::R::OP::Int->lt);
ok(SPVM::TestCase::R::OP::Int->le);
ok(SPVM::TestCase::R::OP::Int->rep);
ok(SPVM::TestCase::R::OP::Int->rep_length);
ok(SPVM::TestCase::R::OP::Int->seq);
ok(SPVM::TestCase::R::OP::Int->sum);
ok(SPVM::TestCase::R::OP::Int->cumsum);
ok(SPVM::TestCase::R::OP::Int->prod);
ok(SPVM::TestCase::R::OP::Int->cumprod);
ok(SPVM::TestCase::R::OP::Int->diff);
ok(SPVM::TestCase::R::OP::Int->max);
ok(SPVM::TestCase::R::OP::Int->min);
ok(SPVM::TestCase::R::OP::Int->and);
ok(SPVM::TestCase::R::OP::Int->or);
ok(SPVM::TestCase::R::OP::Int->not);
ok(SPVM::TestCase::R::OP::Int->bit_and);
ok(SPVM::TestCase::R::OP::Int->bit_or);
ok(SPVM::TestCase::R::OP::Int->bit_not);
ok(SPVM::TestCase::R::OP::Int->left_shift);
ok(SPVM::TestCase::R::OP::Int->arithmetic_right_shift);
ok(SPVM::TestCase::R::OP::Int->logical_right_shift);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
