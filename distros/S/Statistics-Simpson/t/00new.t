use strict;
use warnings;

use Statistics::Simpson;

print "1..2\n";

my $pop = Statistics::Simpson->new(qw(a b b c c c c));

# 1/((1/7)**2+(2/7)**2+(4/7)**2)
print abs($pop->index    - 2.33333333333333) < 1E-6 ?
  "ok 1\n" : "not ok 1\n";

# (1/((1/7)**2+(2/7)**2+(4/7)**2))/3
print abs($pop->evenness - 0.777777777777778) < 1E-6 ?
  "ok 2\n" : "not ok 2\n";





