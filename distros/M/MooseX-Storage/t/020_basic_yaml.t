$|++;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use Test::Requires qw(
    YAML::Any
    YAML
    Test::Without::Module
);
diag 'using YAML backend: ', YAML::Any->implementation;

BEGIN {
    Test::Without::Module->import(YAML::Any->order);
    Test::Without::Module->unimport('YAML');
    plan tests => 9;
}

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage( 'format' => 'YAML' );

    has 'number' => ( is => 'ro', isa => 'Int' );
    has 'string' => ( is => 'ro', isa => 'Str' );
    has 'float'  => ( is => 'ro', isa => 'Num' );
    has 'array'  => ( is => 'ro', isa => 'ArrayRef' );
    has 'hash'   => ( is => 'ro', isa => 'HashRef' );
    has 'object' => ( is => 'ro', isa => 'Object' );
}

{
    my $foo = Foo->new(
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $yaml = $foo->freeze;

    my $bar = Foo->thaw( $yaml );
    isa_ok( $bar, 'Foo' );

    is( $bar->number, 10,    '... got the right number' );
    is( $bar->string, 'foo', '... got the right string' );
    is( $bar->float,  10.5,  '... got the right float' );
    cmp_deeply( $bar->array, [ 1 .. 10 ], '... got the right array' );
    cmp_deeply(
        $bar->hash,
        { map { $_ => undef } ( 1 .. 10 ) },
        '... got the right hash'
    );

    isa_ok( $bar->object, 'Foo' );
    is( $bar->object->number, 2,
        '... got the right number (in the embedded object)' );
}
