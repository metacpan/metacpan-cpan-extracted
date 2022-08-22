#!/usr/bin/env perl

=head1 NAME

C<App::pickle::import> - Converts external files into PickLE pick lists.

=cut

package App::pickle::import;

use strict;
use warnings;
use autodie;
use utf8;
use Moo;

use PickLE::Document;
use PickLE::Converter::EagleBOM;

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

Type of file we are trying to import.

=cut

has type => (
	is => 'rw'
);

=item I<file>

PickLE file to be parsed into I<document>.

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

	# Import the file and print the converted PickLE pick list.
	$self->import_file;
	print $self->document->as_string;
}

=item C<import_file>()

Converts the imported file into a PickLE pick list document.

=cut

sub import_file {
	my ($self) = @_;

	# Make the type lowercase for good measure.
	$self->{type} = lc($self->{type});

	# Check if we are even able to import this file.
	if ($self->{type} eq 'eagle') {
		# Eagle CAD.
		my $bom = PickLE::Converter::EagleBOM->load($self->{file});
		$self->_set_document($bom->document);

		return;
	}

	# Unknown type to import.
	die "Unknown type of file to be imported. Supported types: eagle\n";
}

1;

__END__

=back

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
