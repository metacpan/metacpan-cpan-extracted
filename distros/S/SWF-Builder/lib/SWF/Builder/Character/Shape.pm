package SWF::Builder::Character::Shape;

use strict;
use Carp;
use SWF::Element;
use SWF::Builder::Character;
use SWF::Builder::ExElement;
use SWF::Builder::Gradient;
use SWF::Builder::Shape;

our $VERSION="0.05";

@SWF::Builder::Character::Shape::ISA = qw/ SWF::Builder::Character::UsableAsMask /;
@SWF::Builder::Character::Shape::Imported::ISA = qw/ SWF::Builder::Character::Imported SWF::Builder::Character::Shape /;

{
    package SWF::Builder::Character::Shape::Def;

    use SWF::Builder::ExElement;

    @SWF::Builder::Character::Shape::Def::ISA = qw/ SWF::Builder::Shape SWF::Builder::Character::Shape SWF::Builder::ExElement::Color::AddColor /;

    sub new {
	my $self = shift->SUPER::new;
    }

    sub _init {
	my $self = shift;
	$self->_init_character;
	$self->_init_is_alpha;

	$self->{_edges} = SWF::Element::SHAPEWITHSTYLE3->ShapeRecords->new;
	$self->{_current_line_width} = -1;
	$self->{_current_line_color} = '';
	$self->{_current_FillStyle0} = '';
	$self->{_current_FillStyle1} = '';
	$self->{_line_styles} = $self->{_shape_line_styles} = SWF::Element::SHAPEWITHSTYLE3->LineStyles->new;
	$self->{_line_style_hash} = {};
	$self->{_fill_styles} = $self->{_shape_fill_styles} = SWF::Element::SHAPEWITHSTYLE3->FillStyles->new;
	$self->{_fill_style_hash} = {};
	$self->{_links} = [];

	$self;
    }

    sub _add_gradient {
	my ($self, $gradient) = @_;

	$self->{_is_alpha}->configure($self->{_is_alpha}->value | $gradient->{_is_alpha}->value);
	return bless {
	    _is_alpha => $self->{_is_alpha},
	    _gradient => $gradient,
	}, 'SWF::Builder::Shape::Gradient';
    }

    sub linestyle {
	my $self = shift;
	my ($index, $width, $color);

	if ($_[0] eq 'none' or $_[0] eq 0) {
	    $index = 0;
	    $width = -1;
	    $color = '';
	} else {
	    my %param;
	    if ($_[0] eq 'Width' or $_[0] eq 'Color') {
		%param = @_;
	    } else {
		%param = (Width => $_[0], Color => $_[1]);
	    }
	    $width = $param{Width};
	    $width = $self->{_current_line_width} unless defined $width;
	    if (defined $param{Color}) {
		$color = $self->_add_color($param{Color});
	    } else {
		$color = $self->{_current_line_color};
	    }
	    return $self if ($width == $self->{_current_line_width} and $color eq $self->{_current_line_color});
	    
	    if (exists $self->{_line_style_hash}{"$width:$color"}) {
		$index = $self->{_line_style_hash}{"$width:$color"};
	    } else {
		if (@{$self->{_line_styles}} >= 65534) {
		    my $r = $self->_get_stylerecord;
		    $self->{_line_styles} = $r->LineStyles;
		    $self->{_line_style_hash} = {};
		    $self->{_fill_styles} = $r->FillStyles;
		    $self->{_fill_style_hash} = {};
		}
		my $ls = $self->{_line_styles};
		push @$ls, $ls->new_element(Width => $width*20, Color => $color);
		$index = $self->{_line_style_hash}{"$width:$color"} = @$ls;
	    }
	}
	$self->_set_style(LineStyle => $index);
	$self->{_current_line_width} = $width;
	$self->{_current_line_color} = $color;
	$self;
    }

    sub _fillstyle {
	my $self = shift;
	my $setstyle = shift;
	my ($index, $fillkey);

	if ($_[0] eq 'none' or $_[0] eq 0) {
	    $index = 0;
	    $fillkey = '';
	} else {
	    my %param;
	    if ($_[0] eq 'Color' or $_[0] eq 'Gradient' or $_[0] eq 'Bitmap') {
		%param = @_;
	    } else {
		for (ref($_[0])) {
		    /Gradient/ and do {
			%param = (Gradient => $_[0], Type => $_[1], Matrix => $_[2]);
			last;
		    };
		    /Bitmap/ and do {
			%param = (Bitmap => $_[0], Type => $_[1], Matrix => $_[2]);
			last;
		    };
		    %param = (Color => $_[0]);
		}
	    }
	    my @param2;

	    $fillkey = join(',', %param);
	    if (exists $param{Gradient}) {
		unless (UNIVERSAL::isa($param{Matrix}, 'SWF::Builder::ExElement::MATRIX')) {
		    $param{Matrix} = SWF::Builder::ExElement::MATRIX->new->init($param{Matrix});
		}
		push @param2, Gradient       => $self->_add_gradient($param{Gradient}),
		              FillStyleType  =>
				 (lc($param{Type}) eq 'radial' ? 0x12 : 0x10), 
			      GradientMatrix => $param{Matrix};
 
	    } elsif (exists $param{Bitmap}) {
		unless (UNIVERSAL::isa($param{Matrix}, 'SWF::Builder::ExElement::MATRIX')) {
		    my $m = $param{Bitmap}->matrix;
		    $m->init($param{Matrix}) if defined $param{Matrix};
		    $param{Matrix} = $m;
		}
		push @param2, BitmapID      => $param{Bitmap}->{ID},
		              FillStyleType =>
				  (lc($param{Type}) =~ /^clip(ped)?$/ ? 0x41 : 0x40),
			      BitmapMatrix  => $param{Matrix};
		$self->{_is_alpha}->configure($self->{_is_alpha} | $param{Bitmap}{_is_alpha});
		$self->_depends($param{Bitmap});
	    } else {
		push @param2, Color => $self->_add_color($param{Color}),
		              FillStyleType => 0x00;
	    }

	    return $self if $self->{"_current_$setstyle"} eq $fillkey;

	    if (exists $self->{_fill_style_hash}{$fillkey}) {
		$index = $self->{_fill_style_hash}{$fillkey};
	    } else {
		if (@{$self->{_fill_styles}} >= 65534) {
		    my $r = $self->_get_stylerecord;
		    $self->{_line_styles} = $r->LineStyles;
		    $self->{_line_style_hash} = {};
		    $self->{_fill_styles} = $r->FillStyles;
		    $self->{_fill_style_hash} = {};
		}
		my $fs = $self->{_fill_styles};
		push @$fs, $fs->new_element(@param2);
		$index = $self->{_fill_style_hash}{$fillkey} = @$fs;
	    }
	}
	$self->_set_style($setstyle => $index);
	$self->{"_current_$setstyle"} = $fillkey;
	$self;
    }

    sub fillstyle {
	my $self = shift;
	_fillstyle($self, 'FillStyle0', @_);
    }

    *fillstyle0 = \&fillstyle;

    sub fillstyle1 {
	my $self = shift;
	_fillstyle($self, 'FillStyle1', @_);
    }

    sub anchor {
	my ($self, $anchor) = @_;

	$self->{_anchors}{$anchor} = [$#{$self->{_edges}}, $self->{_current_X}, $self->{_current_Y}, $#{$self->{_links}}];
	$self->{_last_anchor} = $anchor;
	$self;
    }

    sub _set_bounds {
	my ($self, $x, $y, $f) = @_;
	$self->SUPER::_set_bounds($x, $y);
	return if $f;

	if (defined $self->{_links}[-1]) {
#	    my $cw = $self->{_current_line_width} * 10;
	    my $m = $self->{_links}[-1];
#	    $m->[6]->set_boundary($x-$cw, $y-$cw, $x+$cw, $y+$cw);
	    my (undef, $tlx, $tly) = @{$m->[5]};
	    if ($x*$x+$y*$y < $tlx*$tlx+$tly*$tly) {
		$m->[5] = [$#{$self->{_edges}}, $x, $y];
	    }
	}
    }

    sub _set_style {
	my ($self, %param) = @_;

	if (exists $param{MoveDeltaX} and defined $self->{_links}[-1]) {
	    my $m = $self->{_links}[-1];
	    $m->[1] = $#{$self->{_edges}}; 
	    $m->[3] = $self->{_current_X}; 
	    $m->[4] = $self->{_current_Y}; 
	}

	my $r = $self->SUPER::_set_style(%param);

	if (exists $param{MoveDeltaX}) {
	    my ($x, $y) = ($param{MoveDeltaX}, $param{MoveDeltaY});
	    my @linkinfo = 
		($#{$self->{_edges}},        # start edge index
		 undef,                      # last continuous edge index
		 [$#{$self->{_edges}}],      # STYLECHANGERECORD indice
		 undef,                      # last X
		 undef,                      # last Y
		 [$#{$self->{_edges}}, $x, $y],               # top left
#	         SWF::Builder::ExElement::BoundaryRect->new,  # boundary
		 );
	    if (exists $self->{_links}[-1] and $self->{_links}[-1][0] == $linkinfo[0]) {
		$self->{_links}[-1] = \ @linkinfo;
	    } else {
		push @{$self->{_links}}, \ @linkinfo;
	    }
	    if (defined $self->{_last_anchor}) {
		my $last_anchor = $self->{_anchors}{$self->{_last_anchor}};
		if ($last_anchor->[0] == $#{$self->{_edges}} or $last_anchor->[0] == $#{$self->{_edges}}-1) {
		    $last_anchor->[0] = $#{$self->{_edges}};
		    $last_anchor->[1] = $x;
		    $last_anchor->[2] = $y;
		    $last_anchor->[3] = $#{$self->{_links}};
		}
	    }
	    $r->LineStyle($self->{_line_style_hash}{$self->{_current_line_width}.':'.$self->{_current_line_color}}) unless defined $r->LineStyle;
	    $r->FillStyle0($self->{_fill_style_hash}{$self->{_current_FillStyle0}}) unless defined $r->FillStyle0;
	    $r->FillStyle1($self->{_fill_style_hash}{$self->{_current_FillStyle1}}) unless defined $r->FillStyle1;
	} else {
	    push @{$self->{_links}[-1][2]}, $#{$self->{_edges}} if $self->{_links}[-1][2][-1] != $#{$self->{_edges}};
	}
	$r;
    }

    sub _pack {
	my ($self, $stream) = @_;

	my $tag = ($self->{_is_alpha} ? SWF::Element::Tag::DefineShape3->new : SWF::Element::Tag::DefineShape2->new);
	$tag->ShapeID($self->{ID});
	$tag->ShapeBounds($self->{_bounds});
	$tag->Shapes
	    (
	      FillStyles => $self->{_shape_fill_styles},
	      LineStyles => $self->{_shape_line_styles},
	      ShapeRecords =>$self->{_edges},
	     );
	$tag->pack($stream);
    }
}

#####

{
    package SWF::Builder::Shape::Gradient;

    @SWF::Builder::Shape::Gradient::ISA = ('SWF::Element::Array::GRADIENT3');

    sub pack {
	my ($self, $stream) = @_;

	my $g = $self->{_gradient};
	my $a = $g->{_is_alpha}->value;
	$g->{_is_alpha}->configure($self->{_is_alpha});
	$g->pack($stream);
	$g->{_is_alpha}->configure($a);
    }
}

1;
__END__


=head1 NAME

SWF::Builder::Character::Shape - SWF shape character.

=head1 SYNOPSIS

  my $shape = $mc->new_shape
    ->fillstyle('ff0000')
    ->linestyle(1, '000000')
    ->moveto(0,-11)
    ->lineto(10,6)
    ->lineto(-10,6)
    ->lineto(0,-11);
  my @bbox = $shape->get_bbox;

=head1 DESCRIPTION

SWF shape is defined by a list of edges. Set linestyle for the edges and
fillstyle to fill the enclosed area, and draw edges with 'pen' 
which has own drawing position. 
Most drawing methods draw from the current pen position and move the pen 
to the last drawing position.

=head2 Coordinate System

The positive X-axis points toward right, and the Y-axis points toward down. 
All angles are measured clockwise.
Placing, scaling, and rotating the display instance of the shape are based 
on the origin of the shape coodinates.

=head2 Creator and Display Method

=over 4

=item $shape = $mc->new_shape

returns a new shape character.

=item $disp_i = $shape->place( ... )

returns the display instance of the shape. See L<SWF::Builder>.

=back

=head2 Methods to Draw Edges

All drawing methods return $shape itself. You can call these methods successively.

=over 4

=item $shape->linestyle( [ Width => $width, Color => $color ] )

=item $shape->linestyle( $width, $color )

=item $shape->linestyle( 'none' )

sets line width and color. The color can take a six or eight-figure
hexadecimal string, an array reference of R, G, B, and optional alpha value, 
an array reference of named parameters such as [Red => 255],
and SWF::Element::RGB/RGBA object.
If you set the style 'none', edges are not drawn.

=item $shape->fillstyle( [ Color => $color / Gradient => $gradient, Type => $type, Matrix => $matrix / Bitmap => $bitmap, Type => $type, Matrix => $matrix ] )

=item $shape->fillstyle( $color )

=item $shape->fillstyle( $gradient, $type, $matrix )

=item $shape->fillstyle( $bitmap, $type, $matrix )

=item $shape->fillstyle( 'none' )

sets a fill style.

$color is a solid fill color. 
See $shape->linestyle for the acceptable color value.

$gradient is a gradient object. Give $type 'radial' to fill with 
radial gradient, otherwise linear.
$matrix is a matrix to transform the gradient. 
See L<SWF::Builder::Gradient>.

$bitmap is a bitmap character. Give $type 'clipped' to fill with 
clipped bitmap, otherwise tiled.
$matrix is a matrix to transform the bitmap. 
See L<SWF::Builder::Character::Bitmap>.

=item $shape->fillstyle0( ... )

synonym of $shape->fillstyle.

=item $shape->fillstyle1( ... )

sets an additional fillstyle used in self-overlap shape.

=item $shape->moveto( $x, $y )

moves the pen to ($x, $y).

=item $shape->r_moveto( $dx, $dy )

moves the pen relatively to ( current X + $dx, current Y + $dy ).

=item $shape->lineto( $x, $y [, $x2, $y2, ...] )

draws a connected line to ($x, $y), ($x2, $y2), ...

=item $shape->r_lineto( $dx, $dy [, $dx2, $dy2, ...] )

draws a connected line relatively to ( current X + $dx, current Y + $dy ), 
( former X + $dx2, former Y + $dy2 ), ...

=item $shape->curveto( $cx, $cy, $ax, $ay [,$cx2, $cy2, $ax2, $ay2, ...] )

draws a quadratic Bezier curve to ($ax, $ay)
using ($cx, $cy) as the control point.

=item $shape->r_curveto( $cdx, $cdy, $adx, $ady [,$cdx2, $cdy2, $adx2, $ady2, ...] )

draws a quadratic Bezier curve to 
(current X + $cdx+$adx, current Y + $cdy+$ady)
using (current X + $cdx, current Y + $cdy) as the control point.

=item $shape->curve3to( $cx1, $cy1, $cx2, $cy2, $ax, $ay [, ...] )

draws a cubic Bezier curve to ($ax, $ay) using ($cx1, $cy1) and
($cx2, $cy2) as control points.

=item $shape->r_curve3to( $cdx1, $cdy1, $cdx2, $cdy2, $adx, $ady [, ...] )

draws a cubic Bezier curve to (current X + $cx1 + $cx2 + $ax, current Y + $cy1 + $cy2 + $ay)
using (current X + $cx1, current Y + $cy1) and (current X + $cx1 + $cx2, current Y + $cy1 + $cy2) as control points.

=item $shape->arcto( $startangle, $centralangle, $rx [, $ry [, $rot]] )

draws an elliptic arc from the current pen position.
$startangle is the starting angle of the arc in degrees.
$centralangle is the central angle of the arc in degrees.
$rx and $ry are radii of the full ellipse. If $ry is not specified, 
a circular arc is drawn.
Optional $rot is the rotation angle of the full ellipse. 

=item $shape->radial_moveto( $r, $theta )

moves the pen from the current position to distance $r and angle $theta in degrees
measured clockwise from X-axis.

=item $shape->r_radial_moveto( $r, $dtheta )

moves the pen from the current position to distance $r and angle $dtheta in degrees
measured clockwise from the current direction.
The current direction is calculated from the start point of 
the last line segment or the control point of the last curve segment, 
and is reset to 0 when the pen was moved without drawing.

=item $shape->radial_lineto( $r, $theta [, $r2, $theta2,... ] )

draws a line from the current position to distance $r and angle $theta
measured clockwise from X-axis in degrees.

=item $shape->r_radial_lineto( $r, $dtheta [, $r2, $dtheta2,... ] )

draws a line from the current position to distance $r and angle $dtheta
measured clockwise from the current direction in degrees.
The current direction is calculated from the start point of 
the last line segment or the control point of the last curve segment, 
and is reset to 0 when the pen was moved without drawing.

=item $shape->close_path()

closes the path drawn by '...to' commands. 
This draws a line to the position set by the last '*moveto' command.
After drawing shapes or text by the methods described the next section, 
'close_path' may not work properly because those methods may use 'moveto' internally.

=back

=head2 Methods to Draw Shapes and Texts



=over 4

=item $shape->font( $font )

applies the font to the following text.
$font is an SWF::Builder::Font object.

=item $shape->size( $size )

sets a font size to $size in pixel.

=item $text->text( $string )

draws the $string with the current Y coordinate as the baseline
and moves the pen to the position which the next letter will be written.

=item $shape->box( $x1, $y1, $x2, $y2 )

draws a rectangle from ($x1, $y1) to ($x2, $y2) and moves the pen to ($x1, $y1).

=item $shape->rect( $w, $h, [, $rx [, $ry]] )

draws a rectangle with width $w and height $h from the current position.
If optional $rx is set, draws a rounded rectangle. $rx is a corner radius.
You can also set $ry, elliptic Y radius ($rx for X radius).
The pen does not move after drawing.

=item $shape->circle( $r )

draws a circle with radius $r.
The current pen position is used as the center.
The pen does not move after drawing.

=item $shape->ellipse( $rx, $ry [, $rot] )

draws an ellipse with radii $rx and $ry.
The current pen position is used as the center.
Optional $rot is a rotation angle.
The pen does not move after drawing.

=item $shape->starshape( $size [, $points [, $thickness [, $screw]]] )

draws a $points pointed star shape with size $size.
The current pen position is used as the center.
If $points is not specified, 5-pointed star (pentagram) is drawn.

Optional $thickness can take a number 0(thin) to 2(thick).
0 makes to draw lines like spokes and 2 makes to draw a convex polygon.
Default is 1.

Optional $screw is an angle to screw the concave corners of 
the star in degrees.

The pen does not move after drawing.

=item $shape->path( $pathdata )

draws a path defined by $pathdata.
$pathdata is a string compatible with 'd' attribute in 'path' element of SVG. 
See SVG specification for details.

=back

=head2 Methods for Pen Position and Coordinates

=over 4

=item $shape->get_bbox

returns the bounding box of the shape, a list of coordinates
( top-left X, top-left Y, bottom-right X, bottom-right Y ).

=item $shape->get_pos

returns the current pen position ($x, $y).

=item $shape->push_pos

pushes the current pen position onto the internal stack.

=item $shape->pop_pos

pops the pen position from the internal stack and move there.

=item $shape->lineto_pop_pos

pops the pen position from the internal stack and draw line to there.

=item $shape->transform( \@matrix_options [, \&sub] )

transforms the coordinates for subsequent drawings by the matrix.
Matrix options are pairs of a keyword and a scalar parameter or 
array reference of coordinates list, as follows:

  scale  => $scale or [$scalex, $scaley]  # scales up/down by $scale.
  rotate => $angle                        # rotate $angle degree clockwise.
  translate => [$x, $y]                   # translate coordinates to ($x, $y)
  moveto => [$x, $y]                      # same as 'translate'

  and all SWF::Element::MATRIX fields 
  ( ScaleX / ScaleY / RotateSkew0 / RotateSkew1 / TranslateX / TranslateY ).

ATTENTION: 'translate/moveto' takes coordinates in pixel, while 'TranslateX' and 'TranslateY' in TWIPS (20 TWIPS = 1 pixel).

If &sub is specified, this method calls &sub with a shape object 
with transformed coordinates, and return the original, untransformed shape object.
Otherwise, it returns a transformed shape object. 
You may need to call 'end_transform' to stop transformation.

This method does not affect either paths drawn before or the current pen position.

=item $tx_shape->end_transform

stops transformation of the coordinates and returns the original shape object.

=back

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
