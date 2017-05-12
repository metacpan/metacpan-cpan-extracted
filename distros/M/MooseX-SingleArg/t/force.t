#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

require_ok('MooseX::SingleArg');

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
    is_deeply( $obj->arg1(), {one=>1}, 'able to set a single arg to a hashref' );
}

like(
    exception { MyClass->new( arg1 => {one=>1} ) },
    qr{accepts only one argument },
    'when force is on then passing more than one argument errors',
);

done_testing;
