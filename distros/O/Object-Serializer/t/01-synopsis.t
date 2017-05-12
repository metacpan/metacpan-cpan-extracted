use utf8;
use strict;
use warnings;
use Test::More;

package Foo;

use base 'Object::Serializer';

sub new {
    my $class = shift;
    bless {@_}, $class;
}

package main;

my $foo = Foo->new(
    number  => 10,
    string  => 'foo',
    boolean => 1,
    float   => 10.5,
    array   => [ 1 .. 10 ],
    hash    => { map { $_ => undef } ( 1 .. 10 ) },
    object  => Foo->new( number => 2 ),
    union   => [ 1, 2, 3 ],
    union2  => 'A String'
);

my $foo1 = {
    'object' => {
        '__CLASS__' => 'Foo',
        'number'    => 2
    },
    'number'    => 10,
    'union2'    => 'A String',
    'string'    => 'foo',
    '__CLASS__' => 'Foo',
    'array'     => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'boolean'   => 1,
    'hash'      => {
        '6'  => undef,
        '3'  => undef,
        '7'  => undef,
        '9'  => undef,
        '2'  => undef,
        '8'  => undef,
        '1'  => undef,
        '4'  => undef,
        '10' => undef,
        '5'  => undef
    },
    'float' => '10.5',
    'union' => [1, 2, 3]
};

is_deeply $foo->serialize => $foo1, '$foo->serialize == $foo1 ok';

my $foo2 = {
    'object' => {
        'number'    => 2
    },
    'number'    => 10,
    'union2'    => 'A String',
    'string'    => 'foo',
    'array'     => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'boolean'   => 1,
    'hash'      => {
        '6'  => undef,
        '3'  => undef,
        '7'  => undef,
        '9'  => undef,
        '2'  => undef,
        '8'  => undef,
        '1'  => undef,
        '4'  => undef,
        '10' => undef,
        '5'  => undef
    },
    'float' => '10.5',
    'union' => [1, 2, 3]
};

is_deeply $foo->serialize($foo, marker => undef) => $foo2,
    '$foo->serialize == $foo2 ok';


done_testing;
