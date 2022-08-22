#!/usr/bin/env perl

=head1 NAME

C<PickLE::Exporter::JSON> - Converts a PickLE document to JSON.

=cut

package PickLE::Exporter::JSON;

use strict;
use warnings;
use autodie;
use JSON::MaybeXS;

use PickLE::Document;

=head1 METHODS

=over 4

=item I<$%json> = C<PickLE::Exporter::JSON>->C<as_hash>(I<$document>)

Converts a PickLE I<$document> into a hash reference that can be easily
converted to JSON by any of the common libraries.

=cut

sub as_hash {
	my ($class, $document) = @_;
	my $json = {
		doctype => 'pickle',
		version => 1,
		name => undef,
		revision => undef,
		description => undef,
		properties => [],
		categories => []
	};

	# Populate the properties list.
	$document->foreach_property(sub {
		my $property = shift;

		# Handle special properties.
		if ($property->name eq 'Name') {
			# Name
			$json->{name} = $property->value;
		} elsif ($property->name eq 'Revision') {
			# Revision
			$json->{revision} = $property->value;
		} elsif ($property->name eq 'Description') {
			# Description
			$json->{description} = $property->value;
		} else {
			# All other properties.
			push @{$json->{properties}}, {
				name => $property->name,
				value => $property->value
			};
		}
	});

	# Populate the categories list.
	$document->foreach_category(sub {
		my $category = shift;
		my $cat_json = {
			name => $category->name,
			components => []
		};

		# Populate the components list.
		$category->foreach_component(sub {
			my $component = shift;
			push @{$cat_json->{components}}, {
				picked => (($component->picked) ? \1 : \0),
				quantity => $component->quantity,
				name => $component->name,
				value => $component->value,
				description => $component->description,
				package => $component->case,
				refdes => $component->refdes
			};
		});

		# Push the category to the list.
		push @{$json->{categories}}, $cat_json;
	});

	return $json;
}

=item I<$json_str> = C<PickLE::Exporter::JSON>->C<as_string>(I<$document>)

Converts a PickLE I<$document> into a JSON string.

=cut

sub as_string {
	my ($class, $document) = @_;

	my $json = JSON::MaybeXS->new(
		utf8 => 1,
		pretty => 1,
		sort_by => 1
	);

	return $json->encode(PickLE::Exporter::JSON->as_hash($document));
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
