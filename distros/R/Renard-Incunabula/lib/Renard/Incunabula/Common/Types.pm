use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Common::Types;
# ABSTRACT: Type library
$Renard::Incunabula::Common::Types::VERSION = '0.003';
use Type::Library 0.008 -base,
	-declare => [qw(
		DocumentModel
		RenderableDocumentModel
		PageNumber
		PageCount
		LaxPageNumber
		ZoomLevel
		SizeRequest
	)];
use Type::Utils -all;

# Listed here so that scan-perl-deps can find them
use Types::Path::Tiny      ();
use Types::URI             ();
use Types::Standard        qw(Tuple);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt PositiveNum);

use Type::Libraries;
Type::Libraries->setup_class(
	__PACKAGE__,
	qw(
		Types::Standard
		Types::Path::Tiny
		Types::URI
		Types::Common::Numeric
	)
);


class_type "DocumentModel",
	{ class => "Renard::Incunabula::Document" };

role_type "RenderableDocumentModel",
	{ role => "Renard::Incunabula::Document::Role::Renderable" };

role_type "RenderablePageModel",
	{ role => "Renard::Incunabula::Page::Role::CairoRenderable" };

declare "PageNumber", parent => PositiveInt;

declare "PageCount", parent => PositiveInt;

declare "LaxPageNumber", parent => PositiveOrZeroInt;

declare "ZoomLevel", parent => PositiveNum;

declare "SizeRequest",
	parent => Tuple[PositiveInt,PositiveInt];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Common::Types - Type library

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=item * L<Type::Library>

=back

=head1 TYPES

=head2 DocumentModel

A type for any reference that extends L<Renard::Incunabula::Document>.

=head2 RenderableDocumentModel

A type for any reference that does
L<Renard::Incunabula::Document::Role::Renderable>.

=head2 RenderablePageModel

A type for any reference that does
L<Renard::Incunabula::Page::Role::CairoRenderable>.

=head2 PageNumber

An alias to L<PositiveInt> that can be used for document page number semantics.

=head2 PageCount

An alias to L<PositiveInt> that can be used for document page number count semantics.

=head2 LaxPageNumber

An alias to L<PositiveOrZeroInt> that can be used for document page number
semantics when the source data may contain invalid pages.

=head2 ZoomLevel

The amount to zoom in on a page. This is a multiplier such that

=over 4

=item *

when the value is C<1.0>, the page area is the standard area

=item *

when the value is C<2.0>, the page is C<4> times the standard area

=item *

when the value is C<0.5>, the page is C<0.25> times the standard area

=back

=head2 SizeRequest

A tuple that represents a size request for a widget.

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

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
