use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Page::CairoImageSurface;
# ABSTRACT: Page directly generated from a Cairo image surface
$Renard::Incunabula::Page::CairoImageSurface::VERSION = '0.003';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has cairo_image_surface => (
	is => 'ro',
	isa => InstanceOf['Cairo::ImageSurface'],
	required => 1
);

with qw(
	Renard::Incunabula::Page::Role::CairoRenderable
	Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Page::CairoImageSurface - Page directly generated from a Cairo image surface

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

=back

=head1 ATTRIBUTES

=head2 cairo_image_surface

The L<Cairo::ImageSurface> that this page is drawn on.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
