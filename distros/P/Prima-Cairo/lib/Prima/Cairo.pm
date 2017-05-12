package Prima::Cairo;
use strict;
use Prima;
use Cairo;
use Carp qw(croak);
require Exporter;
require DynaLoader;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);

sub dl_load_flags { 0x01 };

$VERSION = '1.06';
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();

sub to_cairo_surface
{
	my ($image, $format) = @_;
	$format ||= 'rgb24';

	if ( $image->type == im::BW && $format eq 'a1') {
		# 1-bit alpha
	} elsif ( $image->type == im::Byte && $format eq 'a8') {
		# 8-bit alpha
	} elsif ( $image->isa('Prima::Icon') && $format eq 'argb32') {
		if ( $image->type != im::bpp24) {
			my ( $xor, $and ) = $image->split;
			$xor->type(im::bpp24);
			$image->combine($xor, $and);
		}
	} elsif ( $format eq 'rgb24' || $format eq 'argb32') {
		if ( $image->type != im::bpp24) {
			$image = $image->dup;
			$image->type(im::bpp24);
		}
	} else {
		croak "bad combination of $image and $format";
	}

	my $surface = Cairo::ImageSurface->create($format, $image->size);
	unless ($surface) {
		$surface = Cairo::ImageSurface->create($format, 1, 1);
		$surface->status('not enough memory');
		return $surface;
	}
	return $surface unless $surface->status eq 'success';

	if ( $format eq 'rgb24' || $format eq 'argb32') {
		my $stride = Cairo::Format::stride_for_width($format, $image->width);
		if ( $stride != $image->width * 4) {
			$surface->status('assertion about stride size failed');
			return $surface;
		}
	}
	
	Prima::Cairo::copy_image_data($image, $$surface, 1);
	$surface->mark_dirty;
	return $surface;
}

sub Prima::Image::to_cairo_surface { Prima::Cairo::to_cairo_surface($_[0], 'rgb24') }
sub Prima::Icon::to_cairo_surface { Prima::Cairo::to_cairo_surface($_[0], 'argb32') }

sub Cairo::ImageSurface::to_prima_image
{
	my ( $surface, $class ) = @_;
	my $format = $surface->get_format;
	$class ||= 'Prima::Image';

	my ( $pformat, $mformat );
	$mformat = im::bpp1;
	if ( $format eq 'argb32') {
		$pformat = im::bpp24;
		$mformat = im::bpp8;
	} elsif ( $format eq 'rgb24') {
		$pformat = im::bpp24;
	} elsif ( $format eq 'a8') {
		$pformat = im::Byte;
	} elsif ( $format eq 'a1') {
		$pformat = im::BW;
	} else {
		warn "Image surface format '$format' is not understood";
		return undef;
	}

	my $image = $class->new(
		width       => $surface->get_width,
		height      => $surface->get_height,
		type        => $pformat,
		maskType    => $mformat, 
		autoMasking => am::None,
	);
	Prima::Cairo::copy_image_data($image, $$surface, 0);
	return $image;
}

bootstrap Prima::Cairo $VERSION;

package
	Prima::Cairo::Surface;
use vars qw(@ISA);
our @ISA = qw(Cairo::Surface);

package
	Prima::Drawable;

sub cairo_context
{
	my ( $canvas, %options) = @_;
	my $surface = $options{surface} // Prima::Cairo::surface_create($canvas);
	if ( $surface && $surface->status eq 'success') {
		my $context = $options{context} // Cairo::Context->create ($surface);
		if (( $options{transform} // 'prima' ) eq 'prima' ) {
			my $matrix = Cairo::Matrix->init(
				1,	0, 
				0, -1, 
				0, $canvas->height
			);
			$context->transform($matrix);
		}
		return $context;
	} else {
		return undef;
	}
}

package 
	Prima::PS::Cairo::Context;

sub create
{
	my ( $class, $surface, $canvas ) = @_;
	return bless {
		context => Cairo::Context->create( $surface ),
		canvas  => $canvas,
	}, $class;
}

sub show_page
{
	my $self = shift;

	my $recorder = $self->{context}->get_target;
	my ($x,$y,$w,$h) = $recorder->ink_extents;
	return unless $w > 0 && $h > 0;

	my $image = Prima::Image->new(
		width    => $w,
		height   => $h,
		type     => 24,
	);
	$image->begin_paint;
	$image->clear;
	my $cr = $image->cairo_context;
	$cr->set_source_surface( $recorder, -$x, -$y );
	$cr->paint;
	$cr->show_page;

	$image->end_paint;
	$self->{canvas}->put_image($x,$self->{canvas}->height - $h - $y,$image);
}

sub AUTOLOAD {
	my $self = shift;
	my $stash_name = our $AUTOLOAD;
	$stash_name =~ s/.*:://;
	return $self->{context}->$stash_name(@_);
}

sub DESTROY {}

package
	Prima::PS::Drawable;

sub cairo_context
{
	my ( $canvas, %options) = @_;
	my $surface = Cairo::RecordingSurface->create( 'color-alpha', {
		x      => 0,
		y      => 0,
		width  => $canvas->width,
		height => $canvas->height,
	});
	return Prima::Drawable::cairo_context( $canvas, %options, 
		surface => $surface,
		context => Prima::PS::Cairo::Context->create($surface, $canvas),
	);		
}

1;

__END__

=pod

=head1 NAME

Prima::Cairo - Prima extension for Cairo drawing

=head1 DESCRIPTION

The module allows for programming Cairo library together with Prima widgets.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Cairo;
    use Prima qw(Application);
    use Prima::Cairo;
    
    my $w = Prima::MainWindow->new( onPaint => sub {
        my ( $self, $canvas ) = @_;
        $canvas->clear;

            my $cr = $canvas->cairo_context;
    
            $cr->rectangle (10, 10, 40, 40);
            $cr->set_source_rgb (0, 0, 0);
            $cr->fill;
    
            $cr->rectangle (50, 50, 40, 40);
            $cr->set_source_rgb (1, 1, 1);
            $cr->fill;
    
            $cr->show_page;
    });
    run Prima;

=head1 Prima::Drawable API

=head2 cairo_context %options

Returns the Cairo context bound to the Prima drawable - widget, bitmap etc or an undef.

Options:

=over

=item transform 'prima' || 'native'

Prima coordinate system is such that lower left pixel is (0,0), while
cairo system is that (0,0) is upper left pixel. By default C<cairo_context>
returns a context adapted for Prima, but if you want native cairo coordinate
system call it like this:

   $canvas->cairo_context( transform => 0 );

=item Cairo::ImageSurface::to_prima_image [ $class = Prima::Image ].

Returns a im::bpp24 (for color surfaces) or im::Byte/im::BW (for a8/a1 mask
surfaces) Prima::Image object with pixels copies from the image surface.
If C<$class> is 'Prima::Icon' and image surface has 'argb32' format then
fills the 1-bit alpha channel in the Prima icon object.

=item Prima::Image::to_cairo_surface

Returns a rgb24 Cairo::ImageSurface object with pixels copied from the image

=item Prima::Icon::to_cairo_surface

Returns a argb32 Cairo::ImageSurface object with pixels copied from the image and its mask


=back

=head1 Installation on Strawberry win32

Before installing the module, you need to install L<Cairo> perl wrapper.
That requires libcairo binaries, includes, and pkg-config.

In case you don't have cairo binaries and include files, grab them here:

L<http://karasik.eu.org/misc/cairo/cairo-win32.zip> .

Hack lib/pkgconfig/cairo.pc and point PKG_CONFIG_PATH to the directory where it
is located or copy it to where your system pkgconfig files are.

Strawberry 5.20 is shipped with a broken pkg-config (
L<https://rt.cpan.org/Ticket/Display.html?id=96315>,
L<https://rt.cpan.org/Ticket/Display.html?id=96317>
), you'll need to install the latest ExtUtils::PkgConfig from CPAN.

This setup is needed both for L<Cairo> and L<Prima-Cairo>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 SEE ALSO

L<Prima>, L<Cairo>

   git clone git@github.com:dk/Prima-Cairo.git

=head1 LICENSE

This software is distributed under the BSD License.

=cut
