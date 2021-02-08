use strict;
use warnings;
use Test::Most tests => 6;

BEGIN {
    local $ENV{EXTENDED_TESTING} = 0;
    local $ENV{AUTHOR_TESTING}   = 0;
    local $ENV{RELEASE_TESTING}  = 0;
    local $ENV{PERL_STRICT}      = 0;
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

ok !Devel::StrictMode::STRICT, 'Devel::StrictMode is off';

lives_ok { Impl->foo(1, 2) } 'correct implementation and call';
lives_ok { Impl->foo(1, 2, 3) } 'argument count exceeded';
lives_ok { Impl->foo(1, 'Two') } 'argument type check failed';
lives_ok { my $x = Impl->bar() } 'return type check failed';
throws_ok { Impl->foo(11, 2) } qr/X is too big/, 'custom check still throws an error';
