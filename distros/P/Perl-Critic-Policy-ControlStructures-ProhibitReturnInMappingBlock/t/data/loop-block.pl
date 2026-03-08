use strict;
use warnings;

sub func {
    for my $x (1..10) {
        return if $x < 5;
    }

    return 1;
}
func();
