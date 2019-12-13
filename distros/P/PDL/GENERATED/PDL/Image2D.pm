
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Image2D;

@EXPORT_OK  = qw(  PDL::PP conv2d PDL::PP med2d PDL::PP med2df PDL::PP box2d PDL::PP patch2d PDL::PP patchbad2d PDL::PP max2d_ind PDL::PP centroid2d  cc8compt cc4compt PDL::PP ccNcompt polyfill  pnpoly  polyfillv  rotnewsz PDL::PP rot2d PDL::PP bilin2d PDL::PP rescale2d  fitwarp2d applywarp2d PDL::PP warp2d  warp2d_kernel PDL::PP warp2d_kernel );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Image2D ;





=head1 NAME

PDL::Image2D - Miscellaneous 2D image processing functions

=head1 DESCRIPTION

Miscellaneous 2D image processing functions - for want
of anywhere else to put them.

=head1 SYNOPSIS

 use PDL::Image2D;

=cut

use PDL;  # ensure qsort routine available
use PDL::Math;
use Carp;

use strict;







=head1 FUNCTIONS



=cut





















=head2 conv2d

=for sig

  Signature: (a(m,n); kern(p,q); [o]b(m,n); int opt)


=for ref

2D convolution of an array with a kernel (smoothing)

For large kernels, using a FFT routine,
such as L<fftconvolve()|PDL::FFT/fftconvolve()> in C<PDL::FFT>,
will be quicker.

=for usage

 $new = conv2d $old, $kernel, {OPTIONS}

=for example

 $smoothed = conv2d $image, ones(3,3), {Boundary => Reflect}

=for options

 Boundary - controls what values are assumed for the image when kernel
            crosses its edge:
 	    => Default   - periodic boundary conditions
                           (i.e. wrap around axis)
 	    => Reflect   - reflect at boundary
 	    => Truncate  - truncate at boundary
 	    => Replicate - repeat boundary pixel values



=for bad

Unlike the FFT routines, conv2d is able to process bad values.

=cut






sub PDL::conv2d {
   my $opt; $opt = pop @_ if ref($_[$#_]) eq 'HASH';
   die 'Usage: conv2d( a(m,n), kern(p,q), [o]b(m,n), {Options} )'
      if $#_<1 || $#_>2;
   my($x,$kern) = @_;
   my $c = $#_ == 2 ? $_[2] : $x->nullcreate;
   &PDL::_conv2d_int($x,$kern,$c,
	(!(defined $opt && exists $$opt{Boundary}))?0:
	(($$opt{Boundary} eq "Reflect") +
	2*($$opt{Boundary} eq "Truncate") +
	3*($$opt{Boundary} eq "Replicate")));
   return $c;
}



*conv2d = \&PDL::conv2d;





=head2 med2d

=for sig

  Signature: (a(m,n); kern(p,q); [o]b(m,n); int opt)


=for ref

2D median-convolution of an array with a kernel (smoothing)

Note: only points in the kernel E<gt>0 are included in the median, other
points are weighted by the kernel value (medianing lots of zeroes
is rather pointless)

=for usage

 $new = med2d $old, $kernel, {OPTIONS}

=for example

 $smoothed = med2d $image, ones(3,3), {Boundary => Reflect}

=for options

 Boundary - controls what values are assumed for the image when kernel
            crosses its edge:
 	    => Default   - periodic boundary conditions (i.e. wrap around axis)
 	    => Reflect   - reflect at boundary
 	    => Truncate  - truncate at boundary
 	    => Replicate - repeat boundary pixel values



=for bad

Bad values are ignored in the calculation. If all elements within the
kernel are bad, the output is set bad.

=cut






sub PDL::med2d {
   my $opt; $opt = pop @_ if ref($_[$#_]) eq 'HASH';
   die 'Usage: med2d( a(m,n), kern(p,q), [o]b(m,n), {Options} )'
      if $#_<1 || $#_>2;
   my($x,$kern) = @_;
   croak "med2d: kernel must contain some positive elements.\n"
       if all( $kern <= 0 );
   my $c = $#_ == 2 ? $_[2] : $x->nullcreate;
   &PDL::_med2d_int($x,$kern,$c,
	(!(defined $opt && exists $$opt{Boundary}))?0:
	(($$opt{Boundary} eq "Reflect") +
	2*($$opt{Boundary} eq "Truncate") +
	3*($$opt{Boundary} eq "Replicate")));
   return $c;
}



*med2d = \&PDL::med2d;





=head2 med2df

=for sig

  Signature: (a(m,n); [o]b(m,n); int __p_size; int __q_size; int opt)


=for ref

2D median-convolution of an array in a pxq window (smoothing)

Note: this routine does the median over all points in a rectangular
      window and is not quite as flexible as C<med2d> in this regard
      but slightly faster instead

=for usage

 $new = med2df $old, $xwidth, $ywidth, {OPTIONS}

=for example

 $smoothed = med2df $image, 3, 3, {Boundary => Reflect}

=for options

 Boundary - controls what values are assumed for the image when kernel
            crosses its edge:
 	    => Default   - periodic boundary conditions (i.e. wrap around axis)
 	    => Reflect   - reflect at boundary
 	    => Truncate  - truncate at boundary
 	    => Replicate - repeat boundary pixel values



=for bad

med2df does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






sub PDL::med2df {
   my $opt; $opt = pop @_ if ref($_[$#_]) eq 'HASH';
   die 'Usage: med2df( a(m,n), [o]b(m,n), p, q, {Options} )'
      if $#_<2 || $#_>3;
   my($x,$p,$q) = @_;
   croak "med2df: kernel must contain some positive elements.\n"
       if $p == 0 && $q == 0;
   my $c = $#_ == 3 ? $_[3] : $x->nullcreate;
   &PDL::_med2df_int($x,$c,$p,$q,
	(!(defined $opt && exists $$opt{Boundary}))?0:
	(($$opt{Boundary} eq "Reflect") +
	2*($$opt{Boundary} eq "Truncate") +
	3*($$opt{Boundary} eq "Replicate")));
   return $c;
}



*med2df = \&PDL::med2df;





=head2 box2d

=for sig

  Signature: (a(n,m); [o] b(n,m); int wx; int wy; int edgezero)


=for ref

fast 2D boxcar average

=for example

  $smoothim = $im->box2d($wx,$wy,$edgezero=1);

The edgezero argument controls if edge is set to zero (edgezero=1)
or just keeps the original (unfiltered) values.

C<box2d> should be updated to support similar edge options
as C<conv2d> and C<med2d> etc.

Boxcar averaging is a pretty crude way of filtering. For serious stuff
better filters are around (e.g., use L<conv2d|conv2d> with the appropriate
kernel). On the other hand it is fast and computational cost grows only
approximately linearly with window size.



=for bad

box2d does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*box2d = \&PDL::box2d;





=head2 patch2d

=for sig

  Signature: (a(m,n); int bad(m,n); [o]b(m,n))


=for ref

patch bad pixels out of 2D images using a mask

=for usage

 $patched = patch2d $data, $bad;

C<$bad> is a 2D mask array where 1=bad pixel 0=good pixel.
Pixels are replaced by the average of their non-bad neighbours;
if all neighbours are bad, the original data value is
copied across.



=for bad

This routine does not handle bad values - use L<patchbad2d|/patchbad2d> instead

=cut






*patch2d = \&PDL::patch2d;





=head2 patchbad2d

=for sig

  Signature: (a(m,n); [o]b(m,n))


=for ref

patch bad pixels out of 2D images containing bad values

=for usage

 $patched = patchbad2d $data;

Pixels are replaced by the average of their non-bad neighbours;
if all neighbours are bad, the output is set bad.
If the input piddle contains I<no> bad values, then a straight copy
is performed (see L<patch2d|/patch2d>).



=for bad

patchbad2d handles bad values. The output piddle I<may> contain
bad values, depending on the pattern of bad values in the input piddle.

=cut






*patchbad2d = \&PDL::patchbad2d;





=head2 max2d_ind

=for sig

  Signature: (a(m,n); [o]val(); int [o]x(); int[o]y())


=for ref

Return value/position of maximum value in 2D image

Contributed by Tim Jeness



=for bad

Bad values are excluded from the search. If all pixels
are bad then the output is set bad.



=cut






*max2d_ind = \&PDL::max2d_ind;





=head2 centroid2d

=for sig

  Signature: (im(m,n); x(); y(); box(); [o]xcen(); [o]ycen())


=for ref

Refine a list of object positions in 2D image by centroiding in a box

C<$box> is the full-width of the box, i.e. the window
is C<+/- $box/2>.



=for bad

Bad pixels are excluded from the centroid calculation. If all elements are
bad (or the pixel sum is 0 - but why would you be centroiding
something with negatives in...) then the output values are set bad.



=cut






*centroid2d = \&PDL::centroid2d;




=head2 cc8compt

=for ref

Connected 8-component labeling of a binary image.

Connected 8-component labeling of 0,1 image - i.e. find separate
segmented objects and fill object pixels with object number.
8-component labeling includes all neighboring pixels.
This is just a front-end to ccNcompt.  See also L<cc4compt|cc4compt>.

=for example

 $segmented = cc8compt( $image > $threshold );

=head2 cc4compt

=for ref

Connected 4-component labeling of a binary image.

Connected 4-component labeling of 0,1 image - i.e. find separate
segmented objects and fill object pixels with object number.
4-component labling does not include the diagonal neighbors.
This is just a front-end to ccNcompt.  See also L<cc8compt|cc8compt>.

=for example

 $segmented = cc4compt( $image > $threshold );

=cut

sub PDL::cc8compt{
return ccNcompt(shift,8);
}
*cc8compt = \&PDL::cc8compt;

sub PDL::cc4compt{
return ccNcompt(shift,4);
}
*cc4compt = \&PDL::cc4compt;





=head2 ccNcompt

=for sig

  Signature: (a(m,n); int+ [o]b(m,n); int con)



=for ref

Connected component labeling of a binary image.

Connected component labeling of 0,1 image - i.e. find separate
segmented objects and fill object pixels with object number.
See also L<cc4compt|cc4compt> and L<cc8compt|cc8compt>.

The connectivity parameter must be 4 or 8.

=for example

 $segmented = ccNcompt( $image > $threshold, 4);

 $segmented2 = ccNcompt( $image > $threshold, 8);

where the second parameter specifies the connectivity (4 or 8) of the labeling.



=for bad

ccNcompt ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ccNcompt = \&PDL::ccNcompt;



=head2 polyfill

=for ref

fill the area of the given polygon with the given colour.

This function works inplace, i.e. modifies C<im>.

=for usage

  polyfill($im,$ps,$colour,[\%options]);

The default method of determining which points lie inside of the polygon used
is not as strict as the method used in L<pnpoly|pnpoly>. Often, it includes vertices
and edge points. Set the C<Method> option to change this behaviour.

=for option

Method   -  Set the method used to determine which points lie in the polygon.
            => Default - internal PDL algorithm
            => pnpoly  - use the L<pnpoly|pnpoly> algorithm

=for example

  # Make a convex 3x3 square of 1s in an image using the pnpoly algorithm
  $ps = pdl([3,3],[3,6],[6,6],[6,3]);
  polyfill($im,$ps,1,{'Method' =>'pnpoly'});

=cut
sub PDL::polyfill {
	my $opt;
	$opt = pop @_ if ref($_[-1]) eq 'HASH';
	barf('Usage: polyfill($im,$ps,$colour,[\%options])') unless @_==3;
	my ($im,$ps,$colour) = @_;

	if($opt) {
		use PDL::Options qw();
		my $parsed = PDL::Options->new({'Method' => undef});
		$parsed->options($opt);
		if( $parsed->current->{'Method'} eq 'pnpoly' ) {
			PDL::pnpolyfill_pp($im,$ps,$colour);
		}
	}
	else
	{
		PDL::polyfill_pp($im,$ps,$colour);
	}
	return $im;

}

*polyfill = \&PDL::polyfill;




=head2 pnpoly

=for ref

'points in a polygon' selection from a 2-D piddle

=for usage

  $mask = $img->pnpoly($ps);

  # Old style, do not use
  $mask = pnpoly($x, $y, $px, $py);

For a closed polygon determined by the sequence of points in {$px,$py}
the output of pnpoly is a mask corresponding to whether or not each
coordinate (x,y) in the set of test points, {$x,$y}, is in the interior
of the polygon.  This is the 'points in a polygon' algorithm from
L<http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html>
and vectorized for PDL by Karl Glazebrook.

=for example

  # define a 3-sided polygon (a triangle)
  $ps = pdl([3, 3], [20, 20], [34, 3]);

  # $tri is 0 everywhere except for points in polygon interior
  $tri = $img->pnpoly($ps);

  With the second form, the x and y coordinates must also be specified.
  B< I<THIS IS MAINTAINED FOR BACKWARD COMPATIBILITY ONLY> >.

  $px = pdl( 3, 20, 34 );
  $py = pdl( 3, 20,  3 );
  $x = $img->xvals;      # get x pixel coords
  $y = $img->yvals;      # get y pixel coords

  # $tri is 0 everywhere except for points in polygon interior
  $tri = pnpoly($x,$y,$px,$py);

=cut

# From: http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
#
# Fixes needed to pnpoly code:
#
# Use topdl() to ensure piddle args
#
# Add POD docs for usage
#
# Calculate first term in & expression to use to fix divide-by-zero when
#   the test point is in line with a vertical edge of the polygon.
#   By adding the value of $mask we prevent a divide-by-zero since the &
#   operator does not "short circuit".

sub PDL::pnpoly {
	barf('Usage: $mask = pnpoly($img, $ps);') unless(@_==2 || @_==4);
 	my ($tx, $ty, $vertx, $verty) = @_;

 	# if only two inputs, use the pure PP version
 	unless( defined $vertx ) {
		barf("ps must contain pairwise points.\n") unless $ty->getdim(0) == 2;

		# Input mapping:  $img => $tx, $ps => $ty
		return PDL::pnpoly_pp($tx,$ty);
	}

	my $testx = PDL::Core::topdl($tx)->dummy(0);
	my $testy = PDL::Core::topdl($ty)->dummy(0);
	my $vertxj = PDL::Core::topdl($vertx)->rotate(1);
	my $vertyj = PDL::Core::topdl($verty)->rotate(1);
	my $mask = ( ($verty>$testy) == ($vertyj>$testy) );
	my $c = sumover( ! $mask & ( $testx < ($vertxj-$vertx) * ($testy-$verty)
	                             / ($vertyj-$verty+$mask) + $vertx) ) % 2;
	return $c;
}

*pnpoly = \&PDL::pnpoly;




=head2 polyfillv

=for ref

return the (dataflown) area of an image described by a polygon

=for usage

  polyfillv($im,$ps,[\%options]);

The default method of determining which points lie inside of the polygon used
is not as strict as the method used in L<pnpoly|pnpoly>. Often, it includes vertices
and edge points. Set the C<Method> option to change this behaviour.

=for option

Method   -  Set the method used to determine which points lie in the polygon.
            => Default - internal PDL algorithm
            => pnpoly  - use the L<pnpoly|pnpoly> algorithm

=for example

  # increment intensity in area bounded by $poly using the pnpoly algorithm
  $im->polyfillv($poly,{'Method'=>'pnpoly'})++; # legal in perl >= 5.6

  # compute average intensity within area bounded by $poly using the default algorithm
  $av = $im->polyfillv($poly)->avg;

=cut

sub PDL::polyfillv :lvalue {
	my $opt;
	$opt = pop @_ if ref($_[-1]) eq 'HASH';
	barf('Usage: polyfillv($im,$ps,[\%options])') unless @_==2;

	my ($im,$ps) = @_;
	barf("ps must contain pairwise points.\n") unless $ps->getdim(0) == 2;

	if($opt) {
		use PDL::Options qw();
		my $parsed = PDL::Options->new({'Method' => undef});
		$parsed->options($opt);
		return $im->where(PDL::pnpoly_pp($im, $ps)) if $parsed->current->{'Method'} eq 'pnpoly';
	}

	my $msk = zeroes(long,$im->dims);
	PDL::polyfill_pp($msk, $ps, 1);
	return $im->where($msk);
}
*polyfillv = \&PDL::polyfillv;





=head2 rot2d

=for sig

  Signature: (im(m,n); float angle(); bg(); int aa(); [o] om(p,q))


=for ref

rotate an image by given C<angle>

=for example

  # rotate by 10.5 degrees with antialiasing, set missing values to 7
  $rot = $im->rot2d(10.5,7,1);

This function rotates an image through an C<angle> between -90 and + 90
degrees. Uses/doesn't use antialiasing depending on the C<aa> flag.
Pixels outside the rotated image are set to C<bg>.

Code modified from pnmrotate (Copyright Jef Poskanzer) with an algorithm based
on "A Fast Algorithm for General  Raster  Rotation"  by  Alan Paeth,
Graphics Interface '86, pp. 77-81.

Use the C<rotnewsz> function to find out about the dimension of the
newly created image

  ($newcols,$newrows) = rotnewsz $oldn, $oldm, $angle;

L<PDL::Transform|PDL::Transform> offers a more general interface to
distortions, including rotation, with various types of sampling; but
rot2d is faster.



=for bad

rot2d ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*rot2d = \&PDL::rot2d;





=head2 bilin2d

=for sig

  Signature: (I(n,m); O(q,p))


=for ref

Bilinearly maps the first piddle in the second. The
interpolated values are actually added to the second
piddle which is supposed to be larger than the first one.



=for bad

bilin2d ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*bilin2d = \&PDL::bilin2d;





=head2 rescale2d

=for sig

  Signature: (I(m,n); O(p,q))


=for ref

The first piddle is rescaled to the dimensions of the second
(expanding or meaning values as needed) and then added to it in place.
Nothing useful is returned.

If you want photometric accuracy or automatic FITS header metadata
tracking, consider using L<PDL::Transform::map|PDL::Transform/map>
instead: it does these things, at some speed penalty compared to
rescale2d.



=for bad

rescale2d ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*rescale2d = \&PDL::rescale2d;





=head2 fitwarp2d

=for ref

Find the best-fit 2D polynomial to describe
a coordinate transformation.

=for usage

  ( $px, $py ) = fitwarp2d( $x, $y, $u, $v, $nf, { options } )

Given a set of points in the output plane (C<$u,$v>), find
the best-fit (using singular-value decomposition) 2D polynomial
to describe the mapping back to the image plane (C<$x,$y>).
The order of the fit is controlled by the C<$nf> parameter
(the maximum power of the polynomial is C<$nf - 1>), and you
can restrict the terms to fit using the C<FIT> option.

C<$px> and C<$py> are C<np> by C<np> element piddles which describe
a polynomial mapping (of order C<np-1>)
from the I<output> C<(u,v)> image to the I<input> C<(x,y)> image:

  x = sum(j=0,np-1) sum(i=0,np-1) px(i,j) * u^i * v^j
  y = sum(j=0,np-1) sum(i=0,np-1) py(i,j) * u^i * v^j

The transformation is returned for the reverse direction (ie
output to input image) since that is what is required by the
L<warp2d()|/warp2d> routine.  The L<applywarp2d()|/applywarp2d>
routine can be used to convert a set of C<$u,$v> points given
C<$px> and C<$py>.

Options:

=for options

  FIT     - which terms to fit? default ones(byte,$nf,$nf)

=begin comment

old option, caused trouble
  THRESH  - in svd, remove terms smaller than THRESH * max value
            default is 1.0e-5

=end comment

=over 4

=item FIT

C<FIT> allows you to restrict which terms of the polynomial to fit:
only those terms for which the FIT piddle evaluates to true will be
evaluated.  If a 2D piddle is sent in, then it is
used for the x and y polynomials; otherwise
C<< $fit->slice(":,:,(0)") >> will be used for C<$px> and
C<< $fit->slice(":,:,(1)") >> will be used for C<$py>.

=begin comment

=item THRESH

Remove all singular values whose value is less than C<THRESH>
times the largest singular value.

=end comment

=back

The number of points must be at least equal to the number of
terms to fit (C<$nf*$nf> points for the default value of C<FIT>).

=for example

  # points in original image
  $x = pdl( 0,   0, 100, 100 );
  $y = pdl( 0, 100, 100,   0 );
  # get warped to these positions
  $u = pdl( 10, 10, 90, 90 );
  $v = pdl( 10, 90, 90, 10 );
  #
  # shift of origin + scale x/y axis only
  $fit = byte( [ [1,1], [0,0] ], [ [1,0], [1,0] ] );
  ( $px, $py ) = fitwarp2d( $x, $y, $u, $v, 2, { FIT => $fit } );
  print "px = ${px}py = $py";
  px =
  [
   [-12.5  1.25]
   [    0     0]
  ]
  py =
  [
   [-12.5     0]
   [ 1.25     0]
  ]
  #
  # Compared to allowing all 4 terms
  ( $px, $py ) = fitwarp2d( $x, $y, $u, $v, 2 );
  print "px = ${px}py = $py";
  px =
  [
   [         -12.5           1.25]
   [  1.110223e-16 -1.1275703e-17]
  ]
  py =
  [
   [         -12.5  1.6653345e-16]
   [          1.25 -5.8546917e-18]
  ]

  # A higher-degree polynomial should not affect the answer much, but
  # will require more control points

  $x = $x->glue(0,pdl(50,12.5, 37.5, 12.5, 37.5));
  $y = $y->glue(0,pdl(50,12.5, 37.5, 37.5, 12.5));
  $u = $u->glue(0,pdl(73,20,40,20,40));
  $v = $v->glue(0,pdl(29,20,40,40,20));
  ( $px3, $py3 ) = fitwarp2d( $x, $y, $u, $v, 3 );
  print "px3 =${px3}py3 =$py3";
  px3 =
  [
   [-6.4981162e+08       71034917     -726498.95]
   [      49902244     -5415096.7      55945.388]
   [    -807778.46      88457.191     -902.51612]
  ]
  py3 =
  [
   [-6.2732159e+08       68576392     -701354.77]
   [      48175125     -5227679.8      54009.114]
   [    -779821.18      85395.681     -871.27997]
  ]

  #This illustrates an important point about singular value
  #decompositions that are used in fitwarp2d: like all SVDs, the
  #rotation matrices are not unique, and so the $px and $py returned
  #by fitwarp2d are not guaranteed to be the "simplest" solution.
  #They do still work, though:

  ($x3,$y3) = applywarp2d($px3,$py3,$u,$v);
  print approx $x3,$x,1e-4;
  [1 1 1 1 1 1 1 1 1]
  print approx $y3,$y;
  [1 1 1 1 1 1 1 1 1]

=head2 applywarp2d

=for ref

Transform a set of points using a 2-D polynomial mapping

=for usage

  ( $x, $y ) = applywarp2d( $px, $py, $u, $v )

Convert a set of points (stored in 1D piddles C<$u,$v>)
to C<$x,$y> using the 2-D polynomial with coefficients stored in C<$px>
and C<$py>.  See L<fitwarp2d()|/fitwarp2d>
for more information on the format of C<$px> and C<$py>.

=cut

# use SVD to fit data. Assuming no errors.

=pod

=begin comment

Some explanation of the following three subroutines (_svd, _mkbasis,
and fitwarp2d): See Wolberg 1990 (full ref elsewhere in this
documentation), Chapter 3.6 "Polynomial Transformations".  The idea is
that, given a set of control points in the input and output images
denoted by coordinates (x,y) and (u,v), we want to create a polynomial
transformation that relates u to linear combinations of powers of x
and y, and another that relates v to powers of x and y.

The transformations used here and by Wolberg differ slightly, but the
basic idea is something like this.  For each u and each v, define a
transform:

u = (sum over j) (sum over i) a_{ij} x**i * y**j , (eqn 1)
v = (sum over j) (sum over i) b_{ij} x**i * y**j . (eqn 2)

We can write this in matrix notation.  Given that there are M control
points, U is a column vector with M rows.  A and B are vectors containing
the N coefficients (related to the degree of the polynomial fit).  W
is an MxN matrix of the basis row-vectors (the x**i y**j).

The matrix equations we are trying to solve are
U = W A , (eqn 3)
V = W B . (eqn 4)

We need to find the A and B column vectors, those are the coefficients
of the polynomial terms in W.  W is not square, so it has no inverse.
But is has a pseudo-inverse W^+ that is NxM.  We are going to use that
pseudo-inverse to isolate A and B, like so:

W^+ U = W^+ W A = A (eqn 5)
W^+ V = W^+ W B = B (eqn 6)

We are going to get W^+ by performing a singular value decomposition
of W (to use some of the variable names below):

W = $svd_u x SIGMA x $svd_v->transpose (eqn 7)
W^+ = $svd_v x SIGMA^+ x $svd_u->transpose . (eqn 8)

Here SIGMA is a square diagonal matrix that contains the singular
values of W that are in the variable $svd_w.  SIGMA^+ is the
pseudo-inverse of SIGMA, which is calculated by replacing the non-zero
singular values with their reciprocals, and then taking the transpose
of the matrix (which is a no-op since the matrix is square and
diagonal).

So the code below does this:

_mkbasis computes the matrix W, given control coordinates u and v and
the maximum degree of the polynomial (and the terms to use).

_svd takes the svd of W, computes the pseudo-inverse of W, and then
multiplies that with the U vector (there called $y). The output of
_svd is the A or B vector in eqns 5 & 6 above. Rarely is the matrix
multiplication explicit, unfortunately, so I have added EXPLANATIONs
below.

=end comment

=cut

sub _svd ($$) {
    my $basis  = shift;
    my $y      = shift;
#    my $thresh = shift;

    # if we had errors for these points, would normalise the
    # basis functions, and the output array, by these errors here

    # perform the SVD
    my ( $svd_u, $svd_w, $svd_v ) = svd( $basis );

    # DAL, 09/2017: the reason for removing ANY singular values, much less
    #the smallest ones, is not clear. I commented the line below since this
    #actually removes the LARGEST values in SIGMA^+.
    # $svd_w *= ( $svd_w >= ($svd_w->max * $thresh ) );
    # The line below would instead remove the SMALLEST values in SIGMA^+, but I can see no reason to include it either.
    # $svd_w *= ( $svd_w <= ($svd_w->min / $thresh ) );

    # perform the back substitution
    # EXPLANATION: same thing as $svd_u->transpose x $y->transpose.
    my $tmp = $y x $svd_u;

    #EXPLANATION: the division by (the non-zero elements of) $svd_w (the singular values) is
    #equivalent to $sigma_plus x $tmp, so $tmp is now SIGMA^+ x $svd_u x $y
    if ( $PDL::Bad::Status ) {
	$tmp /= $svd_w->setvaltobad(0.0);
	$tmp->inplace->setbadtoval(0.0);
    } else {
	# not checked
	my $mask = ($svd_w == 0.0);
	$tmp /= ( $svd_w + $mask );
	$tmp *= ( 1 - $mask );
    }

    #EXPLANATION:   $svd_v x SIGMA^+ x $svd_u x $y
    return sumover( $svd_v * $tmp );

} # sub: _svd()

#_mkbasis returns a piddle in which the k(=j*n+i)_th column is v**j * u**i
#k=0 j=0 i=0
#k=1 j=0 i=1
#k=2 j=0 i=2
#k=3 j=1 i=0
# ...

#each row corresponds to a control point
#and the rows for each of the control points look like this, e.g.:
# (1) (u) (u**2) (v) (vu) (v(u**2)) (v**2) ((v**2)u) ((v**2)(u**2))
# and so on for the next control point.

sub _mkbasis ($$$$) {
    my $fit    = shift;
    my $npts   = shift;
    my $u      = shift;
    my $v      = shift;

    my $n      = $fit->getdim(0) - 1;
    my $ncoeff = sum( $fit );

    my $basis = zeroes( $u->type, $ncoeff, $npts );
    my $k = 0;
    foreach my $j ( 0 .. $n ) {
	my $tmp_v = $v**$j;
	foreach my $i ( 0 .. $n ) {
	    if ( $fit->at($i,$j) ) {
		my $tmp = $basis->slice("($k),:");
		$tmp .= $tmp_v * $u**$i;
		$k++;
	    }
	}
    }
    return $basis;

} # sub: _mkbasis()

sub PDL::fitwarp2d {
    croak "Usage: (\$px,\$py) = fitwarp2d(x(m);y(m);u(m);v(m);\$nf; { options })"
	if $#_ < 4 or ( $#_ >= 5 and ref($_[5]) ne "HASH" );

    my $x  = shift;
    my $y  = shift;
    my $u  = shift;
    my $v  = shift;
    my $nf = shift;

    my $opts = PDL::Options->new( { FIT => ones(byte,$nf,$nf) } ); #, THRESH => 1.0e-5 } );
    $opts->options( $_[0] ) if $#_ > -1;
    my $oref = $opts->current();

    # safety checks
    my $npts = $x->nelem;
    croak "fitwarp2d: x, y, u, and v must be the same size (and 1D)"
	unless $npts == $y->nelem and $npts == $u->nelem and $npts == $v->nelem
	    and $x->getndims == 1 and $y->getndims == 1 and $u->getndims == 1 and $v->getndims == 1;

#    my $svd_thresh = $$oref{THRESH};
#    croak "fitwarp2d: THRESH option must be >= 0."
#	if $svd_thresh < 0;

    my $fit = $$oref{FIT};
    my $fit_ndim = $fit->getndims();
    croak "fitwarp2d: FIT option must be sent a (\$nf,\$nf[,2]) element piddle"
	unless UNIVERSAL::isa($fit,"PDL") and
	    ($fit_ndim == 2 or ($fit_ndim == 3 and $fit->getdim(2) == 2)) and
	    $fit->getdim(0) == $nf and $fit->getdim(1) == $nf;

    # how many coeffs to fit (first we ensure $fit is either 0 or 1)
    $fit = convert( $fit != 0, byte );

    my ( $fitx, $fity, $ncoeffx, $ncoeffy, $ncoeff );
    if ( $fit_ndim == 2 ) {
	$fitx = $fit;
	$fity = $fit;
	$ncoeff = $ncoeffx = $ncoeffy = sum( $fit );
    } else {
	$fitx = $fit->slice(",,(0)");
	$fity = $fit->slice(",,(1)");
	$ncoeffx = sum($fitx);
	$ncoeffy = sum($fity);
	$ncoeff = $ncoeffx > $ncoeffy ? $ncoeffx : $ncoeffy;
    }

    croak "fitwarp2d: number of points ($npts) must be >= \$ncoeff ($ncoeff)"
	unless $npts >= $ncoeff;

    # create the basis functions for the SVD fitting
    my ( $basisx, $basisy );

    $basisx = _mkbasis( $fitx, $npts, $u, $v );

    if ( $fit_ndim == 2 ) {
	$basisy = $basisx;
    } else {
	$basisy = _mkbasis( $fity, $npts, $u, $v );
    }

    my $px = _svd( $basisx, $x ); # $svd_thresh);
    my $py = _svd( $basisy, $y ); # $svd_thresh);

    # convert into $nf x $nf element piddles, if necessary
    my $nf2 = $nf * $nf;

    return ( $px->reshape($nf,$nf), $py->reshape($nf,$nf) )
	if $ncoeff == $nf2 and $ncoeffx == $ncoeffy;

    # re-create the matrix
    my $xtmp = zeroes( $nf, $nf );
    my $ytmp = zeroes( $nf, $nf );

    my $kx = 0;
    my $ky = 0;
    foreach my $i ( 0 .. ($nf - 1) ) {
	foreach my $j ( 0 .. ($nf - 1) ) {
	    if ( $fitx->at($i,$j) ) {
		$xtmp->set($i,$j, $px->at($kx) );
		$kx++;
	    }
	    if ( $fity->at($i,$j) ) {
		$ytmp->set($i,$j, $py->at($ky) );
		$ky++;
	    }
	}
    }

    return ( $xtmp, $ytmp )

} # sub: fitwarp2d

*fitwarp2d = \&PDL::fitwarp2d;

sub PDL::applywarp2d {
    # checks
    croak "Usage: (\$x,\$y) = applywarp2d(px(nf,nf);py(nf,nf);u(m);v(m);)"
	if $#_ != 3;

    my $px = shift;
    my $py = shift;
    my $u  = shift;
    my $v  = shift;
    my $npts = $u->nelem;

    # safety check
    croak "applywarp2d: u and v must be the same size (and 1D)"
	unless $npts == $u->nelem and $npts == $v->nelem
	    and $u->getndims == 1 and $v->getndims == 1;

    my $nf  = $px->getdim(0);
    my $nf2 = $nf * $nf;

    # could remove terms with 0 coeff here
    # (would also have to remove them from px/py for
    #  the matrix multiplication below)
    #
    my $mat = _mkbasis( ones(byte,$nf,$nf), $npts, $u, $v );

    my $x = reshape( $mat x $px->clump(-1)->transpose(), $npts );
    my $y = reshape( $mat x $py->clump(-1)->transpose(), $npts );
    return ( $x, $y );

} # sub: applywarp2d

*applywarp2d = \&PDL::applywarp2d;




=head2 warp2d

=for sig

  Signature: (img(m,n); double px(np,np); double py(np,np); [o] warp(m,n); { options })

=for ref

Warp a 2D image given a polynomial describing the I<reverse> mapping.

=for usage

  $out = warp2d( $img, $px, $py, { options } );

Apply the polynomial transformation encoded in the C<$px> and
C<$py> piddles to warp the input image C<$img> into the output
image C<$out>.

The format for the polynomial transformation is described in
the documentation for the L<fitwarp2d()|/fitwarp2d> routine.

At each point C<x,y>, the closest 16 pixel values are combined
with an interpolation kernel to calculate the value at C<u,v>.
The interpolation is therefore done in the image, rather than
Fourier, domain.
By default, a C<tanh> kernel is used, but this can be changed
using the C<KERNEL> option discussed below
(the choice of kernel depends on the frequency content of the input image).

The routine is based on the C<warping> command from
the Eclipse data-reduction package - see http://www.eso.org/eclipse/ - and
for further details on image resampling see
Wolberg, G., "Digital Image Warping", 1990, IEEE Computer
Society Press ISBN 0-8186-8944-7).

Currently the output image is the same size as the input one,
which means data will be lost if the transformation reduces
the pixel scale.  This will (hopefully) be changed soon.

=for example

  $img = rvals(byte,501,501);
  imag $img, { JUSTIFY => 1 };
  #
  # use a not-particularly-obvious transformation:
  #   x = -10 + 0.5 * $u - 0.1 * $v
  #   y = -20 + $v - 0.002 * $u * $v
  #
  $px  = pdl( [ -10, 0.5 ], [ -0.1, 0 ] );
  $py  = pdl( [ -20, 0 ], [ 1, 0.002 ] );
  $wrp = warp2d( $img, $px, $py );
  #
  # see the warped image
  imag $warp, { JUSTIFY => 1 };

The options are:

=for options

  KERNEL - default value is tanh
  NOVAL  - default value is 0

C<KERNEL> is used to specify which interpolation kernel to use
(to see what these kernels look like, use the
L<warp2d_kernel()|/warp2d_kernel> routine).
The options are:

=over 4

=item tanh

Hyperbolic tangent: the approximation of an ideal box filter by the
product of symmetric tanh functions.

=item sinc

For a correctly sampled signal, the ideal filter in the fourier domain is a rectangle,
which produces a C<sinc> interpolation kernel in the spatial domain:

  sinc(x) = sin(pi * x) / (pi * x)

However, it is not ideal for the C<4x4> pixel region used here.

=item sinc2

This is the square of the sinc function.

=item lanczos

Although defined differently to the C<tanh> kernel, the result is very
similar in the spatial domain.  The Lanczos function is defined as

  L(x) = sinc(x) * sinc(x/2)  if abs(x) < 2
       = 0                       otherwise

=item hann

This kernel is derived from the following function:

  H(x) = a + (1-a) * cos(2*pi*x/(N-1))  if abs(x) < 0.5*(N-1)
       = 0                                 otherwise

with C<a = 0.5> and N currently equal to 2001.

=item hamming

This kernel uses the same C<H(x)> as the Hann filter, but with
C<a = 0.54>.

=back

C<NOVAL> gives the value used to indicate that a pixel in the
output image does not map onto one in the input image.

=cut

# support routine
{
    my %warp2d = map { ($_,1) } qw( tanh sinc sinc2 lanczos hamming hann );

    # note: convert to lower case
    sub _check_kernel ($$) {
	my $kernel = lc shift;
	my $code   = shift;
	barf "Unknown kernel $kernel sent to $code\n" .
	    "\tmust be one of [" . join(',',keys %warp2d) . "]\n"
		unless exists $warp2d{$kernel};
	return $kernel;
    }
}





sub PDL::warp2d {
    my $opts = PDL::Options->new( { KERNEL => "tanh", NOVAL => 0 } );
    $opts->options( pop(@_) ) if ref($_[$#_]) eq "HASH";

    die "Usage: warp2d( in(m,n), px(np,np); py(np,np); [o] out(m,n), {Options} )"
	if $#_<2 || $#_>3;
    my $img = shift;
    my $px  = shift;
    my $py  = shift;
    my $out = $#_ == -1 ? PDL->null() : shift;

    # safety checks
    my $copt   = $opts->current();
    my $kernel = _check_kernel( $$copt{KERNEL}, "warp2d" );

    &PDL::_warp2d_int( $img, $px, $py, $out, $kernel, $$copt{NOVAL} );
    return $out;
}



*warp2d = \&PDL::warp2d;





=head2 warp2d_kernel

=for ref

Return the specified kernel, as used by L<warp2d|/warp2d>

=for usage

  ( $x, $k ) = warp2d_kernel( $name )

The valid values for C<$name> are the same as the C<KERNEL> option
of L<warp2d()|/warp2d>.

=for example

  line warp2d_kernel( "hamming" );

=cut





sub PDL::warp2d_kernel ($) {
    my $kernel = _check_kernel( shift, "warp2d_kernel" );

    my $nelem = _get_kernel_size();
    my $x     = zeroes( $nelem );
    my $k     = zeroes( $nelem );

    &PDL::_warp2d_kernel_int( $x, $k, $kernel );
    return ( $x, $k );

#    return _get_kernel( $kernel );
}
*warp2d_kernel = \&PDL::warp2d_kernel;



*warp2d_kernel = \&PDL::warp2d_kernel;



;


=head1 AUTHORS

Copyright (C) Karl Glazebrook 1997 with additions by Robin Williams
(rjrw@ast.leeds.ac.uk), Tim Jeness (timj@jach.hawaii.edu),
and Doug Burke (burke@ifa.hawaii.edu).

All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut





# Exit with OK status

1;

		   