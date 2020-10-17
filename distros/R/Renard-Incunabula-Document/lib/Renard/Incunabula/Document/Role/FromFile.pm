use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::FromFile;
# ABSTRACT: Role that provides a filename for a document
$Renard::Incunabula::Document::Role::FromFile::VERSION = '0.005';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(File FileUri);

has filename => (
	is => 'ro',
	isa => File,
	coerce => 1,
);

has filename_uri => (
	is => 'lazy', # _build_filename_uri
	isa => FileUri,
);

method _build_filename_uri() :ReturnType(FileUri) {
	FileUri->coerce($self->filename);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::FromFile - Role that provides a filename for a document

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 filename

A C<File> containing the path to a document.

=head2 filename_uri

A C<FileUri> containing the path to the document as a URI.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
