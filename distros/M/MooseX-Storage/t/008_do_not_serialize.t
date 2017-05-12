use strict;
use warnings;

use Test::More tests => 12;
use Test::Deep;

{
    package Foo;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'bar' => (
        metaclass => 'DoNotSerialize',
        is        => 'rw',
        default   => sub { 'BAR' }
    );

    has 'baz' => (
        traits  => [ 'DoNotSerialize' ],
        is      => 'rw',
        default => sub { 'BAZ' }
    );

    has 'gorch' => (
        is      => 'rw',
        default => sub { 'GORCH' }
    );

    1;
}

{   my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    is($foo->bar, 'BAR', '... got the value we expected');
    is($foo->baz, 'BAZ', '... got the value we expected');
    is($foo->gorch, 'GORCH', '... got the value we expected');

    cmp_deeply(
        $foo->pack,
        {
            __CLASS__ => 'Foo',
            gorch     => 'GORCH'
        },
        '... got the right packed class data'
    );
}

### more involved test; required attribute that's not serialized
{   package Bar;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has foo => (
        metaclass   => 'DoNotSerialize',
        required    => 1,
        is          => 'rw',
        isa         => 'Object',        # type constraint is important
    );

    has zot => (
        default     => sub { $$ },
        is          => 'rw',
    );
}

{   my $obj = bless {};
    my $bar = Bar->new( foo => $obj );

    ok( $bar,                   "New object created" );
    is( $bar->foo, $obj,        "   ->foo => $obj" );
    is( $bar->zot, $$,          "   ->zot => $$" );

    my $bpack = $bar->pack;
    cmp_deeply(
        $bpack,
        {   __CLASS__   => 'Bar',
            zot         => $$,
        },                      "   Packed correctly" );

    eval { Bar->unpack( $bpack ) };
    ok( $@,                     "   Unpack without required attribute fails" );
    like( $@, qr/foo/,          "       Proper error recorded" );

    my $bar2 = Bar->unpack( $bpack, inject => { foo => bless {} } );
    ok( $bar2,                  "   Unpacked correctly with foo => Object");
}
