#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::ImageND;

our @EXPORT_OK = qw(kernctr convolve ninterpol rebin circ_mean circ_mean_p convolveND contour_segments contour_polylines path_join path_segs );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::ImageND ;







#line 4 "imagend.pd"

=head1 NAME

PDL::ImageND - useful image processing in N dimensions

=head1 DESCRIPTION

These routines act on PDLs as N-dimensional objects, not as broadcasted
sets of 0-D or 1-D objects.  The file is sort of a catch-all for
broadly functional routines, most of which could legitimately
be filed elsewhere (and probably will, one day).

ImageND is not a part of the PDL core (v2.4) and hence must be explicitly
loaded.

=head1 SYNOPSIS

 use PDL::ImageND;

 $y = $x->convolveND($kernel,{bound=>'periodic'});
 $y = $x->rebin(50,30,10);

=cut

use strict;
use warnings;
#line 53 "ImageND.pm"


=head1 FUNCTIONS

=cut





#line 95 "imagend.pd"

use Carp;
#line 67 "ImageND.pm"


=head2 convolve

=for sig

  Signature: (a(m); b(n); indx adims(p); indx bdims(q); [o]c(m))

=for ref

N-dimensional convolution (Deprecated; use convolveND)

=for usage

  $new = convolve $x, $kernel

Convolve an array with a kernel, both of which are N-dimensional.  This
routine does direct convolution (by copying) but uses quasi-periodic
boundary conditions: each dim "wraps around" to the next higher row in
the next dim.

This routine is kept for backwards compatibility with earlier scripts;
for most purposes you want L<convolveND|PDL::ImageND/convolveND> instead:
it runs faster and handles a variety of boundary conditions.

=for bad

convolve does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





sub PDL::convolve {
    my($x,$y,$c) = @_;
    barf("Usage: convolve(a(*), b(*), [o]c(*)") if $#_<1 || $#_>2;
    $c = PDL->null if $#_<2;
    PDL::_convolve_int( $x->flat, $y->flat,
       $x->shape, $y->shape,
       $c->isnull ? $c : $c->flat,
    );
    $c->setdims([$x->dims]);

    if($x->is_inplace) {
      $x .= $c;
      $x->set_inplace(0);
      return $x;
    }
    return $c;
}



*convolve = \&PDL::convolve;





#line 220 "imagend.pd"

=head2 ninterpol()

=for ref

N-dimensional interpolation routine

=for sig

 Signature: ninterpol(point(),data(n),[o]value())

=for usage

      $value = ninterpol($point, $data);

C<ninterpol> uses C<interpol> to find a linearly interpolated value in
N dimensions, assuming the data is spread on a uniform grid.  To use
an arbitrary grid distribution, need to find the grid-space point from
the indexing scheme, then call C<ninterpol> -- this is far from
trivial (and ill-defined in general).

See also L<interpND|PDL::Primitive/interpND>, which includes boundary
conditions and allows you to switch the method of interpolation, but
which runs somewhat slower.

=cut

*ninterpol = \&PDL::ninterpol;

sub PDL::ninterpol {
    use PDL::Math 'floor';
    use PDL::Primitive 'interpol';
    print 'Usage: $x = ninterpolate($point(s), $data);' if $#_ != 1;
    my ($p, $y) = @_;
    my ($ip) = floor($p);
    # isolate relevant N-cube
    $y = $y->slice(join (',',map($_.':'.($_+1),list $ip)));
    for (list ($p-$ip)) { $y = interpol($_,$y->xvals,$y); }
    $y;
}
#line 171 "ImageND.pm"


=head2 rebin

=for sig

  Signature: (a(m); [o]b(n); int ns => n)

=for ref

N-dimensional rebinning algorithm

=for usage

  $new = rebin $x, $dim1, $dim2,..;.
  $new = rebin $x, $template;
  $new = rebin $x, $template, {Norm => 1};

Rebin an N-dimensional array to newly specified dimensions.
Specifying `Norm' keeps the sum constant, otherwise the intensities
are kept constant.  If more template dimensions are given than for the
input pdl, these dimensions are created; if less, the final dimensions
are maintained as they were.

So if C<$x> is a 10 x 10 pdl, then C<rebin($x,15)> is a 15 x 10 pdl,
while C<rebin($x,15,16,17)> is a 15 x 16 x 17 pdl (where the values
along the final dimension are all identical).

Expansion is performed by sampling; reduction is performed by averaging.
If you want different behavior, use L<PDL::Transform::map|PDL::Transform/map>
instead.  PDL::Transform::map runs slower but is more flexible.

=for bad

rebin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





#line 297 "imagend.pd"
sub PDL::rebin {
    my($x) = shift;
    my($opts) = ref $_[-1] eq "HASH" ? pop : {};
    my(@idims) = $x->dims;
    my(@odims) = ref $_[0] ? $_[0]->dims : @_;
    my($i,$y);
    foreach $i (0..$#odims) {
      if ($i > $#idims) {  # Just dummy extra dimensions
          $x = $x->dummy($i,$odims[$i]);
          next;
      # rebin_int can cope with all cases, but code
      # 1->n and n->1 separately for speed
      } elsif ($odims[$i] != $idims[$i]) {       # If something changes
         if (!($odims[$i] % $idims[$i])) {      # Cells map 1 -> n
               my ($r) = $odims[$i]/$idims[$i];
               $y = ($i==0 ? $x : $x->mv($i,0))->dupN($r);
         } elsif (!($idims[$i] % $odims[$i])) { # Cells map n -> 1
               my ($r) = $idims[$i]/$odims[$i];
               $x = $x->mv($i,0) if $i != 0;
               # -> copy so won\'t corrupt input PDL
               $y = $x->slice("0:-1:$r")->copy;
               foreach (1..$r-1) {
                  $y += $x->slice("$_:-1:$r");
               }
               $y /= $r;
         } else {                               # Cells map n -> m
             &PDL::_rebin_int(($i==0 ? $x : $x->mv($i,0)), $y = null, $odims[$i]);
         }
         $x = $y->mv(0,$i);
      }
    }
    if (exists $opts->{Norm} and $opts->{Norm}) {
      my ($norm) = 1;
      for $i (0..$#odims) {
         if ($i > $#idims) {
              $norm /= $odims[$i];
         } else {
              $norm *= $idims[$i]/$odims[$i];
         }
      }
      return $x * $norm;
    } else {
      # Explicit copy so i) can\'t corrupt input PDL through this link
      #                 ii) don\'t waste space on invisible elements
      return $x -> copy;
    }
}
#line 263 "ImageND.pm"

*rebin = \&PDL::rebin;





#line 370 "imagend.pd"

=head2 circ_mean_p

=for ref

Calculates the circular mean of an n-dim image and returns
the projection. Optionally takes the center to be used.

=for usage

   $cmean=circ_mean_p($im);
   $cmean=circ_mean_p($im,{Center => [10,10]});

=cut

sub circ_mean_p {
 my ($x,$opt) = @_;
 my ($rad,$sum,$norm);

 if (defined $opt) {
   $rad = indx PDL::rvals($x,$opt);
 }
 else {
   $rad = indx rvals $x;
 }
 my $max1 = $rad->max->sclr+1;
 $sum = zeroes($max1);
 PDL::indadd $x->flat, $rad->flat, $sum; # this does the real work
 $norm = zeroes($max1);
 PDL::indadd pdl(1), $rad->flat, $norm;       # equivalent to get norm
 $sum /= $norm;
 return $sum;
}

=head2 circ_mean

=for ref

Smooths an image by applying circular mean.
Optionally takes the center to be used.

=for usage

   circ_mean($im);
   circ_mean($im,{Center => [10,10]});

=cut

sub circ_mean {
 my ($x,$opt) = @_;
 my ($rad,$sum,$norm,$a1);

 if (defined $opt) {
   $rad = indx PDL::rvals($x,$opt);
 }
 else {
   $rad = indx rvals $x;
 }
 my $max1 = $rad->max->sclr+1;
 $sum = zeroes($max1);
 PDL::indadd $x->flat, $rad->flat, $sum; # this does the real work
 $norm = zeroes($max1);
 PDL::indadd pdl(1), $rad->flat, $norm;       # equivalent to get norm
 $sum /= $norm;
 $a1 = $x->flat;
 $a1 .= $sum->index($rad->flat);

 return $x;
}

#line 448 "imagend.pd"

=head2 kernctr

=for ref

`centre' a kernel (auxiliary routine to fftconvolve)

=for usage

	$kernel = kernctr($image,$smallk);
	fftconvolve($image,$kernel);

kernctr centres a small kernel to emulate the behaviour of the direct
convolution routines.

=cut

*kernctr = \&PDL::kernctr;

sub PDL::kernctr {
    # `centre' the kernel, to match kernel & image sizes and
    # emulate convolve/conv2d.  FIX: implement with phase shifts
    # in fftconvolve, with option tag
    barf "Must have image & kernel for kernctr" if $#_ != 1;
    my ($imag, $kern) = @_;
    my (@ni) = $imag->dims;
    my (@nk) = $kern->dims;
    barf "Kernel and image must have same number of dims" if $#ni != $#nk;
    my ($newk) = zeroes(double,@ni);
    my ($k,$n,$y,$d,$i,@stri,@strk,@b);
    for ($i=0; $i <= $#ni; $i++) {
	$k = $nk[$i];
	$n = $ni[$i];
	barf "Kernel must be smaller than image in all dims" if ($n < $k);
	$d = int(($k-1)/2);
        $stri[$i][0] = "0:$d,";
        $strk[$i][0] = (-$d-1).":-1,";
        $stri[$i][1] = $d == 0 ? '' : ($d-$k+1).':-1,';
        $strk[$i][1] = $d == 0 ? '' : '0:'.($k-$d-2).',';
    }
    # kernel is split between the 2^n corners of the cube
    my ($nchunk) = 2 << $#ni;
    CHUNK:
      for ($i=0; $i < $nchunk; $i++) {
	my ($stri,$strk);
	for ($n=0, $y=$i; $n <= $#ni; $n++, $y >>= 1) {
        next CHUNK if $stri[$n][$y & 1] eq '';
	  $stri .= $stri[$n][$y & 1];
	  $strk .= $strk[$n][$y & 1];
	}
	chop ($stri); chop ($strk);
	(my $t = $newk->slice($stri)) .= $kern->slice($strk);
    }
    $newk;
}
#line 398 "ImageND.pm"


=head2 convolveND

=for sig

  Signature: (k0(); pdl *k; pdl *aa; pdl *a)

=for ref

Speed-optimized convolution with selectable boundary conditions

=for usage

  $new = convolveND($x, $kernel, [ {options} ]);

Convolve an array with a kernel, both of which are N-dimensional.

If the kernel has fewer dimensions than the array, then the extra array
dimensions are broadcasted over.  There are options that control the boundary
conditions and method used.

The kernel's origin is taken to be at the kernel's center.  If your
kernel has a dimension of even order then the origin's coordinates get
rounded up to the next higher pixel (e.g. (1,2) for a 3x4 kernel).
This mimics the behavior of the earlier L</convolve> and
L<fftconvolve|PDL::FFT/fftconvolve()> routines, so convolveND is a drop-in
replacement for them.

The kernel may be any size compared to the image, in any dimension.

The kernel and the array are not quite interchangeable (as in mathematical
convolution): the code is inplace-aware only for the array itself, and
the only allowed boundary condition on the kernel is truncation.

convolveND is inplace-aware: say C<convolveND(inplace $x ,$k)> to modify
a variable in-place.  You don't reduce the working memory that way -- only
the final memory.

OPTIONS

Options are parsed by PDL::Options, so unique abbreviations are accepted.

=over 3

=item boundary (default: 'truncate')

The boundary condition on the array, which affects any pixel closer
to the edge than the half-width of the kernel.

The boundary conditions are the same as those accepted by
L<range|PDL::Slices/range>, because this option is passed directly
into L<range|PDL::Slices/range>.  Useful options are 'truncate' (the
default), 'extend', and 'periodic'.  You can select different boundary
conditions for different axes -- see L<range|PDL::Slices/range> for more
detail.

The (default) truncate option marks all the near-boundary pixels as BAD if
you have bad values compiled into your PDL and the array's badflag is set.

=item method (default: 'auto')

The method to use for the convolution.  Acceptable alternatives are
'direct', 'fft', or 'auto'.  The direct method is an explicit
copy-and-multiply operation; the fft method takes the Fourier
transform of the input and output kernels.  The two methods give the
same answer to within double-precision numerical roundoff.  The fft
method is much faster for large kernels; the direct method is faster
for tiny kernels.  The tradeoff occurs when the array has about 400x
more pixels than the kernel.

The default method is 'auto', which chooses direct or fft convolution
based on the size of the input arrays.

=back

NOTES

At the moment there's no way to broadcast over kernels.  That could/should
be fixed.

The broadcasting over input is cheesy and should probably be fixed:
currently the kernel just gets dummy dimensions added to it to match
the input dims.  That does the right thing tersely but probably runs slower
than a dedicated broadcastloop.

The direct copying code uses PP primarily for the generic typing: it includes
its own broadcastloops.

=for bad

convolveND does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut





use PDL::Options;

# Perl wrapper conditions the data to make life easier for the PP sub.

sub PDL::convolveND {
  my($a0,$k,$opt0) = @_;
  my $inplace = $a0->is_inplace;
  my $x = $a0->new_or_inplace;

  barf("convolveND: kernel (".join("x",$k->dims).") has more dims than source (".join("x",$x->dims).")\n")
    if($x->ndims < $k->ndims);

  # Coerce stuff all into the same type.  Try to make sense.
  # The trivial conversion leaves dataflow intact (nontrivial conversions
  # don't), so the inplace code is OK.  Non-inplace code: let the existing
  # PDL code choose what type is best.
  my $type;
  if($inplace) {
	$type = $a0->get_datatype;
  } else {
	my $z = $x->flat->index(0) + $k->flat->index(0);
	$type = $z->get_datatype;
  }
  $x = $x->convert($type);
  $k = $k->convert($type);

  ## Handle options -- $def is a static variable so it only gets set up once.
  our $def;
  unless(defined($def)) {
    $def = PDL::Options->new( {
                              Method=>'a',
                              Boundary=>'t'
                             }
			     );
    $def->minmatch(1);
    $def->casesens(0);
  }

  my $opt = $def->options(PDL::Options::ifhref($opt0));

  ###
  # If the kernel has too few dimensions, we broadcast over the other
  # dims -- this is the same as supplying the kernel with dummy dims of
  # order 1, so, er, we do that.
  $k = $k->dummy($x->dims - 1, 1)
    if($x->ndims > $k->ndims);
  my $kdims = pdl($k->dims);

  ###
  # Decide whether to FFT or directly convolve: if we're in auto mode,
  # choose based on the relative size of the image and kernel arrays.
  my $fft = ( ($opt->{Method} =~ m/^a/i) ?
	       ( $x->nelem > 2500 and ($x->nelem) <= ($k->nelem * 500) ) :
  	       ( $opt->{Method} !~ m/^[ds]/i )
	      );

  ###
  # Pad the array to include boundary conditions
  my $adims = $x->shape;
  my $koff = ($kdims/2)->ceil - 1;

  my $aa = $x->range( -$koff, $adims + $kdims, $opt->{Boundary} )
               ->sever;

  if($fft) {
    require PDL::FFT;

    print "convolveND: using FFT method\n" if($PDL::debug);

    # FFT works best on doubles; do our work there then cast back
    # at the end.
    $aa = double($aa);
    $_ = $aa->zeroes for my ($aai, $kk, $kki);
    my $tmp;  # work around new perl -d "feature"
    ($tmp = $kk->range( - ($kdims/2)->floor, $kdims, 'p')) .= $k;
    PDL::fftnd($kk, $kki);
    PDL::fftnd($aa, $aai);

    {
      my($ii) = $kk * $aai   +    $aa * $kki;
      $aa =     $aa * $kk    -   $kki * $aai;
      $aai .= $ii;
    }

    PDL::ifftnd($aa,$aai);
    $x .= $aa->range( $koff, $adims);

  } else {
    print "convolveND: using direct method\n" if($PDL::debug);

    ### The first argument is a dummy to set $GENERIC.
    &PDL::_convolveND_int( $k->flat->index(0), $k, $aa, $x );

  }

  $x;
}




*convolveND = \&PDL::convolveND;






=head2 contour_segments

=for sig

  Signature: (c(); data(m,n); points(d,m,n);
    [o] segs(d,q=CALC(($SIZE(m)-1)*($SIZE(n)-1)*4)); indx [o] cnt();)

=for ref

Finds a contour in given data. Takes 3 ndarrays as input:

C<$c> is the contour value (broadcast with this)

C<$data> is an [m,n] array of values at each point

C<$points> is a list of [d,m,n] points. It should be a grid monotonically
increasing with m and n.

Returns C<$segs>, and C<$cnt> which is the highest 2nd-dim index in
C<$segs> that's defined. The contours are a collection of disconnected
line segments rather than a set of closed polygons.

The data array represents samples of some field observed on the surface
described by points. This uses a variant of the Marching Squares
algorithm, though without being data-driven.

=for bad

contour_segments does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*contour_segments = \&PDL::contour_segments;






=head2 contour_polylines

=for sig

  Signature: (c(); data(m,n); points(d,m,n);
    indx [o] pathendindex(q=CALC(($SIZE(m)-1)*($SIZE(n)-1)*5)); [o] paths(d,q);
    byte [t] seenmap(m,n))

=for ref

Finds polylines describing contours in given data. Takes 3 ndarrays as input:

C<$c> is the contour value (broadcast with this)

C<$data> is an [m,n] array of values at each point

C<$points> is a list of [d,m,n] points. It should be a grid monotonically
increasing with m and n.

Returns C<$pathendindex>, and C<$paths>. Any C<$pathendindex> entries
after the pointers to the ends of polylines are negative.

=head3 Algorithm

Has two modes: scanning, and line-walking. Scanning is done from the
top left, along each row. Each point can be considered as, at C<a>:

    a|b
   +-+-
  c|d|e

Every potential boundary above, or to the left of (including the bottom
boundaries), C<a> has been cleared (marked with a space above).

=head4 Boundary detection

This is done by first checking both points' coordinates are within
bounds, then checking if the boundary is marked seen, then detecting
whether the two cells' values cross the contour threshold.

=head4 Scanning

If detect boundary between C<a>-C<b>, and also C<a>-C<d>, C<d>-C<e>,
or C<b>-C<e>, line-walking starts C<a>-C<b> facing south.

If not, mark C<a>-C<b> seen.

If detect boundary C<a>-C<d> and C<c>-C<d>, line-walking starts C<a>-C<d>
facing west.

If detect boundary C<a>-C<d> and also C<d>-C<e> or C<b>-C<e>, line-walking
starts C<a>-C<d> facing east.

If not, mark C<a>-C<d> seen, and continue scanning.

=head4 Line-walking

The conditions above guarantee that any line started will have at least
two points, since two connected "points" (boundaries between two cells)
have been detected. The coordinates of the back end of the starting
"point" (boundary with direction) are recorded.

At each, a line-point is emitted and that "point" is marked seen. The
coordinates emitted are linearly interpolated between the coordinates
of the two cells similarly to the Marching Squares algorithm.

The next "point" is sought, looking in order right, straight ahead, then
left. Each one not detected is marked seen. That order means the walked
boundary will always turn as much right (go clockwise) as available,
thereby guaranteeing enclosing the area, which deals with saddle points.

If a next "point" is found, move to that and repeat.

If not, then if the front of the ending "point" (boundary plus direction)
is identical to the back of the starting point, a final point is emitted
to close the shape. Then the polyline is closed by emitting the current
point-counter into C<polyendindex>.

=for usage

  use PDL;
  use PDL::ImageND;
  use PDL::Graphics::Simple;
  $SIZE = 500;
  $vals = rvals($SIZE,$SIZE)->divide($SIZE/12.5)->sin;
  @cntr_threshes = zeroes(9)->xlinvals($vals->minmax)->list;
  $win = pgswin();
  $xrange = [0,$vals->dim(0)-1]; $yrange = [0,$vals->dim(1)-1];
  $win->plot(with=>'image', $vals, {xrange=>$xrange,yrange=>$yrange,j=>1},);
  for $thresh (@cntr_threshes) {
    ($pi, $p) = contour_polylines($thresh, $vals, $vals->ndcoords);
    $pi_max = $pi->max;
    next if $pi_max < 0;
    $pi = $pi->where($pi > -1);
    $p = $p->slice(',0:'.$pi_max);
    @paths = path_segs($pi, $p->mv(0,-1));
    $win->oplot(
      (map +(with=>'lines', $_->dog), @paths),
      {xrange=>$xrange,yrange=>$yrange,j=>1},
    );
  }
  print "ret> "; <>;

=for bad

contour_polylines does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*contour_polylines = \&PDL::contour_polylines;






=head2 path_join

=for sig

  Signature: (e(v=2,n);
    indx [o] pathendindex(n); indx [o] paths(nout=CALC($SIZE(n)*2));
    indx [t] highestoutedge(d); indx [t] outedges(d,d); byte [t] hasinward(d);
    indx [t] sourceids(d);
  ; PDL_Indx d => d; int directed)

=for ref

Links a (by default directed) graph's edges into paths.

The outputs are the indices into C<paths> ending each path. Past the last
path, the indices are set to -1.

=for bad

path_join does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*path_join = \&PDL::path_join;





#line 1138 "imagend.pd"

=head2 path_segs

=for ref

Divide a path into segments.

=for usage

  @segments = path_segs($pathindices, $paths);

Returns a series of slices of the C<paths>, such as those created by
L</path_join>, stopping at the first negative index. Currently does not
broadcast.

=for example

  use PDL;
  use PDL::ImageND;
  use PDL::Graphics::Simple;
  $SIZE = 500;
  $vals = rvals($SIZE,$SIZE)->divide($SIZE/12.5)->sin;
  @cntr_threshes = zeroes(9)->xlinvals($vals->minmax)->list;
  $win = pgswin();
  $xrange = [0,$vals->dim(0)-1]; $yrange = [0,$vals->dim(1)-1];
  $win->plot(with=>'image', $vals, {xrange=>$xrange,yrange=>$yrange,j=>1},);
  for $thresh (@cntr_threshes) {
    my ($segs, $cnt) = contour_segments($thresh, $vals, $vals->ndcoords);
    my $segscoords = $segs->slice(',0:'.$cnt->max)->clump(-1)->splitdim(0,4);
    $linesegs = $segscoords->splitdim(0,2);
    $uniqcoords = $linesegs->uniqvec;
    next if $uniqcoords->dim(1) < 2;
    $indexed = vsearchvec($linesegs, $uniqcoords)->uniqvec;
    @paths = path_segs(path_join($indexed, $uniqcoords->dim(1), 0));
    @paths = map $uniqcoords->dice_axis(1, $_)->mv(0,-1), @paths;
    $win->oplot(
      (map +(with=>'lines', $_->dog), @paths),
      {xrange=>$xrange,yrange=>$yrange,j=>1},
    );
  }
  print "ret> "; <>;

=cut

*path_segs = \&PDL::path_segs;
sub PDL::path_segs {
  my ($pi, $p) = @_;
  my ($startind, @out) = 0;
  for ($pi->list) {
    last if $_ < 0;
    push @out, $p->slice("$startind:$_");
    $startind = $_ + 1;
  }
  @out;
}

#line 34 "imagend.pd"

=head1 AUTHORS

Copyright (C) Karl Glazebrook and Craig DeForest, 1997, 2003
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 872 "ImageND.pm"

# Exit with OK status

1;
