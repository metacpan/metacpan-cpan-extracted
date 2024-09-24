use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::R::OP::Long';

use SPVM 'R';
use SPVM::R;
use SPVM 'Fn';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count;

ok(SPVM::TestCase::R::OP::Long->c);
ok(SPVM::TestCase::R::OP::Long->add);
ok(SPVM::TestCase::R::OP::Long->sub);
ok(SPVM::TestCase::R::OP::Long->mul);
ok(SPVM::TestCase::R::OP::Long->div);
ok(SPVM::TestCase::R::OP::Long->div_u);
ok(SPVM::TestCase::R::OP::Long->mod);
ok(SPVM::TestCase::R::OP::Long->mod_u);
ok(SPVM::TestCase::R::OP::Long->neg);
ok(SPVM::TestCase::R::OP::Long->abs);
ok(SPVM::TestCase::R::OP::Long->eq);
ok(SPVM::TestCase::R::OP::Long->ne);
ok(SPVM::TestCase::R::OP::Long->gt);
ok(SPVM::TestCase::R::OP::Long->ge);
ok(SPVM::TestCase::R::OP::Long->lt);
ok(SPVM::TestCase::R::OP::Long->le);
ok(SPVM::TestCase::R::OP::Long->rep);
ok(SPVM::TestCase::R::OP::Long->rep_length);
ok(SPVM::TestCase::R::OP::Long->seq);
ok(SPVM::TestCase::R::OP::Long->sum);
ok(SPVM::TestCase::R::OP::Long->cumsum);
ok(SPVM::TestCase::R::OP::Long->prod);
ok(SPVM::TestCase::R::OP::Long->cumprod);
ok(SPVM::TestCase::R::OP::Long->diff);
ok(SPVM::TestCase::R::OP::Long->max);
ok(SPVM::TestCase::R::OP::Long->min);
ok(SPVM::TestCase::R::OP::Long->bit_and);
ok(SPVM::TestCase::R::OP::Long->bit_or);
ok(SPVM::TestCase::R::OP::Long->bit_not);
ok(SPVM::TestCase::R::OP::Long->left_shift);
ok(SPVM::TestCase::R::OP::Long->arithmetic_right_shift);
ok(SPVM::TestCase::R::OP::Long->logical_right_shift);

my $end_memory_blocks_count = $api->get_memory_blocks_count;
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
