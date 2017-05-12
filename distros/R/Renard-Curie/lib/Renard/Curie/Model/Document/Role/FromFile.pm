use Renard::Curie::Setup;
package Renard::Curie::Model::Document::Role::FromFile;
# ABSTRACT: Role that provides a filename for a document
$Renard::Curie::Model::Document::Role::FromFile::VERSION = '0.001';
use Moo::Role;
use Renard::Curie::Types qw(File);

has filename => (
	is => 'ro',
	isa => File,
	coerce => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Document::Role::FromFile - Role that provides a filename for a document

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 filename

A C<Str> containing the path to a document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
