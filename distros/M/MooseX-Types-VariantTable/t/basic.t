#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MooseX::Types::VariantTable';
use Test::Exception;

use Moose::Util::TypeConstraints;

{
    package Bar;
    use Moose;

    package Foo;
    use Moose;

    extends qw(Bar);
    
    package Gorch;
    use Moose;

    extends qw(Bar);

    package Blah;
    use Moose;

    extends qw(Foo);

    package Oink;
    use Moose;
}

my %types = ( Foo => "a foo", Bar => "a bar", Item => "any", ArrayRef => "array ref" );

BEGIN {
    if ( eval { require Math::Combinatorics } ) {
        Math::Combinatorics->import("permute");
    } else {
        *permute = sub {
            # not quite, but close enough
            return ( [ @_ ], [ reverse @_ ], [ sort @_ ], [ reverse sort @_ ] );
        };
    }
}

foreach my $keys ( permute keys %types ) {

    my $v = MooseX::Types::VariantTable->new;

    foreach my $key ( @$keys ) {
        $v->add_variant( $key => $types{$key} );
    }

    is( $v->find_variant( Foo->new ), "a foo", "foo object" );
    is( $v->find_variant( Bar->new ), "a bar", "bar object" );
    is( $v->find_variant( Gorch->new ), "a bar", "bar subclass" );
    is( $v->find_variant( Blah->new ), "a foo", "foo subclass" );
    is( $v->find_variant( Oink->new ), "any", "fallback to Item" );
    is( $v->find_variant( [] ), "array ref", "simple tc" );
    is( $v->find_variant( undef ), "any", "fallback to Item" );
}

my $v = MooseX::Types::VariantTable->new(
    variants => [
        { type => "Foo", value => "a foo" },
        { type => "Bar", value => "a bar" },
    ],
);

is( $v->find_variant( Foo->new ), "a foo", "Foo object" );
is( $v->find_variant( Bar->new ), "a bar", "bar object" );

ok( $v->has_type("Foo"), "has a foo variant" );
ok( $v->has_parent("Foo"), "has a foo parent variant" );

$v->remove_variant("Foo");

is( $v->find_variant( Foo->new ), "a bar", "foo variant removed" );
is( $v->find_variant( Bar->new ), "a bar", "bar object" );

ok( !$v->has_type("Foo"), "no longer has a foo variant" );
ok( $v->has_parent("Foo"), "has a foo parent variant" );

ok( !$v->has_type("ArrayRef"), "no ArrayRef variant" );
ok( !$v->has_parent("ArrayRef"), "no ArrayRef parent variant" );
is( $v->find_variant([]), undef, "nothing found" );

throws_ok { $v->add_variant(Bar => "something else") } qr/duplicate/i;
