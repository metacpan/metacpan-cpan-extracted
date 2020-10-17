use Renard::Incunabula::Common::Setup;
package Renard::Block::Format::PDF::Devel::TestHelper;
# ABSTRACT: A test helper with functions useful for testing PDF documents
$Renard::Block::Format::PDF::Devel::TestHelper::VERSION = '0.005';
use Renard::Incunabula::Common::Types qw(InstanceOf);

use Renard::Incunabula::Devel::TestHelper;
use Renard::Block::Format::PDF::Document;

classmethod pdf_reference_document_path() {
	Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
}

classmethod pdf_reference_document_object() :ReturnType(InstanceOf['Renard::Block::Format::PDF::Document']) {
	Renard::Block::Format::PDF::Document->new(
		filename => $class->pdf_reference_document_path
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::Format::PDF::Devel::TestHelper - A test helper with functions useful for testing PDF documents

=head1 VERSION

version 0.005

=head1 CLASS METHODS

=head2 pdf_reference_document_path

Returns the path to C<pdf_reference_1-7.pdf> in the test data directory.

=head2 pdf_reference_document_object

Returns a L<Renard::Block::Format::PDF::Document> for the document located
at the path returned by L<pdf_reference_document_path>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
