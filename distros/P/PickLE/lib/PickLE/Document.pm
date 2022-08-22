#!/usr/bin/env perl

=head1 NAME

C<PickLE::Document> - Component pick list document abstraction

=cut

package PickLE::Document;

use 5.010;
use strict;
use warnings;
use autodie;
use Moo;
use Carp;
use List::Util qw(any);
use Scalar::Util qw(reftype);

use PickLE::Property;
use PickLE::Category;
use PickLE::Component;

=head1 SYNOPSIS

  use PickLE::Document;

  # Start from scratch.
  my $doc = PickLE::Document->new;
  $doc->add_category($category);
  $doc->save("example.pkl");

  # Load from file.
  $doc = PickLE::Document->load("example.pkl");

  # List all document properties.
  $doc->foreach_property(sub {
    my $property = shift;
    say $property->name . ': ' . $property->value;
  });

  # List all components in each category.
  $doc->foreach_category(sub {
    my $category = shift;
    $category->foreach_component(sub {
      my ($component) = @_;
      say $component->name;
    });
  });

=head1 ATTRIBUTES

=over 4

=item I<properties>

List of all of the pick list properties in the document.

=cut

has properties => (
	is      => 'ro',
	lazy    => 1,
	default => sub { [] },
	writer  => '_set_properties'
);

=item I<categories>

List of all of the categories available in the document.

=cut

has categories => (
	is      => 'ro',
	lazy    => 1,
	default => sub { [] },
	writer  => '_set_categories'
);

=back

=head1 METHODS

=over 4

=item I<$doc> = C<PickLE::Document>->C<new>()

Initializes an empty document object.

=item I<$doc> = C<PickLE::Document>->C<load>(I<$filename>)

=item I<$doc>->C<load>(I<$filename>)

Parses a component pick list file located at I<$filename>. This method can be
called statically, or as an object method. In both cases a brand new object will
be contructed.

=cut

sub load {
	my ($proto, $filename) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;

	# Parse the file.
	open my $fh, '<:encoding(UTF-8)', $filename;
	$self->_parse($fh) or return undef;
	close $fh;

	return $self;
}

=item I<$doc> = C<PickLE::Document>->C<from_string>(I<$str>)

=item I<$doc>->C<from_string>(I<$str>)

Parses a component pick list document from a string I<$str>. This method can be
called statically, or as an object method. In both cases a brand new object will
be contructed.

=cut

sub from_string {
	my ($proto, $str) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;

	# Parse the document.
	open my $fh, '<:encoding(UTF-8)', \$str;
	$self->_parse($fh) or return undef;
	close $fh;

	return $self;
}

=item I<$doc>->C<add_property>(I<@property>)

Adds any number of proprerties in the form of L<PickLE::Property> objects to the
document.

=cut

sub add_property {
	my $self = shift;

	# Go through properties adding them to the properties list.
	foreach my $property (@_) {
		push @{$self->properties}, $property;
	}
}

=item I<$doc>->C<add_category>(I<@category>)

Adds any number of categories in the form of L<PickLE::Category> objects to the
document.

=cut

sub add_category {
	my $self = shift;

	# Go through categories adding them to the categories list.
	foreach my $category (@_) {
		push @{$self->categories}, $category;
	}
}

=item I<$doc>->C<foreach_property>(I<$coderef>)

Executes a block of code (I<$coderef>) for each proprety. The property object
will be passed as the first argument.

=cut

sub foreach_property {
	my ($self, $coderef) = @_;

	# Go through the properties.
	foreach my $property (@{$self->properties}) {
		# Call the coderef given by the caller.
		$coderef->($property);
	}
}

=item I<$doc>->C<foreach_category>(I<$coderef>)

Executes a block of code (I<$coderef>) for each category available in the
document. The category object will be passed as the first argument.

=cut

sub foreach_category {
	my ($self, $coderef) = @_;

	# Go through the categories.
	foreach my $category (@{$self->categories}) {
		$coderef->($category);
	}
}

=item I<$property> = I<$self>->C<get_property>(I<$name>)

Gets a property of the document by its I<$name> and returns it if found,
otherwise returns C<undef>.

=cut

sub get_property {
	my ($self, $name) = @_;
	my $found = undef;

	# Go through the properties checking their names for a match.
	$self->foreach_property(sub {
		my $property = shift;
		if ($property->name eq $name) {
			$found = $property;
		}
	});

	return $found;
}

=item I<$category> = I<$self>->C<get_category>(I<$name>)

Gets a category in the document by its I<$name> and returns it if found,
otherwise returns C<undef>.

=cut

sub get_category {
	my ($self, $name) = @_;
	my $found = undef;

	# Go through the categories checking their names for a match.
	$self->foreach_category(sub {
		my $category = shift;
		if ($category->name eq $name) {
			$found = $category;
		}
	});

	return $found;
}

=item I<$doc>->C<save>(I<$filename>)

Saves the document object to a file.

=cut

sub save {
	my ($self, $filename) = @_;

	# Write object to file.
	open my $fh, '>:encoding(UTF-8)', $filename;
	print $fh $self->as_string;
	close $fh;
}

=item I<$doc>->C<as_string>()

String representation of this object, just like it is representated in the file.

=cut

sub as_string {
	my ($self) = @_;
	my $str = "";

	# Check if we have the required Name property.
	if (not defined $self->get_property('Name')) {
		carp "Document can't be represented because the required 'Name' " .
			'property is not defined';
		return '';
	}

	# Check if we have the required Revision property.
	if (not defined $self->get_property('Revision')) {
		carp "Document can't be represented because the required 'Revision' " .
			'property is not defined';
		return '';
	}

	# Check if we have the required Description property.
	if (not defined $self->get_property('Description')) {
		carp "Document can't be represented because the required 'Description' " .
			'property is not defined';
		return '';
	}

	# Go through properties getting their string representations.
	$self->foreach_property(sub {
		my $property = shift;
		$str .= $property->as_string . "\n";
	});

	# Add the header section separator.
	$str .= "\n---\n\n";

	# Go through categories getting their string representations.
	$self->foreach_category(sub {
		my $category = shift;
		$str .= $category->as_string . "\n";

		# Go through components getting their string representations.
		$category->foreach_component(sub {
			my $component = shift;
			$str .= $component->as_string . "\n\n";
		});
	});

	return $str;
}

=back

=head1 PRIVATE METHODS

=over 4

=item I<$status> = I<$self>->C<_parse>(I<$fh>)

Parses the contents of a file or scalar handle (I<$fh>) and populates the
object. Returns C<0> if there were parsing errors.

=cut

sub _parse {
	my ($self, $fh) = @_;
	my $status = 1;
	my $phases = {
		empty	   => 0,
		property   => 1,
		descriptor => 2,
		refdes	   => 3,
	};
	my $phase = $phases->{property};
	my $component = undef;
	my $category = undef;

	# Go through the file line-by-line.
	while (my $line = <$fh>) {
		# Clean up the line string.
		$line =~ s/^\s+|[\s\r\n]+$//g;

		# Check if we are about to parse a descriptor.
		if ($phase == $phases->{empty}) {
			if (substr($line, 0, 1) eq '[') {
				# Looks like we have to parse a descriptor line.
				$phase = $phases->{descriptor};
			} elsif (substr($line, -1, 1) eq ':') {
				# Got a category line.
				if (defined $category) {
					# Append the last category we parsed to the list.
					$self->add_category($category);
				}

				# Parse the new category.
				$category = PickLE::Category->from_line($line);
				if (not defined $category) {
					# Looks like the category line was malformed.
					carp "Error parsing category '$line'";
					$status = 0;
				}

				next;
			} elsif ($line eq '') {
				# Just another empty line...
				next;
			}
		} elsif ($phase == $phases->{refdes}) {
			# Parse the reference designators.
			$component->parse_refdes_line($line);

			# Append the component to the pick list and go to the next line.
			$category->add_component($component);
			$component = undef;
			$phase = $phases->{empty};
			next;
		} elsif ($phase == $phases->{property}) {
			# Looks like we are in the properties header.
			if ($line eq '') {
				# Just another empty line...
				next;
			} elsif ($line eq '---') {
				# We've finished parsing the properties header.
				$phase = $phases->{empty};
				next;
			}
			
			# Parse the property.
			my $prop = PickLE::Property->from_line($line);
			if (not defined $prop) {
				# Looks like the property line was malformed.
				carp "Error parsing property '$line'";
				$status = 0;
			}

			# Append the property to the properties list of the document.
			$self->add_property($prop);
			next;
		}

		# Parse the descriptor line into a component.
		$component = PickLE::Component->from_line($line);
		$phase = $phases->{refdes};
		if (not defined $component) {
			# Looks like the descriptor line was malformed.
			carp "Error parsing component descriptor '$line'";
			$status = 0;
		}
	}

	# Make sure we get that last category.
	if (defined $category) {
		# Append the last category we parsed to the list.
		$self->add_category($category);
	}

	return $status;
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
