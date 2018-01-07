use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Format::PDF::InformationDictionary;
# ABSTRACT: represents the PDF document information dictionary
$Renard::Incunabula::Format::PDF::InformationDictionary::VERSION = '0.004';
use Moo;
use Renard::Incunabula::Common::Types qw(Maybe File InstanceOf Str HashRef ArrayRef);
use Renard::Incunabula::MuPDF::mutool;

has filename => (
	is => 'ro',
	isa => File,
	coerce => 1,
);

has _object => (
	is => 'lazy',
	isa => InstanceOf['Renard::Incunabula::MuPDF::mutool::ObjectParser'],
	handles => {
	},
);

method _build__object() {
	Renard::Incunabula::MuPDF::mutool::get_mutool_get_info_object_parsed( $self->filename );
}

method _get_data( (Str) $key ) {
	my $obj = $self->_object->resolve_key($key);

	return $obj->data if $obj;
}

has default_properties => (
	is => 'ro',
	isa => ArrayRef,
	default => sub {
		[qw(
			Title
			Subject
			Author
			Keywords
			Creator
			Producer
			CreationDate
			ModDate
		)]
	},
);

method Title() :ReturnType(Maybe[Str]) {
	$self->_get_data('Title');
}

method Subject() :ReturnType(Maybe[Str]) {
	$self->_get_data('Subject');
}

method Author() :ReturnType(Maybe[Str]) {
	$self->_get_data('Author');
}

method Keywords() :ReturnType(Maybe[Str]) {
	$self->_get_data('Keywords');
}

method Creator() :ReturnType(Maybe[Str]) {
	$self->_get_data('Creator');
}

method Producer() :ReturnType(Maybe[Str]) {
	$self->_get_data('Producer');
}

method CreationDate() :ReturnType(Maybe[InstanceOf['Renard::Incunabula::MuPDF::mutool::DateObject']]) {
	$self->_get_data('CreationDate');
}

method ModDate() :ReturnType(Maybe[InstanceOf['Renard::Incunabula::MuPDF::mutool::DateObject']]) {
	$self->_get_data('ModDate');
}

1;

__END__

=pod

=encoding UTF-8

=begin stopwords

CreationDate ModDate

PieceInfo

FrameMaker FrameMaker®

=end stopwords

=head1 NAME

Renard::Incunabula::Format::PDF::InformationDictionary - represents the PDF document information dictionary

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Allows for access to the common fields used for the PDF document information
dictionary.

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 filename

A C<File> containing the path to a document.

=head2 default_properties

An C<ArrayRef> of the default properties that are expected in the information
dictionary.

=head1 METHODS

=head2 Title

=over 4

=item Type

text string

=item Description

(Optional; PDF 1.1) The document’s title.

=back

=head2 Subject

=over 4

=item Type

text string

=item Description

(Optional; PDF 1.1) The subject of the document.

=back

=head2 Author

=over 4

=item Type

text string

=item Description

(Optional) The name of the person who created the document.

=back

=head2 Keywords

=over 4

=item Type

text string

=item Description

(Optional; PDF 1.1) Keywords associated with the document.

=back

=head2 Creator

=over 4

=item Type

text string

=item Description

(Optional) If the document was converted to PDF from another format, the
name of the application (for example, Adobe FrameMaker®) that created the
original document from which it was converted.

=back

=head2 Producer

=over 4

=item Type

text string

=item Description

(Optional) If the document was converted to PDF from another format, the name
of the application (for example, Acrobat Distiller) that converted it to PDF.

=back

=head2 CreationDate

=over 4

=item Type

date

=item Description

(Optional) The date and time the document was created, in human-readable form
(see Section 3.8.3, “Dates”).

=back

=head2 ModDate

=over 4

=item Type

date

=item Description

(Required if PieceInfo is present in the document catalog; otherwise optional;
PDF 1.1) The date and time the document was most recently modified, in
human-readable form (see Section 3.8.3, “Dates”).

=back

=head1 SEE ALSO

Table 10.2 on pg. 844 of the I<PDF Reference, version 1.7> for more information.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
