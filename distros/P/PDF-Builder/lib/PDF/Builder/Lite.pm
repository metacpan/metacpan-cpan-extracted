package PDF::Builder::Lite;

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed
# NOTE that this sub-package has not been tested and is not well documented!
#      It is possible that it will be deprecated and removed.

BEGIN {

    use PDF::Builder;
    use PDF::Builder::Util;
    use PDF::Builder::Basic::PDF::Utils;

    use POSIX qw( ceil floor );
    use Scalar::Util qw(blessed);

    use vars qw( $hasWeakRef );

}

=head1 NAME

PDF::Builder::Lite - Lightweight PDF creation methods (UNMAINTAINED)

=head1 SYNOPSIS

    $pdf = PDF::Builder::Lite->new();
    $pdf->page(595,842);
    $img = $pdf->image('some.jpg');
    $font = $pdf->corefont('Times-Roman');
    $font = $pdf->ttfont('TimesNewRoman.ttf');

=head1 DESCRIPTION

=======================================================================

This class is unmaintained (since 2007) and should not be used in new code. It
combines many of the methods from L<PDF::Builder> and L<PDF::Builder::Content> 
into a single class but isn't really otherwise any easier to use.

There have been many improvements and clarifications made to the rest of the
distribution that aren't reflected here, so the term "Lite" no longer applies.
It remains solely for compatibility with existing legacy code.

B<As it is unmaintained, we I<strongly> suggest that you not use "Lite". If
you have old applications that make use of it, we suggest that you consider
upgrading them to use current, supported, PDF::Builder facilities. Although
we try to maintain backwards compatibility for calls made by "Lite", there is
no guarantee that something may break when called by "Lite"!>

=======================================================================

=head1 METHODS

=head2 new

    $pdf = PDF::Builder::Lite->new(%opts)

    $pdf = PDF::Builder::Lite->new()

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless($self, $class);
    $self->{'api'} = PDF::Builder->new(%opts);

    return $self;
}

=head2 page

    $pdf->page()

    $pdf->page($width,$height)

    $pdf->page($llx,$lly, $urx,$ury)

=over

Opens a new page.

=back

=cut

sub page {
    my $self = shift();
    $self->{'page'} = $self->{'api'}->page();
    $self->{'page'}->mediabox(@_) if $_[0];
    $self->{'gfx'} = $self->{'page'}->gfx();
#   $self->{'gfx'}->compressFlate();
    return $self;
}

=head2 mediabox

    $pdf->mediabox($w,$h)

    $pdf->mediabox($llx,$lly, $urx,$ury)

=over

Sets the global mediabox.

=back

=cut

sub mediabox {
    my ($self, $x1,$y1, $x2,$y2) = @_;
    if (defined $x2) {
        $self->{'api'}->mediabox($x1,$y1, $x2,$y2);
    } else {
        $self->{'api'}->mediabox($x1,$y1);
    }
    return $self;
}

=head2 saveas

    $pdf->saveas($file)

=over

Saves the document (may B<not> be modified later) and
deallocates the PDF structures.

If C<$file> is just a hyphen '-', the stringified copy is returned, otherwise
the file is saved, and C<$self> is returned (for chaining calls).

=back

=cut

sub saveas {
    my ($self, $file) = @_;

    if ($file eq '-') {
        return $self->{'api'}->to_string();
    } else {
        $self->{'api'}->saveas($file);
        return $self;
    }
    # is the following code ever reached? - Phil
   #$self->{'api'}->end();
    foreach my $k (keys %{$self}) {
        if      (blessed($k) and $k->can('release')) {
            $k->release(1);
        } elsif (blessed($k) and $k->can('end')) {
            $k->end();
        }
        $self->{$k} = undef;
        delete($self->{$k});
    }
    return;
}

=head2 corefont

    $font = $pdf->corefont($fontname)

=over

Returns a new or existing Adobe core font object.

B<Examples:>

    $font = $pdf->corefont('Times-Roman');
    $font = $pdf->corefont('Times-Bold');
    $font = $pdf->corefont('Helvetica');
    $font = $pdf->corefont('ZapfDingbats');

=back

=cut

sub corefont {
    my ($self, $name, @opts) = @_;

    my $obj = $self->{'api'}->corefont($name, @opts);
    return $obj;
}

=head2 ttfont

    $font = $pdf->ttfont($ttfile)

=over

Returns a new or existing TrueType font object.

B<Examples:>

    $font = $pdf->ttfont('TimesNewRoman.ttf');
    $font = $pdf->ttfont('/fonts/Univers-Bold.ttf');
    $font = $pdf->ttfont('../Democratica-SmallCaps.ttf');

=back

=cut

sub ttfont {
    my ($self, $file, @opts) = @_;

    return $self->{'api'}->ttfont($file, @opts);
}

=head2 psfont

    $font = $pdf->psfont($ps_file, %options)

    $font = $pdf->psfont($ps_file)

=over

Returns a new Type1 (PS) font object.

B<Examples:>

    $font = $pdf->psfont('TimesRoman.pfa', 'afmfile' => 'TimesRoman.afm', 'encode' => 'latin1');
    $font = $pdf->psfont('/fonts/Univers.pfb', 'pfmfile' => '/fonts/Univers.pfm', 'encode' => 'latin2');

=back

=cut

sub psfont {
    my ($self, @args) = @_;

    return $self->{'api'}->psfont(@args);
}

#=head2 color
#
#    @color = $pdf->color($colornumber [, $lightdark ])
#
#    @color = $pdf->color($basecolor [, $lightdark ])
#
#=over
#
#Returns a color.
#
#B<Examples:>
#
#    @color = $pdf->color(0);        # 50% grey
#    @color = $pdf->color(0,+4);     # 10% grey
#    @color = $pdf->color(0,-3);     # 80% grey
#    @color = $pdf->color('yellow');     # yellow, fully saturated
#    @color = $pdf->color('red',+1);     # red, +10% white
#    @color = $pdf->color('green',-2);   # green, +20% black
#
#=back
#
#=cut
#
#sub color {
#    my $self = shift();
#
#    return $self->{'api'}->businesscolor(@_);
#}

=head2 create_egs

    $egs = $pdf->create_egs()

=over

Returns a new extended-graphics-state object.

B<Examples:>

    $egs = $pdf->create_egs();

=back

=cut

sub create_egs {
    my ($self) = @_;

    return $self->{'api'}->egstate();
}

=head2 image_jpeg

    $img = $pdf->image_jpeg($file)

=over

Returns a new JPEG image object.

=back

=cut

sub image_jpeg {
    my ($self, $file) = @_;

    return $self->{'api'}->image_jpeg($file);
}

=head2 image_png

    $img = $pdf->image_png($file)

=over

Returns a new PNG image object.

=back

=cut

sub image_png {
    my ($self, $file) = @_;

    return $self->{'api'}->image_png($file);
}

=head2 image_tiff

    $img = $pdf->image_tiff($file, %opts)

    $img = $pdf->image_tiff($file)

=over

Returns a new TIFF image object.

=back

=cut

sub image_tiff {
    my ($self, $file, @opts) = @_;

    return $self->{'api'}->image_tiff($file, @opts);
}

=head2 image_pnm

    $img = $pdf->image_pnm($file)

=over

Returns a new PNM image object.

=back

=cut

sub image_pnm {
    my ($self, $file) = @_;

    return $self->{'api'}->image_pnm($file);
}

=head2 savestate

    $pdf->savestate()

=over

Saves the state of the page.

=back

=cut

sub savestate {
    my $self = shift();

    return $self->{'gfx'}->save();
}

=head2 restorestate

    $pdf->restorestate()

=over

Restores the state of the page.

=back

=cut

sub restorestate {
    my $self = shift();

    return $self->{'gfx'}->restore();
}

=head2 egstate

    $pdf->egstate($egs)

=over

Sets extended-graphics state.

=back

=cut

sub egstate {
    my $self = shift();

    $self->{'gfx'}->egstate(@_);
    return $self;
}

=head2 fillcolor

    $pdf->fillcolor($color)

=over

Sets the fill color. See C<strokecolor> for color names and specifications.

=back

=cut

sub fillcolor {
    my $self = shift();

    $self->{'gfx'}->fillcolor(@_);
    return $self;
}

=head2 strokecolor

    $pdf->strokecolor($color)

=over

Sets the stroke color.

B<Defined color-names are:>

    aliceblue, antiquewhite, aqua, aquamarine, azure, beige, bisque, black, blanchedalmond,
    blue, blueviolet, brown, burlywood, cadetblue, chartreuse, chocolate, coral, cornflowerblue,
    cornsilk, crimson, cyan, darkblue, darkcyan, darkgoldenrod, darkgray, darkgreen, darkgrey,
    darkkhaki, darkmagenta, darkolivegreen, darkorange, darkorchid, darkred, darksalmon,
    darkseagreen, darkslateblue, darkslategray, darkslategrey, darkturquoise, darkviolet,
    deeppink, deepskyblue, dimgray, dimgrey, dodgerblue, firebrick, floralwhite, forestgreen,
    fuchsia, gainsboro, ghostwhite, gold, goldenrod, gray, grey, green, greenyellow, honeydew,
    hotpink, indianred, indigo, ivory, khaki, lavender, lavenderblush, lawngreen, lemonchiffon,
    lightblue, lightcoral, lightcyan, lightgoldenrodyellow, lightgray, lightgreen, lightgrey,
    lightpink, lightsalmon, lightseagreen, lightskyblue, lightslategray, lightslategrey,
    lightsteelblue, lightyellow, lime, limegreen, linen, magenta, maroon, mediumaquamarine,
    mediumblue, mediumorchid, mediumpurple, mediumseagreen, mediumslateblue, mediumspringgreen,
    mediumturquoise, mediumvioletred, midnightblue, mintcream, mistyrose, moccasin, navajowhite,
    navy, oldlace, olive, olivedrab, orange, orangered, orchid, palegoldenrod, palegreen,
    paleturquoise, palevioletred, papayawhip, peachpuff, peru, pink, plum, powderblue, purple,
    red, rosybrown, royalblue, saddlebrown, salmon, sandybrown, seagreen, seashell, sienna,
    silver, skyblue, slateblue, slategray, slategrey, snow, springgreen, steelblue, tan, teal,
    thistle, tomato, turquoise, violet, wheat, white, whitesmoke, yellow, yellowgreen

or the rgb-hex-notation:

    #rgb, #rrggbb, #rrrgggbbb and #rrrrggggbbbb

or the cmyk-hex-notation:

    %cmyk, %ccmmyykk, %cccmmmyyykkk and %ccccmmmmyyyykkkk

or the hsl-hex-notation:

    &hsl, &hhssll, &hhhssslll and &hhhhssssllll

or the hsv-hex-notation:

    !hsv, !hhssvv, !hhhsssvvv and !hhhhssssvvvv

=back

=cut

sub strokecolor {
    my $self = shift();

    $self->{'gfx'}->strokecolor(@_);
    return $self;
}

=head2 linedash

    $pdf->linedash(@dash)

=over

Sets the line dash pattern.

=back

=cut

sub linedash {
    my ($self, @a) = @_;
    $self->{'gfx'}->linedash(@a);
    return $self;
}

=head2 linewidth

    $pdf->linewidth($width)

=over

Sets the line width.

=back

=cut

sub linewidth {
    my ($self, $linewidth) = @_;

    $self->{'gfx'}->linewidth($linewidth);
    return $self;
}

=head2 transform

    $pdf->transform(%opts)

=over

Sets transformations (i.e., translate, rotate, scale, skew) in PDF-canonical order.

B<Example:>

    $pdf->transform(
        'translate' => [$x,$y],
        'rotate'    => $rot,
        'scale'     => [$sx,$sy],
        'skew'      => [$sa,$sb],
    )

=back

=cut

sub transform {
    my ($self, %opt) = @_;

    $self->{'gfx'}->transform(%opt);
    return $self;
}

=head2 move

    $pdf->move($x,$y)

=over

Move to a new drawing location at C[$x,$y].

=back

=cut

sub move { # x,y ...
    my $self = shift();

    $self->{'gfx'}->move(@_);
    return $self;
}

=head2 line

    $pdf->line($x,$y)

=over

Draw a line to C[$x,$y].

=back

=cut

sub line { # x,y ...
    my $self = shift();

    $self->{'gfx'}->line(@_);
    return $self;
}

=head2 curve

    $pdf->curve($x1,$y1, $x2,$y2, $x3,$y3)

=over

Draw a Bezier curve with three control points.

=back

=cut

sub curve { # x1,y1,x2,y2,x3,y3 ...
    my $self = shift();
    $self->{'gfx'}->curve(@_);
    return $self;
}

=head2 arc

    $pdf->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move, $dir)

    $pdf->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move)

=over

Draw an arc centered at C[$xc,$yc], with x radius C[$rx] and y radius C[$ry],
from C[$alpha] degrees to C[$beta] degrees. If C[$move] is I<true>, do B<not>
draw a line to the start of the arc. C[$dir] defaults to 0 for counter-clockwise
sweep, and may be set to 1 for a clockwise sweep.

=back

=cut

sub arc { # xc,yc, rx,ry, alpha,beta ,move [,dir]
    my $self = shift();

    $self->{'gfx'}->arc(@_);
    return $self;
}

=head2 ellipse

    $pdf->ellipse($xc,$yc, $rx,$ry)

=over

Draw an ellipse centered at C[$xc,$yc], with x radius C[$rx] and y radius C[$ry].

=back

=cut

sub ellipse {
    my $self = shift();

    $self->{'gfx'}->ellipse(@_);
    return $self;
}

=head2 circle

    $pdf->circle($xc,$yc, $r)

=over

Draw a circle centered at C[$xc,$yc], of radius C[$r].

=back

=cut

sub circle {
    my $self = shift();

    $self->{'gfx'}->circle(@_);
    return $self;
}

=head2 rect

    $pdf->rect($x,$y, $w,$h)

=over

Draw a rectangle with lower left corner at C[$x,$y], width (+x) C[$w] and
height (+y) C[$h].

=back

=cut

sub rect { # x,y, w,h ...
    my $self = shift();

    $self->{'gfx'}->rect(@_);
    return $self;
}

=head2 rectxy

    $pdf->rectxy($x1,$y1, $x2,$y2)

=over

Draw a rectangle with opposite corners C[$x1,$y1] and C[$x2,$y2].

=back

=cut

sub rectxy {
    my $self = shift();

    $self->{'gfx'}->rectxy(@_);
    return $self;
}

=head2 poly

    $pdf->poly($x1,$y1, ..., $xn,$yn)

=over

Draw a polyline (multiple line segments) starting at (I<move> to) C[$x1,$y1] and
continuing on to C[$x2,$y2], ..., C[$xn,$yn].

=back

=cut

sub poly {
    my $self = shift();

    $self->{'gfx'}->poly(@_);
    return $self;
}

=head2 close

    $pdf->close()

=over

Close a shape (draw a line back to the beginning).

=back

=cut

sub close {
    my $self = shift();

    $self->{'gfx'}->close();
    return $self;
}

=head2 stroke

    $pdf->stroke()

=over

Stroke (actually draw) a shape whose path has already been laid out, using
the requested C<strokecolor>.

=back

=cut

sub stroke {
    my $self = shift();

    $self->{'gfx'}->stroke();
    return $self;
}

=head2 fill

    $pdf->fill()

=over

Fill in a closed geometry (path), using the requested C<fillcolor>.
The I<non-zero winding rule> is used if the path crosses itself.

=back

=cut

sub fill { # nonzero winding rule
    my $self = shift();

    $self->{'gfx'}->fill();
    return $self;
}

=head2 fillstroke

    $pdf->fillstroke()

=over

Fill (using C<fillcolor>) I<and> stroke (using C<strokecolor>) a closed path.
The I<non-zero winding rule> is used if the path crosses itself.

=back

=cut

sub fillstroke { # nonzero winding rule
    my $self = shift();

    $self->{'gfx'}->fillstroke();
    return $self;
}

=head2 image

    $pdf->image($imgobj, $x,$y, $w,$h)

    $pdf->image($imgobj, $x,$y, $scale)

    $pdf->image($imgobj, $x,$y)

=over

B<Please Note:> The width/height or scale given
is in user-space coordinates, which are subject to
transformations which may have been specified beforehand.

Per default this has a 72dpi resolution, so if you want an
image to have a 150 or 300dpi resolution, you should specify
a scale of 72/150 (or 72/300) or adjust width/height accordingly.

=back

=cut

sub image {
    my $self = shift();

    $self->{'gfx'}->image(@_);
    return $self;
}

=head2 textstart

    $pdf->textstart()

=over

Forces the start of text mode while in graphics.

=back

=cut

sub textstart {
    my $self = shift();

    $self->{'gfx'}->textstart();
    return $self;
}

=head2 textfont

    $pdf->textfont($fontobj, $size)

=over

Define the current font to be an (already defined) font object at the given size.

=back

=cut

sub textfont {
    my $self = shift();

    $self->{'gfx'}->font(@_);
    return $self;
}

=head2 textleading

    $txt->textleading($leading)

=over

Set the baseline-to-baseline "leading" to be used for text lines.

=back

=cut

sub textleading {
    my $self = shift();

    $self->{'gfx'}->leading(@_);
    return $self;
}

=head2 text

    $pdf->text($string)

=over

Applies (writes out) the given text at the current text location, using the
already-specified font.

=back

=cut

sub text {
    my $self = shift();

    return $self->{'gfx'}->text(@_) || $self;
}

=head2 nl

    $pdf->nl()

=over

Write a newline (drop down to the next line).

=back

=cut

sub nl {
    my $self = shift();

    $self->{'gfx'}->nl();
    return $self;
}

=head2 textend

    $pdf->textend()

=over

Force an end to text output and return to graphics.

=back

=cut

sub textend {
    my $self = shift();

    $self->{'gfx'}->textend();
    return $self;
}

=head2 print

    $pdf->print($font, $size, $x,$y, $rot, $just, $text)

=over

Convenience wrapper for shortening the textstart..textend sequence.

Go into text mode, set the font to the object and size, go to the location,
set any rotation, set justification, and write the array of text.
Justification is 0 for left, 1 for center, and 2 for right.

=back

=cut

sub print {
    my $self = shift();
    my ($font, $size, $x,$y, $rot, $just, @text) = @_;

    my $text = join(' ', @text);
    $self->textstart();
    $self->textfont($font, $size);
    $self->transform(
        'translate' => [$x, $y],
        'rotate' => $rot,
    );
    if      ($just==1) {
        $self->{'gfx'}->text_center($text);
    } elsif ($just==2) {
        $self->{'gfx'}->text_right($text);
    } else {
        $self->text(@text);
    }
    $self->textend();
    return $self;
}

1;

__END__

=head1 AUTHOR

This module was originally written by Alfred Reibenschuh. It has had some
minor updates over time, but otherwise is mostly unchanged.

=cut
