#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

{
    package MyRole;
    use Any::Moose 'Role';
    requires 'foo';
}

eval q{

    package MyClass;
    use Mouse;
    use Any::Moose 'X::Types' => [-declare => ['Foo']];
    use Any::Moose 'X::Types::Moose' => ['Int'];
    with 'MyRole';

    subtype Foo, as Int;

    sub foo {}
};

ok !$@, 'type export not picked up as a method on role application';
