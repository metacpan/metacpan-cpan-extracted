use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager::Role::Document;
# ABSTRACT: A role for the document
$Renard::Curie::ViewModel::ViewManager::Role::Document::VERSION = '0.005';
use Moo::Role;

use Renard::Incunabula::Document::Types qw(DocumentModel);
use Renard::Incunabula::Common::Types qw(Path FileUri);

has current_document => (
	is => 'rw',
	isa => DocumentModel,
	trigger => 1, # _trigger_current_document
);

method _trigger_current_document( (DocumentModel) $doc ) {
	$self->clear_view_options;
	$self->current_view(
		Renard::Curie::Model::View::Grid->new(
			view_options => $self->view_options,
			document => $doc,
		)
	);

	$self->signal_emit( 'document-changed' => $doc );
}

method open_pdf_document( (Path->coercibles) $pdf_filename ) {
	$pdf_filename = Path->coerce( $pdf_filename );
	if( not -f $pdf_filename ) {
		Renard::Incunabula::Common::Error::IO::FileNotFound
			->throw("PDF filename does not exist: $pdf_filename");
	}

	$self->current_document(
		Renard::Block::Format::PDF::Document->new(
			filename => $pdf_filename,
		)
	);
}

method open_document_as_file_uri( (FileUri) $uri ) {
	$self->open_pdf_document( $uri->file );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager::Role::Document - A role for the document

=head1 VERSION

version 0.005

=head1 METHODS

=head2 open_pdf_document

  method open_pdf_document( (Path->coercibles) $pdf_filename )

Opens a PDF file stored on the disk.

=head2 open_document_as_file_uri

  method open_document_as_file_uri( (FileUri) $uri )

Takes a file in the form of a C<FileUri> and opens the file.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
