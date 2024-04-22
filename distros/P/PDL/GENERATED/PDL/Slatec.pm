#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Slatec;

our @EXPORT_OK = qw(eigsys matinv polyfit polycoef svdc poco geco gefa podi gedi gesl rs ezffti ezfftf ezfftb pcoef polyvalue chim chic chsp chfd chfe chia chid chcm chbs bvalu polfit );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Slatec ;







#line 5 "slatec.pd"

use strict;
use warnings;

=head1 NAME

PDL::Slatec - PDL interface to the slatec numerical programming library

=head1 SYNOPSIS

 use PDL::Slatec;

 ($ndeg, $r, $ierr, $c) = polyfit($x, $y, $w, $maxdeg, $eps);

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
beginning with 'ch', and accept either float or double ndarrays. 

Most of the routines require an integer parameter called C<skip>;
if set to 1, then no checks on the validity of the input data are
made, otherwise these checks are made.
The value of C<skip> can be set to 1 if a routine
such as L</chim> has already been successfully called.

=over 4

=item * 

If not known, estimate derivative values for the points
using the L</chim>, L</chic>, or L</chsp> routines
(the following routines require both the function (C<f>)
and derivative (C<d>) values at a set of points (C<x>)). 

=item * 

Evaluate, integrate, or differentiate the resulting PCH
function using the routines:
L</chfd>; L</chfe>; L</chia>; L</chid>.

=item * 

If desired, you can check the monotonicity of your
data using L</chcm>, or use L</chbs> to convert a PCH function into
B-representation for use with the B-spline routines of SLATEC.

=back
 
=cut
#line 100 "Slatec.pm"


=head1 FUNCTIONS

=cut





#line 85 "slatec.pd"

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
in one variable.  Handles broadcasting correctly--one can pass in a 2D PDL (as C<$y>)
and it will pass back a 2D PDL, the rows of which are the polynomial regression
results (in C<$r>) corresponding to the rows of $y.

=for usage

 ($ndeg, $r, $ierr, $c, $coeffs, $rms) = polyfit($x, $y, $w, $maxdeg, [$eps]);

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
C<$c> is some working array or other (preserved for historical purposes)
C<$coeffs> is the polynomial coefficients of the best fit polynomial.
C<$rms> is the rms error of the fit.

In scalar context, only $coeffs is returned.

Historically, C<$eps> was modified in-place to be a return value of the
rms error.  This usage is deprecated, and C<$eps> is an optional parameter now.
It is still modified if present.
 
C<$c> is a working array accessible to Slatec - you can feed it to several
other Slatec routines to get nice things out.  It does not broadcast
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

 $tc = polycoef($l, $c, $x);

=head2 detslatec

=for ref

compute the determinant of an invertible matrix

=for example

  $mat = identity(5); # unity matrix
  $det = detslatec $mat;

Usage:

=for usage

  $determinant = detslatec $matrix;

=for sig

  Signature: detslatec(mat(n,m); [o] det())

C<detslatec> computes the determinant of an invertible matrix and barfs if
the matrix argument provided is non-invertible. The matrix broadcasts as usual.

This routine was previously known as C<det> which clashes now with
L<det|PDL::MatrixOps/det> which is provided by L<PDL::MatrixOps>.

=head2 fft

=for ref

Fast Fourier Transform

=for example

  $v_in = pdl(1,0,1,0);
  ($azero,$x,$y) = PDL::Slatec::fft($v_in);

C<PDL::Slatec::fft> is a convenience wrapper for L</ezfftf>, and
performs a Fast Fourier Transform on an input vector C<$v_in>. The
return values are the same as for L</ezfftf>.

=head2 rfft

=for ref

reverse Fast Fourier Transform

=for example

  $v_out = PDL::Slatec::rfft($azero,$x,$y);
  print $v_in, $vout
  [1 0 1 0] [1 0 1 0]

C<PDL::Slatec::rfft> is a convenience wrapper for L</ezfftb>,
and performs a reverse Fast Fourier Transform. The input is the same
as the output of L</PDL::Slatec::fft>, and the output
of C<rfft> is a data vector, similar to what is input into
L</PDL::Slatec::fft>.

=cut

#line 409 "slatec.pd"
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
		my $eigval=PDL->null,
		1,my $eigmat=PDL->null,
		my $errflag=PDL->null
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
	my ($ipvt,$info) = gefa($m);
	if(sum($info) > 0) {
		barf("Uninvertible matrix given to inv: $m\n");
	}
	gedi($m,$ipvt,1);
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
	my ($det) = gedi($m,$ipvt,10);
	return $det->slice('(0)')*10**$det->slice('(1)');
}

sub prepfft {
	my($n) = @_;
	my $ifac = ezffti($n,my $wsave = PDL->zeroes(float(),$n*3));
	return ($wsave, $ifac);
}

sub fft (;@) {
	my ($v) = @_;
	ezfftf($v, prepfft($v->getdim(0)));
}

sub rfft {
	my ($az,$x,$y) = @_;
	ezfftb($az,$x,$y,prepfft($x->getdim(0)));
}

# polynomial fitting routines
# simple wrappers around the SLATEC implementations

*polyfit = \&PDL::polyfit;
sub PDL::polyfit {
  barf 'Usage: polyfit($x, $y, $w, $maxdeg, [$eps]);'
    unless (@_ == 5 || @_==4 );

  my ($x_in, $y_in, $w_in, $maxdeg_in, $eps_io) = map PDL->topdl($_), @_;

  my $template_ind = maximum_n_ind([(map $_->ndims-1, $x_in, $y_in, $w_in), $maxdeg_in->ndims, defined $eps_io ? $eps_io->ndims : -1], 1)->sclr;
  my $template = $_[$template_ind];
  # if $w_in does not match the data vectors ($x_in, $y_in), then we can resize
  # it to match the size of $y_in :
  $w_in = $w_in + $template->zeroes;
  $eps_io = $eps_io + $template->slice('(0)')->zeroes; # also needs to match but with one less dim
  my $max_maxdeg = $maxdeg_in->max->sclr;

  # Now call polfit
  my $rms = pdl($eps_io);
  my ($ndeg, $r, $ierr, $a1, $coeffs) = polfit($x_in, $y_in, $w_in, $maxdeg_in, $rms, $max_maxdeg+1);
  # Preserve historic compatibility by flowing rms error back into the argument
  $eps_io .= $rms if UNIVERSAL::isa($_[4],'PDL');

  # Return the arrays
  wantarray ? ($ndeg, $r, $ierr, $a1, $coeffs, $rms) : $coeffs;
}

*polycoef = \&PDL::polycoef;
sub PDL::polycoef {
  barf 'Usage: polycoef($l, $c, $x);'
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
#line 384 "Slatec.pm"


=head2 svdc

=for sig

  Signature: (x(n,p);[o]s(p);[o]e(p);[o]u(n,p);[o]v(p,p);[t]work(n);longlong job();longlong [o]info())

=for ref

singular value decomposition of a matrix

=for bad

svdc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*svdc = \&PDL::svdc;






=head2 poco

=for sig

  Signature: ([io]a(n,n);[o]rcond();[o]z(n);longlong [o]info())

Factor a real symmetric positive definite matrix
and estimate the condition number of the matrix.

=for bad

poco does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*poco = \&PDL::poco;






=head2 geco

=for sig

  Signature: (a(n,n);longlong [o]ipvt(n);[o]rcond();[o]z(n))

Factor a matrix using Gaussian elimination and estimate
the condition number of the matrix.

=for bad

geco does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*geco = \&PDL::geco;






=head2 gefa

=for sig

  Signature: ([io]a(n,n);longlong [o]ipvt(n);longlong [o]info())

=for ref

Factor a matrix using Gaussian elimination.

=for bad

gefa does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gefa = \&PDL::gefa;






=head2 podi

=for sig

  Signature: ([io]a(n,n);[o]det(two=2);longlong job())

Compute the determinant and inverse of a certain real
symmetric positive definite matrix using the factors
computed by L</poco>.

=for bad

podi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*podi = \&PDL::podi;






=head2 gedi

=for sig

  Signature: ([io]a(n,n);longlong ipvt(n);[o]det(two=2);[t]work(n);longlong job())

Compute the determinant and inverse of a matrix using the
factors computed by L</geco> or L</gefa>.

=for bad

gedi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gedi = \&PDL::gedi;






=head2 gesl

=for sig

  Signature: (a(lda,n);longlong ipvt(n);[io]b(n);longlong job())

Solve the real system C<A*X=B> or C<TRANS(A)*X=B> using the
factors computed by L</geco> or L</gefa>.

=for bad

gesl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gesl = \&PDL::gesl;






=head2 rs

=for sig

  Signature: (a(n,n);[o]w(n);longlong matz();[o]z(n,n);[t]fvone(n);[t]fvtwo(n);longlong [o]ierr())

This subroutine calls the recommended sequence of
subroutines from the eigensystem subroutine package (EISPACK)
to find the eigenvalues and eigenvectors (if desired)
of a REAL SYMMETRIC matrix.

=for bad

rs does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*rs = \&PDL::rs;






=head2 ezffti

=for sig

  Signature: (longlong n();[io]wsave(foo);longlong [o]ifac(ni=15))

Subroutine ezffti initializes the work array C<wsave(3n or more)>
and C<ifac()>
which is used in both L</ezfftf> and L</ezfftb>.
The prime factorization
of C<n> together with a tabulation of the trigonometric functions
are computed and stored in C<wsave()>.

=for bad

ezffti does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ezffti = \&PDL::ezffti;






=head2 ezfftf

=for sig

  Signature: (r(n);[o]azero();[o]a(n);[o]b(n);wsave(foo);longlong ifac(ni=15))

=for ref

=for bad

ezfftf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ezfftf = \&PDL::ezfftf;






=head2 ezfftb

=for sig

  Signature: ([o]r(n);azero();a(n);b(n);wsave(foo);longlong ifac(ni=15))

=for ref

=for bad

ezfftb does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ezfftb = \&PDL::ezfftb;






=head2 pcoef

=for sig

  Signature: (longlong l();c();[o]tc(bar);a(foo))

Convert the C<polfit> coefficients to Taylor series form.
C<c> and C<a()> must be of the same type.

=for bad

pcoef does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pcoef = \&PDL::pcoef;






=head2 polyvalue

=for sig

  Signature: (longlong l();x();[o]yfit();[o]yp(nder);a(foo); PDL_LongLong nder => nder)

=for ref

Use the coefficients C<c> generated by L</polyfit> (or L</polfit>) to evaluate
the polynomial fit of degree C<l>, along with the first C<nder> of its
derivatives, at a specified point C<x>.
Broadcasts correctly over multiple C<x> positions.

=for usage

 ($yfit, $yp) = polyvalue($l, $nder, $x, $c);

=for bad

polyvalue does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*polyvalue = \&PDL::polyvalue;






=head2 chim

=for sig

  Signature: (x(n);f(n);[o]d(n);longlong [o]ierr())

=for ref

Calculate the derivatives of (x,f(x)) using cubic Hermite interpolation.

Calculate the derivatives at the given set of points (C<$x,$f>,
where C<$x> is strictly increasing).
The resulting set of points - C<$x,$f,$d>, referred to
as the cubic Hermite representation - can then be used in
other functions, such as L</chfe>, L</chfd>,
and L</chia>.

The boundary conditions are compatible with monotonicity,
and if the data are only piecewise monotonic, the interpolant
will have an extremum at the switch points; for more control
over these issues use L</chic>. 

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chim = \&PDL::chim;






=head2 chic

=for sig

  Signature: (longlong ic(two=2);vc(two=2);mflag();x(n);f(n);[o]d(n);[t]wk(nwk=CALC(2*$SIZE(n)));longlong [o]ierr())

=for ref

Calculate the derivatives of (x,f(x)) using cubic Hermite interpolation.

Calculate the derivatives at the given points (C<$x,$f>,
where C<$x> is strictly increasing).
Control over the boundary conditions is given by the 
C<$ic> and C<$vc> ndarrays, and the value of C<$mflag> determines
the treatment of points where monotoncity switches
direction. A simpler, more restricted, interface is available 
using L</chim>.

The first and second elements of C<$ic> determine the boundary
conditions at the start and end of the data respectively.
If the value is 0, then the default condition, as used by
L</chim>, is adopted.
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chic = \&PDL::chic;






=head2 chsp

=for sig

  Signature: (longlong ic(two=2);vc(two=2);x(n);f(n);[o]d(n);[t]wk(nwk=CALC(2*$SIZE(n)));longlong [o]ierr())

=for ref

Calculate the derivatives of (x,f(x)) using cubic spline interpolation.

Calculate the derivatives, using cubic spline interpolation,
at the given points (C<$x,$f>), with the specified
boundary conditions. 
Control over the boundary conditions is given by the 
C<$ic> and C<$vc> ndarrays.
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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chsp = \&PDL::chsp;






=head2 chfd

=for sig

  Signature: (x(n);f(n);d(n);int [io]skip();xe(ne);[o]fe(ne);[o]de(ne);longlong [o]ierr())

=for ref

Interpolate function and derivative values.

Given a piecewise cubic Hermite function - such as from
L</chim> - evaluate the function (C<$fe>) and 
derivative (C<$de>) at a set of points (C<$xe>).
If function values alone are required, use L</chfe>.
Set C<skip> to 0 to skip checks on the input data.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chfd = \&PDL::chfd;






=head2 chfe

=for sig

  Signature: (x(n);f(n);d(n);int [io]skip();xe(ne);[o]fe(ne);longlong [o]ierr())

=for ref

Interpolate function values.

Given a piecewise cubic Hermite function - such as from
L</chim> - evaluate the function (C<$fe>) at
a set of points (C<$xe>).
If derivative values are also required, use L</chfd>.
Set C<skip> to 0 to skip checks on the input data.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chfe = \&PDL::chfe;






=head2 chia

=for sig

  Signature: (x(n);f(n);d(n);int [io]skip();la();lb();[o]ans();longlong [o]ierr())

=for ref

Integrate (x,f(x)) over arbitrary limits.

Evaluate the definite integral of a piecewise
cubic Hermite function over an arbitrary interval,
given by C<[$la,$lb]>. C<$d> should contain the derivative values, computed by L</chim>.
See L</chid> if the integration limits are
data points.
Set C<skip> to 0 to skip checks on the input data.

The values of C<$la> and C<$lb> do not have
to lie within C<$x>, although the resulting integral
value will be highly suspect if they are not.

Error status returned by C<$ierr>:

=over 4

=item *

0 if successful.

=item *

1 if C<$la> lies outside C<$x>.

=item *

2 if C<$lb> lies outside C<$x>.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chia = \&PDL::chia;






=head2 chid

=for sig

  Signature: (x(n);f(n);d(n);int [io]skip();longlong ia();longlong ib();[o]ans();longlong [o]ierr())

=for ref

Integrate (x,f(x)) between data points.

Evaluate the definite integral of a a piecewise
cubic Hermite function between C<x($ia)> and
C<x($ib)>. 

See L</chia> for integration between arbitrary
limits.

Although using a fortran routine, the values of
C<$ia> and C<$ib> are zero offset.
C<$d> should contain the derivative values, computed by L</chim>.
Set C<skip> to 0 to skip checks on the input data.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chid = \&PDL::chid;






=head2 chcm

=for sig

  Signature: (x(n);f(n);d(n);int [io]skip();longlong [o]ismon(n);longlong [o]ierr())

=for ref

Check the given piecewise cubic Hermite function for monotonicity.

The outout ndarray C<$ismon> indicates over
which intervals the function is monotonic.
Set C<skip> to 0 to skip checks on the input data.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chcm = \&PDL::chcm;






=head2 chbs

=for sig

  Signature: (x(n);f(n);d(n);longlong knotyp();longlong [io]nknots();[io]t(tsize=CALC(2*$SIZE(n)+4));[o]bcoef(bsize=CALC(2*$SIZE(n)));longlong [o]ndim();longlong [o]kord();longlong [o]ierr())

=for ref

Piecewise Cubic Hermite function to B-Spline converter.

The resulting B-spline representation of the data
(i.e. C<nknots>, C<t>, C<bcoeff>, C<ndim>, and
C<kord>) can be evaluated by L</bvalu>.

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
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*chbs = \&PDL::chbs;






=head2 bvalu

=for sig

  Signature: (t(nplusk);a(n);longlong ideriv();x();[t]work(k3=CALC(3*($SIZE(nplusk)-$SIZE(n))));[o]ans())

=for ref

Evaluate the B-representation of a B-spline at X for the
function value or any of its derivatives.

Evaluates the B-representation C<(T,A,N,K)> of a B-spline
at C<X> for the function value on C<IDERIV = 0> or any of its
derivatives on C<IDERIV = 1,2,...,K-1>.  Right limiting values
(right derivatives) are returned except at the right end
point C<X=T(N+1)> where left limiting values are computed.  The
spline is defined on C<T(K) .LE. X .LE. T(N+1)>.  BVALU returns
a fatal error message when C<X> is outside of this interval.

To compute left derivatives or left limiting values at a
knot C<T(I)>, replace C<N> by C<I-1> and set C<X=T(I)>, C<I=K+1,N+1>.

=head3 Description of Arguments

=head4 Input

     T       - knot vector of length N+K
     A       - B-spline coefficient vector of length N
     N       - number of B-spline coefficients
               N = sum of knot multiplicities-K
     K       - order of the B-spline, K .GE. 1
     IDERIV  - order of the derivative, 0 .LE. IDERIV .LE. K-1
               IDERIV=0 returns the B-spline value
     X       - argument, T(K) .LE. X .LE. T(N+1)
     INBV    - an initialization parameter which must be set
               to 1 the first time BVALU is called. (PDL sets to 1 for you)

=head4 Output

     INBV    - INBV contains information for efficient process-
               ing after the initial call and INBV must not
               be changed by the user.  Distinct splines require
               distinct INBV parameters. (unavailable in PDL)
     WORK    - work vector of length 3*K.
     BVALU   - value of the IDERIV-th derivative at X

=head4 Error Conditions

An improper input is a fatal error

=for bad

bvalu does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*bvalu = \&PDL::bvalu;






=head2 polfit

=for sig

  Signature: (x(n); y(n); w(n); longlong maxdeg(); longlong [o]ndeg(); [io]eps(); [o]r(n); longlong [o]ierr(); [o]a(foo=CALC(3*($SIZE(n) + $SIZE(bar)))); [o]coeffs(bar);[t]xtmp(n);[t]ytmp(n);[t]wtmp(n);[t]rtmp(n); IV max_maxdeg_plus1 => bar)

Fit discrete data in a least squares sense by polynomials
          in one variable. C<x()>, C<y()> and C<w()> must be of the same type.
	  This version handles bad values appropriately

=for bad

polfit processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*polfit = \&PDL::polfit;





#line 1552 "slatec.pd"

=head1 AUTHOR

Copyright (C) 1997 Tuomas J. Lukka. 
Copyright (C) 2000 Tim Jenness, Doug Burke.            
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.

=cut
#line 1596 "Slatec.pm"

# Exit with OK status

1;
