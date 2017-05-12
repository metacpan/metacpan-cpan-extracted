
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::ImageND;

@EXPORT_OK  = qw(  kernctr PDL::PP convolve  ninterpol PDL::PP rebin  circ_mean circ_mean_p PDL::PP convolveND );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::ImageND ;





=head1 NAME

PDL::ImageND - useful image processing in N dimensions

=head1 DESCRIPTION

These routines act on PDLs as N-dimensional objects, not as threaded 
sets of 0-D or 1-D objects.  The file is sort of a catch-all for 
broadly functional routines, most of which could legitimately 
be filed elsewhere (and probably will, one day).  

ImageND is not a part of the PDL core (v2.4) and hence must be explicitly
loaded.

=head1 SYNOPSIS

 use PDL::ImageND;

 $b = $a->convolveND($kernel,{bound=>'periodic'});
 $b = $a->rebin(50,30,10);
 
=cut








=head1 FUNCTIONS



=cut





use Carp;





=head2 convolve

=for sig

  Signature: (a(m); b(n); indx adims(p); indx bdims(q); [o]c(m))

=for ref

N-dimensional convolution (Deprecated; use convolveND)

=for usage

$new = convolve $a, $kernel

Convolve an array with a kernel, both of which are N-dimensional.  This 
routine does direct convolution (by copying) but uses quasi-periodic
boundary conditions: each dim "wraps around" to the next higher row in
the next dim.  

This routine is kept for backwards compatibility with earlier scripts; 
for most purposes you want L<convolveND|PDL::ImageND/convolveND> instead:
it runs faster and handles a variety of boundary conditions.



=for bad

convolve does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






# Custom Perl wrapper

sub PDL::convolve{
    my($a,$b,$c) = @_;
    barf("Usage: convolve(a(*), b(*), [o]c(*)") if $#_<1 || $#_>2;
    $c = PDL->null if $#_<2;
    &PDL::_convolve_int( $a->clump(-1), $b->clump(-1),
       long([$a->dims]), long([$b->dims]),
       ($c->getndims>1? $c->clump(-1) : $c)
     );
     $c->setdims([$a->dims]);

    if($a->is_inplace) {
      $a .= $c;
      $a->set_inplace(0);
      return $a;
    }
    return $c;
}



*convolve = \&PDL::convolve;




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
    print 'Usage: $a = ninterpolate($point(s), $data);' if $#_ != 1;
    my ($p, $y) = @_;
    my ($ip) = floor($p);
    # isolate relevant N-cube
    $y = $y->slice(join (',',map($_.':'.($_+1),list $ip)));
    for (list ($p-$ip)) { $y = interpol($_,$y->xvals,$y); }
    $y;
}





=head2 rebin

=for sig

  Signature: (a(m); [o]b(n); int ns => n)

=for ref

N-dimensional rebinning algorithm

=for usage

$new = rebin $a, $dim1, $dim2,..;.
$new = rebin $a, $template;
$new = rebin $a, $template, {Norm => 1};

Rebin an N-dimensional array to newly specified dimensions.
Specifying `Norm' keeps the sum constant, otherwise the intensities
are kept constant.  If more template dimensions are given than for the
input pdl, these dimensions are created; if less, the final dimensions
are maintained as they were.

So if C<$a> is a 10 x 10 pdl, then C<rebin($a,15)> is a 15 x 10 pdl,
while C<rebin($a,15,16,17)> is a 15 x 16 x 17 pdl (where the values
along the final dimension are all identical).

Expansion is performed by sampling; reduction is performed by averaging.
If you want different behavior, use L<PDL::Transform::map|PDL::Transform/map>
instead.  PDL::Transform::map runs slower but is more flexible.



=for bad

rebin does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






# Custom Perl wrapper

sub PDL::rebin {
    my($a) = shift;
    my($opts) = ref $_[-1] eq "HASH" ? pop : {};
    my(@idims) = $a->dims;
    my(@odims) = ref $_[0] ? $_[0]->dims : @_;
    my($i,$b);
    foreach $i (0..$#odims) {
      if ($i > $#idims) {  # Just dummy extra dimensions
          $a = $a->dummy($i,$odims[$i]);
          next;
      # rebin_int can cope with all cases, but code
      # 1->n and n->1 separately for speed
      } elsif ($odims[$i] != $idims[$i]) {       # If something changes
         if (!($odims[$i] % $idims[$i])) {      # Cells map 1 -> n
               my ($r) = $odims[$i]/$idims[$i];
               $b = $a->mv($i,0)->dummy(0,$r)->clump(2);
         } elsif (!($idims[$i] % $odims[$i])) { # Cells map n -> 1
               my ($r) = $idims[$i]/$odims[$i];
               $a = $a->mv($i,0);
               # -> copy so won't corrupt input PDL
               $b = $a->slice("0:-1:$r")->copy;
               foreach (1..$r-1) {
                  $b += $a->slice("$_:-1:$r");
               }
               $b /= $r;
         } else {                               # Cells map n -> m
             &PDL::_rebin_int($a->mv($i,0), $b = null, $odims[$i]);
         }
         $a = $b->mv(0,$i);
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
      return $a * $norm;
    } else {
      # Explicit copy so i) can't corrupt input PDL through this link
      #                 ii) don't waste space on invisible elements
      return $a -> copy;
    }
}


*rebin = \&PDL::rebin;




=head2 circ_mean_p

=for ref

Calculates the circular mean of an n-dim image and returns
the projection. Optionally takes the center to be used.

=for usage

   $cmean=circ_mean_p($im);
   $cmean=circ_mean_p($im,{Center => [10,10]});

=cut


sub circ_mean_p {
 my ($a,$opt) = @_;
 my ($rad,$sum,$norm);

 if (defined $opt) {
   $rad = long PDL::rvals($a,$opt);
 }
 else {
   $rad = long rvals $a;
 }
 $sum = zeroes($rad->max+1);
 PDL::indadd $a->clump(-1), $rad->clump(-1), $sum; # this does the real work
 $norm = zeroes($rad->max+1);
 PDL::indadd pdl(1), $rad->clump(-1), $norm;       # equivalent to get norm
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
 my ($a,$opt) = @_;
 my ($rad,$sum,$norm,$a1);

 if (defined $opt) {
   $rad = long PDL::rvals($a,$opt);
 }
 else {
   $rad = long rvals $a;
 }
 $sum = zeroes($rad->max+1);
 PDL::indadd $a->clump(-1), $rad->clump(-1), $sum; # this does the real work
 $norm = zeroes($rad->max+1);
 PDL::indadd pdl(1), $rad->clump(-1), $norm;       # equivalent to get norm
 $sum /= $norm;
 $a1 = $a->clump(-1);
 $a1 .= $sum->index($rad->clump(-1));

 return $a;
}




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
    my ($k,$n,$d,$i,@stri,@strk,@b);
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
	for ($n=0, $b=$i; $n <= $#ni; $n++, $b >>= 1) {
        next CHUNK if $stri[$n][$b & 1] eq '';
	  $stri .= $stri[$n][$b & 1];
	  $strk .= $strk[$n][$b & 1];
	}
	chop ($stri); chop ($strk);
	($t = $newk->slice($stri)) .= $kern->slice($strk);
    }
    $newk;
}





=head2 convolveND

=for sig

  Signature: (k0(); SV *k; SV *aa; SV *a)


=for ref

Speed-optimized convolution with selectable boundary conditions

=for usage

$new = convolveND($a, $kernel, [ {options} ]);

Conolve an array with a kernel, both of which are N-dimensional.

If the kernel has fewer dimensions than the array, then the extra array
dimensions are threaded over.  There are options that control the boundary 
conditions and method used.

The kernel's origin is taken to be at the kernel's center.  If your
kernel has a dimension of even order then the origin's coordinates get
rounded up to the next higher pixel (e.g. (1,2) for a 3x4 kernel).
This mimics the behavior of the earlier L<convolve|convolve> and
L<fftconvolve|PDL::FFT/fftconvolve()> routines, so convolveND is a drop-in
replacement for them.


The kernel may be any size compared to the image, in any dimension.

The kernel and the array are not quite interchangeable (as in mathematical
convolution): the code is inplace-aware only for the array itself, and
the only allowed boundary condition on the kernel is truncation.

convolveND is inplace-aware: say C<convolveND(inplace $a ,$k)> to modify
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

At the moment there's no way to thread over kernels.  That could/should
be fixed.

The threading over input is cheesy and should probably be fixed:
currently the kernel just gets dummy dimensions added to it to match
the input dims.  That does the right thing tersely but probably runs slower
than a dedicated threadloop.  

The direct copying code uses PP primarily for the generic typing: it includes
its own threadloops.



=for bad

convolveND does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut





use PDL::Options;

# Perl wrapper conditions the data to make life easier for the PP sub.

sub PDL::convolveND {
  my($a0,$k,$opt0) = @_;
  my $inplace = $a0->is_inplace;
  my $a = $a0->new_or_inplace;

 
  barf("convolveND: kernel (".join("x",$k->dims).") has more dims than source (".join("x",$a->dims).")\n")
    if($a->ndims < $k->ndims);
  

  # Coerce stuff all into the same type.  Try to make sense.
  # The trivial conversion leaves dataflow intact (nontrivial conversions
  # don't), so the inplace code is OK.  Non-inplace code: let the existing
  # PDL code choose what type is best.
  my $type;
  if($inplace) {
	$type = $a0->get_datatype;
  } else {
	my $z = $a->flat->index(0) + $k->flat->index(0);
	$type = $z->get_datatype;
  }
  $a = $a->convert($type);
  $k = $k->convert($type);
	

  ## Handle options -- $def is a static variable so it only gets set up once.
  our $def;
  unless(defined($def)) {
    $def = new PDL::Options( {
                              Method=>'a',
                              Boundary=>'t'
                             }
			     );
    $def->minmatch(1);
    $def->casesens(0);
  }

  my $opt = $def->options(PDL::Options::ifhref($opt0));

  ### 
  # If the kernel has too few dimensions, we thread over the other
  # dims -- this is the same as supplying the kernel with dummy dims of
  # order 1, so, er, we do that.
  $k = $k->dummy($a->dims - 1, 1)
    if($a->ndims > $k->ndims);
  my $kdims = pdl($k->dims); 

  ###
  # Decide whether to FFT or directly convolve: if we're in auto mode,
  # choose based on the relative size of the image and kernel arrays.
  my $fft = ( ($opt->{Method} =~ m/^a/i) ?
	       ( $a->nelem > 2500 and ($a->nelem) <= ($k->nelem * 500) ) :
  	       ( $opt->{Method} !~ m/^[ds]/i )
	      );

  ###
  # Pad the array to include boundary conditions
  my $adims = pdl($a->dims);
  my $koff = ($kdims/2)->ceil - 1;

  my $aa = $a->range( -$koff, $adims + $kdims, $opt->{Boundary} )
               ->sever;

  if($fft) {
    #  The eval here keeps conflicts from happening at compile time
    eval "use PDL::FFT" ;

    print "convolveND: using FFT method\n" if($PDL::debug);

    # FFT works best on doubles; do our work there then cast back
    # at the end.  
    $aa = double($aa);
    my $aai = $aa->zeroes;

    my $kk = $aa->zeroes;
    my $kki = $aa->zeroes;
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
    $a .= $aa->range( $koff, $adims);

  } else {
    print "convolveND: using direct method\n" if($PDL::debug);

    ### The first argument is a dummy to set $GENERIC.	
    &PDL::_convolveND_int( $k->flat->index(0), $k, $aa, $a );

  }


  $a;
}



*convolveND = \&PDL::convolveND;



;


=head1 AUTHORS

Copyright (C) Karl Glazebrook and Craig DeForest, 1997, 2003
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut






# Exit with OK status

1;

		   