use strict;
use warnings;

package Foo {
    use Test::Deep::NoTest;

    sub check_this {
        return eq_deeply($_[1], []);
    }
}

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Deep;

ok(Foo->check_this([]), 'notest 1');
ok(! Foo->check_this({}), 'notest 2');
cmp_deeply([], [], 'got cmp_deeply');

done_testing;
