use Renard::Curie::Setup;
package Renard::Curie::Model::Document::CairoImageSurface;
# ABSTRACT: Document made up of a collection of Cairo image surfaces
$Renard::Curie::Model::Document::CairoImageSurface::VERSION = '0.002';
use Renard::Curie::Model::Page::CairoImageSurface;
use Function::Parameters;
use Renard::Curie::Types qw(PageNumber InstanceOf ArrayRef);

use Moo;

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

	return Renard::Curie::Model::Page::CairoImageSurface->new(
		page_number => $page_number,
		cairo_image_surface => $self->image_surfaces->[$index],
	);
}

extends qw(Renard::Curie::Model::Document);

with qw(
	Renard::Curie::Model::Document::Role::Pageable
	Renard::Curie::Model::Document::Role::Renderable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Document::CairoImageSurface - Document made up of a collection of Cairo image surfaces

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Renard::Curie::Model::Document>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Model::Document::Role::Pageable>

=item * L<Renard::Curie::Model::Document::Role::Renderable>

=back

=head1 ATTRIBUTES

=head2 image_surfaces

An L<ArrayRef> of C<Cairo::ImageSurface>s which are the backing store of this
document.

=head1 METHODS

=head2 get_rendered_page

  method get_rendered_page( (PageNumber) :$page_number )

Returns a new L<Renard::Curie::Model::Page::CairoImageSurface> object.

See L<Renard::Curie::Model::Document::Role::Renderable/get_rendered_page> for more details.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
