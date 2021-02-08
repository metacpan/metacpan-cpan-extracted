use strict;
use warnings;
use Test::Most;

package Interface {
    use Role::Declare -no_type_check;
    use Types::Standard qw[ Int ];

    method foo(Int $x, Int $y) :Return(Int) { }
};

package Impl1 {
    use Role::Tiny::With;
    with 'Interface';

    sub foo { return 42 }
}

package Impl2 {
    use Role::Tiny::With;
    with 'Interface';

    sub foo { return 'String' }
}

lives_ok { Impl1->foo(1, "Two") } 'argument type constraint broken';
lives_ok { my $x = Impl2->foo(1, 1) } 'return type constraint broken';
throws_ok { Impl1->foo(1, 2, 3) } qr/Too many arguments/, 'extra arguments still trigger errors';
throws_ok { Impl2->foo(1, 2, 3) } qr/Too many arguments/, 'extra arguments still trigger errors';

done_testing();
