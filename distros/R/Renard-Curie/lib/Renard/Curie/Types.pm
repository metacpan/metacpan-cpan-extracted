use Renard::Curie::Setup;
package Renard::Curie::Types;
# ABSTRACT: Type library
$Renard::Curie::Types::VERSION = '0.001';
use Type::Library 0.008 -base,
	-declare => [qw(
		DocumentModel
		RenderableDocumentModel
		PageNumber
	)];
use Type::Utils -all;

# Listed here so that scan-perl-deps can find them
use Types::Path::Tiny      ();
use Types::Standard        ();
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt);

use Type::Libraries;
Type::Libraries->setup_class(
	__PACKAGE__,
	qw(
		Types::Standard
		Types::Path::Tiny
		Types::Common::Numeric
	)
);


class_type "DocumentModel",
	{ class => "Renard::Curie::Model::Document" };

role_type "RenderableDocumentModel",
	{ role => "Renard::Curie::Model::Document::Role::Renderable" };

role_type "RenderablePageModel",
	{ role => "Renard::Curie::Model::Page::Role::CairoRenderable" };

declare "PageNumber", parent => PositiveInt;

declare "LaxPageNumber", parent => PositiveOrZeroInt;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Types - Type library

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=item * L<Type::Library>

=back

=head1 TYPES

=head2 DocumentModel

A type for any reference that extends L<Renard::Curie::Model::Document>.

=head2 RenderableDocumentModel

A type for any reference that does
L<Renard::Curie::Model::Document::Role::Renderable>.

=head2 RenderablePageModel

A type for any reference that does
L<Renard::Curie::Model::Page::Role::CairoRenderable>.

=head2 PageNumber

An alias to L<PositiveInt> that can be used for document page number semantics.

=head2 LaxPageNumber

An alias to L<PositiveOrZeroInt> that can be used for document page number
semantics when the source data may contain invalid pages.

=head1 TYPE LIBRARIES

=over 4

=item *

L<Types::Standard>

=item *

L<Types::Path::Tiny>

=item *

L<Types::Common::Numeric>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
