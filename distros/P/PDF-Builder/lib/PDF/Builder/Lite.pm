package PDF::Builder::Lite;

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.019'; # VERSION
my $LAST_UPDATE = '3.016'; # manually update whenever code is changed

BEGIN {

    use PDF::Builder;
    use PDF::Builder::Util;
    use PDF::Builder::Basic::PDF::Utils;

    use POSIX qw( ceil floor );
    use Scalar::Util qw(blessed);

    use vars qw( $hasWeakRef );

}

=head1 NAME

PDF::Builder::Lite - Lightweight PDF creation methods

=head1 SYNOPSIS

    $pdf = PDF::Builder::Lite->new();
    $pdf->page(595,842);
    $img = $pdf->image('some.jpg');
    $font = $pdf->corefont('Times-Roman');
    $font = $pdf->ttfont('TimesNewRoman.ttf');

=head1 METHODS

=over

=item $pdf = PDF::Builder::Lite->new(%opts)

=item $pdf = PDF::Builder::Lite->new()

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless($self, $class);
    $self->{'api'} = PDF::Builder->new(%opts);

    return $self;
}

=item $pdf->page()

=item $pdf->page($width,$height)

=item $pdf->page($llx,$lly, $urx,$ury)

Opens a new page.

=cut

sub page {
    my $self = shift();
    $self->{'page'} = $self->{'api'}->page();
    $self->{'page'}->mediabox(@_) if $_[0];
    $self->{'gfx'} = $self->{'page'}->gfx();
#   $self->{'gfx'}->compressFlate();
    return $self;
}

=item $pdf->mediabox($w,$h)

=item $pdf->mediabox($llx,$lly, $urx,$ury)

Sets the global mediabox.

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

=item $pdf->saveas($file)

Saves the document (may B<not> be modified later) and
deallocates the PDF structures.

If C<$file> is just a hyphen '-', the stringified copy is returned, otherwise
the file is saved, and C<$self> is returned (for chaining calls).

=cut

sub saveas {
    my ($self, $file) = @_;

    if ($file eq '-') {
        return $self->{'api'}->stringify();
    } else {
        $self->{'api'}->saveas($file);
        return $self;
    }
    # is the following code ever reached? - Phil
    $self->{'api'}->end();
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


=item $font = $pdf->corefont($fontname)

Returns a new or existing Adobe core font object.

B<Examples:>

    $font = $pdf->corefont('Times-Roman');
    $font = $pdf->corefont('Times-Bold');
    $font = $pdf->corefont('Helvetica');
    $font = $pdf->corefont('ZapfDingbats');

=cut

sub corefont {
    my ($self, $name, @opts) = @_;

    my $obj = $self->{'api'}->corefont($name, @opts);
    return $obj;
}

=item $font = $pdf->ttfont($ttfile)

Returns a new or existing TrueType font object.

B<Examples:>

    $font = $pdf->ttfont('TimesNewRoman.ttf');
    $font = $pdf->ttfont('/fonts/Univers-Bold.ttf');
    $font = $pdf->ttfont('../Democratica-SmallCaps.ttf');

=cut

sub ttfont {
    my ($self, $file, @opts) = @_;

    return $self->{'api'}->ttfont($file, @opts);
}

=item $font = $pdf->psfont($ps_file, %options)

=item $font = $pdf->psfont($ps_file)

Returns a new Type1 (PS) font object.

B<Examples:>

    $font = $pdf->psfont('TimesRoman.pfa', -afmfile => 'TimesRoman.afm', -encode => 'latin1');
    $font = $pdf->psfont('/fonts/Univers.pfb', -pfmfile => '/fonts/Univers.pfm', -encode => 'latin2');

=cut

sub psfont {
    my ($self, @args) = @_;

    return $self->{'api'}->psfont(@args);
}

#=item @color = $pdf->color($colornumber [, $lightdark ])
#
#=item @color = $pdf->color($basecolor [, $lightdark ])
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
#=cut
#
#sub color {
#    my $self = shift();
#
#    return $self->{'api'}->businesscolor(@_);
#}

=item $egs = $pdf->create_egs()

Returns a new extended-graphics-state object.

B<Examples:>

    $egs = $pdf->create_egs();

=cut

sub create_egs {
    my ($self) = @_;

    return $self->{'api'}->egstate();
}

=item $img = $pdf->image_jpeg($file)

Returns a new JPEG image object.

=cut

sub image_jpeg {
    my ($self, $file) = @_;

    return $self->{'api'}->image_jpeg($file);
}

=item $img = $pdf->image_png($file)

Returns a new PNG image object.

=cut

sub image_png {
    my ($self, $file) = @_;

    return $self->{'api'}->image_png($file);
}

=item $img = $pdf->image_tiff($file, %opts)

=item $img = $pdf->image_tiff($file)

Returns a new TIFF image object.

=cut

sub image_tiff {
    my ($self, $file, @opts) = @_;

    return $self->{'api'}->image_tiff($file, @opts);
}

=item $img = $pdf->image_pnm($file)

Returns a new PNM image object.

=cut

sub image_pnm {
    my ($self, $file) = @_;

    return $self->{'api'}->image_pnm($file);
}

=item $pdf->savestate()

Saves the state of the page.

=cut

sub savestate {
    my $self = shift();

    return $self->{'gfx'}->save();
}

=item $pdf->restorestate()

Restores the state of the page.

=cut

sub restorestate {
    my $self = shift();

    return $self->{'gfx'}->restore();
}

=item $pdf->egstate($egs)

Sets extended-graphics state.

=cut

sub egstate {
    my $self = shift();

    $self->{'gfx'}->egstate(@_);
    return $self;
}

=item $pdf->fillcolor($color)

Sets the fill color. See C<strokecolor> for color names and specifications.

=cut

sub fillcolor {
    my $self = shift();

    $self->{'gfx'}->fillcolor(@_);
    return $self;
}

=item $pdf->strokecolor($color)

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

=cut

sub strokecolor {
    my $self = shift();

    $self->{'gfx'}->strokecolor(@_);
    return $self;
}

=item $pdf->linedash(@dash)

Sets the line dash pattern.

=cut

sub linedash {
    my ($self, @a) = @_;
    $self->{'gfx'}->linedash(@a);
    return $self;
}

=item $pdf->linewidth($width)

Sets the line width.

=cut

sub linewidth {
    my ($self, $linewidth) = @_;

    $self->{'gfx'}->linewidth($linewidth);
    return $self;
}

=item $pdf->transform(%opts)

Sets transformations (i.e., translate, rotate, scale, skew) in PDF-canonical order.

B<Example:>

    $pdf->transform(
        -translate => [$x,$y],
        -rotate    => $rot,
        -scale     => [$sx,$sy],
        -skew      => [$sa,$sb],
    )

=cut

sub transform {
    my ($self, %opt) = @_;

    $self->{'gfx'}->transform(%opt);
    return $self;
}

=item $pdf->move($x,$y)

Move to a new drawing location at C[$x,$y].

=cut

sub move { # x,y ...
    my $self = shift();

    $self->{'gfx'}->move(@_);
    return $self;
}

=item $pdf->line($x,$y)

Draw a line to C[$x,$y].

=cut

sub line { # x,y ...
    my $self = shift();

    $self->{'gfx'}->line(@_);
    return $self;
}

=item $pdf->curve($x1,$y1, $x2,$y2, $x3,$y3)

Draw a Bezier curve with three control points.

=cut

sub curve { # x1,y1,x2,y2,x3,y3 ...
    my $self = shift();
    $self->{'gfx'}->curve(@_);
    return $self;
}

=item $pdf->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move, $dir)

=item $pdf->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move)

Draw an arc centered at C[$xc,$yc], with x radius C[$rx] and y radius C[$ry],
from C[$alpha] degrees to C[$beta] degrees. If C[$move] is I<true>, do B<not>
draw a line to the start of the arc. C[$dir] defaults to 0 for counter-clockwise
sweep, and may be set to 1 for a clockwise sweep.

=cut

sub arc { # xc,yc, rx,ry, alpha,beta ,move [,dir]
    my $self = shift();

    $self->{'gfx'}->arc(@_);
    return $self;
}

=item $pdf->ellipse($xc,$yc, $rx,$ry)

Draw an ellipse centered at C[$xc,$yc], with x radius C[$rx] and y radius C[$ry].

=cut

sub ellipse {
    my $self = shift();

    $self->{'gfx'}->ellipse(@_);
    return $self;
}

=item $pdf->circle($xc,$yc, $r)

Draw a circle centered at C[$xc,$yc], of radius C[$r].

=cut

sub circle {
    my $self = shift();

    $self->{'gfx'}->circle(@_);
    return $self;
}

=item $pdf->rect($x,$y, $w,$h)

Draw a rectangle with lower left corner at C[$x,$y], width (+x) C[$w] and
height (+y) C[$h].

=cut

sub rect { # x,y, w,h ...
    my $self = shift();

    $self->{'gfx'}->rect(@_);
    return $self;
}

=item $pdf->rectxy($x1,$y1, $x2,$y2)

Draw a rectangle with opposite corners C[$x1,$y1] and C[$x2,$y2].

=cut

sub rectxy {
    my $self = shift();

    $self->{'gfx'}->rectxy(@_);
    return $self;
}

=item $pdf->poly($x1,$y1, ..., $xn,$yn)

Draw a polyline (multiple line segments) starting at (I<move> to) C[$x1,$y1] and
continuing on to C[$x2,$y2], ..., C[$xn,$yn].

=cut

sub poly {
    my $self = shift();

    $self->{'gfx'}->poly(@_);
    return $self;
}

=item $pdf->close()

Close a shape (draw a line back to the beginning).

=cut

sub close {
    my $self = shift();

    $self->{'gfx'}->close();
    return $self;
}

=item $pdf->stroke()

Stroke (actually draw) a shape whose path has already been laid out, using
the requested C<strokecolor>.

=cut

sub stroke {
    my $self = shift();

    $self->{'gfx'}->stroke();
    return $self;
}

=item $pdf->fill()

Fill in a closed geometry (path), using the requested C<fillcolor>.
The I<non-zero winding rule> is used if the path crosses itself.

=cut

sub fill { # nonzero winding rule
    my $self = shift();

    $self->{'gfx'}->fill();
    return $self;
}

=item $pdf->fillstroke()

Fill (using C<fillcolor>) I<and> stroke (using C<strokecolor>) a closed path.
The I<non-zero winding rule> is used if the path crosses itself.

=cut

sub fillstroke { # nonzero winding rule
    my $self = shift();

    $self->{'gfx'}->fillstroke();
    return $self;
}

=item $pdf->image($imgobj, $x,$y, $w,$h)

=item $pdf->image($imgobj, $x,$y, $scale)

=item $pdf->image($imgobj, $x,$y)

B<Please Note:> The width/height or scale given
is in user-space coordinates, which are subject to
transformations which may have been specified beforehand.

Per default this has a 72dpi resolution, so if you want an
image to have a 150 or 300dpi resolution, you should specify
a scale of 72/150 (or 72/300) or adjust width/height accordingly.

=cut

sub image {
    my $self = shift();

    $self->{'gfx'}->image(@_);
    return $self;
}

=item $pdf->textstart()

Forces the start of text mode while in graphics.

=cut

sub textstart {
    my $self = shift();

    $self->{'gfx'}->textstart();
    return $self;
}

=item $pdf->textfont($fontobj, $size)

Define the current font to be an (already defined) font object at the given size.

=cut

sub textfont {
    my $self = shift();

    $self->{'gfx'}->font(@_);
    return $self;
}

=item $txt->textlead($leading)

Set the baseline-to-baseline "leading" to be used for text lines.

=cut

sub textlead {
    my $self = shift();

    $self->{'gfx'}->lead(@_);
    return $self;
}

=item $pdf->text($string)

Applies (writes out) the given text at the current text location, using the
already-specified font.

=cut

sub text {
    my $self = shift();

    return $self->{'gfx'}->text(@_) || $self;
}

=item $pdf->nl()

Write a newline (drop down to the next line).

=cut

sub nl {
    my $self = shift();

    $self->{'gfx'}->nl();
    return $self;
}

=item $pdf->textend()

Force an end to text output and return to graphics.

=cut

sub textend {
    my $self = shift();

    $self->{'gfx'}->textend();
    return $self;
}

=item $pdf->print($font, $size, $x,$y, $rot, $just, $text)

Convenience wrapper for shortening the textstart..textend sequence.

Go into text mode, set the font to the object and size, go to the location,
set any rotation, set justification, and write the array of text.
Justification is 0 for left, 1 for center, and 2 for right.

=cut

sub print {
    my $self = shift();
    my ($font, $size, $x,$y, $rot, $just, @text) = @_;

    my $text = join(' ', @text);
    $self->textstart();
    $self->textfont($font, $size);
    $self->transform(
        -translate=>[$x, $y],
        -rotate=> $rot,
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

=back

=head1 AUTHOR

Alfred Reibenschuh

=cut
