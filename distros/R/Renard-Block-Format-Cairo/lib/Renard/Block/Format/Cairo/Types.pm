use Renard::Incunabula::Common::Setup;
package Renard::Block::Format::Cairo::Types;
# ABSTRACT: Type library
$Renard::Block::Format::Cairo::Types::VERSION = '0.005';
use Type::Library 0.008 -base,
	-declare => [qw(
		RenderableDocumentModel
		RenderablePageModel
	)];
use Type::Utils -all;

role_type "RenderableDocumentModel",
	{ role => "Renard::Incunabula::Document::Role::Renderable" };

role_type "RenderablePageModel",
	{ role => "Renard::Incunabula::Page::Role::CairoRenderable" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::Format::Cairo::Types - Type library

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 RenderableDocumentModel

A type for any reference that does
L<Renard::Incunabula::Document::Role::Renderable>.

=head2 RenderablePageModel

A type for any reference that does
L<Renard::Incunabula::Page::Role::CairoRenderable>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
