use strict;
use warnings;

use Statistics::Simpson;

print "1..2\n";

my $pop = [ 1, 2, 4 ];

# 1/((1/7)**2+(2/7)**2+(4/7)**2)
print abs(Statistics::Simpson::index($pop) - 2.33333333333333) < 1E-6 ?
  "ok 1\n" : "not ok 1\n";

# (1/((1/7)**2+(2/7)**2+(4/7)**2))/3
print abs(Statistics::Simpson::evenness($pop) - 0.777777777777778) < 1E-6 ?
  "ok 2\n" : "not ok 2\n";





