use strict;
use warnings;
use Test::Most tests => 6;

BEGIN {
    local $ENV{PERL_STRICT} = 1;
    require Devel::StrictMode;
}

package Interface {
    use Role::Declare::Should;
    use Types::Standard qw[ Int ];

    method foo(Int $x, Int $y) : Return(Int) {
        die 'X is too big' if $x > 10;
    }
    method bar() : Return(Int) { }
};

package Impl {
    use Role::Tiny::With;
    with 'Interface';

    sub foo { return 12 }
    sub bar { return 'Str' }
}

ok Devel::StrictMode::STRICT, 'Devel::StrictMode is on';

lives_ok { Impl->foo(1, 2) } 'correct implementation and call';
throws_ok { Impl->foo(1, 2, 3) } qr/Too many arguments/, 'argument count exceeded';
throws_ok { Impl->foo(1, 'Two') } qr/did not pass type constraint/, 'argument type check failed';
throws_ok { my $x = Impl->bar() } qr/did not pass type constraint/, 'return type check failed';
throws_ok { Impl->foo(11, 2) } qr/X is too big/, 'custom check failed';
