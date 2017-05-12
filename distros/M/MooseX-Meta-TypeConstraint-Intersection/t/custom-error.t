#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $tc;
{
    use MooseX::Meta::TypeConstraint::Intersection;
    use Moose::Util::TypeConstraints;

    subtype 'PositiveInt', as 'Int', where { $_ > 0 }, message { "$_ isn't greater than 0!" };
    subtype 'LessThanThirty', as 'Int', where { $_ < 30 }, message { "$_ isn't less than 30!" };

    $tc = MooseX::Meta::TypeConstraint::Intersection->new(
        type_constraints => [map { find_type_constraint($_) } 'PositiveInt', 'LessThanThirty'],
    );
}

{
    package Foo;
    use Moose;
    has foo => (
        is  => 'ro',
        isa => $tc,
    );
}

like(
    exception { Foo->new(foo => -1) },
    qr/-1 isn't greater than 0!/,
    "get the custom error"
);

like(
    exception { Foo->new(foo => 40) },
    qr/40 isn't less than 30!/,
    "get the custom error"
);

done_testing;
