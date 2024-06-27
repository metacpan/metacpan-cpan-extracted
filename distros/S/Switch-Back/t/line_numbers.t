use v5.36;

use strict;
use warnings;
use Test::More;

use Switch::Back;

plan tests => 1;

my $x;
given ($x) {
    when (1) {
        # nothing
        # nothing
        # nothing
        # nothing
    }

    when (
        2
    ) { }

    1
    when
    3;
}


is __LINE__(), 30 => 'Correct line number after keyword interpolation';

done_testing();


