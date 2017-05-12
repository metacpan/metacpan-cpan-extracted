#! perl --
use strict;
use warnings;

use lib '../lib';
use Perl6::GatherTake;


my $powers_of_two = gather {
    my $i = 1;
    for (;;) {
        take $i;
        $i *= 2;
    }
};

print $powers_of_two->[3], "\n";

