package PDF::Builder::Content;

use base 'PDF::Builder::Basic::PDF::Dict';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use Carp;
use Compress::Zlib qw();
use Encode;
use Math::Trig;    # CAUTION: deg2rad(0) = deg2rad(360) = 0!
use List::Util    qw(min max);
use PDF::Builder::Matrix;

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use PDF::Builder::Content::Text;

# unless otherwise noted, routines beginning with _ are internal helper 
# functions and should not be used by others
#
=head1 NAME

PDF::Builder::Content - Methods for adding graphics and text to a PDF

Inherits from L<PDF::Builder::Basic::PDF::Dict>

=head1 SYNOPSIS

    # Start with a PDF page (new or opened)
    my $pdf = PDF::Builder->new();
    my $page = $pdf->page();

    # Add new content object(s)
    my $content = $page->graphics();  # or gfx()
    #   and/or (as separate object name)
    my $content = $page->text();

    # Then call the methods below to add graphics and text to the page.
    # Note that negative coordinates can have unpredictable effects, so
    # keep your coordinates non-negative!

These methods add content to I<streams> output for text or graphics objects.
Unless otherwise restricted by a check that we are in or out of text mode,
many methods listed here apply equally to text and graphics streams. It is
possible that there I<are> some which have no effect in one stream type or
the other, but are currently lacking a check to prevent them from being 
inserted into an inapplicable stream.

=head1 METHODS

All public methods listed, I<except as otherwise noted,> return C<$self>,
for ease of chaining calls.

=cut

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(@_);
    $self->{' stream'}         = '';
    $self->{' poststream'}     = '';
    $self->{' font'}           = undef;
    $self->{' fontset'}        = 0;
    $self->{' fontsize'}       = 0;
    $self->{' charspace'}      = 0;
    $self->{' hscale'}         = 100;
    $self->{' wordspace'}      = 0;
    $self->{' leading'}        = 0;
    $self->{' rise'}           = 0;
    $self->{' render'}         = 0;
    $self->{' matrix'}         = [1,0,0,1,0,0];
    $self->{' textmatrix'}     = [1,0,0,1,0,0];
    $self->{' textlinematrix'} = [0,0];
    $self->{' textlinestart'}  = 0;
    $self->{' fillcolor'}      = [0];
    $self->{' strokecolor'}    = [0];
    $self->{' translate'}      = [0,0];
    $self->{' scale'}          = [1,1];
    $self->{' skew'}           = [0,0];
    $self->{' rotate'}         = 0;
    $self->{' linewidth'}      = 1;      # see also gs LW
    $self->{' linecap'}        = 0;      # see also gs LC
    $self->{' linejoin'}       = 0;      # see also gs LJ
    $self->{' miterlimit'}     = 10;     # see also gs ML
    $self->{' linedash'}       = [[],0]; # see also gs D
    $self->{' flatness'}       = 1;      # see also gs FL
    $self->{' apiistext'}      = 0;
    $self->{' openglyphlist'}  = 0;
    # hold only latest of multiple instances
    $self->{' doPending'}      = 0;   # DISABLE for now
    $self->{' Tpending'}         = ();
      $self->{' Tpending'}{'Tm'} = '';
      $self->{' Tpending'}{'Tf'} = '';
     # Td (and T*) are relative positioning, so don't buffer
     #$self->{' Tpending'}{'Td'} = '';
      $self->{' Tpending'}{'color'} = ''; # rg, g, k, etc.
      $self->{' Tpending'}{'Color'} = ''; # RG, G, K, etc.
    $self->{' Gpending'}         = ();
      $self->{' Gpending'}{'color'} = ''; # rg, g, k, etc.
      $self->{' Gpending'}{'Color'} = ''; # RG, G, K, etc.
      # consider line width, dash pattern, linejoin, linecap, etc.

    return $self;
}

# internal helper method
sub outobjdeep {
    my $self = shift();

    $self->textend();
#   foreach my $k (qw[ api apipdf apiistext apipage font fontset fontsize
#                      charspace hscale wordspace leading rise render matrix
#                      textmatrix textlinematrix fillcolor strokecolor
#                      translate scale skew rotate ]) {
#       $self->{" $k"} = undef;
#       delete($self->{" $k"});
#   }
    if ($self->{'-docompress'} && $self->{'Filter'}) {
        $self->{' stream'} = Compress::Zlib::compress($self->{' stream'});
        $self->{' nofilt'} = 1;
        delete $self->{'-docompress'};
    }
    return $self->SUPER::outobjdeep(@_);
}

=head2 Coordinate Transformations

The methods in this section change the coordinate system for the
current content object relative to the rest of the document.
B<Note:> the changes are relative to the I<original> page coordinates (and 
thus, absolute), not to the previous position! Thus, C<translate(10, 10); 
translate(10, 10);> ends up only moving the origin to C<[10, 10]>, rather than 
to C<[20, 20]>. There is one call, C<transform_rel()>, which makes your changes 
I<relative> to the previous position.

If you call more than one of these methods, the PDF specification
recommends calling them in the following order: translate, rotate,
scale, skew.  Each change builds on the last, and you can get
unexpected results when calling them in a different order.

B<CAUTION:> a I<text> object ($content) behaves a bit differently. Individual
translate, rotate, scale, and skew calls I<cancel out> any previous settings.
If you want to combine multiple transformations for text, use the C<transform>
call.

=head3 translate

    $content->translate($dx,$dy)

=over

Moves the origin along the x and y axes to 
C<$dx> and C<$dy> respectively.

=back

=cut

sub _translate {
    my ($x,$y) = @_;

    return (1,0,0,1, $x,$y);
}

# transform in turn calls _translate
sub translate {
    my ($self, $x,$y) = @_;

    $self->transform('translate' => [$x,$y]);

    return $self;
}

=head3 rotate

    $content->rotate($degrees)

=over

Rotates the coordinate system counter-clockwise (anti-clockwise) around the
current origin. Use a negative argument to rotate clockwise. Note that 360 
degrees will be treated as 0 degrees.

B<Note:> Unless you have already moved (translated) the origin, it is, and will
remain, at the lower left corner of the visible sheet. It will I<not>
automatically shift to another corner. For example, a rotation of +90 degrees
(counter-clockwise) will leave the entire visible sheet in negative Y territory (0 at the left edge, -original_width at the right edge), while X remains in
positive territory (0 at bottom, +original_height at the top edge).

This C<rotate()> call permits any angle. Do not confuse it with the I<page>
rotation C<rotate> call, which only permits increments of 90 degrees (with
opposite sign!), but I<does> shift the origin to another corner of the sheet.

=back

=cut

sub _rotate {
    my ($deg) = @_;

    return (cos(deg2rad($deg)), sin(deg2rad($deg)), -sin(deg2rad($deg)), cos(deg2rad($deg)), 0,0);
}

# transform in turn calls _rotate
sub rotate {
    my ($self, $deg) = @_;

    $self->transform('rotate' => $deg);

    return $self;
}

=head3 scale

    $content->scale($sx,$sy)

=over

Scales (stretches) the coordinate systems along the x and y axes.
Separate multipliers are provided for x and y.

=back

=cut

sub _scale {
    my ($sx,$sy) = @_;

    return ($sx,0,0,$sy, 0,0);
}

# transform in turn calls _scale
sub scale {
    my ($self, $sx,$sy) = @_;

    $self->transform('scale' => [$sx,$sy]);

    return $self;
}

=head3 skew

    $content->skew($skx,$sky)

=over

Skews the coordinate system by C<$skx> degrees 
(counter-clockwise/anti-clockwise) from
the x axis I<and> C<$sky> degrees (clockwise) from the y axis.
Note that 360 degrees will be treated the same as 0 degrees.

=back

=cut

sub _skew {
    my ($skx,$sky) = @_;

    return (1, tan(deg2rad($skx)), tan(deg2rad($sky)), 1, 0,0);
}

# transform in turn calls _skew
sub skew {
    my ($self, $skx,$sky) = @_;

    $self->transform('skew' => [$skx,$sky]);

    return $self;
}

=head3 transform

    $content->transform(%opts)

=over

Use one or more of the given %opts:

    $content->transform(
        'translate' => [$dx,$dy],
        'rotate'    => $degrees,
        'scale'     => [$sx,$sy],
        'skew'      => [$skx,$sky],
        'matrix'    => [$a, $b, $c, $d, $e, $f],
        'point'     => [$x,$y]
	'repeat'    => $boolean
    )

A six element list may be given (C<matrix>) for a 
further transformation matrix:

    $a = cos(rot) * scale factor for X 
    $b = sin(rot) * tan(skew for X)
    $c = -sin(rot) * tan(skew for Y)
    $d = cos(rot) * scale factor for Y 
    $e = translation for X
    $f = translation for Y

Performs multiple coordinate transformations in one call, in the order
recommended by the PDF specification (translate, rotate, scale, skew).
This is equivalent to making each transformation separately, I<in the
indicated order>.
A matrix of 6 values may also be given (C<matrix>). The transformation matrix 
is updated. 
A C<point> may be given (a point to be multiplied [transformed] by the 
completed matrix).
Omitted options will be unchanged.

If C<repeat> is true, and if this is not the first call to a transformation
method, the previous transformation will be performed again, modified by any
other provided arguments.

=back

=cut

sub _transform {
    my (%opts) = @_;
    # user should not be calling this routine directly, but only via transform()

    # start with "no-op" identity matrix
    my $mtx = PDF::Builder::Matrix->new([1,0,0], [0,1,0], [0,0,1]);
    # note order of operations, compared to PDF spec
    foreach my $o (qw( matrix skew scale rotate translate )) {
        next unless defined $opts{$o};

        if      ($o eq 'translate') {
            my @mx = _translate(@{$opts{$o}});
            $mtx = $mtx->multiply(PDF::Builder::Matrix->new(
                [$mx[0],$mx[1],0],
                [$mx[2],$mx[3],0],
                [$mx[4],$mx[5],1]
            ));
        } elsif ($o eq 'rotate') {
            my @mx = _rotate($opts{$o});
            $mtx = $mtx->multiply(PDF::Builder::Matrix->new(
                [$mx[0],$mx[1],0],
                [$mx[2],$mx[3],0],
                [$mx[4],$mx[5],1]
            ));
        } elsif ($o eq 'scale') {
            my @mx = _scale(@{$opts{$o}});
            $mtx = $mtx->multiply(PDF::Builder::Matrix->new(
                [$mx[0],$mx[1],0],
                [$mx[2],$mx[3],0],
                [$mx[4],$mx[5],1]
            ));
        } elsif ($o eq 'skew') {
            my @mx = _skew(@{$opts{$o}});
            $mtx = $mtx->multiply(PDF::Builder::Matrix->new(
                [$mx[0],$mx[1],0],
                [$mx[2],$mx[3],0],
                [$mx[4],$mx[5],1]
            ));
        } elsif ($o eq 'matrix') {
            my @mx = @{$opts{$o}};  # no check that 6 elements given
            $mtx = $mtx->multiply(PDF::Builder::Matrix->new(
                [$mx[0],$mx[1],0],
                [$mx[2],$mx[3],0],
                [$mx[4],$mx[5],1]
            ));
        }
    }
    if ($opts{'point'}) {
        my $mp = PDF::Builder::Matrix->new([$opts{'point'}->[0], $opts{'point'}->[1], 1]);
        $mp = $mp->multiply($mtx);
        return ($mp->[0][0], $mp->[0][1]);
    }

    # if not point
    return (
        $mtx->[0][0],$mtx->[0][1],
        $mtx->[1][0],$mtx->[1][1],
        $mtx->[2][0],$mtx->[2][1]
    );
}

sub transform {
    my ($self, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if ($opts{'-translate'} && !defined $opts{'translate'}) { $opts{'translate'} = delete($opts{'-translate'}); }
    if ($opts{'-rotate'} && !defined $opts{'rotate'}) { $opts{'rotate'} = delete($opts{'-rotate'}); }
    if ($opts{'-scale'} && !defined $opts{'scale'}) { $opts{'scale'} = delete($opts{'-scale'}); }
    if ($opts{'-skew'} && !defined $opts{'skew'}) { $opts{'skew'} = delete($opts{'-skew'}); }
    if ($opts{'-point'} && !defined $opts{'point'}) { $opts{'point'} = delete($opts{'-point'}); }
    if ($opts{'-matrix'} && !defined $opts{'matrix'}) { $opts{'matrix'} = delete($opts{'-matrix'}); }
    if ($opts{'-repeat'} && !defined $opts{'repeat'}) { $opts{'repeat'} = delete($opts{'-repeat'}); }

    # 'repeat' changes mode to relative
    return $self->transform_rel(%opts) if $opts{'repeat'};

    # includes point and matrix operations
    $self->matrix(_transform(%opts));

    if ($opts{'translate'}) {
        @{$self->{' translate'}} = @{$opts{'translate'}};
    } else {
        @{$self->{' translate'}} = (0,0);
    }

    if ($opts{'rotate'}) {
        $self->{' rotate'} = $opts{'rotate'};
    } else {
        $self->{' rotate'} = 0;
    }

    if ($opts{'scale'}) {
        @{$self->{' scale'}} = @{$opts{'scale'}};
    } else {
        @{$self->{' scale'}} = (1,1);
    }

    if ($opts{'skew'}) {
        @{$self->{' skew'}} = @{$opts{'skew'}};
    } else {
        @{$self->{' skew'}} = (0,0);
    }

    return $self;
}

=head3 transform_rel

    $content->transform_rel(%opts)

=over

Makes transformations similarly to C<transform>, except that it I<adds>
to the previously set values, rather than I<replacing> them (except for 
I<scale>, which B<multiplies> the new values with the old).

Unlike C<transform>, C<matrix> and C<point> are not supported.

=back

=cut

sub transform_rel {
    my ($self, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-skew'} && !defined $opts{'skew'}) { $opts{'skew'} = delete($opts{'-skew'}); }
    if (defined $opts{'-scale'} && !defined $opts{'scale'}) { $opts{'scale'} = delete($opts{'-scale'}); }
    if (defined $opts{'-rotate'} && !defined $opts{'rotate'}) { $opts{'rotate'} = delete($opts{'-rotate'}); }
    if (defined $opts{'-translate'} && !defined $opts{'translate'}) { $opts{'translate'} = delete($opts{'-translate'}); }

    my ($sa1,$sb1) = @{$opts{'skew'} ? $opts{'skew'} : [0,0]};
    my ($sa0,$sb0) = @{$self->{" skew"}};

    my ($sx1,$sy1) = @{$opts{'scale'} ? $opts{'scale'} : [1,1]};
    my ($sx0,$sy0) = @{$self->{" scale"}};

    my $rot1 = $opts{'rotate'} || 0;
    my $rot0 = $self->{" rotate"};

    my ($tx1,$ty1) = @{$opts{'translate'} ? $opts{'translate'} : [0,0]};
    my ($tx0,$ty0) = @{$self->{" translate"}};

    $self->transform(
        'skew'      => [$sa0+$sa1, $sb0+$sb1],
        'scale'     => [$sx0*$sx1, $sy0*$sy1],
        'rotate'    => $rot0+$rot1,
        'translate' => [$tx0+$tx1, $ty0+$ty1]
    );

    return $self;
}

=head3 matrix

    $content->matrix($a, $b, $c, $d, $e, $f)

=over

I<(Advanced)> Sets the current transformation matrix manually. Unless
you have a particular need to enter transformations manually, you
should use the C<transform> method instead.

    $a = cos(rot) * scale factor for X 
    $b = sin(rot) * tan(skew for X)
    $c = -sin(rot) * tan(skew for Y)
    $d = cos(rot) * scale factor for Y 
    $e = translation for X
    $f = translation for Y

In text mode, the text matrix is B<returned>. 
In graphics mode, C<$self> is B<returned>.

=back

=cut

sub _matrix_text {
    my ($a, $b, $c, $d, $e, $f) = @_;

   #return (floats($a, $b, $c, $d, $e, $f), 'Tm');
    return
       float($a).' '.float($b).' '.float($c).' '.float($d).' '.
       float($e).' '.float($f).' Tm';
}

sub _matrix_gfx {
    my ($a, $b, $c, $d, $e, $f) = @_;

    return (floats($a, $b, $c, $d, $e, $f), 'cm');
}

# internal helper method
sub matrix_update {
    my ($self, $tx,$ty) = @_;

    $self->{' textlinematrix'}->[0] += $tx;
    $self->{' textlinematrix'}->[1] += $ty;
    return $self;
}

sub matrix {
    my ($self, $a, $b, $c, $d, $e, $f) = @_;

    if (defined $a) {
        if ($self->_in_text_object()) {
	    # in text mode, buffer the Tm output
	    if ($self->{' doPending'}) {
	        $self->{' Tpending'}{'Tm'} = _matrix_text($a, $b, $c, $d, $e, $f);
	    } else {
                $self->add(_matrix_text($a, $b, $c, $d, $e, $f));
	    }
            @{$self->{' textmatrix'}} = ($a, $b, $c, $d, $e, $f);
            @{$self->{' textlinematrix'}} = (0,0);
        } else {
	    # in graphics mode, directly output cm 
            $self->add(_matrix_gfx($a, $b, $c, $d, $e, $f));
        }
    }
    if ($self->_in_text_object()) {
        return @{$self->{' textmatrix'}};
    } else {
        return $self;
    }
}

=head2 Graphics State Parameters

The following calls also affect the B<text> state.

=head3 linewidth, line_width

    $content->linewidth($width)

=over

Sets the width of the stroke (in points). This is the line drawn in graphics 
mode, or the I<outline> of a character in text mode (with appropriate C<render> 
mode). If no C<$width> is given, the current setting is B<returned>. If the 
width is being set, C<$self> is B<returned> so that calls may be chained.

B<Alternate name:> C<line_width>

This is provided for compatibility with PDF::API2.

=back

=cut

sub _linewidth {
    my ($linewidth) = @_;

    return ($linewidth, 'w');
}

sub line_width { return linewidth(@_); } ## no critic

sub linewidth {
    my ($self, $linewidth) = @_;

    if (!defined $linewidth) {
	return $self->{' linewidth'};
    }
    $self->add(_linewidth($linewidth));
    $self->{' linewidth'} = $linewidth;

    return $self;
}

=head3 linecap, line_cap

    $content->linecap($style)

=over

Sets the style to be used at the end of a stroke. This applies to lines
which come to a free-floating end, I<not> to "joins" ("corners") in 
polylines (see C<linejoin>).

B<Alternate name:> C<line_cap>

This is provided for compatibility with PDF::API2.

=over

=item "butt" or "b" or 0 = Butt Cap (default)

The stroke ends at the end of the path, with no projection.

=item "round" or "r" or 1 = Round Cap

A semicircular arc is drawn around the end of the path with a diameter equal to
the line width, and is filled in.

=item "square" or "s" or 2 = Projecting Square Cap

The stroke continues past the end of the path for half the line width.

=back

If no C<$style> is given, the current setting is B<returned>. If the style is
being set, C<$self> is B<returned> so that calls may be chained.

Either a number or a string (case-insensitive) may be given.

=back

=cut

sub _linecap {
    my ($linecap) = @_;

    return ($linecap, 'J');
}

sub line_cap { return linecap(@_); } ## no critic

sub linecap {
    my ($self, $linecap) = @_;

    if (!defined $linecap) {  # Get
	return $self->{' linecap'};
    }

    # Set
    my $style = lc($linecap) // 0; # could be number or string
    $style = 0 if $style eq 'butt'   or $style eq 'b';
    $style = 1 if $style eq 'round'  or $style eq 'r';
    $style = 2 if $style eq 'square' or $style eq 's';
    unless ($style >= 0 && $style <= 2) {
	carp "Unknown line cap style '$linecap', using 0 instead";
	$style = 0;
    }

    $self->add(_linecap($style));
    $self->{' linecap'} = $style;

    return $self;
}

=head3 linejoin, line_join

    $content->linejoin($style)

=over

Sets the style of join to be used at corners of a path
(within a multisegment polyline).

B<Alternate name:> C<line_join>

This is provided for compatibility with PDF::API2.

=over

=item "miter" or "m" or 0 = Miter Join, default

The outer edges of the strokes extend until they meet, up to the limit
specified by I<miterlimit>. If the limit would be surpassed, a I<bevel> join
is used instead. For a given linewidth, the more acute the angle is (closer
to 0 degrees), the higher the ratio of miter length to linewidth will be, and 
that's what I<miterlimit> controls -- a very "pointy" join is replaced by
a bevel.

=item "round" or "r" or 1 = Round Join

A filled circle with a diameter equal to the I<linewidth> is drawn around the
corner point, producing a rounded corner. The arc will meet up with the sides
of the line in a smooth tangent.

=item "bevel" or "b" or 2 = Bevel Join

A filled triangle is drawn to fill in the notch between the two strokes.

=back

If no C<$style> is given, the current setting is B<returned>. If the style is
being set, C<$self> is B<returned> so that calls may be chained.

Either a number or a string (case-insensitive) may be given.

=back

=cut

sub _linejoin {
    my ($style) = @_;

    return ($style, 'j');
}

sub line_join { return linejoin(@_); } ## no critic

sub linejoin {
    my ($self, $linejoin) = @_;

    if (!defined $linejoin) {  # Get
	return $self->{' linejoin'};
    }

    # Set
    my $style = lc($linejoin) // 0; # could be number or string
    $style = 0 if $style eq 'miter'  or $style eq 'm';
    $style = 1 if $style eq 'round'  or $style eq 'r';
    $style = 2 if $style eq 'bevel'  or $style eq 'b';
    unless ($style >= 0 && $style <= 2) {
	carp "Unknown line join style '$linejoin', using 0 instead";
	$style = 0;
    }

    $self->add(_linejoin($style));
    $self->{' linejoin'} = $style;

    return $self;
}

=head3 miterlimit, miter_limit

    $content->miterlimit($ratio)

=over

Sets the miter limit when the line join style is a I<miter> join.

The ratio is the maximum length of the miter (inner to outer corner) divided 
by the line width. Any miter above this ratio will be converted to a I<bevel> 
join. The practical effect is that lines meeting at shallow
angles are chopped off instead of producing long pointed corners.

The default miter limit is 10.0 (approximately 11.5 degree cutoff angle).
The smaller the limit, the larger the cutoff angle.

If no C<$ratio> is given, the current setting is B<returned>. If the ratio is
being set, C<$self> is B<returned> so that calls may be chained.

B<Alternate name:> C<miter_limit>

This is provided for compatibility with PDF::API2.
Long ago, in a distant galaxy, this method was misnamed I<meterlimit>, but
that was removed a while ago. Any code using that name should be updated!

=back

=cut

sub _miterlimit {
    my ($ratio) = @_;

    return ($ratio, 'M');
}

sub miter_limit { return miterlimit(@_); } ## no critic

sub miterlimit {
    my ($self, $ratio) = @_;

    if (!defined $ratio) {
	return $self->{' miterlimit'};
    }
    $self->add(_miterlimit($ratio));
    $self->{' miterlimit'} = $ratio;

    return $self;
}

# Note: miterlimit was originally named incorrectly to meterlimit, renamed.
# is available in PDF::API2

=head3 linedash, line_dash_pattern

    $content->linedash()

    $content->linedash($length)

    $content->linedash($dash_length, $gap_length, ...)

    $content->linedash('pattern' => [$dash_length, $gap_length, ...], 'shift' => $offset)

=over

Sets the line dash pattern.

If called without any arguments, a solid line will be drawn.

If called with one argument, the dashes and gaps (strokes and
spaces) will have equal lengths.

If called with two or more arguments, the arguments represent
alternating dash and gap lengths.

If called with a hash of arguments, the I<pattern> array may have one or
more elements, specifying the dash and gap lengths. 
A dash phase may be set (I<shift>), which is a B<positive integer>
specifying the distance into the pattern at which to start the dashed line.
Note that if you wish to give a I<shift> amount, using C<shift>,
you need to use C<pattern> instead of one or two elements.

If an B<odd> number of dash array elements are given, the list is repeated by 
the reader software to form an even number of elements (pairs). 

If a single argument of B<-1> is given, the current setting is B<returned>. 
This is an array consisting of two elements: an anonymous array containing the 
dash pattern (default: empty), and the shift (offset) amount (default: 0). 
It may be used directly in a linedash() call, as linedash will recognize the 
special pattern [ array, number ].

If the dash pattern is being I<set>, C<$self> is B<returned> so that calls may 
be chained.

B<Alternate name:> C<line_dash_pattern>

This is provided for compatibility with PDF::API2.

=back

=cut

sub _linedash {
    my ($self, @pat) = @_;

    unless (@pat) {  # no args
        $self->{' linedash'} = [[],0];
        return ('[', ']', '0', 'd');
    } else {
        if ($pat[0] =~ /^\-?pattern/ || $pat[0] =~ /^\-?shift/) {
            my %pat = @pat;
	    # copy dashed option names to preferred undashed names
	    if (defined $pat{'-pattern'} && !defined $pat{'pattern'}) { $pat{'pattern'} = delete($pat{'-pattern'}); }
	    if (defined $pat{'-shift'} && !defined $pat{'shift'}) { $pat{'shift'} = delete($pat{'-shift'}); }

            # Note: use pattern to replace the old -full and -clear options
	    #     which are NOT implemented
            $self->{' linedash'} = [[@{$pat{'pattern'}}],($pat{'shift'} || 0)];
            return ('[', floats(@{$pat{'pattern'}}), ']', ($pat{'shift'} || 0), 'd');
        } else {
            $self->{' linedash'} = [[@pat],0];
            return ('[', floats(@pat), '] 0 d');
        }
    }
}

sub line_dash_pattern { return linedash(@_); } ## no critic

sub linedash {
    my ($self, @pat) = @_;

    # request existing pattern and offset?
    if (scalar @pat == 1 && $pat[0] == -1) {
	return @{$self->{' linedash'}};
    }
    # request to restore stored pattern and offset?
    if (scalar @pat == 2 && ref($pat[0]) eq 'ARRAY' && ref($pat[1]) eq '') {
        @{$self->{' linedash'}} = @pat;
	if (@{$pat[0]}) {
	    # not an empty array
	    return ('[', floats(@{$pat[0]}), '] ', $pat[1], ' d');
	} else {
	    return ('[ ] 0 d');
	}
    }
    # anything else, including empty pattern
    $self->add($self->_linedash(@pat));

    return $self;
}

=head3 flatness, flatness_tolerance

    $content->flatness($tolerance)

=over

I<(Advanced)> Sets the maximum variation in output pixels when drawing
curves. The defined range of C<$tolerance> is 0 to 100, with 0 meaning I<use 
the device default flatness>. According to the PDF specification, you should 
not try to force visible line segments (the curve's approximation); results 
will be unpredictable. Usually, results for different flatness settings will be 
indistinguishable to the eye.

The C<$tolerance> value is silently clamped to be between 0 and 100.

If no C<$tolerance> is given, the current setting is B<returned>. If the 
tolerance is being set, C<$self> is B<returned> so that calls may be chained.

B<Alternate name:> C<flatness_tolerance>

This is provided for compatibility with PDF::API2.

=back

=cut

sub _flatness {
    my ($tolerance) = @_;

    if ($tolerance < 0  ) { $tolerance = 0;   }
    if ($tolerance > 100) { $tolerance = 100; }
    return ($tolerance, 'i');
}

sub flatness_tolerance { return flatness(@_); } ## no critic

sub flatness {
    my ($self, $tolerance) = @_;

    if (!defined $tolerance) {
	return $self->{' flatness'};
    }
    $self->add(_flatness($tolerance));
    $self->{' flatness'} = $tolerance;

    return $self;
}

=head3 egstate

    $content->egstate($object)

=over

I<(Advanced)> Adds an Extended Graphic State B<object> containing additional
state parameters.

=back

=cut

sub egstate {
    my ($self, $egs) = @_;

    $self->add('/' . $egs->name(), 'gs');
    $self->resource('ExtGState', $egs->name(), $egs);

    return $self;
}

=head2 Path Construction (Drawing)

=head3 move

    $content->move($x,$y)

=over

Starts a new path at the specified coordinates.
Note that multiple x,y pairs I<can> be given, although this isn't that useful
(only the last pair would have an effect).

=back

=cut

sub _move {
    my ($x,$y) = @_;

    return (floats($x,$y), 'm');
}

sub move {
    my ($self) = shift;

    $self->_Gpending();
    my ($x,$y);
    while (scalar @_ >= 2) {
        $x = shift;
        $y = shift;
        $self->{' mx'} = $x;
        $self->{' my'} = $y;
        if ($self->_in_text_object()) {
            $self->add_post(floats($x,$y), 'm');
        } else {
            $self->add(floats($x,$y), 'm');
        }
        $self->{' x'}  = $x;  # set new current position
        $self->{' y'}  = $y;
    }
   #if (@_) {   # normal practice is to discard unused values
   #    warn "extra coordinate(s) ignored in move\n";
   #}

    return $self;
}

=head3 close

    $content->close()

=over

Closes and ends the current path by extending a line from the current
position to the starting position.

=back

=cut

sub close {
    my ($self) = shift;

    $self->add('h');
    $self->{' x'} = $self->{' mx'};
    $self->{' y'} = $self->{' my'};

    return $self;
}

=head3 Straight line constructs

B<Note:> None of these will actually be I<visible> until you call C<stroke>, 
C<fill>, or C<fillstroke>. They are merely setting up the path to draw.

=head4 line

    $content->line($x,$y)

    $content->line($x,$y, $x2,$y2,...)

=over

Extends the path in a line from the I<current> coordinates to the
specified coordinates, and updates the current position to be the new
coordinates.

Multiple additional C<[$x,$y]> pairs are permitted, to draw joined multiple 
line segments. Note that this is B<not> equivalent to a polyline (see C<poly>),
because the first C<[$x,$y]> pair in a polyline is a I<move> operation.
Also, the C<linecap> setting will be used rather than the C<linejoin>
setting for treating the ends of segments.

=back

=cut

sub _line {
    my ($x,$y) = @_;

    return (floats($x,$y), 'l');
}

sub line {
    my ($self) = shift;

    $self->_Gpending();
    my ($x,$y);
    while (scalar @_ >= 2) {
        $x = shift;
        $y = shift;
        if ($self->_in_text_object()) {
            $self->add_post(floats($x,$y), 'l');
        } else {
            $self->add(floats($x,$y), 'l');
        }
        $self->{' x'} = $x;   # new current point
        $self->{' y'} = $y;
    }
   #if (@_) {    leftovers ignored, as is usual practice
   #    warn "line() has leftover coordinate (ignored).";
   #}

    return $self;
}

=head4 hline, vline

    $content->hline($x)

    $content->vline($y)

=over

Shortcuts for drawing horizontal and vertical lines from the current
position. They are like C<line()>, but to the new x and current y (C<hline>),
or to the the current x and new y (C<vline>).

=back

=cut

sub hline {
    my ($self, $x) = @_;

    $self->_Gpending();
    if ($self->_in_text_object()) {
        $self->add_post(floats($x, $self->{' y'}), 'l');
    } else {
        $self->add(floats($x, $self->{' y'}), 'l');
    }
    # extraneous inputs discarded
    $self->{' x'} = $x;   # update current position

    return $self;
}

sub vline {
    my ($self, $y) = @_;

    $self->_Gpending();
    if ($self->_in_text_object()) {
        $self->add_post(floats($self->{' x'}, $y), 'l');
    } else {
        $self->add(floats($self->{' x'}, $y), 'l');
    }
    # extraneous inputs discarded
    $self->{' y'} = $y;   # update current position

    return $self;
}

=head4 polyline

    $content->polyline($x1,$y1, ..., $xn,$yn)

=over

This is a shortcut for creating a polyline path from the current position. It 
extends the path in line segments along the specified coordinates.
The current position is changed to the last C<[$x,$y]> pair given.

A critical distinction between the C<polyline> method and the C<poly> method 
is that in this (C<polyline>), the first pair of coordinates are treated as a
I<draw> order (unlike the I<move> order in C<poly>).

Thus, while this is provided for compatibility with PDF::API2, it is I<not>
really an alias or alternate name for C<poly>!

=back

=cut

# TBD document line_join vs line_cap? (see poly()). perhaps demo in Content.pl?
sub polyline {
    my $self = shift();
    unless (@_ % 2 == 0) {
        croak 'polyline requires pairs of coordinates';
    }

    $self->_Gpending();
    while (@_) {
        my $x = shift();
        my $y = shift();
        $self->line($x, $y);
    }

    return $self;
}

=head4 poly

    $content->poly($x1,$y1, ..., $xn,$yn)

=over

This is a shortcut for creating a polyline path. It moves to C<[$x1,$y1]>, and
then extends the path in line segments along the specified coordinates.
The current position is changed to the last C<[$x,$y]> pair given.

The difference between a polyline and a C<line> with multiple C<[$x,$y]>
pairs is that the first pair in a polyline are a I<move>, while in a line
they are a I<draw>.
Also, C<line_join> instead of C<line_cap> is used to control the appearance
of the ends of line segments.

A critical distinction between the C<polyline> method and the C<poly> method 
is that in this (C<poly>), the first pair of coordinates are treated as a
I<move> order.

=back

=cut

sub poly {
    # not implemented as self,x,y = @_, as @_ must be shifted
    my ($self) = shift;
    my $x      = shift;
    my $y      = shift;

    $self->_Gpending();
    $self->move($x,$y);
    $self->line(@_);

    return $self;
}

=head4 rectangle

    $content = $content->rectangle($x1, $y1, $x2, $y2)

=over

Creates a new rectangle-shaped path, between the two corner points C<[$x1, $y1]>
and C<[$x2, $y2]>. The corner points are swapped if necessary, to make
"1" the lower left and "2" the upper right (x2 > x1 and y2 > y1).
The object (here, C<$content>) is returned, to permit chaining.

B<Note> that this is I<not> an alias or alternate name for C<rect>. It handles
only one rectangle, and takes corner coordinates for corner "2", rather than
the width and height.

=back

=cut

sub rectangle {
    my ($self, $x1, $y1, $x2, $y2) = @_;

    # Ensure that x1,y1 is lower-left and x2,y2 is upper-right
    # swap corners if necessary
    if ($x2 < $x1) {
        my $x = $x1;
        $x1 = $x2;
        $x2 = $x;
    }
    if ($y2 < $y1) {
        my $y = $y1;
        $y1 = $y2;
        $y2 = $y;
    }

    $self->_Gpending();
    $self->add(floats($x1, $y1, ($x2 - $x1), ($y2 - $y1)), 're');
    $self->{' x'} = $x1;
    $self->{' y'} = $y1;

    return $self;
}

=head4 rect

    $content = $content->rect($x,$y, $w,$h)

    $content = $content->rect($x1,$y1, $w1,$h1, ..., $xn,$yn, $wn,$hn)

=over

This creates paths for one or more rectangles, with their lower left points
at C<[$x,$y]> and specified widths (+x direction) and heights (+y direction). 
Negative widths and heights are permitted, which draw to the left (-x) and 
below (-y) the given corner point, respectively. 
The current position is changed to the C<[$x,$y]> of the last rectangle given.
Note that this is the I<starting> point of the rectangle, not the end point.
The object (here, C<$content>) is returned, to permit chaining.

B<Note> that this differs from the C<rectangle> method in that multiple
rectangles may be drawn in one call, and the second pair for each rectangle
are the width and height, not the opposite corner coordinates. 

=back

=cut

sub rect {
    my $self = shift;

    my ($x,$y, $w,$h);
    $self->_Gpending();
    while (scalar @_ >= 4) {
        $x = shift;
        $y = shift;
        $w = shift;
        $h = shift;
        $self->add(floats($x,$y, $w,$h), 're');
    }
   #if (@_) {   # usual practice is to ignore extras
   #    warn "rect() extra coordinates discarded.\n";
   #}
    $self->{' x'} = $x;   # set new current position
    $self->{' y'} = $y;

    return $self;
}

=head4 rectxy

    $content->rectxy($x1,$y1, $x2,$y2)

=over

This creates a rectangular path, with C<[$x1,$y1]> and C<[$x2,$y2]>
specifying I<opposite> corners. They can be Lower Left and Upper Right,
I<or> Upper Left and Lower Right, in either order, so long as they are
diagonally opposite each other. 
The current position is changed to the C<[$x1,$y1]> (first) pair.

This is not I<quite> an alias or alternate name for C<rectangle>, as it 
permits the corner points to be specified in any order.

=back

=cut

# TBD allow multiple rectangles, as in rect()

sub rectxy {
    my ($self, $x,$y, $x2,$y2) = @_;

   #$self->_Gpending();  unnecessary, handled by rect()
    $self->rect($x,$y, ($x2-$x),($y2-$y));

    return $self;
}

=head3 Curved line constructs

B<Note:> None of these will actually be I<visible> until you call C<stroke>,
C<fill>, or C<fillstroke>. They are merely setting up the path to draw.

=head4 circle

    $content->circle($xc,$yc, $radius)

=over

This creates a circular path centered on C<[$xc,$yc]> with the specified
radius. It does B<not> change the current position.

=back

=cut

sub circle {
    my ($self, $xc,$yc, $r) = @_;

    $self->_Gpending();
    $self->arc($xc,$yc, $r,$r, 0,360, 1);
    $self->close();

    return $self;
}

=head4 ellipse

    $content->ellipse($xc,$yc, $rx,$ry)

=over

This creates a closed elliptical path centered on C<[$xc,$yc]>, with axis radii
(semidiameters) specified by C<$rx> (x axis) and C<$ry> (y axis), respectively.
It does not change the current position.

=back

=cut

sub ellipse {
    my ($self, $xc,$yc, $rx,$ry) = @_;

    $self->_Gpending();
    $self->arc($xc,$yc, $rx,$ry, 0,360, 1);
    $self->close();

    return $self;
}

# input: x and y axis radii
#        sweep start and end angles
#        sweep direction (0=CCW (default), or 1=CW)
# output: two endpoints and two control points for
#           the Bezier curve describing the arc
# maximum 30 degrees of sweep: is broken up into smaller
#   arc segments if necessary
# if crosses 0 degree angle in either sweep direction, split there at 0
# if alpha=beta (0 degree sweep) or either radius <= 0, fatal error
sub _arctocurve {
    my ($rx,$ry, $alpha,$beta, $dir) = @_;

    if (!defined $dir) { $dir = 0; }  # default is CCW sweep
    # check for non-positive radius
    if ($rx <= 0 || $ry <= 0) {
	die "curve request with radius not > 0 ($rx, $ry)";
    }
    # check for zero degrees of sweep
    if ($alpha == $beta) {
	die "curve request with zero degrees of sweep ($alpha to $beta)";
    }

    # constrain alpha and beta to 0..360 range so 0 crossing check works
    while ($alpha < 0.0)   { $alpha += 360.0; }
    while ( $beta < 0.0)   {  $beta += 360.0; }
    while ($alpha > 360.0) { $alpha -= 360.0; }
    while ( $beta > 360.0) {  $beta -= 360.0; }

    # Note that there is a problem with the original code, when the 0 degree
    # angle is crossed. It especially shows up in arc() and pie(). Therefore, 
    # split the original sweep at 0 degrees, if it crosses that angle.
    if (!$dir && $alpha > $beta) { # CCW pass over 0 degrees
      if      ($alpha == 360.0 && $beta == 0.0) { # oddball case
        return (_arctocurve($rx,$ry, 0.0,360.0, 0));
      } elsif ($alpha == 360.0) { # alpha to 360 would be null
        return (_arctocurve($rx,$ry, 0.0,$beta, 0));
      } elsif ($beta == 0.0) { # 0 to beta would be null
        return (_arctocurve($rx,$ry, $alpha,360.0, 0));
      } else {
        return (
            _arctocurve($rx,$ry, $alpha,360.0, 0),
            _arctocurve($rx,$ry, 0.0,$beta, 0)
        );
      }
    }
    if ($dir && $alpha < $beta) { # CW pass over 0 degrees
      if      ($alpha == 0.0 && $beta == 360.0) { # oddball case
        return (_arctocurve($rx,$ry, 360.0,0.0, 1));
      } elsif ($alpha == 0.0) { # alpha to 0 would be null
        return (_arctocurve($rx,$ry, 360.0,$beta, 1));
      } elsif ($beta == 360.0) { # 360 to beta would be null
        return (_arctocurve($rx,$ry, $alpha,0.0, 1));
      } else {
        return (
            _arctocurve($rx,$ry, $alpha,0.0, 1),
            _arctocurve($rx,$ry, 360.0,$beta, 1)
        );
      }
    }

    # limit arc length to 30 degrees, for reasonable smoothness
    # none of the long arcs or short resulting arcs cross 0 degrees
    if (abs($beta-$alpha) > 30) {
        return (
            _arctocurve($rx,$ry, $alpha,($beta+$alpha)/2, $dir),
            _arctocurve($rx,$ry, ($beta+$alpha)/2,$beta, $dir)
        );
    } else {
       # Note that we can't use deg2rad(), because closed arcs (circle() and 
       # ellipse()) are 0-360 degrees, which deg2rad treats as 0-0 radians!
        $alpha = ($alpha * pi / 180);
        $beta  = ($beta * pi / 180);

        my $bcp = (4.0/3 * (1 - cos(($beta - $alpha)/2)) / sin(($beta - $alpha)/2));
        my $sin_alpha = sin($alpha);
        my $sin_beta  = sin($beta);
        my $cos_alpha = cos($alpha);
        my $cos_beta  = cos($beta);

        my $p0_x = $rx * $cos_alpha;
        my $p0_y = $ry * $sin_alpha;
        my $p1_x = $rx * ($cos_alpha - $bcp * $sin_alpha);
        my $p1_y = $ry * ($sin_alpha + $bcp * $cos_alpha);
        my $p2_x = $rx * ($cos_beta  + $bcp * $sin_beta);
        my $p2_y = $ry * ($sin_beta  - $bcp * $cos_beta);
        my $p3_x = $rx * $cos_beta;
        my $p3_y = $ry * $sin_beta;

        return ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
    }
}

=head4 arc

    $content->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move, $dir)

    $content->arc($xc,$yc, $rx,$ry, $alpha,$beta, $move)

=over

This extends the path along an arc of an ellipse centered at C<[$xc,$yc]>.
The semidiameters of the elliptical curve are C<$rx> (x axis) and C<$ry> 
(y axis), respectively, and the arc sweeps from C<$alpha> degrees to C<$beta>
degrees. The current position is then set to the endpoint of the arc.

Set C<$move> to a I<true> value if this arc is the beginning of a new
path instead of the continuation of an existing path. Either way, the 
current position will be updated to the end of the arc.
Use C<$rx == $ry> for a circular arc.

The optional C<$dir> arc sweep direction defaults to 0 (I<false>), for a
counter-clockwise/anti-clockwise sweep. Set to 1 (I<true>) for a clockwise
sweep.

=back

=cut

sub arc {
    my ($self, $xc,$yc, $rx,$ry, $alpha,$beta, $move, $dir) = @_;

    if (!defined $dir) { $dir = 0; }
    my @points = _arctocurve($rx,$ry, $alpha,$beta, $dir);
    my ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);

    $self->_Gpending();
    $p0_x = $xc + shift @points;
    $p0_y = $yc + shift @points;

    $self->move($p0_x,$p0_y) if $move;

    while (scalar @points >= 6) {
        $p1_x = $xc + shift @points;
        $p1_y = $yc + shift @points;
        $p2_x = $xc + shift @points;
        $p2_y = $yc + shift @points;
        $p3_x = $xc + shift @points;
        $p3_y = $yc + shift @points;
        $self->curve($p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
        shift @points;
        shift @points;
        $self->{' x'} = $p3_x;   # set new current position
        $self->{' y'} = $p3_y;
    }
    # should we worry about anything left over in @points?
    # supposed to be blocks of 8 (4 points)

    return $self;
}

=head4 pie

    $content->pie($xc,$yc, $rx,$ry, $alpha,$beta, $dir)

    $content->pie($xc,$yc, $rx,$ry, $alpha,$beta)

=over

Creates a pie-shaped path from an ellipse centered on C<[$xc,$yc]>.
The x-axis and y-axis semidiameters of the ellipse are C<$rx> and C<$ry>,
respectively, and the arc sweeps from C<$alpha> degrees to C<$beta>
degrees. 
It does not change the current position.
Depending on the sweep angles and direction, this can draw either the
pie "slice" or the remaining pie (with slice removed).
Use C<$rx == $ry> for a circular pie.
Use a different C<[$xc,$yc]> for the slice, to offset it from the remaining pie.

The optional C<$dir> arc sweep direction defaults to 0 (I<false>), for a
counter-clockwise/anti-clockwise sweep. Set to 1 (I<true>) for a clockwise
sweep.

This is a shortcut to draw a section of elliptical (or circular) arc and
connect it to the center of the ellipse or circle, to form a pie shape.

=back

=cut

sub pie {
    my ($self, $xc,$yc, $rx,$ry, $alpha,$beta, $dir) = @_;

    if (!defined $dir) { $dir = 0; }
    my ($p0_x,$p0_y) = _arctocurve($rx,$ry, $alpha,$beta, $dir);
   #$self->_Gpending();  move() will take care of this
    $self->move($xc,$yc);
    $self->line($p0_x+$xc, $p0_y+$yc);
    $self->arc($xc,$yc, $rx,$ry, $alpha,$beta, 0, $dir);
    $self->close();

    return $self;
}

=head4 curve

    $content->curve($cx1,$cy1, $cx2,$cy2, $x,$y)

=over

This extends the path in a curve from the current point to C<[$x,$y]>,
using the two specified I<control> points to create a B<cubic Bezier curve>, and
updates the current position to be the new point (C<[$x,$y]>).

Within a B<text> object, the text's baseline follows the Bezier curve.

Note that while multiple sets of three C<[x,y]> pairs are permitted, these
are treated as I<independent> cubic Bezier curves. There is no attempt made to
smoothly blend one curve into the next!

=back

=cut

sub curve {
    my ($self) = shift;

    my ($cx1,$cy1, $cx2,$cy2, $x,$y);
    $self->_Gpending();
    while (scalar @_ >= 6) {
        $cx1 = shift;
        $cy1 = shift;
        $cx2 = shift;
        $cy2 = shift;
        $x   = shift;
        $y   = shift;
        if ($self->_in_text_object()) {
            $self->add_post(floats($cx1,$cy1, $cx2,$cy2, $x,$y), 'c');
        } else {
            $self->add(floats($cx1,$cy1, $cx2,$cy2, $x,$y), 'c');
        }
        $self->{' x'} = $x;   # set new current position
        $self->{' y'} = $y;
    }

    return $self;
}

=head4 qbspline, spline

    $content->qbspline($cx1,$cy1, $x,$y)

=over

This extends the path in a curve from the current point to C<[$x,$y]>,
using the two specified points to create a quadratic Bezier curve, and updates 
the current position to be the new point.

Internally, these splines are one or more cubic Bezier curves (see C<curve>) 
with the two control points synthesized from the two given points (a control 
point and the end point of a I<quadratic> Bezier curve).

Note that while multiple sets of two C<[x,y]> pairs are permitted, these
are treated as I<independent> quadratic Bezier curves. There is no attempt 
made to smoothly blend one curve into the next!

Further note that this "spline" does not match the common definition of
a spline being a I<continuous> curve passing I<through> B<all> the given 
points! It is a piecewise non-continuous cubic Bezier curve. Use with care, and 
do not make assumptions about splines for you or your readers. You may wish
to use the C<bspline> call to have a continuously smooth spline to pass through
all given points.

Pairs of points (control point and end point) are consumed in a loop. If one 
point or coordinate is left over at the end, it is discarded (as usual practice
for excess data to a routine). There is no check for duplicate points or other 
degeneracies.

B<Alternate name:> C<spline>

This method is still named C<spline> in PDF::API2, so for compatibility, that
name is usable here. Since there are both quadratic and cubic splines available
in PDF, it is preferred to use more descriptive names such as C<qbspline> and
C<cbspline> to minimize confusion.

=back

=cut

sub spline { return qbspline(@_); } ## no critic

sub qbspline {
    my ($self) = shift;

   #$self->_Gpending();  curve() will take care of this
    while (scalar @_ >= 4) {
        my $cx = shift;  # single Control Point
        my $cy = shift;
        my $x = shift;   # new end point
        my $y = shift;
	# synthesize 2 cubic Bezier control points from two given points
        my $c1x = (2*$cx + $self->{' x'})/3;
        my $c1y = (2*$cy + $self->{' y'})/3;
        my $c2x = (2*$cx + $x)/3;
        my $c2y = (2*$cy + $y)/3;
        $self->curve($c1x,$c1y, $c2x,$c2y, $x,$y);
    }
   ## one left over point? straight line (silent error recovery)
   #if (scalar @_ >= 2) {
   #    my $x = shift;   # new end point
   #    my $y = shift;
   #    $self->line($x,$y);
   #}
   #if (@_) {    leftovers ignored, as is usual practice
   #    warn "qbspline() has leftover coordinate (ignored).";
   #}

    return $self;
}

=head4 bspline, cbspline

    $content->bspline($ptsRef, %opts)

=over

This extends the path in a curve from the current point to the end of a list
of coordinate pairs in the array referenced by C<$ptsRef>. Smoothly continuous
cubic Bezier splines are used to create a curve that passes through I<all>
the given points. Multiple control points are synthesized; they are not 
supplied in the call. The current position is updated to the last point.

Internally, these splines are one cubic Bezier curve (see C<curve>) per pair
of input points, with the two control points synthesized from the tangent 
through each point as set by the polyline that would connect each point to its
neighbors. The intent is that the resulting curve should follow reasonably 
closely a polyline that would connect the points, and should avoid any major 
excursions. See the discussions below for the handling of the control points
at the endpoints (current point and last input point). The point at the end
of the last line or curve drawn becomes the new current point.

Options %opts:

=back

=over

=item 'firstseg' => 'I<mode>'

where I<mode> is 

=over

=item curve

This is the B<default> behavior.
This forces the first segment (from the current point to the first given point)
to be drawn as a cubic Bezier curve. This means that the direction of the curve
coming off the current point is unconstrained (it will end up being a reflection
of the tangent at the first given point).

=item line1

This forces the first segment (from the current point to the first given point)
to be drawn as a curve, with the tangent at the current point to be constrained 
as parallel to the polyline segment. 

=item line2

This forces the first segment (from the current point to the first given point)
to be drawn as a line segment. This also sets the tangent through the first
given point as a continuation of the line, as well as constraining the direction
of the line at the current point.

=item constraint1

This forces the first segment (from the current point to the first given point)
to B<not> be drawn, but to be an invisible curve (like mode=line1) to leave
the tangent at the first given point unconstrained. A I<move> will be made to 
the first given point, and the current point is otherwise ignored.

=item constraint2

This forces the first segment (from the current point to the first given point)
to B<not> be drawn, but to be an invisible line (like mode=line2) to constrain
the tangent at the first given point. A I<move> will be made to the first given
point, and the current point is otherwise ignored.

=back

=item 'lastseg' => 'I<mode>'

where I<mode> is 

=over

=item curve

This is the B<default> behavior.
This forces the last segment (to the last given input point)
to be drawn as a cubic Bezier curve. This means that the direction of the curve
going to the last point is unconstrained (it will end up being a reflection
of the tangent at the next-to-last given point).

=item line1

This forces the last segment (to the last given input point) to be drawn as a 
curve with the the tangent through the last given point parallel to the 
polyline segment, thus constraining the direction of the line at the last 
point.

=item line2

This forces the last segment (to the last given input point)
to be drawn as a line segment. This also sets the tangent through the 
next-to-last given point as a back continuation of the line, as well as 
constraining the direction of the line at the last point.

=item constraint1

This forces the last segment (to the last given input point)
to B<not> be drawn, but to be an invisible curve (like mode=line1) to leave
the tangent at the next-to-last given point unconstrained. The last given 
input point is ignored, and next-to-last point becomes the new current point.

=item constraint2

This forces the last segment (to the last given input point)
to B<not> be drawn, but to be an invisible line (like mode=line2) to constrain
the tangent at the next-to-last given point. The last given input point is
ignored, and next-to-last point becomes the new current point.

=back

=item 'ratio' => I<n>

I<n> is the ratio of the length from a point to a control point to the length
of the polyline segment on that side of the given point. It must be greater
than 0.1, and the default is 0.3333 (1/3).

=item 'colinear' => 'I<mode>'

This describes how to handle the middle segment when there are four or more 
colinear points in the input set. A I<mode> of 'line' specifies that a line 
segment will be drawn between each of the interior colinear points. A I<mode> 
of 'curve' (this is the default) will draw a Bezier curve between each of those 
points.

C<colinear> applies only to interior runs of colinear points, between curves. 
It does not apply to runs at the beginning or end of the point list, which are
drawn as line segments or linear constraints regardless of I<firstseg> and 
I<lastseg> settings.

=item 'debug' => I<N>

If I<N> is 0 (the default), only the spline is returned. If it is greater than
0, a number of additional items will be drawn: (N>0) the points, (N>1) a green 
solid polyline connecting them, (N>2) blue original tangent lines at each 
interior point, and (N>3) red dashed lines and hollow points representing the 
Bezier control points.

=back

=over

B<Special cases>

Adjacent points which are duplicates are consolidated. 
An extra coordinate at the end of the input point list (not a full 
C<[x,y]> pair) will, as usual, be ignored.

=back

=over

=item 0 given points (after duplicate consolidation)

This leaves only the current point (unchanged), so it is a no-op.

=item 1 given point (after duplicate consolidation)

This leaves the current point and one point, so it is rendered as a line,
regardless of %opt flags.

=item 2 given points (after duplicate consolidation)

This leaves the current point, an intermediate point, and the end point. If
the three points are colinear, two line segments will be drawn. Otherwise, both
segments are curves (through the tangent at the intermediate point). If either
end segment mode is requested to be a line or constraint, it is treated as a 
B<line1> mode request instead. 

=item I<N> colinear points at beginning or end 

I<N> colinear points at beginning or end of the point set causes I<N-1> line 
segments (C<line2> or C<constraint2>, regardless of the settings of 
C<firstseg>, C<lastseg>, and C<colinear>.

=back

=over

B<Alternate name:> C<cbspline>

This is to emphasize that it is a I<cubic> Bezier spline, as opposed to a
I<quadratic> Bezier spline (see C<qbspline> above).

=back

=cut

sub cbspline { return bspline(@_); } ## no critic

sub bspline {
    my ($self, $ptsRef, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-firstseg'} && !defined $opts{'firstseg'}) { $opts{'firstseg'} = delete($opts{'-firstseg'}); }
    if (defined $opts{'-lastseg'} && !defined $opts{'lastseg'}) { $opts{'lastseg'} = delete($opts{'-lastseg'}); }
    if (defined $opts{'-ratio'} && !defined $opts{'ratio'}) { $opts{'ratio'} = delete($opts{'-ratio'}); }
    if (defined $opts{'-colinear'} && !defined $opts{'colinear'}) { $opts{'colinear'} = delete($opts{'-colinear'}); }
    if (defined $opts{'-debug'} && !defined $opts{'debug'}) { $opts{'debug'} = delete($opts{'-debug'}); }

    my @inputPts = @$ptsRef;
    my ($firstseg, $lastseg, $ratio, $colinear, $debug);
    my (@oldColor, @oldFill, $oldWidth, @oldDash);
    # specific treatment of the first and last segments of the spline
    # code will be checking for line[12] and constraint[12], and assume it's
    # 'curve' if nothing else matches (silent error)
    if (defined $opts{'firstseg'}) {
	$firstseg = $opts{'firstseg'};
    } else {
	$firstseg = 'curve';
    }
    if (defined $opts{'lastseg'}) {
	$lastseg = $opts{'lastseg'};
    } else {
	$lastseg = 'curve';
    }
    # ratio of the length of a Bezier control point line to the distance
    # between the points
    if (defined $opts{'ratio'}) {
        $ratio = $opts{'ratio'};
	# clamp it (silent error) to be >0.1. probably no need to limit high end
	if ($ratio <= 0.1) { $ratio = 0.1; }
    } else {
	$ratio = 0.3333;  # default
    }
    # colinear points (4 or more) draw a line instead of a curve
    if (defined $opts{'colinear'}) {
	$colinear = $opts{'colinear'}; # 'line' or 'curve'
    } else {
	$colinear = 'curve';  # default
    }
    # debug options to draw out intermediate stages
    if (defined $opts{'debug'}) {
	$debug = $opts{'debug'};
    } else {
	$debug = 0;  # default
    }

    $self->_Gpending();
    # copy input point list pairs, checking for duplicates
    my (@inputs, $x,$y);
    @inputs = ([$self->{' x'}, $self->{' y'}]); # initialize to current point
    while (scalar(@inputPts) >= 2) {
	$x = shift @inputPts;
	$y = shift @inputPts;
	push @inputs, [$x, $y];
	# eliminate duplicate point just added
        if ($inputs[-2][0] == $inputs[-1][0] &&
            $inputs[-2][1] == $inputs[-1][1]) {
	    # duplicate
	    pop @inputs; 
	}
    }
   #if (@inputPts) {    leftovers ignored, as is usual practice
   #    warn "bspline() has leftover coordinate (ignored).";
   #}

    # handle special cases of 1, 2, or 3 points in @inputs
    if      (scalar @inputs == 1) {
	# only current point in list: no-op
	return $self;
    } elsif (scalar @inputs == 2) {
	# just two points: draw a line
	$self->line($inputs[1][0],$inputs[1][1]);
	return $self;
    } elsif (scalar @inputs == 3) {
	# just 3 points: adjust flags
	if ($firstseg ne 'curve') { $firstseg = 'line1'; }
	if ($lastseg ne 'curve') { $lastseg = 'line1'; }
	# note that if colinear, will become line2 for both
    } 

    # save existing settings if debug draws anything
    if ($debug > 0) {
	@oldColor = $self->strokecolor();
	@oldFill  = $self->fillcolor();
        $oldWidth = $self->linewidth();
	@oldDash  = $self->linedash(-1);
    }
    # initialize working arrays
    #  dx,dy are unit vector (sum of squares is 1)
    #   polyline [n][0] = dx, [n][1] = dy, [n][2] = length for segment between
    #     points n and n+1
    #   colinpt [n] = 0 if not, 1 if it is interior colinear point
    #   type [n] = 0 it's a Bezier curve, 1 it's a line between pts n, n+1
    #              2 it's a curve constraint (not drawn), 3 line constraint ND
    #   tangent [n][0] = dx, [n][1] = dy for tangent line direction (forward)
    #     at point n
    #   cp [n][0][0,1] = dx,dy direction to control point "before" point n
    #            [2] = distance from point n to this control point
    #         [1]  likewise for control point "after" point n
    #     n=0 doesn't use "before" and n=last doesn't use "after"
    #
    # every time a tangent is set, also set the cp unit vectors, so nothing
    # is overlooked, even if a tangent may be changed later
    my ($i,$j,$k, $l, $dx,$dy, @polyline, @colinpt, @type, @tangent, @cp);
    my $last = $#inputs; # index number of last point (first is 0)

    for ($i=0; $i<=$last; $i++) {  # through all points
	$polyline[$i] = [0,0,0];
	if ($i < $last) {  # polyline[i] is line point i to i+1
	    $dx = $inputs[$i+1][0] - $inputs[$i][0];
	    $dy = $inputs[$i+1][1] - $inputs[$i][1];
	    $polyline[$i][2] = $l = sqrt($dx*$dx + $dy*$dy);
            $polyline[$i][0] = $dx/$l;
            $polyline[$i][1] = $dy/$l;
	}

	$colinpt[$i] = 0; # default: not colinear at this point i
	$type[$i] = 0;    # default: using a curve at this point i to i+1
	                  # N/A if i=last, will ignore
	if ($i > 0 && $i < $last) { # colinpt... look at polyline unit vectors
		                    # of lines coming into and out of point i
	    if ($polyline[$i-1][0] == $polyline[$i][0] &&
		$polyline[$i-1][1] == $polyline[$i][1]) {
		$colinpt[$i] = 1; # same unit vector at prev point
		                  # so point is colinear (inside run)
		# set type[i] even if may change later
		if ($i == 1) {
		    # point 1 is colinear? force line2 or constraint2
		    if ($firstseg =~ m#^constraint#) {
		        $firstseg = 'constraint2';
			$type[0] = 3;
		    } else {
		        $firstseg = 'line2';
			$type[0] = 1;
		    }
		    $colinpt[0] = 1; # if 1 is colinear, so is 0
		    $type[1] = 1;
		}
		if ($i == $last-1) {
		    # point last-1 is colinear? force line2 or constraint2
		    if ($lastseg =~ m#^constraint#) {
		        $lastseg = 'constraint2';
			$type[$i] = 3;
		    } else {
		        $lastseg = 'line2';
			$type[$i] = 1;
		    }
		    $colinpt[$last] = 1; # if last-1 is colinear, so is last
		    $type[$last-2] = 1;
		}
	    } # it is colinear
	}  # looking for colinear interior points
	# if 3 or more colinear points at beginning or end, handle later

	$tangent[$i] = [0,0];  # set tangent at each point
	# endpoints & interior colinear points just use the polyline they're on
        #
	# at point $i, [0 1] "before" for previous curve and "after"
	# each [dx, dy, len] from this point to control point
	$cp[$i] = [[0,0,0], [0,0,0]];
	# at least can set the lengths here. uvecs will be set to tangents,
	# even though some may be changed later
	
	if ($i > 0) { # do 'before' cp length
	    $cp[$i][0][2] = $polyline[$i-1][2] * $ratio;
	}
	if ($i < $last) { # do 'after' cp length
	    $cp[$i][1][2] = $polyline[$i][2] * $ratio;
	}

	if      ($i == 0 || $i < $last && $colinpt[$i]) {
	    $cp[$i][1][0] = $tangent[$i][0] = $polyline[$i][0];
	    $cp[$i][1][1] = $tangent[$i][1] = $polyline[$i][1];
	    if ($i > 0) { 
		$cp[$i][0][0] = -$cp[$i][1][0];
	        $cp[$i][0][1] = -$cp[$i][1][1]; 
	    }
	} elsif ($i == $last) {
	    $tangent[$i][0] = $polyline[$i-1][0];
	    $tangent[$i][1] = $polyline[$i-1][1];
	    $cp[$i][0][0] = -$tangent[$i][0];
	    $cp[$i][0][1] = -$tangent[$i][1];
	} else {
	    # for other points, add the incoming and outgoing polylines
	    # and normalize to unit length
	    $dx = $polyline[$i-1][0] + $polyline[$i][0];
	    $dy = $polyline[$i-1][1] + $polyline[$i][1];
	    $l = sqrt($dx*$dx + $dy*$dy);
	    # degenerate sequence A-B-A would give a length of 0, so avoid /0
	    # TBD: look at entry and exit curves to instead have assigned
	    #      tangent go left instead of right, to avoid in some cases a
	    #      twist in the loop
	    if ($l == 0) { 
		# still no direction to it. assign 90 deg right turn
		# on outbound A-B (at point B)
	        my $theta = atan2($polyline[$i-1][1], $polyline[$i-1][0]) - Math::Trig::pip2;
		$cp[$i][1][0] = $tangent[$i][0] = cos($theta);
		$cp[$i][1][1] = $tangent[$i][1] = sin($theta);
	    } else {
	        $cp[$i][1][0] = $tangent[$i][0] = $dx/$l;
	        $cp[$i][1][1] = $tangent[$i][1] = $dy/$l;
	    }
	    $cp[$i][0][0] = -$cp[$i][1][0];
	    $cp[$i][0][1] = -$cp[$i][1][1];
	}
    } # for loop to initialize all arrays

    # debug: show points, polyline, and original tangents
    if ($debug > 0) {
	$self->linedash();  # solid
        $self->linewidth(2);
	$self->strokecolor('green');
	$self->fillcolor('green');

	# points (debug = 1+)
	for ($i=0; $i<=$last; $i++) {
	    $self->circle($inputs[$i][0],$inputs[$i][1], 2);
	}
	$self->fillstroke();
	# polyline (@inputs not in correct format for poly() call)
	if ($debug > 1) {
	    $self->move($inputs[0][0], $inputs[0][1]);
	    for ($i=1; $i<=$last; $i++) {
		$self->line($inputs[$i][0], $inputs[$i][1]);
	    }
	    $self->stroke();
	    $self->fillcolor(@oldFill);
        }

	# original tangents (before adjustment)
	if ($debug > 2) {
	    $self->linewidth(1);
	    $self->strokecolor('blue');
	    for ($i=0; $i<=$last; $i++) {
	        $self->move($inputs[$i][0], $inputs[$i][1]);
	        $self->line($inputs[$i][0] + 20*$tangent[$i][0],
	                    $inputs[$i][1] + 20*$tangent[$i][1]);
	    }
	    $self->stroke();
	}

	# prepare for control points and dashed lines
	if ($debug > 3) {
	    $self->linedash(2);  # repeating 2 on 2 off (solid for points)
	    $self->linewidth(2); # 1 for points (circles)
	    $self->strokecolor('red');
	}
    } # debug dump of intermediate results
    # at this point, @tangent unit vectors need to be adjusted for several 
    # reasons, and @cp unit vectors need to await final tangent vectors.
    # @type is "displayed curve" (0) for all segments ex possibly first and last

    # follow colinear segments at beginning and end (not interior).
    # follow colinear segments from 1 to $last-1, and same $last-1 to 1,
    # setting type to 1 (line segment). once type set to non-zero, will
    # not revisit it. we should have at least 3 points ($last >= 2), and points
    # 0, 1, last-1, and last should already have been set. tangents already set.
    for ($i=1; $i<$last-1; $i++) {
	if ($colinpt[$i]) {
	    $type[$i] = 1;
	    $cp[$i+1][1][0] =  $tangent[$i+1][0] = $polyline[$i][0];
	    $cp[$i+1][1][1] =  $tangent[$i+1][1] = $polyline[$i][1];
	    $cp[$i+1][0][0] = -$tangent[$i+1][0];
	    $cp[$i+1][0][1] = -$tangent[$i+1][1];
	} else {
	    last;
        }
    }
    for ($i=$last-1; $i>1; $i--) {
	if ($colinpt[$i]) {
	    $type[$i-1] = 1;
	    $cp[$i-1][1][0] =  $tangent[$i-1][0] = $polyline[$i-1][0];
	    $cp[$i-1][1][1] =  $tangent[$i-1][1] = $polyline[$i-1][1];
	    $cp[$i-1][0][0] = -$tangent[$i-1][0];
	    $cp[$i-1][0][1] = -$tangent[$i-1][1];
	} else {
            last;
        }
    }

    # now the major work of deciding whether line segment or Bezier curve
    # at each polyline segment, and placing the control points for the curves
    #
    # handle first and last segments first, as they affect tangents.
    # then go through, setting colinear sections to lines if requested,
    # or setting tangents if curves. calculate all control points from final
    # tangents, and draw them if debug.
    my ($ptheta, $ttheta, $dtheta);
    # special treatments for first segment
    if      ($firstseg eq 'line1') {
	# Bezier curve from point 0 to 1, constrained to polyline at point 0
	# but no constraint on tangent at point 1.
	# should already be type 0 between points 0 and 1
	# point 0 tangent should already be on polyline segment
    } elsif ($firstseg eq 'line2') {
	# line drawn from point 0 to 1, constraining the tangent at point 1
	$type[0] = 1; # set to type 1 between points 0 and 1
	# no need to set tangent at point 0, or set control points
	$cp[1][1][0] = $tangent[1][0] = $polyline[0][0];
	$cp[1][1][1] = $tangent[1][1] = $polyline[0][1];
	$cp[1][0][0] = -$tangent[1][0];
	$cp[1][0][1] = -$tangent[1][1];
    } elsif ($firstseg eq 'constraint1') {
	# Bezier curve from point 0 to 1, constrained to polyline at point 0
	# (not drawn, allows unconstrained tangent at point 1)
	$type[0] = 2; 
	# no need to set after and before, as is not drawn
    } elsif ($firstseg eq 'constraint2') {
	# line from point 0 to 1 (not drawn, only sets tangent at point 1)
	$type[0] = 3;
	# no need to set before, as is not drawn and is line anyway
	$cp[1][1][0] = $tangent[1][0] = $polyline[0][0];
	$cp[1][1][1] = $tangent[1][1] = $polyline[0][1];
    } else { # 'curve'
	# Bezier curve from point 0 to 1. both ends unconstrained, at point 0
	# it is just a reflection of the tangent at point 1
       #$type[0] = 0; # should already be 0
	$ptheta = atan2($polyline[0][1], $polyline[0][0]);
	$ttheta = atan2(-$tangent[1][1], -$tangent[1][0]);
	$dtheta = _leftright($ptheta, $ttheta);
	$ptheta = atan2(-$polyline[0][1], -$polyline[0][0]);
	$ttheta = _sweep($ptheta, $dtheta);
	$cp[0][1][0] =  $tangent[0][0] = cos($ttheta); # also 'after' uvec at 0
	$cp[0][1][1] =  $tangent[0][1] = sin($ttheta);
    }
    # special treatments for last segment
    if      ($lastseg eq 'line1') {
	# Bezier curve from point last-1 to last, constrained to polyline at 
	# point last but no constraint on tangent at point last-1
	# should already be type 0 at last-1
	# point last tangent should already be on polyline segment
    } elsif ($lastseg eq 'line2') {
	# line drawn from point last-1 to last, constraining the tangent at point last-1
	$type[$last-1] = 1;
	# no need to set tangent at point last, or set control points at last
	$cp[$last-1][1][0] = $tangent[$last-1][0] = $polyline[$last-1][0];
	$cp[$last-1][1][1] = $tangent[$last-1][1] = $polyline[$last-1][1];
	$cp[$last-1][0][0] = -$tangent[$last-1][0];
	$cp[$last-1][0][1] = -$tangent[$last-1][1];
    } elsif ($lastseg eq 'constraint1') {
	# Bezier curve from point last-1 to last, constrained to polyline at point last
	# (not drawn, allows unconstrained tangent at point last-1)
	$type[$last-1] = 2; 
    } elsif ($lastseg eq 'constraint2') {
	# line from point last-1 to last (not drawn, only sets tangent at point last-1)
	$type[$last-1] = 3;
	# no need to set after, as is not drawn and is line anyway
	$tangent[$last-1][0] = $polyline[$last-1][0];
	$tangent[$last-1][1] = $polyline[$last-1][1];
	$cp[$last-1][0][0] = -$tangent[$last-1][0];
	$cp[$last-1][0][1] = -$tangent[$last-1][1];
    } else { # 'curve'
	# Bezier curve from point last-1 to last. both ends unconstrained, at point last
	# it is just a reflection of the tangent at point last-1
       #$type[$last-1] = 0; # should already be 0
	$ptheta = atan2($polyline[$last-1][1], $polyline[$last-1][0]);
	$ttheta = atan2($tangent[$last-1][1], $tangent[$last-1][0]);
	$dtheta = _leftright($ptheta, $ttheta);
	$ptheta = atan2(-$polyline[$last-1][1], -$polyline[$last-1][0]);
	$ttheta = _sweep($ptheta, $dtheta);
	$tangent[$last][0] = -cos($ttheta);
	$tangent[$last][1] = -sin($ttheta);
	$cp[$last][0][0] = -$tangent[$last][0]; # set 'before' unit vector at point 1
	$cp[$last][0][1] = -$tangent[$last][1];
    }

    # go through interior points (2..last-2) and set tangents if colinear
    # (and not forcing lines). by default are curves.
    for ($i=2; $i<$last-1; $i++) {
	if ($colinpt[$i]) {
	    # this is a colinear point (1 or more in a row with endpoints of
	    # run). first, find run
	    for ($j=$i+1; $j<$last-1; $j++) {
		if (!$colinpt[$j]) { last; }
	    }
	    $j--; # back up one
	    # here with $i = first of a run of colinear points, and $j = last
	    # of the run. $i may equal $j (no lines to force)
            if ($colinear eq 'line' && $j>$i) {
		for ($k=$i; $k<$j; $k++) {
	            $type[$k] = 1; # force a drawn line, ignore tangents/cps
		}
	    } else {
		# colinear, will draw curve
		my ($pthetap, $tthetap, $dthetap, $count, $odd, $kk, 
		    $center, $tthetax, $same);
		# odd number of points or even?
		$count = $j - $i + 1; # only interior colinear points (>= 1)
		$odd = $count % 2; # odd = 1 if odd count, 0 if even

		# need to figure tangents for each colinear point (draw curves)
		# first get d-theta for entry angle, d-theta' for exit angle
		# for which side of polyline the entry, exit control points are
	        $ptheta = atan2($polyline[$i-1][1], $polyline[$i-1][0]);
	        $ttheta = atan2($tangent[$i-1][1], $tangent[$i-1][0]);
	        $dtheta = _leftright($ptheta, $ttheta); # >=0 CCW left side
		                                        #  <0 CW right side
	        $pthetap = atan2(-$polyline[$j][1], -$polyline[$j][0]);
	        $tthetap = atan2(-$tangent[$j+1][1], -$tangent[$j+1][0]);
	        $dthetap = _leftright($pthetap, $tthetap); # >=0 CCW right side
		                                           #  <0 CW left side

                # both dtheta and dtheta' are modified below, so preserve here
		if ($dtheta >= 0 && $dthetap  < 0 ||
		    $dtheta  < 0 && $dthetap >= 0) {
		    # non-colinear end tangents are on same side
		    $same = 1;
		} else {
		    # non-colinear end tangents are on opposite sides
		    $same = 0;
		}
		# $kk is how many points on each side to set tangent at,
		# including $i and $j (but excluding $center)
		if ($odd) {
		    # center (i + (count-1)/2) stays flat tangent,
		    $kk = ($count-1)/2; # ignore if 0
		    $center = $i + $kk;
		} else {
                    # center falls between i+count/2 and i+count/2+1
		    $kk = $count/2; # minimum 1
		    $center = -1;  # not used
		}

		# dtheta[p]/2,3,4... towards center alternating
		#     direction from initial dtheta[p]
		# from left, i, i+1, i+2,...,i+kk-1, (center)
		# from right, j, j-1, j-2,...,j-kk+1, (center)
		for ($k=0; $k<$kk; $k++) {
		    # handle i+k and j-k points
		    $dtheta = -$dtheta;
	            $tthetax = _sweep($ptheta, -$dtheta/($k+2));
		    $cp[$i+$k][1][0] =  $tangent[$i+$k][0] = cos($tthetax);
		    $cp[$i+$k][1][1] =  $tangent[$i+$k][1] = sin($tthetax);
		    $cp[$i+$k][0][0] = -$tangent[$i+$k][0];
		    $cp[$i+$k][0][1] = -$tangent[$i+$k][1];

		    $dthetap = -$dthetap;
	            $tthetax = _sweep($pthetap, -$dthetap/($k+2));
		    $cp[$j-$k][1][0] =  $tangent[$j-$k][0] = -cos($tthetax);
		    $cp[$j-$k][1][1] =  $tangent[$j-$k][1] = -sin($tthetax);
		    $cp[$j-$k][0][0] = -$tangent[$j-$k][0];
		    $cp[$j-$k][0][1] = -$tangent[$j-$k][1];
		}

		# if odd (there is a center point), either flat or averaged
		if ($odd) {
		    if ($same) {
		        # non-colinear tangents are on same side,
		        # so tangent is flat (in line with polyline)
			# tangent[center] should already be set to polyline
		    } else {
		        # non-colinear tangents are on opposite sides
		        # so tangent is average of both neighbors dtheta's
		        # and is opposite sign of the left neighbor
		        $dtheta = -($dtheta + $dthetap)/2/($kk+2);
		        $tthetax = _sweep($ptheta, -$dtheta);
		        $tangent[$center][0] = cos($tthetax);
		        $tangent[$center][1] = sin($tthetax);
		    }
		    # finally, the cps for the center. redundant for flat
		    $cp[$center][0][0] = -$tangent[$center][0];
		    $cp[$center][0][1] = -$tangent[$center][1];
		    $cp[$center][1][0] =  $tangent[$center][0];
		    $cp[$center][1][1] =  $tangent[$center][1];
	        } # odd length of run
	    } # it IS a colinear point

	    # done dealing with run of colinear points
	    $i = $j; # jump ahead over the run
	    next;
            # end of handling colinear points
	} else {
	    # non-colinear. just set cp before and after uvecs (lengths should
	    # already be set)
	}
    } # end of for loop through interior points

    # all cp entries should be set, and all type entries should be set. if
    # debug flag, output control points (hollow red circles) with dashed 2-2
    # red lines from their points
    if ($debug > 3) {
	for ($i=0; $i<$last; $i++) {
	    # if a line or constraint line, no cp/line to draw
	    # don't forget, for i=last-1 and type=0 or 2, need to draw at last
	    if ($i < $last && ($type[$i] == 1 || $type[$i] == 3)) { next; }

	    # have point i that is end of curve, so draw dashed line to
	    # control point, change to narrow solid line, draw open circle,
	    # change back to heavy dashed line for next
	    for ($j=0; $j<2; $j++) {
		# j=0 'after' control point for point $i 
		# j=1 'before' control point for point $i+1

		# dashed red line
		$self->move($inputs[$i+$j][0], $inputs[$i+$j][1]);
		$self->line($inputs[$i+$j][0] + $cp[$i+$j][1-$j][0]*$cp[$i+$j][1-$j][2], 
			    $inputs[$i+$j][1] + $cp[$i+$j][1-$j][1]*$cp[$i+$j][1-$j][2]);
		$self->stroke();
		# red circle
		$self->linewidth(1);
		$self->linedash();
		$self->circle($inputs[$i+$j][0] + $cp[$i+$j][1-$j][0]*$cp[$i+$j][1-$j][2], 
			      $inputs[$i+$j][1] + $cp[$i+$j][1-$j][1]*$cp[$i+$j][1-$j][2], 
			      2);
		$self->stroke();
		# prepare for next line
		$self->linewidth(2);
		$self->linedash(2);
	    }
	} # loop through all points
    } # debug == 3

    # restore old settings 
    if ($debug > 0) {
	$self->fillstroke();
	$self->strokecolor(@oldColor);
        $self->linewidth($oldWidth);
	$self->linedash(@oldDash);
    }

    # the final act: go through each segment and draw either a line or a
    # curve
    if ($type[0] < 2) {  # start drawing at 0 or 1? 
        $self->move($inputs[0][0], $inputs[0][1]);
    } else {
        $self->move($inputs[1][0], $inputs[1][1]);
    }
    for ($i=0; $i<$last; $i++) {
	if ($type[$i] > 1) { next; } # 2, 3 constraints, not drawn
	if ($type[$i] == 0) {
	    # Bezier curve, use $cp[$i][1] and $cp[$i+1][0] to generate 
	    # points for curve call
	    $self->curve($inputs[$i][0]   + $cp[$i][1][0]*$cp[$i][1][2], 
		         $inputs[$i][1]   + $cp[$i][1][1]*$cp[$i][1][2],
	                 $inputs[$i+1][0] + $cp[$i+1][0][0]*$cp[$i+1][0][2], 
		         $inputs[$i+1][1] + $cp[$i+1][0][1]*$cp[$i+1][0][2],
			 $inputs[$i+1][0],
			 $inputs[$i+1][1]);
	} else {
	    # line to next point
 	    $self->line($inputs[$i+1][0], $inputs[$i+1][1]);
	}
    }
    
    return $self;
}
# helper function for bspline()
# given two unit vectors (direction in radians), return the delta change in
# direction (radians) of the first vector to the second. left is positive.
sub _leftright {
    my ($ptheta, $ttheta) = @_;
    # ptheta is the angle (radians) of the polyline vector from one
    # point to the next, and ttheta is the tangent vector at the point
    my ($dtheta, $antip);

    if ($ptheta >= 0 && $ttheta >= 0 || # both in top half (QI, QII)
        $ptheta < 0 && $ttheta < 0) { # both in bottom half (QIII, QIV)
	$dtheta = $ttheta - $ptheta;
    } else {  # p in top half (QI, QII), t,antip in bottom half (QIII, QIV)
	      # or p in bottom half, t,antip in top half
	if ($ttheta < 0) {
	    $antip = $ptheta - pi;
	} else {
	    $antip = $ptheta + pi;
	}
	if ($ttheta <= $antip) {
	    $dtheta = pi - $antip + $ttheta; # pi - (antip - ttheta)
	} else {
	    $dtheta = $ttheta - $antip - pi; # (ttheta - antip) - pi
	}
    }

    return $dtheta;
}
# helper function. given a unit direction ptheta, swing +dtheta radians right,
# return normalized result
sub _sweep {
    my ($ptheta, $dtheta) = @_;
    my ($max, $result);

    if ($ptheta >= 0) { # p in QI or QII
	if ($dtheta >= 0) { # delta CW radians
	    $result = $ptheta - $dtheta; # OK to go into bottom quadrants
	} else { # delta CCW radians
	    $max = pi - $ptheta; # max delta (>0) to stay in top quadrants
	    if ($max >= -$dtheta) { # end up still in top quadrants
		$result = $ptheta - $dtheta;
	    } else { # into bottom quadrants
		$dtheta += $max; # remaining CCW amount from -pi
                $result = -1*pi - $dtheta;  # -pi caused some problems
	    }
	}
    } else { # p in QIII or QIV
	if ($dtheta >= 0) { # delta CW radians
	    $max = pi + $ptheta; # max delta (>0) to stay in bottom quadrants
	    if ($max >= $dtheta) { # end up still in bottom quadrants
		$result = $ptheta - $dtheta;
	    } else { # into top quadrants
		$dtheta -= $max; # remaining CCW amount from +pi
                $result = pi - $dtheta;
	    }
	} else { # delta CCW radians
            $result = $ptheta - $dtheta; # OK to go into top quadrants
	}
    }

    return $result;
}

=head4 bogen

    $content->bogen($x1,$y1, $x2,$y2, $radius, $move, $larger, $reverse)

    $content->bogen($x1,$y1, $x2,$y2, $radius, $move, $larger)

    $content->bogen($x1,$y1, $x2,$y2, $radius, $move)

    $content->bogen($x1,$y1, $x2,$y2, $radius)

=over

(I<bogen> is German for I<bow>, as in a segment (arc) of a circle. This is a 
segment of a circle defined by the intersection of two circles of a given 
radius, with the two intersection points as inputs. There are B<four> possible 
resulting arcs, which can be selected with C<$larger> and C<$reverse>.)

This extends the path along an arc of a circle of the specified radius
between C<[$x1,$y1]> to C<[$x2,$y2]>. The current position is then set
to the endpoint of the arc (C<[$x2,$y2]>).

Set C<$move> to a I<true> value if this arc is the beginning of a new
path instead of the continuation of an existing path. Note that the default 
(C<$move> = I<false>) is
I<not> a straight line to I<P1> and then the arc, but a blending into the curve
from the current point. It will often I<not> pass through I<P1>!

Set C<$larger> to a I<true> value to draw the larger ("outer") arc between the 
two points, instead of the smaller one. Both arcs are drawn I<clockwise> from 
I<P1> to I<P2>. The default value of I<false> draws the smaller arc.
Note that the "other" circle's larger arc is used (the center point is 
"flipped" across the line between I<P1> and I<P2>), rather than using the 
"remainder" of the smaller arc's circle (which would necessitate reversing the
direction of travel along the arc -- see C<$reverse>).

Set C<$reverse> to a I<true> value to draw the mirror image of the
specified arc (flip it over, so that its center point is on the other
side of the line connecting the two points). Both arcs are drawn
I<counter-clockwise> from I<P1> to I<P2>. The default (I<false>) draws 
clockwise arcs. An arc is B<always> drawn from I<P1> to I<P2>; the direction
(clockwise or counter-clockwise) may be chosen.

The C<$radius> value cannot be smaller than B<half> the distance from 
C<[$x1,$y1]> to C<[$x2,$y2]>. If it is too small, the radius will be set to
half the distance between the points (resulting in an arc that is a
semicircle). This is a silent error, as even if the points are correct, due
to rounding etc. they may not fall I<exactly> on the two circles.

You can think of "looking" from I<P1> to I<P2>. In the degenerate case, where
the radius is exactly half the distance between the points, there is no
difference between "small" and "large" arcs, and both circles will coincide
with their center half way between I<P1> and I<P2>. Only the direction matters.
Once the radius is any larger, the two circles become distinct. The primary 
circle is centered to your right, whose small arc is CW on your left; the 
secondary circle is centered to your left, whose small arc is CCW on your 
right. The "large" arcs are the arcs using the remainder of the circles: CW 
large is part of the left (secondary) circle, and CCW large is part of the 
right (primary) circle.

=back

=cut

sub bogen {
    my ($self, $x1,$y1, $x2,$y2, $r, $move, $larc, $dir) = @_;
    # in POD description, dir is "reverse" flag

    my ($p0_x,$p0_y, $p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
    my ($dx,$dy, $x,$y, $alpha,$beta, $alpha_rad, $d,$z, @points);

    if ($x1 == $x2 && $y1 == $y2) {
        die "bogen requires two distinct points";
	# SVG def of (arc) merely leaves it as a point
    }
    if ($r <= 0.0) {
        die "bogen requires a positive radius";
	# SVG def of (arc) merely takes absolute value
    }
    $move = 0 if !defined $move;
    $larc = 0 if !defined $larc;
    $dir  = 0 if !defined $dir;

    $self->_Gpending();
    $dx = $x2 - $x1;
    $dy = $y2 - $y1;
    $z = sqrt($dx**2 + $dy**2);
    $alpha_rad = asin($dy/$z); # |dy/z| guaranteed <= 1.0
    $alpha_rad = pi - $alpha_rad if $dx < 0;

    # alpha is direction of vector P1 to P2
    $alpha = rad2deg($alpha_rad);
    # use the complementary angle for flipped arc (arc center on other side)
    # effectively clockwise draw from P2 to P1
    $alpha -= 180 if $dir;

    $d = 2*$r;
    # z/d must be no greater than 1.0 (arcsine arg)
    if ($z > $d) { 
        $d = $z;  # SILENT error and fixup
        $r = $d/2;
    }

    $beta = rad2deg(2*asin($z/$d));
    # beta is the sweep P1 to P2: ~0 (r very large) to 180 degrees (min r)
    $beta = 360-$beta if $larc;  # large arc is remainder of small arc
    # for large arc, beta could approach 360 degrees if r is very large

    # always draw CW (dir=1)
    # note that start and end could be well out of +/-360 degree range
    @points = _arctocurve($r,$r, 90+$alpha+$beta/2,90+$alpha-$beta/2, 1);

    if ($dir) {  # flip order of points for reverse arc
        my @pts = @points;
        @points = ();
        while (@pts) {
            $y = pop @pts;
            $x = pop @pts;
            push(@points, $x,$y);
        }
    }

    $p0_x = shift @points;
    $p0_y = shift @points;
    $x = $x1 - $p0_x;
    $y = $y1 - $p0_y;

    $self->move($x1,$y1) if $move;

    while (scalar @points > 0) {
        $p1_x = $x + shift @points;
        $p1_y = $y + shift @points;
        $p2_x = $x + shift @points;
        $p2_y = $y + shift @points;
        # if we run out of data points, use the end point instead
        if (scalar @points == 0) {
            $p3_x = $x2;
            $p3_y = $y2;
        } else {
            $p3_x = $x + shift @points;
            $p3_y = $y + shift @points;
        }
        $self->curve($p1_x,$p1_y, $p2_x,$p2_y, $p3_x,$p3_y);
        shift @points;
        shift @points;
    }

    return $self;
}

=head2 Path Painting (Drawing)

=head3 stroke

    $content->stroke()

=over

Strokes the current path. That is, it is drawing solid or dashed I<lines>, but
B<not> filling areas.

=back

=cut

sub _stroke {
    return 'S';
}

sub stroke {
    my ($self) = shift;

    $self->_Gpending(); # flush buffered commands
    $self->add(_stroke());

    return $self;
}

=head3 fill

    $content->fill($use_even_odd_fill)

    $content->fill('rule' => $rule)

    $content->fill()  # use default nonzero rule

=over

Fill the current path's enclosed I<area>. 
It does I<not> stroke the enclosing path around the area.

=over

=item $user_even_odd_fill = 0 or I<false> (B<default>)

=item $rule = 'nonzero'

If the path intersects with itself, the I<nonzero> winding rule will be
used to determine which part of the path is filled in. This basically
fills in I<everything> inside the path, except in some situations depending
on the direction of the path. 

=item $user_even_odd_fill = 1 (non-zero value) or I<true>

=item $rule = 'even-odd'

If the path intersects with itself, the I<even-odd> winding rule will be
used to determine which part of the path is filled in. In most cases, this
means that the filling state alternates each time the path is intersected.
This basically will fill alternating closed sub-areas.

=back

See the PDF Specification, section 8.5.3.3 (in version 1.7), 
for more details on filling.

The "rule" parameter is added for PDF::API2 compatibility.

=back

=cut

sub fill {
    my ($self) = shift;

    $self->_Gpending(); # flush buffered commands
    my $even_odd = 0; # default (use non-zero rule)
    if (@_ == 2) {  # hash list (one element) given
        my %opts = @_;
	if (defined $opts{'-rule'} && !defined $opts{'rule'}) { $opts{'rule'} = delete($opts{'-rule'}); }
        if (($opts{'rule'} // 'nonzero') eq 'even-odd') {
            $even_odd = 1;
        }
    } else {  # single value (boolean)
        $even_odd = shift();
    }

    $self->add($even_odd ? 'f*' : 'f');

    return $self;
}

=head3 fillstroke, paint, fill_stroke

    $content->fillstroke($use_even_odd_fill)

    $content->fillstroke('rule' => $rule)

    $content->fillstroke()  # use default nonzero rule

=over

B<Fill> the current path's enclosed I<area> and then B<stroke> the enclosing 
path around the area (possibly with a different color).

=over

=item $user_even_odd_fill = 0 or I<false> (B<default>)

=item $rule = 'nonzero'

If the path intersects with itself, the I<nonzero> winding rule will be
used to determine which part of the path is filled in. This basically
fills in I<everything> inside the path, except in some situations depending
on the direction of the path. 

=item $user_even_odd_fill = 1 (non-zero value) or I<true>

=item $rule = 'even-odd'

If the path intersects with itself, the I<even-odd> winding rule will be
used to determine which part of the path is filled in. In most cases, this
means that the filling state alternates each time the path is intersected.
This basically will fill alternating closed sub-areas.

=back

See the PDF Specification, section 8.5.3.3 (in version 1.7), 
for more details on filling.

The "rule" parameter is added for PDF::API2 compatibility.

B<Alternate names:> C<paint> and C<fill_stroke>

C<paint> is for compatibility with PDF::API2, while C<fill_stroke> is added
for compatibility with many other PDF::API2-related renamed methods.

=back

=cut

sub paint { return fillstroke(@_); } ## no critic

sub fill_stroke { return fillstroke(@_); } ## no critic

sub fillstroke {
    my ($self) = shift;

    my $even_odd = 0; # default (use non-zero rule)
    if (@_ == 2) {  # hash list (one element) given
        my %opts = @_;
	if (defined $opts{'-rule'} && !defined $opts{'rule'}) { $opts{'rule'} = delete($opts{'-rule'}); }
        if (($opts{'rule'} // 'nonzero') eq 'even-odd') {
            $even_odd = 1;
        }
    } else {  # single value (boolean)
        $even_odd = shift();
    }

    $self->add($even_odd ? 'B*' : 'B');

    return $self;
}

=head3 clip

    $content->clip($use_even_odd_fill)

    $content->clip('rule' => $rule)

    $content->clip()  # use default nonzero rule

=over

Modifies the current clipping path by intersecting it with the current
path. Initially (a fresh page), the clipping path is the entire media. Each
definition of a path, and a C<clip()> call, intersects the new path with the
existing clip path, so the resulting clip path is no larger than the new path, 
and may even be empty if the intersection is null.

=over

=item $user_even_odd_fill = 0 or I<false> (B<default>)

=item $rule = 'nonzero'

If the path intersects with itself, the I<nonzero> winding rule will be
used to determine which part of the path is included (clipped in or out). 
This basically includes I<everything> inside the path, except in some 
situations depending on the direction of the path. 

=item $user_even_odd_fill = 1 (non-zero value) or I<true>

=item $rule = 'even-odd'

If the path intersects with itself, the I<even-odd> winding rule will be
used to determine which part of the path is included. In most cases, this
means that the inclusion state alternates each time the path is intersected.
This basically will include alternating closed sub-areas.

=back

It is common usage to make the 
C<endpath()> call (B<n>) after the C<clip()> call, to clear the path (unless 
you want to reuse that path, such as to fill and/or stroke it to show the clip 
path). If you want to clip text glyphs, it gets rather complicated, as a clip
port cannot be created within a text object (that will have an effect on text). 
See the object discussion in L<PDF::Builder::Docs/Rendering Order>.

    my $grfxC1 = $page->gfx();
    my $textC  = $page->text();
    my $grfxC2 = $page->gfx();
     ...
    $grfxC1->save();
    $grfxC1->endpath();
    $grfxC1->rect(...);
    $grfxC1->clip();
    $grfxC1->endpath();
     ...
    $textC->  output text to be clipped
     ...
    $grfxC2->restore();

The "rule" parameter is added for PDF::API2 compatibility.

=back

=cut

sub clip {
    my ($self) = shift;

    my $even_odd = 0; # default (use non-zero rule)
    if (@_ == 2) {  # hash list (one element) given
        my %opts = @_;
	if (defined $opts{'-rule'} && !defined $opts{'rule'}) { $opts{'rule'} = delete($opts{'-rule'}); }
        if (($opts{'rule'} // 'nonzero') eq 'even-odd') {
            $even_odd = 1;
        }
    } else {  # single value (boolean)
        $even_odd = shift();
    }

    $self->add($even_odd ? 'W*' : 'W');

    return $self;
}

=head3 endpath, end

    $content->endpath()

=over

Ends the current path without explicitly enclosing it.
That is, unlike C<close>, there is B<no> line segment 
drawn back to the starting position.
This is often used to end the current path without filling or
stroking, for the side effect of changing the current clipping path.

B<Alternate name:> C<end>

This is provided for compatibility with PDF::API2. Do not confuse it with
the C<$pdf-E<gt>end()> method!

=back

=cut

sub end { return endpath(@_); } ## no critic

sub endpath {
    my ($self) = shift;

    $self->add('n');

    return $self;
}

=head3 shade

    $content->shade($shade, @coord)

=over

Sets the shading matrix.

=over

=item $shade

A hash reference that includes a C<name()> method for the shade name.

=item @coord

An array of 4 items: X-translation, Y-translation, 
X-scaled and translated, Y-scaled and translated.

=back

=back

=cut

sub shade {
    my ($self, $shade, @coord) = @_;

    my @tm = (
        $coord[2]-$coord[0] , 0,
        0                   , $coord[3]-$coord[1],
        $coord[0]           , $coord[1]
    );
    $self->save();
    $self->matrix(@tm);
    $self->add('/'.$shade->name(), 'sh');

    $self->resource('Shading', $shade->name(), $shade);
    $self->restore();

    return $self;
}

=head2 Colors

=head3 fillcolor, fill_color, strokecolor, stroke_color

    $content->fillcolor($color)

    $content->strokecolor($color)

=over

Sets the fill (enclosed area) or stroke (path) color. The interior of text
characters are I<filled>, and (I<if> ordered by C<render>) the outline is
I<stroked>.

    # Use a named color
    # -> RGB color model
    # there are many hundreds of named colors defined in 
    # PDF::Builder::Resource::Colors
    $content->fillcolor('blue');

    # Use an RGB color (# followed by 3, 6, 9, or 12 hex digits)
    # -> RGB color model
    # This maps to 0-1.0 values for red, green, and blue
    $content->fillcolor('#FF0000');   # red

    # Use a CMYK color (% followed by 4, 8, 12, or 16 hex digits)
    # -> CMYK color model
    # This maps to 0-1.0 values for cyan, magenta, yellow, and black
    $content->fillcolor('%FF000000');   # cyan
    # Note: you might wish to make use of packages such as 
    #  HashData::Color::PantoneToCMYK to map "Pantone" color names/codes to a 
    #  set of CMYK values

    # Use an HSV color (! followed by 3, 6, 9, or 12 hex digits)
    # -> RGB color model
    # This maps to 0-360 degrees for the hue, and 0-1.0 values for 
    # saturation and value
    $content->fillcolor('!FF0000');

    # Use an HSL color (& followed by 3, 6, 9, or 12 hex digits)
    # -> L*a*b color model
    # This maps to 0-360 degrees for the hue, and 0-1.0 values for 
    # saturation and lightness. Note that 360 degrees = 0 degrees (wraps)
    $content->fillcolor('&FF0000');

    # Use an L*a*b color ($ followed by 3, 6, 9, or 12 hex digits)
    # -> L*a*b color model
    # This maps to 0-100 for L, -100 to 100 for a and b
    $content->fillcolor('$FF0000');

In all cases, if too few digits are given, the given digits
are silently right-padded with 0's (zeros). If an incorrect number 
of digits are given, the next lowest number of expected
digits are used, and the remaining digits are silently ignored.

    # A single number between 0.0 (black) and 1.0 (white) is an alternate way
    # of specifying a gray scale.
    $content->fillcolor(0.5);

    # Three array elements between 0.0 and 1.0 is an alternate way of specifying
    # an RGB color.
    $content->fillcolor(0.3, 0.59, 0.11);

    # Four array elements between 0.0 and 1.0 is an alternate way of specifying
    # a CMYK color.
    $content->fillcolor(0.1, 0.9, 0.3, 1.0);

In all cases, if a number is less than 0, it is silently turned into a 0. If
a number is greater than 1, it is silently turned into a 1. This "clamps" all
values to the range 0.0-1.0.

    # A single reference is treated as a pattern or shading space.

    # Two or more entries with the first element a Perl reference, is treated 
    # as either an indexed colorspace reference plus color-index(es), or 
    # as a custom colorspace reference plus parameter(s).

If no value was passed in, the current fill color (or stroke color) I<array> 
is B<returned>, otherwise C<$self> is B<returned>.

B<Alternate names:> C<fill_color> and C<stroke_color>.

These are provided for PDF::API2 compatibility.

=back

=cut

# TBD document in POD (examples) and add t tests for (pattern/shading space, 
#     indexed colorspace + color-index, or custom colorspace + parameter)
#     for both fillcolor() and strokecolor(). t/cs-webcolor.t does test 
#     cs + index

# note that namecolor* routines all handle #, %, !, &, and named
# colors, even though _makecolor only sends each type to proper
# routine. reserved for different output color models?

# I would have preferred to move _makecolor and _clamp over to Util.pm, but
# some subtle errors were showing up. Maybe in the future...
sub _makecolor {
    my ($self, $sf, @clr) = @_;

    # $sf is the stroke/fill flag (0/1)
    # note that a scalar argument is turned into a single element array
    # there will be at least one element, guaranteed

    if      (scalar @clr == 1) {  # a single @clr element
        if      (ref($clr[0])) {
            # pattern or shading space
            return '/Pattern', ($sf? 'cs': 'CS'), '/'.($clr[0]->name()), ($sf? 'scn': 'SCN');
    
        } elsif ($clr[0] =~ m/^[a-z#!]/i) {
            # colorname (alpha) or # (RGB) or ! (HSV) specifier and 3/6/9/12 digits
            # with rgb target colorspace
            # namecolor always returns an RGB
           #return namecolor($clr[0]), ($sf? 'rg': 'RG');
            return join(' ',namecolor($clr[0])).' '.($sf? 'rg': 'RG');
    
        } elsif ($clr[0] =~ m/^%/) {
            # % (CMYK) specifier and 4/8/12/16 digits
            # with cmyk target colorspace
           #return namecolor_cmyk($clr[0]), ($sf? 'k': 'K');
            return join(' ',namecolor_cmyk($clr[0])).' '.($sf? 'k': 'K');

        } elsif ($clr[0] =~ m/^[\$\&]/) {
            # & (HSL) or $ (L*a*b) specifier
            # with L*a*b target colorspace
            if (!defined $self->resource('ColorSpace', 'LabS')) {
                my $dc = PDFDict();
                my $cs = PDFArray(PDFName('Lab'), $dc);
                $dc->{'WhitePoint'} = PDFArray(map { PDFNum($_) } qw(1 1 1));
                $dc->{'Range'} = PDFArray(map { PDFNum($_) } qw(-128 127 -128 127));
                $dc->{'Gamma'} = PDFArray(map { PDFNum($_) } qw(2.2 2.2 2.2));
                $self->resource('ColorSpace', 'LabS', $cs);
            }
           #return '/LabS', ($sf? 'cs': 'CS'), namecolor_lab($clr[0]), ($sf? 'sc': 'SC');
            return '/LabS '.($sf? 'cs': 'CS').' '.join(' ',namecolor_lab($clr[0])).' '.($sf? 'sc': 'SC');

        } else { # should be a float number... add a test and else failure?
            # grey color spec.
            $clr[0] = _clamp($clr[0], 0, 0, 1);
           #return $clr[0], ($sf? 'g': 'G');
            return $clr[0].' '.($sf? 'g': 'G');

       #} else {
       #    die 'invalid color specification.';
        } # @clr 1 element

    } elsif (scalar @clr > 1) {  # 2 or more @clr elements
        if      (ref($clr[0])) {
            # indexed colorspace plus color-index(es)
            # or custom colorspace plus param(s)
            my $cs = shift @clr;
           #return '/'.($cs->name()).' '.($sf? 'cs': 'CS').' '.($cs->param(@clr)).' '.($sf? 'sc': 'SC');
	    my $out = '/'.($cs->name());
	    $out .= ' '.($sf? 'cs': 'CS');
	    $out .= " @clr";
	    $out .= ' '.($sf? 'sc': 'SC');
            return $out;

       # What exactly is the difference between the following case and the 
       # previous case? The previous allows multiple indices or parameters and
       # this one doesn't. Also, this one would try to process a bad call like
       # fillcolor('blue', 'gray').
       #} elsif (scalar @clr == 2) {
       #    # indexed colorspace plus color-index
       #    # or custom colorspace plus param
       #    return '/'.$clr[0]->name(), ($sf? 'cs': 'CS'), $clr[0]->param($clr[1]), ($sf? 'sc': 'SC');

        } elsif (scalar @clr == 3) {
            # legacy rgb color-spec (0 <= x <= 1)
            $clr[0] = _clamp($clr[0], 0, 0, 1);
            $clr[1] = _clamp($clr[1], 0, 0, 1);
            $clr[2] = _clamp($clr[2], 0, 0, 1);
           #return floats($clr[0], $clr[1], $clr[2]), ($sf? 'rg': 'RG');
            return join(' ',floats($clr[0], $clr[1], $clr[2])).' '.($sf? 'rg': 'RG');

        } elsif (scalar @clr == 4) {
            # legacy cmyk color-spec (0 <= x <= 1)
            $clr[0] = _clamp($clr[0], 0, 0, 1);
            $clr[1] = _clamp($clr[1], 0, 0, 1);
            $clr[2] = _clamp($clr[2], 0, 0, 1);
            $clr[3] = _clamp($clr[3], 0, 0, 1);
           #return floats($clr[0], $clr[1], $clr[2], $clr[3]), ($sf? 'k': 'K');
            return join(' ',floats($clr[0], $clr[1], $clr[2], $clr[3])).' '.($sf? 'k': 'K');

        } else {
            die 'invalid color specification.';
        } # @clr with 2 or more elements

    } else {  # @clr with 0 elements. presumably won't see...
        die 'invalid color specification.';
    }
}

# silent error if non-numeric value (assign default), 
# or outside of min..max limits (clamp to closer limit).
sub _clamp {
    my ($val, $default, $min, $max) = @_;

    if (!Scalar::Util::looks_like_number($val)) { $val = $default; }
    if      ($val < $min) { 
        $val = $min; 
    } elsif ($val > $max) {
        $val = $max;
    }

    return $val;
}

sub _fillcolor {
    my ($self, @clrs) = @_;

    if      (ref($clrs[0]) =~ m|^PDF::Builder::Resource::ColorSpace|) {
        $self->resource('ColorSpace', $clrs[0]->name(), $clrs[0]);
    } elsif (ref($clrs[0]) =~ m|^PDF::Builder::Resource::Pattern|) {
        $self->resource('Pattern', $clrs[0]->name(), $clrs[0]);
    }

    return $self->_makecolor(1, @clrs);
}

sub fill_color { return fillcolor(@_); } ## no critic

sub fillcolor {
    my $self = shift;

    if (@_) {
        @{$self->{' fillcolor'}} = @_;
	my $string = $self->_fillcolor(@_);
	if ($self->_in_text_object()) {
	    if ($self->{' doPending'}) {
	        $self->{' Tpending'}{'color'} = $string;
	    } else {
                $self->add($string);
	    }
	} else {
	    if ($self->{' doPending'}) {
	        $self->{' Gpending'}{'color'} = $string;
	    } else {
                $self->add($string);
	    }
        }

	return $self;
    } else {

        return @{$self->{' fillcolor'}};
    }
}

sub _strokecolor {
    my ($self, @clrs) = @_;

    if      (ref($clrs[0]) =~ m|^PDF::Builder::Resource::ColorSpace|) {
        $self->resource('ColorSpace', $clrs[0]->name(), $clrs[0]);
    } elsif (ref($clrs[0]) =~ m|^PDF::Builder::Resource::Pattern|) {
        $self->resource('Pattern', $clrs[0]->name(), $clrs[0]);
    }

    return $self->_makecolor(0, @clrs);
}

sub stroke_color { return strokecolor(@_); } ## no critic

sub strokecolor {
    my $self = shift;

    if (@_) {
        @{$self->{' strokecolor'}} = @_;
	my $string = $self->_strokecolor(@_);
	if ($self->_in_text_object()) {
	    if ($self->{' doPending'}) {
	        $self->{' Tpending'}{'Color'} = $string;
	    } else {
                $self->add($string);
	    }
	} else {
	    if ($self->{' doPending'}) {
	        $self->{' Gpending'}{'Color'} = $string;
	    } else {
                $self->add($string);
	    }
	}

	return $self;
    } else {

        return @{$self->{' strokecolor'}};
    }
}

=head2 External Objects

=head3 image

    $content->image($image_object, $x,$y, $width,$height)

    $content->image($image_object, $x,$y, $scale)

    $content->image($image_object, $x,$y)

    $content->image($image_object)

    # Example
    my $image_object = $pdf->image_jpeg($my_image_file);
    $content->image($image_object, 100, 200);

=over

Places an image on the page in the specified location (specifies the lower 
left corner of the image). The default location is C<[0,0]>.

If coordinate transformations have been made (see I<Coordinate
Transformations> above), the position and scale will be relative to the
updated coordinates. Otherwise, C<[0,0]> will represent the bottom left
corner of the page, and C<$width> and C<$height> will be measured at
72dpi.

For example, if you have a 600x600 image that you would like to be
shown at 600dpi (i.e., one inch square), set the width and height to 72.
(72 Big Points is one inch)

If passed the output of C<image_svg()>, C<image()> will simply pass it on to
the C<object()> method, with adjusted parameters. Note that this usage 
requires that the C<width> and C<height> are replaced by C<scale_x> and
C<scale_y> values (optionally).

=back

=cut

# deprecated in PDF::API2 -- suggests use of object() instead
sub image {
    my ($self, $img, $x,$y, $w,$h) = @_;

    if (!defined $y) { $y = 0; }
    if (!defined $x) { $x = 0; }

    # is this a processed SVG (array of hashes)? throw over the wall to object
    if (ref($img) eq 'ARRAY') {
	# note that w and h are NOT the sizes, but are the SCALING factors
	# (default: 1). discussed in image_svg() call.
	$self->object($img, $x,$y, $w,$h);
	return $self;
    }

    if (defined $img->{'Metadata'}) {
        $self->_metaStart('PPAM:PlacedImage', $img->{'Metadata'});
    }
    $self->save();
    if      (!defined $w) {
        $h = $img->height();
        $w = $img->width();
    } elsif (!defined $h) {
        $h = $img->height()*$w;
        $w = $img->width()*$w;
    }
    $self->matrix($w,0,0,$h, $x,$y);
    $self->add("/".$img->name(), 'Do');
    $self->restore();
    $self->{' x'} = $x;
    $self->{' y'} = $y;
    $self->resource('XObject', $img->name(), $img);
    if (defined $img->{'Metadata'}) {
        $self->_metaEnd();
    }

    return $self;
}

=head3 formimage

    $content->formimage($form_object, $x,$y, $scaleX, $scaleY)

    $content->formimage($form_object, $x,$y, $scale)

    $content->formimage($form_object, $x,$y)

    $content->formimage($form_object)

=over

Places an XObject on the page in the specified location (giving the lower
left corner of the image) and scale (applied to the image's native height
and width). If no scale is given, use 1 for both X and Y. If one scale is 
given, use for both X and Y.  If two scales given, they are for (separately) 
X and Y. In general, you should not greatly distort an image by using greatly 
different scaling factors in X and Y, although it is now possible for when 
that effect is desirable. The C<$x,$y> default is C<[0,0]>.

B<Note> that while this method is named form I<image>, it is also used for the 
pseudoimages created by the barcode routines. Images are naturally dimensionless
(1 point square) and need at some point to be scaled up to the desired point 
size. Barcodes are naturally sized in points, and should be scaled at 
approximately I<1>. Therefore, it would greatly overscale barcodes to multiply 
by image width and height I<within> C<formimage>, and require scaling of 
1/width and 1/height in the call. So, we leave scaling alone within 
C<formimage> and have the user manually scale I<images> by the image width and 
height (in pixels) in the call to C<formimage>.

=back

=cut

sub formimage {
    my ($self, $img, $x,$y, $sx,$sy) = @_;

    if (!defined $y) { $y = 0; }
    if (!defined $x) { $x = 0; }

    # if one scale given, use for both
    # if no scale given, use 1 for both
    if (!defined $sx) { $sx = 1; }
    if (!defined $sy) { $sy = $sx; }

   ## convert to desired height and width in pixels
   #$sx *= $img->width();
   #$sy *= $img->height();

    $self->save();

    $self->matrix($sx,0,0,$sy, $x,$y);
    $self->add('/' . $img->name(), 'Do');
    $self->restore();
    $self->resource('XObject', $img->name(), $img);

    return $self;
}

=head3 object

    $content->object($object, $x,$y, $scale_x,$scale_y)

    $content->object($object, $x,$y, $scale)

    $content->object($object, $x,$y)

    $content->object($object)

=over

Places an image or other external object (a.k.a. XObject) on the page in the
specified location (giving the upper left corner of the object). Note that this
positioning is I<different> from C<image()> and C<formimage()>, which give the
I<lower left> corner!

Up to four optional arguments may be given, with their defaults as described
below.

C<$x> and C<$y> are the I<upper left> corner of the object. If they are 
omitted, the object will be placed with its I<lower left> corner at C<[0, 0]>.
B<Note> that if the object's bounding box has the fourth value (maximum
ascender) greater than 0, you may need to subtract that value from C<y> to get
the desired vertical position! A typical application will have a bounding box
of C<[0, -height, width, 0]>, and no correction is needed. If the bounding box
is C<[0, -max_descender, width, max_ascender]>, you may need to add the
correction.

For images, C<$scale_x> and C<$scale_y> represent the width and height of the
image on the page, in points. If C<$scale_x> is omitted, it will default to 72
pixels per inch. If C<$scale_y> is omitted, the image will be scaled
proportionally, based on the image dimensions.

For other external objects, including B<SVG images>, the scale is a 
multiplier, where 1 (the default) represents 100% (i.e., no change).

If coordinate transformations have been made (see Coordinate Transformations
above), the position and scale will be relative to the updated coordinates.

If no coordinate transformations are needed, this method can be called directly
from the L<PDF::Builder::Page> object instead.

If an SVG XObject array (output from C<image_svg()>) is passed in, only the
first [0th] element will be displayed. Any others will be ignored.

=back

=cut

# Behavior based on argument count. xo, UL x,y, scale_x/w,scale_y/h
# 1: Place at 0, 0, 100% (lower left)
# 2: Place at x, 0, 100%
# 3: Place at X, Y, 100%
# 4: Place at X, Y, scaled
# 5: Place at X, Y, scale_w, scale_h
# TBD: size=>'points' or 'scale' to override Image usage. can do by finding
#        an element 'size' (string) and inserting undef's before it to fill
#        out @_ to 7+ in length.

sub object {
    my ($self, $object, $x, $y, $scale_x, $scale_y) = @_;
    $x //= 0;
    $y //= 0;
    $scale_x //= 1;
    $scale_y //= $scale_x;

    my $name;
    if (UNIVERSAL::isa($object,'PDF::Builder::Resource::XObject::Image')) {
        $scale_x = $object->width();
        $scale_y = $object->height() * $scale_x / $object->width();
	$name    = $object->name();

    } elsif (ref($object) eq 'ARRAY') {
	# output from image_svg()
	if (defined $object->[0]) {

	    # simply ignore anything after the first element (first <svg>)
	    my $xo      = $object->[0]->{'xo'};      # hash of content
            my $width   = $object->[0]->{'width'};   # viewBox width
            my $height  = $object->[0]->{'height'};  # viewBox height
	    my $vwidth  = $object->[0]->{'vwidth'};  # desired (design) width
	    my $vheight = $object->[0]->{'vheight'}; # desired (design) height
	    my @vb = @{$object->[0]->{'vbox'}};      # viewBox
	    my @bb = $xo->bbox();                       # bounding box

	    # scale factors to get viewBox dimensions to design dimensions
	    my $flag = 1; # h and v scale will be defined
	    if (!defined $width || !defined $vwidth ||
	        !defined $height || !defined $vheight)  {
	        $flag = 0;
	    }

  	    # bbox: y=0 is baseline, [1] is max descender, [3] is max ascender
	    #       [0] min x (usually 0), [2] max x (usually width).
	    #       if no "baseline", [3] is usually 0 (and [1] is -height)
            my $h = $bb[3] - $bb[1];
	    my ($hscale, $vscale);
	    if ($flag) {
	        $hscale = $vwidth / $width;
                $vscale = $vheight / $height;
	    } else {
	        $hscale = $vscale = 1;
	    }
	    $scale_x *= $hscale;
	    $scale_y *= $vscale;

	    # if x,y = 0,0, assume want that to be the LOWER left corner,
	    #   and rejigger y to be UPPER left
	    if ($x == 0 && $y == 0) {
                $y = $h;
	    }

            # store away in $object where the image bounds are UL to LR, 
	    #    baseline y. only for SVG images, used by higher level apps.
	    if ($bb[3] > 0) {
	        # baseline for equation is above bottom of viewbox
                $object->[0]->{'imageVB'} = [ 
	             $x, $y, 
	             $x+($bb[2]-$bb[0])*$scale_x, $y-$h*$scale_y,
	             $y-($h+$bb[1])*$scale_y
                ];
	    } else {
		# no separate baseline (give as LRy)
                $object->[0]->{'imageVB'} = [ 
	             $x, $y, 
	             $x+($bb[2]-$bb[0])*$scale_x, $y-$h*$scale_y,
	             $y-$h*$scale_y
                ];
	    }

	    # make up a name
	    $name = 'Sv' . pdfkey();

            $self->save();
	    # baseline for equation is above bottom of viewbox
	    # also adjust y position, otherwise MathJax eqn
	    #   itself is too high on page
            $self->matrix($scale_x, 0, 0, $scale_y, $x, $y-$bb[3]*$scale_y);
            $self->add('/' . $name, 'Do');
            $self->restore();

            $self->resource('XObject', $name, $xo);
	    return $self;

	} else {
	    # don't have at least one <svg>
	    carp "attempt to display SVG object with no content.";
	    return $self;
	}
    } else {
        # scale_x/y already set
        $name    = $object->name();
    }

    $self->save();
    $self->matrix($scale_x, 0, 0, $scale_y, $x, $y);
    $self->add('/' . $name, 'Do');
    $self->restore();

    $self->resource('XObject', $name, $object);

    return $self;
}

=head2 Text 

=head3 Text State Parameters

All of the following parameters that take a size are applied before
any scaling takes place, so you don't need to adjust values to
counteract scaling.

=head4 charspace, character_spacing, char_space

    $spacing = $content->charspace($spacing)

=over

Sets additional B<horizontal> spacing between B<characters> in a line. Vertical 
writing systems are not supported. This is in I<points> and is initially zero.
It may be positive to give an I<expanded> effect to words, or
it may be negative to give a I<condensed> effect to words.
If C<$spacing> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$spacing> is not given, the current setting is B<returned>.

One use for character spacing is to adjust I<tracking> in a line of text.
It is common to adjust inter-word spacing (e.g., TeX "glue" length) to justify 
a line (see C<wordspace>), but in cases where the result is words too close 
together (or too far apart), you may want to adjust tracking in order to force 
spaces back to a more "reasonable" standard size. For example, if you have a 
fairly "loose" line, with wide spaces between words, you could add a little 
character spacing between the letters of words, and shrink the spaces down to a 
more reasonable size. Don't overdo it, and make the words themselves difficult
to read! You also would want to take care to "drive" the resulting spaces 
towards a consistent width throughout a document (or at least, a paragraph).

You may also choose to use character spacing for special effects, such as a
high-level heading expanded with extra space. This is a decorative effect, and
should be used with restraint.

Note that interword spaces (x20) I<also> receive additional character space,
in addition to any additional word space (C<wordspace>) defined!

B<CAUTION:> be careful about using C<charspace> if you are using a connected
("script") font. This might include Arabic, Devanagari, Latin cursive 
handwriting, and so on. You don't want to leave gaps between characters, or 
cause overlaps. For such fonts and typefaces, you I<may> need to explicitly set 
the C<charspace> spacing to 0, if you have set it to non-zero elsewhere. 
PDF::Builder may not be able to determine that a given font is a connected
script font, and automatically suppress non-zero character spacing.

B<Alternate names:> C<character_spacing> and C<char_space>

I<character_spacing> is provided for compatibility with PDF::API2, while
I<char_space> is provided to be consistent with many other method name
changes in PDF::API2.

=back

=cut

sub _charspace {
    my ($space) = @_;

    return float($space, 6) . ' Tc';
}

sub character_spacing { return charspace(@_); } ## no critic

sub char_space { return charspace(@_); } ## no critic

sub charspace {
    my ($self, $space) = @_;

    if (defined $space) {
        $self->{' charspace'} = $space;
        $self->add(_charspace($space));

	return $self;
    } else {
        return $self->{' charspace'};
    }
}

=head4 wordspace, word_spacing, word_space

    $spacing = $content->wordspace($spacing)

=over

Sets additional B<horizontal> spacing between B<words> in a line. Vertical 
writing systems are not supported. This is in I<points> and is initially zero 
(i.e., just the width of the space, without anything extra). It may be negative
to close up sentences a bit. 
If C<$spacing> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$spacing> is not given, the current setting is B<returned>.

See the note in C<charspace> in regards to I<tracking> adjustment, and its
effect on C<wordspace>. The two calls may often be used together for optimal
results (although resulting in a somewhat increased PDF file size).

Note that it is a limitation of the PDF specification (as of version 1.7, 
section 9.3.3) that only spacing with an ASCII space (x20) is adjusted. Neither
required blanks (xA0) nor any multiple-byte spaces (including thin and wide
spaces) are currently adjusted. B<However,> multiple I<spaces> between words
I<each> are expanded. E.g., if you have a double x20 space between words, it
will receive I<twice> the expansion of a single space! Furthermore, character
spacing (Tc) is also added to each space, in I<addition> to word spacing (Tw).

B<alternate names:> C<word_spacing> and C<word_space>

I<word_spacing> is provided for compatibility with PDF::API2, while
I<word_space> is provided to be consistent with many other method name
changes in PDF::API2.

=back

=cut

sub _wordspace {
    my ($space) = @_;

    return float($space, 6) . ' Tw';
}

sub word_spacing { return wordspace(@_); } ## no critic

sub word_space { return wordspace(@_); } ## no critic

sub wordspace {
    my ($self, $space) = @_;

    if (defined $space) {
        $self->{' wordspace'} = $space;
        $self->add(_wordspace($space));

	return $self;
    } else {
        return $self->{' wordspace'};
    }
}

=head4 hscale

    $scale = $content->hscale($scale)

=over

Sets the percentage of horizontal text scaling (relative sizing, I<not> 
spacing). This is initially 100 (percent, i.e., no scaling). A scale of greater 
than 100 will stretch the text, while less than 100 will compress it.
If C<$scale> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$scale> is not given, the current setting is B<returned>.

Note that scaling affects all of the character widths, interletter spacing, and
interword spacing. It is inadvisable to stretch or compress text by a large 
amount, as it will quickly make the text unreadable. If your objective is to 
justify text, you will usually be better off using C<charspace> and C<wordspace>
to expand (or slightly condense) a line to fill a desired width. Also see 
the C<text_justify()> calls for this purpose.

=back

=cut

sub _hscale {
    my ($scale) = @_;

    return float($scale, 6) . ' Tz';
}

sub hscale {
    my ($self, $scale) = @_;

    if (defined $scale) {
        $self->{' hscale'} = $scale;
        $self->add(_hscale($scale));

	return $self;
    } else {
        return $self->{' hscale'};
    }
}

# Note: hscale was originally named incorrectly as hspace, renamed
# note that the private class data ' hspace' is no longer supported
# PDF::API2 still provides 'hspace' and '_hspace'

# lead() and the associated lead variable have been replaced by leading()

=head4 leading

    $leading = $content->leading($leading)

    $leading = $content->leading()

=over

Sets the text leading, which is the distance between baselines. This
is initially B<zero> (i.e., the lines will be printed on top of each
other). The unit of leading is points.
If C<$leading> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$leading> is not given, the current setting is B<returned>.

Note that C<leading> here is defined as used in electronic typesetting and
the PDF specification, which is the full interline spacing (text baseline to
text baseline distance, in points). In cold metal typesetting, I<leading> was 
usually the I<extra> spacing between lines beyond the font height itself, 
created by inserting lead (type alloy) shims.

=back

=cut

sub _leading {
    my ($leading) = @_;

    return float($leading) . ' TL';
}

sub leading {
    my ($self, $leading) = @_;

    if (defined $leading) {
        $self->{' leading'} = $leading;
        $self->add(_leading($leading));

	return $self;
    } else {
        return $self->{' leading'};
    }
}

=head4 render

    $mode = $content->render($mode)

=over

Sets the text rendering mode.

=over

=item 0 = Fill text

=item 1 = Stroke text (outline)

=item 2 = Fill, then stroke text

=item 3 = Neither fill nor stroke text (invisible)

=item 4 = Fill text and add to path for clipping

=item 5 = Stroke text and add to path for clipping

=item 6 = Fill, then stroke text and add to path for clipping

=item 7 = Add text to path for clipping

=back

If C<$mode> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$mode> is not given, the current setting is B<returned>.

=back

=cut

sub _render {
    my ($mode) = @_;

    return intg($mode) . ' Tr';
}

sub render {
    my ($self, $mode) = @_;

    if (defined $mode) {
        $mode = max(0, min(7, int($mode))); # restrict to integer range 0..7
        $self->{' render'} = $mode;
        $self->add(_render($mode));

        return $self;
    } else {
        return $self->{' render'};
    }
}

=head4 rise

    $dist = $content->rise($dist)

=over

Adjusts the baseline up or down from its current location.  This is
initially zero. A C<$dist> greater than 0 moves the baseline B<up> the page
(y increases).

Use this for creating superscripts or subscripts (usually along with an
adjustment to the font size).
If C<$dist> is given, the current setting is replaced by that value and
C<$self> is B<returned> (to permit chaining).
If C<$dist> is not given, the current setting is B<returned>.

=back

=cut

sub _rise {
    my ($dist) = @_;

    return float($dist) . ' Ts';
}

sub rise {
    my ($self, $dist) = @_;

    if (defined $dist) {
        $self->{' rise'} = $dist;
        $self->add(_rise($dist));

	return $self;
    } else {
        return $self->{' rise'};
    }
}

=head4 textstate

    %state = $content->textstate('charspace'=>$value, 'wordspace'=>$value, ...)

=over

This is a shortcut for setting multiple text state parameters at once.
If any parameters are set, an I<empty> hash is B<returned>.
This can also be used without arguments to retrieve the current text
state settings (a hash of the state is B<returned>).

B<Note:> This does not work with the C<save> and C<restore> commands.

=back

=cut

sub textstate {
    my ($self) = shift;

    my %state;
    if (@_) {
        %state = @_;
        foreach my $k (qw( charspace hscale wordspace leading rise render )) {
            next unless $state{$k};
            $self->can($k)->($self, $state{$k});
        }
        if ($state{'font'} && $state{'fontsize'}) {
            $self->font($state{'font'}, $state{'fontsize'});
        }
        if ($state{'textmatrix'}) {
            $self->matrix(@{$state{'textmatrix'}});
            @{$self->{' translate'}} = @{$state{'translate'}};
            $self->{' rotate'} = $state{'rotate'};
            @{$self->{' scale'}} = @{$state{'scale'}};
            @{$self->{' skew'}} = @{$state{'skew'}};
        }
        if ($state{'fillcolor'}) {
            $self->fillcolor(@{$state{'fillcolor'}});
        }
        if ($state{'strokecolor'}) {
            $self->strokecolor(@{$state{'strokecolor'}});
        }
        %state = ();
    } else {
        foreach my $k (qw( font fontsize charspace hscale wordspace leading rise render )) {
            $state{$k}=$self->{" $k"};
        }
        $state{'matrix'}         = [@{$self->{" matrix"}}];
        $state{'textmatrix'}     = [@{$self->{" textmatrix"}}];
        $state{'textlinematrix'} = [@{$self->{" textlinematrix"}}];
        $state{'rotate'}         = $self->{" rotate"};
        $state{'scale'}          = [@{$self->{" scale"}}];
        $state{'skew'}           = [@{$self->{" skew"}}];
        $state{'translate'}      = [@{$self->{" translate"}}];
        $state{'fillcolor'}      = [@{$self->{" fillcolor"}}];
        $state{'strokecolor'}    = [@{$self->{" strokecolor"}}];
    }

    return %state;
}

=head4 font

    $content->font($font_object, $size)  # Set

    ($font_object, $size) = $content->font()  # Get

=over

Sets or gets the font and font size. C<$font> is an object created by calling
L<PDF::Builder/"font"> to add the font to the document.

    # Example (12 point Helvetica)
    my $pdf = PDF::Builder->new();

    my $font = $pdf->font('Helvetica');
    $text->font($font, 24);
    $text->position(72, 720);
    $text->text('Hello, World!');

    $pdf->save('sample.pdf');

Or, get the current font object and size setting:

    my ($font, $size) = $text->font();

Results ($font and $size) are indeterminate if font() was not previously called
using them.

=back

=cut

sub _font {
    my ($font, $size) = @_;

    if ($font->isvirtual()) {
        return '/'.$font->fontlist()->[0]->name().' '.float($size).' Tf';
    } else {
        return '/'.$font->name().' '.float($size).' Tf';
    }
}

sub font {
    my ($self, $font, $size) = @_;

    if (!defined $font) { # Get
	$font = $self->{' font'}; 
	$size = $self->{' fontsize'};
	return ($font, $size);
    }

    # otherwise Set
    unless ($size) {
        croak q{A font size is required};
    }
    $self->_fontset($font, $size);
    # buffer the Tf command
    if ($self->{' doPending'}) {
        $self->{' Tpending'}{'Tf'} = _font($font, $size);
    } else {
        $self->add(_font($font, $size));
    }
    $self->{' fontset'} = 1;

    return $self;
}

sub _fontset {
    my ($self, $font, $size) = @_;

    $self->{' font'} = $font;
    $self->{' fontsize'} = $size;
    $self->{' fontset'} = 0;

    if ($font->isvirtual()) {
        foreach my $f (@{$font->fontlist()}) {
            $self->resource('Font', $f->name(), $f);
        }
    } else {
        $self->resource('Font', $font->name(), $font);
    }

    return $self;
}

=head3 Positioning Text

=head4 position

    $content = $content->position($x, $y) # Set (also returns object, for ease of chaining)

    ($x, $y) = $content->position()  # Get

=over

If called I<with> arguments (Set), moves to the start of the current line of 
text, offset by C<$x> and C<$y> (right and up for positive values).

If called I<without> arguments (Get), returns the current position of the 
cursor (before the effects of any coordinate transformation methods).

Note that this is very similar in function to C<distance()>, added recently 
to PDF::API2 and added here for compatibility.

=back

=cut

sub position {
    my ($self, $x, $y) = @_;

    if (defined $x and not defined $y) {
        croak 'position() requires either 0 or 2 arguments';
    }

    if (defined $x) { # Set
	$self->_Tpending();
#       if ($self->{' doPending'}) {
#           $self->{' Tpending'}{'Td'} = float($x).' '.float($y).' Td';
#       } else {
            $self->add(float($x), float($y), 'Td');
#       }
        $self->matrix_update($x, $y);
        $self->{' textlinematrix'}->[0] = $self->{' textlinestart'} + $x;
        $self->{' textlinestart'} = $self->{' textlinematrix'}->[0];
        return $self;
    }

    # Get
    return @{$self->{' textlinematrix'}};
}

=head4 textpos, (see also) position

    ($tx,$ty) = $content->textpos()

=over

B<Returns> the current text position on the page (where next write will happen) 
as an array.

B<Note:> This does not affect the PDF in any way. It only tells you where the
the next write will occur.

B<Alternate name:> C<position> (added for compatibility with PDF::API2)

=back

=cut

sub _textpos {
    my ($self, @xy) = @_;

    my ($x,$y) = (0,0);
    while (scalar @xy > 0) {
        $x += shift @xy;
        $y += shift @xy;
    }
    my @m = _transform(
        'matrix' => $self->{" textmatrix"},
        'point'  => [$x,$y]
    );
    return ($m[0],$m[1]);
}

sub _textpos2 {
    my ($self) = shift;

    return @{$self->{" textlinematrix"}};
}

sub textpos {
    my ($self) = shift;

    return $self->_textpos(@{$self->{" textlinematrix"}});
}

=head4 distance

    $content->distance($dx,$dy)

=over

This moves to the start of the previously-written line, plus an offset by the 
given amounts, which are both required. C<[0,0]> would overwrite the previous 
line, while C<[0,36]> would place the new line 36pt I<above> the old line 
(higher y). The C<$dx> moves to the right, if positive.

C<distance> is analogous to graphic's C<move>, except that it is relative to
the beginning of the previous text write, not to the coordinate origin.
B<Note> that subsequent text writes will be relative to this new starting
(left) point and Y position! E.g., if you give a non-zero C<$dx>, subsequent
lines will be indented by that amount.

=back

=cut

sub distance {
    my ($self, $dx,$dy) = @_;

    $self->_Tpending();
#   if ($self->{' doPending'}) {
#       $self->{' Tpending'}{'Td'} = float($dx).' '.float($dy).' Td';
#   } else {
        $self->add(float($dx), float($dy), 'Td');
#   }
    $self->matrix_update($dx,$dy);
    $self->{' textlinematrix'}->[0] = $self->{' textlinestart'} + $dx;
    $self->{' textlinestart'} = $self->{' textlinematrix'}->[0];

    return $self;
}

=head4 cr

    $content->cr()

    $content->cr($vertical_offset)

    $content->cr(0)

=over

If passed without an argument, moves (down) to the start of the I<next> line 
(distance set by C<leading>). This is similar to C<nl()>.

If passed I<with> an argument, the C<leading> distance is ignored and the next 
line starts that far I<up> the page (positive value) or I<down> the page 
(negative value) from the current line. "Y" increases upward, so a negative
value would normally be used to get to the next line down.

An argument of I<0> would
simply return to the start of the present line, overprinting it with new text.
That is, it acts as a simple carriage return, without a linefeed.

Note that any setting for C<leading> is ignored. If you wish to account for
the C<leading> setting, you may wish to use the C<crlf> method instead.

=back

=cut

sub cr {
    my ($self, $offset) = @_;

    $self->_Tpending();
    if (defined $offset) {
#       if ($self->{' doPending'}) {
#           $self->{' Tpending'}{'Td'} = '0 '.float($offset).' Td';
#       } else {
            $self->add(0, float($offset), 'Td');
#       }
        $self->matrix_update(0, $offset);
    } else {
        $self->add('T*');
        $self->matrix_update(0, $self->leading() * -1);
    }
    $self->{' textlinematrix'}->[0] = $self->{' textlinestart'};

    return $self;
}

=head4 nl

    $content->nl()

    $content->nl($indent)

    $content->nl(0)

=over

Moves to the start of the next line (see C<leading>). If C<$indent> is not given,
or is 0, there is no indentation. Otherwise, indent by that amount (I<out>dent
if a negative value). The unit of measure is hundredths of a "unit of text
space", or roughly 88 per em.

Note that any setting for C<leading> is ignored. If you wish to account for
the C<leading> setting, you may wish to use the C<crlf> method instead.

=back

=cut

sub nl {
    my ($self, $indent) = @_;

    $self->_Tpending();

    # can't use Td, because it permanently changes the line start by $indent
    # same problem using the distance() call
    $self->add('T*');  # go to start of next line
    $self->matrix_update(0, $self->leading() * -1);
    $self->{' textlinematrix'}->[0] = $self->{' textlinestart'};

    if (defined($indent) && $indent != 0) {
	# move right or left by $indent
	$self->add('[' . (-10 * $indent) . '] TJ');
    }

    return $self;
}

=head4 crlf

    $content = $content->crlf()

=over

Moves to the start of the next line, based on the L</"leading"> setting. It
returns its own object, for ease of chaining.

If leading isn't set, a default distance of 120% of the font size will be used.

Added for compatibility with PDF::API2 changes; may be used to replace both
C<cr> and C<nl> methods.

=back

=cut

sub crlf {
    my $self = shift();
    $self->_Tpending();
    my $leading = $self->leading();
    if ($leading or not $self->{' fontsize'}) {
        $self->add('T*');
    }
    else {
        $leading = $self->{' fontsize'} * 1.2;
#       if ($self->{' doPending'}) {
#           $self->{' Tpending'}{'Td'} = '0 '.float($leading * -1).' Td';
#       } else {
            $self->add(0, float($leading * -1), 'Td');
#       }
    }

    $self->matrix_update(0, $leading * -1);
    $self->{' textlinematrix'}->[0] = $self->{' textlinestart'};
    return $self;
}

=head4 advancewidth, text_width

    $width = $content->advancewidth($string, %opts)

=over

Returns the number of points that will be used (horizontally) by the input
string. This assumes all on one line (no line breaking).

Options %opts:

=over

=item 'font' => $f3_TimesRoman

Change the font used, overriding $self->{' font'}. The font must have been
previously created (i.e., is not the name). Example: use Times-Roman.

=item 'fontsize' => 12

Change the font size, overriding $self->{' fontsize'}. Example: 12 pt font.

=item 'wordspace' => 0.8

Change the additional word spacing, overriding $self->wordspace(). 
Example: add 0.8 pt between words.

=item 'charspace' => -2.1

Change the additional character spacing, overriding $self->charspace(). 
Example: subtract 2.1 pt between letters, to condense the text.

=item 'hscale' => 125

Change the horizontal scaling factor, overriding $self->hscale(). 
Example: stretch text to 125% of its natural width.

=back

B<Returns> the B<width of the $string> (when set as a line of type), based 
on all currently set text-state
attributes. These can optionally be overridden with %opts. I<Note that these
values temporarily B<replace> the existing values, B<not> scaling them up or
down.> For example, if the existing charspace is 2, and you give in options
a value of 3, the value used is 3, not 5.

B<Note:> This does not affect the PDF in any way. It only tells you how much
horizontal space a text string will take up.

B<Alternate name:> C<text_width>

This is provided for compatibility with PDF::API2.

=back

=cut

sub text_width { return advancewidth(@_); } ## no critic

sub advancewidth {
    my ($self, $text, %opts) = @_;

    my ($glyph_width, $num_space, $num_char, $word_spaces,
	$char_spaces, $advance);

    return 0 unless defined($text) and length($text);
    # fill %opts from current settings unless explicitly given
    foreach my $k (qw[ font fontsize wordspace charspace hscale]) {
        $opts{$k} = $self->{" $k"} unless defined $opts{$k};
    }
    # any other options given are ignored
    
    # $opts{'font'} (not ' font'}) needs to be defined. fail if not.
    # other code should first fatal error in text() call, this is a fallback
    return 0 if !defined $opts{'font'};

    # leading, trailing, extra spaces are counted (not squeezed out)
    # width of text without adjusting char and word spacing
    $glyph_width = $opts{'font'}->width($text)*$opts{'fontsize'};
    # how many ASCII spaces x20. TBD: account for other size spaces, maybe tabs
    $num_space   = $text =~ y/\x20/\x20/;
    # how many characters in all, including spaces
    $num_char    = length($text);
    # how many points to add to width due to spaces. note that doubled 
    # interword spaces count as two (or more) word spaces, not just one
    $word_spaces = $opts{'wordspace'}*$num_space;
    # intercharacter additional spacing (note that interword spaces count
    # as normal characters here. TBD: check PDF spec if that is correct).
    # want extra space after EACH character, including the one on the end, not
    # just between each character WITHIN the text string.
    $char_spaces = $opts{'charspace'}*$num_char;
    $advance     = ($glyph_width+$word_spaces+$char_spaces)*$opts{'hscale'}/100;

    return $advance;
}

=head3 Rendering Text

=head4 Single Lines

=head4 text

    $width = $content->text($text, %opts)

=over

Adds text to the page (left justified by default). 
The width used (in points) is B<returned>.

Options:

=over

=item 'align' => position

Align the text, assuming left-to-right writing direction (RTL/bidirectional is
not currently supported).

=over

=item 'l' or 'left' (case insensitive).

B<default.> Text I<begins> at the current text position.

=item 'c' or 'center' (case insensitive).

Text is I<centered> at the current text position.

=item 'r' or 'right' (case insensitive). 

Text I<ends> (is right justified to) at the current text position.

=back

In all cases, the ending text position is at the (right) end of the text.
If mixing various alignments, you should explicitly place the current text
position so as to not overwrite earlier text.

=item 'indent' => $distance

Indents the text by the number of points (A value less than 0 gives an
I<outdent>).
The indentation amount moves the text left (negative indentation) or right 
(positive indentation), regardless of alignment. This allows desired alignment
effects (for centered and right) that aren't exactly aligned on the current 
position. For example, consider a column of decimal numbers centered on a
desired I<x> position, but aligned on their decimal points. The C<indent>
would be on a per-line basis, adjusted by the length of the number and the
decimal position.

=item 'underline' => 'none'

=item 'underline' => 'auto'

=item 'underline' => $distance

=item 'underline' => [$distance, $thickness, ...]

Underlines the text. C<$distance> is the number of units beneath the
baseline, and C<$thickness> is the width of the line.
Multiple underlines can be made by passing several distances and
thicknesses. 
A value of 'none' means no underlining (is the default).

Example:
 
    # 3 underlines:
    #   distance 4, thickness 1, color red
    #   distance 7, thickness 1.5, color yellow
    #   distance 11, thickness 2, color (strokecolor default)
    'underline' => [4,[1,'red'],7,[1.5,'yellow'],11,2],

=item 'strikethru' => 'none'

=item 'strikethru' => 'auto'

=item 'strikethru' => $distance

=item 'strikethru' => [$distance, $thickness, ...]

Strikes through the text (like HTML I<s> tag). A value of 'auto' places the
line about 30% of the font size above the baseline, or a specified C<$distance>
(above the baseline) and C<$thickness> (in points).
Multiple strikethroughs can be made by passing several distances and
thicknesses.
A value of 'none' means no strikethrough. It is the default.

Example:
 
    # 2 strikethroughs:
    #   distance 4, thickness 1, color red
    #   distance 7, thickness 1.5, color yellow
    'strikethru' => [4,[1,'red'],7,[1.5,'yellow']],

=item 'strokecolor' => color_spec

Defines the underline or strikethru line color, if different from the text
color.

=back

=back

=cut

# TBD: consider 'overline' similar to underline
#      bidirectional/RTL identation, alignment meanings?

sub _text_underline {
    my ($self, $xy1,$xy2, $underline, $color) = @_;

    $color ||= 'black';
    my @underline = ();
    if (ref($underline) eq 'ARRAY') {
        @underline = @{$underline};
    } else {
		if ($underline eq 'none') { return; }
        @underline = ($underline, 1);
    }
    push @underline,1 if @underline%2;

    my $upem = $self->{' font'}->upem();
    my $underlineposition = (-$self->{' font'}->underlineposition()*$self->{' fontsize'}/$upem ||1);
    my $underlinethickness = ($self->{' font'}->underlinethickness()*$self->{' fontsize'}/$upem ||1);
    my $pos = 1;

    while (@underline) {
        $self->add_post(_save());

        my $distance = shift @underline;
        my $thickness = shift @underline;
        my $scolor = $color;
        if (ref($thickness)) {
            ($thickness, $scolor) = @{$thickness};
        }

        if ($distance eq 'auto') {
            $distance = $pos*$underlineposition;
        }
        if ($thickness eq 'auto') {
            $thickness = $underlinethickness;
        }

        my ($x1,$y1, $x2,$y2);
        my $h = $distance+($thickness/2);
        if (scalar(@{$xy1}) > 2) {
            # actual baseline start and end points, not old reduced method
            my @xyz = @{$xy1};
            $x1 = $xyz[1]; $y1 = $xyz[2] - $h;
            @xyz = @{$xy2};
            $x2 = $xyz[1]; $y2 = $xyz[2] - $h;
        } else {
            ($x1,$y1) = $self->_textpos(@{$xy1}, 0, -$h);
            ($x2,$y2) = $self->_textpos(@{$xy2}, 0, -$h);
		}

        $self->add_post($self->_strokecolor($scolor));
        $self->add_post(_linewidth($thickness));
        $self->add_post(_move($x1,$y1));
        $self->add_post(_line($x2,$y2));
        $self->add_post(_stroke);

        $self->add_post(_restore());
        $pos++;
    }
    return;
}

sub _text_strikethru {
    my ($self, $xy1,$xy2, $strikethru, $color) = @_;

    $color ||= 'black';
    my @strikethru = ();
    if (ref($strikethru) eq 'ARRAY') {
        @strikethru = @{$strikethru};
    } else {
		if ($strikethru eq 'none') { return; }
        @strikethru = ($strikethru, 1);
    }
    push @strikethru,1 if @strikethru%2;

    my $upem = $self->{' font'}->upem();
   # fonts define an underline position and thickness, but not strikethrough
   # ideally would be just under 1ex
   #my $strikethruposition = (-$self->{' font'}->strikethruposition()*$self->{' fontsize'}/$upem ||1);
    my $strikethruposition = 5*(($self->{' fontsize'}||20)/20);  # >0 is up
   # let's borrow the underline thickness for strikethrough purposes
    my $strikethruthickness = ($self->{' font'}->underlinethickness()*$self->{' fontsize'}/$upem ||1);
    my $pos = 1;

    while (@strikethru) {
        $self->add_post(_save());

        my $distance = shift @strikethru;
        my $thickness = shift @strikethru;
        my $scolor = $color;
        if (ref($thickness)) {
            ($thickness, $scolor) = @{$thickness};
        }

        if ($distance eq 'auto') {
            $distance = $pos*$strikethruposition;
        }
        if ($thickness eq 'auto') {
            $thickness = $strikethruthickness;
        }

        my ($x1,$y1, $x2,$y2);
        my $h = $distance+($thickness/2);
        if (scalar(@{$xy1}) > 2) {
            # actual baseline start and end points, not old reduced method
            my @xyz = @{$xy1};
            $x1 = $xyz[1]; $y1 = $xyz[2] + $h;
            @xyz = @{$xy2};
            $x2 = $xyz[1]; $y2 = $xyz[2] + $h;
        } else {
            ($x1,$y1) = $self->_textpos(@{$xy1}, 0, $h);
            ($x2,$y2) = $self->_textpos(@{$xy2}, 0, $h);
        }

        $self->add_post($self->_strokecolor($scolor));
        $self->add_post(_linewidth($thickness));
        $self->add_post(_move($x1,$y1));
        $self->add_post(_line($x2,$y2));
        $self->add_post(_stroke);

        $self->add_post(_restore());
        $pos++;
    }
    return;
}

sub text {
    my ($self, $text, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-align'} && !defined $opts{'align'}) { $opts{'align'} = delete($opts{'-align'}); }
    if (defined $opts{'-indent'} && !defined $opts{'indent'}) { $opts{'indent'} = delete($opts{'-indent'}); }
    if (defined $opts{'-underline'} && !defined $opts{'underline'}) { $opts{'underline'} = delete($opts{'-underline'}); }
    if (defined $opts{'-strokecolor'} && !defined $opts{'strokecolor'}) { $opts{'strokecolor'} = delete($opts{'-strokecolor'}); }
    if (defined $opts{'-strikethru'} && !defined $opts{'strikethru'}) { $opts{'strikethru'} = delete($opts{'-strikethru'}); }

    my $align = 'l'; # default
    if (defined $opts{'align'}) {
	$align = lc($opts{'align'});
	if      ($align eq 'l' || $align eq 'left') {
	    $align = 'l';
	} elsif ($align eq 'c' || $align eq 'center') {
	    $align = 'c';
	} elsif ($align eq 'r' || $align eq 'right') {
	    $align = 'r';
	} elsif ($align eq 'j' || $align eq 'justified') {
	    $align = 'j';
	} else {
	    $align = 'l'; # silent error on bad alignment
	}
    }

    $self->_Tpending(); # flush any accumulated PDF text settings

    if ($self->{' fontset'} == 0) {
        unless (defined($self->{' font'}) and $self->{' fontsize'}) {
            croak q{Can't add text without first setting a font and font size};
        }
        $self->font($self->{' font'}, $self->{' fontsize'});
        $self->{' fontset'} = 1;
    }

    my $wd = $self->advancewidth($text);

    my $indent = 0; # default
    if (defined $opts{'indent'}) {
	$indent = $opts{'indent'};
	# indent may be negative to "outdent" a line
	# TBD: later may define indentation for RTL/bidirectional
    }

    # now have alignment, indentation amount, text width
    # adjust indentation by text width and alignment. negative to move text left
    if      ($align eq 'l' || $align eq 'j') {
	# no change
    } elsif ($align eq 'c') {
	$indent -= $wd/2;
    } else { # 'r'
	$indent -= $wd;
    }

    # indent is points to move text left (<0) or right (>0)
    # per input 'indent' AND alignment AND text width
    $self->matrix_update($indent, 0) if ($indent); # move current pos to start

    my $ulxy1 = [$self->_textpos2()]; # x,y start of under/thru line

    if ($indent) {
	# indent is positive >0 to move right (explicit 'indent' optional 
	# amount plus left adjustment for centered or right alignment). 
	# convert to milliems and scale
        $self->add(
	    $self->{' font'}->text(
		$text, 
		$self->{' fontsize'}, 
	        -$indent*(1000/$self->{' fontsize'})*(100/$self->hscale()) ));
    } else {
	# indent ended up 0
        $self->add(
	    $self->{' font'}->text(
		$text, 
		$self->{' fontsize'} ));
    }

    $self->matrix_update($wd, 0); # move current position right to end of text
    # regardless of alignment used.
    # TBD need to check if will be left end for RTL/bidirectional

    my $ulxy2 = [$self->_textpos2()]; # x,y end of under/thru line

    if (defined $opts{'underline'}) {
        $self->_text_underline($ulxy1,$ulxy2, $opts{'underline'}, $opts{'strokecolor'});
    }

    if (defined $opts{'strikethru'}) {
        $self->_text_strikethru($ulxy1,$ulxy2, $opts{'strikethru'}, $opts{'strokecolor'});
    }

    return $wd;
}

sub _metaStart {
    my ($self, $tag, $obj) = @_;

    $self->add("/$tag");
    if (defined $obj) {
        my $dict = PDFDict();
        $dict->{'Metadata'} = $obj;
        $self->resource('Properties', $obj->name(), $dict);
        $self->add('/'.($obj->name()));
        $self->add('BDC');
    } else {
        $self->add('BMC');
    }
    return $self;
}

sub _metaEnd {
    my ($self) = shift;

    $self->add('EMC');
    return $self;
}

=head4 textHS

    $width = $content->textHS($HSarray, $settings, %opts)

=over

Takes an array of hashes produced by HarfBuzz::Shaper and outputs them to the
PDF output file. HarfBuzz outputs glyph CIDs and positioning information. 
It may rearrange and swap characters (glyphs), and the result may bear no
resemblance to the original Unicode point list. You should see 
examples/HarfBuzz.pl, which shows a number of examples with Latin and non-Latin 
text, as well as vertical writing. 
https://www.catskilltech.com/Examples has a sample available in case you want 
to see some examples of what HarfBuzz can do, and don't yet have 
HarfBuzz::Shaper installed.

=over

=item $HSarray

This is the reference to array of hashes produced by HarfBuzz::Shaper, normally 
unchanged after being created (but I<can> be modified). See 
L<PDF::Builder::Docs/Using Shaper> for some things that can be done.

=item $settings

This a reference to a hash of various pieces of information that C<textHS()> 
needs in order to function. They include:

=over

=item 'script' => 'script_name'

This is the standard 4 letter code (e.g., 'Latn') for the script (alphabet and
writing system) you're using. Currently, only Latn (Western writing systems)
do kerning, and 'Latn' is the default. HarfBuzz::Shaper will usually be able to 
figure out from the Unicode points used what the script is, and you might be 
able to use the C<set_script()> call to override its guess. However, 
PDF::Builder and HarfBuzz::Shaper do not talk to each other about the script 
being used.

=item 'features' => array_of_features

This item is B<required>, but may be empty, e.g., 
C<$settings-E<gt>{'features'} = ();>.
It can include switches using the standard HarfBuzz naming, and a + or -
switch, such as '-liga' to turn B<off> ligatures. '-liga' and '-kern', to turn
off ligatures and kerning, are the only features supported currently. B<Note>
that this is separate from any switches for features that you send to 
HarfBuzz::Shaper (with C<$hb-E<gt>add_features()>, etc.) when you run it 
(before C<textHS()>).

=item 'language' => 'language_code'

This item is optional and currently does not appear to have any substantial
effect with HarfBuzz::Shaper. It is the standard code for the
language to be used, such as 'en' or 'en_US'. You might need to define this for
HarfBuzz::Shaper, in case that system can't surmise the language rules to be 
used.

=item 'dir' => 'flag'

Tell C<textHS()> whether this text is to be written in a Left-To-Right manner 
(B<L>, the B<default>), Right-To-Left (B<R>), Top-To-Bottom (B<T>), or 
Bottom-To-Top (B<B>). From the script used (Unicode points), HarfBuzz::Shaper 
can usually figure out what direction to write text in. Also, HarfBuzz::Shaper 
does not share its information with PDF::Builder -- you need to separately 
specify the direction, unless you want to accept the default LTR direction. You 
I<can> use HarfBuzz::Shaper's C<get_direction()> call (in addition to 
C<get_language()> and C<get_script()>) to see what HarfBuzz thinks is the 
correct text direction. C<set_direction()> may be used to override Shaper's
guess as to the direction.

By the way, if the direction is RTL, HarfBuzz will reverse the text and return 
an array with the last character first (to be written LTR). Likewise, for BTT, 
HarfBuzz will reverse the text and return a string to be written from the top 
down. Languages which are normally written horizontally are usually set 
vertically with direction TTB. If setting text vertically, ligatures and 
kerning, as well as character connectivity for cursive scripts, are 
automatically turned off, so don't let the direction default to LTR or RTL in 
the Shaper call, and then try to fix it up in C<textHS()>.

=item align => 'flag'

Given the current output location, align the
text at the B<B>eginning of the line (left for LTR, right for RTL), B<C>entered
at the location, or at the B<E>nd of the line (right for LTR, left for RTL).
The default is B<B>. B<C>entered is analogous to using C<text_center()>, and
B<E>nd is analogous to using C<text_right()>. Similar alignments are done for
TTB and BTT.

=item 'dump' => flag

Set to 1, it prints out positioning and glyph CID information (to STDOUT) for
each glyph in the chunk. The default is 0 (no information dump).

=item 'minKern' => amount (default 1)

If the amount of kerning (font character width B<differs from> glyph I<ax> 
value) is I<larger> than this many character grid units, use the unaltered ax 
for the width (C<textHS()> will output a kern amount in the TJ operation). 
Otherwise, ignore kerning and use ax of the actual character width. The intent 
is to avoid bloating the PDF code with unnecessary tiny kerning adjustments in 
the TJ operation.

=back

=item %opts

This a hash of options.

=over

=item 'underline' => underlining_instructions

See C<text()> for available instructions.

=item 'strikethru' => strikethrough_instructions

See C<text()> for available instructions.

=item 'strokecolor' => line_color

Color specification (e.g., 'green', '#FF3377') for underline or strikethrough,
if not given in an array with their instructions.

=back

=back

Text is sent I<separately> to HarfBuzz::Shaper in 'chunks' ('segments') of a 
single script (alphabet), a
single direction (LTR, RTL, TTB, or BTT), a single font file, 
and a single font size. A 
chunk may consist of a large amount of text, but at present, C<textHS()> can 
only output a single line. For long lines that need to be split into 
column-width lines, the best way may be to take the array of hashes returned by
HarfBuzz::Shaper and split it into smaller chunks at spaces and other 
whitespace. You may have to query the font to see what the glyph CIDs are for 
space and anything else used.

It is expected that when C<textHS()> is called, that the font and font size
have already been set in PDF::Builder code, as this information is needed to
interpret what HarfBuzz::Shaper is returning, and to write it to the PDF file.
Needless to say, the font should be opened from the same file as was given
to HarfBuzz::Shaper (C<ttfont()> only, with .ttf or .otf files), and the font
size must be the same. The appropriate location on the page must also already
have been specified.

=back

=cut

sub textHS {
    my ($self, $HSarray, $settings, %opts) = @_;
    # TBD justify would be multiple lines split up from a long string,
    #       not really applicable here
    #     full justification to stretch/squeeze a line to fit a given width
    #       might better be done on the $info array out of Shaper
    #     indent probably not useful at this level
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-underline'} && !defined $opts{'underline'}) { $opts{'underline'} = delete($opts{'-underline'}); }
    if (defined $opts{'-strikethru'} && !defined $opts{'strikethru'}) { $opts{'strikethru'} = delete($opts{'-strikethru'}); }
    if (defined $opts{'-strokecolor'} && !defined $opts{'strokecolor'}) { $opts{'strokecolor'} = delete($opts{'-strokecolor'}); }

    $self->_Tpending();

    my $font = $self->{' font'};
    my $fontsize = $self->{' fontsize'};
    my $dir = $settings->{'dir'} || 'L';
    my $align = $settings->{'align'} || 'B';
    my $dump = $settings->{'dump'} || 0;
    my $script = $settings->{'script'} || 'Latn';  # Latn (Latin), etc.
    my $language;  # not used
    if (defined $settings->{'language'}) { 
	$language = $settings->{'language'}; 
    }
    my $minKern = $settings->{'minKern'} || 1; # greater than 1 don't omit kern
    my (@ulxy1, @ulxy2);

    my $dokern = 1; # why did they take away smartmatch???
    foreach my $feature (@{ $settings->{'features'} }) { 
	if ($feature ne '-kern') { next; }
        $dokern = 0;
	last;
    }
    if ($dir eq 'T' || $dir eq 'B') { $dokern = 0; }

    # check if font and font size set
    if ($self->{' fontset'} == 0) {
        unless (defined($self->{' font'}) and $self->{' fontsize'}) {
            croak q{Can't add text without first setting a font and font size};
        }
        $self->font($self->{' font'}, $self->{' fontsize'});
        $self->{' fontset'} = 1;
    }
    # TBD consider indent option   (at Beginning of line)

    # Horiz width, Vert height
    my $chunkLength = $self->advancewidthHS($HSarray, $settings, 
	              %opts, 'doKern'=>$dokern, 'minKern'=>$minKern);
    my $kernPts = 0; # amount of kerning (left adjust) this glyph
    my $prevKernPts = 0; # amount previous glyph (THIS TJ operator)

    # Ltr: lower left of next character box
    # Rtl: lower right of next character box
    # Ttb: center top of next character box
    # Btt: center bottom of next character box
    my @currentOffset = (0, 0);
    my @currentPos = $self->textpos();
    my @startPos = @currentPos;

    my $mult;
    # need to first back up (to left) to write chunk
    # LTR/TTB B and RTL/BTT E write (LTR/TTB) at current position anyway
    if ($dir eq 'L' || $dir eq 'T') {
	if      ($align eq 'B') {
	    $mult = 0;
	} elsif ($align eq 'C') {
	    $mult = -.5;
	} else { # align E
	    $mult = -1;
	}
    } else { # dir R or B
	if      ($align eq 'B') {
	    $mult = -1;
	} elsif ($align eq 'C') {
	    $mult = -.5;
	} else { # align E
	    $mult = 0;
	}
    }
    if ($mult != 0) {
        if ($dir eq 'L' || $dir eq 'R') {
            $self->translate($currentPos[0]+$chunkLength*$mult, $currentPos[1]);
            # now can just write chunk LTR
        } else {
            $self->translate($currentPos[0], $currentPos[1]-$chunkLength*$mult);
            # now can just write chunk TTB
	}
    }

    # start of any underline or strikethru
    @ulxy1 = (0, $self->textpos());

    foreach my $glyph (@$HSarray) { # loop through all glyphs in chunk
	my $ax = $glyph->{'ax'}; # output as LTR, +ax = advance to right
	my $ay = $glyph->{'ay'};
	my $dx = $glyph->{'dx'};
	my $dy = $glyph->{'dy'};
	my  $g = $glyph->{'g'};
	my $gCID = sprintf("%04x", $g);
	my $cw = $ax;
	    
	# kerning for any LTR or RTL script? not just Latin script?
        if ($dokern) { 
	    # kerning, etc. cw != ax, but ignore tiny differences
	    # cw = width font (and Reader) thinks character is
            $cw = $font->wxByCId($g)/1000*$fontsize;
	    # if kerning ( ax < cw ), set kern amount as difference.
	    # very small amounts ignore by setting ax = cw 
	    # (> minKern? use the kerning, else ax = cw)
	    # Shaper may expand spacing, too!
	    $kernPts = $cw - $ax;  # sometimes < 0 !
	    if ($kernPts != 0) {
	        if (int(abs($kernPts*1000/$fontsize)+0.5) <= $minKern) {
	            # small amount, cancel kerning
		    $kernPts = 0;
		    $ax = $cw;
		}
	    }
	    if ($dump && $cw != $ax) {
            print "cw exceeds ax by ".sprintf("%.2f", $cw-$ax)."\n";
	    }
	    # kerning to NEXT glyph (used on next loop)
	    # this is why we use axs and axr instead of changing ax, so it
	    # won't think a huge amount of kerning is requested!
	}

	if ($dump) {
            print "glyph CID $g ";
            if ($glyph->{'name'} ne '') { print "name '$glyph->{'name'}' "; }
            print "offset x/y $dx/$dy ";
	    print "orig. ax $ax ";
	} # continued after $ax modification...

        # keep coordinated with advancewidthHS(), see for documentation
	if      (defined $glyph->{'axs'}) {
	    $ax = $glyph->{'axs'};
	} elsif (defined $glyph->{'axsp'}) {
	    $ax *= $glyph->{'axsp'}/100;
	} elsif (defined $glyph->{'axr'}) {
	    $ax -= $glyph->{'axr'};
	} elsif (defined $glyph->{'axrp'}) {
	    $ax *= (1 - $glyph->{'axrp'}/100);
	}

	if ($dump) { # ...continued
            print "advance x/y $ax/$ay ";  # modified ax
            print "char width $cw ";
	        if ($ay != 0 || $dx != 0 || $dy != 0) {
	            print "! "; # flag that adjustments needed
	        }
	        if ($kernPts != 0) {
	            print "!! "; # flag that kerning is apparently done
	        }
            print "\n";
	}

	# dy not 0? end everything and output Td and do a Tj
	# internal location (textpos) should be at dx=dy=0, as should
	# be currentOffset array. however, Reader current position is
	# likely to be at last Tm or Td.
	# note that RTL is output LTR
	if ($dy != 0) {
	    $self->_endCID();

	    # consider ignoring any kern request, if vertically adjusting dy
	    my $xadj = $dx - $prevKernPts;
	    my $yadj = $dy;
            # currentOffset should be at beginning of glyph before dx/dy
	    # text matrix should be there, too
	    # Reader is still back at Tm/Td plus any glyphs so far
            @currentPos = ($currentPos[0]+$currentOffset[0]+$xadj, 
 	                   $currentPos[1]+$currentOffset[1]+$yadj); 
#           $self->translate(@currentPos);
 	    $self->distance($currentOffset[0]+$xadj,
	                    $currentOffset[1]+$yadj);

	    $self->add("<$gCID> Tj");
	    # add glyph to subset list
	    $font->fontfile()->subsetByCId($g);

	    @currentOffset = (0, 0);
	    # restore positions to base line for next character
		@currentPos = ($currentPos[0]+$prevKernPts-$dx+$ax, 
 		               $currentPos[1]-$dy+$ay); 
#	    $self->translate(@currentPos);
 	    $self->distance($prevKernPts-$dx+$ax, -$dy+$ay);

	} else {
	    # otherwise simply add glyph to TJ array, with possible x adj
	    $self->_outputCID($gCID, $dx, $prevKernPts, $font);
	    $currentOffset[0] += $ax + $dx;
	    $currentOffset[1] += $ay;  # for LTR/RTL probably always 0
 	    $self->matrix_update($ax + $dx, $ay);
	}

	$prevKernPts = $kernPts; # for next glyph's adjustment
	$kernPts = 0;
    } # end of chunk by individual glyphs
    $self->_endCID();

    # if LTR, need to move to right end, if RTL, need to return to left end.
    # if TTB, need to move to the bottom, if BTT, need to return to top
    if ($dir eq 'L' || $dir eq 'T') {
	if      ($align eq 'B') {
	    $mult = 1;
	} elsif ($align eq 'C') {
	    $mult = .5;
	} else { # align E
	    $mult = 0;
	}
    } else { # dir R or B
	    $mult = -1;
	if      ($align eq 'B') {
	} elsif ($align eq 'C') {
	    $mult = -.5;
	} else { # align E
	    $mult = 0;
	}
    }
    if ($dir eq 'L' || $dir eq 'R') {
        $self->translate($startPos[0]+$chunkLength*$mult, $startPos[1]);
    } else {
        $self->translate($startPos[0], $startPos[1]-$chunkLength*$mult);
    }

    if ($dir eq 'L' || $dir eq 'R') {
        @ulxy2 = (0, $ulxy1[1]+$chunkLength, $ulxy1[2]);
    } else {
        @ulxy2 = (0, $ulxy1[1], $ulxy1[2]-$chunkLength);
    }

    # need to swap ulxy1 and ulxy2? draw UL or ST L to R. direction of 'up'
    # depends on LTR, so doesn't work if draw RTL. ditto for TTB/BTT.
    if (($dir eq 'L' || $dir eq 'R') && $ulxy1[1] > $ulxy2[1] ||
        ($dir eq 'T' || $dir eq 'B') && $ulxy1[2] < $ulxy2[2]) {
        my $t; 
        $t = $ulxy1[1]; $ulxy1[1]=$ulxy2[1]; $ulxy2[1]=$t;
        $t = $ulxy1[2]; $ulxy1[2]=$ulxy2[2]; $ulxy2[2]=$t;
    }

    # handle outputting underline and strikethru here
    if (defined $opts{'underline'}) {
        $self->_text_underline(\@ulxy1,\@ulxy2, $opts{'underline'}, $opts{'strokecolor'});
    }
    if (defined $opts{'strikethru'}) {
        $self->_text_strikethru(\@ulxy1,\@ulxy2, $opts{'strikethru'}, $opts{'strokecolor'});
    }

    return $chunkLength;
} # end of textHS

# output any pending text state-related commands before ink hits paper
# currently text matrix (Tm), font select (Tf), displacement (Td), 
#           stroke color (text, RG/K/G/SC), fill color (text, rg/k/g/sc)
# future?
sub _Tpending {
    my ($self) = @_;
    my $item;
    foreach (qw(Tf Tm color Color)) {
        $item = $self->{' Tpending'}{$_};
        if (defined $item && $item ne '') {
	    $self->add($item);
	    $self->{' Tpending'}{$_} = '';
        }
    }
    return;
}

# output any pending graphics state-related commands before ink hits paper
# currently stroke color (graphics), fill color (graphics)
# future? linewidth (w), linejoin (j), linecap (J), linedash (d), et al.
sub _Gpending {
    my ($self) = @_;
    my $item;
    foreach (qw(color Color)) {
        $item = $self->{' Gpending'}{$_};
        if (defined $item && $item ne '') {
	    $self->add($item);
	    $self->{' Gpending'}{$_} = '';
        }
    }
    return;
}

sub _startCID {
    my ($self) = @_;
    if ($self->{' openglyphlist'}) { return; }
    $self->addNS(" [<");
    return;
}
 
sub _endCID {
    my ($self) = @_;
    if (!$self->{' openglyphlist'}) { return; }
    $self->addNS(">] TJ ");
    # TBD look into detecting empty list already, avoid <> in TJ
    $self->{' openglyphlist'} = 0;
    return;
}

sub _outputCID {
    my ($self, $glyph, $dx, $kern, $font) = @_;
    # outputs a single glyph to TJ array, either adding to existing glyph 
    # string or starting new one after kern amount. kern > 0 moves left, 
    # dx > 0 moves right, both in points (change to milliems).
    # add glyph to subset list
    $font->fontfile()->subsetByCId(hex($glyph));

    if (!$self->{' openglyphlist'}) {
	# need to output [< first
	$self->_startCID();
	$self->{' openglyphlist'} = 1;
    }

    if ($dx == $kern) { 
	    # no adjustment, just add to existing output
	    $self->addNS($glyph); # <> still open
    } else {
	    $kern -= $dx;
	    # adjust right by dx after closing glyph string
	    # dx>0 is move char RIGHT, kern>0 is move char LEFT, both in points
	    # kern/fontsize*1000 is units to move left, round to 1 decimal place
	    # >0 means move left (in TJ operation) that many char grid units
	    $kern *= (1000/$self->{' fontsize'});
	    # output correction (char grid units) and this glyph in new <> string
	    $self->addNS(sprintf("> %.1f <%s", $kern, $glyph));
	    # TBD look into detecting empty list already, avoid <> in TJ
    }
    return;
}

=head4 advancewidthHS, text_widthHS

    $width = $content->advancewidthHS($HSarray, $settings, %opts)

=over

Returns text chunk width (in points) for Shaper-defined glyph array.
This is the horizontal width for LTR and RTL direction, and the vertical
height for TTB and BTT direction.
B<Note:> You must define the font and font size I<before> calling 
C<advancewidthHS()>.

=over

=item $HSarray

The array reference of glyphs created by the HarfBuzz::Shaper call. 
See C<textHS()> for details.

=item $settings

the hash reference of settings. See C<textHS()> for details.

=over

=item 'dir' => 'L' etc.

the direction of the text, to know which "advance" value to sum up.

=back

=item %opts

Options. Unlike C<advancewidth()>, you
cannot override the font, font size, etc. used by HarfBuzz::Shaper to calculate
the glyph list.

=over

=item 'doKern' => flag (default 1)

If 1, cancel minor kerns per C<minKern> setting. This flag should be 0 (false)
if B<-kern> was passed to HarfBuzz::Shaper (do not kern text).
This is treated as 0 if an ax override setting is given.

=item 'minKern' => amount (default 1)

If the amount of kerning (font character width B<differs from> glyph I<ax> 
value) is I<larger> than this many character grid units, use the unaltered I<ax>
for the width (C<textHS()> will output a kern amount in the TJ operation). 
Otherwise, ignore kerning and use ax of the actual character width. The intent 
is to avoid bloating the PDF code with unnecessary tiny kerning adjustments in 
the TJ operation.

=back

=back

Returns total width in points.

B<Alternate name:> C<text_widthHS>

=back

=cut

sub text_widthHS { return advancewidthHS(@_); } ## no critic

sub advancewidthHS {
    my ($self, $HSarray, $settings, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-doKern'} && !defined $opts{'doKern'}) { $opts{'doKern'} = delete($opts{'-doKern'}); }
    if (defined $opts{'-minKern'} && !defined $opts{'minKern'}) { $opts{'minKern'} = delete($opts{'-minKern'}); }

    # check if font and font size set
    if ($self->{' fontset'} == 0) {
        unless (defined($self->{' font'}) and $self->{' fontsize'}) {
            croak q{Can't add text without first setting a font and font size};
        }
        $self->font($self->{' font'}, $self->{' fontsize'});
        $self->{' fontset'} = 1;
    }

    my $doKern  = $opts{'doKern'}  || 1; # flag
    my $minKern = $opts{'minKern'} || 1; # character grid units (about 1/1000 em)
    my $dir = $settings->{'dir'};
    if ($dir eq 'T' || $dir eq 'B') { # vertical text
	$doKern = 0;
    }

    my $width = 0;
    my $ax = 0;
    my $cw = 0;
    # simply go through the array and add up all the 'ax' values.
    # if 'axs' defined, use that instead of 'ax'
    # if 'axsp' defined, use that percentage of 'ax'
    # if 'axr' defined, reduce 'ax' by that amount (increase if <0)
    # if 'axrp' defined, reduce 'ax' by that percentage (increase if <0)
    #  otherwise use 'ax' value unchanged
    # if vertical text, use ay instead
    #
    # as in textHS(), ignore kerning (small difference between cw and ax)
    # however, if user defined an override of ax, assume they want any
    # resulting kerning! only look at minKern (default 1 char grid unit)
    # if original ax is used.
    
    foreach my $glyph (@$HSarray) {
        $ax = $glyph->{'ax'};
	if ($dir eq 'T' || $dir eq 'B') {
	    $ax = $glyph->{'ay'} * -1;
	}

	if      (defined $glyph->{'axs'}) {
	    $width += $glyph->{'axs'};
	} elsif (defined $glyph->{'axsp'}) {
	    $width += $glyph->{'axsp'}/100 * $ax;
	} elsif (defined $glyph->{'axr'}) {
	    $width += ($ax - $glyph->{'axr'});
	} elsif (defined $glyph->{'axrp'}) {
	    $width += $ax * (1 - $glyph->{'axrp'}/100);
	} else {
	    if ($doKern) {
	        # kerning, etc. cw != ax, but ignore tiny differences
	        my $fontsize = $self->{' fontsize'};
	        # cw = width font (and Reader) thinks character is (points)
	        $cw = $self->{' font'}->wxByCId($glyph->{'g'})/1000*$fontsize;
	        # if kerning ( ax < cw ), set kern amount as difference.
	        # very small amounts ignore by setting ax = cw 
	        # (> minKern? use the kerning, else ax = cw)
	        # textHS() should be making the same adjustment as here
	        my $kernPts = $cw - $ax;  # sometimes < 0 !
	        if ($kernPts > 0) {
	            if (int(abs($kernPts*1000/$fontsize)+0.5) <= $minKern) {
	                # small amount, cancel kerning
	                $ax = $cw;
	            }
	        }
	    }
	    $width += $ax;
	}
    }

    return $width; # height >0 for TTB and BTT
}

=head2 Advanced Methods

=head3 save

    $content->save()

=over

Saves the current I<graphics> state on a PDF stack. See PDF definition 8.4.2 
through 8.4.4 for details. This includes the line width, the line cap style, 
line join style, miter limit, line dash pattern, stroke color, fill color,
current transformation matrix, current clipping port, flatness, and dictname.

This method applies to I<only> I<gfx/graphics> objects. If attempted with
I<text> objects, you will receive a one-time (per run) warning message, and
should update your code B<not> to do save() and restore() on a text object.
Only save() generates the message, as presumably each restore() has already had
a save() performed.

=back

=cut

# 8.4.1 Table 52 Graphics State Parameters (device independent) -----------
# current transformation matrix*, current clipping path*, current color space,
# current color*, TEXT painting parameters (see 9.3), line width*%, line cap*%,
# line join*%, miter limit*%, dash pattern*%, rendering intent%, stroke adjust%,
# blend mode%, soft mask, alpha constant%, alpha source%
# 8.4.1 Table 53 Graphics State Parameters (device dependent) -------------
# overprint%, overprint mode%, black generation%, undercolor removal%, 
# transfer%, halftone%, flatness*%, smoothness%
# 9.3 Table 104 Text State Parameters -------------------------------------
# character spacing+, word spacing+, horizontal scaling+, leading+, text font+, 
# text font size+, text rendering mode+, text rise+, text knockout%
#  * saved on graphics state stack
#  + now saved on graphics state stack since save/restore enabled for text
#  % see ExtGState.pm for setting as extended graphics state

sub _save {
    return 'q';
}

sub save {
    my ($self) = shift;

    our @MSG_COUNT;
    if ($self->_in_text_object()) {
	# warning in text mode, no other effect
	if (!$MSG_COUNT[2]) {
	    print STDERR "Can not call save() or restore() on a text object.\n";
	    $MSG_COUNT[2]++;
	}
    } else {
        $self->_Gpending(); # flush buffered commands
        $self->add(_save());
    }

   return $self;
}

=head3 restore

    $content->restore()

=over

Restores the most recently saved graphics state (see C<save>),
removing it from the stack. You cannot I<restore> the graphics state (pop it off
the stack) unless you have done at least one I<save> (pushed it on the stack).
This method applies to both I<text> and I<gfx/graphics> objects.

=back

=cut

sub _restore {
    return 'Q';
}

sub restore {
    my ($self) = shift;

    if ($self->_in_text_object()) {
	# save() already gave any warning
    } else {
        $self->add(_restore());
    }

   return $self;
}

=head3 add

    $content->add(@content)

=over

Add raw content (arbitrary string(s)) to the PDF stream. 
You will generally want to use the other methods in this class instead,
unless this is in order to implement some PDF operation that PDF::Builder
does not natively support. An array of multiple strings may be given; 
they will be concatenated with spaces between them.

Be careful when doing this, as you are dabbling in the black arts, 
directly setting PDF operations! 

One interesting use is to split up an overly long object stream that is giving 
your editor problems when exploring a PDF file. Add a newline B<add("\n")> 
every few hundred bytes of output or so, to do this. Note that you must use 
double quotes (quotation marks), rather than single quotes (apostrophes).

Use extreme care if inserting B<BT> and B<ET> markers into the PDF stream.
You may want to use C<textstart()> and C<textend()> calls instead, and even
then, there are many side effects either way. It is generally not useful 
to suspend text mode with ET/textend() and BT/textstart(), but it is possible, 
if you I<really> need to do it.

Another, useful, case is when your input PDF is from the B<Chrome browser> 
printing a page to PDF with
headers and/or footers. In some versions, this leaves the PDF page with a
strange scaling (such as the page height in points divided by 3300) and the 
Y-axis flipped so 0 is at the top. This causes problems when trying to add
additional text or graphics in a new text or graphics record, where text is 
flipped (mirrored) upside down and at the wrong end of the page. If this 
happens, you might be able to cure it by adding

    $scale = .23999999; # example, 792/3300, examine PDF or experiment!
     ...
    if ($scale != 1) {
        my @pageDim = $page->mediabox();     # e.g., 0 0 612 792
        my $size_page = $pageDim[3]/$scale;  # 3300 = 792/.23999999
        my $invScale = 1.0/$scale;           # 4.16666684
        $text->add("$invScale 0 0 -$invScale 0 $size_page cm");
    }

as the first output to the C<$text> stream. Unfortunately, it is difficult to
predict exactly what C<$scale> should be, as it may be 3300 units per page, or
a fixed amount. You may need to examine an uncompressed PDF file stream to 
see what is being used. It I<might> be possible to get the input (original) 
PDF into a string and look for a certain pattern of "cm" output

    .2399999 0 0 -.23999999 0 792 cm

or similar, which is not within a save/restore (q/Q). If the stream is 
already compressed, this might not be possible.

=back

=head3 addNS

    $content->addNS(@content)

=over

Like C<add()>, but does B<not> make sure there is a space between each element
and before and after the new content. It is up to I<you> to ensure that any
necessary spaces in the PDF stream are placed there explicitly!

=back

=cut

# add to 'poststream' string (dumped by ET)
sub add_post {
    my ($self) = shift;

    if (@_) {
        unless ($self->{' poststream'} =~ m|\s$|) {
            $self->{' poststream'} .= ' ';
        }
        $self->{' poststream'} .= join(' ', @_) . ' ';
    }

    return $self;
}

sub add {
    my $self = shift;

    if (@_) {
        unless (defined $self->{' stream'} && $self->{' stream'} =~ m|\s$|) {
            $self->{' stream'} .= ' ';
	}
        # have started seeing undefined elements in @_. skip them for now.
       #$self->{' stream'} .= encode('iso-8859-1', join(' ', @_) . ' ');
	my $ecstr = '';
	foreach (@_) {
	    if (defined $_) {
		if ($ecstr eq '') { # first
		    $ecstr = $_;
		} else {
		    $ecstr .= " $_";
		}
	    }
	}
	if ($ecstr ne '') {
            $self->{' stream'} .= encode('iso-8859-1', $ecstr . ' ');
	}
    }

    return $self;
}

sub addNS {
    my $self = shift;

    if (@_) {
       $self->{' stream'} .= encode('iso-8859-1', join('', @_));
    }

    return $self;
}

# Shortcut method for determining if we're inside a text object
# (i.e., between BT and ET). See textstart() and textend().
sub _in_text_object {
    my ($self) = shift;

    return $self->{' apiistext'};
}

=head3 compressFlate

    $content->compressFlate()

=over

Marks content for compression on output.  This is done automatically
in nearly all cases, so you shouldn't need to call this yourself.

The C<new()> call can set the B<compress> parameter to 'flate' (default) to
compress all object streams, or 'none' to suppress compression and allow you
to examine the output in an editor.

=back

=cut

sub compressFlate {
    my $self = shift;

    $self->{'Filter'} = PDFArray(PDFName('FlateDecode'));
    $self->{'-docompress'} = 1;

    return $self;
}

=head3 textstart

    $content->textstart()

=over

Starts a text object (ignored if already in a text object). You will likely 
want to use the C<text()> method (text I<context>, not text output) instead.

Note that calling this method, besides outputting a B<BT> marker, will reset
most text settings to their default values. In addition, B<BT> itself will
reset some transformation matrices.

=back

=cut

sub textstart {
    my ($self) = @_;

    unless ($self->_in_text_object()) {
        $self->add(' BT ');
        $self->{' apiistext'}         = 1;
        $self->{' font'}              = undef;
        $self->{' fontset'}           = 0;
        $self->{' fontsize'}          = 0;
        $self->{' charspace'}         = 0;
        $self->{' hscale'}            = 100;
        $self->{' wordspace'}         = 0;
        $self->{' leading'}           = 0;
        $self->{' rise'}              = 0;
        $self->{' render'}            = 0;
        $self->{' textlinestart'}     = 0;
        @{$self->{' matrix'}}         = (1,0,0,1,0,0);
        @{$self->{' textmatrix'}}     = (1,0,0,1,0,0);
        @{$self->{' textlinematrix'}} = (0,0);
        @{$self->{' fillcolor'}}      = (0);
        @{$self->{' strokecolor'}}    = (0);
        @{$self->{' translate'}}      = (0,0);
        @{$self->{' scale'}}          = (1,1);
        @{$self->{' skew'}}           = (0,0);
        $self->{' rotate'}            = 0;
	$self->{' openglyphlist'}     = 0;
    }

    return $self;
}

=head3 textend

    $content->textend()

=over

Ends a text object (ignored if not in a text object).

Note that calling this method, besides outputting an B<ET> marker, will output
any accumulated I<poststream> content.

=back

=cut

sub textend {
    my ($self) = @_;

    if ($self->_in_text_object()) {
        $self->add(' ET ', $self->{' poststream'});
        $self->{' apiistext'}  = 0;
        $self->{' poststream'} = '';
    }

    return $self;
}

# helper function for many methods
sub resource {
    my ($self, $type, $key, $obj, $force) = @_;

    if ($self->{' apipage'}) {
        # we are a content stream on a page.
        return $self->{' apipage'}->resource($type, $key, $obj, $force);
    } else {
        # we are a self-contained content stream.
        $self->{'Resources'} //= PDFDict();

        my $dict = $self->{'Resources'};
        $dict->realise() if ref($dict) =~ /Objind$/;

        $dict->{$type} ||= PDFDict();
        $dict->{$type}->realise() if ref($dict->{$type}) =~ /Objind$/;
        unless (defined $obj) {
            return $dict->{$type}->{$key} || undef;
        } else {
            if ($force) {
                $dict->{$type}->{$key} = $obj;
            } else {
                $dict->{$type}->{$key} ||= $obj;
            }
            return $dict;
        }
    }
}

1;
