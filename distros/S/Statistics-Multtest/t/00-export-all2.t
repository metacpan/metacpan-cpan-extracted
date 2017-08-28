use Test::More tests => 8;
use strict;

use_ok("Statistics::Multtest", qw(:all));

can_ok("main", "bonferroni");
can_ok("main", "holm");
can_ok("main", "hommel");
can_ok("main", "hochberg");
can_ok("main", "BH");
can_ok("main", "BY");
can_ok("main", "qvalue");
