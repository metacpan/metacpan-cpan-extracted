use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Page::RenderedFromPNG;
# ABSTRACT: Page generated from PNG data
$Renard::Incunabula::Page::RenderedFromPNG::VERSION = '0.003';
use Moo;

with qw(
	Renard::Incunabula::Page::Role::CairoRenderableFromPNG
	Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Page::RenderedFromPNG - Page generated from PNG data

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Page::Role::Bounds>

=item * L<Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface>

=item * L<Renard::Incunabula::Page::Role::CairoRenderable>

=item * L<Renard::Incunabula::Page::Role::CairoRenderableFromPNG>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
