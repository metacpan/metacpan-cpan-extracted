
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::FFTW3;

our @EXPORT_OK = qw( fft1 ifft1 rfft1 rNfft1 irfft1 fft2 ifft2 rfft2 rNfft2 irfft2 fft3 ifft3 rfft3 rNfft3 irfft3 fft4 ifft4 rfft4 rNfft4 irfft4 fft5 ifft5 rfft5 rNfft5 irfft5 fft6 ifft6 rfft6 rNfft6 irfft6 fft7 ifft7 rfft7 rNfft7 irfft7 fft8 ifft8 rfft8 rNfft8 irfft8 fft9 ifft9 rfft9 rNfft9 irfft9 fft10 ifft10 rfft10 rNfft10 irfft10 fftn ifftn rfftn irfftn );
our %EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   our $VERSION = '0.15';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::FFTW3 $VERSION;




#line 0 "README.pod"

=head1 NAME

PDL::FFTW3 - PDL interface to the Fastest Fourier Transform in the West v3

=head1 SYNOPSIS

 use PDL;
 use PDL::FFTW3;
 use PDL::Graphics::Gnuplot;
 use PDL::Complex;

 # Basic functionality
 my $x = sin( sequence(100) * 2.0 ) + 2.0 * cos( sequence(100) / 3.0 );
 my $F = rfft1( $x );
 gplot( with => 'lines', inner($F,$F));

 =====>

  8000 ++------------+-------------+------------+-------------+------------++
       +             +             +            +             +             +
       |                                                                    |
       |      *                                                             |
  7000 ++     *                                                            ++
       |      *                                                             |
       |      *                                                             |
       |      *                                                             |
       |      *                                                             |
  6000 ++     *                                                            ++
       |      *                                                             |
       |      *                                                             |
       |      *                                                             |
  5000 ++     *                                                            ++
       |      *                                                             |
       |      *                                                             |
       |      **                                                            |
  4000 ++     **                                                           ++
       |      **                                                            |
       |     * *                                                            |
       |     * *                                                            |
       |     * *                                                            |
  3000 ++    * *                                                           ++
       |     * *                                                            |
       |     * *                                                            |
       |     * *                                   *                        |
  2000 ++    * *                                   *                       ++
       |     * *                                   *                        |
       |     * *                                   **                       |
       |     * *                                   **                       |
       |     * *                                   **                       |
  1000 ++    *  *                                 * *                      ++
       |     *  *                                 * *                       |
       |    **   *                                *  *                      |
       +   *     *   +             +            + *  *        +             +
     0 ****-------*********************************--************************
       0             10            20           30            40            50



 # Correlation of two real signals

 # two signals offset by 30 units
 my $x    = sequence(100);
 my $y1   = exp( 0.2*($x - 20.5) ** (-2.0) );
 my $y2   = exp( 0.2*($x - 50.5) ** (-2.0) );

 # compute the correlation
 my $F12  = rfft1( cat($y1,$y2) );
 my $corr = irfft1( Cmul(      $F12(:,:,(1)),
                            Cconj $F12(:,:,(0)) ) );
 # and find the peak
 say maximum_ind($corr);

 =====> 30

=head1 DESCRIPTION

This is a PDL binding to version 3 of the FFTW library. Supported are complex
<-> complex and real <-> complex FFTs.

=head2 NB to install

  wget http://www.fftw.org/fftw-3.3.4.tar.gz
  tar xvf fftw-3.3.4.tar.gz
  cd fftw-3.3.4/
  ./configure --prefix=/usr --enable-threads --enable-float --enable-shared --with-pic
  make all install install-pkgconfigDATA
  make clean
  ./configure --prefix=/usr --enable-threads --enable-shared --with-pic
  make all install install-pkgconfigDATA

This will give you both fftw3f (first chunk) and fftw3 (second).

=head2 Supported operations

This module computes the Discrete Fourier Transform. In its most basic form,
this transform converts a vector of complex numbers in the time domain into
another vector of complex numbers in the frequency domain. These complex <->
complex transforms are supported with C<fftN> functions for a rank-C<N>
transform. The opposite effect (transform data in the frequency domain back to
the time domain) can be achieved with the C<ifftN> functions.

A common use case is to transform purely-real data. This data has 0 for its
complex component, and FFTW can take advantage of this to compute the FFT faster
and using less memory. Since a Fourier Transform of a real signal has an even
real part and an odd imaginary part, only 1/2 of the spectrum is needed. These
forward real -> complex transforms are supported with the C<rfftN> functions.
The backward version of this transform is complex -> real and is supported with
the C<irfftN> functions.

=head2 Basic usage details

Arbitrary C<N>-dimensional transforms are supported. All functions exported by
this module have the C<N> in their name, so for instance a complex <-> complex
3D forward transform is computed with the C<fft3> function. The rank I<must
always> be specified in this way; there is no function called simply C<fft>.

In-place operation is supported for complex <-> complex functions, but not the
real ones (real function don't have mathing dimensionality of the input and
output). An in-place transform of C<$x> can be computed with

 fft1( $x->inplace );

All the functions in this module support PDL threading. For instance, if we have
4 different image ndarrays C<$a>, C<$b>, C<$c>, C<$d> and we want to compute
their 2D FFTs at the same time, we can say

 my $ABCD_transformed = rfft2( PDL::cat( $a, $b, $c, $d) );

This takes advantage of PDL's automatic parallelization, if appropriate (See
L<PDL::ParallelCPU>).

=head2 Data formats

FFTW supports single and double-precision floating point numbers directly. If
possible, the PDL input will be used as-is. If not, a type conversion will be
made to use the lowest-common type. So as an example, the following will perform
a single-precision floating point transform (and return data of that type).

 fft1( $x->byte )

This module expects complex numbers to be stored as a (real,imag) pair in the
first dimension of an ndarray. Thus in a complex ndarray C<$x>, it is expected that
C<$x-E<gt>dim(0) == 2> (this module verifies this before proceeding).
As of 0.10, it works to pass in a L<PDL::Complex> object, though the
output will still currently be a similarly-shaped "real" L<PDL>
object with the initial dimension of 2. This is intended to be changed
so the output type is the same as the input.

As of version 0.11, you can also pass in ndarrays with the new "native
complex" types (C<cfloat>, C<cdouble>), without the initial dimension of
2. Outputs will also be native complex.

Generally, the sizes of the input and the output must match. This is completely
true for the complex <-> complex transforms: the output will have the same size
and the input, and an error will result if this isn't possible for some reason.

This is a little bit more involved for the real <-> complex transforms. If I'm
transforming a real 3D vector of dimensions C<K,L,M>, I will get an output of
dimensions C<2,int(K/2)+1,L,M>. The leading 2 is there because the output is
complex; the C<K/2> is there because the input was real. The first dimension is
always the one that gets the C<K/2>. This is described in detail in section 2.4
of the FFTW manual.

Note that given a real input, the dimensionality of the complex transformed
output is unambiguous. However, this is I<not> true for the backward transform.
For instance, a 1D inverse transform of a vector of 10 complex numbers can
produce real output of either 18 or 19 elements (because C<int(18/2)+1 == 10>
and C<int(19/2)+1 == 10>).

I<Without any extra information this module assumes the even-sized input>.

Thus C<irfft1( sequence(2,10) )-E<gt>dim(0) == 18> is true. If we want the odd-sized output, we have to explicitly pass this into the function like this:

 irfft1( sequence(2,10), zeros(19) )

Here I create a new output ndarray with the C<zeros> function; C<irfft1> then
fills in this ndarray with the result of the computation. This module validates
all of its input, so only 18 and 19 are valid here. An error will be thrown if
you try to pass in C<zeros(20)>.

This all means that the following will produce surprising results if
C<$x-E<gt>dim(0)> isn't even

 irfft1( rfft1( $x ) )

=head2 FFT normalization

Following the widest-used convention for discrete Fourier transforms,
this module normalizes the inverse transform (but not the forward
transform) by dividing by the number of elements in the data set, so
that

 ifft1( fft1( $x ) )

is a slow approximate no-op, if C<$x> is well-behaved.

This is different from the behavior of the underlying FFTW3 library itself,
but more consistent with other FFT packages for popular analysis languages
including PDL.


=head1 FUNCTIONS

=head2 fftX (fft1, fft2, fft3, ..., fftn)

The basic complex <-> complex FFT. You can pass in the rank as a
parameter with the C<fftn> form, or append the rank to the function
name for ranks up to 9. These functions all take one input ndarray and
one output ndarray.  The dimensions of the input and the output are
identical. The output parameter is optional and, if present, must be
the last argument. If the output ndarray is passed in, the user I<must>
make sure the dimensions match.

If PDL 2.027+ "native complex" data is the input, the dimensions are as
you'd expect. Otherwise, the 0 dim of the input PDL must have size 2 and
run over (real,imaginary) components. The transform is carried out over
the remaining dims.

The fftn form takes a minimum of two arguments: the PDL to transform,
and the number of dimensions to transform as a separate argument.

The following are equivalent:

 $X = fftn( $x, 1 );
 $X = fft1( $x );
 fft1( $x, my $X = $x->zeros );


=head2 ifftX (ifft1, ifft2, ifft3, ..., ifftn)

The basic, properly normalized, complex <-> complex backward
FFT. Everything is exactly like in the C<fftX> functions, except the
inverse transform is computed and normalized, so that (for example)

 ifft1( fft1 ( $x ) )

is a good approximation of C<$x> itself.

=head2 rfftX (rfft1, rfft2, rfft3, ..., rfftn)

The real -> complex FFT. You can pass in the rank with the C<rfftn>
form, or append the rank to the function name for ranks up to 9.
These functions all take one input ndarray and one output ndarray. The
dimensions of the input and the output are not identical, but are
related as described in L<Data formats>. The output can be passed in
as the last argument, if desired. If the output ndarray is passed in,
the user I<must> make sure the dimensions match.

In the C<rfftn> form, the rank is the second argument.

The following are equivalent:

 $X = rfftn( $x, 1 );
 $X = rfft1( $x );
 rfft1( $x, my $X = $x->zeroes );

=head2 rNfftX (rNfft1, rNfft2, rNfft3, ..., rNfftn)

Similar to the above, but returns native-complex ndarrays.

=head2 irfftX (irfft1, irfft2, irfft3, ..., irfftn)

The complex -> real inverse FFT. You can pass in the rank with the
C<irfftn> form, or append the rank to the function name for ranks up
to 9. Argument passing and interpretation is as described in
C<rfftX> above. Please read L<Data formats> for details about dimension
interpretation. There's an ambiguity about the output dimensionality,
which is described in that section.

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>; contributions from Craig
DeForest, C<< <craig@deforest.org> >>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dima Kogan and Craig DeForest.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License.

=cut

use strict;
use warnings;



















































































































































































































































































































#line 0 "FFTW3_header_include.pm"

# This file is included by FFTW3.pd


use PDL::Types;
use List::Util 'reduce';

# when I compute an FFTW plan, it goes here
my %existingPlans;

# these are for the unit tests
our $_Nplans = 0;
our $_last_do_double_precision;

# This file is included verbatim into the final module via pp_addpm()

# This is a function that sits between the user's call into this module and the
# PP-generated internals. Specifically, this function is called BEFORE any PDL
# threading happens. Here I make sure the FFTW plan exists, or if it doesn't, I
# make it. Thus the PP-based internals can safely assume that the plan exists
sub __fft_internal {
  my $thisfunction = shift;

  my ($do_inverse_fft, $is_real_fft, $is_native_output, $rank) = $thisfunction =~ /^(i?)(r?)(N?).*fft([0-9]+)/;

  # first I parse the variables. This is a very direct translation of what PP
  # does normally. Plan-creation has to be outside of PP, so I must re-do this
  # here
  my $Nargs = scalar @_;

  my ($in, $out);
  if ( $Nargs == 2 ) {
    # all variables on stack, read in output and temp vars
    ($in, $out) = map {defined $_ ? PDL::Core::topdl($_) : $_} @_;
  } elsif ( $Nargs == 1 ) {
    $in = PDL::Core::topdl $_[0];
    if ( $in->is_inplace ) {
      barf <<EOF if $is_real_fft;
$thisfunction: in-place real FFTs are not supported since the input/output types and data sizes differ.
Giving up.
EOF
      $out = $in;
      $in->set_inplace(0);
    } else {
      $out = PDL::null();
    }
  } else {
    barf( <<EOF );
$thisfunction must be given the input or the input and output as args.
Exactly 1 or 2 arguments are required. Instead I got $Nargs args. Giving up.
EOF
  }

  # make sure the in/out types match. Convert $in if needed. This needs to
  # happen before we instantiate $out (if it's null) to make sure we know the
  # type
  processTypes( $thisfunction, $is_native_output, \$in, \$out );

  # I now create an ndarray for the null output. Normally PP does this, but I need
  # to have the ndarray made to create plans. If I don't, the alignment may
  # differ between plan-time and run-time
  if ( $out->isnull ) {
    my @args = getOutArgs($in, $is_real_fft, $do_inverse_fft, $is_native_output);
    $out .= zeros(@args);
  }

  validateArguments( $rank, $is_real_fft, $do_inverse_fft, $is_native_output, $thisfunction, $in, $out );

  # I need to physical-ize the ndarrays before I make a plan. Again, normally PP
  # does this, but to make sure alignments match, I need to do this myself, now
  $in->make_physical;
  $out->make_physical;

  my $plan = getPlan( $thisfunction, $rank, $is_real_fft, $do_inverse_fft, $in, $out );
  barf "$thisfunction couldn't make a plan. Giving up\n" unless defined $plan;

  my $is_native = !$in->type->real; # native complex
  $is_native_output ||= !$out->type->real;
  # I now have the arguments and the plan. Go!
  my $internal_function = 'PDL::__';
  $internal_function .=
    ($is_native && !$is_real_fft) ? 'N' :
    !$is_real_fft ? '' :
    ($is_native && $do_inverse_fft) ? 'irN' :
    $do_inverse_fft ? 'ir' :
    ($is_native_output) ? 'rN' :
    'r';
  $internal_function .= "fft$rank";
  eval { no strict 'refs'; $internal_function->( $in, $out, $plan ) };
  barf $@ if $@;

  ($in->isa('PDL::Complex') && !($do_inverse_fft  && $is_real_fft))
    ? $out->complex : $out;
}

sub getOutArgs {
  my ($in, $is_real_fft, $do_inverse_fft, $is_native_output) = @_;

  my @dims = $in->dims;
  my $is_native = !$in->type->real;
  my $out_type = $in->type;

  if ( !$is_real_fft ) {
    # complex fft. Output is the same size as the input.
  } elsif ( !$do_inverse_fft ) {
    # forward real fft
    $dims[0] = int($dims[0]/2)+1;
    if ($is_native_output) {
      $out_type = typeWithComplexity(getPrecision($out_type), $is_native_output);
    } else {
      unshift @dims, 2;
    }
  } else {
    # backward real fft
    #
    # there's an ambiguity here. I want int($out->dim(0)/2) + 1 == $in->dim(1),
    # however this could mean that
    #  $out->dim(0) = 2*$in->dim(1) - 2
    # or
    #  $out->dim(0) = 2*$in->dim(1) - 1
    #
    # WITHOUT ANY OTHER INFORMATION, I ASSUME EVEN INPUT SIZES, SO I ASSUME
    #  $out->dim(0) = 2*$in->dim(1) - 2
    if ($is_native) {
      $out_type = ($out_type == cfloat) ? float : double;
    } else {
      shift @dims;
    }
    $dims[0] = 2*($dims[0]-1);
  }
  ($out_type, @dims);
}

sub validateArguments
{
  my ($rank, $is_real_fft, $do_inverse_fft, $is_native_output, $thisfunction, $in, $out) = @_;

  for my $arg ( $in, $out )
  {
    barf <<EOF unless defined $arg;
$thisfunction arguments must all be defined. If you want an auto-growing ndarray, use 'null' such as
$thisfunction( \$in, \$out = null )
Giving up.
EOF

    my $type = ref $arg;
    $type = 'scalar' unless defined $arg;
    barf <<EOF unless ref $arg && $arg->isa('PDL');
$thisfunction arguments must be of type 'PDL' (including 'PDL::Complex').
Instead I got an arg of type '$type'. Giving up.
EOF
  }

  # validate dimensionality of the ndarrays
  my @inout = ($in, $out);

  for my $iarg ( 0..1 )
  {
    my $arg = $inout[$iarg];

    if( $arg->isnull )
    {
      barf "$thisfunction: don't know what to do with a null input. Giving up";
    }

    if( !$is_real_fft )
    { validateArgumentDimensions_complex( $rank, $thisfunction, $arg); }
    else
    { validateArgumentDimensions_real( $rank, $do_inverse_fft, $is_native_output, $thisfunction, $iarg, $arg); }
  }

  # we have an explicit output ndarray we're filling in. Make sure the
  # input/output dimensions match up
  if ( !$is_real_fft )
  { matchDimensions_complex($thisfunction, $rank, $in, $out); }
  else
  { matchDimensions_real($thisfunction, $rank, $do_inverse_fft, $is_native_output, $in, $out); }
}

sub validateArgumentDimensions_complex
{
  my ( $rank, $thisfunction, $arg ) = @_;
  my $is_native = !$arg->type->real;

  # complex FFT. Identically-sized inputs/outputs
  barf <<EOF if !$is_native and $arg->dim(0) != 2;
$thisfunction must have dim(0) == 2 for non-native complex inputs and outputs.
This is the (real,imag) dimension. Giving up.
EOF

  my $dims_cmp = $arg->ndims - ($is_native ? 0 : 1);
  barf <<EOF if $dims_cmp < $rank;
Tried to compute a $rank-dimensional FFT, but an array has fewer than $rank dimensions.
Giving up.
EOF
}

sub validateArgumentDimensions_real {
  my ( $rank, $do_inverse_fft, $is_native_output, $thisfunction, $iarg, $arg ) = @_;
  my $is_native = !$arg->type->real; # native complex
#use Carp; use Test::More; diag "vAD_r ($arg)($is_native) ", $arg->info;

  # real FFT. Forward transform takes in real and spits out complex;
  # backward transform does the reverse
  if ( !$is_native && $arg->dim(0) != 2 ) {
    my ($verb, $var);
    if ( !$is_native_output && !$do_inverse_fft && $iarg == 1 ) {
      ($verb, $var) = qw(produces output);
    } elsif ( $do_inverse_fft && $iarg == 0 ) {
      ($verb, $var) = qw(takes input);
    }
    barf <<EOF if $verb;
$thisfunction $verb complex $var, so \$$var->dim(0) == 2 should be true,
but it's not (in @{[$arg->info]}: $arg). This is the (real,imag) dimension. Giving up.
EOF
  }

  my ($min_dimensionality, $var) = $rank;
  if( $iarg == 0 ) {
    # The input needs at least $rank dimensions. If this is a backward
    # transform, the input is complex, so it needs an extra dimension
    $min_dimensionality++ if $do_inverse_fft && !$is_native;
    $var = 'input';
  } else {
    # The output needs at least $rank dimensions. If this is a forward
    # transform, the output is complex, so it needs an extra dimension
    $min_dimensionality++ if !$do_inverse_fft && !$is_native_output;
    $var = 'output';
  }
  if ( $arg->ndims < $min_dimensionality ) {
    barf <<EOF;
$thisfunction: The $var needs at least $min_dimensionality dimensions, but
it has fewer. Giving up.
EOF
  }
}

sub matchDimensions_complex {
  my ($thisfunction, $rank, $in, $out) = @_;
  for my $idim (0..$rank) {
    if ( $in->dim($idim) != $out->dim($idim) ) {
      barf <<EOF;
$thisfunction was given input/output matrices of non-matching sizes.
Giving up.
EOF
    }
  }
}

sub matchDimensions_real {
  my ($thisfunction, $rank, $do_inverse_fft, $is_native_output, $in, $out) = @_;
  my ($varname1, $varname2, $var1, $var2);
  if ( !$do_inverse_fft ) {
    # Forward FFT. The input is real, the output is complex. $output->dim(0)
    # == 2, since that's the (real, imag) dimension. Furthermore,
    # $output->dim(1) should be int($input->dim(0)/2) + 1 (Section 2.4 of
    # the FFTW3 documentation)
    ($varname1, $varname2, $var1, $var2) = (qw(input output), $in, $out);
  } else {
    # Backward FFT. The input is complex, the output is real.
    ($varname1, $varname2, $var1, $var2) = (qw(output input), $out, $in);
  }
  my $is_native = !$var2->type->real || $is_native_output; # native complex
  barf <<EOF if int($var1->dim(0)/2) + 1 != $var2->dim($is_native ? 0 : 1);
$thisfunction: mismatched first dimension:
\$$varname2->dim(1) == int(\$$varname1->dim(0)/2) + 1 wasn't true.
$varname1: @{[$var1->info]}
$varname2: @{[$var2->info]}
Giving up.
EOF
  for my $idim (1..$rank-1) {
    if ( $var1->dim($idim) != $var2->dim($idim + ($is_native ? 0 : 1)) ) {
      barf <<EOF;
$thisfunction was given input/output matrices of non-matching sizes.
Giving up.
EOF
    }
  }
}

sub processTypes
{
  my ($thisfunction, $is_native_output, $in, $out) = @_;

  # types:
  #
  # Input and output types must match, and I can only really deal with float and
  # double. If given an output, I refuse to tweak the type of the output,
  # otherwise, I upgrade to float and then to double
  if( $$out->isnull ) {
    if( $$in->type < float ) {
      forceType( $in, (float) );
    }
  } else {
    # I'm given an output. Make sure this is of a type I can work with,
    # otherwise give up
    my $out_type = $$out->type;
    barf <<EOF if $out_type < float;
$thisfunction can only generate 'float' or 'double' output. You gave an output
of type '$out_type'. I can't change this so I give up
EOF
    my $in_type = $$in->type;
    my $in_precision = getPrecision($in_type);
    my $out_precision = getPrecision($out_type);
    return if $in_precision == $out_precision;
    forceType( $in, typeWithComplexity($out_precision, !$in_type->real) );
    forceType( $out, typeWithComplexity($out_precision, !$out_type->real) );
  }
}

sub typeWithComplexity {
  my ($precision, $complex) = @_;
  $complex ? ($precision == 1 ? cfloat : cdouble) :
    $precision == 1 ? float : double;
}

sub getPrecision {
  my ($type) = @_;
  ($type <= float || $type == cfloat) ? 1 : # float
  2; # double
}

sub forceType
{
  my ($x, $type) = @_;
  $$x = convert( $$x, $type ) unless $$x->type == $type;
}

sub getPlan
{
  my ($thisfunction, $rank, $is_real_fft, $do_inverse_fft, $in, $out) = @_;

  # I get the plan ID, check if I already have a plan, and make a new plan if I
  # don't already have one

  my @dims; # the dimensionality of the FFT
  if( !$is_real_fft )
  {
    # complex FFT
    @dims = $in->dims;
    shift @dims if $in->type->real; # ignore first dimension which is (real, imag)
  }
  elsif( !$do_inverse_fft )
  {
    # forward real FFT - the input IS the dimensionality
    @dims = $in->dims;
  }
  else
  {
    # backward real FFT
    # we're given an output, and this is the dimensionality
    @dims = $out->dims;
  }

  my $Nslices = reduce {$a*$b} splice(@dims, $rank);
  $Nslices = 1 unless defined $Nslices;

  my $do_double_precision = ($in->get_datatype == $PDL_F || $in->get_datatype == $PDL_CF)
    ? 0 : 1;
  $_last_do_double_precision = $do_double_precision;

  my $do_inplace = is_same_data( $in, $out );

  # I compute a single plan for the whole set of thread slices. I make a
  # worst-case plan, so I find the worst-aligned thread slice and plan off of
  # it. So if $Nslices>1 then the worst-case alignment is the worse of (1st,
  # 2nd) slices
  my $in_alignment  = get_data_alignment_pdl( $in );
  my $out_alignment = get_data_alignment_pdl( $out );
  my $stride_bytes  = ($do_double_precision ? 8 : 4) * reduce {$a*$b} @dims;
  if( $Nslices > 1 )
  {
    my $in_alignment_2nd  = get_data_alignment_int($in_alignment  + $stride_bytes);
    my $out_alignment_2nd = get_data_alignment_int($out_alignment + $stride_bytes);
    $in_alignment         = $in_alignment_2nd  if $in_alignment_2nd  < $in_alignment;
    $out_alignment        = $out_alignment_2nd if $out_alignment_2nd < $out_alignment;
  }

  my $planID = join('_',
                    $thisfunction,
                    $do_double_precision,
                    $do_inplace,
                    $in_alignment,
                    $out_alignment,
                    @dims);
  if ( !exists $existingPlans{$planID} )
  {
    $existingPlans{$planID} = compute_plan( \@dims, $do_double_precision, $is_real_fft, $do_inverse_fft,
                                            $in, $out, $in_alignment, $out_alignment );
    $_Nplans++;
  }

  return $existingPlans{$planID};
}


;


#line 61 "FFTW3.pd"
sub fft1 { __fft_internal( "fft1",@_ ); }
*PDL::fft1 = \&fft1;

sub ifft1 {
  my $a = __fft_internal( "ifft1", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:1')->prodover : $a->shape->slice('0:0')->prodover;
  $a;
}
*PDL::ifft1 = \&ifft1;

sub rfft1 { __fft_internal( "rfft1", @_ ); }
*PDL::rfft1 = \&rfft1;

sub rNfft1 { __fft_internal( "rNfft1", @_ ); }
*PDL::rNfft1 = \&rNfft1;

sub irfft1 { my $a = __fft_internal( "irfft1", @_ ); $a /= $a->shape->slice('0:0')->prodover; $a; }
*PDL::irfft1 = \&irfft1;



#line 61 "FFTW3.pd"
sub fft2 { __fft_internal( "fft2",@_ ); }
*PDL::fft2 = \&fft2;

sub ifft2 {
  my $a = __fft_internal( "ifft2", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:2')->prodover : $a->shape->slice('0:1')->prodover;
  $a;
}
*PDL::ifft2 = \&ifft2;

sub rfft2 { __fft_internal( "rfft2", @_ ); }
*PDL::rfft2 = \&rfft2;

sub rNfft2 { __fft_internal( "rNfft2", @_ ); }
*PDL::rNfft2 = \&rNfft2;

sub irfft2 { my $a = __fft_internal( "irfft2", @_ ); $a /= $a->shape->slice('0:1')->prodover; $a; }
*PDL::irfft2 = \&irfft2;



#line 61 "FFTW3.pd"
sub fft3 { __fft_internal( "fft3",@_ ); }
*PDL::fft3 = \&fft3;

sub ifft3 {
  my $a = __fft_internal( "ifft3", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:3')->prodover : $a->shape->slice('0:2')->prodover;
  $a;
}
*PDL::ifft3 = \&ifft3;

sub rfft3 { __fft_internal( "rfft3", @_ ); }
*PDL::rfft3 = \&rfft3;

sub rNfft3 { __fft_internal( "rNfft3", @_ ); }
*PDL::rNfft3 = \&rNfft3;

sub irfft3 { my $a = __fft_internal( "irfft3", @_ ); $a /= $a->shape->slice('0:2')->prodover; $a; }
*PDL::irfft3 = \&irfft3;



#line 61 "FFTW3.pd"
sub fft4 { __fft_internal( "fft4",@_ ); }
*PDL::fft4 = \&fft4;

sub ifft4 {
  my $a = __fft_internal( "ifft4", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:4')->prodover : $a->shape->slice('0:3')->prodover;
  $a;
}
*PDL::ifft4 = \&ifft4;

sub rfft4 { __fft_internal( "rfft4", @_ ); }
*PDL::rfft4 = \&rfft4;

sub rNfft4 { __fft_internal( "rNfft4", @_ ); }
*PDL::rNfft4 = \&rNfft4;

sub irfft4 { my $a = __fft_internal( "irfft4", @_ ); $a /= $a->shape->slice('0:3')->prodover; $a; }
*PDL::irfft4 = \&irfft4;



#line 61 "FFTW3.pd"
sub fft5 { __fft_internal( "fft5",@_ ); }
*PDL::fft5 = \&fft5;

sub ifft5 {
  my $a = __fft_internal( "ifft5", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:5')->prodover : $a->shape->slice('0:4')->prodover;
  $a;
}
*PDL::ifft5 = \&ifft5;

sub rfft5 { __fft_internal( "rfft5", @_ ); }
*PDL::rfft5 = \&rfft5;

sub rNfft5 { __fft_internal( "rNfft5", @_ ); }
*PDL::rNfft5 = \&rNfft5;

sub irfft5 { my $a = __fft_internal( "irfft5", @_ ); $a /= $a->shape->slice('0:4')->prodover; $a; }
*PDL::irfft5 = \&irfft5;



#line 61 "FFTW3.pd"
sub fft6 { __fft_internal( "fft6",@_ ); }
*PDL::fft6 = \&fft6;

sub ifft6 {
  my $a = __fft_internal( "ifft6", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:6')->prodover : $a->shape->slice('0:5')->prodover;
  $a;
}
*PDL::ifft6 = \&ifft6;

sub rfft6 { __fft_internal( "rfft6", @_ ); }
*PDL::rfft6 = \&rfft6;

sub rNfft6 { __fft_internal( "rNfft6", @_ ); }
*PDL::rNfft6 = \&rNfft6;

sub irfft6 { my $a = __fft_internal( "irfft6", @_ ); $a /= $a->shape->slice('0:5')->prodover; $a; }
*PDL::irfft6 = \&irfft6;



#line 61 "FFTW3.pd"
sub fft7 { __fft_internal( "fft7",@_ ); }
*PDL::fft7 = \&fft7;

sub ifft7 {
  my $a = __fft_internal( "ifft7", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:7')->prodover : $a->shape->slice('0:6')->prodover;
  $a;
}
*PDL::ifft7 = \&ifft7;

sub rfft7 { __fft_internal( "rfft7", @_ ); }
*PDL::rfft7 = \&rfft7;

sub rNfft7 { __fft_internal( "rNfft7", @_ ); }
*PDL::rNfft7 = \&rNfft7;

sub irfft7 { my $a = __fft_internal( "irfft7", @_ ); $a /= $a->shape->slice('0:6')->prodover; $a; }
*PDL::irfft7 = \&irfft7;



#line 61 "FFTW3.pd"
sub fft8 { __fft_internal( "fft8",@_ ); }
*PDL::fft8 = \&fft8;

sub ifft8 {
  my $a = __fft_internal( "ifft8", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:8')->prodover : $a->shape->slice('0:7')->prodover;
  $a;
}
*PDL::ifft8 = \&ifft8;

sub rfft8 { __fft_internal( "rfft8", @_ ); }
*PDL::rfft8 = \&rfft8;

sub rNfft8 { __fft_internal( "rNfft8", @_ ); }
*PDL::rNfft8 = \&rNfft8;

sub irfft8 { my $a = __fft_internal( "irfft8", @_ ); $a /= $a->shape->slice('0:7')->prodover; $a; }
*PDL::irfft8 = \&irfft8;



#line 61 "FFTW3.pd"
sub fft9 { __fft_internal( "fft9",@_ ); }
*PDL::fft9 = \&fft9;

sub ifft9 {
  my $a = __fft_internal( "ifft9", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:9')->prodover : $a->shape->slice('0:8')->prodover;
  $a;
}
*PDL::ifft9 = \&ifft9;

sub rfft9 { __fft_internal( "rfft9", @_ ); }
*PDL::rfft9 = \&rfft9;

sub rNfft9 { __fft_internal( "rNfft9", @_ ); }
*PDL::rNfft9 = \&rNfft9;

sub irfft9 { my $a = __fft_internal( "irfft9", @_ ); $a /= $a->shape->slice('0:8')->prodover; $a; }
*PDL::irfft9 = \&irfft9;



#line 61 "FFTW3.pd"
sub fft10 { __fft_internal( "fft10",@_ ); }
*PDL::fft10 = \&fft10;

sub ifft10 {
  my $a = __fft_internal( "ifft10", @_ );
  $a /= $_[0]->type->real ? $a->shape->slice('1:10')->prodover : $a->shape->slice('0:9')->prodover;
  $a;
}
*PDL::ifft10 = \&ifft10;

sub rfft10 { __fft_internal( "rfft10", @_ ); }
*PDL::rfft10 = \&rfft10;

sub rNfft10 { __fft_internal( "rNfft10", @_ ); }
*PDL::rNfft10 = \&rNfft10;

sub irfft10 { my $a = __fft_internal( "irfft10", @_ ); $a /= $a->shape->slice('0:9')->prodover; $a; }
*PDL::irfft10 = \&irfft10;



#line 89 "FFTW3.pd"
sub _rank_springboard {
  my ($name, $source, $rank, @rest) = @_;
  my $inverse = ($name =~ m/^i/);
  my $real    = ($name =~ m/r/) || !$source->type->real;

  unless(defined $rank) {
    die "${name}n: second argument must be the rank of the transform you want";
  }
  $rank = 0+$rank;  # force numeric context
  unless($rank>=1 ) {
    die "${name}n: second argument (rank) must be between 1 and 10";
  }

  my $active_lo = ($real ? 0 : 1);
  my $active_hi = ($real ? $rank-1 : $rank);

  unless($source->ndims > $active_hi) {
    die "${name}n: rank is $rank but input has only ".($active_hi-$active_lo)." active dims!";
  }

  my $out = __fft_internal( $name.$rank, $source, @rest );

  if($inverse) {
    $out /= $out->shape->slice("$active_lo:$active_hi")->prodover;
  }
  return $out;
}

sub fftn    { _rank_springboard( "fft",      @_ ) }
sub ifftn   { _rank_springboard( "ifft",     @_ ) }
sub rfftn   { _rank_springboard( "rfft",  @_ ) }
sub irfftn  { _rank_springboard( "irfft", @_ ) }

*PDL::fftn   = \&fftn;
*PDL::ifftn  = \&ifftn;
*PDL::rfftn  = \&rfftn;
*PDL::irfftn = \&irfftn;




# Exit with OK status

1;

		   