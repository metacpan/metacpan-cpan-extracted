use Renard::Incunabula::Common::Setup;
package Renard::Block::Format::Cairo::Devel::TestHelper;
# ABSTRACT: A test helper with functions useful for testing Cairo documents
$Renard::Block::Format::Cairo::Devel::TestHelper::VERSION = '0.005';
use Renard::Block::Format::Cairo::ImageSurface::Document;
use Cairo;

classmethod create_cairo_document( :$repeat = 1, :$width = 5000, :$height = 5000 ) {
	my $colors = [
		(
			[ 1, 0, 0 ],
			[ 0, 1, 0 ],
			[ 0, 0, 1 ],
			[ 0, 0, 0 ],
		) x ( $repeat )
	];

	my @surfaces = map {
		my $surface = Cairo::ImageSurface->create(
			'rgb24', $width, $height
		);
		my $cr = Cairo::Context->create( $surface );

		my $rgb = $_;
		$cr->set_source_rgb( @$rgb );
		$cr->rectangle(0, 0, $width, $height);
		$cr->fill;

		$surface;
	} @$colors;

	my $cairo_doc = Renard::Block::Format::Cairo::ImageSurface::Document->new(
		image_surfaces => \@surfaces,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Block::Format::Cairo::Devel::TestHelper - A test helper with functions useful for testing Cairo documents

=head1 VERSION

version 0.005

=head1 CLASS METHODS

=head2 create_cairo_document

  Renard::Block::Format::Cairo::Devel::TestHelper->create_cairo_document

Returns a L<Renard::Block::Format::Cairo::ImageSurface::Document> which can be
used for testing.

The pages have the colors:

=over 4



=back

* red

* green

* blue

* black

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
