use strict;
use warnings;
use Test::Most;

package Interface {
    use Role::Declare -lax;
    use Types::Standard qw[ Int ];

    method foo(Int $x, Int $y) { }
};

package Impl {
    use Role::Tiny::With;
    with 'Interface';

    sub foo { }
}

lives_ok { Impl->foo(1, 2, 3) } 'extra argument';
throws_ok { Impl->foo(1, "Two") } qr/did not pass type constraint/, 'type constraints still work';
throws_ok { Impl->foo(1) } qr/did not pass type constraint/, 'missing argument triggers a type error';

done_testing();
