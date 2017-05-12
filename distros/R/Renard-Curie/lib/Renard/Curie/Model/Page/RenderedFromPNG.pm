use Renard::Curie::Setup;
package Renard::Curie::Model::Page::RenderedFromPNG;
# ABSTRACT: Page generated from PNG data
$Renard::Curie::Model::Page::RenderedFromPNG::VERSION = '0.001';
use Moo;
use Cairo;
use Function::Parameters;
use Renard::Curie::Types qw(Str InstanceOf Int);

has png_data => (
	is => 'rw',
	isa => Str,
	required => 1
);

has cairo_image_surface => (
	is => 'lazy', # _build_cairo_image_surface
);

method _build_cairo_image_surface :ReturnType(InstanceOf['Cairo::ImageSurface']) {
	# read the PNG data in-memory
	my $img = Cairo::ImageSurface->create_from_png_stream(
		fun ((Str) $callback_data, (Int) $length) {
			state $offset = 0;
			my $data = substr $callback_data, $offset, $length;
			$offset += $length;
			$data;
		}, $self->png_data );

	return $img;
}

with qw(
	Renard::Curie::Model::Page::Role::CairoRenderable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Page::RenderedFromPNG - Page generated from PNG data

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

=head2 png_data

A binary C<Str> which contains the PNG data that represents this page.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
