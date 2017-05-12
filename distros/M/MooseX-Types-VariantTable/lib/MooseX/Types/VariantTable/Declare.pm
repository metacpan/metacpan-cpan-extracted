#!/usr/bin/perl

package MooseX::Types::VariantTable::Declare;

use strict;
use warnings;

use Carp qw(croak);

use Sub::Exporter -setup => {
    exports => [qw(variant_method)],
    groups => {
        default => [qw(variant_method)],
    },
};

use Moose::Meta::Method::VariantTable;

sub variant_method ($$$) {
	my ( $name, $type, $body ) = @_;

	my $class = caller;

	my $meta = $class->meta;

	my $meta_method = $class->meta->get_method($name);

	unless ( $meta_method ) {
        $meta_method = Moose::Meta::Method::VariantTable->new(
            name => $name,
            class => $meta,
            package_name => $class,
        );

        $meta->add_method( $name => $meta_method );
	}

	if ( $meta_method->isa("Moose::Meta::Method::VariantTable") ) {
		$meta_method->add_variant( $type, $body );
	} else {
		croak "Method '$name' is already defined";
	}

	return $meta_method->body;
}

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Types::VariantTable::Declare - Declarative sugar for
L<MooseX::Types::VariantTable> based methods.

=head1 SYNOPSIS

    package Awesome;
    use Moose;

    variant_method dance => Item => sub {
        # Item is the least derived type in the hierarchy,
        # every other type subtypes it
        # this is in effect a fallback
        return "fallback";
    };

    # a more specific type
    variant_method dance => Ballerina => sub {
        my ( $self, $ballerina, @args ) = @_;

        $ballerina; # a value that passed the TC named "Ballerina"

        return "pretty!";
    };

    # also works with objects
    variant_method dance => $type_object => sub { ... };

=head1 DESCRIPTION

This module provides declarative sugar for defining
L<Moose::Meta::Method::VariantTable> methods in your L<Moose> classes and
roles.

These methods have some semantics:

=head2 Declaration

The order of the declarations do not matter in most cases.

It is the type hierarchy that defines the order in which the constraints are
checked and items dispatched.

However, in the case that two constraints without an explicit relationship
between them (one is a subtype of the other) both accept the same value, the
one that was declared earlier will win. There is no way around this issue, so
be careful what types you use especially when mixing variants form many
different sources.

Adding the same type to a variant table twice is an error.

=head2 Inheritence

When dispatching all of the subclass's variants will be tried before the
superclass.

This allows shadowing of types from the superclass even using broader types.

=head2 Roles

... are currently broken.

Don't use variant table methods in a role, unless that's the only definition,
because in the future variant table merging will happen at role composition
time in a role composition like way, so your code will not continue to work the
same.

=back
