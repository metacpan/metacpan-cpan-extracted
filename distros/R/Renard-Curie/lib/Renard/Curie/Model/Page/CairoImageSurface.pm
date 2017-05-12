use Renard::Curie::Setup;
package Renard::Curie::Model::Page::CairoImageSurface;
# ABSTRACT: Page directly generated from a Cairo image surface
$Renard::Curie::Model::Page::CairoImageSurface::VERSION = '0.001';
use Moo;
use Renard::Curie::Types qw(InstanceOf);

has cairo_image_surface => (
	is => 'ro',
	isa => InstanceOf['Cairo::ImageSurface'],
	required => 1
);

with qw(Renard::Curie::Model::Page::Role::CairoRenderable);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Page::CairoImageSurface - Page directly generated from a Cairo image surface

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Model::Page::Role::Bounds>

=item * L<Renard::Curie::Model::Page::Role::CairoRenderable>

=back

=head1 ATTRIBUTES

=head2 cairo_image_surface

The L<Cairo::ImageSurface> that this page is drawn on.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
