use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'number'  => ( is => 'ro', isa => 'Int', default => 42 );
    has 'string'  => ( is => 'ro', isa => 'Str', default => "true" );
    has 'boolean' => ( is => 'ro', isa => 'Bool', default => 1 );
}

{
    my $foo = Foo->new(
        number  => 0,
        string  => '',
        boolean => 0,
    );
    isa_ok( $foo, 'Foo' );

    is($foo->boolean, 0, '... got the right boolean value');

    cmp_deeply(
        $foo->pack,
        {
            __CLASS__ => 'Foo',
            number    => 0,
            string    => '',
            boolean   => 0,
        },
        '... got the right frozen class'
    );
}

{
    my $foo = Foo->unpack(
        {
            __CLASS__ => 'Foo',
            number    => 0,
            string    => '',
            boolean   => 0,
        }
    );
    isa_ok( $foo, 'Foo' );

    is( $foo->number, 0,  '... got the right number' );
    is( $foo->string, '', '... got the right string' );
    ok( !$foo->boolean,   '... got the right boolean' );
}
