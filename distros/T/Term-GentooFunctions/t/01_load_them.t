# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;

plan tests => 1;

for my $p (qw(Term::GentooFunctions)) {
    eval "use $p";

    if( $@ ) {
        warn " $@\n";
        ok 0;

    } else {
        ok 1;
    }
}
