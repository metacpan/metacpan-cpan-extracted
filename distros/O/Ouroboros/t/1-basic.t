use strict;
use warnings;

use Test::More;

require_ok("Ouroboros");

can_ok("Ouroboros", "ouroboros_stack_init_ptr");

cmp_ok(Ouroboros::SVt_PVIV(), "<", Ouroboros::SVt_PVAV());
cmp_ok(Ouroboros::SVt_PVMG(), "<", Ouroboros::SVt_PVAV());

done_testing;
