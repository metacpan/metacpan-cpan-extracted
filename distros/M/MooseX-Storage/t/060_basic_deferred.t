$|++;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Storable;

use Test::Requires qw(
    Test::Deep::JSON
    JSON::MaybeXS
    YAML::Any
);
diag 'using JSON backend: ', JSON;
diag 'using YAML backend: ', YAML::Any->implementation;

plan tests => 33;

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with 'MooseX::Storage::Deferred';

    has 'unset'  => ( is => 'ro', isa => 'Any' );
    has 'undef'  => ( is => 'ro', isa => 'Any' );
    has 'number' => ( is => 'ro', isa => 'Int' );
    has 'string' => ( is => 'ro', isa => 'Str' );
    has 'float'  => ( is => 'ro', isa => 'Num' );
    has 'array'  => ( is => 'ro', isa => 'ArrayRef' );
    has 'hash'   => ( is => 'ro', isa => 'HashRef' );
    has 'object' => ( is => 'ro', isa => 'Object' );
}

{
    my $foo = Foo->new(
        undef => undef,
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $json = $foo->freeze({ 'format' => 'JSON' });

    cmp_deeply(
        $json,
        json({
            undef => undef,
            number => 10,
            string => 'foo',
            float  => 10.5,
            array  => [ 1 .. 10 ],
            hash   => { map { $_ => undef } ( 1 .. 10 ) },
            __CLASS__ => 'Foo',
            object => {
                number => 2,
                __CLASS__ => 'Foo'
            },
        }),
        '... got the right JSON'
    );
}

{
    my $foo = Foo->thaw(
        '{"array":[1,2,3,4,5,6,7,8,9,10],"hash":{"6":null,"3":null,"7":null,"9":null,"2":null,"8":null,"1":null,"4":null,"10":null,"5":null},"float":10.5,"object":{"number":2,"__CLASS__":"Foo"},"number":10,"__CLASS__":"Foo","string":"foo"}',
        { 'format' => 'JSON' }
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

{
    my $foo = Foo->new(
        undef => undef,
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $stored = $foo->freeze({ 'format' => 'Storable' });

    my $struct = Storable::thaw($stored);
    cmp_deeply(
        $struct,
        {
            '__CLASS__' => 'Foo',
            'undef'     => undef,
            'number'    => 10,
            'float'     => 10.5,
            'string'    => 'foo',
            'array'     => [ 1 .. 10],
            'hash'      => { map { $_ => undef } 1 .. 10 },
            'object'    => {
                '__CLASS__' => 'Foo',
                'number' => 2
            },
        },
        '... got the data struct we expected'
    );
}

{
    my $stored = Storable::nfreeze({
        '__CLASS__' => 'Foo',
        'undef'     => undef,
        'number'    => 10,
        'string'    => 'foo',
        'float'     => 10.5,
        'array'     => [ 1 .. 10],
        'hash'      => { map { $_ => undef } 1 .. 10 },
        'object'    => {
            '__CLASS__' => 'Foo',
            'number' => 2
        },
    });

    my $foo = Foo->thaw($stored, { 'format' => 'Storable' });
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

{
    my $foo = Foo->new(
        undef  => undef,
        number => 10,
        string => 'foo',
        float  => 10.5,
        array  => [ 1 .. 10 ],
        hash   => { map { $_ => undef } ( 1 .. 10 ) },
        object => Foo->new( number => 2 ),
    );
    isa_ok( $foo, 'Foo' );

    my $yaml = $foo->freeze({ 'format' => 'YAML' });

    my $bar = Foo->thaw( $yaml, { 'format' => 'YAML' } );
    isa_ok( $bar, 'Foo' );

    is( $foo->unset, undef,  '... got the right unset value');
    ok(!$foo->meta->get_attribute('unset')->has_value($foo), 'unset attribute has no value');
    is( $foo->undef, undef,  '... got the right undef value');
    ok( $foo->meta->get_attribute('undef')->has_value($foo), 'undef attribute has a value');
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
