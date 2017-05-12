#!perl -w
use Test::More;

use Test::Mouse;

{
    package Foo;
    use Mouse;
    use MouseX::StrictConstructor;

    has [qw(foo bar)] => (is => 'rw');
}

{
    package Foo::Bar;
    use Mouse;
    extends 'Foo';

    has [qw(baz)] => (is => 'rw');
}

with_immutable sub {
    isa_ok(Foo->new(foo => 1, bar => 2), 'Foo');

    eval {
        Foo->new(foo => 1, bar => 2, baz => 3);
    };
    like $@, qr/\b Foo \b/xms;
    like $@, qr/\b baz \b/xms;

    isa_ok eval {
        Foo::Bar->new(foo => 1, bar => 2, baz => 3);
    }, 'Foo::Bar';

    eval {
        Foo::Bar->new(foo => 1, bar => 2, baz => 3, qux => 4);
    };
    like $@, qr/\b Foo::Bar \b/xms;
    like $@, qr/\b qux \b/xms;
}, qw(Foo Foo::Bar);

done_testing;
