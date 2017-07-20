use warnings;
use strict;

do "./t/setup_pp.pl" or die $@ || $!;
do "./t/classify.t" or die $@ || $!;

1;
