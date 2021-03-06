use Renard::Incunabula::Common::Setup;
package Renard::Block::Format::PDF::Page;
# ABSTRACT: Page from a PDF document
$Renard::Block::Format::PDF::Page::VERSION = '0.005';
use Moo;
use MooX::HandlesVia;
use Cairo;
use POSIX qw(ceil);

use Renard::Incunabula::Common::Types qw(Str InstanceOf HashRef);
use Renard::Incunabula::Document::Types qw(ZoomLevel PageNumber);

has document => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Block::Format::PDF::Document'],
);

has page_number => ( is => 'ro', required => 1, isa => PageNumber, );

has zoom_level => ( is => 'ro', required => 1, isa => ZoomLevel, );

has png_data => (
	is => 'lazy', # _build_png_data
	isa => Str,
);

method _build_png_data() {
	my $png_data = Renard::API::MuPDF::mutool::get_mutool_pdf_page_as_png(
		$self->document->filename, $self->page_number, $self->zoom_level
	);
}


has _size => (
	is => 'lazy',
	isa => HashRef,
	handles_via => 'Hash',
	handles => {
		width => ['get', 'width'],
		height => ['get', 'height'],
	},
);

method _build__size() {
	my $page_identity = $self->document
		->identity_bounds
		->[ $self->page_number - 1 ];

	# multiply to account for zoom-level
	my $w = ceil($page_identity->{dims}{w} * $self->zoom_level);
	my $h = ceil($page_identity->{dims}{h} * $self->zoom_level);

	{ width => $w, height => $h };
}


with qw(
	Renard::Incunabula::Page::Role::CairoRenderableFromPNG
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::Format::PDF::Page - Page from a PDF document

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Page::Role::CairoRenderable>

=item * L<Renard::Incunabula::Page::Role::CairoRenderableFromPNG>

=back

=head1 ATTRIBUTES

=head2 document

  InstanceOf['Renard::Block::Format::PDF::Document']

The document that created this page.

=head2 page_number

  PageNumber

The page number that this page represents.

=head2 zoom_level

  ZoomLevel

The zoom level for this page.

=head2 height

The height of the page at with the current parameters.

=head2 width

The width of the page at with the current parameters.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
