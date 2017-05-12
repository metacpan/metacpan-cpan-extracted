use lib "t/lib";
use lib "moose/lib";
use lib "lib";

## skip Test::Tabs
use strict;
use warnings;
use Test::More;
use Test::Moose;

{
    package Foo;
    use MyMoose;

    has foo => (
        is        => 'ro',
        isa       => 'Maybe[Int]',
        default   => undef,
        predicate => 'has_foo',
    );
}

with_immutable {
    is(Foo->new->foo, undef);
    ok(Foo->new->has_foo);
} 'Foo';

done_testing;
