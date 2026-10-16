package Term::Fabulous::Widget::Image;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Image
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Feature::Compat::Try;
	use List::Util ();    # max and min are methods elsewhere in the family
	use MIME::Base64 qw(decode_base64);
	use POSIX qw(ceil);
	use Term::Fabulous::Check qw(describe one_of);
	use Term::Fabulous::Render::Attr qw(cell_color_attr);
	use Term::Fabulous::Unicode qw(string_columns);

	use constant UPPER_HALF => "\x{2580}";
	use constant LOWER_HALF => "\x{2584}";

	# What the widget shows instead of the image when Imager is missing,
	# and the columns it wraps at unless the layout gives it a width.
	use constant NOTICE       => 'Image needs the Perl module Imager, which is not installed.';
	use constant NOTICE_WIDTH => 28;

	# Imager is optional: without it the widget shows the notice. Any
	# other error than a missing Imager.pm is a broken installation.
	sub _load_imager () {    ## no critic (Subroutines::RequireFinalReturn) PPI does not parse try/catch
		try {
			require Imager;
		}
		catch ($error) {
			die $error unless $error =~ /\ACan't locate Imager\.pm /;
			return 0;
		}
		return 1;
	}
	use constant HAS_IMAGER => _load_imager();

	my @FITS    = qw(contain stretch none);
	my @SOURCES = qw(file data base64 data_url);

	field $fit :param = 'none';

	# Where the image came from: one of @SOURCES and the value given for
	# it, undef without an image.
	field $source_kind;
	field $source;

	# The decoded image as 8-bit RGBA; undef without an image or Imager.
	field $picture;

	ADJUST :params ( :$file = undef, :$data = undef, :$base64 = undef, :$data_url = undef ) {
		$fit = one_of( $self, fit => $fit, @FITS );
		my %given = ( file => $file, data => $data, base64 => $base64, data_url => $data_url );
		my @kinds = grep { defined $given{$_} } @SOURCES;
		die ref($self) . ": give at most one of file, data, base64 and data_url, got @kinds" if @kinds > 1;
		$self->_load( $kinds[0], $given{ $kinds[0] } ) if @kinds;
	}

	method theme_family :common () {
		return 'image';
	}

	method themed_params :common () {
		return ( $class->SUPER::themed_params, notice_color => [ 'notice', 'normal', 'cell_color' ] );
	}

	# ---------------------------------------------------------------------
	# Sources
	# ---------------------------------------------------------------------

	# Replaces the image with the one of a source, or removes it for undef.
	# A source that cannot be read dies and leaves the old image.
	method _load ( $kind, $value ) {
		die ref($self) . ": $kind must be a string, got " . describe($value) if ref $value;
		my $decoded = defined $value && HAS_IMAGER ? _rgba_image( $self->_decoded( $kind, $value ) ) : undef;
		( $source_kind, $source, $picture ) = defined $value ? ( $kind, $value, $decoded ) : ( undef, undef, undef );
		$self->mark_changed;
		return $value;
	}

	method _decoded ( $kind, $value ) {
		my $image = $kind eq 'file' ? Imager->new( file => $value ) : Imager->new( data => $self->_bytes_of( $kind, $value ) );
		return $image if defined $image;
		my $origin = $kind eq 'file' ? "the file '$value'" : "the $kind given";
		die ref($self) . ": cannot read an image from $origin: " . Imager->errstr;
	}

	method _bytes_of ( $kind, $value ) {
		return $self->_base64_bytes( base64 => $value ) if $kind eq 'base64';
		return $self->_data_url_bytes($value) if $kind eq 'data_url';

		my $bytes = $value;
		die ref($self) . ": data must be a byte string, got characters above 0xFF" unless utf8::downgrade( $bytes, 1 );
		return $bytes;
	}

	# Base64 in either alphabet (RFC 4648 base64 or base64url), padded or
	# not; whitespace is ignored.
	method _base64_bytes ( $name, $text ) {
		my $digits = $text =~ s/\s+//gr =~ tr{-_}{+/}r;
		my $length = length( $digits =~ s/=+\z//r );
		die ref($self) . ": $name must be base64 or base64url text" unless $digits =~ m{\A[A-Za-z0-9+/]*={0,2}\z} && $length % 4 != 1;
		return decode_base64($digits);
	}

	# data:[<media type>][;base64],<data>; the media type is not needed,
	# Imager recognizes the format by its content.
	method _data_url_bytes ($url) {
		my ( $parameters, $payload ) = $url =~ /\Adata:([^,]*),(.*)\z/s or die ref($self) . ": data_url must be a data URL ('data:image/png;base64,...')";
		return $self->_base64_bytes( data_url => $payload ) if $parameters =~ /;base64\z/i;
		return $payload =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ger;
	}

	# The image as 8-bit RGBA, whatever its type and channels.
	sub _rgba_image ($image) {
		my $rgba = $image->to_rgb8;
		$rgba = $rgba->convert( preset => 'rgb' ) if $rgba->getchannels < 3;
		$rgba = $rgba->convert( preset => 'addalpha' ) if $rgba->getchannels == 3;
		return $rgba;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _source_of ($kind) {
		return defined $source_kind && $source_kind eq $kind ? $source : undef;
	}

	method file     (@new) { return @new ? $self->_load( file     => $new[0] ) : $self->_source_of('file') }
	method data     (@new) { return @new ? $self->_load( data     => $new[0] ) : $self->_source_of('data') }
	method base64   (@new) { return @new ? $self->_load( base64   => $new[0] ) : $self->_source_of('base64') }
	method data_url (@new) { return @new ? $self->_load( data_url => $new[0] ) : $self->_source_of('data_url') }

	method fit (@new) {
		return $fit unless @new;
		$fit = one_of( $self, fit => $new[0], @FITS );
		$self->mark_changed;
		return $fit;
	}

	method notice_color (@new) { return @new ? $self->set_look( notice_color => $new[0] ) : $self->look_value('notice_color') }

	# The decoded picture as 8-bit RGBA, undef without one, for subclasses.
	method _picture () { return $picture }

	method image_width ()  { return defined $picture ? $picture->getwidth  : undef }
	method image_height () { return defined $picture ? $picture->getheight : undef }

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, map { $_ => 'scalar' } qw(file base64 data_url fit) );
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# What the widget shows instead of the image, undef when it can show it.
	method _notice () {
		return HAS_IMAGER ? undef : NOTICE;
	}

	method natural_size () {
		my $notice = $self->_notice;
		return $self->_notice_size($notice) if defined $notice;
		return ( 0,                  0 ) unless defined $picture;
		return ( $picture->getwidth, ceil( $picture->getheight / 2 ) );
	}

	# Translucent pixels are mixed with the background below the widget.
	method paint_key :override () {
		return ( $self->SUPER::paint_key, join ',', @{ $self->background_below( translucent => 1 ) // [] } );
	}

	method paint () {
		my $notice = $self->_notice;
		return $self->_paint_notice($notice) if defined $notice;
		return unless defined $picture;

		my ( $width, $height, $x0, $y0 ) = $self->_placement( $self->columns, 2 * $self->rows );
		my $shown      = $self->_scaled( $width, $height );
		my $background = $self->background_below( translucent => 1 );
		my $first      = List::Util::max( 0, $x0 );
		my $count      = List::Util::min( $self->columns, $x0 + $width ) - $first;
		foreach my $row ( 0 .. $self->rows - 1 ) {
			my ( $tops, $bottoms ) = map { _pixel_attrs( $shown, $_, $first - $x0, $count, $background ) } 2 * $row - $y0, 2 * $row + 1 - $y0;
			$self->_paint_cell( $first + $_, $row, $tops->[$_], $bottoms->[$_] ) foreach 0 .. $count - 1;
		}
		return;
	}

	# The size the image is drawn in, in pixels, and the pixel its top left
	# corner lands on, in an area of the given pixels. It is centered, so
	# with fit 'none' an image larger than the area is cut on every side.
	method _placement ( $area_width, $area_height ) {
		my ( $width, $height ) = ( $picture->getwidth, $picture->getheight );
		if ( $fit eq 'stretch' ) {
			( $width, $height ) = ( $area_width, $area_height );
		}
		elsif ( $fit eq 'contain' ) {
			my $factor = List::Util::min( $area_width / $width, $area_height / $height );
			( $width, $height ) = map { List::Util::max( 1, int( $_ * $factor + 0.5 ) ) } $width, $height;
		}
		return ( $width, $height, int( ( $area_width - $width ) / 2 ), int( ( $area_height - $height ) / 2 ) );
	}

	# Enlarging repeats pixels, which keeps pixel art crisp; shrinking
	# mixes them.
	method _scaled ( $width, $height ) {
		my ( $original_width, $original_height ) = ( $picture->getwidth, $picture->getheight );
		return $picture if $width == $original_width && $height == $original_height;
		my $enlarging = $width >= $original_width && $height >= $original_height;
		return $picture->scale( xpixels => $width, ypixels => $height, type => 'nonprop', qtype => $enlarging ? 'preview' : 'mixing' );
	}

	# The attributes of $count pixels of image row $y from column $x; none
	# for a row outside the image.
	sub _pixel_attrs ( $image, $y, $x, $count, $background ) {
		return [] if $y < 0 || $y >= $image->getheight || $count < 1;
		my @samples = $image->getsamples( y => $y, x => $x, width => $count, type => '8bit' );
		return [ map { _pixel_attr( @samples[ 4 * $_ .. 4 * $_ + 3 ], $background ) } 0 .. $count - 1 ];
	}

	# No color where the pixel is transparent, its own where it is opaque
	# or nothing is below to mix with, else the mix with the background.
	sub _pixel_attr ( $red, $green, $blue, $alpha, $background ) {
		return undef if $alpha == 0;
		my @rgb = ( $red, $green, $blue );
		@rgb = map { int( ( $rgb[$_] * $alpha + $background->[$_] * ( 255 - $alpha ) ) / 255 + 0.5 ) } 0 .. 2 if $alpha < 255 && defined $background;
		return cell_color_attr( color => ( $rgb[0] << 16 ) | ( $rgb[1] << 8 ) | $rgb[2] );
	}

	# A cell shows its upper pixel as the color of an upper half block and
	# the lower one as the background, or a lower half block alone.
	method _paint_cell ( $x, $y, $top, $bottom ) {
		return $self->put_attrs( $x, $y, UPPER_HALF, $top,    $bottom ) if defined $top;
		return $self->put_attrs( $x, $y, LOWER_HALF, $bottom, undef ) if defined $bottom;
		return;
	}

	# ---------------------------------------------------------------------
	# The notice shown instead of the image
	# ---------------------------------------------------------------------

	method _notice_size ($notice) {
		my @lines = _wrapped( $notice, NOTICE_WIDTH );
		return ( List::Util::max( map { string_columns($_) } @lines ), scalar @lines );
	}

	method _paint_notice ($notice) {
		my @lines = _wrapped( $notice, $self->columns );
		my $fg    = $self->color_attr( $self->notice_color );
		$self->paint_text( 0, $_, $lines[$_], $fg, undef ) foreach 0 .. List::Util::min( $#lines, $self->rows - 1 );
		return;
	}

	# The words of a text in lines of at most $width columns; a longer
	# word is a line of its own.
	sub _wrapped ( $text, $width ) {
		my @lines;
		foreach my $word ( split ' ', $text ) {
			if ( @lines && string_columns("$lines[-1] $word") <= $width ) {
				$lines[-1] .= " $word";
				next;
			}
			push @lines, $word;
		}
		return @lines;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Image - Show a picture in half-block pixels

=head1 SYNOPSIS

	use Clay::XS qw(sizing_fixed);
	use Term::Fabulous::Widget::Image;

	# At its natural size: a column per pixel, a row per two pixel rows.
	my $icon = Term::Fabulous::Widget::Image->new( file => 'examples/images/rainbow_circle.png' );

	# Scaled to fit 40 columns and 20 rows, from bytes or base64 text.
	my $photo = Term::Fabulous::Widget::Image->new(
		data   => $png_bytes,
		fit    => 'contain',
		layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(20) } },
	);
	my $logo = Term::Fabulous::Widget::Image->new( base64 => $base64_text );
	my $mark = Term::Fabulous::Widget::Image->new( data_url => 'data:image/png;base64,iVBORw0KGgo...' );

	# Another picture later.
	$icon->file('examples/images/other.png');

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-image.svg" alt="A 16x16 circle of rainbow-colored rings in three frames of 32x24 cells: at its natural size and centered (none), scaled up twice with its proportions kept (contain) and stretched twice wide and three times high to fill the frame (stretch); three frames of 12x4 cells below each other cut it (none), shrink it to half its size (contain) and shrink it to fill the frame (stretch)"></p>

=end html

=head1 DESCRIPTION

The picture shows a 16x16 PNG in three widgets of a fixed 32x24 cells,
one per L</fit>: C<none> (the default) keeps its natural size,
C<contain> scales it to fit and keeps its proportions, C<stretch>
fills the widget. In the three widgets of 12x4 cells, smaller than the
picture, C<none> cuts it, C<contain> shrinks it to half its size and
C<stretch> shrinks it to fill the widget. The program is F<examples/widgets/image.pl>.

An image widget reads a picture (PNG, JPEG, GIF, BMP, ... whatever
formats your L<Imager> was built with) from a file, from bytes, from
base64 text or from a data URL, and draws it the way a
L<Term::Fabulous::Widget::PixelCanvas> draws pixels: two per cell, the
upper one as the color of an upper half block (U+2580), the lower one
as its background. Unless the C<layout> sizes it, the widget is as big
as the picture: a column per pixel and a row per two rows of pixels.
Given another size, the picture keeps its natural size, or is scaled
as L</fit> says.

Transparent pixels are not drawn, so the background below the widget
shows through them. Translucent pixels are mixed with that background
(the widget's own C<background_color> or the nearest one below it, see
L<Term::Fabulous::Widget/background_below>), and drawn opaque where
there is none, on the terminal's default background.

=head2 Without Imager

Imager is not a requirement of Term::Fabulous, only a recommendation:
the widget is the only part that needs it. Without it, the class still
loads and takes the same parameters, so programs and layouts work
unchanged, but it shows a notice in its place instead of the picture:

=for highlighter language=text

	Image needs the Perl module
	Imager, which is not
	installed.

The notice is drawn in C<notice_color>, wrapped at 28 columns unless
the layout gives the widget another width. The sources given are kept
(their accessors return them) but not read, so a bad one does not die.
Install Imager (C<cpanm Imager>, with the development files of libpng,
libjpeg, ... installed first for the formats you need) to see the
pictures.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $image = Term::Fabulous::Widget::Image->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...)
and the ones below. All are optional; unknown parameters die. Give at
most one of C<file>, C<data>, C<base64> and C<data_url>; without any,
the widget shows nothing and has no natural size.

=over

=item C<file>

The path of a picture file.

=item C<data>

The bytes of a picture, as read from a file in C<:raw> mode. A string
with characters above 0xFF dies.

=item C<base64>

The bytes of a picture in base64 text, in either alphabet: standard
base64 (C<+> and C</>) or base64url (C<-> and C<_>, RFC 4648). The
C<=> padding may be left out; whitespace and line breaks are ignored.

=item C<data_url>

A data URL, C<data:[MEDIA TYPE][;base64],DATA>, such as
C<data:image/png;base64,iVBORw0KGgo...>. Its data is base64 text with
C<;base64>, percent-encoded bytes without. The media type is not
needed: Imager recognizes the format by the bytes.

=item C<fit>

How the picture fills a widget whose size is not the picture's:
C<none> (the default) draws it at its natural size, cut on every side
if it is larger; C<contain> scales it to the largest size that fits,
keeping its proportions; C<stretch> scales it to fill the widget
exactly. The picture is centered in the widget. Enlarging repeats
pixels (nearest neighbor), which keeps pixel art crisp; shrinking, on
either axis, mixes them. Anything else dies.

=item C<notice_color>

The color of the notice shown without Imager, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<image.notice>, C<[150, 160, 180, 255]> in the dark theme.

=back

A source that cannot be read dies: a missing file, bytes of no format
Imager knows (or knows but was built without), base64 text with
foreign characters or a length no base64 text has, a C<data_url> that
does not start with C<data:> or has no comma. The message names the
source and includes Imager's error.

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus:

=head2 file

	my $path = $image->file;
	$image->file('examples/images/rainbow_circle.png');

Accessor for the C<file> parameter. Writing reads the picture and
replaces the one shown, whatever its source; the reader returns
C<undef> unless the picture came from a file. Writing C<undef> removes
the picture. A source that cannot be read dies and keeps the old
picture.

=head2 data

	$image->data($png_bytes);

Accessor for the C<data> parameter; works like L</file>.

=head2 base64

	$image->base64($base64_text);

Accessor for the C<base64> parameter; works like L</file>. The reader
returns the text as given.

=head2 data_url

	$image->data_url('data:image/png;base64,iVBORw0KGgo...');

Accessor for the C<data_url> parameter; works like L</file>.

=head2 fit

	$image->fit('stretch');

Accessor for the C<fit> parameter.

=head2 notice_color

	$image->notice_color('#e5c07b');

Accessor for the C<notice_color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 image_width

	my $pixels = $image->image_width;

The width of the picture in pixels, C<undef> without a picture or
without Imager. Read-only.

=head2 image_height

	my $pixels = $image->image_height;

The height of the picture in pixels, C<undef> without a picture or
without Imager. Read-only.

Every writer marks the image changed, so the next frame paints it.

=head1 EVENTS

An image fires no events of its own.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<file>, C<base64>, C<data_url> and C<fit> (strings) and
C<notice_color> (a color string). A relative C<file> is found from the
program's working directory.

=for highlighter language=kdl

	use Term::Fabulous::Widget::Image as Image

	Image "logo" {
		file "examples/images/rainbow_circle.png"
		sizing width="fixed(32)" height="fixed(16)"
		fit "contain"
	}

=head1 SEE ALSO

L<Imager>, L<Term::Fabulous::Widget::PixelCanvas>,
L<Term::Fabulous::Widget::Display>,
L<Term::Fabulous::Cookbook::Canvases/Show a picture file (Image, fit)>,
L<Term::Fabulous::Cookbook::Canvases/Embed a logo in the program (Image, base64)>.

=cut
