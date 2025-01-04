#
# GENERATED WITH PDL::PP from slatec.pd! Don't modify!
#
package PDL::Slatec;

our @EXPORT_OK = qw(eigsys matinv polyfit polycoef svdc poco geco gefa podi gedi gesl rs ezffti ezfftf ezfftb pcoef polyvalue polfit );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '2.097';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Slatec $VERSION;







#line 8 "slatec.pd"

use strict;
use warnings;

=head1 NAME

PDL::Slatec - PDL interface to some LINPACK and EISPACK routines - DEPRECATED

=head1 SYNOPSIS

 use PDL::Slatec;

 ($ndeg, $r, $ierr, $c) = polyfit($x, $y, $w, $maxdeg, $eps);

=head1 DESCRIPTION

This module is now deprecated in favour of L<PDL::LinearAlgebra>.

This module serves the dual purpose of providing an interface to
parts of the slatec library and showing how to interface PDL
to an external library.
Using this library requires a Fortran compiler; the source for the routines
is provided for convenience.

Currently available are routines to:
manipulate matrices; calculate FFT's; 
and fit data using polynomials.

=head2 Piecewise cubic Hermite interpolation (PCHIP)

These routines are now in L<PDL::Primitive> as of PDL 2.096.

=cut
#line 60 "Slatec.pm"


=head1 FUNCTIONS

=cut





#line 47 "slatec.pd"

=head2 eigsys

=for ref

Eigenvalues and eigenvectors of a real positive definite symmetric matrix.

=for usage

 ($eigvals,$eigvecs) = eigsys($mat)

Note: this function should be extended to calculate only eigenvalues if called 
in scalar context!

This is the EISPACK routine C<rs>.

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

#line 362 "slatec.pd"
use PDL::Core;
use PDL::Basic;
use PDL::Primitive;
use PDL::Ufunc;
use strict;

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
#line 344 "Slatec.pm"


=head2 svdc

=for sig

  Signature: (x(n,p); [o] s(p); [o] e(p); [o] u(n,p); [o] v(p,p); [t] work(n); longlong job(); longlong [o] info())

=for ref

singular value decomposition of a matrix

=for bad

svdc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*svdc = \&PDL::svdc;






=head2 poco

=for sig

  Signature: ([io] a(n,n); [o] rcond(); [o] z(n); longlong [o] info())

Factor a real symmetric positive definite matrix
and estimate the condition number of the matrix.

=for bad

poco does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*poco = \&PDL::poco;






=head2 geco

=for sig

  Signature: (a(n,n); longlong [o] ipvt(n); [o] rcond(); [o] z(n))

Factor a matrix using Gaussian elimination and estimate
the condition number of the matrix.

=for bad

geco does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*geco = \&PDL::geco;






=head2 gefa

=for sig

  Signature: ([io] a(n,n); longlong [o] ipvt(n); longlong [o] info())

=for ref

Factor a matrix using Gaussian elimination.

=for bad

gefa does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gefa = \&PDL::gefa;






=head2 podi

=for sig

  Signature: ([io] a(n,n); [o] det(two=2); longlong job())

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

  Signature: ([io] a(n,n); longlong ipvt(n); [o] det(two=2); [t] work(n); longlong job())

Compute the determinant and inverse of a matrix using the
factors computed by L</geco> or L</gefa>.

=for bad

gedi does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gedi = \&PDL::gedi;






=head2 gesl

=for sig

  Signature: (a(lda,n); longlong ipvt(n); [io] b(n); longlong job())

Solve the real system C<A*X=B> or C<TRANS(A)*X=B> using the
factors computed by L</geco> or L</gefa>.

=for bad

gesl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*gesl = \&PDL::gesl;






=head2 rs

=for sig

  Signature: (a(n,n); [o] w(n); longlong matz(); [o] z(n,n); [t] fvone(n); [t] fvtwo(n); longlong [o] ierr())

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

  Signature: (longlong n(); [io] wsave(foo); longlong [o] ifac(ni=15))

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

  Signature: (r(n); [o] azero(); [o] a(n); [o] b(n); wsave(foo); longlong ifac(ni=15))

=for ref

=for bad

ezfftf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ezfftf = \&PDL::ezfftf;






=head2 ezfftb

=for sig

  Signature: ([o] r(n); azero(); a(n); b(n); wsave(foo); longlong ifac(ni=15))

=for ref

=for bad

ezfftb does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*ezfftb = \&PDL::ezfftb;






=head2 pcoef

=for sig

  Signature: (longlong l(); c(); [o] tc(bar); a(foo))

Convert the C<polfit> coefficients to Taylor series form.
C<c> and C<a()> must be of the same type.

=for bad

pcoef does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*pcoef = \&PDL::pcoef;






=head2 polyvalue

=for sig

  Signature: (longlong l(); x(); [o] yfit(); [o] yp(nder); a(foo); PDL_LongLong nder => nder)

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





#line 766 "slatec.pd"

=head1 AUTHOR

Copyright (C) 1997 Tuomas J. Lukka. 
Copyright (C) 2000 Tim Jenness, Doug Burke.            
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.

=cut
#line 739 "Slatec.pm"

# Exit with OK status

1;
