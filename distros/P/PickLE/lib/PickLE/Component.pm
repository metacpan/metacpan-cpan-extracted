#!/usr/bin/env perl

=head1 NAME

C<PickLE::Component> - Representation of an electronic component in a pick list

=cut

package PickLE::Component;

use strict;
use warnings;
use Carp;
use Moo;

=head1 ATTRIBUTES

=over 4

=item I<picked>

Has the component in the list already been picked?

=cut

has picked => (
	is      => 'rw',
	default => 0
);

=item I<name>

Name or part number of the component. A way to uniquely identify this component
in the list without being too descriptive.

=cut

has name => (
	is      => 'rw',
	default => ''
);

=item I<value>

Component value if it has one. Useful for things like passive components. This
attribute also has associated clearer (C<clear_value>) and predicate
(C<has_value>) methods.

=cut

has value => (
	is        => 'rw',
	clearer   => 1,
	predicate => 1
);

=item I<description>

A brief description of the component to make it easier to understand what the
often times cryptic I<name> refers to. This attribute also has associated
clearer (C<clear_description>) and predicate (C<has_description>) methods.

=cut

has description => (
	is        => 'rw',
	clearer   => 1,
	predicate => 1
);

=item I<case>

Since C<package> is kind of a reserved word, this defines the component package
as a simple string. This attribute also has associated clearer (C<clear_case>)
and predicate (C<has_case>) methods.

=cut

has case => (
	is        => 'rw',
	clearer   => 1,
	predicate => 1
);

=item I<refdes>

A B<list reference> of reference designators for this component. This is
important since it'll be the only way this class can determine the quantity of
components to be picked.

=cut

has refdes => (
	is      => 'ro',
	lazy    => 1,
	default => sub { [] },
	writer  => '_set_refdes'
);

=back

=head1 METHODS

=over 4

=item I<$comp> = C<PickLE::Component>->C<new>([I<picked>, I<name>, I<value>,
I<description>, I<case>, I<refdes>])

Initializes a component object with a I<name>, the reference designator list
(I<refdes>), if the component has been I<picked>, a I<value> in cases where it
is applicable, a brief I<description> if you see fit, and an component package
(I<case>).

=item I<$comp> = C<PickLE::Component>->C<from_line>(I<$line>)

=item I<$comp> = I<$comp>->C<from_line>(I<$line>)

This method can be called statically, in which it will initialize a brand new
component object, or in object context in which it'll override just the
attributes of the object and leave the instance intact.

In both variants it'll parse a component descriptor I<$line> and populate the
component object. Will return C<undef> if we couldn't parse a component from the
given line.

=cut

sub from_line {
	my ($self, $line) = @_;
	$self = $self->new() unless ref $self;

	# Try to parse the component descriptor line.
	if ($line =~ /\[(?<picked>.)\]\s+(?<quantity>\d+)\s+(?<name>[^\s]+)\s*(\((?<value>[^\)]+)\)\s*)?("(?<description>[^"]+)"\s*)?(\[(?<case>[^\]]+)\]\s*)?/) {
		# Populate the component with required parameters.
		$self->picked(($+{picked} ne ' ') ? 1 : 0);
		$self->name($+{name});

		# Component value.
		if (exists $+{value}) {
			$self->value($+{value});
		}

		# Component description.
		if (exists $+{description}) {
			$self->description($+{description});
		}

		# Component package.
		if (exists $+{case}) {
			$self->case($+{case});
		}

		return $self;
	}

	# Looks like the component descriptor line couldn't be parsed.
	return undef;
}

=item I<$comp>->C<parse_refdes_line>(I<$line>)

Parses the reference designator line in a document and populates the I<refdes>
list with them.

=cut

sub parse_refdes_line {
	my ($self, $line) = @_;

	# Append the reference designators.
	if (substr($line, 0, 1) ne '') {
		$self->add_refdes(split /\s+/, $line);
	}
}

=item I<$comp>->C<add_refdes>(I<@refdes>)

Adds any number of reference designators to the reference designator list.

=cut

sub add_refdes {
	my $self = shift;
	push @{$self->refdes}, @_;
}

=item I<$quantity> = I<$comp>->C<quantity>()

Gets the quantity of the component to be picked.

=cut

sub quantity {
	my ($self) = @_;

	return scalar @{$self->refdes};
}

=item I<$str> = I<$comp>->C<refdes_string>()

Gets the list of reference designators seoarated by spaces as a string.

=cut

sub refdes_string {
	my ($self) = @_;
	my $str = '';

	# Go through reference designators building up a string.
	foreach my $refdes (@{$self->refdes}) {
		$str .= "$refdes ";
	}

	# Remove any trailling whitespace and return.
	$str =~ s/\s+$//;
	return $str;
}

=item I<$str> = I<$comp>->C<as_string>()

Gets the string representation of this object.

=cut

sub as_string {
	my ($self) = @_;
	my $str = '';

	# Make sure we have a name.
	if (not $self->_attr_available($self->name)) {
		carp "Component can't be represented because no name has been defined";
		return '';
	}

	# First line.
	$str .= '[' . (($self->picked) ? 'X' : ' ') . "]\t" . $self->quantity .
		"\t" . $self->name;

	# Component value.
	if ($self->_attr_available($self->value)) {
		$str .= "\t(" . $self->value . ')';
	}

	# Component description.
	if ($self->_attr_available($self->description)) {
		$str .= "\t\"" . $self->description . "\"";
	}

	# Component package.
	if ($self->_attr_available($self->case)) {
		$str .= "\t[" . $self->case . ']';
	}

	# Reference designators.
	$str .= "\n";
	$str .= $self->refdes_string;

	# Remove any trailling whitespace and return.
	$str =~ s/\s+$//;
	return $str;
}

=back

=head1 PRIVATE METHODS

=over 4

=item I<$available> = I<$self>->C<_attr_available>(I<$attribute>)

Checks if an I<$attribute> is defined and isn't an empty string.

=cut

sub _attr_available {
	my ($self, $attribute) = @_;

	return ((defined $attribute) and ($attribute ne ''));
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
