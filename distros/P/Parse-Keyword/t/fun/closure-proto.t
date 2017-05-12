
use strict;
use warnings;
use Test::More;
use lib 't/fun/lib';

BEGIN {
    if (!eval { require Sub::Name }) {
        plan skip_all => "This test requires Sub::Name";
    }
}

use Fun;

{
    my $x = 10;

    fun bar ($y) {
        $x * $y
    }
}

is(bar(3), 30);

done_testing;
