#!/usr/bin/env perl

=head1 NAME

C<PickLE::Category> - Representation of a category in a pick list

=cut

package PickLE::Category;

use strict;
use warnings;
use Carp;
use Moo;

=head1 ATTRIBUTES

=over 4

=item I<name>

Name of the category.

=cut

has name => (
	is => 'rw',
);

=item I<components>

List of components to be picked from this category.

=cut

has components => (
	is      => 'ro',
	lazy    => 1,
	default => sub { [] },
	writer  => '_set_components'
);

=back

=head1 METHODS

=over 4

=item I<$category> = C<PickLE::Category>->C<new>([I<name>, I<components>])

Initializes a pick list category object with a I<name> and some I<components>.

=item I<$category> = C<PickLE::Category>->C<from_line>(I<$line>)

=item I<$category> = I<$category>->C<from_line>(I<$line>)

This method can be called statically, in which it will initialize a brand new
category object or in object context in which it'll override just the attributes
of the object and leave the instance intact.

In both variants it'll parse a category I<$line> from a document and populate
the object. Will return C<undef> if we couldn't parse a category from the given
line.

=cut

sub from_line {
	my ($self, $line) = @_;
	$self = $self->new() unless ref $self;

	# Try to parse the category line.
	if ($line =~ /(?<name>[^:]+):\s*/) {
		# Populate our object.
		$self->name($+{name});

		return $self;
	}

	# Looks like the category line couldn't be parsed.
	return undef;
}

=item I<$category>->C<add_component>(I<@component>)

Adds any number of components in the form of L<PickLE::Component> objects to the
category.

=cut

sub add_component {
	my $self = shift;

	# Go through components adding them to the components list.
	foreach my $component (@_) {
		push @{$self->components}, $component;
	}
}

=item I<$category>->C<foreach_component>(I<$coderef>)

Executes a block of code (I<$coderef>) for each component available in this
category. The component object will be passed as the first argument.

=cut

sub foreach_component {
	my ($self, $coderef) = @_;

	# Go through the components.
	foreach my $component (@{$self->components}) {
		$coderef->($component);
	}
}

=item I<$str> = I<$category>->C<as_string>()

Gets the string representation of this object. Won't include any of the
associated components and will return an empty string if a I<name> isn't
defined.

=cut

sub as_string {
	my ($self) = @_;

	# Check if we have a name.
	if (not defined $self->name) {
		carp "Category can't be represented because the name is not defined";
		return '';
	}

	# Properly populated category.
	return $self->name . ':';
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
