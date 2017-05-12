use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok "Photography::EV" }

is ev(1,1),       0,   "EV  0 = f/1.0 1s";
is ev(1.4,1),     1,   "EV  1 = f/1.4 1s";
is ev(5.6,8*60),  -4,  "EV -4 = f/5.6 8m";
is ev(45,1/1000), 21,  "EV 21 = f/45  1/1000s";
