#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::ABC;

    requires 'bar', 'baz';

    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub1;
    use Moose;
    ::is(::exception { extends 'Foo' }, undef,
        "extending works when the requires are fulfilled");
    sub bar { }
    sub baz { }

    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub2;
    use Moose;
    ::like(
        ::exception { extends 'Foo' },
        qr/Foo requires Foo::Sub2 to implement baz/,
        "extending fails with the correct error when requires are not fulfilled"
    );
    sub bar { }
}

{
    package Foo::Sub::Sub;
    use Moose;
    ::is(::exception { extends 'Foo::Sub1' }, undef,
        "extending twice works");

    __PACKAGE__->meta->make_immutable;
}

{
    my $foosub;
    is(exception { $foosub = Foo::Sub1->new }, undef,
       "instantiating concrete subclasses works");
    isa_ok($foosub, 'Foo', 'inheritance is correct');
}

{
    my $foosubsub;
    is(exception { $foosubsub = Foo::Sub::Sub->new }, undef,
       "instantiating deeper concrete subclasses works");
    isa_ok($foosubsub, 'Foo', 'inheritance is correct');
    isa_ok($foosubsub, 'Foo::Sub1', 'inheritance is correct');
}

like(exception { Foo->new }, qr/Foo is abstract, it cannot be instantiated/,
     "instantiating abstract classes fails");

done_testing;
