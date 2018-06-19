package OpenGL::Sandbox::V1;
BEGIN { $OpenGL::Sandbox::V1::VERSION = '0.02'; }
use v5.14;
use strict;
use warnings;
use Carp;
use parent 'Exporter';
use Try::Tiny;
use Math::Trig;
use Cwd;
use OpenGL::Sandbox qw/
	glLoadIdentity glPushAttrib glPopAttrib glEnable glDisable glOrtho glFrustum glMatrixMode
	glFrontFace glTranslated
	GL_CURRENT_BIT GL_ENABLE_BIT GL_TEXTURE_2D GL_PROJECTION GL_CW GL_CCW GL_MODELVIEW
/;
our @EXPORT_OK= qw(
	local_matrix load_identity setup_projection scale trans trans_scale rotate mirror local_gl
	lines line_strip quads quad_strip triangles triangle_strip triangle_fan
	vertex plot_xy plot_xyz plot_st_xy plot_st_xyz plot_norm_st_xyz plot_rect plot_rect3
	cylinder sphere disk partial_disk
	compile_list call_list 
	setcolor color_parts color_mult
	draw_axes_xy draw_axes_xyz draw_boundbox
	get_viewport_rect
);
our %EXPORT_TAGS= (
	all => \@EXPORT_OK,
);

use Inline
	CPP => do { my $x= __FILE__; $x =~ s|\.pm|\.cpp|; Cwd::abs_path($x) },
	(defined $OpenGL::Sandbox::V1::VERSION? (
		NAME => __PACKAGE__,
		VERSION => __PACKAGE__->VERSION
	) : () ),
	LIBS => '-lGL -lGLU',
	CCFLAGSEX => '-Wall -g3 -Os';

# ABSTRACT: Various OpenGL tools and utilities that depend on the OpenGL 1.x API


sub setup_projection {
	my %args= @_ == 1 && ref($_[0]) eq 'HASH'? %{ $_[0] } : @_;
	my ($ortho, $l, $r, $t, $b, $near, $far, $x, $y, $z, $aspect, $mirror_x, $mirror_y)
		= delete @args{qw/ ortho left right top bottom near far x y z aspect mirror_x mirror_y /};
	croak "Unexpected arguments to setup_projection"
		if keys %args;
	my $have_w= defined $l && defined $r;
	my $have_h= defined $t && defined $b;
	unless ($have_h && $have_w) {
		if (!$aspect or $aspect eq 'auto') {
			my ($x, $y, $w, $h)= get_viewport_rect();
			$aspect= $h / $h;
		}
		if (!$have_w) {
			if (!$have_h) {
				$t= (defined $b? -$b : 1) unless defined $t;
				$b= -$t unless defined $b;
			}
			my $w= ($t - $b) * $aspect;
			$r= (defined $l? $l + $w : $w / 2) unless defined $r;
			$l= $r - $w unless defined $l;
		}
		else {
			my $h= ($r - $l) / $aspect;
			$t= (defined $b? $b + $h : $h / 2) unless defined $t;
			$b= $t - $h unless defined $b;
		}
	}
	($l, $r)= ($r, $l) if $mirror_x;
	($t, $b)= ($b, $t) if $mirror_y;
	$near= 1 unless defined $near;
	$far= 1000 unless defined $far;
	defined $_ or $_= 0
		for ($x, $y, $z);
	
	# If Z is specified, then the left/right/top/bottom are interpreted to be the
	# edges of the screen at this position.  Only matters for Frustum.
	if ($z && !$ortho) {
		my $scale= 1.0/$z;
		$l *= $scale;
		$r *= $scale;
		$t *= $scale;
		$b *= $scale;
	}
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	#print "l=$l r=$r b=$b t=$t near=$near far=$far\n";
	$ortho? glOrtho($l, $r, $b, $t, $near, $far)
	      : glFrustum($l, $r, $b, $t, $near, $far);
	
	glTranslated(-$x, -$y, -$z)
		if $x or $y or $z;
	
	# If mirror is in effect, need to tell OpenGL which way the camera is
	glFrontFace(!$mirror_x eq !$mirror_y? GL_CCW : GL_CW);
	glMatrixMode(GL_MODELVIEW);
}



sub local_matrix(&) { goto &_local_matrix }
*load_identity= *glLoadIdentity;


sub local_gl(&) { goto &_local_gl }


sub lines(&) { goto &_lines }
sub line_strip(&) { goto &_line_strip }
sub quads(&) { goto &_quads }
sub quad_strip(&) { goto &_quad_strip }
sub triangles(&) { goto &_triangles }
sub triangle_strip(&) { goto &_triangle_strip }
sub triangle_fan(&) { goto &_triangle_fan }


our $default_quadric;
sub default_quadric { $default_quadric //= OpenGL::Sandbox::V1::Quadric->new }
sub cylinder        { default_quadric->cylinder(@_)     }
sub sphere          { default_quadric->sphere(@_)       }
sub disk            { default_quadric->disk(@_)         }
sub partial_disk    { default_quadric->partial_disk(@_) }


sub compile_list(&) { OpenGL::Sandbox::V1::DisplayList->new->compile(shift); }

*call_list= *_displaylist_call;


sub draw_axes_xy {
	my ($range, $unit_size, $colorX, $colorY)= @_;
	$range //= 1;
	$unit_size //= 0.1;
	$colorY //= $colorX;
	$colorX //= '#FF7777';
	$colorY //= '#77FF77';
	my $whole_units= int($range / $unit_size);
	my $remainder= $range - $whole_units * $unit_size;
	glPushAttrib(GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	my $err= 1;
	eval {
		lines {
			# Grid lines along X axis
			setcolor(color_mult($colorX, [1,1,1,0.5])) if defined $colorX;
			plot_stripe(-$range, -$range+$remainder, 0,
			             $range, -$range+$remainder, 0,
			                  0,         $unit_size, 0,
			            $whole_units * 2 + 1);
			# Grid lines along Y axis
			setcolor(color_mult($colorY, [1,1,1,0.5])) if defined $colorY;
			plot_stripe(-$range+$remainder, -$range, 0,
			            -$range+$remainder,  $range, 0,
			                    $unit_size,       0, 0,
			            $whole_units * 2 + 1);
		};
		quads {
			my $thick= $unit_size*0.05;
			setcolor($colorX) if defined $colorX;
			plot_xy(undef,
				-$range, -$thick, # X axis
				 $range, -$thick,
				 $range,  $thick,
				-$range,  $thick);
			setcolor($colorY) if defined $colorY;
			plot_xy(undef,
				-$thick, -$range, # Y axis
				-$thick,  $range,
				 $thick,  $range,
				 $thick, -$range);
		};
		$err= 0;
	};
	glPopAttrib;
	warn $@ if $err;
}


sub draw_axes_xyz {
	my ($range, $unit_size, $colorX, $colorY, $colorZ)= @_;
	$range //= 1;
	$unit_size //= 0.1;
	$colorY //= $colorX;
	$colorZ //= $colorY;
	$colorX //= '#FF7777';
	$colorY //= '#77FF77';
	$colorZ //= '#7777FF';
	my $whole_units= int($range / $unit_size);
	my $remainder= $range - $whole_units * $unit_size;
	glPushAttrib(GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	my $err= 1;
	eval {
		lines {
			# Grid lines along X axis
			setcolor(color_mult($colorX, [1,1,1,0.5])) if defined $colorX;
			plot_stripe(-$range, 0, -$range+$remainder,
			             $range, 0, -$range+$remainder,
			                  0, 0,         $unit_size,
			            $whole_units * 2 + 1);
			plot_stripe(-$range, -$range+$remainder, 0,
			             $range, -$range+$remainder, 0,
			                  0,         $unit_size, 0,
			            $whole_units * 2 + 1);
			# Grid lines along Y axis
			setcolor(color_mult($colorY, [1,1,1,0.5])) if defined $colorY;
			plot_stripe(-$range+$remainder, -$range, 0,
			            -$range+$remainder,  $range, 0,
			                    $unit_size,       0, 0,
			            $whole_units * 2 + 1);
			plot_stripe(0, -$range, -$range+$remainder, 
			            0,  $range, -$range+$remainder, 
			            0,       0,         $unit_size, 
			            $whole_units * 2 + 1);
			# Grid lines along Z axis
			setcolor(color_mult($colorZ, [1,1,1,0.5])) if defined $colorZ;
			plot_stripe(0, -$range+$remainder, -$range,
			            0, -$range+$remainder,  $range,
			            0,         $unit_size,       0,
			            $whole_units * 2 + 1);
			plot_stripe(-$range+$remainder, 0, -$range,
			            -$range+$remainder, 0,  $range,
			                    $unit_size, 0,       0,
			            $whole_units * 2 + 1);
		};
		quads {
			my $thick= $unit_size*0.05;
			setcolor($colorX) if defined $colorX;
			plot_rect3(-$range, -$thick, -$thick, $range, $thick, $thick); # X axis
			setcolor($colorY) if defined $colorY;
			plot_rect3(-$thick, -$range, -$thick, $thick, $range, $thick); # Y axis
			setcolor($colorZ) if defined $colorZ;
			plot_rect3(-$thick, -$thick, -$range, $thick, $thick, $range); # Z axis
		};
		$err= 0;
	};
	glPopAttrib;
	warn $@ if $err;
}


sub draw_boundbox {
	my ($x0, $y0, $x1, $y1, $color_edge, $color_to_origin, $color_axes)= @_;
	glPushAttrib(GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	setcolor($color_edge // '#77FF77');
	line_strip {
		# Edges of rectangle
		plot_xy(undef,
			$x0, $y0,
			$x1, $y0,
			$x1, $y1,
			$x0, $y1,
			$x0, $y0);
	};
	lines {
		# Cross hairs of origin
		setcolor($color_axes // '#FF777777');
		plot_xy(undef,
			$x0, 0,  $x1, 0,
			0, $y0,  0, $y1);
		# Diagonals from origin to corners
		setcolor($color_to_origin // '#77AAAA77');
		plot_xy(undef,
			$x0, $y0,  0,0,
			$x1, $y0,  0,0,
			$x1, $y1,  0,0,
			$x0, $y1,  0,0);
	};
	glPopAttrib();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::V1 - Various OpenGL tools and utilities that depend on the OpenGL 1.x API

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This module is separated from OpenGL::Sandbox in order to keep the OpenGL API dependencies
less tangled.  Everything specific to OpenGL 1.x that I would have otherwise included in
OpenGL::Sandbox is located here, instead.  The main OpenGL::Sandbox module can automatically
load this module using the import tag of C<:V1> or C<:V1:all>.

=head1 EXPORTABLE FUNCTIONS

=head2 MATRIX FUNCTIONS

=head3 load_identity

Alias for glLoadIdentity

=head3 setup_projection

=head3 local_matrix

  local_matrix { ... };

Wrap a block of code with glPushmatrix/glPopMatrix.  This wrapper also checks the matrix stack
depth before and after the call, warns if they don't match, and performs any missing
glPopMatrix calls.

=head3 scale

  scale $xyz;
  scale $x, $y; # z=1
  scale $x, $y, $z;

Scale all axes (one argument), the x and y axes (2 arguments), or a normal call to glScale
(3 arguments).

=head3 trans

  trans $x, $y;
  trans $x, $y, $z;

Translate along x,y or x,y,z axes.  Calls either glTranslate2f or glTranslate3f.

=head3 trans_scale

  trans_scale $x, $y, $x, $s;       # scale each by $s
  trans_scale $x, $y, $x, $sx, $sy; # $sz=1
  trans_scale $x, $y, $x, $sx, $sy, $sz;

Combination of glTranslate, then glScale.

=head3 rotate

  rotate $degrees, $x, $y, $z;
  rotate x => $degrees;
  rotate y => $degrees;
  rotate z => $degrees;

Normal call to glRotated, or x/y/z notation to rotate around that axis.

=head3 mirror

  mirror 'x';  # glScale(-1, 0, 0)
  mirror 'y';  # glScale(0, -1, 0)
  mirror 'xyz'; # glScale(-1, -1, -1)

Use glScale to invert one more more axes.

=head3 local_gl

  local_gl { ... };

Like local_matrix, but also calls glPushAttrib/glPopAttrib.
This is expensive, and should probably only be used for debugging.

=head2 GEOMETRY PLOTTING

=head3 lines

  lines { ... };  # wraps code with glBegin(GL_LINES); ... glEnd();

=head3 line_strip

  line_strip { ... };  # wraps code with glBegin(GL_LINE_STRIP); ... glEnd();

=head3 quads

  quads { ... };  # wraps code with glBegin(GL_QUADS); ... glEnd();

=head3 quad_strip

  quad_strip { ... }; # wraps code with glBegin(GL_QUAD_STRIP); ... glEnd();

=head3 triangles

  triangles { ... }; # wraps code with glBegin(GL_TRIANGLES); ... glEnd();

=head3 triangle_strip

  triangle_strip { ... }; # wraps code with glBegin(GL_TRIANGLE_STRIP); ... glEnd();

=head3 triangle_fan

  triangle_fan { ... }; # wraps code with glBegin(GL_TRIANGLE_FAN); ... glEnd();

=head3 vertex

  vertex $x, $y;
  vertex $x, $y, $z;
  vertex $x, $y, $z, $w;

Call one of glVertex${N} based on number of arguments.

=head3 plot_xy

  plot_xy(
     $geom_mode,  # optional, i.e. GL_TRIANGLES or undef
     $x0, $y0,  # Shortcut for many glVertex2d calls
     $x1, $y1,
     ...
     $xN, $yN,
  );

If C<$geom_mode> is not undef or zero, this makes a call to C<glBegin> and C<glEnd> around the
calls to C<glVertex2d>.

=head3 plot_xyz

  plot_xyz(
     $geom_mode,
     $x0, $y0, $z0,
     $x1, $y1, $z1,
     ...
     $xN, $yN, $zN,
  );

Like above, but call C<glVertex3d>.

=head3 plot_st_xy

  plot_st_xy(
     $geom_mode,
     $s0, $t0,  $x0, $y0,
     $s1, $t1,  $x1, $y1,
     ...
     $sN, $tN,  $xN, $yN,
  );

Like above, but calls both C<glTexCoord2d> and C<glVertex2d>.

=head3 plot_st_xyz

  plot_st_xyz(
     $geom_mode,
     $s0, $t0,   $x0, $y0, $z0,
     $s1, $t1,   $x1, $y1, $z1,
     ...
     $sN, $tN,   $xN, $yN, $zN,
  );

Like above, but call both C<glTexCoord2d> and C<glVertex3d>.

=head3 plot_norm_st_xyz

  plot_norm_st_xyz(
     $geom_mode,
     $nx0, $ny0, $nz0,   $s0, $t0,   $x0, $y0, $z0,
     $nx0, $ny0, $nz0,   $s1, $t1,   $x1, $y1, $z1,
     ...
     $nx0, $ny0, $nz0,   $sN, $tN,   $xN, $yN, $zN,
  );

Like above, but calls each of C<glNormal3d>, C<glTexCoord2d>, C<glVertex3d>.

=head3 plot_rect

  plot_rect(x0,y0, x1,y1)

=head3 plot_rect3

  plot_rect3(x0,y0,z0, x1,y1,z1)

=head3 cylinder

  cylinder($base_radius, $top_radius, $height, $radial_slices, $stacks);

Plot a cylinder along the Z axis with the specified dimensions.
Shortcut for L<OpenGL::Sandbox::V1::Quadric/cylinder> on the L<default_quadric|OpenGL::Sandbox::ResMan/quadric>.
That quadric determines whether normals or texture coordinates get generated.

=head3 sphere

  sphere($radius, $radial_slices, $stacks);

Plot a sphere around the origin with specified dimensions.
Shortcut for L<OpenGL::Sandbox::V1::Quadric/sphere> on the L<default_quadric|OpenGL::Sandbox::ResMan/quadric>.

=head3 disk

  disk($inner_rad, $outer_rad, $slices, $stacks);

Plot a disk around the Z axis with specified inner and outer radius.
Shortcut for L<OpenGL::Sandbox::V1::Quadric/disk> on the L<default_quadric|OpenGL::Sandbox::ResMan/quadric>.

=head3 partial_disk

  partial_disk($inner_rad, $outer_rad, $slices, $loops, $start_angle, $sweep_degrees);

Plot a wedge of a disk around the Z axis.
Shortcut for L<OpenGL::Sandbox::V1::Quadric/disk> on the L<default_quadric|OpenGL::Sandbox::ResMan/quadric>.

=head2 DISPLAY LISTS

=head3 compile_list

  my $list= compile_list { ... };

Constructs a displaylist by compiling the code in the block.

=head3 call_list

  call_list($list, sub { ... });

If the variable C<$list> contains a compiled displaylist, this calls that list.  Else it
creates a new list, assigns it to the variable C<$list>, and compiles the contents of the
coderef.  This is a convenient way of compiling some code on the first pass and then calling
it every iteration after that.

=head2 COLORS

=head3 setcolor

  setcolor($r, $g, $b);
  setcolor($r, $g, $b, $a);
  setcolor(\@rgb);
  setcolor(\@rgba);
  setcolor('#RRGGBB');
  setcolor('#RRGGBBAA');

Various ways to specify a color for glSetColor4f.  If Alpha component is missing, it defaults to 1.0

=head3 color_parts

  my ($r, $g, $b, $a)= color_parts('#RRGGBBAA');

Convenience method that always returns 4 components of a color, given the same variety of
formats as setcolor.

=head3 color_mult

  my ($r, $g, $b, $a)= color_mult( \@color1, \@color2 )

Multiply each component of color1 by that component of color2.

=head2 MISC DRAWING

=head3 draw_axes_xy

  draw_axes_xy( $range, $unit_size, $color );
  draw_axes_xy( $range, $unit_size, $colorX, $colorY );

Renders the X and Y axis as lines from C<-$range> to C<+$range>, with a thinner lines
making a grid of C<$unit_size> squares on the X/Y plane.

$range defaults to C<1>.  C<$unit_size> defaults to C<0.1>.  C<$color> defaults to the current
color.

Automatically disables textures for this operation.

=head3 draw_axes_xyz

  draw_axes_xyz( $range, $unit_size, $color );
  draw_axes_xyz( $range, $unit_size, $colorX, $colorY, $colorZ );

Renders each of the X,Y,Z axes and the XY, XZ, YZ planes.

=head3 draw_boundbox

  draw_boundbox( $x0, $y0, $x1, $y1, $color_edge, $color_to_origin );

Draw lines around a rectangle, and also a line from each corner to the origin, and the section
of the X and Y axes that are within the bounds of the rectangle.
This is useful for marking a 2D widget relative to the current coordinate system.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
