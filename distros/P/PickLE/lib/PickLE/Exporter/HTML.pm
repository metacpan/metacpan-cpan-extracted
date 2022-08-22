#!/usr/bin/env perl

=head1 NAME

C<PickLE::Exporter::HTML> - Converts a PickLE document to HTML.

=cut

package PickLE::Exporter::HTML;

use strict;
use warnings;
use autodie;
use XML::Writer;

use PickLE::Document;

=head1 METHODS

=over 4

=item I<$html> = C<PickLE::Exporter::HTML>->C<as_string>(I<$document>)

Converts a PickLE document (I<$document>) into an HTML document and returns it
as a string.

=cut

sub as_string {
	my ($class, $document) = @_;

	# Setup HTML generator.
	my $html = XML::Writer->new(
		OUTPUT => 'self',
		DATA_MODE => 1,
		DATA_INDENT => 2
	);

	# Build HTML skeleton.
	$html->startTag('html');
	$html->startTag('head');
	$html->dataElement('title', 'Pick List');
	$html->endTag('head');
	$html->startTag('body');

	# Go through properties.
	$html->startTag('dl');
	$document->foreach_property(sub {
		my $property = shift;
		
		$html->dataElement('dt', $property->name);
		$html->dataElement('dd', $property->value);
	});
	$html->endTag('dl');

	# Go through categories.
	$document->foreach_category(sub {
		my $category = shift;
		$html->dataElement('h2', $category->name);

		# Start creating the table.
		$html->startTag('table',
						border => '1',
						cellpadding => '2',
						cellspacing => '1');
		$html->startTag('tr');
		$html->dataElement('th', '#');
		$html->dataElement('th', 'Qnt.');
		$html->dataElement('th', 'Part #');
		$html->dataElement('th', 'Value');
		$html->dataElement('th', 'Reference Designators');
		$html->dataElement('th', 'Description');
		$html->dataElement('th', 'Package');
		$html->endTag('tr');

		# Go through components for the given category.
		$category->foreach_component(sub {
			my $component = shift;

			# Add a component to the table.
			$html->startTag('tr');
			$html->startTag('td', align => 'center');
			if ($component->picked) {
				$html->emptyTag('input',
								type => 'checkbox',
								checked => 'checked');
			} else {
				$html->emptyTag('input', type => 'checkbox');
			}
			$html->endTag('td');
			$html->dataElement('td', $component->quantity, align => 'center');
			$html->dataElement('td', $component->name, align => 'center');
			$html->dataElement('td', $component->value, align => 'center');
			$html->dataElement('td', $component->refdes_string);
			$html->dataElement('td', $component->description, align => 'center');
			$html->dataElement('td', $component->case, align => 'center');
			$html->endTag('tr');
		});

		# End the table.
		$html->endTag('table');
	});

	# Finish up and return.
	$html->endTag('body');
	$html->endTag('html');
	return $html->end();
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
