#!/usr/bin/perl -T
# test a custom normalizer supplied by Flyweight::Test3

use strict;
use warnings;

use Test::More tests => 8;
use Test::Fatal;

use lib 't/lib';

BEGIN {
    use_ok 'MooseX::Role::Flyweight';
    use_ok 'Flyweight::Test3';
}

is(
    Flyweight::Test3->normalizer( { id => 123 } ),
    Flyweight::Test3->normalizer( { id => 123, attr => 1 } ),
    'handles attribute default'
);

is(
    Flyweight::Test3->normalizer( { id => 123 } ),
    Flyweight::Test3->normalizer( { id => 123, init_attr => 1 } ),
    'handles init_arg default'
);

isnt(
    Flyweight::Test3->normalizer( { id => 123 } ),
    Flyweight::Test3->normalizer( { id => 123, _private_attr => 1 } ),
    'ignores _private attributes'
);

isnt(
    Flyweight::Test3->normalizer( { id => 123 } ),
    Flyweight::Test3->normalizer( { id => 123, _lazy_attr => 1 } ),
    'ignores lazy attributes'
);

like(
    exception { Flyweight::Test3->normalizer( { id => 123, abc => 123 } ) },
    qr/Found unknown attribute/,
    'unknown attribute error'
);

like(
    exception {
        Flyweight::Test3->normalizer( { id => 123, uninit_attr => 1 } );
    },
    qr/Found unknown attribute/,
    'undef init_arg error'
);
