#!/usr/bin/env perl
use strictures 2;

use Test2::V0;

{
    package Foo;

    use Moo;
    use MooX::ChainedAttributes;

    has foo1 => (
        is => 'rw',
        chained => 1,
    );

    has foo2 => (
        is => 'rw',
    );

    has foo3 => (
        is => 'rwp',
        chained => 1,
    );

    has foo4 => (
        is => 'rw',
        chained => 1,
        writer => 'set_foo4',
    );

    has foo5 => (
        is => 'rwp',
        chained => 1,
        writer => 'set_foo5',
    );
}

is(
    dies { Foo->can('has')->('foo6', is=>'rw') },
    undef,
    'remote attribute declaration works',
);

isnt(
    dies { Foo->can('has')->('foo6', is=>'ro') },
    undef,
    'ro failed',
);

my $f = Foo->new();

is( $f->foo1(32), $f, 'rw chained' );
is( $f->foo1(), 32, 'chained accessor reader returned value' );

is( $f->foo2(56), 56, 'rw non-chained' );
is( $f->_set_foo3(19), $f, 'rwp chained' );
is( $f->set_foo4(98), $f, 'rw chained writer' );
is( $f->set_foo5(77), $f, 'rwp chained writer' );

{
    package Foo2;

    use Moo;
    use MooX::ChainedAttributes;

    has foo2 => (
        is => 'rw',
    );

    chain 'foo2';
}

my $f2 = Foo2->new;
is( $f2->foo2(56), $f2, 'make existing attribute chained' );

done_testing;
