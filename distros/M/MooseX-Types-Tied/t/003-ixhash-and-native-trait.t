#!/usr/bin/env perl
#
# This file is part of MooseX-Types-Tied
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package TestClass;

    use Moose;
    use MooseX::Types::Tied::Hash::IxHash ':all';

    has ixhash => (
        traits => ['Hash'],
        is => 'rw', isa => IxHash, coerce => 1,
        handles => {
            h_keys   => 'keys',
            h_values => 'values',
            h_del    => 'delete',
            h_set    => 'set',
        },
    );
}

my $foo = TestClass->new();

# note arrayref
$foo->ixhash( [ one => 'first', two => 'second', three => 'third' ] );

is_deeply(
    [ $foo->h_keys        ],
    [ qw{ one two three } ],
    'keys are sorted correctly',
);

is_deeply(
    [ $foo->h_values           ],
    [ qw{ first second third } ],
    'values returned as expected',
);

TODO: {
    local $TODO = 'Moose Hash native trait known to harmful to tied structs';

    lives_ok { $foo->h_del('two')            } 'h_del(2) lives';
    lives_ok { $foo->h_set(four => 'fourth') } 'h_set(...) lives';

    is_deeply(
        [ $foo->h_keys         ],
        [ qw{ one three four } ],
        'keys are sorted correctly',
    );

    is_deeply(
        [ $foo->h_values           ],
        [ qw{ first third fourth } ],
        'values returned as expected',
    );
}

done_testing;
