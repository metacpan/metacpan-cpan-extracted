package Term::Fabulous::Widget::Sixel;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Image;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Sixel
	:isa(Term::Fabulous::Widget::Image)
	:strict(params)
{
	use Feature::Compat::Try;
	use List::Util ();    # max is a method elsewhere in the family
	use POSIX qw(ceil);

	use constant TERMINAL_NOTICE => 'Sixel needs a terminal that shows sixel graphics and reports the size of its cells.';

	# Imager::File::SIXEL is optional like Imager, which it needs: without
	# either, the widget shows a notice. Any other error than a missing
	# Imager/File/SIXEL.pm is a broken installation.
	sub _load_sixel_writer () {    ## no critic (Subroutines::RequireFinalReturn) PPI does not parse try/catch
		return 0 unless Term::Fabulous::Widget::Image::HAS_IMAGER;
		try {
			require Imager::File::SIXEL;
		}
		catch ($error) {
			die $error unless $error =~ m{\ACan't locate Imager/File/SIXEL\.pm };
			return 0;
		}
		return 1;
	}
	use constant HAS_SIXEL_WRITER => _load_sixel_writer();

	# The last picture encoded: what it was encoded for, and its SIXEL data.
	field $_encoded_for = '';
	field $_encoded;

	# ---------------------------------------------------------------------
	# What the terminal can show
	# ---------------------------------------------------------------------

	# The pixels of a cell of the terminal the widget is shown on, empty
	# outside a UI and on a terminal that shows no sixel.
	method _cell_size () {
		my $ui = $self->ui // return ();
		return () unless $ui->can('cell_target');
		my $target = $ui->cell_target;
		return () unless $target->DOES('Term::Fabulous::Render::Target::Sixel');
		return $target->sixel_cell_size;
	}

	method _notice :override () {
		return 'Sixel needs the Perl module Imager, which is not installed.' unless Term::Fabulous::Widget::Image::HAS_IMAGER;
		return 'Sixel needs the Perl module Imager::File::SIXEL, which is not installed.' unless HAS_SIXEL_WRITER;
		my @cell_size = $self->_cell_size;
		return @cell_size ? undef : TERMINAL_NOTICE;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method natural_size :override () {
		my $notice = $self->_notice;
		return $self->_notice_size($notice) if defined $notice;
		my $picture = $self->_picture // return ( 0, 0 );
		my ( $cell_width, $cell_height ) = $self->_cell_size;
		return ( ceil( $picture->getwidth / $cell_width ), ceil( $picture->getheight / $cell_height ) );
	}

	# Whether the notice shows depends on the terminal, too.
	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->_notice // '' );
	}

	# The cells stay empty below the picture, which the terminal draws
	# over them.
	method paint :override () {
		my $notice = $self->_notice;
		$self->_paint_notice($notice) if defined $notice;
		return;
	}

	method sixel_data :override (%frame) {
		return undef if defined $self->_notice || !defined $self->_picture;
		my $key = join "\x{1F}", ( map { $_ // '' } $self->paint_key ), map { "@$_" } $frame{cell_size}, $frame{shown}, @{ $frame{covered} };
		( $_encoded_for, $_encoded ) = ( $key, $self->_encoded(%frame) ) unless $key eq $_encoded_for;
		return $_encoded;
	}

	# The pixels of the shown cells: the picture placed as fit says,
	# transparent around it and in the covered cells.
	method _encoded (%frame) {
		my ( $cell_width, $cell_height ) = @{ $frame{cell_size} };
		my ( $x0,    $y0,     $x1,   $y1 )  = @{ $frame{shown} };
		my ( $width, $height, $left, $top ) = $self->_placement( $self->columns * $cell_width, $self->rows * $cell_height );

		my $shown = Imager->new( xsize => ( $x1 - $x0 ) * $cell_width, ysize => ( $y1 - $y0 ) * $cell_height, channels => 4 );
		_paste( $shown, $self->_on_background( $self->_scaled( $width, $height ) ), $left - $x0 * $cell_width, $top - $y0 * $cell_height );
		my $transparent = Imager::Color->new( 0, 0, 0, 0 );
		foreach my $covered ( @{ $frame{covered} } ) {
			my ( $cx0, $cy0, $cx1, $cy1 ) = @$covered;
			$shown->box(
				xmin   => ( $cx0 - $x0 ) * $cell_width,
				ymin   => ( $cy0 - $y0 ) * $cell_height,
				xmax   => ( $cx1 - $x0 ) * $cell_width - 1,
				ymax   => ( $cy1 - $y0 ) * $cell_height - 1,
				filled => 1,
				color  => $transparent,
			);
		}
		$shown->write( data => \my $data, type => 'sixel' ) or die ref($self) . ": cannot write the picture as sixel: " . $shown->errstr;
		return $data;
	}

	# Translucent pixels are mixed with the background below the widget,
	# like Image does, and transparent ones stay transparent: the mix is
	# copied through a mask of the pixels with any alpha. Without a
	# background, the terminal draws the pixels of at least half alpha
	# opaque and leaves out the others.
	method _on_background ($image) {
		my $background = $self->background_below( translucent => 1 ) // return $image;
		my ( $width, $height ) = ( $image->getwidth, $image->getheight );
		my $mixed = Imager->new( xsize => $width, ysize => $height, channels => 4 );
		$mixed->box( filled => 1, color => Imager::Color->new( @{$background}[ 0 .. 2 ], 255 ) );
		$mixed->compose( src => $image ) or die ref($self) . ": cannot mix the picture with the background: " . $mixed->errstr;

		my $painted = $image->convert( matrix => [ [ 0, 0, 0, 1 ] ] )->map( maps => [ [ 0, (255) x 255 ] ] );
		my $result  = Imager->new( xsize => $width, ysize => $height, channels => 4 );
		$result->compose( src => $mixed, mask => $painted ) or die ref($self) . ": cannot mix the picture with the background: " . $result->errstr;
		return $result;
	}

	# Copies $image to ($left, $top) of $target, cut at $target's edges.
	sub _paste ( $target, $image, $left, $top ) {
		my ( $from_x, $from_y ) = ( List::Util::max( 0, -$left ), List::Util::max( 0, -$top ) );
		return if $from_x >= $image->getwidth || $from_y >= $image->getheight;
		return if $left >= $target->getwidth  || $top >= $target->getheight;
		$target->paste( src => $image, left => List::Util::max( 0, $left ), top => List::Util::max( 0, $top ), src_minx => $from_x, src_miny => $from_y );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Sixel - Show a picture in sixel graphics

=head1 SYNOPSIS

	use Clay::XS qw(sizing_fixed);
	use Term::Fabulous::Widget::Sixel;

	# At its natural size: as many cells as its pixels cover.
	my $photo = Term::Fabulous::Widget::Sixel->new( file => 'examples/images/mandelbrot.png' );

	# Scaled to fit 40 columns and 12 rows, from bytes or base64 text.
	my $preview = Term::Fabulous::Widget::Sixel->new(
		data   => $png_bytes,
		fit    => 'contain',
		layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(12) } },
	);
	my $logo = Term::Fabulous::Widget::Sixel->new( base64 => $base64_text );

	# Another picture later.
	$photo->file('examples/images/other.png');

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-sixel.svg" alt="A detail of the Mandelbrot set, blue and white spirals with orange and dark red bands, in sixel graphics in three frames of 28x10 cells: cut to the frame at its natural size (none), scaled down to fit the frame with its proportions kept (contain) and stretched to fill the frame (stretch)"></p>

=end html

=head1 DESCRIPTION

The picture shows a 480x320 PNG of the Mandelbrot set in three widgets
of a fixed 28x10 cells, one per fit, in a terminal with cells of 10x20
pixels: C<none> (the default) keeps its natural size of 48x16 cells,
cut to the widget on every side, C<contain> scales it to fit and keeps
its proportions, C<stretch> fills the widget. The program is
F<examples/widgets/sixel.pl>.

A sixel widget shows a picture like L<Term::Fabulous::Widget::Image>,
but in the terminal's own pixels instead of half blocks: the terminal
draws it as a sixel image over the widget's cells. It reads the same
sources (a file, bytes, base64 text or a data URL, in whatever formats
your L<Imager> was built with), takes the same parameters and scales
the same way (see L</fit>); it is a subclass of Image.

Unless the C<layout> sizes it, the widget is as big as the picture: as
many columns and rows as its pixels cover, with the size of a cell the
terminal reports. Given another size, the picture keeps its natural
size, or is scaled as L</fit> says, and is centered in the widget.

Term::Fabulous sends a picture to the terminal when it first shows,
when it changes, moves or is resized, and when the cells below it are
drawn again; otherwise the terminal keeps it on the screen. A picture
that disappears gets its cells drawn again, which erases it.

=head2 What covers the picture

Everything the frame paints over the widget hides the picture there,
cell by cell: a dialog, a dropdown's list, a toast, another widget
floating over it. Those cells are left out of the picture (its pixels
there are transparent), so they show what is painted in them. In a
L<Term::Fabulous::Widget::ScrollBox>, the picture shows only in the
visible cells of the widget.

A picture never covers the last row of the terminal: the terminal would
scroll the screen up to place its cursor below it. The cells of the
widget in that row stay empty.

=head2 Transparency

Transparent pixels are not drawn, so the cells below them show the
background. Translucent pixels are mixed with the background below the
widget (the widget's own C<background_color> or the nearest one below
it, see L<Term::Fabulous::Widget/background_below>), like Image does.
Where there is none, on the terminal's default background, pixels with
an alpha of at least 128 are drawn opaque and the others are left out.

=head2 Without sixel

The widget needs the Perl modules L<Imager> and L<Imager::File::SIXEL>,
and a terminal that shows sixel graphics and reports the size of its
cells in pixels. Neither module is a requirement of Term::Fabulous,
only a recommendation. Without one of them, or on another terminal,
the class still loads and takes the same parameters, so programs and
layouts work unchanged, but it shows a notice in its place instead of
the picture, like Image does without Imager:

=for highlighter language=text

	Sixel needs a terminal that
	shows sixel graphics and
	reports the size of its
	cells.

The notices name the missing module instead, for example
C<Sixel needs the Perl module Imager::File::SIXEL, which is not
installed.> They are drawn in C<notice_color>, wrapped at 28 columns
unless the layout gives the widget another width.

L<Term::Fabulous::Terminal::Termbox> asks the terminal when it opens
it: the terminal shows sixel graphics when its primary device
attributes (the answer to C<ESC [ c>) list C<4>, as those of xterm
(started with C<-ti vt340>), foot, WezTerm, mlterm, Contour, Konsole,
iTerm2 and Windows Terminal do. The size of a cell comes from the
terminal's answer to C<ESC [ 16 t>, else from the pixel size of the
terminal device's window (C<TIOCGWINSZ>). A terminal that shows sixel
graphics is asked again after it is resized, since a new font size
changes the size of a cell.
L<Term::Fabulous::Static> and L<Term::Fabulous::Terminal::Memory>
(unless given C<sixel_cell_size>) show no sixel graphics.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $picture = Term::Fabulous::Widget::Sixel->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Image/new>:
C<file>, C<data>, C<base64>, C<data_url>, C<fit> and C<notice_color>,
besides those of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>. They work
the same, except:

=over

=item C<fit>

C<none> (the default) draws the picture at its natural size, cut on
every side if it is larger than the widget; C<contain> scales it to the
largest size that fits the widget's pixels, keeping its proportions;
C<stretch> scales it to fill them. The widget's pixels are its columns
and rows times the size of a cell. Enlarging repeats pixels (nearest
neighbor), shrinking mixes them.

=item C<notice_color>

The color of the notice shown without sixel. Default: the theme's
C<image.notice>, like Image.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Image>: L<file|Term::Fabulous::Widget::Image/file>,
L<data|Term::Fabulous::Widget::Image/data>, L<base64|Term::Fabulous::Widget::Image/base64>,
L<data_url|Term::Fabulous::Widget::Image/data_url>, L<fit|Term::Fabulous::Widget::Image/fit>,
L<notice_color|Term::Fabulous::Widget::Image/notice_color>,
L<image_width|Term::Fabulous::Widget::Image/image_width> and
L<image_height|Term::Fabulous::Widget::Image/image_height>, plus:

=head2 sixel_data

	my $data = $picture->sixel_data( shown => [ 0, 0, 8, 4 ], covered => [], cell_size => [ 10, 20 ] );

Called by the renderer (see L<Term::Fabulous::Widget::Canvas/sixel_data>)
once per frame: the picture's pixels in the C<shown> cells of the
widget as SIXEL data, transparent in the C<covered> ones, or C<undef>
when the widget shows a notice or has no picture. The data of the last
call is kept and returned again while nothing changes.

=head1 EVENTS

A sixel widget fires no events of its own.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Image/KDL PROPERTIES>.

=for highlighter language=kdl

	use Term::Fabulous::Widget::Sixel as Sixel

	Sixel "photo" {
		file "examples/images/mandelbrot.png"
		sizing width="fixed(32)" height="fixed(10)"
		fit "contain"
	}

=head1 SEE ALSO

L<Imager::File::SIXEL>, L<Term::Fabulous::Widget::Image>,
L<Term::Fabulous::Render::Target::Sixel>,
L<Term::Fabulous::Cookbook::Canvases/Show a photo in sixel graphics (Sixel)>.

=cut
