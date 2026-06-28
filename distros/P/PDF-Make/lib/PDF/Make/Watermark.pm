package PDF::Make::Watermark;

use strict;
use warnings;
use PDF::Make;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

PDF::Make::Watermark - Watermarks and page stamps

=head1 SYNOPSIS

	use PDF::Make;
	use PDF::Make::Watermark;

	my $doc = PDF::Make::Document->new;
	$doc->add_page;

	# Text watermark
	my $wm = PDF::Make::Watermark->text(
		'CONFIDENTIAL',
		position => 'diagonal',
		opacity  => 0.3,
		size     => 72,
	);
	$doc->add_watermark($wm);

	# Image watermark
	my $logo = PDF::Make::Watermark->image(
		42,
		width    => 200,
		height   => 100,
		position => 'center',
		opacity  => 0.2,
	);
	$doc->add_watermark($logo);

	# Text stamp
	my $stamp = PDF::Make::Stamp->text(
		'Page %p of %P',
		position => 'bottom_center',
		margin   => 36,
		size     => 10,
	);
	$doc->apply_stamp($stamp);

	# Bates stamp
	my $bates = PDF::Make::Stamp->bates(
		prefix => 'DOC',
		start  => 1,
		digits => 6,
	);
	$doc->apply_stamp($bates);

=head1 DESCRIPTION

C<PDF::Make::Watermark> and C<PDF::Make::Stamp> provide watermark and
stamp objects implemented in XS/C.

This module contains no Perl-side behavior logic. Constructors,
validation, option parsing, format expansion, and rendering application
all execute in XS/C.

Supported watermark types:

=over 4

=item * text watermark

=item * image watermark

=back

Supported stamp types:

=over 4

=item * text format stamps (C<%p>, C<%P>, C<%d>, C<%t>, C<%f>, C<%%>)

=item * Bates numbering stamps

=back

=head1 CLASSES

=head2 PDF::Make::Watermark

Constructors:

=over 4

=item * C<text($text, %options)>

=item * C<image($image_obj, %options)>

=back

Common option keys include:
C<position>, C<opacity>, C<rotation>, C<scale>, C<x_offset>, C<y_offset>,
C<overlay>, C<tile_spacing_x>, C<tile_spacing_y>.

Text watermark options additionally include:
C<font>, C<size>, C<color>.

Image watermark requires:
C<width> and C<height>.

=head2 PDF::Make::Stamp

Constructors:

=over 4

=item * C<text($format, %options)>

=item * C<bates(%options)>

=back

Stamp option keys include:
C<position>, C<margin>, C<margin_x>, C<margin_y>, C<font>, C<size>,
C<color>.

For Bates stamps, additional keys include:
C<prefix>, C<start>, C<digits>, C<suffix>.

=head1 DOCUMENT METHODS

The following methods are provided by C<PDF::Make::Document>:

=over 4

=item * C<add_watermark($watermark)>

=item * C<apply_stamp($stamp)>


=back

=head1 POSITIONS

Position names accepted by constructors:

	center diagonal tile custom
	top_left top_center top_right
	bottom_left bottom_center bottom_right
	left_center right_center

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Document>, L<PDF::Make::Builder>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by LNATION

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
