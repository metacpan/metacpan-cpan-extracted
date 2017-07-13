use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface;
# ABSTRACT: A role to build the bounds from the size of a Cairo::ImageSurface
$Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(PositiveOrZeroInt);

with qw(Renard::Incunabula::Page::Role::Bounds);

has [ qw(width height) ] => (
	is => 'lazy', # _build_width _build_height
	isa => PositiveOrZeroInt,
);

method _build_width() :ReturnType(PositiveOrZeroInt) {
	$self->cairo_image_surface->get_width;
}

method _build_height() :ReturnType(PositiveOrZeroInt) {
	$self->cairo_image_surface->get_height;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Page::Role::BoundsFromCairoImageSurface - A role to build the bounds from the size of a Cairo::ImageSurface

=head1 VERSION

version 0.003

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Page::Role::Bounds>

=back

=head1 ATTRIBUTES

=head2 width

A L<PositiveOrZeroInt> that is the width of the C</cairo_image_surface>.

=head2 height

A L<PositiveOrZeroInt> that is the height of the C</cairo_image_surface>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
