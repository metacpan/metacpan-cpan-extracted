package PDF::Cairo;

=encoding utf8

=cut

# IMPORTANT! Any methods that actually put ink on the page must set
# $self->{_dirtypage}=1; this is used by the PDF::API2 compatibility
# page() method to avoid creating extra blank pages.

use 5.016;
use utf8;
use strict;
use warnings;
use Carp;
use Cairo;
use Image::CairoSVG;
use Module::Path 'module_path';
use PDF::Cairo::Util;

our $VERSION = "1.05";
$VERSION = eval $VERSION;

=head1 NAME

PDF::Cairo - simple API for creating PDF files using the Cairo library

=head1 SYNOPSIS

PDF::Cairo is loosely based on the API of L<PDF::API2::Lite>, but uses
L<Cairo>, L<Font::FreeType>, and (optionally) L<Pango> to provide
better support for modern TrueType and OpenType fonts. Compatibility
methods are provided to more easily convert existing scripts.

    use PDF::Cairo qw(cm);
    $pdf = PDF::Cairo->new(
        file => "output.pdf",
        paper => "a4",
        landscape => 1,
    );
    $font = $pdf->loadfont('Times-Bold');
    $pdf->move(cm(2), cm(4));
    $pdf->fillcolor('red');
    $pdf->setfont($font, 32);
    $pdf->print("Hamburgefontsiv");
    $image = $pdf->loadimage("logo.png");
    $pdf->showimage($image, cm(5), cm(5),
        scale => 0.5, rotate => 45);
    $pdf->write;

=head1 DESCRIPTION

L<Cairo|https://www.cairographics.org> is a cross-platform vector
graphics library that is capable of generating high-quality PDF output
(as well as PNG, PS, and SVG). Unfortunately, the L<Cairo> Perl module
is not well documented or easy to use, especially in combination with
L<Font::FreeType> and/or L<Pango>. PDF::Cairo adapts the simple and
straightforward interface of L<PDF::API2::Lite>, hiding the quirks of
the underlying C libraries. Methods that do not return an explicit
value return $self so they can be chained.

Many scripts can be ported from L<PDF::API2::Lite> just by updating
the module name; the L</LIMITATIONS> section at the end of this manual
documents a few exceptions and workarounds.

L<PDF::Cairo::Box> is a simple rectangle-manipulation library for
quickly dividing up a page, useful for making forms, graph papers,
calendars, etc.

=cut

our (
	@ISA,
	@EXPORT,
	@EXPORT_OK,
	%EXPORT_TAGS,
	%rgb,
	$HAS_IMAGEMAGICK,
);

BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw();
	@EXPORT_OK = qw(in mm cm paper_size regular_polygon);
	%EXPORT_TAGS = (all => \@EXPORT_OK);

	%rgb = ();
	#TODO: allow loading NBS/XKCD/Resene rgb.txt
	my $file = module_path('PDF::Cairo') || "PDF/Cairo/rgb.txt";
	$file =~ s/\.pm$/\/rgb.txt/;
	open(my $In, "<", $file) or
		die "$0: PDF::Cairo::rgb.txt ($file): $!\n";
	while (<$In>) {
		next if /^\s*$|^\s[#!]/;
		chomp;
		tr/A-Z/a-z/;
		my ($r,$g,$b,$name) = split(" ", $_, 4);
		$rgb{$name} = {};
		$rgb{$name}->{hex} = sprintf("#%2X%2X%2X", $r, $g, $b);
		$rgb{$name}->{dec} = [ $r, $g, $b ];
		$rgb{$name}->{float} = [ $r / 255, $g / 255, $b / 255 ];
	}
	CORE::close($In);

	# If convert is in the path, use it to support non-PNG image
	# formats in loadimage().
	my $convtmp = `convert --version 2>&1` || '';
	$HAS_IMAGEMAGICK = $convtmp =~ /ImageMagick/;
}

INIT {
	require PDF::Cairo::Font;
	require PDF::Cairo::Box;
}

=head2 Creation

=over 4

=item B<new> %options

=over 4

=item paper => $paper_size

=item file => $file

=item height => $Ypts

=item width => $Xpts

=item wide|landscape => 1

=item tall|portrait => 1

=back

Creates a new PDF document object with the first page initialized. All
arguments are optional. If called without either height/width or paper
size, it defaults to US Letter (8.5x11 inches). You must use write(),
saveas() or stringify() to output the results.

=cut

sub new {
	my $class = shift;
	die "$0: Cairo module built without PDF support!\n"
		unless Cairo::HAS_PDF_SURFACE;
	my $self = {};
	my %options = @_;
	$options{paper} ||= "usletter";
	paper_size($self, %options);
	$self->{filename} = $options{file}
		if defined $options{file};

#	if (defined $self->{filename}) {
# BUG! Under some poorly-defined circumstances, Freetype can segfault
# in FT_Set_Transform when called from Cairo on a surface created with
# this method. Need to re-test after Homebrew catches up with Cairo
# 1.17.x.
#		$self->{surface} = Cairo::PdfSurface->create(
#			$self->{filename}, $self->{w}, $self->{h}
#		);
#	}else{
		$self->{_streamdata} = '';
		if ($options{_recording}) {
			my $bbox = {
				x => 0,
				y => 0,
				width => $self->{w},
				height => $self->{h}
			};
			# unlimited recording needed for SVG support
			$self->{surface} = Cairo::RecordingSurface->create(
				"color-alpha", $options{_unlimited} ? undef : $bbox);
		}else{
			$self->{surface} = Cairo::PdfSurface->create_for_stream(
				sub {
					my ($self, $data) = @_;
					$self->{_streamdata} .= $data;
				},
				$self, $self->{w}, $self->{h},
			);
			$self->{_is_stream} = 1;
		}
#	}
	_setup_page_state($self);

	# compatibility hack!
	# PDF::API2::Lite doesn't directly support clip()/endpath(),
	# so I have scripts that call them through the reference to
	# the underlying PDF::API2 object. This is unnecessary in new
	# code. ("hybrid" was replaced with "gfx" in early 2005...)
	#
	$self->{hybrid} = $self;
	$self->{gfx} = $self;

	bless($self, $class);
}

=item B<newpage> %options

Ends the current page and creates a new one with the default graphics
state. If called without any arguments, the new page will be the same
size as the previous one.

=cut

sub newpage {
	my $self = shift;
	my %options = @_;
	$self->{context}->show_page;
	if (@_ > 0) {
		$self->paper_size(%options);
		$self->{surface}->set_size($self->{w}, $self->{h});
	}
	_setup_page_state($self);
	return $self;
}

=item B<write> [$file]

Finishes the current PDF file and writes it to $file (either passed as
an argument here or to new()). No further drawing operations can be
performed.

=cut

sub write {
	my $self = shift;
	my $filename = shift || $self->{filename};
	if (! defined $filename) {
		croak "PDF::Cairo::write(): no output file in new() or write()";
	}
	# fall through to the standard write-on-close if it's not a stream
	if ($self->{_is_stream}) {
		$self->{surface}->flush;
		$self->{surface}->finish;
		open(my $Out, '>:raw', $filename)
			or croak "PDF::Cairo::write($filename): $!";
		print $Out $self->{_streamdata};
		CORE::close($Out);
	}
}

=item B<pagebox>

Creates a PDF::Cairo::Box with width and height set to the size
of the current page in points. Does not take into account any
coordinate transformations applied to the page.

=cut

sub pagebox {
	my $self = shift;
	return PDF::Cairo::Box->new(width => $self->{w}, height => $self->{h});
}

=back

=head2 Colors

Colors can be specified by name as per X11's F<rgb.txt> file (see
L<PDF::Cairo::Colors> for a list), or by hex RGB value as #rgb,
#rrggbb, or #rrrrggggbbbb.

=over 4

=item B<fillcolor> $color

Set the current fill color.

=cut

sub fillcolor {
	my $self = shift;
	my ($color) = @_;
	$self->{_fill} = $color;
	$self->{context}->set_source_rgb(_color($color));
	return $self;
}

=item B<strokecolor> $color

Set the current stroke color.

=cut

sub strokecolor {
	my $self = shift;
	my ($color) = @_;
	$self->{_stroke} = $color;
	$self->{context}->set_source_rgb(_color($color));
	return $self;
}

=back

=head2 Graphics State Parameters

=over 4

=item B<save>

Saves the current graphics state.

=cut

sub save {
	my $self = shift;
	$self->{context}->save;
	my $state = {};
	foreach my $i (qw(_fill _stroke)) {
		$state->{$i} = $self->{$i};
	}
	push(@{$self->{stack}}, $state);
	return $self;
}

=item B<restore>

Restore the most recently saved graphics state.

=cut

sub restore {
	my $self = shift;
	$self->{context}->restore;
	my $state = pop(@{$self->{stack}});
	foreach my $i (qw(_fill _stroke)) {
		$self->{$i} = $state->{$i};
	}
	return $self;
}	

=item B<linewidth> $width

Set the current line width.

=cut

sub linewidth {
	my $self = shift;
	$self->{context}->set_line_width(@_);
	return $self;
}

=item B<linedash> [$on, $off, ...], $offset

Set the line dash style to the array reference of on-off lengths,
starting the pattern at $on-off[$offset] (default $offset 0). If
called without any arguments, a solid line will be drawn.

=cut

sub linedash {
	my $self = shift;
	my @dashes = ();
	my $offset = 0;
	if (ref $_[0] eq "ARRAY") {
		my $tmp = shift;
		@dashes = @$tmp;
		$offset = shift if @_;
	}elsif (defined $_[0] and $_[0] =~ /^-/) {
		# PDF::API2 long form
		my %options = @_;
		@dashes = @{$options{-pattern}}
			if defined $options{-pattern};
		$offset = $options{-shift}
			if defined $options{-shift};
	}else{
		# PDF::API2 short form
		@dashes = @_;
	}
	$self->{context}->set_dash($offset, @dashes);
	return $self;
}

=item B<linecap> $style

Set the line cap style to 'butt' (default), 'round', or 'square'.

=cut

sub linecap {
	my $self = shift;
	my $style = shift;
	$style = qw(butt line square)[$style]
		if $style =~ /^[012]$/;
	$self->{context}->set_line_cap($style);
	return $self;
}

=item B<linejoin> $style

Set the line join style to 'miter' (default), 'round', or 'bevel'.

=cut

sub linejoin {
	my $self = shift;
	my $style = shift;
	$style = qw(miter round bevel)[$style]
		if $style =~ /^[012]$/;
	$self->{context}->set_line_join($style);
	return $self;
}

=item B<miterlimit> $limit

Set the miter limit; if the current line join style is set to 'miter',
the miter limit is used to determine whether the lines should be
joined with a bevel instead of a miter. Cairo divides the length of
the miter by the line width. If the result is greater than the miter
limit, the style is converted to a bevel.

The default miter limit value is 10.0, which will convert joins with
interior angles less than 11 degrees to bevels instead of miters. For
reference, a miter limit of 2.0 makes the miter cutoff at 60 degrees,
and a miter limit of 1.414 makes the cutoff at 90 degrees.

A miter limit for a desired angle can be computed as: miter limit =
1/sin(angle/2)

=cut

sub miterlimit {
	my $self = shift;
	$self->{context}->set_miter_limit(@_);
	return $self;
}

=item B<tolerance> $flatness

Set the flatness tolerance (maximum distance in device pixels between
the mathematically correct path and a polygon approximation). Cairo's
default is 0.1, while PDF's is undefined and device-specific. Rarely
used, unless you know the characteristics of the device where you'll
eventually print your PDF file.

=cut

sub tolerance {
	my $self = shift;
	$self->{context}->set_tolerance(@_);
	return $self;
}

=back

=head2 Coordinate Transformations

=over 4

=item B<translate> $Xdelta, $Ydelta

Translate the origin of the coordinate system.

=cut

sub translate {
	my $self = shift;
	my ($dx, $dy) = @_;
	$self->{context}->translate($dx, -1 * $dy);
	return $self;
}

=item B<rotate> $degrees

Rotate the coordinate system counterclockwise. Use a negative
argument to rotate clockwise.

=cut

sub rotate {
	my $self = shift;
	my ($degrees) = @_;
	$self->{context}->rotate(-1 * _rad($degrees));
	return $self;
}

=item B<scale> $Xscale, [$Yscale]

Scale the coordinate system. If only one argument is passed, scale
both X and Y.

=cut

sub scale {
	my $self = shift;
	my ($sx, $sy) = @_;
	$sy = $sx unless defined $sy;
	$self->{context}->scale($sx, $sy);
	return $self;
}

=item B<skew> $sa, $sb

Skews the coordinate system by $sa degrees (counter-clockwise) from
the x axis and $sb degrees (clockwise) from the y axis.

=cut

# As per https://www.cairographics.org/cookbook/matrix_transform/,
# an X-skew is:
#   init(1,0,tan($sa_radians),1,0,0)
# a Y-skew is:
#   init(1,tan($sb_radians),0,1,0,0)
# Multiply them together, then call transform() on the results.
#
sub skew {
	my $self = shift;
	my ($sa, $sb) = @_;
	my $y_skew = Cairo::Matrix->init(
		1, -1 * sin(_rad($sa)) / cos(_rad($sa)),
		0, 1,
		0, 0,
	);
	my $x_skew = Cairo::Matrix->init(
		1, 0,
		-1 * sin(_rad($sb)) / cos(_rad($sb)), 1,
		0, 0,
	);
	$self->{context}->transform(Cairo::Matrix::multiply($y_skew, $x_skew));
	return $self;
}

=back

=head2 Path Construction

=over 4

=item B<move> $x, $y

Begin a new (sub)path at ($x, $y).

=cut

sub move {
	my $self = shift;
	my ($x, $y) = @_;
	$self->{context}->move_to($x, -1 * $y);
	return $self;
}

=item B<rel_move> $dx, $dy

Begin a new (sub)path offset from the current position by ($dx, $dy).

=cut

sub rel_move {
	my $self = shift;
	my ($dx, $dy) = @_;
	$self->{context}->rel_move_to($dx, -1 * $dy);
	return $self;
}

=item B<line> $x, $y

Adds a line to the path from the current point to ($x, $y).

=cut

sub line {
	my $self = shift;
	my ($x, $y) = @_;
	$self->{context}->line_to($x, -1 * $y);
	return $self;
}

=item B<rel_line> $dx, $dy

Adds a line to the path from the current point to a point that is
offset from the current point by ($dx,$dy).

=cut

sub rel_line {
	my $self = shift;
	my ($dx, $dy) = @_;
	$self->{context}->rel_line_to($dx, -1 * $dy);
	return $self;
}

=item B<curve> $cx1, $cy1, $cx2, $cy2, $x, $y

Extends the path in a curve from the current point to ($x, $y), using
the two specified points to create a cubic Bézier curve, and updates
the current position to be the new point.

=cut

sub curve {
	my $self = shift;
	my ($cx1, $cy1, $cx2, $cy2, $x, $y) = @_;
	$self->{context}->curve_to($cx1, -1 * $cy1, $cx2, -1 * $cy2, $x, -1 * $y);
	return $self;
}

=item B<rel_curve> $dx1,$dy1, $dx2,$dy2, $dx3,$dy3

Adds a cubic Bézier spline to the path from the current point to a
point offset from the current point by dx3 , dy3 ), using points
offset by (dx1 , dy1 ) and (dx2 , dy2 ) as the control points. After
this call the current point will be offset by (dx3 , dy3 ).

=cut

sub rel_curve {
	my $self = shift;
	my ($dx1, $dy1, $dx2, $dy2, $dx3, $dy3) = @_;
	$self->{context}->rel_curve_to($dx1, -1 * $dy1, $dx2, -1 * $dy2,
		$dx3, -1 * $dy3);
	return $self;
}

=item B<arc> $x, $y, $a, $b, $alpha, $beta, $move

Extends the path along an arc of an ellipse centered at ($x, $y). The
major and minor axes of the ellipse are $a and $b, respectively, and
the arc moves from $alpha degrees to $beta degrees, counterclockwise.
The current position is then set to the endpoint of the arc.

Set $move to a true value if this arc is the beginning of a new
path instead of the continuation of an existing path.

=cut

# Note: angles increase *clockwise* in Cairo space, but
# counter-clockwise in PDF space.
#
sub arc {
	my $self = shift;
	my ($x, $y, $a, $b, $alpha, $beta, $move) = @_;
	$self->{context}->new_sub_path if $move;
	my $tmp = $self->{context}->get_matrix;
	$self->{context}->translate($x, -1 * $y);
	$self->scale(1, $b/$a); 
	if ($alpha > $beta) {
		$self->{context}->arc(0, 0, $a, -_rad($alpha), -_rad($beta));
	}else{
		$self->{context}->arc_negative(0, 0, $a, -_rad($alpha), -_rad($beta));
	}
	$self->{context}->set_matrix($tmp);
	return $self;
}

=item B<poly> $x1,$y1, $x2,$y2, ...

Equivalent to move($x1, $y1) followed by a series of line($xn, $yn).

=cut

sub poly {
	my $self = shift;
	my ($x, $y) = splice(@_, 0, 2);
	$self->move($x, $y);
	while (@_) {
		my ($x, $y) = splice(@_, 0, 2);
		$self->line($x, $y)
			if defined $y;
	}
	return $self;
}

=item B<rel_poly> $dx1,$dy1, $dx2,$dy2, ...

Equivalent to rel_move($dx1, $dy1) followed by a series of
rel_line($dxn, $dyn).

=cut

sub rel_poly {
	my $self = shift;
	my ($x, $y) = splice(@_, 0, 2);
	$self->rel_move($x, $y);
	while (@_) {
		my ($x, $y) = splice(@_, 0, 2);
		$self->rel_line($x, $y)
			if defined $y;
	}
	return $self;
}

=item B<close>

Adds a line segment to the path from the current point to the
beginning of the current sub-path (the most recent point passed to
move()), and closes this sub-path.

=cut

sub close {
	my $self = shift;
	$self->{context}->close_path;
	return $self;
}

=back

=head2 Closed Shapes

=over 4

=item B<circle> $x, $y, $radius

Creates a circular path centered on ($x, $y) with radius $radius.

=cut

sub circle {
	my $self = shift;
	my ($x, $y, $radius) = @_;
	$self->{context}->new_sub_path;
	$self->{context}->arc($x, -1 * $y, $radius, 0, _rad(360));
	$self->{context}->close_path;
	return $self;
}

=item B<ellipse> $x, $y, $xRadius, $yRadius

Creates an elliptical path centered on ($x, $y), with major and
minor axes specified by $a and $b, respectively.

=cut

sub ellipse {
	my $self = shift;
	my ($x, $y, $a, $b) = @_;
	my $tmp = $self->{context}->get_matrix;
	$self->{context}->translate($x, -1 * $y);
	$self->scale(1, $b/$a); 
	$self->{context}->new_sub_path;
	$self->{context}->arc(0, 0, $a, 0, _rad(360));
	$self->{context}->close_path;
	$self->{context}->set_matrix($tmp);
	return $self;
}

=item B<polygon> $x, $y, $scale, $sides, %options

=over 4

=item edge => 1

=item inradius => 1

=back

Creates a regular polygon path with $sides sides centered on ($x, $y)
with circumradius length $scale. The bottom edge of the polygon is
horizontal. If either the edge or inradius option is provided, set
that length to $scale instead of the circumradius.

=cut

sub polygon {
	my $self = shift;
	my ($cx, $cy, $scale, $sides, %options) = @_;
	croak "PDF::Cairo::polygon: $sides < 3" if $sides < 3;
	croak "PDF::Cairo::polygon: $sides must be an integer"
		unless $sides == int($sides);
	my $poly = regular_polygon($sides);
	my @points = map(@$_, @{$poly->{points}});
	$self->save;
	$self->translate($cx, $cy);
	if ($options{edge}) {
		$self->scale($scale / $poly->{edge});
	}elsif ($options{inradius}) {
		$self->scale($scale / $poly->{inradius});
	}else{
		# circumradius
		$self->scale($scale);
	}
	$self->poly(@points);
	$self->close;
	$self->restore;
	return $self;
}

=item B<rect> $x, $y, $width, $height

Draws a rectangle starting at ($x, $y) with $width and $height.
Can also pass a single argument containing an array reference.

=cut

sub rect {
	my $self = shift;
	my ($x, $y, $w, $h) = @_;
	($x, $y, $w, $h) = @$x if ref $x eq 'ARRAY';
	$self->{context}->rectangle($x, -1 * $y, $w, -1 * $h);
	return $self;
}

=item B<rel_rect> $dx, $dy, $width, $height

Draws a rectangle offset from the current point by ($dx, $dy), with
$width and $height. Can also pass a single argument containing an
array reference.

=cut

sub rel_rect {
	my $self = shift;
	croak "PDF::Cairo::rel_rect: no current point"
		unless $self->{context}->has_current_point;
	my $tmp = $self->{context}->get_matrix;
	my ($x, $y) = $self->{context}->get_current_point;
	$self->translate($x, - $y);
	$self->rect(@_);
	$self->{context}->set_matrix($tmp);
	return $self;
}

=item B<roundrect> $x, $y, $width, $height, [$radius]

Draws a rectangle starting at ($x, $y) with $width and $height,
with corners rounded by $radius (defaults to 1/20th the length
of the shortest side).

=cut

sub roundrect {
	my $self = shift;
	my ($x, $y, $w, $h, $r) = @_;
	my $tmp = $w < $h ? $w : $h;
	$r ||= $tmp / 20;
	if ($r * 2 > $tmp) {
		$r = $tmp / 2;
		carp "PDF::Cairo::roundrect: Radius too large, reduced to $r";
	}
	$self->arc($x + $r, $y + $r,
		$r, $r, -90, -180, 1);
 	$self->arc($x + $r, $y + $h - $r,
		$r, $r, 180, 90);
	$self->arc($x + $w - $r, $y + $h - $r,
		$r, $r, 90, 0);
	$self->arc($x + $w - $r, $y + $r,
		$r, $r, 0, -90);
	$self->close;
	return $self;
}

=item B<rel_roundrect> $dx, $dy, $width, $height, [$radius]

Draws a rectangle offset from the current point by ($dx, $dy), with
$width and $height, with corners rounded by $radius (defaults to
1/20th the length of the shortest side).

=cut

sub rel_roundrect {
	my $self = shift;
	croak "PDF::Cairo::rel_roundrect: no current point"
		unless $self->{context}->has_current_point;
	my $tmp = $self->{context}->get_matrix;
	my ($x, $y) = $self->{context}->get_current_point;
	$self->translate($x, - $y);
	$self->roundrect(@_);
	$self->{context}->set_matrix($tmp);
	return $self;
}

=back

=head2 Path Painting

=over 4

=item B<fill> [evenodd => 1], [preserve => 1]

Fills the current path with the current fillcolor. The path is cleared
unless you pass the preserve option. If a non-zero argument is
provided, use the even-odd rule instead of the default non-zero
winding rule.

=cut

sub fill {
	my $self = shift;
	my %options = @_;
	$options{evenodd} = $_[0] if @_ == 1;
	$self->{context}->set_source_rgb(_color($self->{_fill}));
	my $current_fill = $self->{context}->get_fill_rule;
	$self->{context}->set_fill_rule('even_odd') if $options{evenodd};
	if ($options{preserve}) {
		$self->{context}->fill_preserve;
	}else{
		$self->{context}->fill;
	}
	$self->{context}->set_fill_rule($current_fill) if $options{evenodd};
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<stroke> [preserve => 1]

Strokes the current path with the current linewidth and strokecolor.
The path is cleared unless you pass the preserve option.

=cut

sub stroke {
	my $self = shift;
	my %options = @_;
	$self->{context}->set_source_rgb(_color($self->{_stroke}));
	if ($options{preserve}) {
		$self->{context}->stroke_preserve;
	}else{
		$self->{context}->stroke;
	}
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<fillstroke> [evenodd => 1]

Fills and then strokes the current path, exactly as if fill() and
stroke() were called in order without clearing the path in between. If
a non-zero argument is provided, use the even-odd rule instead of the
default non-zero winding rule.

=cut

sub fillstroke {
	my $self = shift;
	my %options = @_;
	$options{evenodd} = $_[0] if @_ == 1;
	$self->{context}->set_source_rgb(_color($self->{_fill}));
	my $current_fill = $self->{context}->get_fill_rule;
	$self->{context}->set_fill_rule('even_odd') if $options{evenodd};
	$self->{context}->fill_preserve;
	$self->{context}->set_fill_rule($current_fill) if $options{evenodd};
	$self->{context}->set_source_rgb(_color($self->{_stroke}));
	$self->{context}->stroke;
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<strokefill> [evenodd => 1]

Strokes and then fills the current path, exactly as if stroke() and
fill() were called in order without clearing the path in between. If
a non-zero argument is provided, use the even-odd rule instead of the
default non-zero winding rule.

=cut

sub strokefill {
	my $self = shift;
	my %options = @_;
	$options{evenodd} = $_[0] if @_ == 1;
	$self->{context}->set_source_rgb(_color($self->{_stroke}));
	$self->{context}->stroke_preserve;
	$self->{context}->set_source_rgb(_color($self->{_fill}));
	my $current_fill = $self->{context}->get_fill_rule;
	$self->{context}->set_fill_rule('even_odd') if $options{evenodd};
	$self->{context}->fill;
	$self->{context}->set_fill_rule($current_fill) if $options{evenodd};
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<clip> [evenodd => 1], [preserve => 1]

Intersects the current path with the current clipping path. The path
is cleared unless you pass the preserve option. If the evenodd
argument is passed, use the even-odd rule instead of the default
non-zero winding rule.

Note that this differs from PDF::API2, where you must call endpath()
to clear the path after clip().

=cut

sub clip {
	my $self = shift;
	my %options = @_;
	$options{evenodd} = $_[0] if @_ == 1;
	my $current_fill = $self->{context}->get_fill_rule;
	$self->{context}->set_fill_rule('even_odd') if $options{evenodd};
	if ($options{preserve}) {
		$self->{context}->clip_preserve;
	}else{
		$self->{context}->clip;
	}
	$self->{context}->set_fill_rule($current_fill) if $options{evenodd};
	$self->{_dirtypage} = 1;
	return $self;
}

=back

=head2 Text

=over 4

=item B<loadfont> $font, [$index|$metrics]

Load $font from disk with FreeType, returning a PDF::Cairo::Font
object. If the file is not found in the current directory, the font
path will be searched. If $font doesn't look like a file name, it will
be matched against the PDF::API2 'core' and 'cjk' font names, and
Fontconfig will be used to find something compatible.

For multi-font container formats (TTC, OTC, DFONT), $index can be
supplied to select one of the other fonts; for PostScript PFB fonts,
the location of an AFM metrics file can be supplied, or it will search
the font path to find one with a matching name (case-insensitive).

=cut

sub loadfont {
	my $self = shift;
	my $face = join(",", @_);
	return PDF::Cairo::Font->new($self, $face);
}

=item B<setfont> $fontref, [$size]

Set the current font and size. Default size is 1 point.

=cut

sub setfont {
	my $self = shift;
	my ($font, $size) = @_;
	$size ||= 1;
	$self->{context}->set_font_face($font->{face})
		if ref $font and $font->{face} ne $self->{context}->get_font_face;
	$self->{context}->set_font_size($size);
	return $self;
}

=item B<setfontsize> $size

Set the size of the current font.

=cut

sub setfontsize {
	my $self = shift;
	my $size = shift;
	$self->{context}->set_font_size($size);
	return $self;
}

=item B<print> $text, %options

=over 4

=item align => 'left|right|center'

=item valign => 'baseline|top|center'

=item shift => $vertical_shift

=item center => 1

=back

Display text at current position, with current font and fillcolor. If
the first argument is a font reference, the PDF::API2::Lite
compatibility version of print() will be used instead.

The current position will be moved to the end of the displayed text.
Any vertical shift will not affect the baseline of subsequent calls
to print().

=cut

sub print {
	my $self = shift;
	if (ref $_[0]) {
		$self->_api2_print(@_);
	}else{
		my ($text, %options) = @_;
		my $extents = $self->extents($text);
		my $width = $extents->width;
		my $height = $extents->height;
		my ($dx, $dy) = (0, 0);
		$options{align} ||= "left";
		if ($options{center}) {
			$options{align} = 'center';
			$options{valign} = 'center';
		}
		if ($options{align} eq "center") {
			$dx -= $width / 2 + $extents->x;
		}elsif ($options{align} eq "right") {
			$dx -= $width;
		}
		# TODO: add "bottom", distinct from default baseline
		$options{valign} ||= "baseline";
		if ($options{valign} eq "center") {
			$dy += $height / 2 + $extents->y;
		}elsif ($options{valign} eq "top") {
			$dy += $height;
		}
		if ($dx or $dy) {
			my ($x, $y) = $self->{context}->get_current_point;
			$self->{context}->move_to($x + $dx, $y + $dy);
		}
		$self->{context}->set_source_rgb(_color($self->{_fill}));
		$self->rel_move(0, $options{shift})
			if $options{shift};
		$self->{context}->show_text($text);
		$self->rel_move(0, -$options{shift})
			if $options{shift};
		# note this leaves the current point offset by the alignment
		# which means calling print() again without moving first
		# will match the baseline. I think this is a feature.
	}
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<autosize> $text, $box

Set the size of the current font to the largest value that allows
$text to fit inside of the specified PDF::Cairo::Box object.

=cut

sub autosize {
	my $self = shift;
	my ($text, $box) = @_;
	croak "PDF::Cairo::autosize: requires a PDF::Cairo::Box object"
		unless ref $box eq 'PDF::Cairo::Box';
	$self->setfontsize($box->height);
	my $extents = $self->extents($text);
	$self->setfontsize($box->height * $box->width / $extents->width)
		if $extents->width > $box->width;
	return $self;
}

=item B<extents> $text

Returns a L<PDF::Cairo::Box> object containing the ink extents
of $text as it would be rendered with the current font/size.

=cut

sub extents {
	my $self = shift;
	my $text = shift;
	croak "PDF::Cairo::extents: requires text string as argument"
		unless defined $text;
	my $extents = $self->{context}->text_extents($text);
	my $box = PDF::Cairo::Box->new(
		width => $extents->{width},
		height => $extents->{height},
		x => $extents->{x_bearing},
		y => -($extents->{y_bearing} + $extents->{height}),
	);
	return $box;
}

=item B<textpath> $text

Add the outlines of the glyphs in $text to the current path, using
the current font and size.

=cut

sub textpath {
	my $self = shift;
	my $text = shift;
	$self->{context}->text_path($text);
	return $self;
}

=back

=head2 Raster Images

=over 4

=item B<loadimage> $file

Load a PNG-format image from $file. Returns a Cairo image surface that
can be placed any number of times with showimage(); height() and
width() methods are available to determine appropriate scaling values.

If L<ImageMagick|https://imagemagick.org/>'s F<convert> command is
available, it will be used to convert other image formats into PNG.

=cut

sub loadimage {
	my $self = shift;
	my $file = shift;
	if ($HAS_IMAGEMAGICK) {
		my $fh;
		my @convert = qw(convert -density 72);
		if (!open($fh, '-|:raw', @convert, $file, 'png:-')) {
			croak "loadimage($file): $!\n";
		}
		my $result = Cairo::ImageSurface->create_from_png_stream(
			sub {
				my ($fh, $length) = @_;
				my $buffer;
				read($fh, $buffer, $length);
				return $buffer;
			}, $fh,
		);
		CORE::close($fh);
		return $result;
	}else{
		my $result = Cairo::ImageSurface->create_from_png($file);
		croak "loadimage($file) failed (not a PNG and convert not available?)"
			unless $result->status eq 'success';
		return $result;
	}
}

=item B<showimage> $image, $x, $y, %options

=over 4

=item align => 'left|center|right'

=item valign => 'top|center|bottom'

=item center => 1

=item scale => $scale

=item size => [ $width, $height ]

=item x_scale => $scale

=item y_scale => $scale

=item rotate => $degrees

=back

Display $image with its lower-left corner at ($x, $y), scaled at 100%
in the current user coordinate unless one of the scaling options is
supplied.

=cut

sub showimage {
	my $self = shift;
	my $image_surface = shift;
	my $x = shift;
	my $y = shift;
	my %options = @_;
	my ($x_scale, $y_scale) = (1, 1);
	if ($options{scale}) {
		$x_scale = $options{scale};
		$y_scale = $options{scale};
	}
	if ($options{x_scale}) {
		$x_scale = $options{x_scale};
	}
	if ($options{y_scale}) {
		$y_scale = $options{y_scale};
	}
	if ($options{size}) {
		my ($w, $h) = @{$options{size}};
		$x_scale = $w / $image_surface->get_width;
		$y_scale = $h / $image_surface->get_height;
	}
	my $height = $image_surface->get_height * $y_scale;
	my $width = $image_surface->get_width * $x_scale;
	$self->save;
	$self->translate($x, $y + $height);

	if (defined $options{rotate}) {
		# calculate the rotated position of lower-left corner and
		# translate the origin so that the rotation comes from there.
		my $a = -1 * _rad($options{rotate});
		$self->translate($height * sin($a), $height * (cos($a) - 1));
		$self->rotate($options{rotate});
	}

	# align image to other than bottom-left
	# this must happen after rotation but before scaling
	my ($tx, $ty) = (0, 0);
	if ($options{center}) {
		$options{align} = "center";
		$options{valign} = "center";
	}
	$options{align} ||= "left";
	if ($options{align} eq "center") {
		$tx = - $width / 2;
	}elsif ($options{align} eq "right") {
		$tx = - $width;
	}
	$options{valign} ||= "bottom";
	if ($options{valign} eq "center") {
		$ty = $height / 2;
	}elsif ($options{valign} eq "top") {
		$ty = $height;
	}
	if ($tx or $ty) {
		my ($x, $y) = $self->{context}->get_current_point;
		$self->{context}->translate($tx, $ty);
	}

	if ($x_scale != 1 or $y_scale != 1) {
		$self->scale($x_scale, $y_scale);
	}
	$self->{context}->set_source_surface($image_surface, 0, 0);
	$self->{context}->paint;
	$self->restore;
	return $self;
}

=back

=head2 Advanced and Experimental

=over 4

=item B<loadsvg> $file|$string

Create an object with recording() containing an SVG image rendered
with L<Image::CairoSVG>, with the lower-left corner at (0,0). It can
be rendered with place() as many times as you want. height() and
width() methods are available to determine appropriate scaling values.

Note that Image::CairoSVG only supports path operators, and ignores
filters, fonts, and text, so many complex SVG files will not render
as expected.

=cut

# renders the SVG *twice*; first to find its bounding box, then
# with the origin translated vertically so it matches the PDF
# coordinate system.
#
sub loadsvg {
	my $class = shift;
	my $svg = shift;
	my $rectmp = PDF::Cairo->recording(_unlimited => 1);
	my $image = Image::CairoSVG->new (context => $rectmp->{context});
	$image->render($svg);
	my @ink = $rectmp->{surface}->ink_extents;

	my $recording = PDF::Cairo->recording(width => $ink[2], height => $ink[3]);
	$recording->translate(0, $ink[3]);
	$image = Image::CairoSVG->new (context => $recording->{context});
	$image->render($svg);
	$recording->{surface}->flush;
	return $recording;
}

=item B<path> ['move|line|curve|close', [$x, $y, ...], ...]

Appends an array of move/line/curve/close operations to the current
path. This is done with Cairo's append_path() method, so it's more
efficient than calling each method one-by-one.

If no arguments are passed, returns the current path in this
format, and then clears the path.

=cut

sub path {
	my $self = shift;
	if (@_) {
		$self->_appendpath(@_);
	}else{
		$self->_getpath;
	}
}

sub _appendpath {
	my $self = shift;
	my @path;
	while (@_) {
		my $op = shift;
		my $val = shift;
		if ($op eq 'move') {
			my ($x, $y) = @$val;
			push(@path, { type => 'move-to', points => [ [$x, -$y] ] });
		}elsif ($op eq 'line') {
			my ($x, $y) = @$val;
			push(@path, { type => 'line-to', points => [ [$x, -$y] ] });
		}elsif ($op eq 'curve') {
			my ($cx1, $cy1, $cx2, $cy2, $x, $y) = @$val;
			push(@path, { type => 'curve-to', points => [
				[$cx1, -$cy1],
				[$cx2, -$cy2],
				[$x, -$y],
			]});
		}elsif ($op eq 'close') {
			push(@path, { type => 'close-path', points => [] });
		}else{
			croak "PDF::Cairo::_appendpath: unknown operator '$op'";
		}
	}
	$self->{context}->append_path(\@path);
	return $self;
}

sub _getpath {
	my $self = shift;
	my @path;
	foreach my $op (@{$self->{context}->copy_path}) {
		my $key = $op->{type};
		my $val = $op->{points};
		$key =~ s/-.*$//;
		my @points;
		foreach my $pt (@$val) {
			my ($x, $y) = @$pt;
			push(@points, $x, - $y);
		}
		push(@path, $key, \@points);
	}
	$self->{context}->new_path;
	return @path;
}

=item B<place> $recording, $x,$y, %options

=over 4

=item clip => [ $width, $height]

=item dx => $offset_x

=item dy => $offset_y

=item align => 'left|center|right'

=item valign => 'top|center|bottom'

=item center => 1

=item scale => $scale

=item size => [ $width, $height ]

=item x_scale => $scale

=item y_scale => $scale

=item rotate => $degrees

=back

Places the recording object $recording with its lower-left corner at
($x,$y). If the clip argument is provided, the recording is clipped
to that width/height before rendering. If $dx or $dy is provided, the
recording will be offset by those amounts before rendering. This can
be used to do things like tile a large image across multiple pages.

=cut

sub place {
	my $self = shift;
	croak "PDF::Cairo::place: first argument must be a recording/svg/image"
		unless defined $_[0];
	# pass raster images to showimage
	return $self->showimage(@_)
		if ref $_[0] eq 'Cairo::ImageSurface';
	my $recording = shift;
	croak "PDF:Cairo::place: first argument must be a recording object"
		unless ref $recording->{surface} eq 'Cairo::RecordingSurface';
	my $width = $recording->{w};
	my $height = $recording->{h};
	my $x = shift || 0;
	my $y = shift || 0;
	my %options = @_;

	my $dx = defined $options{dx} ? $options{dx} : 0;
	my $dy = defined $options{dy} ? $options{dy} : 0;
	my ($x_scale, $y_scale) = (1, 1);
	if ($options{scale}) {
		$x_scale = $options{scale};
		$y_scale = $options{scale};
	}
	if ($options{x_scale}) {
		$x_scale = $options{x_scale};
	}
	if ($options{y_scale}) {
		$y_scale = $options{y_scale};
	}
	if ($options{size}) {
		my ($w, $h) = @{$options{size}};
		$x_scale = $w / $width;
		$y_scale = $h / $height;
	}
	$self->save;
	$self->translate($x, $y) if $x or $y;
	if (defined $options{rotate}) {
		$self->rotate($options{rotate});
	}

	# align image to other than bottom-left
	# this must happen after rotation but before scaling
	my ($tx, $ty) = (0, 0);
	if ($options{center}) {
		$options{align} = "center";
		$options{valign} = "center";
	}
	$options{align} ||= "left";
	if ($options{align} eq "center") {
		$tx = - $width * $x_scale / 2;
	}elsif ($options{align} eq "right") {
		$tx = - $width * $x_scale;
	}
	$options{valign} ||= "bottom";
	if ($options{valign} eq "center") {
		$ty = $height * $y_scale / 2;
	}elsif ($options{valign} eq "top") {
		$ty = $height * $y_scale;
	}
	if ($tx or $ty) {
		my ($x, $y) = $self->{context}->get_current_point;
		$self->{context}->translate($tx, $ty);
	}

	if ($x_scale != 1 or $y_scale != 1) {
		$self->scale($x_scale, $y_scale);
	}
	if (defined $options{clip}) {
		$self->rect(0, 0, @{$options{clip}});
		$self->clip;
	}
	$recording->{surface}->flush;
	$self->{context}->set_source_surface($recording->{surface},
		-$dx, -$recording->{h} + $dy);
	$self->{context}->paint;
	$self->restore;
	return $self;
}

=item B<recording> %options

=over 4

=item paper => $paper_size

=item height => $Ypts

=item width => $Xpts

=item wide|landscape => 1

=item tall|portrait => 1

=back

Creates a new PDF::Cairo recording object. You can draw on it
normally, but can only access the results with place(). Options are
the same as new(). height() and width() methods are available to
determine appropriate scaling values. Recording surfaces are clipped
to their size.

=cut

# Create a recording surface.
# 
sub recording {
	my $class = shift;
	my %options = @_;
	return PDF::Cairo->new(_recording => 1, %options);
}

#only really useful for recording/svg surfaces, so otherwise not documented
#
sub height {
	my $self = shift;
	return $self->{h};
}
sub width {
	my $self = shift;
	return $self->{w};
}

=back

=head2 Utility Functions

These are imported from L<PDF::Cairo::Util> so you don't have to
explicitly use that module in every script.

=over 4

=item B<cm> $centimeters

Converts the arguments from centimeters to points. Importable.

=cut

sub cm {
	return PDF::Cairo::Util::cm(@_);
}

=item B<in> $inches

Converts the arguments from inches to points. Importable.

=cut

sub in {
	return PDF::Cairo::Util::in(@_);
}

=item B<mm> $millimeters

Converts the arguments from millimeters to points. Importable.

=cut

sub mm {
	return PDF::Cairo::Util::mm(@_);
}

=item B<paper_size> %options

=over 4

=item paper => $paper_size

=item wide|landscape => 1

=item tall|portrait => 1

=back

Return size in points of a paper type. The default is "US Letter"
(8.5x11 inches). The wide/tall options can be used to ensure that the
orientation of the page is as expected. Importable.

The supported paper sizes are listed in L<PDF::Cairo::Papers>.

=cut

# can either be called as a method or a function;
# returns ($width, $height) in points
#
sub paper_size {
	return PDF::Cairo::Util::paper_size(@_);
}

=item B<regular_polygon> $sides

Calculate the vertices of a regular polygon with $sides sides with
radius 1, along with the relative lengths of the inradius and edge.

Returns a hashref:

    {
      points => [ [$x0, $y0], ... ],
      edge => $edge_length,
      inradius => $inradius_length,
      radius => 1,
    }

Calling the polygon($cx, $cy, $radius, $sides) method is equivalent to:

    $poly = regular_polygon($sides);
    @points = map(@$_, @{$poly->{points}});
    $pdf->save;
    $pdf->translate($cx, $cy);
    $pdf->scale($radius);
    $pdf->poly(@points);
    $pdf->close;
    $pdf->restore;

=cut

sub regular_polygon {
	return PDF::Cairo::Util::regular_polygon(@_);
}

=back

=head2 PDF::API2 Compatibility

=over 4

=item B<addFontDirs> $directory, ...

Append one or more directories to the font search path. Returns
the current font path.

=cut

sub addFontDirs {
	shift if ref $_[0]; # not a method call, but allow the error
	PDF::Cairo::Font::append_font_path(@_);
	return PDF::Cairo::Font::get_font_path();
}

=item B<clip> $use_even_odd

Additional way to specify even-odd fill rule for clip().

=item B<cjkfont> $font

Load something vaguely appropriate for the requested PDF::API2
CJK font name. See PDF::Cairo::Font for recommended alternatives.

=cut

sub cjkfont {
	loadfont(@_);
}

=item B<corefont> $fontname

Load the closest match to a PDF::API2 core font, as described in
PDF::Cairo::Font.

=cut

sub corefont {
	loadfont(@_);
}

=item B<endpath>

Ends current (sub)path without close(). Generally only used after
clip(), so it's effectively a no-op in PDF::Cairo.

=cut

sub endpath {
	my $self = shift;
	$self->{context}->new_path;
	return $self;
}

=item B<fill> $use_even_odd

Additional way to specify even-odd fill rule for fill().

=item B<fillstroke> $use_even_odd

Additional way to specify even-odd fill rule for fillstroke().

=item B<image> $image, $x, $y, ($width, $height) | [$scale]

Wrapper for showimage().

=cut

sub image {
	my $self = shift;
	my $image_surface = shift;
	my $x = shift;
	my $y = shift;
	if (defined $_[1]) {
		$self->showimage($image_surface, $x, $y, size => [ @_ ]);
	}elsif (defined $_[0]) {
		$self->showimage($image_surface, $x, $y, scale => $_[0]);
	}else{
		$self->showimage($image_surface, $x, $y)
	}
	return $self;
}

=item B<image_gif> $file

Alias for loadimage(); requires ImageMagick F<convert> program.

=cut

sub image_gif {
	loadimage(@_);
}

=item B<image_jpg> $file

Alias for loadimage(); requires ImageMagick F<convert> program.

=cut

sub image_jpg {
	loadimage(@_);
}

=item B<image_png> $file

Alias for loadimage().

=cut

sub image_png {
	loadimage(@_);
}

=item B<image_pnm> $file

Alias for loadimage(); requires ImageMagick F<convert> program.

=cut

sub image_pnm {
	loadimage(@_);
}

=item B<image_tiff> $file

Alias for loadimage(); requires ImageMagick F<convert> program.

=cut

sub image_tiff {
	loadimage(@_);
}

=item B<linedash> $length

=item B<linedash> $dash1, $gap1, ...

=item B<linedash> -pattern => [$dash1, $gap1, ...], -shift => $offset

Additional ways to pass arguments to linedash().

=item B<page> [$width, $height]

Emulates the behavior of PDF::API2::Lite's page() method, which starts
a new page, defaulting to the size of the previous page if there was
one. Note that this does not accept the four-argument form with the
coordinates of the lower-left and upper-right corners.

=cut

sub page {
	my $self = shift;
	my ($w, $h) = @_;
	if ($self->{_dirtypage}) {
		$self->newpage(width => $w, height => $h);
	}else{
		$self->paper_size(width => $w, height => $h);
		$self->{surface}->set_size($self->{w}, $self->{h});
		_setup_page_state($self);
	}
	return $self;
}

=item B<print> $font, $size, $x, $y, $rotation, $justification, @text

Sadly necessary, since I use it all the time with PDF::API2::Lite.

=cut

sub _api2_print {
	my $self = shift;
	my ($font, $size, $x, $y, $rotation, $justification, @text) = @_;
	croak "PDF::Cairo::print: requires text argument"
		unless defined $text[0];
	my $text = join(' ', @text);
	$self->{context}->set_font_face($font->{face});
	$self->{context}->set_font_size($size);
	my $extents = $self->{context}->text_extents($text);
	my $width = $extents->{width};
	my $x_bearing = $extents->{x_bearing};
	if ($justification == 1) {
		$x -= $width / 2 + $x_bearing;
	}elsif ($justification == 2) {
		$x -= $width;
	}
	$self->move($x, $y);
	my $tmp = $self->{context}->get_matrix;
	$self->rotate($rotation);
	$self->{context}->set_source_rgb(_color($self->{_fill}));
	$self->{context}->show_text($text);
	$self->{context}->set_matrix($tmp);
	$self->{_dirtypage} = 1;
	return $self;
}

=item B<psfont> $font

Load a Type 1 font from disk using FreeType. If a matching
AFM file is found in the font path, it will also be loaded.

=cut

sub psfont {
	loadfont(@_);
}

=item B<rectxy> $x1, $x1, $x2, $y2

Draw a rectangle with opposite corners at ($x1, $y1) and ($x2, $y2).

=cut

sub rectxy {
	my $self = shift;
	my ($x1, $y1, $x2, $y2) = @_;
	$self->rect($x1, $y1, $x2-$x1, $y2-$y1);
	return $self;
}

=item B<restorestate>

Alias for restore().

=cut

sub restorestate {
	restore(@_);
}

=item B<saveas> $file

Finishes the current PDF file and saves it to $file. No further
drawing operations can be performed.

=cut

sub saveas {
	my $self = shift;
	my $filename = shift;
	if ($self->{_is_stream}) {
		$self->{surface}->flush;
		$self->{surface}->finish;
		open(my $Out, '>:raw', $filename)
			or die "$0: PDF::Cairo::saveas($filename): $!\n";
		print $Out $self->{_streamdata};
		CORE::close($Out);
	}else{
		croak "saveas() only works if you didn't set a filename in new()\n";
	}
}

=item B<savestate>

Alias for save().

=cut

sub savestate {
	save(@_);
}

=item B<stringify>

Finishes the current PDF file and returns it as a scalar. No further
drawing operations can be performed.

=cut

sub stringify {
	my $self = shift;
	if ($self->{_is_stream}) {
		$self->{surface}->flush;
		$self->{surface}->finish;
		return $self->{_streamdata};
	}else{
		croak "stringify() only works if you didn't set a filename in new()\n";
	}
}

=item B<transform> %options

=over 4

=item -translate => [$x, $y]

=item -rotate => $degrees

=item -scale => [$sx, $sy]

=item -skew => [$sa, $sb]

=back

Perform multiple coordinate transforms at once, in PDF-canonical
order.

=cut

# always thought it was odd that PDF::API2::Lite didn't have the
# individual transformations, even though PDF::API2::Content does.
#
sub transform {
	my $self = shift;
	my %options = @_;
	$self->translate(@{$options{-translate}})
		if $options{-translate};
	$self->rotate(@{$options{-rotate}})
		if $options{-rotate};
	$self->scale(@{$options{-scale}})
		if $options{-scale};
	$self->skew(@{$options{-skew}})
		if $options{-skew};
	return $self;
}

=item B<ttfont> $font

Load a TrueType/OpenType font from disk using FreeType.

=cut

sub ttfont {
	loadfont(@_);
}

=back

=head2 PDF::API2::Lite Text Compatibility

These methods should not be used in new code, and are present solely
to simplify converting existing scripts that use L<PDF::API2::Lite>.
Use L<PDF::Cairo::Layout> instead. Honestly, in over 15 years of using
PDF::API2::Lite, I never once used these methods.

Note that this is the I<Lite> version, which exposes only a subset
of the functionality in L<PDF::API2::Content>.

=over 4

=item B<textstart>

Starts a block of text with the baseline set to (0, 0). You must
translate the origin to get the text to appear anywhere else.

=cut

sub textstart {
	my $self = shift;
	$self->{_api2text} = {
		lead => 0,
		lines => 0,
		first => 1,
	};
	return $self;
}

=item B<textfont> $font, $size

Set the current font to $font at $size.

=cut

sub textfont {
	my $self = shift;
	croak("PDF::Cairo::textfont: Must use textstart() first")
		unless defined $self->{_api2text};
	my ($font, $size) = @_;
	croak("PDF::Cairo::textfont(font_ref, font_size)")
		unless $size > 0;
	$self->setfont($font, $size);
	return $self;
}

=item B<textlead> $leading

Set the spacing between lines to $leading (default is 0, which
prints all lines on top of each other).

=cut

sub textlead {
	my $self = shift;
	$self->{_api2text}->{lead} = shift;
	return $self;
}

=item B<text> $string

Display text at current position, with the current font and fillcolor.
The current position will be moved to the end of the displayed text.

=cut

sub text {
	my $self = shift;
	if ($self->{_api2text}->{first} == 1) {
		$self->{_api2text}->{first} = 0;
		$self->move(0, 0);
	}
	$self->print(shift);
	return $self;
}

=item B<nl>

Move to the beginning of the next line of text (0, -$leading * ($lines - 1)).

=cut

sub nl {
	my $self = shift;
	my $api2 = $self->{_api2text};
	$api2->{line}++;
	$self->move(0, -1 * $api2->{line} * $api2->{lead});
	return $self;
}

=item B<textend>

End the current text block.

=cut

sub textend {
	my $self = shift;
	$self->{_api2text} = undef;
	return $self;
}

=back

=cut

# internal functions

# convert color names and hex numbers to floating-point RGB
#
sub _color {
	my ($color) = @_;
	my ($r, $g, $b);
	if ($color =~ /^#/) {
		my $l = int((length($color) - 1) / 3);
		($r, $g, $b) = map(hex($_)/(16**$l - 1),
			$color =~ /^#(.{$l})(.{$l})(.{$l})$/);
	}elsif ($color =~ /^[0-9.]+$/) {
		($r, $g, $b) = ($color, $color, $color);
	}else{
		$color =~ tr/A-Z/a-z/;
		$color =~ tr/ //d;
		($r, $g, $b) = @{$rgb{$color}->{float}};
	}
	return ($r, $g, $b);
}

sub _rad {
	return $_[0] * 0.01745329252;
}

sub _setup_page_state {
	my ($self) = @_;
	$self->{context} = Cairo::Context->create($self->{surface})
		unless defined $self->{context};
	# show_page() doesn't reset a lot of things...
	$self->{context}->new_path;
	$self->{context}->set_source_rgb(0, 0, 0);
	$self->{context}->set_line_width(1);
	$self->{context}->identity_matrix;
	$self->{context}->reset_clip;
	$self->{context}->set_dash(0);
	$self->{context}->set_fill_rule('winding');
	$self->{context}->translate(0, $self->{h});

	# save/restore stack to track separate fill/stroke colors
	# (Cairo has only one active color).
	$self->{stack} = [];
	$self->{_fill} = "black";
	$self->{_stroke} = "black";

	# keep compatibility methods from creating extra blank pages
	$self->{_dirtypage} = 0;
}

=head1 LIMITATIONS

=over 4

=item * libcairo version must be 1.10.0 or greater to support
recording surfaces, which this module makes extensive use of. Future
versions will require 1.16.0 or greater to support metadata, outlines,
hyperlinks, page labels, etc.

=item * The fillcolor/strokecolor methods do not currently support the
various %cmyk, &hsl, !hsv options for setting color values. (TODO)

=item * All images are converted to PNG before embedding in the
output. This is a limitation of the Cairo library.

=item * Vector images placed with loadimage() are rasterized with
ImageMagick's C<convert> command.

=item * Cairo only supports one active color at a time, not separate
stroke and fill colors. I maintain a separate save/restore stack to
work around this, and hopefully I haven't missed any edge cases.

=item * No built-in support for the standard PDF fonts. All fonts will
be embedded in the output, and unless you load a specific font file
from disk, what you get when you specify a font name like
"Helvetica-Bold" will depend on your computer's L<Fontconfig>
settings.

=item * On a Mac, Fontconfig will only search a short list of well-known
directories, which does not include the locations used by font managers
like Typekit and FontExplorer Pro.

=back

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=head1 SEE ALSO

L<PDF::API2>, L<PDF::Builder>, L<Cairo>, L<Font::FreeType>, L<Pango>,
L<Fontconfig|http://fontconfig.org>, L<ImageMagick|https://imagemagick.org/>

Pages 187-192 of 
L<Adobe PPD Specifications|http://partners.adobe.com/asn/developer/pdfs/tn/5003.PPD_Spec_v4.3.pdf>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pdf-cairo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDF-Cairo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PDF::Cairo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=PDF-Cairo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PDF-Cairo>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/PDF-Cairo>

=item * Search CPAN

L<https://metacpan.org/release/PDF-Cairo>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by J Greely.

This is free software, licensed under:

  MIT License

=cut

# quick hack to add width/height methods to images and recordings
#
sub Cairo::ImageSurface::height {
	my $self = shift;
	$self->get_height;
}
sub Cairo::ImageSurface::width {
	my $self = shift;
	$self->get_width;
}

1; # End of PDF::Cairo
