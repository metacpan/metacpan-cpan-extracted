#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    package Foo;
    use Mouse;

    has 'bar' => ( is => 'rw' );

    package Stuffed::Role;
    use Mouse::Role;

    has 'options' => (
        traits => ['Array'],
        is     => 'ro',
        isa    => 'ArrayRef[Foo]',
    );

    package Bulkie::Role;
    use Mouse::Role;

    has 'stuff' => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => 'ArrayRef',
        handles => {
            get_stuff => 'get',
        }
    );

    package Stuff;
    use Mouse;

    ::is( ::exception { with 'Stuffed::Role';
        }, undef, '... this should work correctly' );

    ::is( ::exception { with 'Bulkie::Role';
        }, undef, '... this should work correctly' );
}

done_testing;
