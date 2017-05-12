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

is(foo(), "FOO");

fun foo { "FOO" }

done_testing;
