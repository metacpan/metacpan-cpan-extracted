#!/usr/bin/env perl

=head1 NAME

C<PickLE::Property> - Representation of a header property in a pick list

=cut

package PickLE::Property;

use strict;
use warnings;
use Carp;
use Moo;

=head1 ATTRIBUTES

=over 4

=item I<name>

Name of the property.

=cut

has name => (
	is => 'rw',
);

=item I<value>

Value of the property.

=cut

has value => (
	is => 'rw',
);

=back

=head1 METHODS

=over 4

=item I<$prop> = C<PickLE::Property>->C<new>([I<name>, I<value>])

Initializes a pick list property object with a I<name> and I<value>.

=item I<$prop> = C<PickLE::Property>->C<from_line>(I<$line>)

=item I<$prop> = I<$prop>->C<from_line>(I<$line>)

This method can be called statically, in which it will initialize a brand new
property object or in object context in which it'll override just the attributes
of the object and leave the instance intact.

In both variants it'll parse a property I<$line> from a document and populate
the object. Will return C<undef> if we couldn't parse a property from the given
line.

=cut

sub from_line {
	my ($self, $line) = @_;
	$self = $self->new() unless ref $self;

	# Try to parse the property line.
	if ($line =~ /(?<name>[A-Za-z0-9 \-]+):\s+(?<value>.+)/) {
		# Populate our object.
		$self->name($+{name});
		$self->value($+{value});

		return $self;
	}

	# Looks like the property line couldn't be parsed.
	return undef;
}

=item I<$str> = I<$prop>->C<as_string>()

Gets the string representation of this object. Will return an empty string if
the object is poorly populated.

=cut

sub as_string {
	my ($self) = @_;

	# Check if we have a name.
	if (not defined $self->name) {
		carp "Property can't be represented because the name is not defined";
		return '';
	}

	# Check if we have a value.
	if (not defined $self->value) {
		carp "Property can't be represented because the value is not defined";
		return '';
	}

	# Properly populated property.
	return $self->name . ': ' . $self->value;
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
