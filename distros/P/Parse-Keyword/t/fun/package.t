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

fun Foo::foo ($x, $y) {
    $x + $y;
}

ok(!main->can('foo'));
ok(Foo->can('foo'));
is(Foo::foo(1, 2), 3);

done_testing;
