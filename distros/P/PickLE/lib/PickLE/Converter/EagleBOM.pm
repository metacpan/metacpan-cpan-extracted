#!/usr/bin/env perl

=head1 NAME

C<PickLE::Converter::EagleBOM> - Converts an EAGLE exported BOM CSV file

=cut

package PickLE::Converter::EagleBOM;

use strict;
use warnings;
use autodie;
use Moo;
use Text::CSV;

use PickLE::Document;
use PickLE::Property;
use PickLE::Category;
use PickLE::Component;

=head1 ATTRIBUTES

=over 4

=item I<document>

Converted BOM into a L<PickLE::Document> object.

=cut

has document => (
	is      => 'ro',
	lazy    => 1,
	default => sub { PickLE::Document->new },
	writer  => '_set_document'
);

=back

=head1 METHODS

=over 4

=item I<$bom> = C<PickLE::Converter::EagleBOM>->C<load>(I<$csvfile>)

Initializes the converter with a CSV file of a BOM exported straight out of
Eagle.

=cut

sub load {
	my ($proto, $csvfile) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;

	# Setup the CSV parser.
	my $csv = Text::CSV->new({
		sep_char => ';',
		auto_diag => 2
	});

	# Create a basic document with the required properties.
	$self->_set_document(PickLE::Document->new);
	$self->document->add_property(PickLE::Property->new(
		name  => 'Name',
		value =>'Eagle Imported File'
	));
	$self->document->add_property(PickLE::Property->new(
		name  => 'Revision',
		value => 'A'
	));
	$self->document->add_property(PickLE::Property->new(
		name  => 'Description',
		value => 'A very descriptive description.'
	));

	# Open the CSV file to be parsed and dicard the row with the headers.
	open my $fh, "<:encoding(UTF-8)", $csvfile;
	$csv->getline($fh);

	# Go through each line parsing the components.
	while (my $row = $csv->getline($fh)) {
		# Do we need to create a new category?
		my $category = $self->document->get_category($row->[5]);
		if (not defined $category) {
			$category = PickLE::Category->new(name => $row->[5]);
			$self->document->add_category($category);
		}

		# Create and populate our component object.
		my $component = PickLE::Component->new;
		$component->name($row->[2]);
		$component->value($row->[1]) if ($row->[1] ne $row->[2]);
		$component->description($row->[5]);
		$component->case($row->[3]);
		$component->add_refdes(split /, /, $row->[4]);

		# Append the parsed component to its category.
		$category->add_component($component);
    }
	close $fh;

	return $self;
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
