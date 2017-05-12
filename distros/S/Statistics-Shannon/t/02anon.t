use strict;
use warnings;

use Statistics::Shannon;

print "1..2\n";

my $pop = [ 1, 2, 4 ];

# -(1/7*log(1/7)+2/7*log(2/7)+4/7*log(4/7))
print abs(Statistics::Shannon::index($pop) - 0.955699891112534) < 1E-6 ?
  "ok 1\n" : "not ok 1\n";

# -(1/7*log(1/7)+2/7*log(2/7)+4/7*log(4/7))/log(3)
print abs(Statistics::Shannon::evenness($pop) - 0.869915529773626) < 1E-6 ?
  "ok 2\n" : "not ok 2\n";





