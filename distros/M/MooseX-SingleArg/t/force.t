#!/usr/bin/env perl
use strict;
use warnings;

use Test2::V0;

{
    package MyClass;
    use Moose;
    use MooseX::SingleArg;

    single_arg arg1 => (
        force => 1,
    );

    has arg1 => (
        is  => 'ro',
        isa => 'HashRef',
    );
}

{
    my $obj = MyClass->new( {one=>1} );
    is( $obj->arg1(), {one=>1}, 'able to set a single arg to a hashref' );
}

like(
    dies { MyClass->new( arg1 => {one=>1} ) },
    qr{accepts only one argument },
    'when force is on then passing more than one argument errors',
);

done_testing;
