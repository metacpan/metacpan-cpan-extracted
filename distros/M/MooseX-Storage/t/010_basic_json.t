use strict;
use warnings;

use Test::More;
use Test::Deep;

use Test::Requires qw(
    JSON::MaybeXS
    Test::Deep::JSON
);
diag 'using JSON backend: ', JSON;

plan tests => 10;

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage( 'format' => 'JSON' );

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

    my $json = $foo->freeze;

    cmp_deeply(
        $json,
        json({
            number => 10,
            string => 'foo',
            float => 10.5,
            array => [ 1 .. 10 ],
            hash => { map { $_ => undef } (1 .. 10) },
            __CLASS__ => 'Foo',
            object => {
                number => 2,
                __CLASS__ => 'Foo'
            },
        }),
        'is valid JSON and content matches',
    );
}

{
    my $foo =
      Foo->thaw(
'{"array":[1,2,3,4,5,6,7,8,9,10],"hash":{"6":null,"3":null,"7":null,"9":null,"2":null,"8":null,"1":null,"4":null,"10":null,"5":null},"float":10.5,"object":{"number":2,"__CLASS__":"Foo"},"number":10,"__CLASS__":"Foo","string":"foo"}'
      );
    isa_ok( $foo, 'Foo' );

    is( $foo->number, 10,    '... got the right number' );
    is( $foo->string, 'foo', '... got the right string' );
    is( $foo->float,  10.5,  '... got the right float' );
    cmp_deeply( $foo->array, [ 1 .. 10 ], '... got the right array' );
    cmp_deeply(
        $foo->hash,
        { map { $_ => undef } ( 1 .. 10 ) },
        '... got the right hash'
    );

    isa_ok( $foo->object, 'Foo' );
    is( $foo->object->number, 2,
        '... got the right number (in the embedded object)' );
}
