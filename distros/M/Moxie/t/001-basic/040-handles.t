#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has 'bar' => sub { 'FOO::BAR' };

    sub bar : ro;
}

package Bar {
    use Moxie;

    extends 'Moxie::Object';

    has 'foo' => sub { Foo->new };

    sub foo    : ro;
    sub foobar : handles('foo->bar');
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
