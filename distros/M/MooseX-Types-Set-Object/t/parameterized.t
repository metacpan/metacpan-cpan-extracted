use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

BEGIN {
    plan skip_all => 'parameterization does not work -- see code removed in commit 262e683 for what should happen';
}

use ok 'MooseX::Types::Set::Object';

{
    package Blah;
    use Moose;

    has misc => (
        isa => "Set::Object[Foo]",
        is  => "rw",
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

{
    local $TODO = "coercion for parameterized types seems borked";
    is( exception { Blah->new( misc => [ ] ) }, undef, "doesn't fail with empty array for parameterized set type");
}

is( exception { Blah->new( misc => Set::Object->new ) }, undef, "doesn't fail with empty set for parameterized set type");

like( exception { Blah->new( misc => \@objs ) }, qr/Foo/, "fails on parameterized set type");

like( exception { Blah->new( misc => Set::Object->new(@objs) ) }, qr/Foo/, "fails on parameterized set type");

{
    local $TODO = "coercion for parameterized types seems borked";
    is( exception { Blah->new( misc => [ Foo->new, Bar->new ] ) }, undef, "no error on coercion from array filled with the right type");
}

is( exception { Blah->new( misc => Set::Object->new(Foo->new, Bar->new) ) }, undef, "no error with set filled with the right type");
like( exception { Blah->new( misc => Set::Object->new(Foo->new, Gorch->new, Bar->new) ) }, qr/Foo/, "error with set that has a naughty object");

done_testing;
