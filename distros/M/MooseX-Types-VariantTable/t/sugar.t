#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

{
    package Gorch;
    use Moose;

    package Bar;
    use Moose;
    
    extends qw(Gorch);

    package Baz;
    use Moose;

    extends qw(Gorch);

    package Foo;
    use Moose;
    use MooseX::Types::VariantTable::Declare;

    variant_method foo => Gorch => sub { "gorch" };
    variant_method foo => Bar => sub { "bar" };
    variant_method foo => Item => sub { "any" };

    package Oink;
    use Moose;

    extends qw(Foo);

    MooseX::Types::VariantTable::Declare::variant_method( foo => Baz => sub { "baz" } );
}

my $bar = Bar->new;
my $gorch = Gorch->new;
my $baz = Baz->new;

my $foo = Foo->new;
my $oink = Oink->new;

can_ok( $foo, "foo" );

is( $foo->foo($gorch), "gorch", "variant table method on $gorch" );
is( $foo->foo($bar), "bar", "... on $bar" );
is( $foo->foo([]), "any", "... on array ref" );

is( $oink->foo($baz), "baz", "additional variant in subclass" );
is( $oink->foo($gorch), "gorch", "inherited variant in subclass" );
is( $oink->foo($bar), "bar", "inherited variant in subclass" );

$foo->meta->get_method("foo")->remove_variant("Bar");

is( $foo->foo($gorch), "gorch", "$gorch" );
is( $foo->foo($bar), "gorch", "$bar is now gorch because it's variant was removed" );

is( $foo->foo($baz), "gorch", "$baz is gorch" );

is( $oink->foo($bar), "gorch", "removal from superclass propagated" );

# TODO roles
