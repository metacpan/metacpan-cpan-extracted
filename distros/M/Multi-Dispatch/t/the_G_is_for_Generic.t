use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 6;

use Multi::Dispatch;


multi foo  ($r1, $r2, $r3, @s1)  { return "R$r1, R$r2, R$r3, S@s1" }
multi foo  ($r1, $r2, @       )  { return "R$r1, R$r2, S?" }
multi foo  ($r1               )  { return "R$r1" }

is foo(1,2,3,4), 'R1, R2, R3, S4'  => 'RRS';
is foo(1,2,3),   'R1, R2, R3, S'   => 'RRS';
is foo(1,2),     'R1, R2, S?'      => 'RNS';
is foo(1),       'R1'              => 'R';


multi bar  ($r1, $r2, $r3, $r4)  { return "R$r1; R$r2; R$r3; R$r4" }
multi bar  ($r, $o='o', %)       { return "R$r; O$o; S?" }

is bar(1, 2, 3, 4),          "R1; R2; R3; R4"    => 'RRRR';
is bar(1, 2, s1=>3, s2=>4),  "R1; O2; S?"        => 'ROS';

done_testing();







