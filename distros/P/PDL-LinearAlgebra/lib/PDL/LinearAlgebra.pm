package PDL::LinearAlgebra;
use PDL::Ops;
use PDL::Core;
use PDL::Basic qw/sequence/;
use PDL::Primitive qw/which which_both/;
use PDL::Ufunc qw/sumover/;
use PDL::NiceSlice;
use PDL::Slices;
use PDL::LinearAlgebra::Real;
use PDL::LinearAlgebra::Complex;
use PDL::LinearAlgebra::Special qw//;
use PDL::Exporter;
no warnings 'uninitialized';
use constant{
	NO => 0,
	WARN => 1,
	BARF => 2,
};

use strict;

our $VERSION = '0.22';
$VERSION = eval $VERSION;

@PDL::LinearAlgebra::ISA = qw/PDL::Exporter/;
@PDL::LinearAlgebra::EXPORT_OK = qw/t diag issym minv mtriinv msyminv mposinv mdet mposdet mrcond positivise
				mdsvd msvd mgsvd mpinv mlu mhessen mchol mqr mql mlq mrq meigen meigenx
				mgeigen  mgeigenx msymeigen msymeigenx msymgeigen msymgeigenx
				msolve mtrisolve msymsolve mpossolve msolvex msymsolvex mpossolvex
				mrank mlls mllsy mllss mglm mlse tritosym mnorm mgschur mgschurx
				mcrossprod mcond morth mschur mschurx posinf neginf
				NO WARN BARF setlaerror getlaerorr laerror/;
%PDL::LinearAlgebra::EXPORT_TAGS = (Func=>[@PDL::LinearAlgebra::EXPORT_OK]);

my $_laerror = BARF;

my $posinf;
BEGIN { $posinf = 1/pdl(0) }
sub posinf() { $posinf->copy };
my $neginf;
BEGIN { $neginf = -1/pdl(0) }
sub neginf() { $neginf->copy };

{

package # hide from CPAN indexer
  PDL::Complex;

use PDL::Types;

use vars qw($sep $sep2);
our $floatformat  = "%4.4g";    # Default print format for long numbers
our $doubleformat = "%6.6g";


*r2p = \&PDL::Complex::Cr2p;
*p2r = \&PDL::Complex::Cp2r;
*scale = \&PDL::Complex::Cscale;
*conj = \&PDL::Complex::Cconj;
*abs2 = \&PDL::Complex::Cabs2;
*arg = \&PDL::Complex::Carg;
*tan = \&PDL::Complex::Ctan;
*proj = \&PDL::Complex::Cproj;
*asin = \&PDL::Complex::Casin;
*acos = \&PDL::Complex::Cacos;
*atan = \&PDL::Complex::Catan;
*sinh = \&PDL::Complex::Csinh;
*cosh = \&PDL::Complex::Ccosh;
*tanh = \&PDL::Complex::Ctanh;
*asinh = \&PDL::Complex::Casinh;
*acosh = \&PDL::Complex::Cacosh;
*atanh = \&PDL::Complex::Catanh;
*prodover = \&PDL::Complex::Cprodover;

sub ecplx {
  my ($re, $im) = @_;
  return $re if UNIVERSAL::isa($re,'PDL::Complex');
  if (defined $im){
	  $re = pdl($re) unless (UNIVERSAL::isa($re,'PDL'));
	  $im = pdl($im) unless (UNIVERSAL::isa($im,'PDL'));
	  my $ret =  PDL::new_from_specification('PDL::Complex', $re->type, 2, $re->dims);
	  $ret->slice('(0),') .= $re;
	  $ret->slice('(1),') .= $im;
	  return $ret;  
  }
  Carp::croak("first dimsize must be 2") unless $re->dims > 0 && $re->dim(0) == 2;
  bless $_[0]->slice('');
}


sub sumover {
	my $c = shift;
	return dims($c) > 1 ? PDL::Ufunc::sumover($c->xchg(0,1)) : $c;
}



sub norm {
	my ($m, $real, $trans) = @_;
	
	# If trans == true => transpose output matrice
	# If real == true => rotate (complex as a vector)
	# 		     such that max abs will be real
	
	#require PDL::LinearAlgebra::Complex;
	PDL::LinearAlgebra::Complex::cnrm2($m,1, my $ret = PDL::null());
	if ($real){
		my ($index, $scale);
		$m = PDL::Complex::Cscale($m,1/$ret->dummy(0))->reshape(-1);
		$index = $m->Cabs->maximum_ind;
		$scale = $m->mv(0,-1)->index($index)->mv(-1,0);
		$scale= $scale->Cconj/$scale->Cabs;
		return $trans ? $m->xchg(1,2)*$scale->dummy(2) : $m*$scale->dummy(2)->xchg(1,2);
	}
	return $trans ? PDL::Complex::Cscale($m->xchg(1,2),1/$ret->dummy(0)->xchg(0,1))->reshape(-1) :
		PDL::Complex::Cscale($m,1/$ret->dummy(0))->reshape(-1);
}


}
########################################################################

=encoding Latin-1

=head1 NAME

PDL::LinearAlgebra - Linear Algebra utils for PDL

=head1 SYNOPSIS

 use PDL::LinearAlgebra;

 $a = random (100,100);
 ($U, $s, $V) = mdsvd($a);

=head1 DESCRIPTION

This module provides a convenient interface to L<PDL::LinearAlgebra::Real|PDL::LinearAlgebra::Real>
and L<PDL::LinearAlgebra::Complex|PDL::LinearAlgebra::Complex>. Its primary purpose is educational.
You have to know that routines defined here are not optimized, particularly in term of memory. Since
Blas and Lapack use a column major ordering scheme some routines here need to transpose matrices before
calling fortran routines and transpose back (see the documentation of each routine). If you need
optimized code use directly  L<PDL::LinearAlgebra::Real|PDL::LinearAlgebra::Real> and 
L<PDL::LinearAlgebra::Complex|PDL::LinearAlgebra::Complex>. It's planned to "port" this module to PDL::Matrix such
that transpositions will not be necessary, the major problem is that two new modules need to be created PDL::Matrix::Real
and PDL::Matrix::Complex.


=cut


=head1 FUNCTIONS

=head2 setlaerror

=for ref

Sets action type when an error is encountered, returns previous type. Available values are NO, WARN and BARF (predefined constants).
If, for example, in computation of the inverse, singularity is detected,
the routine can silently return values from computation (see manuals), 
warn about singularity or barf. BARF is the default value.

=for example

 # h : x -> g(f(x))

 $a = sequence(5,5);
 $err = setlaerror(NO);
 ($b, $info)= f($a);
 setlaerror($err);
 $info ? barf "can't compute h" : return g($b);


=cut

sub setlaerror($){
	my $err = $_laerror;
	$_laerror = shift;
	$err;
}

=head2 getlaerror

=for ref

Gets action type when an error is encountered.
	
	0 => NO,
	1 => WARN,
	2 => BARF

=cut

sub getlaerror{
	$_laerror;
}

sub laerror{
	return unless $_laerror;
	if ($_laerror < 2){
		warn "$_[0]\n";
	}
	else{
		barf "$_[0]\n";
	}
}

=head2 t

=for usage

 PDL = t(PDL, SCALAR(conj))
 conj : Conjugate Transpose = 1 | Transpose = 0, default = 1;

=for ref

Convenient function for transposing real or complex 2D array(s).
For PDL::Complex, if conj is true returns conjugate transposed array(s) and doesn't support dataflow.
Supports threading.

=cut

sub t{
	my $m = shift;
	$m->t(@_);
}

sub PDL::t {
	$_[0]->xchg(0,1);
}
sub PDL::Complex::t {
	my ($m, $conj) = @_;
	$conj = 1 unless defined($conj);
	$conj ? PDL::Complex::Cconj($m->xchg(1,2)) : $m->xchg(1,2);
}

=head2 issym

=for usage

 PDL = issym(PDL, SCALAR|PDL(tol),SCALAR(hermitian))
 tol : tolerance value, default: 1e-8 for double else 1e-5 
 hermitian : Hermitian = 1 | Symmetric = 0, default = 1;

=for ref

Checks symmetricity/Hermitianicity of matrix.
Supports threading.

=cut

sub issym{
	my $m = shift;
	$m->issym(@_);
}

sub PDL::issym {
	my ($m, $tol) = @_;
	my @dims = $m->dims;

	barf("issym: Require square array(s)")
		if( $dims[0] != $dims[1] );

	$tol =  defined($tol) ? $tol  : ($m->type == double) ? 1e-8 : 1e-5;

	my ($min,$max) = PDL::Ufunc::minmaximum($m - $m->xchg(0,1));
	$min = $min->minimum;
	$max = $max->maximum;
	return  (((abs($max) > $tol) + (abs($min) > $tol)) == 0);
}

sub PDL::Complex::issym {
	my ($m, $tol, $conj) = @_;
	my @dims = $m->dims;

	barf("issym: Require square array(s)")
		if( $dims[1] != $dims[2] );

	$conj = 1 unless defined($conj);
	$tol =  defined($tol) ? $tol  : ($m->type == double) ? 1e-8 : 1e-5;

	my ($min, $max, $mini, $maxi);
	if ($conj){
		($min,$max) = PDL::Ufunc::minmaximum(PDL::clump($m - $m->t(1),2));
	}
	else{
		($min,$max) = PDL::Ufunc::minmaximum(PDL::clump($m - $m->xchg(1,2),2));
	}
	$min->minimum($mini = null);
	$max->maximum($maxi = null);
	return  (((abs($maxi) > $tol) + (abs($mini) > $tol)) == 0);

}


=head2 diag

=for ref

Returns i-th diagonal if matrix in entry or matrix with i-th diagonal
with entry. I-th diagonal returned flows data back&forth.
Can be used as lvalue subs if your perl supports it.
Supports threading.

=for usage

 PDL = diag(PDL, SCALAR(i), SCALAR(vector)))
 i	: i-th diagonal, default = 0
 vector	: create diagonal matrices by threading over row vectors, default = 0
 

=for example

 my $a = random(5,5);
 my $diag  = diag($a,2);
 # If your perl support lvaluable subroutines.
 $a->diag(-2) .= pdl(1,2,3);
 # Construct a (5,5,5) PDL (5 matrices) with
 # diagonals from row vectors of $a
 $a->diag(0,1)

=cut

sub diag{
	my $m = shift;
	$m->diag(@_);
}
sub PDL::diag{
	my ($a,$i, $vec) = @_;
	my ($diag, $dim, @dims, $z);
	@dims = $a->dims;

	$diag = ($i < 0) ? -$i : $i ;

	if (@dims == 1 || $vec){ 
		$dim = $dims[0];
		my $zz = $dim + $diag;
		$z= PDL::zeroes('PDL',$a->type,$zz, $zz,@dims[1..$#dims]);
		if ($i){
			($i < 0) ? $z(:($dim-1),$diag:)->diagonal(0,1) .= $a : $z($diag:,:($dim-1))->diagonal(0,1).=$a;
		}
		else{ $z->diagonal(0,1) .= $a; }
	}
	elsif($i < 0){
		$z = $a(:-$diag-1 , $diag:)->diagonal(0,1);
	}
	elsif($i){
		$z = $a($diag:, :-$diag-1)->diagonal(0,1);
	}
	else{$z = $a->diagonal(0,1);}
	$z;
}

sub PDL::Complex::diag{
	my ($a,$i, $vec) = @_;
	my ($diag, $dim, @dims, $z);
	@dims = $a->dims;

	$diag = ($i < 0) ? -$i : $i ;


	if (@dims == 2 || $vec){ 
		$dim = $dims[1];
		my $zz = $dim + $diag;
		$z= PDL::zeroes('PDL::Complex',$a->type, 2, $zz, $zz,@dims[2..$#dims]);
		if ($i){
			($i < 0) ? $z(,:($dim-1),$diag:)->diagonal(1,2) .= $a : $z(,$diag:,:($dim-1))->diagonal(1,2).=$a;
		}
		else{ $z->diagonal(1,2) .= $a; }
	}
	elsif($i < 0){
		$z = $a(,:-$diag-1 , $diag:)->diagonal(1,2);
	}
	elsif($i){
		$z = $a(,$diag:, :-$diag-1 )->diagonal(1,2);
	}
	else{
		$z = $a->diagonal(1,2);
	}
	$z;
}

if ($^V and $^V ge v5.6.0){
use attributes 'PDL', \&PDL::diag, 'lvalue';
use attributes 'PDL', \&PDL::Complex::diag, 'lvalue';
}

=head2 tritosym

=for ref

Returns symmetric or Hermitian matrix from lower or upper triangular matrix.
Supports inplace and threading.
Uses L<tricpy|PDL::LinearAlgebra::Real/tricpy> or L<ctricpy|PDL::LinearAlgebra::Complex/ctricpy> from Lapack.

=for usage

 PDL = tritosym(PDL, SCALAR(uplo), SCALAR(conj))
 uplo : UPPER = 0 | LOWER = 1, default = 0
 conj : Hermitian = 1 | Symmetric = 0, default = 1;

=for example

 # Assume $a is symmetric triangular
 my $a = random(10,10);
 my $b = tritosym($a);

=cut

sub tritosym{
	my $m = shift;
	$m->tritosym(@_);
}

sub PDL::tritosym {
	my ($m, $upper) = @_;
	my @dims = $m->dims;

	barf("tritosym: Require square array(s)")
		unless( $dims[0] == $dims[1] );

	my $b = $m->is_inplace ? $m : PDL::new_from_specification(ref($m),$m->type,@dims);
	$m->tricpy($upper, $b) unless $m->is_inplace(0);
	$m->tricpy($upper, $b->xchg(0,1));
	$b;

}

sub PDL::Complex::tritosym {
	my ($m, $upper, $conj) = @_;
	my @dims = $m->dims;

	barf("tritosym: Require square array(s)")
		if( $dims[1] != $dims[2] );

	my $b = $m->is_inplace ? $m : PDL::new_from_specification(ref($m),$m->type,@dims);
	$conj = 1 unless defined($conj);
	$conj ? PDL::Complex::Cconj($m)->ctricpy($upper, $b->xchg(1,2)) : 
			$m->ctricpy($upper, $b->xchg(1,2));
	# ...
	$m->ctricpy($upper, $b) unless (!$conj && $m->is_inplace(0));
	$b((1),)->diagonal(0,1) .= 0 if $conj;
	$b;

}


=head2 positivise

=for ref

Returns entry pdl with changed sign by row so that average of positive sign > 0.
In other words threads among dimension 1 and row  =  -row if sum(sign(row)) < 0.
Works inplace.

=for example

 my $a = random(10,10);
 $a -= 0.5;
 $a->xchg(0,1)->inplace->positivise;

=cut

*positivise = \&PDL::positivise;
sub PDL::positivise{
	my $m = shift;
	my $tmp;
	$m = $m->copy unless $m->is_inplace(0);
	$tmp = $m->dice('X', which((   $m->lt(0,0)->sumover > ($m->dim(0)/2))>0));
	$tmp->inplace->mult(-1,0);# .= -$tmp;
	$m;
}




=head2 mcrossprod

=for ref

Computes the cross-product of two matrix: A' x  B. 
If only one matrix is given, takes B to be the same as A.
Supports threading.
Uses L<crossprod|PDL::LinearAlgebra::Real/crossprod> or L<ccrossprod|PDL::LinearAlgebra::Complex/ccrossprod>.

=for usage

 PDL = mcrossprod(PDL(A), (PDL(B))

=for example

 my $a = random(10,10);
 my $crossproduct = mcrossprod($a);

=cut

sub mcrossprod{
	my $m = shift;
	$m->mcrossprod(@_);
}

sub PDL::mcrossprod {
	my($a, $b) = @_;
	my(@dims) = $a->dims;

	barf("mcrossprod: Require 2D array(s)")
		unless( @dims >= 2 );
	
	$b = $a unless defined $b;
	$a->crossprod($b);
}

sub PDL::Complex::mcrossprod {
	my($a, $b) = @_;
	my(@dims) = $a->dims;

	barf("mcrossprod: Require 2D array(s)")
		unless( @dims >= 3);
	
	$b = $a unless defined $b;
	$a->ccrossprod($b);
}


=head2 mrank

=for ref

Computes the rank of a matrix, using a singular value decomposition.
from Lapack.

=for usage

 SCALAR = mrank(PDL, SCALAR(TOL))
 TOL:	tolerance value, default : mnorm(dims(PDL),'inf') * mnorm(PDL) * EPS

=for example

 my $a = random(10,10);
 my $b = mrank($a, 1e-5);

=cut

*mrank = \&PDL::mrank;

sub PDL::mrank {
	my($m, $tol) = @_;
	my(@dims) = $m->dims;

	barf("mrank: Require a 2D matrix")
		unless( @dims == 2 or @dims == 3 );

	my ($sv, $info, $err);

	$err = setlaerror(NO);
	# Sometimes mdsvd bugs for  float (SGEBRD)
	# ($sv, $info) = $m->msvd(0, 0);
	($sv, $info) = $m->mdsvd(0);
	setlaerror($err);
	barf("mrank: SVD algorithm did not converge\n") if $info;

	unless (defined $tol){
		$tol =  ($dims[-1] > $dims[-2] ? $dims[-1] : $dims[-2]) * $sv((0)) * lamch(pdl($m->type,3));
	}
	(which($sv > $tol))->dim(0);
}

=head2 mnorm

=for ref

Computes norm of real or complex matrix
Supports threading.

=for usage

 PDL(norm) = mnorm(PDL, SCALAR(ord));
 ord : 
 	0|'inf' : Infinity norm
 	1|'one' : One norm
 	2|'two'	: norm 2 (default)
 	3|'fro' : frobenius norm

=for example

 my $a = random(10,10);
 my $norm = mnorm($a);

=cut

sub mnorm {
	my $m =shift;
	$m->mnorm(@_);
}


sub PDL::mnorm {
	my ($m, $ord) = @_;
	$ord = 2 unless (defined $ord);

	if ($ord eq 'inf'){
		$ord = 0;
	}
	elsif ($ord eq 'one'){
		$ord = 1;	
	}
	elsif($ord eq 'two'){
		$ord = 2;
	}
	elsif($ord eq 'fro'){
		$ord = 3;
	}

	if ($ord == 0){
		$m->lange(1);
	}
	elsif($ord == 1){
		$m->lange(2);
	}
	elsif($ord == 3){
		$m->lange(3);
	}
	else{
		my ($sv, $info, $err);
		$err = setlaerror(NO);
		($sv, $info) = $m->msvd(0, 0);
		setlaerror($err);
		if($info->max > 0 && $_laerror) {
			my ($index,@list);
			$index = which($info > 0)+1;
			@list = $index->list;
			laerror("mnorm: SVD algorithm did not converge for matrix (PDL(s) @list): \$info = $info");
		}
		$sv->slice('(0)')->reshape(-1)->sever;
	}
	
}


sub PDL::Complex::mnorm {
	my ($m, $ord) = @_;
	$ord = 2 unless (defined $ord);

	if ($ord eq 'inf'){
		$ord = 0;
	}
	elsif ($ord eq 'one'){
		$ord = 1;	
	}
	elsif($ord eq 'two'){
		$ord = 2;
	}
	elsif($ord eq 'fro'){
		$ord = 3;
	}

	if ($ord == 0){
		return bless $m->clange(1),'PDL';
	}
	elsif($ord == 1){
		return bless $m->clange(2),'PDL';
	}
	elsif($ord == 3){
		return bless  $m->clange(3),'PDL';
	}
	else{
		my ($sv, $info, $err) ;
		$err = setlaerror(NO);
		($sv, $info) = $m->msvd(0, 0);
		setlaerror($err);
		if($info->max > 0 && $_laerror) {
			my ($index,@list);
			$index = which($info > 0)+1;
			@list = $index->list;
			laerror("mnorm: SVD algorithm did not converge for matrix (PDL(s) @list): \$info = $info");
		}
		$sv->slice('(0)')->reshape(-1)->sever;
	}
	
}



=head2 mdet

=for ref

Computes determinant of a general square matrix using LU factorization.
Supports threading.
Uses L<getrf|PDL::LinearAlgebra::Real/getrf> or L<cgetrf|PDL::LinearAlgebra::Complex/cgetrf>
from Lapack.

=for usage

 PDL(determinant) = mdet(PDL);

=for example

 my $a = random(10,10);
 my $det = mdet($a);

=cut

sub mdet{
	my $m =shift;
	$m->mdet;
}


sub PDL::mdet {
	my $m = shift;
	my @dims = $m->dims;

	barf("mdet: Require square array(s)")
		unless( $dims[0] == $dims[1]  && @dims >= 2);

	my ($info, $ipiv);
	$m = $m->copy();
	$info = null;
	$ipiv = null;

	$m->getrf($ipiv, $info);
	$m = $m->diagonal(0,1)->prodover;

	$m = $m *  ((PDL::Ufunc::sumover(sequence($ipiv->dim(0))->plus(1,0) != $ipiv)%2)*(-2)+1) ;
	$info = $m->flat->index(which($info != 0 ));
	$info .= 0 unless $info->isempty;
	$m;
}


sub PDL::Complex::mdet {
	my $m = shift;
	my @dims = $m->dims;

	barf("mdet: Require square array(s)")
		unless( @dims >= 3 && $dims[1] == $dims[2] );

	my ($info, $ipiv);
	$m = $m->copy();
	$info = null;
	$ipiv = null;

	$m->cgetrf($ipiv, $info);
	$m = PDL::Complex::Cprodover($m->diagonal(1,2));
	$m = $m *  ((PDL::Ufunc::sumover(sequence($ipiv->dim(0))->plus(1,0) != $ipiv)%2)*(-2)+1) ;
	
	$info = which($info != 0 );
	unless ($info->isempty){
		$m->re->flat->index($info) .= 0;
		$m->im->flat->index($info) .= 0;
	}
	$m;

}


=head2 mposdet

=for ref

Compute determinant of a symmetric or Hermitian positive definite square matrix using Cholesky factorization.
Supports threading.
Uses L<potrf|PDL::LinearAlgebra::Real/potrf> or L<cpotrf|PDL::LinearAlgebra::Complex/cpotrf> from Lapack.

=for usage

 (PDL, PDL) = mposdet(PDL, SCALAR)
 SCALAR : UPPER = 0 | LOWER = 1, default = 0

=for example

 my $a = random(10,10);
 my $det = mposdet($a);

=cut

sub mposdet{
	my $m =shift;
	$m->mposdet(@_);
}

sub PDL::mposdet {
	my ($m, $upper)  = @_;
	my @dims = $m->dims;

	barf("mposdet: Require square array(s)")
		unless( @dims >= 2 && $dims[0] == $dims[1] );

	$m = $m->copy();
	
	$m->potrf($upper, (my $info=null));
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mposdet: Matrix (PDL(s) @list) is/are not positive definite(s) (after potrf factorization): \$info = $info");
	}
	$m = $m->diagonal(0,1)->prodover->pow(2);
	return wantarray ? ($m, $info) : $m;
}

sub PDL::Complex::mposdet {
	my ($m, $upper)  = @_;
	my @dims = $m->dims;

	barf("mposdet: Require square array(s)")
		unless( @dims >= 3 && $dims[1] == $dims[2] );

	$m = $m->copy();
		
	$m->cpotrf($upper, (my $info=null));
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mposdet: Matrix (PDL(s) @list) is/are not positive definite(s) (after cpotrf factorization): \$info = $info");
	}

	$m = PDL::Complex::re($m)->diagonal(0,1)->prodover->pow(2);
	return wantarray ? ($m, $info) : $m;
}


=head2 mcond

=for ref

Computes the condition number (two-norm) of a general matrix. 

The condition number in two-n is defined:

	norm (a) * norm (inv (a)).

Uses a singular value decomposition.
Supports threading.

=for usage

 PDL = mcond(PDL)

=for example

 my $a = random(10,10);
 my $cond = mcond($a);

=cut

sub mcond{
	my $m =shift;
	$m->mcond(@_);
}

sub PDL::mcond {
	my $m = shift;
	my @dims = $m->dims;

	barf("mcond: Require 2D array(s)")
		unless( @dims >= 2 );

	my ($sv, $info, $err, $ret, $temp);
	$err = setlaerror(NO);
	($sv, $info) = $m->msvd(0, 0);
	setlaerror($err);
	if($info->max > 0) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		barf("mcond: Algorithm did not converge for matrix (PDL(s) @list): \$info = $info");
	}
	
	$temp = $sv->slice('(0)');
        $ret = $temp/$sv->((-1));
	
	$info = $ret->flat->index(which($temp == 0));
	$info .= posinf unless $info->isempty;
	return $ret;
	
}

sub PDL::Complex::mcond {
	my $m = shift;
	my @dims = $m->dims;

	barf("mcond: Require 2D array(s)")
		unless( @dims >= 3);

	my ($sv, $info, $err, $ret, $temp) ;
	$err = setlaerror(NO);
	($sv, $info) = $m->msvd(0, 0);
	setlaerror($err);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mcond: Algorithm did not converge for matrix (PDL(s) @list): \$info = $info");
	}

	$temp = $sv->slice('(0)');
        $ret = $temp/$sv->((-1));
	
	$info = $ret->flat->index(which($temp == 0));
	$info .= posinf unless $info->isempty;
	return $ret;
}



=head2 mrcond

=for ref

Estimates the reciprocal condition number of a
general square matrix using LU factorization
in either the 1-norm or the infinity-norm.

The reciprocal condition number is defined:

	1/(norm (a) * norm (inv (a)))

Supports threading.
Works on transposed array(s)

=for usage

 PDL = mrcond(PDL, SCALAR(ord))
 ord : 
 	0 : Infinity norm (default)
 	1 : One norm

=for example

 my $a = random(10,10);
 my $rcond = mrcond($a,1);

=cut

sub mrcond{
	my $m =shift;
	$m->mcond(@_);
}

sub PDL::mrcond {
	my ($m,$anorm) = @_;
	$anorm = 0 unless defined $anorm;
	my @dims = $m->dims;

	barf("mrcond: Require square array")
		unless ( $dims[0] == $dims[1] );

	my ($ipiv, $info,$rcond,$norm);
	$norm = $m->mnorm($anorm);
	$m = $m->xchg(0,1)->copy();
	$ipiv = PDL->null;
	$info = PDL->null;
	$rcond = PDL->null;

	$m->getrf($ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mrcond: Factor(s) U (PDL(s) @list) is/are singular(s) (after getrf factorization): \$info = $info");
	}
	else{
		$m->gecon($anorm,$norm,$rcond,$info);
	}
	return wantarray ? ($rcond, $info) : $rcond;
}

sub PDL::Complex::mrcond {
	my ($m, $anorm) = @_;
	$anorm = 0 unless defined $anorm;
	my @dims = $m->dims;

	barf("mrcond: Require square array(s)")
		unless ( $dims[1] == $dims[2] );

	my ($ipiv, $info,$rcond,$norm);
	$norm = $m->mnorm($anorm);
	$m = $m->xchg(1,2)->copy();
	$ipiv = PDL->null;
	$info = PDL->null;
	$rcond = PDL->null;
	
	$m->cgetrf($ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mrcond: Factor(s) U (PDL(s) @list) is/are singular(s) (after cgetrf factorization) : \$info = $info");
	}
	else{
		$m->cgecon($anorm,$norm,$rcond,$info);
	}
	return wantarray ? ($rcond, $info) : $rcond;

}





=head2 morth

=for ref

Returns an orthonormal basis of the range space of matrix A.

=for usage

 PDL = morth(PDL(A), SCALAR(tol))
 tol : tolerance for determining rank, default: 1e-8 for double else 1e-5 

=for example

 my $a = sequence(10,10);
 my $ortho = morth($a, 1e-8);

=cut

*morth = \&PDL::morth;

sub PDL::morth {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("morth: Require a matrix")
		unless( (@dims == 2)  || (@dims == 3));

	my ($u, $s, $rank, $info, $err);
	$tol =  (defined $tol) ? $tol  : ($m->type == double) ? 1e-8 : 1e-5;

	$err = setlaerror(NO);
	($u, $s, undef, $info) = $m->mdsvd; 
	setlaerror($err);
	barf("morth: SVD algorithm did not converge\n") if $info;

	$rank = (which($s > $tol))->dim(0) - 1;
	if(@dims == 3){
		return $rank < 0 ? PDL::Complex->null : $u(,:$rank,)->sever; 
	}
	else{
		return $rank < 0 ? null : $u(:$rank,)->sever;
	}
}

=head2 mnull

=for ref

Returns an orthonormal basis of the null space of matrix A.
Works on transposed array.

=for usage

 PDL = mnull(PDL(A), SCALAR(tol))
 tol : tolerance for determining rank, default: 1e-8 for double else 1e-5 

=for example

 my $a = sequence(10,10);
 my $null = mnull($a, 1e-8);

=cut

*mnull = \&PDL::mnull;

sub PDL::mnull {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("mnull: Require a matrix")
		unless( (@dims == 2)  || (@dims == 3));

	my ($v, $s, $rank, $info, $err);
	$tol =  (defined $tol) ? $tol  : ($m->type == double) ? 1e-8 : 1e-5;

	$err = setlaerror(NO);
	(undef, $s, $v, $info) = $m->mdsvd; 
	setlaerror($err);
	barf("mnull: SVD algorithm did not converge\n") if $info;

	#TODO: USE TRANSPOSED A
	$rank = (which($s > $tol))->dim(0);
	if (@dims == 3){
		return $rank < $dims[1] ? $v->(,,$rank:)->t : PDL::Complex->null;
	}
	else{
		return $rank < $dims[1] ? $v->xchg(0,1)->($rank:,)->sever : null;
	}
}



=head2 minv

=for ref

Computes inverse of a general square matrix using LU factorization. Supports inplace and threading.
Uses L<getrf|PDL::LinearAlgebra::Real/getrf> and L<getri|PDL::LinearAlgebra::Real/getri>
or L<cgetrf|PDL::LinearAlgebra::Complex/cgetrf> and L<cgetri|PDL::LinearAlgebra::Complex/cgetri>
from Lapack and returns C<inverse, info> in array context.

=for usage

 PDL(inv)  = minv(PDL)

=for example

 my $a = random(10,10);
 my $inv = minv($a);

=cut

sub minv($) {
	$_[0]->minv;
}
sub PDL::minv {
	my $m = shift;
	my @dims = $m->dims;
	my ($ipiv, $info);

	barf("minv: Require square array(s)")
		if( $dims[0] != $dims[1] );

	$m = $m->copy() unless $m->is_inplace(0);
	$ipiv = PDL->null;
	$info = PDL->null;

	$m->getrf($ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("minv: Factor(s) U (PDL(s) @list) is/are singular(s) (after getrf factorization): \$info = $info");
	}
	$m->getri($ipiv,$info);
	return wantarray ? ($m, $info) : $m;
}
sub PDL::Complex::minv {
	my $m = shift;
	my @dims = $m->dims;
	my ($ipiv, $info);

	barf("minv: Require square array(s)")
		if( $dims[1] != $dims[2] );

	$m = $m->copy() unless $m->is_inplace(0);
	$ipiv = PDL->null;
	$info = PDL->null;

	$m->cgetrf($ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("minv: Factor(s) U (PDL(s) @list) is/are singular(s) (after cgetrf factorization) : \$info = $info");
	}
	else{
		$m->cgetri($ipiv,$info);
	}
	return wantarray ? ($m, $info) : $m;
}

=head2 mtriinv

=for ref

Computes inverse of a triangular matrix. Supports inplace and threading.
Uses L<trtri|PDL::LinearAlgebra::Real/trtri> or L<ctrtri|PDL::LinearAlgebra::Complex/ctrtri> from Lapack.
Returns C<inverse, info> in array context.

=for usage

 (PDL, PDL(info))) = mtriinv(PDL, SCALAR(uplo), SCALAR|PDL(diag))
 uplo : UPPER = 0 | LOWER = 1, default = 0
 diag : UNITARY DIAGONAL = 1, default = 0

=for example

 # Assume $a is upper triangular
 my $a = random(10,10);
 my $inv = mtriinv($a);

=cut


sub mtriinv{
	my $m = shift;
	$m->mtriinv(@_);
}

sub PDL::mtriinv{
	my $m = shift;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my $diag = shift;

	my(@dims) = $m->dims;

	barf("mtriinv: Require square array(s)")
		if( $dims[0] != $dims[1] );

	$m = $m->copy() unless $m->is_inplace(0);
	my $info = PDL->null;
	$m->trtri($upper, $diag, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mtriinv: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}
	return wantarray ? ($m, $info) : $m;
}

sub PDL::Complex::mtriinv{
	my $m = shift;
	my $upper = @_ ? (1 - shift) : pdl (long,1);
	my $diag = shift;

	my(@dims) = $m->dims;

	barf("mtriinv: Require square array(s)")
		if( $dims[1] != $dims[2] );

	$m = $m->copy() unless $m->is_inplace(0);
	my $info = PDL->null;
	$m->ctrtri($upper, $diag, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mtriinv: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}
	return wantarray ? ($m, $info) : $m;
}

=head2 msyminv

=for ref

Computes inverse of a symmetric square matrix using the Bunch-Kaufman diagonal pivoting method.
Supports inplace and threading.
Uses L<sytrf|PDL::LinearAlgebra::Real/sytrf> and L<sytri|PDL::LinearAlgebra::Real/sytri> or
L<csytrf|PDL::LinearAlgebra::Complex/csytrf> and L<csytri|PDL::LinearAlgebra::Complex/csytri>
from Lapack and returns C<inverse, info> in array context.

=for usage

 (PDL, (PDL(info))) = msyminv(PDL, SCALAR|PDL(uplo))
 uplo : UPPER = 0 | LOWER = 1, default = 0

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my $inv = msyminv($a);

=cut

sub msyminv {
	my $m = shift;
	$m->msyminv(@_);
}

sub PDL::msyminv {
	my $m = shift;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my ($ipiv , $info);
	my(@dims) = $m->dims;

	barf("msyminv: Require square array(s)")
		if( $dims[0] != $dims[1] );

	$m = $m->copy() unless $m->is_inplace(0);

	$ipiv = zeroes(long, @dims[1..$#dims]);
	@dims = @dims[2..$#dims];
	$info = @dims ? zeroes(long,@dims) : pdl(long,0);

	$m->sytrf($upper, $ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msyminv: Block diagonal matrix D (PDL(s) @list) is/are singular(s) (after sytrf factorization): \$info = $info");
	}
	else{
		$m->sytri($upper,$ipiv,$info);
                $m = $m->t->tritosym($upper);
	}
	return wantarray ? ($m, $info) : $m;
}

sub PDL::Complex::msyminv {
	my $m = shift;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my ($ipiv , $info);
	my(@dims) = $m->dims;

	barf("msyminv: Require square array(s)")
		if( $dims[1] != $dims[2] );

	$m = $m->copy() unless $m->is_inplace(0);

	$ipiv = zeroes(long, @dims[2..$#dims]);
	@dims = @dims[3..$#dims];
	$info = @dims ? zeroes(long,@dims) : pdl(long,0);

	$m->csytrf($upper, $ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msyminv: Block diagonal matrix D (PDL(s) @list) is/are singular(s) (after csytrf factorization): \$info = $info");
	}
	else{
		$m->csytri($upper,$ipiv,$info);
                $m = $m->xchg(1,2)->tritosym($upper, 0);
	}
	return wantarray ? ($m, $info) : $m;
}

=head2 mposinv

=for ref

Computes inverse of a symmetric positive definite square matrix using Cholesky factorization.
Supports inplace and threading.
Uses L<potrf|PDL::LinearAlgebra::Real/potrf> and L<potri|PDL::LinearAlgebra::Real/potri> or
L<cpotrf|PDL::LinearAlgebra::Complex/cpotrf> and L<cpotri|PDL::LinearAlgebra::Complex/cpotri>
from Lapack and returns C<inverse, info> in array context.

=for usage

 (PDL, (PDL(info))) = mposinv(PDL, SCALAR|PDL(uplo))
 uplo : UPPER = 0 | LOWER = 1, default = 0

=for example

 # Assume $a is symmetric positive definite
 my $a = random(10,10);
 $a = $a->crossprod($a);
 my $inv = mposinv($a);

=cut

sub mposinv {
	my $m = shift;
	$m->mposinv(@_);
}

sub PDL::mposinv {
	my $m = shift;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my(@dims) = $m->dims;

	barf("mposinv: Require square array(s)")
		unless( $dims[0] == $dims[1] );

	$m = $m->copy() unless $m->is_inplace(0);
	@dims = @dims[2..$#dims];
	my $info = @dims ? zeroes(long,@dims) : pdl(long,0);

	$m->potrf($upper, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mposinv: matrix (PDL(s) @list) is/are not positive definite(s) (after potrf factorization): \$info = $info");
	}
	else{
		$m->potri($upper, $info);
	}
	return wantarray ? ($m, $info) : $m;
}

sub PDL::Complex::mposinv {
	my $m = shift;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my(@dims) = $m->dims;


	barf("mposinv: Require square array(s)")
		unless( $dims[1] == $dims[2] );

	$m = $m->copy() unless $m->is_inplace(0);
	@dims = @dims[3..$#dims];
	my $info = @dims ? zeroes(long,@dims) : pdl(long,0);

	$m->cpotrf($upper, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mposinv: matrix (PDL(s) @list) is/are not positive definite(s) (after cpotrf factorization): \$info = $info");
	}
	else{
		$m->cpotri($upper, $info);
	}
	return wantarray ? ($m, $info) : $m;
}

=head2 mpinv

=for ref

Computes pseudo-inverse (Moore-Penrose) of a general matrix.
Works on transposed array.

=for usage

 PDL(pseudo-inv)  = mpinv(PDL, SCALAR(tol))
 TOL:	tolerance value, default : mnorm(dims(PDL),'inf') * mnorm(PDL) * EPS

=for example

 my $a = random(5,10);
 my $inv = mpinv($a);

=cut

*mpinv = \&PDL::mpinv;

sub PDL::mpinv{
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("mpinv: Require a matrix")
		unless( @dims == 2 or @dims == 3 );
	
	my ($ind, $cind, $u, $s, $v, $info, $err);

	$err = setlaerror(NO);
	#TODO: don't transpose
	($u, $s, $v, $info) = $m->mdsvd(2);
	setlaerror($err);
	laerror("mpinv: SVD algorithm did not converge\n") if $info;

	unless (defined $tol){
		$tol =  ($dims[-1] > $dims[-2] ? $dims[-1] : $dims[-2]) * $s((0)) * lamch(pdl($m->type,3));
	}


	($ind, $cind) = which_both( $s > $tol );
	$s->index($cind) .= 0 if defined $cind;
	$s->index($ind)  .= 1/$s->index($ind) ;

	$ind =  (@dims == 3) ? ($v->t *  $s->r2C ) x $u->t : 
			($v->xchg(0,1) *  $s ) x $u->xchg(0,1);
	return wantarray ? ($ind, $info) : $ind;

}



=head2 mlu

=for ref

Computes LU factorization.
Uses L<getrf|PDL::LinearAlgebra::Real/getrf> or L<cgetrf|PDL::LinearAlgebra::Complex/cgetrf>
from Lapack and returns L, U, pivot and info.
Works on transposed array.

=for usage

 (PDL(l), PDL(u), PDL(pivot), PDL(info)) = mlu(PDL)

=for example

 my $a = random(10,10);
 ($l, $u, $pivot, $info) = mlu($a);

=cut

*mlu = \&PDL::mlu;

sub PDL::mlu {
	my $m = shift;
	my(@dims) = $m->dims;
	barf("mlu: Require a matrix")
		unless((@dims == 2) || (@dims == 3));
	my ($ipiv, $info, $l, $u);

        $m = $m->copy;
	$info = pdl(long ,0);
	$ipiv = zeroes(long, ($dims[-2] > $dims[-1] ? $dims[-1]: $dims[-2]));

	if (@dims == 3){
		$m->t->cgetrf($ipiv,$info);
		if($info > 0) {
			$info--;
			laerror("mlu: Factor U is singular: U($info,$info) = 0 (after cgetrf factorization)");
			$u = $l = $m;			
		}
		else{
			$u = $m->mtri;
			$l = $m->mtri(1);
			if ($dims[-1] > $dims[-2]){
				$u = $u(,,:($dims[0]-1));
				$l((0), :($dims[0]-1), :($dims[0]-1))->diagonal(0,1) .= 1;
				$l((1), :($dims[0]-1), :($dims[0]-1))->diagonal(0,1) .= 0;
			}
			elsif($dims[-1] < $dims[-2]){
				$l = $l(,:($dims[1]-1),);
			 	$l((0),,)->diagonal(0,1).=1;
			 	$l((1),,)->diagonal(0,1).=0;
			}
			else{
			 	$l((0),,)->diagonal(0,1).=1;
			 	$l((1),,)->diagonal(0,1).=0;
			}
		}
	}
	else{
		$m->t->getrf($ipiv,$info);
		if($info > 0) {
			$info--;
			laerror("mlu: Factor U is singular: U($info,$info) = 0 (after getrf factorization)");
			$u = $l = $m;
		}
		else{
			$u = $m->mtri;
			$l = $m->mtri(1);
			if ($dims[1] > $dims[0]){
				$u = $u(,:($dims[0]-1))->sever;
				$l( :($dims[0]-1), :($dims[0]-1))->diagonal(0,1) .= 1;
			}
			elsif($dims[1] < $dims[0]){
				$l = $l(:($dims[1]-1),)->sever;
				$l->diagonal(0,1) .= 1;
			}
			else{
			 	$l->diagonal(0,1).=1;
			}
		}
	}
	$l, $u, $ipiv, $info;
}

=head2 mchol

=for ref

Computes Cholesky decomposition of a symmetric matrix also knows as symmetric square root.
If inplace flag is set, overwrite  the leading upper or lower triangular part of A else returns
triangular matrix. Returns C<cholesky, info> in array context.
Supports threading.
Uses L<potrf|PDL::LinearAlgebra::Real/potrf> or L<cpotrf|PDL::LinearAlgebra::Complex/cpotrf> from Lapack.

=for usage

 PDL(Cholesky) = mchol(PDL, SCALAR)
 SCALAR : UPPER = 0 | LOWER = 1, default = 0

=for example

 my $a = random(10,10);
 $a = crossprod($a, $a);
 my $u  = mchol($a);

=cut

sub mchol {
	my $m = shift;
	$m->mchol(@_);
}

sub PDL::mchol {
	my($m, $upper) = @_;
	my(@dims) = $m->dims;
	barf("mchol: Require square array(s)")
		if ( $dims[0] != $dims[1] );

	my ($uplo, $info);

	$m = $m->mtri($upper) unless $m->is_inplace(0);
	@dims = @dims[2..$#dims];
	$info = @dims ? zeroes(long,@dims) : pdl(long,0);
	$uplo =  1 - $upper;
	$m->potrf($uplo,$info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mchol: matrix (PDL(s) @list) is/are not positive definite(s) (after potrf factorization): \$info = $info");
	}
	return wantarray ? ($m, $info) : $m;
	
}

sub PDL::Complex::mchol {
	my($m, $upper) = @_;
	my(@dims) = $m->dims;
	barf("mchol: Require square array(s)")
		if ( $dims[1] != $dims[2] );

	my ($uplo, $info);

	$m = $m->mtri($upper) unless $m->is_inplace(0);
	@dims = @dims[3..$#dims];
	$info = @dims ? zeroes(long,@dims) : pdl(long,0);
	$uplo =  1 - $upper;
	$m->cpotrf($uplo,$info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mchol: matrix (PDL(s) @list) is/are not positive definite(s) (after cpotrf factorization): \$info = $info");
	}
	return wantarray ? ($m, $info) : $m;
	
}

=head2 mhessen

=for ref

Reduces a square matrix to Hessenberg form H and orthogonal matrix Q.

It reduces a general matrix A to upper Hessenberg form H by an orthogonal
similarity transformation:

	Q' x A x Q = H

or

	A = Q x H x Q'

Uses L<gehrd|PDL::LinearAlgebra::Real/gehrd> and L<orghr|PDL::LinearAlgebra::Real/orghr> or
L<cgehrd|PDL::LinearAlgebra::Complex/cgehrd> and L<cunghr|PDL::LinearAlgebra::Complex/cunghr>
from Lapack and returns C<H> in scalar context else C<H> and C<Q>.
Works on transposed array.

=for usage

 (PDL(h), (PDL(q))) = mhessen(PDL)

=for example

 my $a = random(10,10);
 ($h, $q) = mhessen($a);

=cut

*mhessen = \&PDL::mhessen;

sub PDL::mhessen {
	my $m = shift;
	my(@dims) = $m->dims;
	barf("mhessen: Require a square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($info, $tau, $h, $q);
	
	$m = $m->t->copy;
	$info = pdl(long, 0);
	if(@dims == 3){
		$tau = zeroes($m->type, 2, ($dims[-2]-1));
		$m->cgehrd(1,$dims[-2],$tau,$info);
		if (wantarray){
			$q = $m->copy;
			$q->cunghr(1, $dims[-2], $tau, $info);
		}
		$m = $m->xchg(1,2);
		$h = $m->mtri;
		$h((0),:-2, 1:)->diagonal(0,1) .= $m((0),:-2, 1:)->diagonal(0,1);
		$h((1),:-2, 1:)->diagonal(0,1) .= $m((1),:-2, 1:)->diagonal(0,1);		
	}
	else{
		$tau = zeroes($m->type, ($dims[0]-1));
		$m->gehrd(1,$dims[0],$tau,$info);
		if (wantarray){
			$q = $m->copy;
			$q->orghr(1, $dims[0], $tau, $info);
		}
		$m = $m->xchg(0,1);
		$h = $m->mtri;
		$h(:-2, 1:)->diagonal(0,1) .= $m(:-2, 1:)->diagonal(0,1);
	}
	wantarray ? return ($h, $q->xchg(-2,-1)->sever) : $h;
}


=head2 mschur

=for ref

Computes Schur form, works inplace.

	A = Z x T x Z'

Supports threading for unordered eigenvalues.
Uses L<gees|PDL::LinearAlgebra::Real/gees> or L<cgees|PDL::LinearAlgebra::Complex/cgees>
from Lapack and returns schur(T) in scalar context.
Works on tranposed array(s).

=for usage

 ( PDL(schur), (PDL(eigenvalues), (PDL(left schur vectors), PDL(right schur vectors), $sdim), $info) ) = mschur(PDL(A), SCALAR(schur vector),SCALAR(left eigenvector), SCALAR(right eigenvector),SCALAR(select_func), SCALAR(backtransform), SCALAR(norm))
 schur vector	     : Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 left eigenvector    : Left eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right eigenvector   : Right eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 select_func	     : Select_func is used to select eigenvalues to sort
		       to the top left of the Schur form.
		       An eigenvalue is selected if PerlInt select_func(PDL::Complex(w)) is true;
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func(PDL::Complex(w)) = 1 after ordering, since
		       ordering may change the value of complex eigenvalues
		       (especially if the eigenvalue is ill-conditioned).
		       All eigenvalues/vectors are selected if select_func is undefined. 
 backtransform	     : Whether or not backtransforms eigenvectors to those of A.
 		       Only supported if schur vectors are computed, default = 1.
 norm                : Whether or not computed eigenvectors are normalized to have Euclidean norm equal to
		       1 and largest component real, default = 1

 Returned values     :
		       Schur form T (SCALAR CONTEXT),
		       eigenvalues,
		       Schur vectors (Z) if requested,
		       left eigenvectors if requested
		       right eigenvectors if requested
		       sdim: Number of eigenvalues selected if select_func is defined.
		       info: Info output from gees/cgees.	    	

=for example

 my $a = random(10,10);
 my $schur  = mschur($a);
 sub select{
 	my $m = shift;
	# select "discrete time" eigenspace
 	return $m->Cabs < 1 ? 1 : 0;
 }
 my ($schur,$eigen, $svectors,$evectors)  = mschur($a,1,1,0,\&select); 

=cut


sub mschur{
	my $m = shift;
	$m->mschur(@_);

}

sub PDL::mschur{
	my ($m, $jobv, $jobvl, $jobvr, $select_func, $mult,$norm) = @_;
	my(@dims) = $m->dims;

	barf("mschur: Require square array(s)")
		unless($dims[0] == $dims[1]);
	barf("mschur: thread doesn't supported for selected vectors")
		if ($select_func && @dims > 2 && ($jobv == 2 || $jobvl == 2 || $jobvr == 2));

       	my ($w, $v, $info, $type, $select,$sdim, $vr,$vl, $mm, @ret, $select_f, $wi, $wtmp);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
       	$jobv = $jobvl = $jobvr = 0 unless wantarray;
	$type = $m->type;
	$select = $select_func ? pdl(long,1) : pdl(long,0);

	$info = null;
	$sdim = null;
	$wtmp = null;
       	$wi = null;

	$mm = $m->is_inplace ? $m->xchg(0,1) : $m->xchg(0,1)->copy;
	if ($select_func){
	 	$select_f= sub{
	 		&$select_func(PDL::Complex::complex(pdl($type,@_[0..1])));
		}; 
	}
	$v = $jobv ? PDL::new_from_specification('PDL', $type, $dims[1], $dims[1],@dims[2..$#dims]) : 
				pdl($type,0);
	$mm->gees( $jobv, $select, $wtmp, $wi, $v, $sdim,$info, $select_f);

	if ($info->max > 0 && $_laerror){
		my ($index, @list);
		$index = which((($info > 0)+($info <=$dims[0]))==2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mschur: The QR algorithm failed to converge for matrix (PDL(s) @list): \$info = $info");
			print ("Returning converged eigenvalues\n");
		}
		if ($select_func){
			$index = which((($info > 0)+($info == ($dims[0]+1) ))==2);
			unless ($index->isempty){
				@list = $index->list;
				laerror("mschur: The eigenvalues could not be reordered because some\n".
                			     "eigenvalues were too close to separate (the problem".
	        		             "is very ill-conditioned) for PDL(s) @list: \$info = $info");
			}
			$index = which((($info > 0)+($info > ($dims[0]+1) ))==2);
			unless ($index->isempty){
				@list = $index->list;
				warn("mschur: The Schur form no longer satisfy select_func = 1\n because of roundoff".
					"or underflow (PDL(s) @list)\n");
			}
		}
	}
	if ($select_func){
		if ($jobvl == 2){
			if(!$sdim){
				push @ret, PDL::Complex->null;
				$jobvl = 0;
			}
		}
		if ($jobvr == 2){
			if(!$sdim){
				push @ret, PDL::Complex->null;
				$jobvr = 0;
			}
		}
		push @ret, $sdim;
	}
	if ($jobvl || $jobvr){
		my ($sel, $job, $wtmpi, $wtmpr, $sdims);
		unless ($jobvr && $jobvl){
			$job = $jobvl ? 2 : 1;
		}
		if ($select_func){
			if ($jobvl == 1 || $jobvr == 1 || $mult){ 
				$sdims = null;
				if ($jobv){
					$vr = $v->copy if $jobvr;
					$vl = $v->copy if $jobvl;
				}
				else{
					$vr = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1],@dims[2..$#dims]) if $jobvr;
					$vl = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1],@dims[2..$#dims]) if $jobvl;
					$mult = 0;
				}
				$mm->trevc($job, $mult, $sel, $vl, $vr, $sdims, my $infos=null);
				if ($jobvr){
					if($norm){
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
						bless $vr, 'PDL::Complex';
						unshift @ret, $jobvr == 2 ? $vr(,,:($sdim-1))->norm(1,1) : $vr->norm(1,1);

					}
					else{
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						unshift @ret, $jobvr == 2 ? $vr(,:($sdim-1))->sever : $vr;
					}
				}
				if ($jobvl){
					if($norm){
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
						bless $vl, 'PDL::Complex';
						unshift @ret, $jobvl == 2 ? $vl(,,:($sdim-1))->norm(1,1) : $vl->norm(1,1);
					}
					else{
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						unshift @ret, $jobvl == 2 ? $vl(,:($sdim-1))->sever : $vl;
					}
				}
			}
			else{
				$vr = PDL::new_from_specification('PDL', $type, $dims[1], $sdim) if $jobvr;
				$vl = PDL::new_from_specification('PDL', $type, $dims[1], $sdim) if $jobvl;
				$sel = zeroes($dims[1]);
				$sel(:($sdim-1)) .= 1; 
				$mm->trevc($job, 2, $sel, $vl, $vr, $sdim, my $infos = null);
				$wtmpr = $wtmp(:($sdim-1));
				$wtmpi = $wi(:($sdim-1));
				if ($jobvr){
					if ($norm){
						(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr,1);
						bless $vr, 'PDL::Complex';
						unshift @ret, $vr->norm(1,1);
					}
					else{
						(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						unshift @ret,$vr;
					}
				}
				if ($jobvl){
					if ($norm){
						(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl,1);
						bless $vl, 'PDL::Complex';
						unshift @ret, $vl->norm(1,1);

					}
					else{
						(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						unshift @ret, $vl;
					}
				}
			}
		}
		else{
			if ($jobv){
				$vr = $v->copy if $jobvr;
				$vl = $v->copy if $jobvl;
			}
			else{
				$vr = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1],@dims[2..$#dims]) if $jobvr;
				$vl = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1],@dims[2..$#dims]) if $jobvl;
				$mult = 0;
			}
			$mm->trevc($job, $mult, $sel, $vl, $vr, $sdim, my $infos=null);
			if ($jobvr){
				if ($norm){
					(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
					bless $vr, 'PDL::Complex';
					unshift @ret, $vr->norm(1,1);
				}
				else{
					(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
					bless $vr, 'PDL::Complex';
					unshift @ret, $vr;
				}
			}
			if ($jobvl){
				if ($norm){
					(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
					bless $vl, 'PDL::Complex';
					unshift @ret, $vl->norm(1,1);
				}
				else{
					(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
					bless $vl, 'PDL::Complex';
					unshift @ret, $vl;
				}
			}
		}
	}
	$w = PDL::Complex::ecplx ($wtmp, $wi);

	if ($jobv == 2 && $select_func) {
		$v = $sdim > 0 ? $v->xchg(0,1)->(:($sdim-1),)->sever : null;
		unshift @ret,$v;
	}
	elsif($jobv){
		$v =  $v->xchg(0,1)->sever;
		unshift @ret,$v;
	}
	$m = $mm->xchg(0,1)->sever unless $m->is_inplace(0);
	return wantarray ? ($m, $w, @ret, $info) : $m;
		
}

sub PDL::Complex::mschur {
	my($m, $jobv, $jobvl, $jobvr, $select_func, $mult, $norm) = @_;
	my(@dims) = $m->dims;

	barf("mschur: Require square array(s)")
		unless($dims[1] == $dims[2]);
	barf("mschur: thread doesn't supported for selected vectors")
		if ($select_func && @dims > 3 && ($jobv == 2 || $jobvl == 2 || $jobvr == 2));

       	my ($w, $v, $info, $type, $select,$sdim, $vr,$vl, $mm, @ret);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
       	$jobv = $jobvl = $jobvr = 0 unless wantarray;
	$type = $m->type;
       	$select = $select_func ? pdl(long,1) : pdl(long,0);

       	$info = null;
       	$sdim = null;

	$mm = $m->is_inplace ? $m->xchg(1,2) : $m->xchg(1,2)->copy;
	$w = PDL::Complex->null;
	$v = $jobv ? PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1],@dims[3..$#dims]) : 
				pdl($type,[0,0]);

	$mm->cgees( $jobv, $select, $w, $v, $sdim, $info, $select_func);

	if ($info->max > 0 && $_laerror){
		my ($index, @list);
		$index = which((($info > 0)+($info <=$dims[1]))==2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mschur: The QR algorithm failed to converge for matrix (PDL(s) @list): \$info = $info");
			print ("Returning converged eigenvalues\n");
		}
		if ($select_func){
			$index = which((($info > 0)+($info == ($dims[1]+1) ))==2);
			unless ($index->isempty){
				@list = $index->list;
				laerror("mschur: The eigenvalues could not be reordered because some\n".
                			     "eigenvalues were too close to separate (the problem".
	        		             "is very ill-conditioned) for PDL(s) @list: \$info = $info");
			}
			$index = which((($info > 0)+($info > ($dims[1]+1) ))==2);
			unless ($index->isempty){
				@list = $index->list;
				warn("mschur: The Schur form no longer satisfy select_func = 1\n because of roundoff".
					"or underflow (PDL(s) @list)\n");
			}
		}
	}

	if ($select_func){
		if ($jobvl == 2){
			if (!$sdim){
				push @ret, PDL::Complex->null;
				$jobvl = 0;
			}
		}
		if ($jobvr == 2){
			if (!$sdim){
				push @ret, PDL::Complex->null;
				$jobvr = 0;
			}
		}
		push @ret, $sdim;
	}
	if ($jobvl || $jobvr){
		my ($sel, $job, $sdims);
		unless ($jobvr && $jobvl){
			$job = $jobvl ? 2 : 1;
		}
		if ($select_func){
			if ($jobvl == 1 || $jobvr == 1 || $mult){ 
				$sdims = null;
				if ($jobv){
					$vr = $v->copy if $jobvr;
					$vl = $v->copy if $jobvl;
				}
				else{
					$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1],@dims[3..$#dims]) if $jobvr;
					$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1],@dims[3..$#dims]) if $jobvl;
					$mult = 0;
				}
				$mm->ctrevc($job, $mult, $sel, $vl, $vr, $sdims, my $infos=null);
				if ($jobvr){
					if ($jobvr == 2){
						unshift @ret, $norm ? $vr(,,:($sdim-1))->norm(1,1) :
									$vr(,,:($sdim-1))->xchg(1,2)->sever;
					}
					else{
						unshift @ret, $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
					}
				}
				if ($jobvl){
					if ($jobvl == 2){
						unshift @ret, $norm ? $vl(,,:($sdim-1))->norm(1,1) :
									$vl(,,:($sdim-1))->xchg(1,2)->sever;
					}
					else{
						unshift @ret, $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
					}
				}
			}
			else{
				$vr = PDL::new_from_specification('PDL::Complex', $type, 2,$dims[1], $sdim) if $jobvr;
				$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $sdim) if $jobvl;
				$sel = zeroes($dims[1]);
				$sel(:($sdim-1)) .= 1; 
				$mm->ctrevc($job, 2, $sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvr){
					unshift @ret, $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
				}
				if ($jobvl){
					unshift @ret, $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
				}
			}
		}
		else{
			if ($jobv){
				$vr = $v->copy if $jobvr;
				$vl = $v->copy if $jobvl;
			}
			else{
				$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1],@dims[3..$#dims]) if $jobvr;
				$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1],@dims[3..$#dims]) if $jobvl;
				$mult = 0;
			}
			$mm->ctrevc($job, $mult, $sel, $vl, $vr, $sdim, my $infos=null);
			if ($jobvl){
				push @ret, $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
			}
			if ($jobvr){
				push @ret, $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
			}
		}
	}
	if ($jobv == 2 && $select_func) {
		$v = $sdim > 0 ? $v->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
		unshift @ret,$v;
	}
	elsif($jobv){
		$v =  $v->xchg(1,2)->sever;
		unshift @ret,$v;
	}
	$m = $mm->xchg(1,2)->sever unless $m->is_inplace(0);
	return wantarray ? ($m, $w, @ret, $info) : $m;
		
}



=head2 mschurx

=for ref

Computes Schur form, works inplace.
Uses L<geesx|PDL::LinearAlgebra::Real/geesx> or L<cgeesx|PDL::LinearAlgebra::Complex/cgeesx>
from Lapack and returns schur(T) in scalar context.
Works on transposed array.

=for usage

 ( PDL(schur) (,PDL(eigenvalues))  (, PDL(schur vectors), HASH(result)) ) = mschurx(PDL, SCALAR(schur vector), SCALAR(left eigenvector), SCALAR(right eigenvector),SCALAR(select_func), SCALAR(sense), SCALAR(backtransform), SCALAR(norm))
 schur vector	     : Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 left eigenvector    : Left eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right eigenvector   : Right eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 select_func         : Select_func is used to select eigenvalues to sort
		       to the top left of the Schur form.
		       An eigenvalue is selected if PerlInt select_func(PDL::Complex(w)) is true;
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func(PDL::Complex(w)) = 1 after ordering, since
		       ordering may change the value of complex eigenvalues
		       (especially if the eigenvalue is ill-conditioned).
		       All  eigenvalues/vectors are selected if select_func is undefined. 
 sense		     : Determines which reciprocal condition numbers will be computed.
			0: None are computed
			1: Computed for average of selected eigenvalues only
			2: Computed for selected right invariant subspace only
			3: Computed for both
			If select_func is undefined, sense is not used.
 backtransform	     : Whether or not backtransforms eigenvectors to those of A.
 		       Only supported if schur vector are computed, default = 1
 norm                : Whether or not computed eigenvectors are normalized to have Euclidean norm equal to
		       1 and largest component real, default = 1

 Returned values     :
		       Schur form T (SCALAR CONTEXT),
		       eigenvalues,
		       Schur vectors if requested,
		       HASH{VL}: left eigenvectors if requested
		       HASH{VR}: right eigenvectors if requested
		       HASH{info}: info output from gees/cgees.
		       if select_func is defined:
			HASH{n}: number of eigenvalues selected,
			HASH{rconde}: reciprocal condition numbers for the average of 
			the selected eigenvalues if requested,
			HASH{rcondv}: reciprocal condition numbers for the selected 
			right invariant subspace if requested.

=for example

 my $a = random(10,10);
 my $schur  = mschurx($a);
 sub select{
 	my $m = shift;
	# select "discrete time" eigenspace
 	return $m->Cabs < 1 ? 1 : 0;
 }
 my ($schur,$eigen, $vectors,%ret)  = mschurx($a,1,0,0,\&select); 

=cut


*mschurx = \&PDL::mschurx;

sub PDL::mschurx{
	my($m, $jobv, $jobvl, $jobvr, $select_func, $sense, $mult,$norm) = @_;
	my(@dims) = $m->dims;

	barf("mschur: Require a square matrix")
		unless( ( (@dims == 2)|| (@dims == 3) )&& $dims[-1] == $dims[-2]);

       	my ($w, $v, $info, $type, $select, $sdim, $rconde, $rcondv, %ret, $mm, $vl, $vr);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
       	$jobv = $jobvl = $jobvr = 0 unless wantarray;
	$type = $m->type;
	if ($select_func){
       		$select =  pdl(long 1);
       	}
       	else{
		$select =  pdl(long,0);
		$sense = pdl(long,0);
	}

	$info = null;
	$sdim = null;
	$rconde = null;
	$rcondv = null;
	$mm = $m->is_inplace ? $m->xchg(-1,-2) : $m->xchg(-1,-2)->copy;

	if (@dims == 3){
		$w = PDL::Complex->null;
		$v = $jobv ? PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]) : 
					pdl($type,[0,0]);
		$mm->cgeesx( $jobv, $select, $sense, $w, $v, $sdim, $rconde, $rcondv,$info, $select_func);

		if ($info){
			if ($info < $dims[1]){
				laerror("mschurx: The QR algorithm failed to converge");
				print ("Returning converged eigenvalues\n") if $_laerror;
			}
			laerror("mschurx: The eigenvalues could not be reordered because some\n".
	                	     "eigenvalues were too close to separate (the problem".
	        	             "is very ill-conditioned)")
				if $info == ($dims[1] + 1);
			warn("mschurx: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n")
					if ($info > ($dims[1] + 1) and $_laerror);
		}

		if ($select_func){
			if(!$sdim){
				if ($jobvl == 2){
					$ret{VL} = PDL::Complex->null;
					$jobvl = 0;
				}
				if ($jobvr == 2){
					$ret{VR} = PDL::Complex->null;
					$jobvr = 0;
				}
			}
			$ret{n} = $sdim;
		}
		if ($jobvl || $jobvr){
			my ($sel, $job, $sdims);
			unless ($jobvr && $jobvl){
				$job = $jobvl ? 2 : 1;
			}
			if ($select_func){
				if ($jobvl == 1 || $jobvr == 1 || $mult){ 
					$sdims = null;
					if ($jobv){
						$vr = $v->copy if $jobvr;
						$vl = $v->copy if $jobvl;
					}
					else{
						$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]) if $jobvr;
						$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]) if $jobvl;
						$mult = 0;
					}
					$mm->ctrevc($job, $mult, $sel, $vl, $vr, $sdims, my $infos=null);
					if ($jobvr){
						if ($jobvr == 2){
							$ret{VR} = $norm ? $vr(,,:($sdim-1))->norm(1,1) :
										$vr(,,:($sdim-1))->xchg(1,2)->sever;
						}
						else{
							$ret{VR} = $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
						}
					}
					if ($jobvl){
						if ($jobvl == 2){
							$ret{VL} = $norm ? $vl(,,:($sdim-1))->norm(1,1) :
										$vl(,,:($sdim-1))->xchg(1,2)->sever;
						}
						else{
							$ret{VL} = $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
						}
					}
				}
				else{
					$vr = PDL::new_from_specification('PDL::Complex', $type, 2,$dims[1], $sdim) if $jobvr;
					$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $sdim) if $jobvl;
					$sel = zeroes($dims[1]);
					$sel(:($sdim-1)) .= 1; 
					$mm->ctrevc($job, 2, $sel, $vl, $vr, $sdim, my $infos=null);
					if ($jobvr){
						$ret{VL} = $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
					}
					if ($jobvl){
						$ret{VL} = $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
					}
				}
			}
			else{
				if ($jobv){
					$vr = $v->copy if $jobvr;
					$vl = $v->copy if $jobvl;
				}
				else{
					$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]) if $jobvr;
					$vl = PDL::new_from_specification('PDL::Complex', $type, $dims[1], 2, $dims[1]) if $jobvl;
					$mult = 0;
				}
				$mm->ctrevc($job, $mult, $sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvl){
					$ret{VL} = $norm ? $vl->norm(1,1) : $vl->xchg(1,2)->sever;
				}
				if ($jobvr){
					$ret{VR} = $norm ? $vr->norm(1,1) : $vr->xchg(1,2)->sever;
				}
			}
		}
		if ($jobv == 2 && $select_func) {
			$v = $sdim > 0 ? $v->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
		}
		elsif($jobv){
			$v =  $v->xchg(1,2)->sever;
		}

	}
	else{
		my ($select_f, $wi, $wtmp);
		if ($select_func){
			no strict 'refs';
		 	$select_f= sub{
				&$select_func(PDL::Complex::complex(pdl($type,$_[0],$_[1])));
			}; 
		}
		$wi = null; 
	       	$wtmp = null;
		$v = $jobv ? PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) : 
					pdl($type,0);
		$mm->geesx( $jobv, $select, $sense, $wtmp, $wi, $v, $sdim, $rconde, $rcondv,$info, $select_f);
		if ($info){
			if ($info < $dims[0]){
				laerror("mschurx: The QR algorithm failed to converge");
				print ("Returning converged eigenvalues\n") if $_laerror;
			}
			laerror("mschurx: The eigenvalues could not be reordered because some\n".
	                	     "eigenvalues were too close to separate (the problem".
	        	             "is very ill-conditioned)")
				if $info == ($dims[0] + 1);
			warn("mschurx: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n")
					if ($info > ($dims[0] + 1) and $_laerror);
		}

		if ($select_func){
			if(!$sdim){
				if ($jobvl == 2){
					$ret{VL} = null;
					$jobvl = 0;
				}
				if ($jobvr == 2){
					$ret{VR} = null;
					$jobvr = 0;
				}
			}
			$ret{n} = $sdim;
		}
		if ($jobvl || $jobvr){
			my ($sel, $job, $wtmpi, $wtmpr, $sdims);
			unless ($jobvr && $jobvl){
				$job = $jobvl ? 2 : 1;
			}
			if ($select_func){
				if ($jobvl == 1 || $jobvr == 1 || $mult){ 
					$sdims = null;
					if ($jobv){
						$vr = $v->copy if $jobvr;
						$vl = $v->copy if $jobvl;
					}
					else{
						$vr = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) if $jobvr;
						$vl = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) if $jobvl;
						$mult = 0;
					}
					$mm->trevc($job, $mult, $sel, $vl, $vr, $sdims, my $infos=null);

					if ($jobvr){
						if($norm){
							(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
							bless $vr, 'PDL::Complex';
							$ret{VR} = $jobvr == 2 ? $vr(,,:($sdim-1))->norm(1,1) : $vr->norm(1,1);
						}
						else{
							(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
							bless $vr, 'PDL::Complex';
							$ret{VR} = $jobvr == 2 ? $vr(,:($sdim-1))->sever : $vr;
						}
					}
					if ($jobvl){
						if($norm){
							(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
							bless $vl, 'PDL::Complex';
							$ret{VL}= $jobvl == 2 ? $vl(,,:($sdim-1))->norm(1,1) : $vl->norm(1,1);
						}
						else{
							(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
							bless $vl, 'PDL::Complex';
							$ret{VL}= $jobvl == 2 ? $vl(,:($sdim-1))->sever : $vl;
						}
					}
				}
				else{
					$vr = PDL::new_from_specification('PDL', $type, $dims[1], $sdim) if $jobvr;
					$vl = PDL::new_from_specification('PDL', $type, $dims[1], $sdim) if $jobvl;
					$sel = zeroes($dims[1]);
					$sel(:($sdim-1)) .= 1; 
					$mm->trevc($job, 2, $sel, $vl, $vr, $sdim, my $infos = null);
					$wtmpr = $wtmp(:($sdim-1));
					$wtmpi = $wi(:($sdim-1));

					if ($jobvr){
						if ($norm){
							(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr,1);
							bless $vr, 'PDL::Complex';
							$ret{VR} = $vr->norm(1,1);
						}
						else{
							(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr->xchg(0,1),0);
							bless $vr, 'PDL::Complex';
							$ret{VR} =  $vr;
						}
					}
					if ($jobvl){
						if ($norm){
							(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl,1);
							bless $vl, 'PDL::Complex';
							$ret{VL} = $vl->norm(1,1);
						}
						else{
							(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl->xchg(0,1),0);
							bless $vl, 'PDL::Complex';
							$ret{VL} = $vl;
						}
					}
				}
			}
			else{
				if ($jobv){
					$vr = $v->copy if $jobvr;
					$vl = $v->copy if $jobvl;
				}
				else{
					$vr = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) if $jobvr;
					$vl = PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) if $jobvl;
					$mult = 0;
				}
				$mm->trevc($job, $mult, $sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvr){
					if ($norm){
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
						bless $vr, 'PDL::Complex';
						$ret{VR} = $vr->norm(1,1);
					}
					else{
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						$ret{VR} = $vr;
					}
				}
				if ($jobvl){
					if ($norm){
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $vl->norm(1,1);
					}
					else{
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $vl;
					}
				}
			}
		}
		$w = PDL::Complex::ecplx ($wtmp, $wi);

		if ($jobv == 2 && $select_func) {
			$v = $sdim > 0 ? $v->xchg(0,1)->(:($sdim-1),) ->sever : null;
		}
		elsif($jobv){
			$v =  $v->xchg(0,1)->sever;
		}

	}

	
	$ret{info} = $info;
	if ($sense){
		if ($sense == 3){
			$ret{rconde} = $rconde;
			$ret{rcondv} = $rcondv;
		}
		else{
			$ret{rconde} = $rconde if ($sense == 1);
			$ret{rcondv} = $rcondv if ($sense == 2);
		}
	}
	$m = $mm->xchg(-1,-2)->sever unless $m->is_inplace(0);
	return wantarray ? $jobv ? ($m, $w, $v, %ret) :
				($m, $w, %ret) :
			$m;
}


# scale by max(abs(real)+abs(imag))
sub magn_norm{
	my ($m, $trans) = @_;
	
	# If trans == true => transpose output matrice
	
	
	my $ret = PDL::abs($m);
	bless $ret,'PDL';
	$ret = PDL::sumover($ret)->maximum;
	return $trans ? PDL::Complex::Cscale($m->xchg(1,2),1/$ret->dummy(0)->xchg(0,1))->reshape(-1) :
		PDL::Complex::Cscale($m,1/$ret->dummy(0))->reshape(-1);
}




#TODO: inplace ?

=head2 mgschur

=for ref

Computes generalized Schur decomposition of the pair (A,B).

	A = Q x S x Z'
	B = Q x T x Z'

Uses L<gges|PDL::LinearAlgebra::Real/gges> or L<cgges|PDL::LinearAlgebra::Complex/cgges>
from Lapack.
Works on transposed array.

=for usage

 ( PDL(schur S), PDL(schur T), PDL(alpha), PDL(beta), HASH{result}) = mgschur(PDL(A), PDL(B), SCALAR(left schur vector),SCALAR(right schur vector),SCALAR(left eigenvector), SCALAR(right eigenvector), SCALAR(select_func), SCALAR(backtransform), SCALAR(scale))
 left schur vector   : Left Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right schur vector  : Right Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 left eigenvector    : Left eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right eigenvector   : Right eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 select_func	     : Select_func is used to select eigenvalues to sort.
		       to the top left of the Schur form.
		       An eigenvalue w = wr(j)+sqrt(-1)*wi(j) is selected if
		       PerlInt select_func(PDL::Complex(alpha),PDL | PDL::Complex (beta)) is true;
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func = 1 after ordering, since
		       ordering may change the value of complex eigenvalues
		       (especially if the eigenvalue is ill-conditioned).
		       All eigenvalues/vectors are selected if select_func is undefined. 
 backtransform 	     : Whether or not backtransforms eigenvectors to those of (A,B).
 		       Only supported if right and/or left schur vector are computed, 
 scale               : Whether or not computed eigenvectors are scaled so the largest component
		       will have abs(real part) + abs(imag. part) = 1, default = 1

 Returned values     :
		       Schur form S,
		       Schur form T,
		       alpha,
		       beta (eigenvalues = alpha/beta),
		       HASH{info}: info output from gges/cgges.
		       HASH{SL}: left Schur vectors if requested
		       HASH{SR}: right Schur vectors if requested
		       HASH{VL}: left eigenvectors if requested
		       HASH{VR}: right eigenvectors if requested
		       HASH{n} : Number of eigenvalues selected if select_func is defined.

=for example

 my $a = random(10,10);
 my $b = random(10,10);
 my ($S,$T) = mgschur($a,$b);
 sub select{
 	my ($alpha,$beta) = @_;
 	return $alpha->Cabs < abs($beta) ? 1 : 0;
 }
 my ($S, $T, $alpha, $beta, %res)  = mgschur( $a, $b, 1, 1, 1, 1,\&select); 

=cut


sub mgschur{
	my $m = shift;
	$m->mgschur(@_);
}

sub PDL::mgschur{
	my($m, $p, $jobvsl, $jobvsr, $jobvl, $jobvr, $select_func, $mult, $norm) = @_;
	my @mdims  = $m->dims;
	my @pdims  = $p->dims;

	barf("mgschur: Require square matrices of same order")
		unless( $mdims[0] == $mdims[1] && $pdims[0] == $pdims[1] && $mdims[0] == $pdims[0]);
	barf("mgschur: thread doesn't supported for selected vectors")
		if ($select_func && ((@mdims > 2) || (@pdims > 2)) && 
			($jobvsl == 2 || $jobvsr == 2 || $jobvl == 2 || $jobvr == 2));


       	my ($w, $vsl, $vsr, $info, $type, $select,$sdim, $vr,$vl, $mm, $pp, %ret, $beta);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
	$type = $m->type;
       	$select = $select_func ? pdl(long,1) : pdl(long,0);

       	$info = null;
       	$sdim = null;
	$mm = $m->is_inplace ? $m->xchg(0,1) : $m->xchg(0,1)->copy;
	$pp = $p->is_inplace ? $p->xchg(0,1) : $p->xchg(0,1)->copy;

	my ($select_f, $wi, $wtmp, $betai);
	if ($select_func){
	 	$select_f= sub{
	 		&$select_func(PDL::Complex::complex(pdl($type,@_[0..1])),pdl($_[2]));
		}; 
	}
	$wtmp = null;
      	$wi = null;
	$beta = null;
#		$vsl = $jobvsl ? PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]) : 
#				pdl($type,[[0]]);

	# Lapack always write in VSL (g77 3.3) ???
	$vsl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]);
	$vsr = $jobvsr ? PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]) : 
				pdl($type,[[0]]);
	$mm->gges( $jobvsl, $jobvsr, $select, $pp, $wtmp, $wi, $beta, $vsl, $vsr, $sdim, $info, $select_f);

	if ($info->max > 0 && $_laerror){
		my ($index, @list);
		$index = which((($info > 0)+($info <=$mdims[0])) == 2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mgschur: The QZ algorithm failed to converge for matrix (PDL(s) @list): \$info = $info");
			print ("Returning converged eigenvalues\n");
		}
		$index = which((($info > 0)+($info <=($mdims[0]+1))) == 2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mgschur: Error in hgeqz for matrix (PDL(s) @list): \$info = $info");
		}
		if ($select_func){
			$index = which((($info > 0)+($info == ($mdims[0]+3))) == 2);
			unless ($index->isempty){
				laerror("mgschur: The eigenvalues could not be reordered because some\n".
                			     "eigenvalues were too close to separate (the problem".
		        	             "is very ill-conditioned) for PDL(s) @list: \$info = $info");
			}
		}
	}

	if ($select_func){
		if ($jobvsl == 2 || $jobvsr == 2 || $jobvl == 2 || $jobvr == 2){
			if ($info == ($mdims[0] + 2)){
				warn("mgschur: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n") if $_laerror;
				#TODO : Check sdim and lapack
				$sdim+=1 if ($sdim < $mdims[0] && $wi($sdim) != 0 && $wi($sdim-1) == -$wi($sdim));
			}
		}
		elsif($_laerror){
			my $index = which((($info > 0)+($info == ($mdims[0]+2))) == 2);
			unless ($index->isempty){
				my @list = $index->list;
				warn("mgschur: The Schur form no longer satisfy select_func = 1\n because".
					"of roundoff or underflow for PDL(s) @list: \$info = $info\n");
			}
		}
		if ($jobvl == 2){
			if (!$sdim){
				$ret{VL} = PDL::Complex->null;
				$jobvl = 0;
			}
		}
		if ($jobvr == 2){
			if(!$sdim){
				$ret{VR} = PDL::Complex->null;
				$jobvr = 0;
			}
		}
		$ret{n} = $sdim;
	}

	if ($jobvl || $jobvr){
		my ($sel, $job, $wtmpi, $wtmpr, $sdims);
		unless ($jobvr && $jobvl){
			$job = $jobvl ? 2 : 1;
		}
		if ($select_func){
			if ($jobvl == 1 || $jobvr == 1 || $mult){ 
				$sdims = null;
				if ($jobvl){
					if ($jobvsl){
						$vl = $vsl->copy;
					}
					else{
						$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]);
						$mult = 0;
					}
				}
				if ($jobvr){
					if ($jobvsr){
						$vr = $vsr->copy;
					}
					else{
						$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]);
						$mult = 0;
					}
				}

				$mm->tgevc($job, $mult, $pp, $sel, $vl, $vr, $sdims, my $infos=null);
				if ($jobvr){
					if($norm){
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
						bless $vr, 'PDL::Complex';
						$ret{VR} =  $jobvr == 2 ? magn_norm($vr(,,:($sdim-1)),1) : magn_norm($vr,1);

					}
					else{
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						$ret{VR} =  $jobvr == 2 ? $vr(,:($sdim-1))->sever : $vr;
					}
				}
				if ($jobvl){
					if ($norm){
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $jobvl == 2 ? magn_norm($vl(,,:($sdim-1)),1) : magn_norm($vl,1);
				
					}
					else{
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $jobvl == 2 ? $vl(,:($sdim-1))->sever : $vl;
					}
				}
			}
			else{
				$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $sdim) if $jobvr;
				$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $sdim) if $jobvl;
				$sel = zeroes($mdims[1]);
				$sel(:($sdim-1)) .= 1; 
				$mm->tgevc($job, 2, $pp, $sel, $vl, $vr, $sdim, my $infos = null);
				$wtmpr = $wtmp(:($sdim-1));
				$wtmpi = $wi(:($sdim-1));
				if ($jobvr){
					if ($norm){
						(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr,1);
						bless $vr, 'PDL::Complex';
						$ret{VR} = magn_norm($vr,1);
					}
					else{
						(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						$ret{VR} = $vr;
					}
				}
				if ($jobvl){
					if ($norm){
						(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl,1);
						bless $vl, 'PDL::Complex';
						$ret{VL} = magn_norm($vl,1);
	
					}
					else{
						(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $vl;
					}
				}
			}
		}
		else{
			if ($jobvl){
				if ($jobvsl){
					$vl = $vsl->copy;
				}
				else{
					$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]);
					$mult = 0;
				}
			}
			if ($jobvr){
				if ($jobvsr){
					$vr = $vsr->copy;
				}
				else{
					$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1],@mdims[2..$#mdims]);
					$mult = 0;
				}
			}

			$mm->tgevc($job, $mult, $pp, $sel, $vl, $vr, $sdim, my $infos=null);
			if ($jobvl){
				if ($norm){
					(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
					bless $vl, 'PDL::Complex';
					$ret{VL} = magn_norm($vl,1);
				}
				else{
					(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
					bless $vl, 'PDL::Complex';
					$ret{VL} = $vl;
				}
			}
			if ($jobvr){
				if ($norm){
					(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
					bless $vr, 'PDL::Complex';
					$ret{VR} = magn_norm($vr,1);
				}
				else{
					(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
					bless $vr, 'PDL::Complex';
					$ret{VR} = $vr;
				}
			}
		}
	}
	$w = PDL::Complex::ecplx ($wtmp, $wi);

	if ($jobvsr == 2 && $select_func) {
		$vsr = $sdim  ? $vsr->xchg(0,1)->(:($sdim-1),) ->sever : null;
		$ret{SR} = $vsr;
	}
	elsif($jobvsr){
		$vsr =  $vsr->xchg(0,1)->sever;
		$ret{SR} = $vsr;
	}

	if ($jobvsl == 2 && $select_func) {
		$vsl = $sdim  ? $vsl->xchg(0,1)->(:($sdim-1),) ->sever : null;
		$ret{SL} = $vsl;
	}
	elsif($jobvsl){
		$vsl =  $vsl->xchg(0,1)->sever;
		$ret{SL} = $vsl;
	}
	$ret{info} = $info;
	$m = $mm->xchg(0,1)->sever unless $m->is_inplace(0);
	$p = $pp->xchg(0,1)->sever unless $p->is_inplace(0);
	return ($m, $p, $w, $beta, %ret);
		
}


sub PDL::Complex::mgschur{
	my($m, $p, $jobvsl, $jobvsr, $jobvl, $jobvr, $select_func, $mult, $norm) = @_;
	my @mdims  = $m->dims;
	my @pdims  = $p->dims;

	barf("mgschur: Require square matrices of same order")
		unless( $mdims[2] == $mdims[1] && $pdims[2] == $pdims[1] && $mdims[1] == $pdims[1]);
	barf("mgschur: thread doesn't supported for selected vectors")
		if ($select_func && ((@mdims > 2) || (@pdims > 2)) && 
			($jobvsl == 2 || $jobvsr == 2 || $jobvl == 2 || $jobvr == 2));


       	my ($w, $vsl, $vsr, $info, $type, $select,$sdim, $vr,$vl, $mm, $pp, %ret, $beta);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
	$type = $m->type;
       	$select = $select_func ? pdl(long,1) : pdl(long,0);

       	$info = null;
       	$sdim = null;
	$mm = $m->is_inplace ? $m->xchg(1,2) : $m->xchg(1,2)->copy;
	$pp = $p->is_inplace ? $p->xchg(1,2) : $p->xchg(1,2)->copy;

	$w = PDL::Complex->null;
	$beta = PDL::Complex->null;
	$vsr = $jobvsr ? PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]) : 
				pdl($type,[0,0]);
#	$vsl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
	$vsl = $jobvsl ? PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]) : 
				pdl($type,[0,0]);

	$mm->cgges( $jobvsl, $jobvsr, $select, $pp, $w, $beta, $vsl, $vsr, $sdim, $info, $select_func);
	if ($info->max > 0 && $_laerror){
		my ($index, @list);
		$index = which((($info > 0)+($info <=$mdims[1])) == 2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mgschur: The QZ algorithm failed to converge for matrix (PDL(s) @list): \$info = $info");
			print ("Returning converged eigenvalues\n");
		}
		$index = which((($info > 0)+($info <=($mdims[1]+1))) == 2);
		unless ($index->isempty){
			@list = $index->list;
			laerror("mgschur: Error in hgeqz for matrix (PDL(s) @list): \$info = $info");
		}
		if ($select_func){
			$index = which((($info > 0)+($info == ($mdims[1]+3))) == 2);
			unless ($index->isempty){
				laerror("mgschur: The eigenvalues could not be reordered because some\n".
                			     "eigenvalues were too close to separate (the problem".
		        	             "is very ill-conditioned) for PDL(s) @list: \$info = $info");
			}
		}
	}

	if ($select_func){
		if ($_laerror){
			if (($jobvsl == 2 || $jobvsr == 2 || $jobvl == 2 || $jobvr == 2) && $info == ($mdims[1] + 2)){
				warn("mgschur: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n");
			}
			else{
				my $index = which((($info > 0)+($info == ($mdims[1]+2))) == 2);
				unless ($index->isempty){
					my @list = $index->list;
					warn("mgschur: The Schur form no longer satisfy select_func = 1\n because".
						"of roundoff or underflow for PDL(s) @list: \$info = $info\n");
				}
			}
		}
		if ($jobvl == 2){
			if (!$sdim){
				$ret{VL} = PDL::Complex->null;
				$jobvl = 0;
			}
		}
		if ($jobvr == 2){
			if(!$sdim){
				$ret{VR} = PDL::Complex->null;
				$jobvr = 0;
			}
		}
		$ret{n} = $sdim;
	}

	if ($jobvl || $jobvr){
		my ($sel, $job, $sdims);
		unless ($jobvr && $jobvl){
			$job = $jobvl ? 2 : 1;
		}
		if ($select_func){
			if ($jobvl == 1 || $jobvr == 1 || $mult){ 
				$sdims = null;
				if ($jobvl){
					if ($jobvsl){
						$vl = $vsl->copy;
					}
					else{
						$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]);
						$mult = 0;
					}
				}
				if ($jobvr){
					if ($jobvsr){
						$vr = $vsr->copy;
					}
					else{
						$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]);
						$mult = 0;
					}
				}
				$mm->ctgevc($job, $mult, $pp, $sel, $vl, $vr, $sdims, my $infos=null);
				if ($jobvr){
					if ($norm){
						$ret{VR} = $jobvr == 2 ? magn_norm($vr(,,:($sdim-1)),1) : magn_norm($vr,1);
					}
					else{
						$ret{VR} = $jobvr == 2 ? $vr(,,:($sdim-1))->xchg(1,2)->sever : $vr->xchg(1,2)->sever;
					}
				}
				if ($jobvl){
					if ($norm){
						$ret{VL} = $jobvl == 2 ? magn_norm($vl(,,:($sdim-1)),1) : magn_norm($vl,1);
					}
					else{
						$ret{VL} = $jobvl == 2 ? $vl(,,:($sdim-1))->xchg(1,2)->sever : $vl->xchg(1,2)->sever;
					}
				}
			}
			else{
				$vr = PDL::new_from_specification('PDL::Complex', $type, 2,$mdims[1], $sdim) if $jobvr;;
				$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $sdim) if $jobvl;;
					$sel = zeroes($mdims[1]);
				$sel(:($sdim-1)) .= 1; 
				$mm->ctgevc($job, 2, $pp, $sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvl){
					$ret{VL} = $norm ? magn_norm($vl,1) : $vl->xchg(1,2)->sever;
				}
				if ($jobvr){
					$ret{VR} = $norm ? magn_norm($vr,1) : $vr->xchg(1,2)->sever;
				}
			}
		}
		else{
			if ($jobvl){
				if ($jobvsl){
					$vl = $vsl->copy;
					}
				else{
					$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]);
					$mult = 0;
				}
			}
			if ($jobvr){
					if ($jobvsr){
					$vr = $vsr->copy;
				}
				else{
					$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1],@mdims[3..$#mdims]);
					$mult = 0;
				}
			}
			$mm->ctgevc($job, $mult, $pp, $sel, $vl, $vr, $sdim, my $infos=null);
			if ($jobvl){
				$ret{VL} = $norm ? magn_norm($vl,1) : $vl->xchg(1,2)->sever;
			}
			if ($jobvr){
				$ret{VR} = $norm ? magn_norm($vr,1) : $vr->xchg(1,2)->sever;
			}
		}
	}
	if ($jobvsl == 2 && $select_func) {
		$vsl = $sdim ? $vsl->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
		$ret{SL} = $vsl;
	}
	elsif($jobvsl){
		$vsl =  $vsl->xchg(1,2)->sever;
		$ret{SL} = $vsl;
	}
	if ($jobvsr == 2 && $select_func) {
		$vsr = $sdim ? $vsr->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
		$ret{SR} = $vsr;
	}
	elsif($jobvsr){
		$vsr =  $vsr->xchg(1,2)->sever;
		$ret{SR} = $vsr;
	}

	$ret{info} = $info;
	$m = $mm->xchg(1,2)->sever unless $m->is_inplace(0);
	$p = $pp->xchg(1,2)->sever unless $p->is_inplace(0);
	return ($m, $p, $w, $beta, %ret);
		
}



=head2 mgschurx

=for ref

Computes generalized Schur decomposition of the pair (A,B).

	A = Q x S x Z'
	B = Q x T x Z'

Uses L<ggesx|PDL::LinearAlgebra::Real/ggesx> or L<cggesx|PDL::LinearAlgebra::Complex/cggesx>
from Lapack. Works on transposed array.

=for usage

 ( PDL(schur S), PDL(schur T), PDL(alpha), PDL(beta), HASH{result}) = mgschurx(PDL(A), PDL(B), SCALAR(left schur vector),SCALAR(right schur vector),SCALAR(left eigenvector), SCALAR(right eigenvector), SCALAR(select_func), SCALAR(sense), SCALAR(backtransform), SCALAR(scale))
 left schur vector   : Left Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right schur vector  : Right Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 left eigenvector    : Left eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right eigenvector   : Right eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 select_func	     : Select_func is used to select eigenvalues to sort.
		       to the top left of the Schur form.
		       An eigenvalue w = wr(j)+sqrt(-1)*wi(j) is selected if
		       PerlInt select_func(PDL::Complex(alpha),PDL | PDL::Complex (beta)) is true;
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func = 1 after ordering, since
		       ordering may change the value of complex eigenvalues
		       (especially if the eigenvalue is ill-conditioned).
		       All eigenvalues/vectors are selected if select_func is undefined. 
 sense		     : Determines which reciprocal condition numbers will be computed.
			0: None are computed
			1: Computed for average of selected eigenvalues only
			2: Computed for selected deflating subspaces only
			3: Computed for both
			If select_func is undefined, sense is not used.

 backtransform 	     : Whether or not backtransforms eigenvectors to those of (A,B).
 		       Only supported if right and/or left schur vector are computed, default = 1
 scale               : Whether or not computed eigenvectors are scaled so the largest component
		       will have abs(real part) + abs(imag. part) = 1, default = 1

 Returned values     :
		       Schur form S,
		       Schur form T,
		       alpha,
		       beta (eigenvalues = alpha/beta),
		       HASH{info}: info output from gges/cgges.
		       HASH{SL}: left Schur vectors if requested
		       HASH{SR}: right Schur vectors if requested
		       HASH{VL}: left eigenvectors if requested
		       HASH{VR}: right eigenvectors if requested
		       HASH{rconde}: reciprocal condition numbers for average of selected eigenvalues if requested
		       HASH{rcondv}: reciprocal condition numbers for selected deflating subspaces if requested
		       HASH{n} : Number of eigenvalues selected if select_func is defined.

=for example

 my $a = random(10,10);
 my $b = random(10,10);
 my ($S,$T) = mgschurx($a,$b);
 sub select{
 	my ($alpha,$beta) = @_;
 	return $alpha->Cabs < abs($beta) ? 1 : 0;
 }
 my ($S, $T, $alpha, $beta, %res)  = mgschurx( $a, $b, 1, 1, 1, 1,\&select,3); 



=cut

*mgschurx = \&PDL::mgschurx;

sub PDL::mgschurx{
	my($m, $p, $jobvsl, $jobvsr, $jobvl, $jobvr, $select_func, $sense, $mult, $norm) = @_;
	my (@mdims) = $m->dims;
	my (@pdims) = $p->dims;

	barf("mgschurx: Require square matrices of same order")
		unless( ( (@mdims == 2) || (@mdims == 3) )&& $mdims[-1] == $mdims[-2] && @mdims == @pdims && 
			$pdims[-1] == $pdims[-2] && $mdims[1] == $pdims[1]);

       	my ($w, $vsl, $vsr, $info, $type, $select, $sdim, $rconde, $rcondv, %ret, $mm, $vl, $vr, $beta, $pp);

	$mult = 1 unless defined($mult);
	$norm = 1 unless defined($norm);
	$type = $m->type;
	if ($select_func){
       		$select =  pdl(long 1);
		$rconde = pdl($type,[0,0]);
		$rcondv = pdl($type,[0,0]);
       	}
       	else{
		$select =  pdl(long,0);
		$sense = pdl(long,0);
		$rconde = pdl($type,0);
		$rcondv = pdl($type,0);
	}

	$info = pdl(long,0);
	$sdim = pdl(long,0);


	$mm = $m->is_inplace ? $m->xchg(-1,-2) : $m->xchg(-1,-2)->copy;
	$pp = $p->is_inplace ? $p->xchg(-1,-2) : $p->xchg(-1,-2)->copy;

	if (@mdims == 3){
		$w = PDL::Complex->null;
		$beta = PDL::Complex->null;
#		$vsl = $jobvsl ? PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]) : 
#					pdl($type,[0,0]);
		$vsl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
		$vsr = $jobvsr ? PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]) : 
					pdl($type,[0,0]);
		$mm->cggesx( $jobvsl, $jobvsr, $select, $sense, $pp, $w, $beta, $vsl, $vsr, $sdim, $rconde, $rcondv,$info, $select_func);
		if ($info){
			if ($info < $mdims[1]){
				laerror("mgschurx: The QZ algorithm failed to converge");
				print ("Returning converged eigenvalues\n") if $_laerror;
			}
			laerror("mgschurx: The eigenvalues could not be reordered because some\n".
	                	     "eigenvalues were too close to separate (the problem".
	        	             "is very ill-conditioned)")
				if $info == ($mdims[1] + 3);
			laerror("mgschurx: Error in hgeqz\n")
				if $info == ($mdims[1] + 1);

			warn("mgschurx: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n")
					if ($info == ($mdims[1] + 2) and $_laerror);

		}

		if ($select_func){
			if(!$sdim){
				if ($jobvl == 2){
					$ret{VL} = PDL::Complex->null;
					$jobvl = 0;
				}
				if ($jobvr == 2){
					$ret{VR} = PDL::Complex->null;
					$jobvr = 0;
				}
			}
			$ret{n} = $sdim;
		}
		if ($jobvl || $jobvr){
			my ($sel, $job, $sdims);
			unless ($jobvr && $jobvl){
				$job = $jobvl ? 2 : 1;
			}
			if ($select_func){
				if ($jobvl == 1 || $jobvr == 1 || $mult){ 
					$sdims = null;
					if ($jobvl){
						if ($jobvsl){
							$vl = $vsl->copy;
						}
						else{
							$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
							$mult = 0;
						}
					}
					if ($jobvr){
						if ($jobvsr){
							$vr = $vsr->copy;
						}
						else{
							$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
							$mult = 0;
						}
					}
					$mm->ctgevc($job, $mult, $pp, $sel, $vl, $vr, $sdims, my $infos=null);
					if ($jobvr){
						if ($norm){
							$ret{VR} = $jobvr == 2 ? magn_norm($vr(,,:($sdim-1)),1) : magn_norm($vr,1);
						}
						else{
							$ret{VR} = $jobvr == 2 ? $vr(,,:($sdim-1))->xchg(1,2)->sever : $vr->xchg(1,2)->sever;
						}
					}
					if ($jobvl){
						if ($norm){
							$ret{VL} = $jobvl == 2 ? magn_norm($vl(,,:($sdim-1)),1) : magn_norm($vl,1);
						}
						else{
							$ret{VL} = $jobvl == 2 ? $vl(,,:($sdim-1))->xchg(1,2)->sever : $vl->xchg(1,2)->sever;
						}
					}
				}
				else{
					$vr = PDL::new_from_specification('PDL::Complex', $type, 2,$mdims[1], $sdim) if $jobvr;
					$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $sdim) if $jobvl;
					$sel = zeroes($mdims[1]);
					$sel(:($sdim-1)) .= 1; 
					$mm->ctgevc($job, 2, $pp, $sel, $vl, $vr, $sdim, my $infos=null);
					if ($jobvl){
						$ret{VL} = $norm ? magn_norm($vl,1) : $vl->xchg(1,2)->sever;
					}
					if ($jobvr){
						$ret{VR} = $norm ? magn_norm($vr,1) : $vr->xchg(1,2)->sever;
					}
				}
			}
			else{
				if ($jobvl){
					if ($jobvsl){
						$vl = $vsl->copy;
					}
					else{
						$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
						$mult = 0;
					}
				}
				if ($jobvr){
					if ($jobvsr){
						$vr = $vsr->copy;
					}
					else{
						$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $mdims[1], $mdims[1]);
						$mult = 0;
					}
				}
				$mm->ctgevc($job, $mult, $pp,$sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvl){
					$ret{VL} = $norm ? magn_norm($vl,1) : $vl->xchg(1,2)->sever;
				}
				if ($jobvr){
					$ret{VR} = $norm ? magn_norm($vr,1) : $vr->xchg(1,2)->sever;
				}
			}
		}
		if ($jobvsl == 2 && $select_func) {
			$vsl = $sdim > 0 ? $vsl->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
			$ret{SL} = $vsl;
		}
		elsif($jobvsl){
			$vsl =  $vsl->xchg(1,2)->sever;
			$ret{SL} = $vsl;
		}
		if ($jobvsr == 2 && $select_func) {
			$vsr = $sdim > 0 ? $vsr->xchg(1,2)->(,:($sdim-1),) ->sever : PDL::Complex->null;
			$ret{SR} = $vsr;
		}
		elsif($jobvsr){
			$vsr =  $vsr->xchg(1,2)->sever;
			$ret{SR} = $vsr;
		}
	}
	else{
		my ($select_f, $wi, $wtmp);
		if ($select_func){
			no strict 'refs';
		 	$select_f= sub{
				&$select_func(PDL::Complex::complex(pdl($type,$_[0],$_[1])), $_[2]);
			}; 
		}
		$wi = null; 
	       	$wtmp = null;
	       	$beta = null;
		#$vsl = $jobvsl ? PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]) : 
		#			pdl($type,[[0]]);
		$vsl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]);
		$vsr = $jobvsr ? PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]) : 
					pdl($type,[[0]]);
		$mm->ggesx( $jobvsl, $jobvsr, $select, $sense, $pp, $wtmp, $wi, $beta, $vsl, $vsr, $sdim, $rconde, $rcondv,$info, $select_f);
		if ($info){
			if ($info < $mdims[0]){
				laerror("mgschurx: The QZ algorithm failed to converge");
				print ("Returning converged eigenvalues\n") if $_laerror;
			}
			laerror("mgschurx: The eigenvalues could not be reordered because some\n".
	                	     "eigenvalues were too close to separate (the problem".
	        	             "is very ill-conditioned)")
				if $info == ($mdims[0] + 3);
			laerror("mgschurx: Error in hgeqz\n")
				if $info == ($mdims[0] + 1);

			if ($info == ($mdims[0] + 2)){
				warn("mgschur: The Schur form no longer satisfy select_func = 1\n because of roundoff or underflow\n") if $_laerror;
				$sdim+=1 if ($sdim < $mdims[0] && $wi($sdim) != 0 && $wi($sdim-1) == -$wi($sdim));
			}
		}

		if ($select_func){
			if(!$sdim){
				if ($jobvl == 2){
					$ret{VL} = null;
					$jobvl = 0;
				}
				if ($jobvr == 2){
					$ret{VR} = null;
					$jobvr = 0;
				}
			}
			$ret{n} = $sdim;
		}

		if ($jobvl || $jobvr){
			my ($sel, $job, $wtmpi, $wtmpr, $sdims);
			unless ($jobvr && $jobvl){
				$job = $jobvl ? 2 : 1;
			}
			if ($select_func){
				$sdims = null;
				if ($jobvl == 1 || $jobvr == 1 || $mult){ 
					if ($jobvl){
						if ($jobvsl){
							$vl = $vsl->copy;
						}
						else{
							$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]);
							$mult = 0;
						}
					}
					if ($jobvr){
						if ($jobvsr){
							$vr = $vsr->copy;
						}
						else{
							$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]);
							$mult = 0;
						}
					}

					$mm->tgevc($job, $mult, $pp, $sel, $vl, $vr, $sdims, my $infos=null);
					if ($jobvr){
						if($norm){
							(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
							bless $vr, 'PDL::Complex';
							$ret{VR} =  $jobvr == 2 ? magn_norm($vr(,,:($sdim-1)),1) : magn_norm($vr,1);
						}
						else{
							(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
							bless $vr, 'PDL::Complex';
							$ret{VR} =  $jobvr == 2 ? $vr(,:($sdim-1))->sever : $vr;
						}
					}
					if ($jobvl){
						if ($norm){
							(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
							bless $vl, 'PDL::Complex';
							$ret{VL} = $jobvl == 2 ? magn_norm($vl(,,:($sdim-1)),1) : magn_norm($vl,1);
						}
						else{
							(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
							bless $vl, 'PDL::Complex';
							$ret{VL} = $jobvl == 2 ? $vl(,:($sdim-1))->sever : $vl;
						}
					}
				}
				else{
					$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $sdim) if $jobvr;
					$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $sdim) if $jobvl;
					$sel = zeroes($mdims[1]);
					$sel(:($sdim-1)) .= 1; 
					$mm->tgevc($job, 2, $pp, $sel, $vl, $vr, $sdim, my $infos = null);
					$wtmpr = $wtmp(:($sdim-1));
					$wtmpi = $wi(:($sdim-1));
					if ($jobvr){
						if ($norm){
							(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr,1);
							bless $vr, 'PDL::Complex';
							$ret{VR} = magn_norm($vr,1);
						}
						else{
							(undef,$vr) = $wtmpr->cplx_eigen($wtmpi,$vr->xchg(0,1),0);
							bless $vr, 'PDL::Complex';
							$ret{VR} = $vr;
						}
					}
					if ($jobvl){
						if ($norm){
							(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl,1);
							bless $vl, 'PDL::Complex';
							$ret{VL} = magn_norm($vl,1);
						}
						else{
							(undef,$vl) = $wtmpr->cplx_eigen($wtmpi,$vl->xchg(0,1),0);
							bless $vl, 'PDL::Complex';
							$ret{VL} = $vl;
						}
					}
				}
			}
			else{
				if ($jobvl){
					if ($jobvsl){
						$vl = $vsl->copy;
					}
					else{
						$vl = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]);
						$mult = 0;
					}
				}
				if ($jobvr){
					if ($jobvsr){
						$vr = $vsr->copy;
					}
					else{
						$vr = PDL::new_from_specification('PDL', $type, $mdims[1], $mdims[1]);
						$mult = 0;
					}
				}

				$mm->tgevc($job, $mult, $pp, $sel, $vl, $vr, $sdim, my $infos=null);
				if ($jobvl){
					if ($norm){
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl,1);
						bless $vl, 'PDL::Complex';
						$ret{VL} = magn_norm($vl,1);
					}
					else{
						(undef,$vl) = $wtmp->cplx_eigen($wi,$vl->xchg(0,1),0);
						bless $vl, 'PDL::Complex';
						$ret{VL} = $vl;
					}
				}
				if ($jobvr){
					if ($norm){
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr,1);
						bless $vr, 'PDL::Complex';
						$ret{VR} = magn_norm($vr,1);
					}
					else{
						(undef,$vr) = $wtmp->cplx_eigen($wi,$vr->xchg(0,1),0);
						bless $vr, 'PDL::Complex';
						$ret{VR} = $vr;
					}
				}
			}
		}
		$w = PDL::Complex::ecplx ($wtmp, $wi);

		if ($jobvsr == 2 && $select_func) {
			$vsr = $sdim > 0 ? $vsr->xchg(0,1)->(:($sdim-1),) ->sever : null;
			$ret{SR} = $vsr;
		}
		elsif($jobvsr){
			$vsr =  $vsr->xchg(0,1)->sever;
			$ret{SR} = $vsr;
		}

		if ($jobvsl == 2 && $select_func) {
			$vsl = $sdim > 0 ? $vsl->xchg(0,1)->(:($sdim-1),) ->sever : null;
			$ret{SL} = $vsl;
		}
		elsif($jobvsl){
			$vsl =  $vsl->xchg(0,1)->sever;
			$ret{SL} = $vsl;
		}

	}

	
	$ret{info} = $info;
	if ($sense){
		if ($sense == 3){
			$ret{rconde} = $rconde;
			$ret{rcondv} = $rcondv;
		}
		else{
			$ret{rconde} = $rconde if ($sense == 1);
			$ret{rcondv} = $rcondv if ($sense == 2);
		}
	}
	$m = $mm->xchg(-1,-2)->sever unless $m->is_inplace(0);
	$p = $pp->xchg(-1,-2)->sever unless $p->is_inplace(0);
	return ($m, $p, $w, $beta, %ret);
}


=head2 mqr

=for ref

Computes QR decomposition.
For complex number needs object of type PDL::Complex.
Uses L<geqrf|PDL::LinearAlgebra::Real/geqrf> and L<orgqr|PDL::LinearAlgebra::Real/orgqr>
or L<cgeqrf|PDL::LinearAlgebra::Complex/cgeqrf> and L<cungqr|PDL::LinearAlgebra::Complex/cungqr>
from Lapack and returns C<Q> in scalar context. Works on transposed array.

=for usage

 (PDL(Q), PDL(R), PDL(info)) = mqr(PDL, SCALAR)
 SCALAR : ECONOMIC = 0 | FULL = 1, default = 0

=for example

 my $a = random(10,10);
 my ( $q, $r )  = mqr($a);
 # Can compute full decomposition if nrow > ncol
 $a = random(5,7);
 ( $q, $r )  = $a->mqr(1);

=cut

sub mqr{
	my $m = shift;
	$m->mqr(@_);
}

sub PDL::mqr {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $r);
	barf("mqr: Require a matrix") unless @dims == 2;

        $m = $m->xchg(0,1)->copy;
	my $min = $dims[0] < $dims[1] ?  $dims[0] : $dims[1];
	
	my $tau = zeroes($m->type, $min);
	$m->geqrf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mqr: Error $info in geqrf\n");
		$q = $r = $m;
	}
	else{
		$q = $dims[0] > $dims[1] ? $m(:,:($min-1))->copy : $m->copy;
        	$q->reshape($dims[1], $dims[1]) if $full && $dims[0] < $dims[1];

		$q->orgqr($tau, $info);
		return $q->xchg(0,1)->sever unless wantarray;

		if ($dims[0] < $dims[1] && !$full){
			$r = zeroes($m->type, $min, $min);
			$m->xchg(0,1)->(,:($min-1))->tricpy(0,$r);
		}
		else{
			$r = zeroes($m->type, $dims[0],$dims[1]);
			$m->xchg(0,1)->tricpy(0,$r);
		}
	}
	return ($q->xchg(0,1)->sever, $r, $info);
}

sub PDL::Complex::mqr {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $r);
	barf("mqr: Require a matrix") unless @dims == 3;

        $m = $m->xchg(1,2)->copy;
	my $min = $dims[1] < $dims[2] ?  $dims[1] : $dims[2];
	
	my $tau = zeroes($m->type, 2, $min);
	$m->cgeqrf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mqr: Error $info in cgeqrf\n");
		$q = $r = $m;
	}
	else{
		$q = $dims[1] > $dims[2] ? $m(,:,:($min-1))->copy : $m->copy;
        	$q->reshape(2,$dims[2], $dims[2]) if $full && $dims[1] < $dims[2];

		$q->cungqr($tau, $info);
		return $q->xchg(1,2)->sever unless wantarray;

		if ($dims[1] < $dims[2] && !$full){
			$r = PDL::new_from_specification('PDL::Complex',$m->type, 2, $min, $min);
			$r .= 0;
			$m->xchg(1,2)->(,,:($min-1))->ctricpy(0,$r);
		}
		else{
			$r = PDL::new_from_specification('PDL::Complex', $m->type, 2, $dims[1],$dims[2]);
			$r .= 0;
			$m->xchg(1,2)->ctricpy(0,$r);
		}
	}
	return ($q->xchg(1,2)->sever, $r, $info);
}

=head2 mrq

=for ref

Computes RQ decomposition.
For complex number needs object of type PDL::Complex.
Uses L<gerqf|PDL::LinearAlgebra::Real/gerqf> and L<orgrq|PDL::LinearAlgebra::Real/orgrq>
or L<cgerqf|PDL::LinearAlgebra::Complex/cgerqf> and L<cungrq|PDL::LinearAlgebra::Complex/cungrq>
from Lapack and returns C<Q> in scalar context. Works on transposed array.

=for usage

 (PDL(R), PDL(Q), PDL(info)) = mrq(PDL, SCALAR)
 SCALAR : ECONOMIC = 0 | FULL = 1, default = 0

=for example

 my $a = random(10,10);
 my ( $r, $q )  = mrq($a);
 # Can compute full decomposition if nrow < ncol
 $a = random(5,7);
 ( $r, $q )  = $a->mrq(1);

=cut

sub mrq{
	my $m = shift;
	$m->mrq(@_);
}

sub PDL::mrq {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $r);


	barf("mrq: Require a matrix") unless @dims == 2;
        $m = $m->xchg(0,1)->copy;
	my $min = $dims[0] < $dims[1] ?  $dims[0] : $dims[1];
	
	my $tau = zeroes($m->type, $min);
	$m->gerqf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror ("mrq: Error $info in gerqf\n");
		$r = $q = $m;
	}
	else{
		if ($dims[0] > $dims[1] && $full){
			$q = zeroes($m->type, $dims[0],$dims[0]);
			$q(($dims[0] - $dims[1]):,:) .= $m;
		}
		elsif ($dims[0] < $dims[1]){
			$q = $m(($dims[1] - $dims[0]):,:)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->orgrq($tau, $info);
		return $q->xchg(0,1)->sever unless wantarray;

		if ($dims[0] > $dims[1] && $full){
			$r = zeroes ($m->type,$dims[0],$dims[1]);
			$m->xchg(0,1)->tricpy(0,$r);
			$r(:($min-1),:($min-1))->diagonal(0,1) .= 0;
		}
		elsif ($dims[0] < $dims[1]){
			my $temp = zeroes($m->type,$dims[1],$dims[1]);
			$temp(-$min:, :) .= $m->xchg(0,1)->sever;
			$r = PDL::zeroes($temp);
			$temp->tricpy(0,$r);
			$r = $r(-$min:, :);
		}
		else{
			$r = zeroes($m->type, $min, $min);
			$m->xchg(0,1)->(($dims[0] - $dims[1]):, :)->tricpy(0,$r);
		}
	}
	return ($r, $q->xchg(0,1)->sever, $info);

}

sub PDL::Complex::mrq {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $r);


	barf("mrq: Require a matrix") unless @dims == 3;
        $m = $m->xchg(1,2)->copy;
	my $min = $dims[1] < $dims[2] ?  $dims[1] : $dims[2];
	
	my $tau = zeroes($m->type, 2, $min);
	$m->cgerqf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror ("mrq: Error $info in cgerqf\n");
		$r = $q = $m;
	}
	else{
		if ($dims[1] > $dims[2] && $full){
			$q = PDL::new_from_specification('PDL::Complex',$m->type, 2, $dims[1],$dims[1]);
			$q .= 0;
			$q(,($dims[1] - $dims[2]):,:) .= $m;
		}
		elsif ($dims[1] < $dims[2]){
			$q = $m(,($dims[2] - $dims[1]):,:)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->cungrq($tau, $info);
		return $q->xchg(1,2)->sever unless wantarray;

		if ($dims[1] > $dims[2] && $full){
			$r = PDL::new_from_specification('PDL::Complex',$m->type,2,$dims[1],$dims[2]);
			$r .= 0;
			$m->xchg(1,2)->ctricpy(0,$r);
			$r(,:($min-1),:($min-1))->diagonal(1,2) .= 0;
		}
		elsif ($dims[1] < $dims[2]){
			my $temp = PDL::new_from_specification('PDL::Complex',$m->type,2,$dims[2],$dims[2]);
			$temp .= 0;
			$temp(,-$min:, :) .= $m->xchg(1,2);
			$r = PDL::zeroes($temp);
			$temp->ctricpy(0,$r);
			$r = $r(,-$min:, :)->sever;
		}
		else{
			$r = PDL::new_from_specification('PDL::Complex',$m->type, 2,$min, $min);
			$r .= 0;
			$m->xchg(1,2)->(,($dims[1] - $dims[2]):, :)->ctricpy(0,$r);
		}
	}
	return ($r, $q->xchg(1,2)->sever, $info);

}

=head2 mql

=for ref

Computes QL decomposition.
For complex number needs object of type PDL::Complex.
Uses L<geqlf|PDL::LinearAlgebra::Real/geqlf> and L<orgql|PDL::LinearAlgebra::Real/orgql>
or L<cgeqlf|PDL::LinearAlgebra::Complex/cgeqlf> and L<cungql|PDL::LinearAlgebra::Complex/cungql>
from Lapack and returns C<Q> in scalar context. Works on transposed array.

=for usage

 (PDL(Q), PDL(L), PDL(info)) = mql(PDL, SCALAR)
 SCALAR : ECONOMIC = 0 | FULL = 1, default = 0

=for example

 my $a = random(10,10);
 my ( $q, $l )  = mql($a);
 # Can compute full decomposition if nrow > ncol
 $a = random(5,7);
 ( $q, $l )  = $a->mql(1);

=cut

sub mql{
	my $m = shift;
	$m->mql(@_);
}

sub PDL::mql {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $l);


	barf("mql: Require a matrix") unless @dims == 2;
        $m = $m->xchg(0,1)->copy;
	my $min = $dims[0] < $dims[1] ?  $dims[0] : $dims[1];
	
	my $tau = zeroes($m->type, $min);
	$m->geqlf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mql: Error $info in geqlf\n");
		$q = $l = $m;
	}
	else{
		if ($dims[0] < $dims[1] && $full){
			$q = zeroes($m->type, $dims[1],$dims[1]);
			$q(:, -$dims[0]:) .= $m;
		}
		elsif ($dims[0] > $dims[1]){
			$q = $m(:,-$min:)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->orgql($tau, $info);
		return $q->xchg(0,1)->sever unless wantarray;

		if ($dims[0] < $dims[1] && $full){
			$l = zeroes ($m->type,$dims[0],$dims[1]);
			$m->xchg(0,1)->tricpy(1,$l);
			$l(:($min-1),:($min-1))->diagonal(0,1) .= 0;
		}
		elsif ($dims[0] > $dims[1]){
			my $temp = zeroes($m->type,$dims[0],$dims[0]);
			$temp(:, -$dims[1]:) .= $m->xchg(0,1);
			$l = PDL::zeroes($temp);
			$temp->tricpy(1,$l);
			$l = $l(:, -$dims[1]:)->sever;
		}
		else{
			$l = zeroes($m->type, $min, $min);
			$m->xchg(0,1)->(:,($dims[1]-$min):)->tricpy(1,$l);
		}
	}
	return ($q->xchg(0,1)->sever, $l, $info);

}

sub PDL::Complex::mql{
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $l);


	barf("mql: Require a matrix") unless @dims == 3;
        $m = $m->xchg(1,2)->copy;
	my $min = $dims[1] < $dims[2] ?  $dims[1] : $dims[2];
	
	my $tau = zeroes($m->type, 2, $min);
	$m->cgeqlf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mql: Error $info in cgeqlf\n");
		$q = $l = $m;
	}
	else{
		if ($dims[1] < $dims[2] && $full){
			$q = PDL::new_from_specification('PDL::Complex', $m->type, 2, $dims[2],$dims[2]);
			$q .= 0;
			$q(,:, -$dims[1]:) .= $m;
		}
		elsif ($dims[1] > $dims[2]){
			$q = $m(,:,-$min:)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->cungql($tau, $info);
		return $q->xchg(1,2)->sever unless wantarray;

		if ($dims[1] < $dims[2] && $full){
			$l = PDL::new_from_specification('PDL::Complex', $m->type, 2, $dims[1], $dims[2]);
			$l .= 0;
			$m->xchg(1,2)->ctricpy(1,$l);
			$l(,:($min-1),:($min-1))->diagonal(1,2) .= 0;
		}
		elsif ($dims[1] > $dims[2]){
			my $temp = PDL::new_from_specification('PDL::Complex',$m->type,2,$dims[1],$dims[1]);
			$temp .= 0;
			$temp(,, -$dims[2]:) .= $m->xchg(1,2);
			$l = PDL::zeroes($temp);
			$temp->ctricpy(1,$l);
			$l = $l(,, -$dims[2]:)->sever;
		}
		else{
			$l = PDL::new_from_specification('PDL::Complex',$m->type, 2, $min, $min);
			$l .= 0;
			$m->xchg(1,2)->(,,($dims[2]-$min):)->ctricpy(1,$l);
		}
	}
	return ($q->xchg(1,2)->sever, $l, $info);

}

=head2 mlq

=for ref

Computes LQ decomposition.
For complex number needs object of type PDL::Complex.
Uses L<gelqf|PDL::LinearAlgebra::Real/gelqf> and L<orglq|PDL::LinearAlgebra::Real/orglq>
or L<cgelqf|PDL::LinearAlgebra::Complex/cgelqf> and L<cunglq|PDL::LinearAlgebra::Complex/cunglq>
from Lapack and returns C<Q> in scalar context. Works on transposed array.

=for usage

 ( PDL(L), PDL(Q), PDL(info) ) = mlq(PDL, SCALAR)
 SCALAR : ECONOMIC = 0 | FULL = 1, default = 0

=for example

 my $a = random(10,10);
 my ( $l, $q )  = mlq($a);
 # Can compute full decomposition if nrow < ncol
 $a = random(5,7);
 ( $l, $q )  = $a->mlq(1);

=cut

sub mlq{ 
	my $m = shift;
	$m->mlq(@_);
}

sub PDL::mlq {
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $l);

	barf("mlq: Require a matrix") unless @dims == 2;
        $m = $m->xchg(0,1)->copy;
	my $min = $dims[0] < $dims[1] ?  $dims[0] : $dims[1];
	
	my $tau = zeroes($m->type, $min);
	$m->gelqf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mlq: Error $info in gelqf\n");
		$q = $l = $m;
	}
	else{
		if ($dims[0] > $dims[1] && $full){
			$q = zeroes($m->type, $dims[0],$dims[0]);
			$q(:($min -1),:) .= $m;
		}
		elsif ($dims[0] < $dims[1]){
			$q = $m(:($min-1),)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->orglq($tau, $info);
		return $q->xchg(0,1)->sever unless wantarray;
	
		if ($dims[0] > $dims[1] && !$full){
			$l = zeroes($m->type, $dims[1], $dims[1]);
			$m->xchg(0,1)->(:($min-1))->tricpy(1,$l);
		}
		else{
			$l = zeroes($m->type, $dims[0], $dims[1]);
			$m->xchg(0,1)->tricpy(1,$l);
		}
	}
	return ($l, $q->xchg(0,1)->sever, $info);

}

sub PDL::Complex::mlq{
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $l);

	barf("mlq: Require a matrix") unless @dims == 3;
        $m = $m->xchg(1,2)->copy;
	my $min = $dims[1] < $dims[2] ?  $dims[1] : $dims[2];
	
	my $tau = zeroes($m->type, 2, $min);
	$m->cgelqf($tau, (my $info = pdl(long,0)));
	if ($info){
		laerror("mlq: Error $info in cgelqf\n");
		$q = $l = $m;
	}
	else{
		if ($dims[1] > $dims[2] && $full){
			$q = PDL::new_from_specification('PDL::Complex',$m->type, 2, $dims[1],$dims[1]);
			$q .= 0;
			$q(,:($min -1),:) .= $m;
		}
		elsif ($dims[1] < $dims[2]){
			$q = $m(,:($min-1),)->copy;
		}
		else{
			$q = $m->copy;			
		}
	
		$q->cunglq($tau, $info);
		return $q->xchg(1,2)->sever unless wantarray;
	
		if ($dims[1] > $dims[2] && !$full){
			$l = PDL::new_from_specification('PDL::Complex',$m->type, 2, $dims[2], $dims[2]);
			$l .= 0;
			$m->xchg(1,2)->(,:($min-1))->ctricpy(1,$l);
		}
		else{
			$l = PDL::new_from_specification('PDL::Complex',$m->type, 2, $dims[1], $dims[2]);
			$l .= 0;
			$m->xchg(1,2)->ctricpy(1,$l);
		}
	}
	return ($l, $q->xchg(1,2)->sever, $info);

}

=head2 msolve

=for ref

Solves linear system of equations using LU decomposition.
	
	A * X = B

Returns X in scalar context else X, LU, pivot vector and info.
B is overwritten by X if its inplace flag is set.
Supports threading.
Uses L<gesv|PDL::LinearAlgebra::Real/gesv> or L<cgesv|PDL::LinearAlgebra::Complex/cgesv> from Lapack.
Works on transposed arrays.

=for usage

 (PDL(X), (PDL(LU), PDL(pivot), PDL(info))) = msolve(PDL(A), PDL(B) )

=for example

 my $a = random(5,5);
 my $b = random(10,5);
 my $X = msolve($a, $b);

=cut


sub msolve{
	my $m = shift;
	$m->msolve(@_);
}

sub PDL::msolve {
	my($a, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($ipiv, $info, $c);

	barf("msolve: Require square coefficient array(s)")
		unless( (@adims >= 2) && $adims[0] == $adims[1] );
	barf("msolve: Require right hand side array(s) B with number".
			 " of row equal to number of columns of A")
		unless( (@bdims >= 2) && $bdims[1] == $adims[0]);
	barf("msolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);
	
	$a = $a->xchg(0,1)->copy;
	$c = $b->is_inplace ? $b->xchg(0,1) : $b->xchg(0,1)->copy;
	$ipiv = zeroes(long, @adims[1..$#adims]);
	@adims = @adims[2..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->gesv($c, $ipiv, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msolve: Can't solve system of linear equations (after getrf factorization): matrix (PDL(s)  @list) is/are singular(s): \$info = $info");
	}
	return wantarray ? $b->is_inplace(0) ? ($b, $a->xchg(0,1)->sever, $ipiv, $info) : ($c->xchg(0,1)->sever , $a->xchg(0,1)->sever, $ipiv, $info) : 
			$b->is_inplace(0) ? $b : $c->xchg(0,1)->sever;

}

sub PDL::Complex::msolve {
	my($a, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($ipiv, $info, $c);

	barf("msolve: Require square coefficient array(s)")
		unless( (@adims >= 3) && $adims[1] == $adims[2] );
	barf("msolve: Require right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 3) && $bdims[2] == $adims[1]);
	barf("msolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);
	
	$a = $a->xchg(1,2)->copy;
	$c = $b->is_inplace ?  $b->xchg(1,2) : $b->xchg(1,2)->copy;
	$ipiv = zeroes(long, @adims[2..$#adims]);
	@adims = @adims[3..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->cgesv($c, $ipiv, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msolve: Can't solve system of linear equations (after cgetrf factorization): matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}
	return wantarray ? $b->is_inplace(0) ? ($b, $a->xchg(1,2)->sever, $ipiv, $info) : ($c->xchg(1,2)->sever , $a->xchg(1,2)->sever, $ipiv, $info): 
			$b->is_inplace(0) ? $b : $c->xchg(1,2)->sever;

}

=head2 msolvex

=for ref

Solves linear system of equations using LU decomposition.
	
	A * X = B

Can optionnally equilibrate the matrix. 
Uses L<gesvx|PDL::LinearAlgebra::Real/gesvx> or L<cgesvx|PDL::LinearAlgebra::Complex/cgesvx> from Lapack.
Works on transposed arrays.

=for usage

 (PDL, (HASH(result))) = msolvex(PDL(A), PDL(B), HASH(options))
 where options are:
 transpose:	solves A' * X = B
		0: false
		1: true
 equilibrate:	equilibrates A if necessary.
		form equilibration is returned in HASH{'equilibration'}:
			0: no equilibration
			1: row equilibration
			2: column equilibration
		row scale factors are returned in HASH{'row'} 
		column scale factors are returned in HASH{'column'} 
		0: false
		1: true
 LU:    	returns lu decomposition in HASH{LU}
		0: false
		1: true
 A:		returns scaled A if equilibration was done in HASH{A}  
		0: false
		1: true
 B:		returns scaled B if equilibration was done in HASH{B} 
		0: false
		1: true
 Returned values:
		X (SCALAR CONTEXT),
		HASH{'pivot'}:
	    	 Pivot indice from LU factorization
		HASH{'rcondition'}:
	    	 Reciprocal condition of the matrix
		HASH{'ferror'}:
	    	 Forward error bound 
		HASH{'berror'}:
		 Componentwise relative backward error
		HASH{'rpvgrw'}:
		 Reciprocal pivot growth factor
		HASH{'info'}:
	    	 Info: output from gesvx

=for example

 my $a = random(10,10);
 my $b = random(5,10);
 my %options = (
 		LU=>1,
 		equilibrate => 1,
		);
 my( $X, %result) = msolvex($a,$b,%options);

=cut


*msolvex = \&PDL::msolvex;

sub PDL::msolvex {
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ( $af, $x, $ipiv, $info, $equilibrate, $berr, $ferr, $rcond, $equed, %result, $r, $c ,$rpvgrw);

	barf("msolvex: Require a square coefficient matrix")
		unless( ((@adims == 2) || (@adims == 3)) && $adims[-1] == $adims[-2] );
	barf("msolvex: Require a right hand side matrix B with number".
			 " of row equal to order of A")
		unless( ((@bdims == 2) || (@bdims == 3))&& $bdims[-1] == $adims[-2]);

	
	$equilibrate = $opt{'equilibrate'} ? pdl(long, 2): pdl(long,1);
	$a = $a->t->copy;
	$b = $b->t->copy;
	$x = PDL::zeroes $b;
	$af = PDL::zeroes $a;
       	$info = pdl(long, 0);
       	$rcond = null;
       	$rpvgrw = null;
	$equed = pdl(long, 0);

	$c = zeroes($a->type, $adims[-2]);
	$r = zeroes($a->type, $adims[-2]);
	$ipiv = zeroes(long, $adims[-2]);
	$ferr = zeroes($b->type, $bdims[-2]);
	$berr = zeroes($b->type, $bdims[-2]);	
	
	( @adims == 3 ) ? $a->cgesvx($opt{'transpose'}, $equilibrate, $b, $af, $ipiv, $equed, $r, $c, $x, $rcond, $ferr, $berr, $rpvgrw,$info) :
			$a->gesvx($opt{'transpose'}, $equilibrate, $b, $af, $ipiv, $equed, $r, $c, $x, $rcond, $ferr, $berr, $rpvgrw,$info); 	
	if( $info < $adims[-2] && $info > 0){
		$info--;
		laerror("msolvex: Can't solve system of linear equations:\nfactor U($info,$info)".
		" of coefficient matrix is exactly 0");
	}
	elsif ($info != 0 and $_laerror){
		warn ("msolvex: The matrix is singular to working precision");
	}

	return $x->xchg(-1,-2)->sever unless wantarray;

	$result{rcondition} = $rcond;
	$result{ferror} = $ferr;
	$result{berror} = $berr;
	if ($opt{equilibrate}){
		$result{equilibration} = $equed;
		$result{row} = $r if $equed == 1 || $equed == 3;
		$result{column} = $c if $equed == 2 || $equed == 3;
		if ($equed){
			$result{A} = $a->xchg(-2,-1)->sever if $opt{A};
			$result{B} = $b->xchg(-2,-1)->sever if $opt{B};
		}
	}
	$result{pivot} = $ipiv;
	$result{rpvgrw} = $rpvgrw;
	$result{info} = $info;
        $result{LU} = $af->xchg(-2,-1)->sever if $opt{LU};
 
	return ($x->xchg(-2,-1)->sever, %result);

}

=head2 mtrisolve

=for ref

Solves linear system of equations with triangular matrix A.
	
	A * X = B  or A' * X = B

B is overwritten by X if its inplace flag is set.
Supports threading.
Uses L<trtrs|PDL::LinearAlgebra::Real/trtrs> or L<ctrtrs|PDL::LinearAlgebra::Complex/ctrtrs> from Lapack.
Work on transposed array(s).

=for usage

 (PDL(X), (PDL(info)) = mtrisolve(PDL(A), SCALAR(uplo), PDL(B), SCALAR(trans), SCALAR(diag))
 uplo	: UPPER  = 0 | LOWER = 1
 trans	: NOTRANSPOSE  = 0 | TRANSPOSE = 1, default = 0
 uplo	: UNITARY DIAGONAL = 1, default = 0

=for example

 # Assume $a is upper triagonal
 my $a = random(5,5);
 my $b = random(5,10);
 my $X = mtrisolve($a, 0, $b);

=cut


sub mtrisolve{
	my $m = shift;
	$m->mtrisolve(@_);
}

sub PDL::mtrisolve{
	my($a, $uplo, $b, $trans, $diag) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $c);

	barf("mtrisolve: Require square coefficient array(s)")
		unless( (@adims >= 2) && $adims[0] == $adims[1] );
	barf("mtrisolve: Require 2D right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 2) && $bdims[1] == $adims[0]);
	barf("mtrisolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;	
       	$trans = 1 - $trans;
	$c = $b->is_inplace ? $b->xchg(0,1) : $b->xchg(0,1)->copy;
	@adims = @adims[2..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->trtrs($uplo, $trans, $diag, $c, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mtrisolve: Can't solve system of linear equations: matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}
	return wantarray  ? $b->is_inplace(0) ? ($b, $info) : ($c->xchg(0,1)->sever, $info) : 
				$b->is_inplace(0) ? $b : $c->xchg(0,1)->sever;
}

sub PDL::Complex::mtrisolve{
	my($a, $uplo, $b, $trans, $diag) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $c);

	barf("mtrisolve: Require square coefficient array(s)")
		unless( (@adims >= 3) && $adims[1] == $adims[2] );
	barf("mtrisolve: Require 2D right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 3) && $bdims[2] == $adims[1]);
	barf("mtrisolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;	
       	$trans = 1 - $trans;
	$c = $b->is_inplace ? $b->xchg(1,2) : $b->xchg(1,2)->copy;
	@adims = @adims[3..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->ctrtrs($uplo, $trans, $diag, $c, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mtrisolve: Can't solve system of linear equations: matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}
	return wantarray  ? $b->is_inplace(0) ? ($b, $info) : ($c->xchg(1,2)->sever, $info) : 
				$b->is_inplace(0) ? $b : $c->xchg(1,2)->sever;
}

=head2 msymsolve

=for ref

Solves linear system of equations using diagonal pivoting method with symmetric matrix A.
	
	A * X = B

Returns X in scalar context else X, block diagonal matrix D (and the
multipliers), pivot vector an info. B is overwritten by X if its inplace flag is set.
Supports threading.
Uses L<sysv|PDL::LinearAlgebra::Real/sysv> or L<csysv|PDL::LinearAlgebra::Complex/csysv> from Lapack.
Works on transposed array(s).

=for usage

 (PDL(X), ( PDL(D), PDL(pivot), PDL(info) ) ) = msymsolve(PDL(A), SCALAR(uplo), PDL(B) )
 uplo : UPPER  = 0 | LOWER = 1, default = 0

=for example

 # Assume $a is symmetric
 my $a = random(5,5);
 my $b = random(5,10);
 my $X = msymsolve($a, 0, $b);

=cut

sub msymsolve{
	my $m = shift;
	$m->msymsolve(@_);
}

sub PDL::msymsolve {
	my($a, $uplo, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($ipiv, $info, $c);

	barf("msymsolve: Require square coefficient array(s)")
		unless( (@adims >= 2) && $adims[0] == $adims[1] );
	barf("msymsolve: Require 2D right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 2)&& $bdims[1] == $adims[0]);
	barf("msymsolve: Require array(s) with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;
	$a = $a->copy;
	$c =  $b->is_inplace ? $b->xchg(0,1) : $b->xchg(0,1)->copy;
	$ipiv = zeroes(long, @adims[1..$#adims]);
	@adims = @adims[2..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);

	$a->sysv($uplo, $c, $ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymsolve: Can't solve system of linear equations (after sytrf factorization): matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	
	wantarray ? (  ( $b->is_inplace(0) ? $b : $c->xchg(0,1)->sever ), $a, $ipiv, $info): 
		$b->is_inplace(0) ? $b : $c->xchg(0,1)->sever;

}

sub PDL::Complex::msymsolve {
	my($a, $uplo, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($ipiv, $info, $c);

	barf("msymsolve: Require square coefficient array(s)")
		unless( (@adims >= 3) && $adims[1] == $adims[2] );
	barf("msymsolve: Require 2D right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 3)&& $bdims[2] == $adims[1]);
	barf("msymsolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;
	$a = $a->copy;
	$c =  $b->is_inplace ? $b->xchg(1,2) : $b->xchg(1,2)->copy;
	$ipiv = zeroes(long, @adims[2..$#adims]);
	@adims = @adims[3..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);

	$a->csysv($uplo, $c, $ipiv, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymsolve: Can't solve system of linear equations (after csytrf factorization): matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	
	wantarray ? (  ( $b->is_inplace(0) ? $b : $c->xchg(1,2)->sever ), $a, $ipiv, $info): 
		$b->is_inplace(0) ? $b : $c->xchg(1,2)->sever;

}

=head2 msymsolvex

=for ref

Solves linear system of equations using diagonal pivoting method with symmetric matrix A.
	
	A * X = B

Uses L<sysvx|PDL::LinearAlgebra::Real/sysvx> or L<csysvx|PDL::LinearAlgebra::Complex/csysvx>
from Lapack. Works on transposed array.

=for usage

 (PDL, (HASH(result))) = msymsolvex(PDL(A), SCALAR (uplo), PDL(B), SCALAR(d))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 d    : whether return diagonal matrix d and pivot vector
 	FALSE  = 0 | TRUE = 1, default = 0 
 Returned values:
		X (SCALAR CONTEXT),
		HASH{'D'}:
		 Block diagonal matrix D (and the multipliers) (if requested)
		HASH{'pivot'}:
	    	 Pivot indice from LU factorization (if requested)
		HASH{'rcondition'}:
	    	 Reciprocal condition of the matrix
		HASH{'ferror'}:
	    	 Forward error bound 
		HASH{'berror'}:
		 Componentwise relative backward error
		HASH{'info'}:
	    	 Info: output from sysvx

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my $b = random(5,10);
 my ($X, %result) = msolvex($a, 0, $b);


=cut


*msymsolvex = \&PDL::msymsolvex;

sub PDL::msymsolvex {
	my($a, $uplo, $b, $d) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ( $af, $x, $ipiv, $info, $berr, $ferr, $rcond, %result);

	barf("msymsolvex: Require a square coefficient matrix")
		unless( ((@adims == 2) || (@adims == 3)) && $adims[-1] == $adims[-2] );
	barf("msymsolvex: Require a right hand side matrix B with number".
			 " of row equal to order of A")
		unless( ((@bdims == 2) || (@bdims == 3))&& $bdims[-1] == $adims[-2]);

	
	$uplo = 1 - $uplo;
	$b = $b->t;
	$x = PDL::zeroes $b;
	$af =  PDL::zeroes $a;
       	$info = pdl(long, 0);
       	$rcond = null;

	$ipiv = zeroes(long, $adims[-2]);
	$ferr = zeroes($b->type, $bdims[-2]);
	$berr = zeroes($b->type, $bdims[-2]);	
	
	(@adims == 3) ?  $a->csysvx($uplo, (pdl(long, 0)), $b, $af, $ipiv, $x, $rcond, $ferr, $berr, $info) :
		$a->sysvx($uplo, (pdl(long, 0)), $b, $af, $ipiv, $x, $rcond, $ferr, $berr, $info);
	if( $info < $adims[-2] && $info > 0){
		$info--;
		laerror("msymsolvex: Can't solve system of linear equations:\nfactor D($info,$info)".
		" of coefficient matrix is exactly 0");
	}
	elsif ($info != 0 and $_laerror){
		warn("msymsolvex: The matrix is singular to working precision");
	}
	$result{rcondition} = $rcond;
	$result{ferror} = $ferr;
	$result{berror} = $berr;
	$result{info} = $info;
        if ($d){
		$result{D} = $af;
		$result{pivot} = $ipiv;
	}
 
	wantarray ? ($x->xchg(-2,-1)->sever, %result): $x->xchg(-2,-1)->sever;

}

=head2 mpossolve

=for ref

Solves linear system of equations using Cholesky decomposition with 
symmetric positive definite matrix A.
	
	A * X = B

Returns X in scalar context else X, U or L and info. 
B is overwritten by X if its inplace flag is set.
Supports threading.
Uses L<posv|PDL::LinearAlgebra::Real/posv> or L<cposv|PDL::LinearAlgebra::Complex/cposv> from Lapack.
Works on transposed array(s).

=for usage

 (PDL, (PDL, PDL, PDL)) = mpossolve(PDL(A), SCALAR(uplo), PDL(B) )
 uplo : UPPER  = 0 | LOWER = 1, default = 0

=for example

 # asume $a is symmetric positive definite
 my $a = random(5,5);
 my $b = random(5,10);
 my $X = mpossolve($a, 0, $b);

=cut


sub mpossolve{
	my $m = shift;
	$m->mpossolve(@_);
}

sub PDL::mpossolve {
	my($a, $uplo, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $c);

	barf("mpossolve: Require square coefficient array(s)")
		unless( (@adims >= 2) && $adims[0] == $adims[1] );
	barf("mpossolve: Require right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 2)&& $bdims[1] == $adims[0]);
	barf("mpossolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;
	$a = $a->copy;
	$c = $b->is_inplace ? $b->xchg(0,1) :  $b->xchg(0,1)->copy;
	@adims = @adims[2..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->posv($uplo, $c, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mpossolve: Can't solve system of linear equations: matrix (PDL(s) @list) is/are not positive definite(s): \$info = $info");
	}
	wantarray ? $b->is_inplace(0) ? ($b, $a,$info) : ($c->xchg(0,1)->sever , $a,$info) : $b->is_inplace(0) ? $b : $c->xchg(0,1)->sever;
}

sub PDL::Complex::mpossolve {
	my($a, $uplo, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $c);

	barf("mpossolve: Require square coefficient array(s)")
		unless( (@adims >= 3) && $adims[1] == $adims[2] );
	barf("mpossolve: Require right hand side array(s) B with number".
			 " of row equal to order of A")
		unless( (@bdims >= 3)&& $bdims[2] == $adims[1]);
	barf("mpossolve: Require arrays with equal number of dimensions")
		if( @adims != @bdims);

       	$uplo = 1 - $uplo;
	$a = $a->copy;
	$c = $b->is_inplace ? $b->xchg(1,2) :  $b->xchg(1,2)->copy;
	@adims = @adims[3..$#adims];
	$info = @adims ? zeroes(long,@adims) : pdl(long,0);
	$a->cposv($uplo, $c, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mpossolve: Can't solve system of linear equations: matrix (PDL(s) @list) is/are not positive definite(s): \$info = $info");
	}
	wantarray ? $b->is_inplace(0) ? ($b, $a,$info) : ($c->xchg(1,2)->sever , $a,$info) : $b->is_inplace(0) ? $b : $c->xchg(1,2)->sever;
}

=head2 mpossolvex

=for ref

Solves linear system of equations using Cholesky decomposition with 
symmetric positive definite matrix A
	
	A * X = B

Can optionnally equilibrate the matrix. 
Uses L<posvx|PDL::LinearAlgebra::Real/posvx> or
L<cposvx|PDL::LinearAlgebra::Complex/cposvx> from Lapack.
Works on transposed array(s).

=for usage

 (PDL, (HASH(result))) = mpossolvex(PDL(A), SCARA(uplo), PDL(B), HASH(options))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 where options are:
 equilibrate:	equilibrates A if necessary.
		form equilibration is returned in HASH{'equilibration'}:
			0: no equilibration
			1: equilibration
		scale factors are returned in HASH{'scale'} 
		0: false
		1: true
 U|L:    	returns Cholesky factorization in HASH{U} or HASH{L}
		0: false
		1: true
 A:		returns scaled A if equilibration was done in HASH{A}  
		0: false
		1: true
 B:		returns scaled B if equilibration was done in HASH{B} 
		0: false
		1: true
 Returned values:
		X (SCALAR CONTEXT),
		HASH{'rcondition'}:
	    	 Reciprocal condition of the matrix
		HASH{'ferror'}:
	    	 Forward error bound 
		HASH{'berror'}:
		 Componentwise relative backward error
		HASH{'info'}:
	    	 Info: output from gesvx

=for example

 # Assume $a is symmetric positive definite
 my $a = random(10,10);
 my $b = random(5,10);
 my %options = (U=>1,
 		equilibrate => 1,
		);
 my ($X, %result) = msolvex($a, 0, $b,%opt);

=cut


*mpossolvex = \&PDL::mpossolvex;

sub PDL::mpossolvex {
	my($a, $uplo, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ( $af, $x, $info, $equilibrate, $berr, $ferr, $rcond, $equed, %result, $s);

	barf("mpossolvex: Require a square coefficient matrix")
		unless( ((@adims == 2) || (@adims == 3)) && $adims[-1] == $adims[-2] );
	barf("mpossolvex: Require a 2D right hand side matrix B with number".
			 " of row equal to order of A")
		unless( ((@bdims == 2) || (@bdims == 3))&& $bdims[-1] == $adims[-2]);

	
	$uplo = $uplo ? pdl(long, 0): pdl(long, 1);
	$equilibrate = $opt{'equilibrate'} ? pdl(long, 2): pdl(long,1);
	$a = $a->copy;
	$b = $b->t->copy;
	$x = PDL::zeroes $b;
	$af = PDL::zeroes $a;
       	$info = pdl(long, 0);
       	$rcond = null;
	$equed = pdl(long, 0);

	$s = zeroes($a->type, $adims[-2]);
	$ferr = zeroes($b->type, $bdims[-2]);
	$berr = zeroes($b->type, $bdims[-2]);	
	
	(@adims == 3) ? $a->cposvx($uplo, $equilibrate, $b, $af, $equed, $s, $x, $rcond, $ferr, $berr, $info) :
		$a->posvx($uplo, $equilibrate, $b, $af, $equed, $s, $x, $rcond, $ferr, $berr, $info);
	if( $info < $adims[-2] && $info > 0){
		$info--;
		barf("mpossolvex: Can't solve system of linear equations:\n".
			"the leading minor of order $info of A is".
                         " not positive definite");
		return;
	}
	elsif ( $info  and $_laerror){
		warn("mpossolvex: The matrix is singular to working precision");
	}
	$result{rcondition} = $rcond;
	$result{ferror} = $ferr;
	$result{berror} = $berr;
	if ($opt{equilibrate}){
		$result{equilibration} = $equed;
		if ($equed){
			$result{scale} = $s if $equed;
			$result{A} = $a if $opt{A};
			$result{B} = $b->xchg(-2,-1)->sever if $opt{B};
		}
	}
	$result{info} = $info;
        $result{L} = $af if $opt{L};
        $result{U} = $af if $opt{U}; 

	wantarray ? ($x->xchg(-2,-1)->sever, %result): $x->xchg(-2,-1)->sever;

}

=head2 mlls

=for ref

Solves overdetermined or underdetermined real linear systems using QR or LQ factorization.

If M > N in the M-by-N matrix A, returns the residual sum of squares too.
Uses L<gels|PDL::LinearAlgebra::Real/gels> or L<cgels|PDL::LinearAlgebra::Complex/cgels> from Lapack.
Works on transposed arrays.

=for usage

 PDL(X) = mlls(PDL(A), PDL(B), SCALAR(trans))
 trans : NOTRANSPOSE  = 0 | TRANSPOSE/CONJUGATE = 1, default = 0

=for example

 $a = random(4,5);
 $b = random(3,5);
 ($x, $res) = mlls($a, $b);

=cut

*mlls = \&PDL::mlls;

sub PDL::mlls {
	my($a, $b, $trans) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $x, $type);

	barf("mlls: Require a matrix")
		unless( @adims == 2 ||  @adims == 3);
	barf("mlls: Require a 2D right hand side matrix B with number".
			 " of rows equal to number of rows of A")	
		unless( (@bdims == 2 || @bdims == 3)&& $bdims[-1] == $adims[-1]);

	$a = $a->copy;
	$type = $a->type;
	if ( $adims[-1] < $adims[-2]){
		if (@adims == 3){
			$x = PDL::new_from_specification('PDL::Complex', $type, 2,$adims[1], $bdims[1]);
			$x(, :($bdims[2]-1), :($bdims[1]-1)) .= $b->xchg(1,2);
		}
		else{
			$x = PDL::new_from_specification('PDL', $type, $adims[0], $bdims[0]);
			$x(:($bdims[1]-1), :($bdims[0]-1)) .= $b->xchg(0,1);		
		}
	}
	else{
		$x = $b->xchg(-2,-1)->copy;	
	}
	$info = pdl(long,0);

	if (@adims == 3){
		$trans ? $a->xchg(1,2)->cgels(1, $x, $info) : $a->xchg(1,2)->cgels(0, $x, $info);
	}
	else{
		$trans ? $a->gels(0, $x, $info) : $a->gels(1, $x, $info);
	}

	$x = $x->xchg(-2,-1);	
	if ( $adims[-1] <= $adims[-2]){	
		return $x->sever;
	}

	
	if(@adims == 2){
		wantarray ? return($x(, :($adims[0]-1))->sever, $x(, $adims[0]:)->xchg(0,1)->pow(2)->sumover) : 
					return $x(, :($adims[0]-1))->sever;
	}
	else{
		wantarray ? return($x(,, :($adims[1]-1))->sever, PDL::Ufunc::sumover(PDL::Complex::Cpow($x(,, $adims[1]:),pdl($type,2,0))->reorder(2,0,1))) : 
					return $x(,, :($adims[1]-1))->sever;	
	}
}

=head2 mllsy

=for ref

Computes the minimum-norm solution to a real linear least squares problem
using a complete orthogonal factorization.

Uses L<gelsy|PDL::LinearAlgebra::Real/gelsy> or L<cgelsy|PDL::LinearAlgebra::Complex/cgelsy>
from Lapack. Works on tranposed arrays.

=for usage

 ( PDL(X), ( HASH(result) ) ) = mllsy(PDL(A), PDL(B))
 Returned values:
		X (SCALAR CONTEXT),
		HASH{'A'}:
	    	 complete orthogonal factorization of A
		HASH{'jpvt'}:
	    	 details of columns interchanges 
		HASH{'rank'}:
	    	 effective rank of A

=for example

 my $a = random(10,10);
 my $b = random(10,10);
 $X = mllsy($a, $b);

=cut

*mllsy = \&PDL::mllsy;

sub PDL::mllsy {
	my($a, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $x, $rcond, $rank, $jpvt, $type);

	barf("mllsy: Require a matrix")
		unless( @adims == 2 || @adims == 3);
	barf("mllsy: Require a 2D right hand side matrix B with number".
			 " of rows equal to number of rows of A")	
		unless( (@bdims == 2 || @bdims == 3)&& $bdims[-1] == $adims[-1]);

	$type = $a->type;
	$rcond = lamch(pdl($type,0));
	$rcond = $rcond->sqrt - ($rcond->sqrt - $rcond) / 2;

	$a = $a->xchg(-2,-1)->copy;

	if ( $adims[1] < $adims[0]){
		if (@adims == 3){
			$x = PDL::new_from_specification('PDL::Complex', $type, 2, $adims[1], $bdims[1]);
			$x(, :($bdims[2]-1), :($bdims[1]-1)) .= $b->xchg(1,2);
		}
		else{
			$x = PDL::new_from_specification('PDL', $type, $adims[0], $bdims[0]);
			$x(:($bdims[1]-1), :($bdims[0]-1)) .= $b->xchg(0,1);		
		}

	}
	else{
		$x = $b->xchg(-2,-1)->copy;	
	}
	$info = pdl(long,0);
	$rank = null;
	$jpvt = zeroes(long, $adims[-2]);

	(@adims == 3) ? $a->cgelsy($x,  $rcond, $jpvt, $rank, $info) : 
			$a->gelsy($x,  $rcond, $jpvt, $rank, $info);
	
	if ( $adims[-1] <= $adims[-2]){	
		wantarray ? return ($x->xchg(-2,-1)->sever, ('A'=> $a->xchg(-2,-1)->sever, 'rank' => $rank, 'jpvt'=>$jpvt)) : 
				return $x->xchg(-2,-1)->sever;
	}
	if (@adims == 3){
		wantarray ? return ($x->xchg(1,2)->(,, :($adims[1]-1))->sever, ('A'=> $a->xchg(1,2)->sever, 'rank' => $rank, 'jpvt'=>$jpvt)) : 
				$x->xchg(1,2)->(, :($adims[1]-1))->sever;	
	}
	else{	
		wantarray ? return ($x->xchg(0,1)->(, :($adims[0]-1))->sever, ('A'=> $a->xchg(0,1)->sever, 'rank' => $rank, 'jpvt'=>$jpvt)) : 
				$x->xchg(0,1)->(, :($adims[0]-1))->sever;
	}
}

=head2 mllss

=for ref

Computes the minimum-norm solution to a real linear least squares problem
using a singular value decomposition.

Uses L<gelss|PDL::LinearAlgebra::Real/gelss> or L<gelsd|PDL::LinearAlgebra::Real/gelsd> from Lapack.
Works on transposed arrays.

=for usage

 ( PDL(X), ( HASH(result) ) )= mllss(PDL(A), PDL(B), SCALAR(method))
 method: specifie which method to use (see Lapack for further details)
 	'(c)gelss' or '(c)gelsd', default = '(c)gelsd'
 Returned values:
		X (SCALAR CONTEXT),
		HASH{'V'}:
	    	 if method = (c)gelss, the right singular vectors, stored columnwise
		HASH{'s'}:
	    	 singular values from SVD 
		HASH{'res'}:
		 if A has full rank the residual sum-of-squares for the solution 
		HASH{'rank'}:
	    	 effective rank of A
		HASH{'info'}:
	    	 info output from method

=for example

 my $a = random(10,10);
 my $b = random(10,10);
 $X = mllss($a, $b);

=cut

*mllss = \&PDL::mllss;

sub PDL::mllss {
	my($a, $b, $method) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my ($info, $x, $rcond, $rank, $s, $min, $type);

	barf("mllss: Require a matrix")
		unless( @adims == 2 || @adims == 3);
	barf("mllss: Require a 2D right hand side matrix B with number".
			 " of rows equal to number of rows of A")	
		unless( (@bdims == 2 || @bdims == 3)&& $bdims[-1] == $adims[-1]);


	$type = $a->type;
	#TODO: Add this in option
	$rcond = lamch(pdl($type,0));
	$rcond = $rcond->sqrt - ($rcond->sqrt - $rcond) / 2;

	$a = $a->xchg(-2,-1)->copy;

	if ($adims[1] < $adims[0]){
		if (@adims == 3){
			$x = PDL::new_from_specification('PDL::Complex', $type, 2, $adims[1], $bdims[1]);
			$x(, :($bdims[2]-1), :($bdims[1]-1)) .= $b->xchg(1,2);
		}
		else{
			$x = PDL::new_from_specification('PDL', $type, $adims[0], $bdims[0]);
			$x(:($bdims[1]-1), :($bdims[0]-1)) .= $b->xchg(0,1);		
		}

	}
	else{
		$x = $b->xchg(-2,-1)->copy;	
	}

	$info = pdl(long,0);
	$rank = null;
	$min =  ($adims[-2] > $adims[-1]) ? $adims[-1] : $adims[-2];
	$s = zeroes($a->type, $min);
	
	unless ($method) {
		$method = (@adims == 3) ? 'cgelsd' : 'gelsd';
	}

	$a->$method($x,  $rcond, $s, $rank, $info);
	laerror("mllss: The algorithm for computing the SVD failed to converge\n") if $info;

	$x = $x->xchg(-2,-1);

	if ( $adims[-1] <= $adims[-2]){	
		if (wantarray){
			$method =~ /gelsd/ ? return ($x->sever, ('rank' => $rank, 's'=>$s, 'info'=>$info)):
					(return ($x, ('V'=> $a, 'rank' => $rank, 's'=>$s, 'info'=>$info)) );
		}
		else{return $x;}
	}
	elsif (wantarray){
		if ($rank == $min){
			if (@adims == 3){
				my $res = PDL::Ufunc::sumover(PDL::Complex::Cpow($x(,, $adims[1]:),pdl($type,2,0))->reorder(2,0,1));
				if ($method =~ /gelsd/){
					
					return ($x(,, :($adims[1]-1))->sever,
						('res' => $res, 'rank' => $rank, 's'=>$s, 'info'=>$info));
				}
				else{
					return ($x(,, :($adims[1]-1))->sever,
						('res' => $res, 'V'=> $a, 'rank' => $rank, 's'=>$s, 'info'=>$info));
				}			
			}
			else{
				my $res = $x(, $adims[0]:)->xchg(0,1)->pow(2)->sumover;
				if ($method =~ /gelsd/){
					
					return ($x(, :($adims[0]-1))->sever,
						('res' => $res, 'rank' => $rank, 's'=>$s, 'info'=>$info));
				}
				else{
					return ($x(, :($adims[0]-1))->sever,
						('res' => $res, 'V'=> $a, 'rank' => $rank, 's'=>$s, 'info'=>$info));
				}
			}
		}
		else {
			if (@adims == 3){
				$method =~ /gelsd/ ? return ($x(,, :($adims[1]-1))->sever, ('rank' => $rank, 's'=>$s, 'info'=>$info))
				: ($x(,, :($adims[1]-1))->sever, ('v'=> $a, 'rank' => $rank, 's'=>$s, 'info'=>$info));			
			}
			else{
				$method =~ /gelsd/ ? return ($x(, :($adims[0]-1))->sever, ('rank' => $rank, 's'=>$s, 'info'=>$info))
				: ($x(, :($adims[0]-1))->sever, ('v'=> $a, 'rank' => $rank, 's'=>$s, 'info'=>$info));
			}
		}

	}
	else{return (@adims == 3) ? $x(,, :($adims[1]-1))->sever : $x(, :($adims[0]-1))->sever;}
}

=head2 mglm

=for ref

Solves a general Gauss-Markov Linear Model (GLM) problem.
Supports threading.
Uses L<ggglm|PDL::LinearAlgebra::Real/ggglm> or L<cggglm|PDL::LinearAlgebra::Complex/cggglm>
from Lapack. Works on transposed arrays.

=for usage

 (PDL(x), PDL(y)) = mglm(PDL(a), PDL(b), PDL(d))
 where d is the left hand side of the GLM equation

=for example

 my $a = random(8,10);
 my $b = random(7,10);
 my $d = random(10);
 my ($x, $y) = mglm($a, $b, $d);

=cut

sub mglm{
	my $m = shift;
	$m->mglm(@_);
}

sub PDL::mglm{
	my($a, $b, $d) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my(@ddims) = $d->dims;
	my($x, $y, $info);

	barf("mglm: Require arrays with equal number of rows")
		unless( @adims >= 2 && @bdims >= 2 && $adims[1] == $bdims[1]);
		
	barf "mglm: Require that column(A) <= row(A) <= column(A) + column(B)" unless
		( ($adims[0] <= $adims[1] ) && ($adims[1] <= ($adims[0] + $bdims[0])) );

	barf("mglm: Require vector(s) with size equal to number of rows of A")
		unless( @ddims >= 1  && $adims[1] == $ddims[0]);

	$a = $a->xchg(0,1)->copy;
	$b = $b->xchg(0,1)->copy;
	$d = $d->copy;

	($x, $y, $info) = $a->ggglm($b, $d);
	$x, $y;

}

sub PDL::Complex::mglm {
	my($a, $b, $d) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my(@ddims) = $d->dims;
	my($x, $y, $info);

	barf("mglm: Require arrays with equal number of rows")
		unless( @adims >= 3 && @bdims >= 3 && $adims[2] == $bdims[2]);
		
	barf "mglm: Require that column(A) <= row(A) <= column(A) + column(B)" unless
		( ($adims[2] <= $adims[2] ) && ($adims[2] <= ($adims[1] + $bdims[1])) );

	barf("mglm: Require vector(s) with size equal to number of rows of A")
		unless( @ddims >= 2  && $adims[2] == $ddims[1]);


	$a = $a->xchg(1,2)->copy;
	$b = $b->xchg(1,2)->copy;
	$d = $d->copy;

	($x, $y, $info) = $a->cggglm($b, $d);
	$x, $y;

}


=head2 mlse

=for ref

Solves a linear equality-constrained least squares (LSE) problem.
Uses L<gglse|PDL::LinearAlgebra::Real/gglse> or L<cgglse|PDL::LinearAlgebra::Complex/cgglse>
from Lapack. Works on transposed arrays.

=for usage

 (PDL(x), PDL(res2)) = mlse(PDL(a), PDL(b), PDL(c), PDL(d))
 where 
 c 	: The right hand side vector for the
 	  least squares part of the LSE problem.
 d	: The right hand side vector for the
	  constrained equation.
 x	: The solution of the LSE problem.
 res2	: The residual sum of squares for the solution
	  (returned only in array context)


=for example

 my $a = random(5,4);
 my $b = random(5,3);
 my $c = random(4);
 my $d = random(3);
 my ($x, $res2) = mlse($a, $b, $c, $d);

=cut

*mlse = \&PDL::mlse;

sub PDL::mlse {
	my($a, $b, $c, $d) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my(@cdims) = $c->dims;
	my(@ddims) = $d->dims;

	my($x, $info);

	barf("mlse: Require 2 matrices with equal number of columns")
		unless( ((@adims == 2 && @bdims == 2)||(@adims == 3 && @bdims == 3)) && 
		$adims[-2] == $bdims[-2]);
		
	barf("mlse: Require 1D vector C with size equal to number of A rows")
		unless( (@cdims == 1 || @cdims == 2)&& $adims[-1] == $cdims[-1]);

	barf("mlse: Require 1D vector D with size equal to number of B rows")
		unless( (@ddims == 1 || @ddims == 2)&& $bdims[-1] == $ddims[-1]);

	barf "mlse: Require that row(B) <= column(A) <= row(A) + row(B)" unless
		( ($bdims[-1] <= $adims[-2] ) && ($adims[-2] <= ($adims[-1]+ $bdims[-1])) );



	$a = $a->xchg(-2,-1)->copy;
	$b = $b->xchg(-2,-1)->copy;
	$c = $c->copy;
	$d = $d->copy;
	($x , $info) = (@adims == 3) ?  $a->cgglse($b, $c, $d) : $a->gglse($b, $c, $d);

	if (@adims == 3){
		wantarray ? ($x, PDL::Ufunc::sumover(PDL::Complex::Cpow($c(,($adims[1]-$bdims[2]):($adims[2]-1)),pdl($a->type,2,0))->xchg(0,1))) : $x;	
	}
	else{
		wantarray ? ($x, $c(($adims[0]-$bdims[1]):($adims[1]-1))->pow(2)->sumover) : $x;	
	}

}

=head2 meigen

=for ref

Computes eigenvalues and, optionally, the left and/or right eigenvectors of a general square matrix
(spectral decomposition).
Eigenvectors are normalized (Euclidean norm = 1) and largest component real.
The eigenvalues and eigenvectors returned are object of type PDL::Complex.
If only eigenvalues are requested, info is returned in array context.
Supports threading.
Uses L<geev|PDL::LinearAlgebra::Real/geev> or L<cgeev|PDL::LinearAlgebra::Complex/cgeev> from Lapack.
Works on transposed arrays.

=for usage

 (PDL(values), (PDL(LV),  (PDL(RV)), (PDL(info))) = meigen(PDL, SCALAR(left vector), SCALAR(right vector))
 left vector  : FALSE = 0 | TRUE = 1, default = 0
 right vector : FALSE = 0 | TRUE = 1, default = 0

=for example 

 my $a = random(10,10);
 my ( $eigenvalues, $left_eigenvectors, $right_eigenvectors )  = meigen($a,1,1);

=cut

sub meigen{
	my $m = shift;
	$m->meigen(@_);
}


sub PDL::meigen {
	my($m,$jobvl,$jobvr) = @_;
	my(@dims) = $m->dims;

	barf("meigen: Require square array(s)")
		unless( @dims >= 2 && $dims[0] == $dims[1]);

       	my ($w, $vl, $vr, $info, $type, $wr, $wi);
       	$type = $m->type;

       	$info = null;
	$wr = null;
	$wi = null;

	$vl = $jobvl ? PDL::new_from_specification('PDL', $type, @dims) : 
				pdl($type,0);
	$vr = $jobvr ? PDL::new_from_specification('PDL', $type, @dims) : 
				pdl($type,0);
	$m->xchg(0,1)->geev( $jobvl,$jobvr, $wr, $wi, $vl, $vr, $info);
	if ($jobvl){
		($w, $vl) = cplx_eigen((bless $wr, 'PDL::Complex'), $wi, $vl, 1);
	}
	if ($jobvr){
		($w, $vr) = cplx_eigen((bless $wr, 'PDL::Complex'), $wi, $vr, 1);
	}
	$w = PDL::Complex::ecplx( $wr, $wi ) unless $jobvr || $jobvl;

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("meigen: The QR algorithm failed to converge for PDL(s) @list: \$info = $info");
		print ("Returning converged eigenvalues\n");
	}

	$jobvl? $jobvr ? ($w, $vl->xchg(1,2)->sever, $vr->xchg(1,2)->sever, $info):($w, $vl->xchg(1,2)->sever, $info) : 
					$jobvr? ($w, $vr->xchg(1,2)->sever, $info) : wantarray ? ($w, $info) : $w;
			
}

sub PDL::Complex::meigen {
	my($m,$jobvl,$jobvr) = @_;
	my(@dims) = $m->dims;

	barf("meigen: Require square array(s)")
		unless( @dims >= 3 && $dims[1] == $dims[2]);

       	my ($w, $vl, $vr, $info, $type);
       	$type = $m->type;

       	$info = null;
	
	$w = PDL::Complex->null;
	#PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1]);
	$vl = $jobvl ? PDL::new_from_specification('PDL::Complex', $type, @dims) : 
				pdl($type,[0,0]);
	$vr = $jobvr ? PDL::new_from_specification('PDL::Complex', $type, @dims) : 
				pdl($type,[0,0]);
	$m->xchg(1,2)->cgeev( $jobvl,$jobvr, $w, $vl, $vr, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("meigen: The QR algorithm failed to converge for PDL(s) @list: \$info = $info");
		print ("Returning converged eigenvalues\n");
	}

	$jobvl? $jobvr ? ($w, $vl->xchg(1,2)->sever, $vr->xchg(1,2)->sever, $info):($w, $vl->xchg(1,2)->sever, $info) : 
					$jobvr? ($w, $vr->xchg(1,2)->sever, $info) : wantarray ? ($w, $info) : $w;
			
}


=head2 meigenx

=for ref

Computes eigenvalues, one-norm and, optionally, the left and/or right eigenvectors of a general square matrix
(spectral decomposition).
Eigenvectors are normalized (Euclidean norm = 1) and largest component real. 
The eigenvalues and eigenvectors returned are object of type PDL::Complex.
Uses L<geevx|PDL::LinearAlgebra::Real/geevx> or 
L<cgeevx|PDL::LinearAlgebra::Complex/cgeevx> from Lapack.
Works on transposed arrays.

=for usage

 (PDL(value), (PDL(lv),  (PDL(rv)), HASH(result)), HASH(result)) = meigenx(PDL, HASH(options))
 where options are:
 vector:     eigenvectors to compute
		'left':  computes left eigenvectors
		'right': computes right eigenvectors
		'all':   computes left and right eigenvectors
		 0:     doesn't compute (default)
 rcondition: reciprocal condition numbers to compute (returned in HASH{'rconde'} for eigenvalues and HASH{'rcondv'} for eigenvectors)
		'value':  computes reciprocal condition numbers for eigenvalues
		'vector': computes reciprocal condition numbers for eigenvectors
		'all':    computes reciprocal condition numbers for eigenvalues and eigenvectors
		 0:      doesn't compute (default)
 error:      specifie whether or not it computes the error bounds (returned in HASH{'eerror'} and HASH{'verror'})
	     error bound = EPS * One-norm / rcond(e|v)
	     (reciprocal condition numbers for eigenvalues or eigenvectors must be computed).
 		1: returns error bounds
 		0: not computed
 scale:      specifie whether or not it diagonaly scales the entry matrix
	     (scale details returned in HASH : 'scale')
 		1: scales
 		0: Doesn't scale (default)
 permute:    specifie whether or not it permutes row and columns
	     (permute details returned in HASH{'balance'})
 		1: permutes
 		0: Doesn't permute (default)
 schur:      specifie whether or not it returns the Schur form (returned in HASH{'schur'})
		1: returns Schur form
		0: not returned
 Returned values:
	    eigenvalues (SCALAR CONTEXT),
	    left eigenvectors if requested,
	    right eigenvectors if requested,
	    HASH{'norm'}:
	    	One-norm of the matrix
	    HASH{'info'}:
	    	Info: if > 0, the QR algorithm failed to compute all the eigenvalues
	    	(see syevx for further details)


=for example

 my $a = random(10,10);
 my %options = ( rcondition => 'all',
             vector => 'all',
             error => 1,
             scale => 1,
             permute=>1,
             shur => 1
             );
 my ( $eigenvalues, $left_eigenvectors, $right_eigenvectors, %result)  = meigenx($a,%options);
 print "Error bounds for eigenvalues:\n $eigenvalues\n are:\n". transpose($result{'eerror'}) unless $info;

=cut


*meigenx = \&PDL::meigenx;

sub PDL::meigenx {
	my($m, %opt) = @_;
	my(@dims) = $m->dims;
	barf("meigenx: Require a square matrix")
		unless( ( (@dims == 2)|| (@dims == 3) )&& $dims[-1] == $dims[-2]);
	

	my (%result, $jobvl, $jobvr, $sense, $balanc, $vr, $vl, $rconde, $rcondv,
	$w, $info, $ilo, $ihi, $scale, $abnrm, $type);

	$type = $m->type;
	$info = null;
	$ilo = null;
	$ihi = null;
	$abnrm = null;
	$balanc =  ($opt{'permute'} &&  $opt{'scale'} ) ? 3 : $opt{'permute'} ? 1 : $opt{'scale'} ? 2:0;

	if (@dims == 3){
		$m = $m->copy;
		$w = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1]);
		$scale  =  PDL::new_from_specification('PDL', $type, $dims[1]);
		
		if ($opt{'vector'} eq 'left' || 
			$opt{'vector'} eq 'all' || 
			$opt{'rcondition'} ){
			$jobvl = 1;
			$vl = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]);
		}
		else{
			$jobvl = 0;
			$vl = pdl($type,[0,0]); 	
		}
	
		if ($opt{'vector'} eq 'right' || 
			$opt{'vector'} eq 'all' || 
			$opt{'rcondition'} ){
			$jobvr = 1;
			$vr = PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]);
		}
		else{
			$jobvr = 0;
			$vr = pdl($type,[0,0]);
		}
	
		if ( $opt{'rcondition'} eq 'value'){
			$sense = 1;
			$rconde = PDL::new_from_specification('PDL', $type, $dims[1]);
			$rcondv = pdl($type,0);
		}
		elsif( $opt{'rcondition'} eq 'vector'){
			$sense = 2;
			$rcondv = PDL::new_from_specification('PDL', $type, $dims[1]);
			$rconde = pdl($type,0);
		}
		elsif( $opt{'rcondition'} eq 'all' ){
			$sense = 3;
			$rcondv = PDL::new_from_specification('PDL', $type, $dims[1]);
			$rconde = PDL::new_from_specification('PDL', $type, $dims[1]);
		}	
		else{
			$sense = 0;
			$rconde = pdl($type,0);
			$rcondv = pdl($type,0);
		}
		$m->xchg(1,2)->cgeevx( $jobvl, $jobvr, $balanc,$sense,$w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info);

	}
	else{
		my ($wr, $wi);
		$m = $m->copy;
		$wr = PDL::new_from_specification('PDL', $type, $dims[0]);
		$wi = PDL::new_from_specification('PDL', $type, $dims[0]);
		$scale  =  PDL::new_from_specification('PDL', $type, $dims[0]);
		
		if ($opt{'vector'} eq 'left' || 
			$opt{'vector'} eq 'all' || 
			$opt{'rcondition'} ){
			$jobvl = 1;
			$vl = PDL::new_from_specification('PDL', $type, $dims[0], $dims[0]);
		}
		else{
			$jobvl = 0;
			$vl = pdl($type, 0); 	
		}
	
		if ($opt{'vector'} eq 'right' || 
			$opt{'vector'} eq 'all' || 
			$opt{'rcondition'} ){
			$jobvr = 1;
			$vr = PDL::new_from_specification('PDL', $type, $dims[0], $dims[0]);
		}
		else{
			$jobvr = 0;
			$vr = pdl($type,0);
		}
	
		if ( $opt{'rcondition'} eq 'value'){
			$sense = 1;
			$rconde = PDL::new_from_specification('PDL', $type, $dims[0]);
			$rcondv = pdl($type, 0);
		}
		elsif( $opt{'rcondition'} eq 'vector'){
			$sense = 2;
			$rcondv = PDL::new_from_specification('PDL', $type, $dims[0]);
			$rconde = pdl($type, 0);
		}
		elsif( $opt{'rcondition'} eq 'all' ){
			$sense = 3;
			$rcondv = PDL::new_from_specification('PDL', $type, $dims[0]);
			$rconde = PDL::new_from_specification('PDL', $type, $dims[0]);
		}	
		else{
			$sense = 0;
			$rconde = pdl($type, 0);
			$rcondv = pdl($type, 0);
		}
		$m->xchg(0,1)->geevx( $jobvl, $jobvr, $balanc,$sense,$wr, $wi, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info);
		if ($jobvl){
			($w, $vl) = cplx_eigen((bless $wr, 'PDL::Complex'), $wi, $vl, 1);
		}
		if ($jobvr){
			($w, $vr) = cplx_eigen((bless $wr, 'PDL::Complex'), $wi, $vr, 1);
		}
		$w = PDL::Complex::complex(t(cat $wr, $wi)) unless $jobvr || $jobvl;
	}

	if ($info){
		laerror("meigenx: The QR algorithm failed to converge");
		print "Returning converged eigenvalues\n" if $_laerror;
	}
	
	
	$result{'schur'} = $m if $opt{'schur'};

	if ($opt{'permute'}){
		my $balance = cat $ilo, $ihi;
		$result{'balance'} =  $balance;
	}
	
	$result{'info'} =  $info;
	$result{'scale'} =  $scale if $opt{'scale'};
	$result{'norm'} =  $abnrm;

	if ( $opt{'rcondition'} eq 'vector' || $opt{'rcondition'} eq "all"){
		$result{'rcondv'} =  $rcondv;
		$result{'verror'} = (lamch(pdl($type,0))* $abnrm /$rcondv  ) if $opt{'error'}; 
	}
	if ( $opt{'rcondition'} eq 'value' || $opt{'rcondition'} eq "all"){	
		$result{'rconde'} =  $rconde;
		$result{'eerror'} = (lamch(pdl($type,0))* $abnrm /$rconde  ) if $opt{'error'};
	}
	
	if ($opt{'vector'} eq "left"){
		return ($w, $vl->xchg(-2,-1)->sever, %result);
	}
	elsif ($opt{'vector'} eq "right"){
		return ($w, $vr->xchg(-2,-1)->sever, %result);
	}
	elsif ($opt{'vector'} eq "all"){
		$w, $vl->xchg(-2,-1)->sever, $vr->xchg(-2,-1)->sever, %result;
	}
	else{
		return ($w, %result);		
	}

}

=head2 mgeigen

=for ref

Computes generalized eigenvalues and, optionally, the left and/or right generalized eigenvectors
for a pair of N-by-N real nonsymmetric matrices (A,B) .
The alpha from ratio alpha/beta is object of type PDL::Complex.
Supports threading. Uses L<ggev|PDL::LinearAlgebra::Real/ggev> or
L<cggev|PDL::LinearAlgebra::Complex/cggev> from Lapack.
Works on transposed arrays.

=for usage

 ( PDL(alpha), PDL(beta), ( PDL(LV),  (PDL(RV) ), PDL(info)) = mgeigen(PDL(A),PDL(B) SCALAR(left vector), SCALAR(right vector))
 left vector  : FALSE = 0 | TRUE = 1, default = 0
 right vector : FALSE = 0 | TRUE = 1, default = 0

=for example

 my $a = random(10,10);
 my $b = random(10,10);
 my ( $alpha, $beta, $left_eigenvectors, $right_eigenvectors )  = mgeigen($a, $b,1, 1);

=cut


sub mgeigen{
	my $m = shift;
	$m->mgeigen(@_);
}

sub PDL::mgeigen {
	my($a, $b,$jobvl,$jobvr) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;


	barf("mgeigen: Require 2 square matrices of same order")
		unless( @adims >= 2 && $adims[0] == $adims[1] &&  
		 @bdims >= 2 && $bdims[0] == $bdims[1] && $adims[0] == $bdims[0]);
	barf("mgeigen: Require matrices with equal number of dimensions")
		if( @adims != @bdims);


       	my ($vl, $vr, $info, $beta, $type, $wtmp);
       	$type = $a->type;

	my ($w,$wi);
       	$b = $b->xchg(0,1);
	$wtmp = null;
	$wi = null;
	$beta = null;
	$vl = $jobvl ? PDL::zeroes $a : pdl($type,0);
	$vr = $jobvr ? PDL::zeroes $a : pdl($type,0);
	$info = null;

	$a->xchg(0,1)->ggev($jobvl,$jobvr, $b, $wtmp, $wi, $beta, $vl, $vr, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mgeigen: Can't compute eigenvalues/vectors for PDL(s) @list: \$info = $info");
	}


	$w = PDL::Complex::ecplx ($wtmp, $wi);
	if ($jobvl){
		(undef, $vl) = cplx_eigen((bless $wtmp, 'PDL::Complex'), $wi, $vl, 1);
	}
	if ($jobvr){
		(undef, $vr) = cplx_eigen((bless $wtmp, 'PDL::Complex'), $wi, $vr, 1);
	}



	$jobvl? $jobvr? ($w, $beta, $vl->xchg(1,2)->sever, $vr->xchg(1,2)->sever, $info):($w, $beta, $vl->xchg(1,2)->sever, $info) : 
					$jobvr? ($w, $beta, $vr->xchg(1,2)->sever, $info): ($w, $beta, $info);
			
}

sub PDL::Complex::mgeigen {
	my($a, $b,$jobvl,$jobvr) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;

       	my ($vl, $vr, $info, $beta, $type, $eigens);

       	$type = $a->type;

	barf("mgeigen: Require 2 square matrices of same order")
		unless( @adims >= 3 && $adims[1] == $adims[2] &&  
		 @bdims >= 3 && $bdims[1] == $bdims[2] && $adims[1] == $bdims[1]);
	barf("mgeigen: Require matrices with equal number of dimensions")
		if( @adims != @bdims);


       	$b = $b->xchg(1,2);
	$eigens = PDL::Complex->null;
	$beta = PDL::Complex->null;
	$vl = $jobvl ? PDL::zeroes $a : pdl($type,[0,0]);
	$vr = $jobvr ? PDL::zeroes $a : pdl($type,[0,0]);
       	$info = null;

	$a->xchg(1,2)->cggev($jobvl,$jobvr, $b, $eigens, $beta, $vl, $vr, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mgeigen: Can't compute eigenvalues/vectors for PDL(s) @list: \$info = $info");
	}

	$jobvl? $jobvr? ($eigens, $beta, $vl->xchg(1,2)->sever, $vr->xchg(1,2)->sever, $info):($eigens, $beta, $vl->xchg(1,2)->sever, $info) : 
					$jobvr? ($eigens, $beta, $vr->xchg(1,2)->sever, $info): ($eigens, $beta, $info);
			
}


=head2 mgeigenx

=for ref

Computes generalized eigenvalues, one-norms and, optionally, the left and/or right generalized 
eigenvectors for a pair of N-by-N real nonsymmetric matrices (A,B).
The alpha from ratio alpha/beta is object of type PDL::Complex.
Uses L<ggevx|PDL::LinearAlgebra::Real/ggevx> or
L<cggevx|PDL::LinearAlgebra::Complex/cggevx> from Lapack.
Works on transposed arrays.

=for usage

 (PDL(alpha), PDL(beta), PDL(lv),  PDL(rv), HASH(result) ) = mgeigenx(PDL(a), PDL(b), HASH(options))
 where options are:
 vector:     eigenvectors to compute
		'left':  computes left eigenvectors
		'right': computes right eigenvectors
		'all':   computes left and right eigenvectors
		 0:     doesn't compute (default)
 rcondition: reciprocal condition numbers to compute (returned in HASH{'rconde'} for eigenvalues and HASH{'rcondv'} for eigenvectors)
		'value':  computes reciprocal condition numbers for eigenvalues
		'vector': computes reciprocal condition numbers for eigenvectors
		'all':    computes reciprocal condition numbers for eigenvalues and eigenvectors
		 0:      doesn't compute (default)
 error:      specifie whether or not it computes the error bounds (returned in HASH{'eerror'} and HASH{'verror'})
	     error bound = EPS * sqrt(one-norm(a)**2 + one-norm(b)**2) / rcond(e|v)
	     (reciprocal condition numbers for eigenvalues or eigenvectors must be computed).
 		1: returns error bounds
 		0: not computed
 scale:      specifie whether or not it diagonaly scales the entry matrix
	     (scale details returned in HASH : 'lscale' and 'rscale')
 		1: scales
 		0: doesn't scale (default)
 permute:    specifie whether or not it permutes row and columns
	     (permute details returned in HASH{'balance'})
 		1: permutes
 		0: Doesn't permute (default)
 schur:      specifie whether or not it returns the Schur forms (returned in HASH{'aschur'} and HASH{'bschur'})
	     (right or left eigenvectors must be computed).
		1: returns Schur forms
		0: not returned
 Returned values:
	    alpha,
	    beta,
	    left eigenvectors if requested,
	    right eigenvectors if requested,
	    HASH{'anorm'}, HASH{'bnorm'}:
	    	One-norm of the matrix A and B
	    HASH{'info'}:
	    	Info: if > 0, the QR algorithm failed to compute all the eigenvalues
	    	(see syevx for further details)

=for example

 $a = random(10,10);
 $b = random(10,10);
 %options = (rcondition => 'all',
             vector => 'all',
             error => 1,
             scale => 1,
             permute=>1,
             shur => 1
             );
 ($alpha, $beta, $left_eigenvectors, $right_eigenvectors, %result)  = mgeigenx($a, $b,%options);
 print "Error bounds for eigenvalues:\n $eigenvalues\n are:\n". transpose($result{'eerror'}) unless $info;

=cut


*mgeigenx = \&PDL::mgeigenx;

sub PDL::mgeigenx {
	my($a, $b,%opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my (%result, $jobvl, $jobvr, $sense, $balanc, $vr, $vl, $rconde, $rcondv,
	$wr, $wi, $beta, $info, $ilo, $ihi, $rscale, $lscale, $abnrm, $bbnrm, $type, $eigens);
	
	if (@adims ==3){
		barf("mgeigenx: Require 2 square matrices of same order")
			unless( @adims == 3 && $adims[1] == $adims[2] &&  
			 @bdims == 3 && $bdims[1] == $bdims[2] && $adims[1] == $bdims[1]);

		$a = $a->copy;
		$b = $b->xchg(-1,-2)->copy;

		$eigens = PDL::Complex->null;
		$beta = PDL::Complex->null;

	}
	else{
		barf("mgeigenx: Require 2 square matrices of same order")
			unless( @adims == 2 && $adims[0] == $adims[1] &&  
			 @bdims == 2 && $bdims[0] == $bdims[1] && $adims[0] == $bdims[0]);

		$a = $a->copy;
		$b = $b->xchg(0,1)->copy;

		$wr = null;
		$wi = null;
		$beta= null;

	}

	$type = $a->type;
	$info = null;
	$ilo = null;
	$ihi = null;

	$rscale  = zeroes($type, $adims[-1]);
	$lscale  = zeroes($type, $adims[-1]);
	$abnrm = null;
	$bbnrm = null;
	
	if ($opt{'vector'} eq 'left' || 
		$opt{'vector'} eq 'all' || 
		$opt{'rcondition'} ){
		$jobvl = pdl(long,1);
		$vl = PDL::zeroes $a;
	}
	else{
		$jobvl = pdl(long,0);
		$vl = pdl($type,0);
	}

	if ($opt{'vector'} eq 'right' || 
		$opt{'vector'} eq 'all' || 
		$opt{'rcondition'} ){
		$jobvr = pdl(long,1);
		$vr = PDL::zeroes $a;
	}
	else{
		$jobvr = pdl(long,0);
		$vr = pdl($type,0);	
	}


	if ( $opt{'rcondition'} eq 'value'){
		$sense = pdl(long,1);
		$rconde = zeroes($type, $adims[-1]);
		$rcondv = pdl($type,0);
	}
	elsif( $opt{'rcondition'} eq 'vector'){
		$sense = pdl(long,2);
		$rcondv = zeroes($type, $adims[-1]);
		$rconde = pdl($type,0);
	}
	elsif( $opt{'rcondition'} eq 'all' ){
		$sense = pdl(long,3);
		$rcondv = zeroes($type, $adims[-1]);
		$rconde = zeroes($type, $adims[-1]);
	}	
	else{
		$sense = pdl(long,0);
		$rconde = pdl($type,0);	
		$rcondv = pdl($type,0);
	}


	$balanc =  ($opt{'permute'} &&  $opt{'scale'} ) ? pdl(long,3) : $opt{'permute'} ? pdl(long,1) : $opt{'scale'} ? pdl(long,2) : pdl(long,0);


	if (@adims == 2){
		$a->xchg(0,1)->ggevx($balanc, $jobvl, $jobvr, $sense, $b, $wr, $wi, $beta, $vl, $vr, $ilo, $ihi, $lscale, $rscale,
					$abnrm, $bbnrm, $rconde, $rcondv, $info);
		$eigens = PDL::Complex::complex(t(cat $wr, $wi));
	}
	else{
		$a->xchg(1,2)->cggevx($balanc, $jobvl, $jobvr, $sense, $b, $eigens, $beta, $vl, $vr, $ilo, $ihi, $lscale, $rscale,
					$abnrm, $bbnrm, $rconde, $rcondv, $info);
	}




	if ( ($info > 0) && ($info < $adims[-1])){
		laerror("mgeigenx: The QZ algorithm failed to converge");
		print ("Returning converged eigenvalues\n") if $_laerror;
	}
	elsif($info){
		laerror("mgeigenx: Error from hgeqz or tgevc");
	}


	$result{'aschur'} = $a if $opt{'schur'};
	$result{'bschur'} = $b->xchg(-1,-2)->sever if $opt{'schur'};

	if ($opt{'permute'}){
		my $balance = cat $ilo, $ihi;
		$result{'balance'} =  $balance;
	}
	
	$result{'info'} =  $info;
	$result{'rscale'} =  $rscale if $opt{'scale'};
	$result{'lscale'} =  $lscale if $opt{'scale'};

	$result{'anorm'} =  $abnrm;
	$result{'bnorm'} =  $bbnrm;

	# Doesn't use lacpy2 =(sqrt **2 , **2) without unnecessary overflow
	if ( $opt{'rcondition'} eq 'vector' || $opt{'rcondition'} eq "all"){
		$result{'rcondv'} =  $rcondv;
		if ($opt{'error'}){ 
			$abnrm = sqrt ($abnrm->pow(2) + $bbnrm->pow(2));
			$result{'verror'} = (lamch(pdl($type,0))* $abnrm /$rcondv  );
		}
	}
	if ( $opt{'rcondition'} eq 'value' || $opt{'rcondition'} eq "all"){	
		$result{'rconde'} =  $rconde;
		if ($opt{'error'}){ 
			$abnrm = sqrt ($abnrm->pow(2) + $bbnrm->pow(2));
			$result{'eerror'} = (lamch(pdl($type,0))* $abnrm /$rconde  );
		}
	}
	
	if ($opt{'vector'} eq 'left'){
		return ($eigens, $beta, $vl->xchg(-1,-2)->sever, %result);
	}
	elsif ($opt{'vector'} eq 'right'){
		return ($eigens, $beta, $vr->xchg(-1,-2)->sever, %result);
	}
	elsif ($opt{'vector'} eq 'all'){
		return ($eigens, $beta, $vl->xchg(-1,-2)->sever, $vr->xchg(-1,-2)->sever, %result);
	}
	else{
		return ($eigens, $beta, %result);		
	}

}


=head2 msymeigen

=for ref

Computes eigenvalues and, optionally eigenvectors of a real symmetric square or
complex Hermitian matrix (spectral decomposition).
The eigenvalues are computed from lower or upper triangular matrix.
If only eigenvalues are requested, info is returned in array context.
Supports threading and works inplace if eigenvectors are requested.
From Lapack, uses L<syev|PDL::LinearAlgebra::Real/syev> or L<syevd|PDL::LinearAlgebra::Real/syevd> for real
and L<cheev|PDL::LinearAlgebra::Complex/cheev> or L<cheevd|PDL::LinearAlgebra::Complex/cheevd> for complex.
Works on transposed array(s).

=for usage

 (PDL(values), (PDL(VECTORS)), PDL(info)) = msymeigen(PDL, SCALAR(uplo), SCALAR(vector), SCALAR(method))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 vector : FALSE = 0 | TRUE = 1, default = 0
 method : 'syev' | 'syevd' | 'cheev' | 'cheevd', default = 'syevd'|'cheevd'

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my ( $eigenvalues, $eigenvectors )  = msymeigen($a,0,1, 'syev');

=cut

sub msymeigen{
	my $m = shift;
	$m->msymeigen(@_);
}

sub PDL::msymeigen {
	my($m, $upper, $jobv, $method) = @_;
	my(@dims) = $m->dims;

	barf("msymeigen: Require square array(s)")
		unless( @dims >= 2 && $dims[0] == $dims[1]);

	my ($w, $v, $info);
       	$info = null;
	$w =  null;
	$method = 'syevd' unless defined $method;
	$m = $m->copy unless ($m->is_inplace(0) and $jobv);

	$m->xchg(0,1)->$method($jobv, $upper, $w, $info);
      	
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymeigen: The algorithm failed to converge for PDL(s) @list: \$info = $info");
	}

	$jobv ? wantarray ? ($w , $m, $info) : $w : wantarray ? ($w, $info) : $w;
}

sub PDL::Complex::msymeigen {
	my($m, $upper, $jobv, $method) = @_;
	my(@dims) = $m->dims;

	barf("msymeigen: Require square array(s)")
		unless( @dims >= 3 && $dims[1] == $dims[2]);

	my ($w, $v, $info);
       	$info = null;
	$w =  null; #PDL::new_from_specification('PDL', $m->type, $dims[1]);
	$m = $m->copy unless ($m->is_inplace(0) and $jobv);

	$method = 'cheevd' unless defined $method;
	$m->xchg(1,2)->$method($jobv, $upper, $w, $info);
      	
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymeigen: The algorithm failed to converge for PDL(s) @list: \$info = $info");
	}

	$jobv ? wantarray ? ($w , $m, $info) : $w : wantarray ? ($w, $info) : $w;
}


=head2 msymeigenx

=for ref

Computes eigenvalues and, optionally eigenvectors of a symmetric square matrix (spectral decomposition).
The eigenvalues are computed from lower or upper triangular matrix and can be selected by specifying a
range. From Lapack, uses L<syevx|PDL::LinearAlgebra::Real/syevx> or
L<syevr|PDL::LinearAlgebra::Real/syevr> for real and L<cheevx|PDL::LinearAlgebra::Complex/cheevx>
or L<cheevr|PDL::LinearAlgebra::Complex/cheevr> for complex. Works on transposed arrays.

=for usage

 (PDL(value), (PDL(vector)), PDL(n), PDL(info), (PDL(support)) ) = msymeigenx(PDL, SCALAR(uplo), SCALAR(vector), HASH(options))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 vector : FALSE = 0 | TRUE = 1, default = 0
 where options are:
 range_type:    method for selecting eigenvalues
		indice:  range of indices
		interval: range of values
		0: find all eigenvalues and optionally all vectors
 range: 	PDL(2), lower and upper bounds interval or smallest and largest indices
 		1<=range<=N for indice
 abstol:        specifie error tolerance for eigenvalues
 method:        specifie which method to use (see Lapack for further details)
 		'syevx' (default)
 		'syevr'
 		'cheevx' (default)
 		'cheevr'
 Returned values:
 		eigenvalues (SCALAR CONTEXT),
 		eigenvectors if requested,
 		total number of eigenvalues found (n),
 		info
		issupz or ifail (support) according to method used and returned info,
 		for (sy|che)evx returns support only if info != 0
 		

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my $overflow = lamch(9);
 my $range = cat pdl(0),$overflow;
 my $abstol = pdl(1.e-5);
 my %options = (range_type=>'interval',
 		range => $range,
 		abstol => $abstol,
		method=>'syevd');
 my ( $eigenvalues, $eigenvectors, $n, $isuppz )  = msymeigenx($a,0,1, %options);

=cut

*msymeigenx = \&PDL::msymeigenx;

sub PDL::msymeigenx {
	my($m, $upper, $jobv, %opt) = @_;
	my(@dims) = $m->dims;

	barf("msymeigenx: Require a square matrix")
		unless( ( (@dims == 2)|| (@dims == 3) )&& $dims[-1] == $dims[-2]);

       	my ($w, $v, $info, $n, $support, $z, $range, $method, $type);

	$type = $m->type;

	$range = ($opt{'range_type'} eq 'interval') ? pdl(long, 1) : 
		($opt{'range_type'} eq 'indice')? pdl(long, 2) : pdl(long, 0); 

	if ((ref $opt{range}) ne 'PDL'){
		$opt{range} = pdl($type,[0,0]); 
		$range = pdl(long, 0);

	}
	elsif ($range == 2){
		barf "msymeigenx: Indices must be > 0" unless $opt{range}->(0) > 0;
		barf "msymeigenx: Indices must be <= $dims[1]" unless $opt{range}->(1) <= $dims[1];
	}
	elsif ($range == 1){
		barf "msymeigenx: Interval limits must be differents" unless ($opt{range}->(0) !=  $opt{range}->(1));
	}
	$w =  PDL::new_from_specification('PDL', $type, $dims[1]);
	$n = null; 
       	$info = pdl(long,0);

	if (!defined $opt{'abstol'})
	{
		my ( $unfl, $ovfl );
		$unfl = lamch(pdl($type,1));
		$ovfl = lamch(pdl($type,9));
		$unfl->labad($ovfl);
		$opt{'abstol'} = $unfl + $unfl;
	}

	$method = $opt{'method'} ?  $opt{'method'} : (@dims == 3) ? 'PDL::LinearAlgebra::Complex::cheevx' : 'PDL::LinearAlgebra::Real::syevx';

	if ( $method =~ 'evx' && $jobv){
		$support =  zeroes(long, $dims[1]);
	}
	elsif ($method =~ 'evr' && $jobv){
		$support = zeroes(long, (2*$dims[1]));	
	}

	if (@dims == 3){
		$upper = $upper ? pdl(long,1) : pdl(long,0);
		$m = $m->xchg(1,2)->copy;
		$z = $jobv ? PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1], $dims[1]) : 
					pdl($type,[0,0]);
	 	$m->$method($jobv, $range, $upper, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
	 						 $opt{'abstol'}, $n, $w, $z , $support, $info);
	}
	else{
		$upper = $upper ? pdl(long,0) : pdl(long,1);
		$m = $m->copy;
		$z = $jobv ? PDL::new_from_specification('PDL', $type, $dims[1], $dims[1]) : 
					pdl($type,0);
	 	$m->$method($jobv, $range, $upper, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
	 						 $opt{'abstol'}, $n, $w, $z ,$support, $info);
	 }

	if ($info){
		laerror("msymeigenx: The algorithm failed to converge.");
		print ("See support for details.\n") if $_laerror;
	}


	if ($jobv){
		if ($info){	
			return ($w , $z->xchg(-2,-1)->sever, $n, $info, $support);
		}
		elsif ($method =~ 'evr'){
			return (undef,undef,$n,$info,$support) if $n == 0;
			return (@dims == 3) ? ($w(:$n-1)->sever , $z->xchg(1,2)->(,:$n-1,)->sever, $n, $info, $support) :
						($w(:$n-1)->sever , $z->xchg(0,1)->(:$n-1,)->sever, $n, $info, $support);
		}
		else{
			return (undef,undef,$n, $info) if $n == 0;
			return (@dims == 3) ? ($w(:$n-1)->sever , $z->xchg(1,2)->(,:$n-1,)->sever, $n, $info) :
						($w(:$n-1)->sever , $z->xchg(0,1)->(:$n-1,)->sever, $n, $info);
		}
	}
	else{
		if ($info){	
			wantarray ?  ($w, $n, $info, $support) : $w;	
		}
		elsif ($method =~ 'evr'){
			wantarray ?  ($w(:$n-1)->sever, $n, $info, $support) : $w;
		}
		else{
			wantarray ?  ($w(:$n-1)->sever, $n, $info) : $w;
		}
	}
}

=head2 msymgeigen

=for ref

Computes eigenvalues and, optionally eigenvectors of a real generalized
symmetric-definite or Hermitian-definite eigenproblem.
The eigenvalues are computed from lower or upper triangular matrix
If only eigenvalues are requested, info is returned in array context.
Supports threading. From Lapack, uses L<sygv|PDL::LinearAlgebra::Real/sygv> or L<sygvd|PDL::LinearAlgebra::Real/sygvd> for real
or L<chegv|PDL::LinearAlgebra::Complex/chegv> or L<chegvd|PDL::LinearAlgebra::Complex/chegvd> for complex.
Works on transposed array(s).

=for usage

 (PDL(values), (PDL(vectors)), PDL(info)) = msymgeigen(PDL(a), PDL(b),SCALAR(uplo), SCALAR(vector), SCALAR(type), SCALAR(method))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 vector : FALSE = 0 | TRUE = 1, default = 0
 type : 
	1: A * x = (lambda) * B * x
	2: A * B * x = (lambda) * x
	3: B * A * x = (lambda) * x
	default = 1
 method : 'sygv' | 'sygvd' for real or  ,'chegv' | 'chegvd' for complex,  default = 'sygvd' | 'chegvd'

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my $b = random(10,10);
 $b = $b->crossprod($b);
 my ( $eigenvalues, $eigenvectors )  = msymgeigen($a, $b, 0, 1, 1, 'sygv');

=cut


sub msymgeigen{
	my $a = shift;
	$a->msymgeigen(@_);
}

sub PDL::msymgeigen {
	my($a, $b, $upper, $jobv, $type, $method) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;

	barf("msymgeigen: Require square matrices of same order")
		unless( @adims >= 2 && @bdims >= 2  && $adims[0] == $adims[1] &&
		$bdims[0] == $bdims[1] && $adims[0] == $bdims[0]);
	barf("msymgeigen: Require matrices with equal number of dimensions")
		if( @adims != @bdims);

	$type = 1 unless $type;
	my ($w, $v, $info);
	$method = 'PDL::LinearAlgebra::Real::sygvd' unless defined $method;


       	$upper = 1-$upper;
	$a = $a->copy;
	$b = $b->copy;
       	$w = null;
	$info = null;
	
	$a->$method($type, $jobv, $upper, $b, $w, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymgeigen: Can't compute eigenvalues/vectors: matrix (PDL(s) @list) is/are not positive definite(s) or the algorithm failed to converge: \$info = $info");
	}

	return $jobv ? ($w , $a->xchg(0,1)->sever, $info) : wantarray ? ($w, $info) : $w;
}

sub PDL::Complex::msymgeigen {
	my($a, $b, $upper, $jobv, $type, $method) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;

	barf("msymgeigen: Require 2 square matrices of same order")
		unless( @adims >= 3 &&  @bdims >= 3  && $adims[1] == $adims[2] &&  
		 $bdims[1] == $bdims[2] && $adims[1] == $bdims[1]);
	barf("msymgeigen: Require matrices with equal number of dimensions")
		if( @adims != @bdims);


	$type = 1 unless $type;
	my ($w, $v, $info);
	$method = 'PDL::LinearAlgebra::Complex::chegvd' unless defined $method;


	$a = $a->xchg(1,2)->copy;
	$b = $b->xchg(1,2)->copy;
       	$w = null;
	$info = null;
	
	# TODO bug in chegv ??? 
	$a->$method($type, $jobv, $upper, $b, $w, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msymgeigen: Can't compute eigenvalues/vectors: matrix (PDL(s) @list) is/are not positive definite(s) or the algorithm failed to converge: \$info = $info");
	}

	return $jobv ? ($w , $a->xchg(1,2)->sever, $info) : wantarray ? ($w, $info) : $w;
}



=head2 msymgeigenx

=for ref

Computes eigenvalues and, optionally eigenvectors of a real generalized
symmetric-definite or Hermitian eigenproblem.
The eigenvalues are computed from lower or upper triangular matrix and can be selected by specifying a
range. Uses L<sygvx|PDL::LinearAlgebra::Real/syevx> or L<cheevx|PDL::LinearAlgebra::Complex/cheevx>
from Lapack. Works on transposed arrays.

=for usage

 (PDL(value), (PDL(vector)), PDL(info), PDL(n), (PDL(support)) ) = msymeigenx(PDL(a), PDL(b), SCALAR(uplo), SCALAR(vector), HASH(options))
 uplo : UPPER  = 0 | LOWER = 1, default = 0
 vector : FALSE = 0 | TRUE = 1, default = 0
 where options are:
 type :         Specifies the problem type to be solved
 		1: A * x = (lambda) * B * x
		2: A * B * x = (lambda) * x
		3: B * A * x = (lambda) * x
		default = 1
 range_type:    method for selecting eigenvalues
		indice:  range of indices
		interval: range of values
		0: find all eigenvalues and optionally all vectors
 range: 	PDL(2), lower and upper bounds interval or smallest and largest indices
 		1<=range<=N for indice
 abstol:        specifie error tolerance for eigenvalues
 Returned values:
 		eigenvalues (SCALAR CONTEXT),
 		eigenvectors if requested,
 		total number of eigenvalues found (n),
 		info
		ifail according to returned info (support).

=for example

 # Assume $a is symmetric
 my $a = random(10,10);
 my $b = random(10,10);
 $b = $b->crossprod($b);
 my $overflow = lamch(9);
 my $range = cat pdl(0),$overflow;
 my $abstol = pdl(1.e-5);
 my %options = (range_type=>'interval',
 		range => $range,
 		abstol => $abstol,
 		type => 1);
 my ( $eigenvalues, $eigenvectors, $n, $isuppz )  = msymgeigenx($a, $b, 0,1, %options);

=cut

*msymgeigenx = \&PDL::msymgeigenx;

sub PDL::msymgeigenx {
	my($a, $b, $upper, $jobv, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;

	if(@adims == 3){
		barf("msymgeigenx: Require 2 square matrices of same order")
			unless( @bdims == 3  && $adims[1] == $adims[2] &&  
			 $bdims[1] == $bdims[2] && $adims[1] == $bdims[1]);
	}
	else{
		barf("msymgeigenx: Require 2 square matrices of same order")
			unless( @adims == 2 && @bdims == 2  && $adims[0] == $adims[1] &&
			$bdims[0] == $bdims[1] && $adims[0] == $bdims[0]);
	}
       
	my ($w, $info, $n, $support, $z, $range, $type);

	$type = $a->type;

	$range = ($opt{'range_type'} eq 'interval') ? pdl(long, 1) : 
		($opt{'range_type'} eq 'indice')? pdl(long, 2) : pdl(long, 0); 

	if (UNIVERSAL::isa($opt{range},'PDL')){
		$opt{range} = pdl($type,[0,0]); 
		$range = pdl(long, 0);

	}
	$opt{type} = 1 unless (defined $opt{type});
       	$w = PDL::new_from_specification('PDL', $type, $adims[1]);
	$n = pdl(long,0); 
       	$info = pdl(long,0);

	if (!defined $opt{'abstol'}){
		my ( $unfl, $ovfl );
		$unfl = lamch(pdl($type,1));
		$ovfl = lamch(pdl($type,9));
		$unfl->labad($ovfl);
		$opt{'abstol'} = $unfl + $unfl;
	}
	$support =  zeroes(long, $adims[1]) if $jobv;
	$w = PDL::new_from_specification('PDL', $type, $adims[1]);
	$z = PDL::zeroes $a;
	if (@adims ==3){
		$upper = $upper ? pdl(long,1) : pdl(long,0);
		$a = $a->xchg(-1,-2)->copy;
		$b = $b->xchg(-1,-2)->copy;
		$a->chegvx($opt{type}, $jobv, $range, $upper, $b, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
	 		$opt{'abstol'}, $n, $w, $z ,$support, $info);
	}
	else{
		$upper = $upper ? pdl(long,0) : pdl(long,1);
		$a = $a->copy;
		$b = $b->copy;
		$a->sygvx($opt{type}, $jobv, $range, $upper, $b, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
	 		$opt{'abstol'}, $n, $w, $z ,$support, $info);
	}
	if ( ($info > 0) && ($info < $adims[-1])){
		laerror("msymgeigenx: The algorithm failed to converge");
		print("see support for details\n") if $_laerror;
	}
	elsif($info){
		$info = $info - $adims[-1] - 1;
		barf("msymgeigenx: The leading minor of order $info of B is not positive definite\n");
	}

	if ($jobv){
		if ($info){
			return ($w , $z->xchg(-1,-2)->sever, $n, $info, $support) ;
		}
		else{
			return ($w , $z->xchg(-1,-2)->sever, $n, $info);
		}
	}
	else{
		if ($info){
			wantarray ?  ($w, $n, $info, $support) : $w;
		}
		else{
			wantarray ?  ($w, $n, $info) : $w;
		}
	}
}


=head2 mdsvd

=for ref

Computes SVD using Coppen's divide and conquer algorithm.
Return singular values in scalar context else left (U),
singular values, right (V' (hermitian for complex)) singular vectors and info.
Supports threading.
If only singulars values are requested, info is only returned in array context.
Uses L<gesdd|PDL::LinearAlgebra::Real/gesdd> or L<cgesdd|PDL::LinearAlgebra::Complex/cgesdd> from Lapack.

=for usage

 (PDL(U), (PDL(s), PDL(V)), PDL(info)) = mdsvd(PDL, SCALAR(job))
 job :  0 = computes only singular values
 	1 = computes full SVD (square U and V)
	2 = computes SVD (singular values, right and left singular vectors) 
	default = 1

=for example

 my $a = random(5,10);
 my ($u, $s, $v) = mdsvd($a);

=cut


sub mdsvd{
	my $a = shift;
	$a->mdsvd(@_);
}


sub PDL::mdsvd {
	my($m, $job) = @_;
	my(@dims) = $m->dims;

	my ($u, $s, $v, $min, $info, $type);
	$type = $m->type;
	if (wantarray){
		$job = 1 unless defined($job);
	}
	else{
		$job = 0;
	}
	$min = $dims[0] > $dims[1] ? $dims[1]: $dims[0];
	$info = null;
	$s = null;
	$m = $m->copy;

	if ($job){
		if ($job == 2){
			$u = PDL::new_from_specification('PDL', $type, $min, $dims[1],@dims[2..$#dims]);
			$v = PDL::new_from_specification('PDL', $type, $dims[0],$min,@dims[2..$#dims]);
		}
		else{			
			$u = PDL::new_from_specification('PDL', $type, $dims[1],$dims[1],@dims[2..$#dims]);
			$v = PDL::new_from_specification('PDL', $type, $dims[0],$dims[0],@dims[2..$#dims]);
		}
	}else{
		$u = PDL::new_from_specification('PDL', $type, 1,1);
		$v = PDL::new_from_specification('PDL', $type, 1,1);	
	}
	$m->gesdd($job, $s, $v, $u, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mdsvd: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	if ($job){
		return ($u, $s, $v, $info);
	}else{ return wantarray ? ($s, $info) : $s; }
}

#Humm... $a= cplx random(2,4,5)
sub PDL::Complex::mdsvd {
	my($m, $job) = @_;
	my(@dims) = $m->dims;

	my ($u, $s, $v, $min, $info, $type);
	$type = $m->type;
	if (wantarray){
		$job = 1 unless defined($job);
	}
	else{
		$job = 0;
	}
	$min = $dims[-2] > $dims[-1] ? $dims[-1]: $dims[-2];
	$info=null;
	$s = null;
	$m = $m->copy;

	if ($job){
		if ($job == 2){
			$u = PDL::new_from_specification('PDL::Complex', $type, 2,$min, $dims[2],@dims[3..$#dims]);
			$v = PDL::new_from_specification('PDL::Complex', $type, 2,$dims[1],$min,@dims[3..$#dims]);
		}
		else{			
			$u = PDL::new_from_specification('PDL::Complex', $type, 2,$dims[2],$dims[2],@dims[3..$#dims]);
			$v = PDL::new_from_specification('PDL::Complex', $type, 2,$dims[1],$dims[1],@dims[3..$#dims]);
		}
	}else{
		$u = PDL::new_from_specification('PDL', $type, 2,1,1);
		$v = PDL::new_from_specification('PDL', $type, 2,1,1);	
	}
	$m->cgesdd($job, $s, $v, $u, $info);
	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("mdsvd: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	if ($job){
		return ($u, $s, $v, $info);
	}else{ return wantarray ? ($s, $info) : $s; }
}



=head2 msvd

=for ref

Computes SVD.
Can compute singular values, either U or V or neither.
Return singulars values in scalar context else left (U),
singular values, right (V' (hermitian for complex) singulars vector and info.
Supports threading.
If only singulars values are requested, info is returned in array context.
Uses L<gesvd|PDL::LinearAlgebra::Real/gesvd> or L<cgesvd|PDL::LinearAlgebra::Complex/cgesvd> from Lapack.

=for usage

 ( (PDL(U)), PDL(s), (PDL(V), PDL(info)) = msvd(PDL, SCALAR(jobu), SCALAR(jobv))
 jobu : 0 = Doesn't compute U
 	1 = computes full SVD (square U)
	2 = computes right singular vectors
	default = 1
 jobv : 0 = Doesn't compute V
 	1 = computes full SVD (square V)
	2 = computes left singular vectors
	default = 1

=for example

 my $a = random(10,10);
 my ($u, $s, $v) = msvd($a);

=cut

sub msvd{
	my $a = shift;
	$a->msvd(@_);
}


sub PDL::msvd {
	my($m, $jobu, $jobv) = @_;
	my(@dims) = $m->dims;

	my ($u, $s, $v, $min, $info, $type);
	$type = $m->type;
	if (wantarray){
		$jobu = 1 unless defined $jobu;
		$jobv = 1 unless defined $jobv;
	}
	else{
		$jobu = 0;
		$jobv = 0;
	}
	$m = $m->copy;
	$min = $dims[-2] > $dims[-1] ? $dims[-1]: $dims[-2];
	$s = null;
        $info = null;

	if ($jobv){		
		$v = ($jobv == 1) ? PDL::new_from_specification('PDL', $type, $dims[0],$dims[0],@dims[2..$#dims]):
					PDL::new_from_specification('PDL', $type, $dims[0],$min,@dims[2..$#dims]);
	}else {$v = PDL::new_from_specification('PDL', $type, 1,1);}
	if ($jobu){
		$u = ($jobu == 1) ? PDL::new_from_specification('PDL', $type, $dims[1],$dims[1],@dims[2..$#dims]):
					PDL::new_from_specification('PDL', $type, $min, $dims[1],@dims[2..$#dims]);
		
	}else {$u = PDL::new_from_specification('PDL', $type, 1,1);}
	$m->gesvd($jobv, $jobu,$s, $v, $u, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msvd: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	if ($jobu){
		if ($jobv){
			return ($u, $s, $v, $info);
		}
		return ($u, $s, $info);
	}
	elsif($jobv){
		return ($s, $v, $info);
	}
	else{return wantarray ? ($s, $info) : $s;}
}

sub PDL::Complex::msvd{
	my($m, $jobu, $jobv) = @_;
	my(@dims) = $m->dims;

	my ($u, $s, $v, $min, $info, $type);
	$type = $m->type;
	if (wantarray){
		$jobu = 1 unless defined $jobu;
		$jobv = 1 unless defined $jobv;
	}
	else{
		$jobu = 0;
		$jobv = 0;
	}
	$m = $m->copy;
	$min = $dims[-2] > $dims[-1] ? $dims[-1]: $dims[-2];
	$s = null;
        $info = null;

	if ($jobv){		
		$v = ($jobv == 1) ? PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1],$dims[1],@dims[3..$#dims]):
					PDL::new_from_specification('PDL::Complex', $type, 2, $dims[1],$min,@dims[3..$#dims]);
	}else {$v = PDL::new_from_specification('PDL', $type, 2,1,1);}
	if ($jobu){
		$u = ($jobu == 1) ? PDL::new_from_specification('PDL::Complex', $type, 2, $dims[2],$dims[2],@dims[3..$#dims]):
					PDL::new_from_specification('PDL::Complex', $type, 2, $min, $dims[2],@dims[3..$#dims]);
		
	}else {$u = PDL::new_from_specification('PDL', $type, 2,1,1);}
	$m->cgesvd($jobv, $jobu,$s, $v, $u, $info);

	if($info->max > 0 && $_laerror) {
		my ($index,@list);
		$index = which($info > 0)+1;
		@list = $index->list;
		laerror("msvd: Matrix (PDL(s) @list) is/are singular(s): \$info = $info");
	}

	if ($jobu){
		if ($jobv){
			return ($u, $s, $v, $info);
		}
		return ($u, $s, $info);
	}
	elsif($jobv){
		return ($s, $v, $info);
	}
	else{return wantarray ? ($s, $info) : $s;}
}


=head2 mgsvd

=for ref

Computes generalized (or quotient) singular value decomposition.
If the effective rank of (A',B')' is 0 return only unitary V, U, Q.
For complex number, needs object of type PDL::Complex.
Uses L<ggsvd|PDL::LinearAlgebra::Real/ggsvd> or
L<cggsvd|PDL::LinearAlgebra::Complex/cggsvd> from Lapack. Works on transposed arrays.

=for usage

 (PDL(sa), PDL(sb), %ret) = mgsvd(PDL(a), PDL(b), %HASH(options))
 where options are:
 V:    whether or not computes V (boolean, returned in HASH{'V'})
 U:    whether or not computes U (boolean, returned in HASH{'U'})
 Q:    whether or not computes Q (boolean, returned in HASH{'Q'})
 D1:   whether or not computes D1 (boolean, returned in HASH{'D1'})
 D2:   whether or not computes D2 (boolean, returned in HASH{'D2'})
 0R:   whether or not computes 0R (boolean, returned in HASH{'0R'})
 R:    whether or not computes R (boolean, returned in HASH{'R'})
 X:    whether or not computes X (boolean, returned in HASH{'X'})
 all:  whether or not computes all the above.
 Returned value:
 	 sa,sb		: singular value pairs of A and B (generalized singular values = sa/sb)
	 $ret{'rank'}   : effective numerical rank of (A',B')'
	 $ret{'info'}   : info from (c)ggsvd

=for example

 my $a = random(5,5);
 my $b = random(5,7);
 my ($c, $s, %ret) = mgsvd($a, $b, X => 1);

=cut

sub mgsvd{
	my $m =shift;
	$m->mgsvd(@_);
}

sub PDL::mgsvd {
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	barf("mgsvd: Require matrices with equal number of columns")
		unless( @adims == 2 && @bdims == 2 && $adims[0] == $bdims[0] );

	my ($U, $V, $Q, $alpha, $beta, $k, $l, $iwork, $info, $D2, $D1, $work, %ret, $X, $jobqx, $type);
	if ($opt{all}){
		$opt{'V'} = 1;
		$opt{'U'} = 1;
		$opt{'Q'} = 1;
		$opt{'D1'} = 1;
		$opt{'D2'} = 1;
		$opt{'0R'} = 1;
		$opt{'R'} = 1;
		$opt{'X'} = 1;
	}
	$type = $a->type;
	$jobqx = ($opt{Q} || $opt{X}) ? 1 : 0; 
	$a = $a->copy;
	$b = $b->xchg(0,1)->copy;
	$k = null;
	$l = null;
	$alpha = zeroes($type, $adims[0]);
	$beta = zeroes($type, $adims[0]);
	
	$U = $opt{U} ? zeroes($type, $adims[1], $adims[1]) : zeroes($type,1,1);
	$V = $opt{V} ? zeroes($b->type, $bdims[1], $bdims[1]) : zeroes($b->type,1,1);
	$Q = $jobqx ? zeroes($type, $adims[0], $adims[0]) : zeroes($type,1,1);
	$iwork = zeroes(long, $adims[0]);
	$info = pdl(long, 0);
	$a->xchg(0,1)->ggsvd($opt{U}, $opt{V}, $jobqx, $b, $k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info);
	laerror("mgsvd: The Jacobi procedure fails to converge") if $info;

	$ret{rank} = $k + $l;
	warn "mgsvd: Effective rank of 0 in mgsvd" if (!$ret{rank} and $_laerror);
	$ret{'info'} = $info;

	if (%opt){
		$Q = $Q->xchg(0,1)->sever if $jobqx;
	
		if (($adims[1] - $k - $l)  < 0  && $ret{rank}){
			
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape($adims[0], ($k + $l));
				# Slice $a ???  => always square ??
				$a ( ($adims[0] -  (($k+$l) - $adims[1])) : , $adims[1]:) .= 
						$b(($adims[1]-$k):($l-1),($adims[0]+$adims[1]-$k - $l):($adims[0]-1))->xchg(0,1);
				$ret{'0R'} = $a if $opt{'0R'};
			}
	
			if ($opt{'D1'}){
				$D1 = zeroes($type, $adims[1], $adims[1]);
				$D1->diagonal(0,1) .= $alpha(:($adims[1]-1));
				$D1 = $D1->xchg(0,1)->reshape($adims[1] , ($k+$l))->xchg(0,1)->sever;
				$ret{'D1'} = $D1;
			}
		}
		elsif ($ret{rank}){
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape($adims[0], ($k + $l));
				$ret{'0R'} = $a if $opt{'0R'};
			}
	
			if ($opt{'D1'}){
				$D1 = zeroes($type, ($k + $l), ($k + $l));
				$D1->diagonal(0,1) .=  $alpha(:($k+$l-1));
				$D1->reshape(($k + $l), $adims[1]);
				$ret{'D1'} = $D1;
			}
		}
	
		if ($opt{'D2'} && $ret{rank}){
			$work = zeroes($b->type, $l, $l);
			$work->diagonal(0,1) .=  $beta($k:($k+$l-1));
			$D2 = zeroes($b->type, ($k + $l), $bdims[1]);
			$D2( $k:, :($l-1)  ) .= $work;
			$ret{'D2'} = $D2;
		}
		
		if ( $ret{rank} && ($opt{X} || $opt{R}) ){
			$work =  $a( -($k + $l):,);
			$ret{R} = $work if $opt{R};
			if ($opt{X}){
				$X = zeroes($type, $adims[0], $adims[0]);
				$X->diagonal(0,1) .= 1 if ($adims[0] > ($k + $l));		
				$X ( -($k + $l): , -($k + $l): )  .=  mtriinv($work);
				$ret{X} = $Q x $X;
			}
		
		}
		
		$ret{U} = $U->xchg(0,1)->sever if $opt{U};
		$ret{V} = $V->xchg(0,1)->sever if $opt{V};
		$ret{Q} = $Q if $opt{Q};
	}
	$ret{rank} ? return ($alpha($k:($k+$l-1))->sever, $beta($k:($k+$l-1))->sever, %ret ) : (undef, undef, %ret);
}

sub PDL::Complex::mgsvd {
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	barf("mgsvd: Require matrices with equal number of columns")
		unless( @adims == 3 && @bdims == 3 && $adims[1] == $bdims[1] );

	my ($U, $V, $Q, $alpha, $beta, $k, $l, $iwork, $info, $D2, $D1, $work, %ret, $X, $jobqx, $type);
	if ($opt{all}){
		$opt{'V'} = 1;
		$opt{'U'} = 1;
		$opt{'Q'} = 1;
		$opt{'D1'} = 1;
		$opt{'D2'} = 1;
		$opt{'0R'} = 1;
		$opt{'R'} = 1;
		$opt{'X'} = 1;
	}
	$type = $a->type;
	$jobqx = ($opt{Q} || $opt{X}) ? 1 : 0; 
	$a = $a->copy;
	$b = $b->xchg(1,2)->copy;
	$k = null;
	$l = null;
	$alpha = zeroes($type, $adims[1]);
	$beta = zeroes($type, $adims[1]);
	
	$U = $opt{U} ? PDL::new_from_specification('PDL::Complex', $type, 2,$adims[2], $adims[2]) : zeroes($type,1,1);
	$V = $opt{V} ? PDL::new_from_specification('PDL::Complex', $b->type, 2,$bdims[2], $bdims[2]) : zeroes($b->type,1,1);
	$Q = $jobqx ? PDL::new_from_specification('PDL::Complex', $type, 2,$adims[1], $adims[1]) : zeroes($type,1,1);
	$iwork = zeroes(long, $adims[1]);
	$info = null;
	$a->xchg(1,2)->cggsvd($opt{U}, $opt{V}, $jobqx, $b, $k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info);
	$k = $k->sclr;
	$l = $l->sclr;
	laerror("mgsvd: The Jacobi procedure fails to converge") if $info;

	$ret{rank} = $k + $l;
	warn "mgsvd: Effective rank of 0 in mgsvd" if (!$ret{rank} and $_laerror);
	$ret{'info'} = $info;

	if (%opt){
		$Q = $Q->xchg(1,2)->sever if $jobqx;
	
		if (($adims[2] - $k - $l)  < 0  && $ret{rank}){
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape(2,$adims[1], ($k + $l));
				# Slice $a ???  => always square ??
				$a (, ($adims[1] -  (($k+$l) - $adims[2])) : , $adims[2]:) .= 
						$b(,($adims[2]-$k):($l-1),($adims[1]+$adims[2]-$k - $l):($adims[1]-1))->xchg(1,2);
				$ret{'0R'} = $a if $opt{'0R'};						
				
			}
			if ($opt{'D1'}){
				$D1 = zeroes($type, $adims[2], $adims[2]);
				$D1->diagonal(0,1) .= $alpha(:($adims[2]-1));
				$D1 = $D1->xchg(0,1)->reshape($adims[2] , ($k+$l))->xchg(0,1)->sever;
				$ret{'D1'} = $D1;
			}
		}
		elsif ($ret{rank}){
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape(2, $adims[1], ($k + $l));
				$ret{'0R'} = $a if $opt{'0R'};
			}
	
			if ($opt{'D1'}){
				$D1 = zeroes($type, ($k + $l), ($k + $l));
				$D1->diagonal(0,1) .=  $alpha(:($k+$l-1));
				$D1->reshape(($k + $l), $adims[2]);
				$ret{'D1'} = $D1;
			}
		}
	
		if ($opt{'D2'} && $ret{rank}){
			$work = zeroes($b->type, $l, $l);
			$work->diagonal(0,1) .=  $beta($k:($k+$l-1));
			$D2 = zeroes($b->type, ($k + $l), $bdims[2]);
			$D2( $k:, :($l-1)  ) .= $work;
			$ret{'D2'} = $D2;
		}
		
		if ( $ret{rank} && ($opt{X} || $opt{R}) ){
			$work =  $a( , -($k + $l):,);
			$ret{R} = $work if $opt{R};
			if ($opt{X}){
				# $X = #zeroes($type, 2, $adims[1], $adims[1]);
				$X = PDL::new_from_specification('PDL::Complex', $type, 2, $adims[1], $adims[1]);
				$X .= 0;
				$X->diagonal(1,2)->(0,) .= 1 if ($adims[1] > ($k + $l));		
				$X ( ,-($k + $l): , -($k + $l): )  .=  mtriinv($work);
				$ret{X} = $Q x $X;
			}
		
		}
		
		$ret{U} = $U->xchg(1,2)->sever if $opt{U};
		$ret{V} = $V->xchg(1,2)->sever if $opt{V};
		$ret{Q} = $Q if $opt{Q};
	}
	$ret{rank} ? return ($alpha($k:($k+$l-1))->sever, $beta($k:($k+$l-1))->sever, %ret ) : (undef, undef, %ret);
}



#TODO

# Others things

#	rectangular diag
#	usage
#	is_inplace and function which modify entry matrix
#	avoid xchg
#	threading support
#	automatically create PDL
#	inplace operation and memory
#d	check s after he/she/it and matrix(s)
#	PDL type, verify float/double
#	eig_det qr_det
#	(g)schur(x): 
#		if conjugate pair
#			non generalized pb: $seldim ?? (cf: generalized)
#			return conjugate pair if only selected?
#	port to PDL::Matrix

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2018.

This library is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License as in the file Artistic_2
in this distribution.

=cut

1;
