use Renard::Curie::Setup;
package Renard::Curie::Model::Page::Role::CairoRenderable;
# ABSTRACT: Role for pages that represented by a Cairo image surface
$Renard::Curie::Model::Page::Role::CairoRenderable::VERSION = '0.001';
use Moo::Role;
use Function::Parameters;
use Renard::Curie::Types qw(PositiveOrZeroInt);
use Function::Parameters;

with qw(Renard::Curie::Model::Page::Role::Bounds);

requires 'cairo_image_surface';

has [ qw(width height) ] => (
	is => 'lazy', # _build_width _build_height
	isa => PositiveOrZeroInt,
);

method _build_width :ReturnType(PositiveOrZeroInt) {
	$self->cairo_image_surface->get_width;
}

method _build_height :ReturnType(PositiveOrZeroInt) {
	$self->cairo_image_surface->get_height;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Page::Role::CairoRenderable - Role for pages that represented by a Cairo image surface

=head1 VERSION

version 0.001

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Model::Page::Role::Bounds>

=back

=head1 ATTRIBUTES

=head2 cairo_image_surface

The L<Cairo::ImageSurface> which consumers of this role will render.

Consumes of this role must implement this.

=head2 width

A L<PositiveOrZeroInt> that is the width of the C</cairo_image_surface>.

=head2 height

A L<PositiveOrZeroInt> that is the height of the C</cairo_image_surface>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
