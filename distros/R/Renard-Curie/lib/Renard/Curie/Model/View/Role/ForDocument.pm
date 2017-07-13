use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Role::ForDocument;
# ABSTRACT: Role for view model based on a document
$Renard::Curie::Model::View::Role::ForDocument::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(RenderableDocumentModel);

has document => (
	is => 'rw',
	isa => RenderableDocumentModel,
	required => 1
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Role::ForDocument - Role for view model based on a document

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 document

The L<RenderableDocumentModel|Renard:Curie::Types/RenderableDocumentModel> that
this view model represents.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
