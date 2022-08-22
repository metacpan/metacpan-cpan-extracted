#!/usr/bin/env perl

=head1 NAME

C<App::pickle::export> - Converts PickLE pick lists into other files.

=cut

package App::pickle::export;

use strict;
use warnings;
use autodie;
use utf8;
use Moo;

use PickLE::Document;
use PickLE::Exporter::JSON;
use PickLE::Exporter::HTML;

=head1 ATTRIBUTES

=over 4

=item I<document>

PickLE parsed document object.

=cut

has document => (
	is     => 'ro',
	writer => '_set_document'
);

=item I<type>

Type of file the pick list will be converted into.

=cut

has type => (
	is => 'rw'
);

=item I<file>

PickLE file to be parsed into I<document> and exported.

=cut

has file => (
	is => 'rw'
);

=back

=head1 METHODS

=over 4

=item C<run>()

OptArgs command entry point.

=cut

sub run {
	my ($self) = @_;

	# Enable UTF-8 output.
	binmode STDOUT, ":encoding(utf8)";

	# Parse the supplied document file.
	$self->_set_document(PickLE::Document->load($self->file));
	if (not defined $self->document) {
		die "There were errors while trying to parse the document.\n";
	}

	# Export the pick list.
	print $self->export;
}

=item I<$contents> = I<$self>->C<export>()

Gets the contents of the PickLE pick list in the specified format.

=cut

sub export {
	my ($self) = @_;

	# Make the type lowercase for good measure.
	$self->{type} = lc($self->{type});

	# Check if we are even able to export in this file type.
	if ($self->{type} eq 'json') {
		# JSON
		return PickLE::Exporter::JSON->as_string($self->{document});
	} elsif ($self->{type} eq 'html') {
		# HTML
		return PickLE::Exporter::HTML->as_string($self->{document});
	}

	# Unknown type to export.
	die "Unknown type of file to be exported. Supported types: html, json\n";
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
