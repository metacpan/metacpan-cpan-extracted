use strict;
use Test::More tests => 4;

use_ok 'Radioactive::Decay';

tie my $var, 'Radioactive::Decay', 1;

$var = 20;
sleep 1;
is $var, 10,  "Decayed to 10";
sleep 1;
is $var, 5,  "Decayed to 5";
sleep 1;
is $var, 2.5, "Decayed to 2.5";


