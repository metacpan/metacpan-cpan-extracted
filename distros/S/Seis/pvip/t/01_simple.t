use strict;
use warnings;
use utf8;
use Test::More;

is(`echo 3 | ./pvip`, "(statements (int 3))\n");
is(`./pvip -e 3`, "(statements (int 3))\n");
is(`./pvip -e ""`, "(nop)\n");

done_testing;

