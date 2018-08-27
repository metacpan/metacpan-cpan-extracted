use strict; use warnings;

use Proc::Fork;

print "1..2\n";

# waitpid ensures order of output
child  {                   print "ok 1 - child code runs\n"  }
parent { waitpid shift, 0; print "ok 2 - parent code runs\n" }
