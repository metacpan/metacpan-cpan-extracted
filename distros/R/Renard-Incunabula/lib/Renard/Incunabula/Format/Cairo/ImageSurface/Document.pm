use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Format::Cairo::ImageSurface::Document;
# ABSTRACT: Document made up of a collection of Cairo image surfaces
$Renard::Incunabula::Format::Cairo::ImageSurface::Document::VERSION = '0.003';
use Moo;
use Renard::Incunabula::Page::CairoImageSurface;
use Function::Parameters;
use Renard::Incunabula::Common::Types qw(PageNumber InstanceOf ArrayRef);

extends qw(Renard::Incunabula::Document);

has image_surfaces => (
	is => 'ro',
	isa => ArrayRef[InstanceOf['Cairo::ImageSurface']],
	required => 1
);

method _build_last_page_number() :ReturnType(PageNumber) {
	return scalar @{ $self->image_surfaces };
}

method get_rendered_page( (PageNumber) :$page_number, @) {
	my $index = $page_number - 1;

	return Renard::Incunabula::Page::CairoImageSurface->new(
		page_number => $page_number,
		cairo_image_surface => $self->image_surfaces->[$index],
	);
}

method _build_identity_bounds() {
	my $surfaces = $self->image_surfaces;
	return [ map {
		{
			x => $surfaces->[$_]->get_height,
			y => $surfaces->[$_]->get_width,
			rotate => 0,
			pageno => $_ + 1,
			dims => {
				w => $surfaces->[$_]->get_width,
				h => $surfaces->[$_]->get_height,
			},
		}
	} 0..@$surfaces-1 ];
}

with qw(
	Renard::Incunabula::Document::Role::Pageable
	Renard::Incunabula::Document::Role::Renderable
	Renard::Incunabula::Document::Role::Boundable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Format::Cairo::ImageSurface::Document - Document made up of a collection of Cairo image surfaces

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Renard::Incunabula::Document>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Document::Role::Boundable>

=item * L<Renard::Incunabula::Document::Role::Pageable>

=item * L<Renard::Incunabula::Document::Role::Renderable>

=back

=head1 ATTRIBUTES

=head2 image_surfaces

An L<ArrayRef> of C<Cairo::ImageSurface>s which are the backing store of this
document.

=head1 METHODS

=head2 get_rendered_page

  method get_rendered_page( (PageNumber) :$page_number )

Returns a new L<Renard::Incunabula::Page::CairoImageSurface> object.

See L<Renard::Incunabula::Document::Role::Renderable/get_rendered_page> for more details.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
