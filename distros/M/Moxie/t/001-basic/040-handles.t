#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Foo {
    use Moxie traits => [':experimental'];

    extends 'Moxie::Object';

    has _bar => sub { 'FOO::BAR' };

    sub bar : ro(_bar);
}

package Bar {
    use Moxie traits => [':experimental'];

    extends 'Moxie::Object';

    has _foo => sub { Foo->new };

    sub BUILDARGS : strict( foo? => _foo );

    sub foo    : ro(_foo);
    sub foobar : handles('_foo->bar');
}

{
    my $bar = Bar->new;
    isa_ok($bar, 'Bar');

    can_ok($bar, 'foo');
    can_ok($bar, 'foobar');

    my $foo = $bar->foo;
    isa_ok($foo, 'Foo');

    is($foo->bar, $bar->foobar, '... the delegated method worked correctly');
}

{
    my $bar = Bar->new( foo => 10 );
    isa_ok($bar, 'Bar');

    can_ok($bar, 'foo');
    can_ok($bar, 'foobar');

    my $foo = $bar->foo;
    is($foo, 10, '... got the value we expected');

    like(
        exception { $bar->foobar },
        qr/^Can\'t locate object method \"bar\" via package \"10\"/,
        '... the delegated method failed correctly'
    );
}


done_testing;
