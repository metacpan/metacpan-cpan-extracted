
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Slatec;

@EXPORT_OK  = qw(  eigsys matinv polyfit polycoef polyvalue PDL::PP svdc PDL::PP poco PDL::PP geco PDL::PP gefa PDL::PP podi PDL::PP gedi PDL::PP gesl PDL::PP rs PDL::PP ezffti PDL::PP ezfftf PDL::PP ezfftb PDL::PP pcoef PDL::PP pvalue PDL::PP chim PDL::PP chic PDL::PP chsp PDL::PP chfd PDL::PP chfe PDL::PP chia PDL::PP chid PDL::PP chcm PDL::PP chbs PDL::PP polfit );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Slatec ;





=head1 NAME

PDL::Slatec - PDL interface to the slatec numerical programming library

=head1 SYNOPSIS

 use PDL::Slatec;

 ($ndeg, $r, $ierr, $a) = polyfit($x, $y, $w, $maxdeg, $eps);

=head1 DESCRIPTION

This module serves the dual purpose of providing an interface to
parts of the slatec library and showing how to interface PDL
to an external library.
Using this library requires a fortran compiler; the source for the routines
is provided for convenience.

Currently available are routines to:
manipulate matrices; calculate FFT's; 
fit data using polynomials; 
and interpolate/integrate data using piecewise cubic Hermite interpolation.

=head2 Piecewise cubic Hermite interpolation (PCHIP)

PCHIP is the slatec package of routines to perform piecewise cubic
Hermite interpolation of data.
It features software to produce a monotone and "visually pleasing"
interpolant to monotone data.  
According to Fritsch & Carlson ("Monotone piecewise
cubic interpolation", SIAM Journal on Numerical Analysis 
17, 2 (April 1980), pp. 238-246),
such an interpolant may be more reasonable than a cubic spline if
the data contains both "steep" and "flat" sections.  
Interpolation of cumulative probability distribution functions is 
another application.
These routines are cryptically named (blame FORTRAN), 
beginning with 'ch', and accept either float or double piddles. 

Most of the routines require an integer parameter called C<check>;
if set to 0, then no checks on the validity of the input data are
made, otherwise these checks are made.
The value of C<check> can be set to 0 if a routine
such as L<chim|/chim> has already been successfully called.

=over 4

=item * 

If not known, estimate derivative values for the points
using the L<chim|/chim>, L<chic|/chic>, or L<chsp|/chsp> routines
(the following routines require both the function (C<f>)
and derivative (C<d>) values at a set of points (C<x>)). 

=item * 

Evaluate, integrate, or differentiate the resulting PCH
function using the routines:
L<chfd|/chfd>; L<chfe|/chfe>; L<chia|/chia>; L<chid|/chid>.

=item * 

If desired, you can check the monotonicity of your
data using L<chcm|/chcm>. 

=back
 
=cut







=head1 FUNCTIONS



=cut




=head2 eigsys

=for ref

Eigenvalues and eigenvectors of a real positive definite symmetric matrix.

=for usage

 ($eigvals,$eigvecs) = eigsys($mat)

Note: this function should be extended to calculate only eigenvalues if called 
in scalar context!

=head2 matinv

=for ref

Inverse of a square matrix

=for usage

 ($inv) = matinv($mat)

=head2 polyfit

Convenience wrapper routine about the C<polfit> C<slatec> function.
Separates supplied arguments and return values.

=for ref

Fit discrete data in a least squares sense by polynomials
in one variable.  Handles threading correctly--one can pass in a 2D PDL (as C<$y>)
and it will pass back a 2D PDL, the rows of which are the polynomial regression
results (in C<$r> corresponding to the rows of $y.

=for usage

 ($ndeg, $r, $ierr, $a, $coeffs, $rms) = polyfit($x, $y, $w, $maxdeg, [$eps]);

 $coeffs = polyfit($x,$y,$w,$maxdeg,[$eps]);

where on input:

C<$x> and C<$y> are the values to fit to a polynomial.
C<$w> are weighting factors
C<$maxdeg> is the maximum degree of polynomial to use and 
C<$eps> is the required degree of fit.

and the output switches on list/scalar context.  

In list context: 

C<$ndeg> is the degree of polynomial actually used
C<$r> is the values of the fitted polynomial 
C<$ierr> is a return status code, and
C<$a> is some working array or other (preserved for historical purposes)
C<$coeffs> is the polynomial coefficients of the best fit polynomial.
C<$rms> is the rms error of the fit.

In scalar context, only $coeffs is returned.

Historically, C<$eps> was modified in-place to be a return value of the
rms error.  This usage is deprecated, and C<$eps> is an optional parameter now.
It is still modified if present.
 
C<$a> is a working array accessible to Slatec - you can feed it to several
other Slatec routines to get nice things out.  It does not thread 
correctly and should probably be fixed by someone.  If you are 
reading this, that someone might be you.

=for bad

This version of polyfit handles bad values correctly.  Bad values in
$y are ignored for the fit and give computed values on the fitted
curve in the return.  Bad values in $x or $w are ignored for the fit and
result in bad elements in the output.

=head2 polycoef

Convenience wrapper routine around the C<pcoef> C<slatec> function.
Separates supplied arguments and return values.                               

=for ref

Convert the C<polyfit>/C<polfit> coefficients to Taylor series form.

=for usage

 $tc = polycoef($l, $c, $a);

=head2 polyvalue

Convenience wrapper routine around the C<pvalue> C<slatec> function.
Separates supplied arguments and return values.

For multiple input x positions, a corresponding y position is calculated.

The derivatives PDL is one dimensional (of size C<nder>) if a single x
position is supplied, two dimensional if more than one x position is
supplied.                                                                     

=for ref

Use the coefficients generated by C<polyfit> (or C<polfit>) to evaluate
the polynomial fit of degree C<l>, along with the first C<nder> of its
derivatives, at a specified point.

=for usage

 ($yfit, $yp) = polyvalue($l, $nder, $x, $a);

=head2 detslatec

=for ref

compute the determinant of an invertible matrix

=for example

  $mat = zeroes(5,5); $mat->diagonal(0,1) .= 1; # unity matrix
  $det = detslatec $mat;

Usage:

=for usage

  $determinant = detslatec $matrix;

=for sig

  Signature: detslatec(mat(n,m); [o] det())

C<detslatec> computes the determinant of an invertible matrix and barfs if
the matrix argument provided is non-invertible. The matrix threads as usual.

This routine was previously known as C<det> which clashes now with
L<det|PDL::MatrixOps/det> which is provided by L<PDL::MatrixOps>.

=head2 fft

=for ref

Fast Fourier Transform

=for example

  $v_in = pdl(1,0,1,0);
  ($azero,$a,$b) = PDL::Slatec::fft($v_in);

C<PDL::Slatec::fft> is a convenience wrapper for L<ezfftf|ezfftf>, and
performs a Fast Fourier Transform on an input vector C<$v_in>. The
return values are the same as for L<ezfftf|ezfftf>.

=head2 rfft

=for ref

reverse Fast Fourier Transform

=for example

  $v_out = PDL::Slatec::rfft($azero,$a,$b);
  print $v_in, $vout
  [1 0 1 0] [1 0 1 0]

C<PDL::Slatec::rfft> is a convenience wrapper for L<ezfftb|ezfftb>,
and performs a reverse Fast Fourier Transform. The input is the same
as the output of L<PDL::Slatec::fft|/PDL::Slatec::fft>, and the output
of C<rfft> is a data vector, similar to what is input into
L<PDL::Slatec::fft|/PDL::Slatec::fft>.

=cut




use PDL::Core;
use PDL::Basic;
use PDL::Primitive;
use PDL::Ufunc;
use strict;

# Note: handles only real symmetric positive-definite.

*eigsys = \&PDL::eigsys;

sub PDL::eigsys {
	my($h) = @_;
	$h = float($h);
	rs($h, 
		(my $eigval=PDL->null),
		(long (pdl (1))),(my $eigmat=PDL->null),
		(my $fvone = PDL->null),(my $fvtwo = PDL->null),
		(my $errflag=PDL->null)
	);
#	print $covar,$eigval,$eigmat,$fvone,$fvtwo,$errflag;
	if(sum($errflag) > 0) {
		barf("Non-positive-definite matrix given to eigsys: $h\n");
	}
	return ($eigval,$eigmat);
}

*matinv = \&PDL::matinv;

sub PDL::matinv {
	my($m) = @_;
	my(@dims) = $m->dims;

	# Keep from dumping core (FORTRAN does no error checking)
	barf("matinv requires a 2-D square matrix")
		unless( @dims >= 2 && $dims[0] == $dims[1] );
  
	$m = $m->copy(); # Make sure we don't overwrite :(
	gefa($m,(my $ipvt=null),(my $info=null));
	if(sum($info) > 0) {
		barf("Uninvertible matrix given to inv: $m\n");
	}
	gedi($m,$ipvt,(pdl 0,0),(null),(long( pdl (1))));
	$m;
}

*detslatec = \&PDL::detslatec;
sub PDL::detslatec {
	my($m) = @_;
	$m = $m->copy(); # Make sure we don't overwrite :(
	gefa($m,(my $ipvt=null),(my $info=null));
	if(sum($info) > 0) {
		barf("Uninvertible matrix given to inv: $m\n");
	}
	gedi($m,$ipvt,(my $det=null),(null),(long( pdl (10))));
	return $det->slice('(0)')*10**$det->slice('(1)');
}


sub prepfft {
	my($n) = @_;
	my $tmp = PDL->zeroes(float(),$n*3+15);
	$n = pdl $n;
	ezffti($n,$tmp);
	return $tmp;
}

sub fft (;@) {
	my($v) = @_;
	my $ws = prepfft($v->getdim(0));
	ezfftf($v,(my $az = PDL->null), (my $a = PDL->null),
		  (my $b = PDL->null), $ws);
	return ($az,$a,$b);
}

sub rfft {
	my($az,$a,$b) = @_;
	my $ws = prepfft($a->getdim(0));
	my $v = $a->copy();
	ezfftb($v,$az,$a,$b,$ws);
	return $v;
}

# polynomial fitting routines
# simple wrappers around the SLATEC implementations

*polyfit = \&PDL::polyfit;
sub PDL::polyfit {
  barf 'Usage: polyfit($x, $y, $w, $maxdeg, [$eps]);'
    unless (@_ == 5 || @_==4 );

  my ($x_in, $y_in, $w_in, $maxdeg_in, $eps_in) = @_;

  # if $w_in does not match the data vectors ($x_in, $y_in), then we can resize
  # it to match the size of $y_in :
  $w_in = $w_in + $y_in->zeros;

  # Create the output arrays
  my $r = PDL->null;

  # A array needs some work space
  my $sz = ((3 * $x_in->getdim(0)) + (3*$maxdeg_in) + 3); # Buffer size called for by Slatec
  my @otherdims = $_[0]->dims; shift @otherdims;          # Thread dims
  my $a =      PDL::new_from_specification('PDL',$x_in->type,$sz,@otherdims);
  my $coeffs = PDL::new_from_specification('PDL',$x_in->type, $maxdeg_in + 1, @otherdims);

  my $ierr = PDL->null;
  my $ndeg = PDL->null;

  # Now call polfit
  my $rms = pdl($eps_in);                                       
  polfit($x_in, $y_in, $w_in, $maxdeg_in, $ndeg, $rms, $r, $ierr, $a, $coeffs);
  # Preserve historic compatibility by flowing rms error back into the argument
  if( UNIVERSAL::isa($eps_in,'PDL') ){
      $eps_in .= $rms;
  }

  # Return the arrays
  if(wantarray) {
    return ($ndeg, $r, $ierr, $a, $coeffs, $rms );
  } else {
      return $coeffs;
  }
}


*polycoef = \&PDL::polycoef;
sub PDL::polycoef {
  barf 'Usage: polycoef($l, $c, $a);'
    unless @_ == 3;

  # Allocate memory for return PDL
  # Simply l + 1 but cant see how to get PP to do this - TJ
  # Not sure the return type since I do not know
  # where PP will get the information from
  my $tc = PDL->zeroes( abs($_[0]) + 1 );                                     

  # Run the slatec routine
  pcoef($_[0], $_[1], $tc, $_[2]);

  # Return results
  return $tc;

}

*polyvalue = \&PDL::polyvalue;
sub PDL::polyvalue {
  barf 'Usage: polyvalue($l, $nder, $x, $a);'
    unless @_ == 4;

  # Two output arrays
  my $yfit = PDL->null;

  # This one must be preallocated and must take into account
  # the size of $x if greater than 1
  my $yp;
  if ($_[2]->getdim(0) == 1) {
    $yp = $_[2]->zeroes($_[1]);
  } else {
    $yp = $_[2]->zeroes($_[1], $_[2]->getdim(0));
  }

  # Run the slatec function
  pvalue($_[0], $_[2], $yfit, $yp, $_[3]);

  # Returns
  return ($yfit, $yp);

}
                                                                              




=head2 svdc

=for sig

  Signature: (x(n,p);[o]s(p);[o]e(p);[o]u(n,p);[o]v(p,p);[o]work(n);int job();int [o]info())

=for ref

singular value decomposition of a matrix

=for bad

svdc does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*svdc = \&PDL::svdc;





=head2 poco

=for sig

  Signature: (a(n,n);rcond();[o]z(n);int [o]info())

Factor a real symmetric positive definite matrix
and estimate the condition number of the matrix.

=for bad

poco does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*poco = \&PDL::poco;





=head2 geco

=for sig

  Signature: (a(n,n);int [o]ipvt(n);[o]rcond();[o]z(n))

Factor a matrix using Gaussian elimination and estimate
the condition number of the matrix.

=for bad

geco does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*geco = \&PDL::geco;





=head2 gefa

=for sig

  Signature: (a(n,n);int [o]ipvt(n);int [o]info())

=for ref

Factor a matrix using Gaussian elimination.

=for bad

gefa does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gefa = \&PDL::gefa;





=head2 podi

=for sig

  Signature: (a(n,n);[o]det(two=2);int job())

Compute the determinant and inverse of a certain real
symmetric positive definite matrix using the factors
computed by L<poco|/poco>.

=for bad

podi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*podi = \&PDL::podi;





=head2 gedi

=for sig

  Signature: (a(n,n);int [o]ipvt(n);[o]det(two=2);[o]work(n);int job())

Compute the determinant and inverse of a matrix using the
factors computed by L<geco|/geco> or L<gefa|/gefa>.

=for bad

gedi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gedi = \&PDL::gedi;





=head2 gesl

=for sig

  Signature: (a(lda,n);int ipvt(n);b(n);int job())

Solve the real system C<A*X=B> or C<TRANS(A)*X=B> using the
factors computed by L<geco|/geco> or L<gefa|/gefa>.

=for bad

gesl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gesl = \&PDL::gesl;





=head2 rs

=for sig

  Signature: (a(n,n);[o]w(n);int matz();[o]z(n,n);[t]fvone(n);[t]fvtwo(n);int [o]ierr())

This subroutine calls the recommended sequence of
subroutines from the eigensystem subroutine package (EISPACK)
to find the eigenvalues and eigenvectors (if desired)
of a REAL SYMMETRIC matrix.

=for bad

rs does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*rs = \&PDL::rs;





=head2 ezffti

=for sig

  Signature: (int n();[o]wsave(foo))

Subroutine ezffti initializes the work array C<wsave()>
which is used in both L<ezfftf|/ezfftf> and 
L<ezfftb|/ezfftb>.  
The prime factorization
of C<n> together with a tabulation of the trigonometric functions
are computed and stored in C<wsave()>.

=for bad

ezffti does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ezffti = \&PDL::ezffti;





=head2 ezfftf

=for sig

  Signature: (r(n);[o]azero();[o]a(n);[o]b(n);wsave(foo))

=for ref



=for bad

ezfftf does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ezfftf = \&PDL::ezfftf;





=head2 ezfftb

=for sig

  Signature: ([o]r(n);azero();a(n);b(n);wsave(foo))

=for ref



=for bad

ezfftb does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ezfftb = \&PDL::ezfftb;





=head2 pcoef

=for sig

  Signature: (int l();c();[o]tc(bar);a(foo))

Convert the C<polfit> coefficients to Taylor series form.
C<c> and C<a()> must be of the same type.

=for bad

pcoef does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pcoef = \&PDL::pcoef;





=head2 pvalue

=for sig

  Signature: (int l();x();[o]yfit();[o]yp(nder);a(foo))

Use the coefficients generated by C<polfit> to evaluate the
polynomial fit of degree C<l>, along with the first C<nder> of
its derivatives, at a specified point. C<x> and C<a> must be of the
same type.

=for bad

pvalue does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*pvalue = \&PDL::pvalue;





=head2 chim

=for sig

  Signature: (x(n);f(n);[o]d(n);int [o]ierr())


=for ref

Calculate the derivatives of (x,f(x)) using cubic Hermite interpolation.

Calculate the derivatives at the given set of points (C<$x,$f>,
where C<$x> is strictly increasing).
The resulting set of points - C<$x,$f,$d>, referred to
as the cubic Hermite representation - can then be used in
other functions, such as L<chfe|/chfe>, L<chfd|/chfd>,
and L<chia|/chia>.

The boundary conditions are compatible with monotonicity,
and if the data are only piecewise monotonic, the interpolant
will have an extremum at the switch points; for more control
over these issues use L<chic|/chic>. 

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

E<gt> 0 if there were C<ierr> switches in the direction of 
monotonicity (data still valid).

=item *

-1 if C<nelem($x) E<lt> 2>.

=item *

-3 if C<$x> is not strictly increasing.

=back



=for bad

chim does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chim = \&PDL::chim;





=head2 chic

=for sig

  Signature: (int ic(two=2);vc(two=2);mflag();x(n);f(n);[o]d(n);wk(nwk);int [o]ierr())


=for ref

Calculate the derivatives of (x,f(x)) using cubic Hermite interpolation.

Calculate the derivatives at the given points (C<$x,$f>,
where C<$x> is strictly increasing).
Control over the boundary conditions is given by the 
C<$ic> and C<$vc> piddles, and the value of C<$mflag> determines
the treatment of points where monotoncity switches
direction. A simpler, more restricted, interface is available 
using L<chim|/chim>.

The first and second elements of C<$ic> determine the boundary
conditions at the start and end of the data respectively.
If the value is 0, then the default condition, as used by
L<chim|/chim>, is adopted.
If greater than zero, no adjustment for monotonicity is made,
otherwise if less than zero the derivative will be adjusted.
The allowed magnitudes for C<ic(0)> are:

=over 4

=item *  

1 if first derivative at C<x(0)> is given in C<vc(0)>.

=item *

2 if second derivative at C<x(0)> is given in C<vc(0)>.

=item *

3 to use the 3-point difference formula for C<d(0)>.
(Reverts to the default b.c. if C<n E<lt> 3>)

=item *

4 to use the 4-point difference formula for C<d(0)>.
(Reverts to the default b.c. if C<n E<lt> 4>)

=item *

5 to set C<d(0)> so that the second derivative is 
continuous at C<x(1)>.
(Reverts to the default b.c. if C<n E<lt> 4>) 

=back

The values for C<ic(1)> are the same as above, except that
the first-derivative value is stored in C<vc(1)> for cases 1 and 2.
The values of C<$vc> need only be set if options 1 or 2 are chosen
for C<$ic>.

Set C<$mflag = 0> if interpolant is required to be monotonic in
each interval, regardless of the data. This causes C<$d> to be
set to 0 at all switch points. Set C<$mflag> to be non-zero to
use a formula based on the 3-point difference formula at switch
points. If C<$mflag E<gt> 0>, then the interpolant at swich points
is forced to not deviate from the data by more than C<$mflag*dfloc>, 
where C<dfloc> is the maximum of the change of C<$f> on this interval
and its two immediate neighbours.
If C<$mflag E<lt> 0>, no such control is to be imposed.            

The piddle C<$wk> is only needed for work space. However, I could
not get it to work as a temporary variable, so you must supply
it; it is a 1D piddle with C<2*n> elements.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

1 if C<ic(0) E<lt> 0> and C<d(0)> had to be adjusted for
monotonicity.

=item *

2 if C<ic(1) E<lt> 0> and C<d(n-1)> had to be adjusted
for monotonicity.

=item * 

3 if both 1 and 2 are true.

=item *

-1 if C<n E<lt> 2>.

=item *

-3 if C<$x> is not strictly increasing.

=item *

-4 if C<abs(ic(0)) E<gt> 5>.

=item *

-5 if C<abs(ic(1)) E<gt> 5>.

=item *

-6 if both -4 and -5  are true.

=item *

-7 if C<nwk E<lt> 2*(n-1)>.

=back



=for bad

chic does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chic = \&PDL::chic;





=head2 chsp

=for sig

  Signature: (int ic(two=2);vc(two=2);x(n);f(n);[o]d(n);wk(nwk);int [o]ierr())


=for ref

Calculate the derivatives of (x,f(x)) using cubic spline interpolation.

Calculate the derivatives, using cubic spline interpolation,
at the given points (C<$x,$f>), with the specified
boundary conditions. 
Control over the boundary conditions is given by the 
C<$ic> and C<$vc> piddles.
The resulting values - C<$x,$f,$d> - can
be used in all the functions which expect a cubic
Hermite function.

The first and second elements of C<$ic> determine the boundary
conditions at the start and end of the data respectively.
The allowed values for C<ic(0)> are:

=over 4

=item *

0 to set C<d(0)> so that the third derivative is 
continuous at C<x(1)>.

=item *

1 if first derivative at C<x(0)> is given in C<vc(0>).

=item *

2 if second derivative at C<x(0>) is given in C<vc(0)>.

=item *

3 to use the 3-point difference formula for C<d(0)>.
(Reverts to the default b.c. if C<n E<lt> 3>.)

=item *

4 to use the 4-point difference formula for C<d(0)>.
(Reverts to the default b.c. if C<n E<lt> 4>.)                 

=back

The values for C<ic(1)> are the same as above, except that
the first-derivative value is stored in C<vc(1)> for cases 1 and 2.
The values of C<$vc> need only be set if options 1 or 2 are chosen
for C<$ic>.

The piddle C<$wk> is only needed for work space. However, I could
not get it to work as a temporary variable, so you must supply
it; it is a 1D piddle with C<2*n> elements.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

-1  if C<nelem($x) E<lt> 2>.

=item *

-3  if C<$x> is not strictly increasing.

=item *

-4  if C<ic(0) E<lt> 0> or C<ic(0) E<gt> 4>.

=item *

-5  if C<ic(1) E<lt> 0> or C<ic(1) E<gt> 4>.

=item *

-6  if both of the above are true.

=item *

-7  if C<nwk E<lt> 2*n>.

=item *

-8  in case of trouble solving the linear system
for the interior derivative values.

=back



=for bad

chsp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chsp = \&PDL::chsp;





=head2 chfd

=for sig

  Signature: (x(n);f(n);d(n);int check();xe(ne);[o]fe(ne);[o]de(ne);int [o]ierr())


=for ref

Interpolate function and derivative values.

Given a piecewise cubic Hermite function - such as from
L<chim|/chim> - evaluate the function (C<$fe>) and 
derivative (C<$de>) at a set of points (C<$xe>).
If function values alone are required, use L<chfe|/chfe>.
Set C<check> to 0 to skip checks on the input data.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

E<gt>0 if extrapolation was performed at C<ierr> points
(data still valid).

=item *

-1 if C<nelem($x) E<lt> 2>

=item *

-3 if C<$x> is not strictly increasing.

=item *

-4 if C<nelem($xe) E<lt> 1>.

=item *

-5 if an error has occurred in a lower-level routine,
which should never happen.

=back



=for bad

chfd does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chfd = \&PDL::chfd;





=head2 chfe

=for sig

  Signature: (x(n);f(n);d(n);int check();xe(ne);[o]fe(ne);int [o]ierr())


=for ref

Interpolate function values.

Given a piecewise cubic Hermite function - such as from
L<chim|/chim> - evaluate the function (C<$fe>) at
a set of points (C<$xe>).
If derivative values are also required, use L<chfd|/chfd>.
Set C<check> to 0 to skip checks on the input data.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

E<gt>0 if extrapolation was performed at C<ierr> points
(data still valid).

=item *

-1 if C<nelem($x) E<lt> 2>

=item *

-3 if C<$x> is not strictly increasing.

=item *

-4 if C<nelem($xe) E<lt> 1>.

=back



=for bad

chfe does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chfe = \&PDL::chfe;





=head2 chia

=for sig

  Signature: (x(n);f(n);d(n);int check();a();b();[o]ans();int [o]ierr())


=for ref

Integrate (x,f(x)) over arbitrary limits.

Evaluate the definite integral of a a piecewise
cubic Hermite function over an arbitrary interval,
given by C<[$a,$b]>.
See L<chid|/chid> if the integration limits are
data points.
Set C<check> to 0 to skip checks on the input data.

The values of C<$a> and C<$b> do not have
to lie within C<$x>, although the resulting integral
value will be highly suspect if they are not.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

1 if C<$a> lies outside C<$x>.

=item *

2 if C<$b> lies outside C<$x>.

=item *

3 if both 1 and 2 are true.

=item *

-1 if C<nelem($x) E<lt> 2>

=item *

-3 if C<$x> is not strictly increasing.

=item *

-4 if an error has occurred in a lower-level routine,
which should never happen.

=back



=for bad

chia does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chia = \&PDL::chia;





=head2 chid

=for sig

  Signature: (x(n);f(n);d(n);int check();int ia();int ib();[o]ans();int [o]ierr())


=for ref

Integrate (x,f(x)) between data points.

Evaluate the definite integral of a a piecewise
cubic Hermite function between C<x($ia)> and
C<x($ib)>. 

See L<chia|/chia> for integration between arbitrary
limits.

Although using a fortran routine, the values of
C<$ia> and C<$ib> are zero offset.
Set C<check> to 0 to skip checks on the input data.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

-1 if C<nelem($x) E<lt> 2>.

=item *

-3 if C<$x> is not strictly increasing.

=item *

-4 if C<$ia> or C<$ib> is out of range.

=back



=for bad

chid does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chid = \&PDL::chid;





=head2 chcm

=for sig

  Signature: (x(n);f(n);d(n);int check();int [o]ismon(n);int [o]ierr())


=for ref

Check the given piecewise cubic Hermite function for monotonicity.

The outout piddle C<$ismon> indicates over
which intervals the function is monotonic.
Set C<check> to 0 to skip checks on the input data.

For the data interval C<[x(i),x(i+1)]>, the
values of C<ismon(i)> can be:

=over 4

=item *

-3 if function is probably decreasing

=item *

-1 if function is strictly decreasing

=item *

0  if function is constant

=item *

1  if function is strictly increasing

=item *

2  if function is non-monotonic

=item *

3  if function is probably increasing

=back

If C<abs(ismon(i)) == 3>, the derivative values are
near the boundary of the monotonicity region. A small
increase produces non-monotonicity, whereas a decrease
produces strict monotonicity.

The above applies to C<i = 0 .. nelem($x)-1>. The last element of
C<$ismon> indicates whether
the entire function is monotonic over $x.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

-1 if C<n E<lt> 2>.

=item *

-3 if C<$x> is not strictly increasing.

=back



=for bad

chcm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chcm = \&PDL::chcm;





=head2 chbs

=for sig

  Signature: (x(n);f(n);d(n);int knotyp();int nknots();t(tsize);[o]bcoef(bsize);int [o]ndim();int [o]kord();int [o]ierr())


=for ref

Piecewise Cubic Hermite function to B-Spline converter.

The resulting B-spline representation of the data
(i.e. C<nknots>, C<t>, C<bcoeff>, C<ndim>, and
C<kord>) can be evaluated by C<bvalu> (which is 
currently not available).

Array sizes: C<tsize = 2*n + 4>, C<bsize = 2*n>,
and C<ndim = 2*n>.

C<knotyp> is a flag which controls the knot sequence.
The knot sequence C<t> is normally computed from C<$x> 
by putting a double knot at each C<x> and setting the end knot pairs
according to the value of C<knotyp> (where C<m = ndim = 2*n>):

=over

=item *

0 -   Quadruple knots at the first and last points.

=item *

1 -   Replicate lengths of extreme subintervals:
C<t( 0 ) = t( 1 ) = x(0) - (x(1)-x(0))> and
C<t(m+3) = t(m+2) = x(n-1) + (x(n-1)-x(n-2))>

=item *

2 -   Periodic placement of boundary knots:
C<t( 0 ) = t( 1 ) = x(0) - (x(n-1)-x(n-2))> and
C<t(m+3) = t(m+2) = x(n) + (x(1)-x(0))>

=item *

E<lt>0 - Assume the C<nknots> and C<t> were set in a previous call.

=back

C<nknots> is the number of knots and may be changed by the routine. 
If C<knotyp E<gt>= 0>, C<nknots> will be set to C<ndim+4>,
otherwise it is an input variable, and an error will occur if its
value is not equal to C<ndim+4>.

C<t> is the array of C<2*n+4> knots for the B-representation
and may be changed by the routine.
If C<knotyp E<gt>= 0>, C<t> will be changed so that the
interior double knots are equal to the x-values and the
boundary knots set as indicated above,
otherwise it is assumed that C<t> was set by a
previous call (no check is made to verify that the data
forms a legitimate knot sequence). 

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

-4 if C<knotyp E<gt> 2>.

=item *

-5 if C<knotyp E<lt> 0> and C<nknots != 2*n + 4>.

=back



=for bad

chbs does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*chbs = \&PDL::chbs;





=head2 polfit

=for sig

  Signature: (x(n); y(n); w(n); int maxdeg(); int [o]ndeg(); [o]eps(); [o]r(n); int [o]ierr(); [o]a(foo); [o]coeffs(bar);[t]xtmp(n);[t]ytmp(n);[t]wtmp(n);[t]rtmp(n))

Fit discrete data in a least squares sense by polynomials
          in one variable. C<x()>, C<y()> and C<w()> must be of the same type.
	  This version handles bad values appropriately

=for bad

polfit processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*polfit = \&PDL::polfit;




=head1 AUTHOR

Copyright (C) 1997 Tuomas J. Lukka. 
Copyright (C) 2000 Tim Jenness, Doug Burke.            
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.

=cut




;



# Exit with OK status

1;

		   