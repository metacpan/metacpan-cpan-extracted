use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Devel::TestHelper;
# ABSTRACT: A test helper with functions useful for various Renard distributions
$Renard::Incunabula::Devel::TestHelper::VERSION = '0.003';
use Renard::Incunabula::Common::Types qw(CodeRef InstanceOf Maybe PositiveInt DocumentModel Dir Tuple);

classmethod test_data_directory() :ReturnType(Dir) {
	require Path::Tiny;
	Path::Tiny->import();

	if( not defined $ENV{RENARD_TEST_DATA_PATH} ) {
		die "Must set environment variable RENARD_TEST_DATA_PATH to the path for the test-data repository";
	}
	return path( $ENV{RENARD_TEST_DATA_PATH} );
}

classmethod create_cairo_document( :$repeat = 1, :$width = 5000, :$height = 5000 ) {
	require Renard::Incunabula::Format::Cairo::ImageSurface::Document;
	require Cairo;

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

	my $cairo_doc = Renard::Incunabula::Format::Cairo::ImageSurface::Document->new(
		image_surfaces => \@surfaces,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Devel::TestHelper - A test helper with functions useful for various Renard distributions

=head1 VERSION

version 0.003

=head1 FUNCTIONS

=head2 test_data_directory

  Renard::Incunabula::Devel::TestHelper->test_data_directory

Returns a L<Path::Class> object that points to the path defined by
the environment variable C<RENARD_TEST_DATA_PATH>.

If the environment variable is not defined, throws an error.

=head2 create_cairo_document

  Renard::Incunabula::Devel::TestHelper->create_cairo_document

Returns a L<Renard::Incunabula::Format::Cairo::ImageSurface::Document> which can be
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
