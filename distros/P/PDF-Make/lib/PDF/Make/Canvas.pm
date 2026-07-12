package PDF::Make::Canvas;

use strict;
use warnings;

our $VERSION = '0.06';

# Load the XS code from PDF::Make
use PDF::Make ();

# XS bindings provide all PDF content stream operators:
#
# Graphics State Operators:
#   q()               - save graphics state
#   Q()               - restore graphics state
#   cm(a,b,c,d,e,f)   - concatenate matrix
#   w(width)          - set line width
#   J(cap)            - set line cap style
#   j(join)           - set line join style
#   M(miter)          - set miter limit
#   d([array], phase) - set dash pattern
#   ri(intent)        - set rendering intent
#   i(flatness)       - set flatness tolerance
#   gs(name)          - set graphics state dict
#
# Path Construction:
#   m(x,y)            - move to
#   l(x,y)            - line to
#   c(x1,y1,x2,y2,x3,y3) - cubic Bézier curve
#   v(x2,y2,x3,y3)    - cubic Bézier (first control = current)
#   y(x1,y1,x3,y3)    - cubic Bézier (second control = endpoint)
#   re(x,y,w,h)       - rectangle
#   h()               - close subpath
#
# Path Painting:
#   S()               - stroke
#   s()               - close and stroke
#   f()               - fill (non-zero)
#   f_star()          - fill (even-odd)
#   B()               - fill and stroke (non-zero)
#   B_star()          - fill and stroke (even-odd)
#   b()               - close, fill, and stroke (non-zero)
#   b_star()          - close, fill, and stroke (even-odd)
#   n()               - end path (no-op)
#
# Clipping:
#   W()               - clip (non-zero)
#   W_star()          - clip (even-odd)
#
# Color:
#   CS(name)          - set stroke color space
#   cs(name)          - set fill color space
#   G(gray)           - set stroke gray
#   g(gray)           - set fill gray
#   RG(r,g,b)         - set stroke RGB
#   rg(r,g,b)         - set fill RGB
#   K(c,m,y,k)        - set stroke CMYK
#   k(c,m,y,k)        - set fill CMYK
#
# Text:
#   BT()              - begin text object
#   ET()              - end text object
#   Tc(space)         - set character spacing
#   Tw(space)         - set word spacing
#   Tz(scale)         - set horizontal scaling
#   TL(leading)       - set leading
#   Tf(font,size)     - set font
#   Tr(render)        - set render mode
#   Ts(rise)          - set rise
#   Td(tx,ty)         - move text position
#   TD(tx,ty)         - move text position, set leading
#   Tm(a,b,c,d,e,f)   - set text matrix
#   T_star()          - move to next line
#   Tj(text)          - show text
#   TJ(array)         - show text with positioning
#   quote(text)       - move to next line and show text
#   dquote(aw,ac,text) - set spacing, move, show
#
# XObject:
#   Do(name)          - invoke XObject
#
# Inline Image:
#   BI()              - begin inline image
#   ID($data)         - image data
#   EI()              - end inline image
#
# Marked Content:
#   BMC(tag)          - begin marked content
#   BDC(tag,props)    - begin marked content with properties
#   EMC()             - end marked content
#   MP(tag)           - marked content point
#   DP(tag,props)     - marked content point with properties
#
# Utility:
#   new()             - create new canvas
#   to_bytes()        - get content stream bytes
#   len()             - get current length
#   clear()           - reset the canvas
#   DESTROY()         - cleanup

# Line cap styles
use constant {
    CAP_BUTT   => 0,
    CAP_ROUND  => 1,
    CAP_SQUARE => 2,
};

# Line join styles
use constant {
    JOIN_MITER => 0,
    JOIN_ROUND => 1,
    JOIN_BEVEL => 2,
};

# Text rendering modes
use constant {
    RENDER_FILL           => 0,
    RENDER_STROKE         => 1,
    RENDER_FILL_STROKE    => 2,
    RENDER_INVISIBLE      => 3,
    RENDER_FILL_CLIP      => 4,
    RENDER_STROKE_CLIP    => 5,
    RENDER_FILL_STROKE_CLIP => 6,
    RENDER_CLIP           => 7,
};

use Exporter 'import';
our @EXPORT_OK = qw(
    CAP_BUTT CAP_ROUND CAP_SQUARE
    JOIN_MITER JOIN_ROUND JOIN_BEVEL
    RENDER_FILL RENDER_STROKE RENDER_FILL_STROKE RENDER_INVISIBLE
    RENDER_FILL_CLIP RENDER_STROKE_CLIP RENDER_FILL_STROKE_CLIP RENDER_CLIP
);
our %EXPORT_TAGS = (
    caps => [qw(CAP_BUTT CAP_ROUND CAP_SQUARE)],
    joins => [qw(JOIN_MITER JOIN_ROUND JOIN_BEVEL)],
    render => [qw(
        RENDER_FILL RENDER_STROKE RENDER_FILL_STROKE RENDER_INVISIBLE
        RENDER_FILL_CLIP RENDER_STROKE_CLIP RENDER_FILL_STROKE_CLIP RENDER_CLIP
    )],
    all => \@EXPORT_OK,
);

1;

__END__

=encoding utf8

=head1 NAME

PDF::Make::Canvas - PDF content stream builder

=head1 SYNOPSIS

    use PDF::Make::Canvas qw(:all);

    my $canvas = PDF::Make::Canvas->new;

    # Draw a rectangle
    $canvas->q                    # save state
           ->w(2)                 # 2pt line width
           ->RG(1, 0, 0)          # red stroke
           ->rg(1, 1, 0)          # yellow fill
           ->re(100, 100, 200, 150)  # rectangle
           ->B                    # fill and stroke
           ->Q;                   # restore state

    # Draw text
    $canvas->BT                   # begin text
           ->Tf('F1', 24)         # set font
           ->Td(100, 700)         # position
           ->Tj('Hello, PDF!')    # show text
           ->ET;                  # end text

    # Get the content stream bytes
    my $bytes = $canvas->to_bytes;

=head1 DESCRIPTION

C<PDF::Make::Canvas> builds PDF content streams using a fluent interface
that mirrors the PDF operators. Each method returns C<$self> for chaining.

=head1 CONSTRUCTOR

=head2 new

    my $canvas = PDF::Make::Canvas->new;

Create a new empty canvas.

=head1 GRAPHICS STATE OPERATORS

=head2 q

    $canvas->q;

Save the current graphics state.

=head2 Q

    $canvas->Q;

Restore the previously saved graphics state.

=head2 cm

    $canvas->cm($a, $b, $c, $d, $e, $f);

Modify the current transformation matrix by concatenating the specified
matrix. The six values form a 3x3 transformation matrix.

=head2 w

    $canvas->w($width);

Set the line width.

=head2 J

    $canvas->J($cap);

Set the line cap style. Use the C<CAP_*> constants.

=head2 j

    $canvas->j($join);

Set the line join style. Use the C<JOIN_*> constants.

=head2 M

    $canvas->M($miter);

Set the miter limit.

=head2 d

    $canvas->d(\@array, $phase);

Set the dash pattern. C<@array> contains dash lengths, C<$phase> is the
starting offset.

=head2 ri

    $canvas->ri($intent);

Set the rendering intent name.

=head2 i

    $canvas->i($flatness);

Set the flatness tolerance.

=head2 gs

    $canvas->gs($name);

Set the graphics state from a named resource.

=head1 PATH CONSTRUCTION OPERATORS

=head2 m

    $canvas->m($x, $y);

Begin a new subpath at the given coordinates.

=head2 l

    $canvas->l($x, $y);

Append a line from the current point to the given coordinates.

=head2 c

    $canvas->c($x1, $y1, $x2, $y2, $x3, $y3);

Append a cubic Bézier curve with control points (x1,y1), (x2,y2) and
endpoint (x3,y3).

=head2 v

    $canvas->v($x2, $y2, $x3, $y3);

Append a cubic Bézier curve with the first control point at the current
point.

=head2 y

    $canvas->y($x1, $y1, $x3, $y3);

Append a cubic Bézier curve with the second control point at the endpoint.

=head2 re

    $canvas->re($x, $y, $width, $height);

Append a rectangle.

=head2 h

    $canvas->h;

Close the current subpath.

=head1 PATH PAINTING OPERATORS

=head2 S

    $canvas->S;

Stroke the path.

=head2 s

    $canvas->s;

Close and stroke the path.

=head2 f

    $canvas->f;

Fill the path using the non-zero winding rule.

=head2 f_star

    $canvas->f_star;

Fill the path using the even-odd rule.

=head2 B

    $canvas->B;

Fill and stroke the path (non-zero winding).

=head2 B_star

    $canvas->B_star;

Fill and stroke the path (even-odd).

=head2 b

    $canvas->b;

Close, fill, and stroke the path (non-zero winding).

=head2 b_star

    $canvas->b_star;

Close, fill, and stroke the path (even-odd).

=head2 n

    $canvas->n;

End the path without filling or stroking.

=head1 CLIPPING OPERATORS

=head2 W

    $canvas->W;

Modify the clipping path using non-zero winding rule.

=head2 W_star

    $canvas->W_star;

Modify the clipping path using even-odd rule.

=head1 COLOR OPERATORS

=head2 CS, cs

    $canvas->CS($name);  # stroke color space
    $canvas->cs($name);  # fill color space

Set the color space.

=head2 G, g

    $canvas->G($gray);   # stroke gray
    $canvas->g($gray);   # fill gray

Set grayscale color (0=black, 1=white).

=head2 RG, rg

    $canvas->RG($r, $g, $b);  # stroke RGB
    $canvas->rg($r, $g, $b);  # fill RGB

Set RGB color (each component 0-1).

=head2 K, k

    $canvas->K($c, $m, $y, $k);  # stroke CMYK
    $canvas->k($c, $m, $y, $k);  # fill CMYK

Set CMYK color (each component 0-1).

=head1 TEXT OPERATORS

=head2 BT, ET

    $canvas->BT;  # begin text object
    $canvas->ET;  # end text object

Begin and end a text object.

=head2 Tc

    $canvas->Tc($char_space);

Set character spacing.

=head2 Tw

    $canvas->Tw($word_space);

Set word spacing.

=head2 Tz

    $canvas->Tz($scale);

Set horizontal scaling (percentage).

=head2 TL

    $canvas->TL($leading);

Set leading (line spacing).

=head2 Tf

    $canvas->Tf($font, $size);

Set the font and size.

=head2 Tr

    $canvas->Tr($mode);

Set the text rendering mode. Use the C<RENDER_*> constants.

=head2 Ts

    $canvas->Ts($rise);

Set text rise (baseline offset).

=head2 Td, TD

    $canvas->Td($tx, $ty);  # move text position
    $canvas->TD($tx, $ty);  # move and set leading

Move the text position.

=head2 Tm

    $canvas->Tm($a, $b, $c, $d, $e, $f);

Set the text matrix.

=head2 T_star

    $canvas->T_star;

Move to the start of the next line.

=head2 Tj

    $canvas->Tj($text);

Show text.

=head2 TJ

    $canvas->TJ(\@array);

Show text with positioning adjustments.

=head2 quote

    $canvas->quote($text);

Move to next line and show text.

=head2 dquote

    $canvas->dquote($aw, $ac, $text);

Set word and character spacing, then show text.

=head1 XOBJECT OPERATORS

=head2 Do

    $canvas->Do($name);

Paint the named XObject.

=head1 UTILITY METHODS

=head2 to_bytes

    my $bytes = $canvas->to_bytes;

Return the accumulated content stream as bytes.

=head2 len

    my $length = $canvas->len;

Return the current byte length of the content.

=head2 clear

    $canvas->clear;

Clear the content buffer for reuse.

=head1 CONSTANTS

=head2 Line Cap Styles

=over 4

=item * C<CAP_BUTT> - Butt cap (default)

=item * C<CAP_ROUND> - Round cap

=item * C<CAP_SQUARE> - Square cap

=back

=head2 Line Join Styles

=over 4

=item * C<JOIN_MITER> - Miter join (default)

=item * C<JOIN_ROUND> - Round join

=item * C<JOIN_BEVEL> - Bevel join

=back

=head2 Text Rendering Modes

=over 4

=item * C<RENDER_FILL> - Fill text (default)

=item * C<RENDER_STROKE> - Stroke text

=item * C<RENDER_FILL_STROKE> - Fill then stroke

=item * C<RENDER_INVISIBLE> - Invisible text

=item * C<RENDER_FILL_CLIP> - Fill and add to clipping path

=item * C<RENDER_STROKE_CLIP> - Stroke and add to clipping path

=item * C<RENDER_FILL_STROKE_CLIP> - Fill, stroke, and clip

=item * C<RENDER_CLIP> - Add to clipping path only

=back

=head1 SEE ALSO

L<PDF::Make::Page>, L<PDF::Make::Document>

=cut
