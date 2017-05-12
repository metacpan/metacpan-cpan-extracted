use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use ok 'MooseX::Types::Set::Object';

{
    package Blah;
    use Moose;

    has stuff => (
        isa => "Set::Object",
        is  => "rw",
        coerce => 1,
    );

    has junk => (
        isa => "Set::Object",
        is  => "rw",
    );

    has moo => (
        isa    => 'ArrayRef',
        is     => 'rw',
        coerce => 1,
    );

    package Foo;
    use Moose;

    package Bar;
    use Moose;

    extends qw(Foo);

    package Gorch;
    use Moose;
}

my @objs = (
    "foo",
    Foo->new,
    [ ],
);

my $obj = Blah->new( stuff => \@objs );

isa_ok( $obj->stuff, "Set::Object" );
is( $obj->stuff->size, 3, "three items" );

foreach my $item ( @objs ) {
    ok( $obj->stuff->includes($item), "'$item' is in the set");
}

like( exception { Blah->new( junk => [ ] ) }, qr/type.*Set::Object/i, "fails without coercion");

like( exception { Blah->new( junk => \@objs ) }, qr/type.*Set::Object/i, "fails without coercion");

done_testing;
