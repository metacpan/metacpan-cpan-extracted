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
use constant {
	NO => 0,
	WARN => 1,
	BARF => 2,
};

use strict;

our $VERSION = '0.431';
$VERSION = eval $VERSION;

@PDL::LinearAlgebra::ISA = qw/PDL::Exporter/;
@PDL::LinearAlgebra::EXPORT_OK = qw/diag issym minv mtriinv msyminv mposinv mdet mposdet mrcond positivise
				mdsvd msvd mgsvd mpinv mlu mhessen mchol mqr mql mlq mrq meigen meigenx
				mgeigen  mgeigenx msymeigen msymeigenx msymgeigen msymgeigenx
				msolve mtrisolve msymsolve mpossolve msolvex msymsolvex mpossolvex
				mrank mlls mllsy mllss mglm mlse tritosym mnorm mgschur mgschurx
				mcrossprod mcond morth mschur mschurx
				NO WARN BARF setlaerror getlaerorr laerror/;
%PDL::LinearAlgebra::EXPORT_TAGS = (Func=>[@PDL::LinearAlgebra::EXPORT_OK]);

my $_laerror = BARF;

########################################################################

=encoding utf8

=head1 NAME

PDL::LinearAlgebra - Linear Algebra utils for PDL

=head1 SYNOPSIS

 use PDL::LinearAlgebra;

 $a = random (100,100);
 ($U, $s, $V) = mdsvd($a);

=head1 DESCRIPTION

This module provides a convenient interface to L<PDL::LinearAlgebra::Real>
and L<PDL::LinearAlgebra::Complex>. Since
Blas and Lapack use a column major ordering scheme some routines here need to transpose matrices before
calling fortran routines and transpose back (see the documentation of each routine). If you need
optimized code use directly  L<PDL::LinearAlgebra::Real> and
L<PDL::LinearAlgebra::Complex>.

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
 conj : Conjugate Transpose = 1 | Transpose = 0, default = 0;

=for ref

Convenient function for transposing real or complex 2D array(s).
For complex data, if conj is true returns conjugate transposed array(s) and doesn't support dataflow.
Supports threading.

=cut

sub PDL::dims_internal {0}
sub PDL::dims_internal_values {()}
sub PDL::_similar {
  my @di_vals = $_[0]->dims_internal_values;
  my ($m, @vdims) = @_;
  ref($m)->new_from_specification($m->type, @di_vals, @vdims);
}
sub PDL::_similar_null { ref($_[0])->null }
sub _complex_null {
  PDL->null
}
sub _ecplx {
  my ($re, $im) = @_;
  $re = PDL->topdl($re);
  return $re if !$re->type->real;
  Carp::confess("Usage: _ecplx(re,im) or (complex)") if !defined $im;
  $im = PDL->topdl($im);
  $re->czip($im);
}
sub PDL::_is_complex { !$_[0]->type->real }
sub PDL::_norm {
	my ($m, $real, $trans) = @_;
	# If trans == true => transpose output matrix
	# If real == true => rotate (complex as a vector)
	#		     such that max abs will be real
	my $ret = PDL::LinearAlgebra::Complex::cnrm2($m);
	return ($trans ? $m->t/$ret->dummy(0)->t : $m/$ret->dummy(0))->reshape(-1) if !$real;
	$m = ($m/$ret->dummy(0))->reshape(-1);
	my $index = $m->abs->maximum_ind;
	my $scale = $m->mv(0,-1)->index($index)->mv(-1,0);
	$scale = $scale->conj/$scale->abs;
	return $trans ? $m->t*$scale->dummy(2) : $m*$scale->dummy(2)->t;
}

=head2 issym

=for usage

 PDL = issym(PDL, SCALAR|PDL(tol),SCALAR(hermitian))
 tol : tolerance value, default: 1e-8 for double else 1e-5
 hermitian : Hermitian = 1 | Symmetric = 0, default = 0;

=for ref

Checks symmetricity/Hermitianicity of matrix.
Supports threading.

=cut

sub _2d_array {
  my @dims = $_[0]->dims;
  my $d = $_[0]->dims_internal;
  barf("Require 2D array(s)") unless @dims >= 2+$d;
}
sub _square {
  &_2d_array;
  my @dims = $_[0]->dims;
  my $d = $_[0]->dims_internal;
  barf("Require square array(s)") unless $dims[$d] == $dims[$d+1];
}
sub _square_same {
  my $d = $_[0]->dims_internal;
  my @adims = $_[0]->dims;
  my @bdims = $_[1]->dims;
  barf("Require square matrices of same order")
    unless( $adims[$d] == $adims[$d+1] && $bdims[$d] == $bdims[$d+1] && $adims[$d] == $bdims[$d]);
}
sub _matrices_match {
  my $d = $_[0]->dims_internal;
  my @adims = $_[0]->dims;
  my @bdims = $_[1]->dims;
  barf("Require right hand side array(s) B with number".
    " of row equal to number of columns of A")
    unless @adims >= 2+$d && @bdims >= 2+$d && $bdims[1+$d] == $adims[$d];
}
sub _matrices_matchcolumns {
  my $di = $_[0]->dims_internal;
  my @adims = $_[0]->dims;
  my @bdims = $_[1]->dims;
  barf("Require 2 matrices with equal number of columns")
    unless( ((@adims >= 2+$di && @bdims >= 2+$di)) &&
    $adims[$di] == $bdims[$di]);
}
sub _matrices_matchrows {
  my $d = $_[0]->dims_internal;
  my @adims = $_[0]->dims;
  my @bdims = $_[1]->dims;
  barf("Require a 2D right hand side matrix B with number".
    " of rows equal to number of rows of A")
    unless @adims >= 2+$d && @bdims >= 2+$d && $bdims[1+$d] == $adims[1+$d];
}
sub _same_dims {
  my $d = $_[0]->dims_internal;
  my @adims = $_[0]->dims;
  my @bdims = $_[1]->dims;
  barf("Require arrays with equal number of dimensions") if @adims != @bdims;
}
sub _error {
  my ($info, $msg) = @_;
  return unless $info->max > 0 && $_laerror;
  my @list = (which($info > 0)+1)->list;
  laerror(sprintf $msg . ": \$info = $info", "@list");
}
sub _error_schur {
  my ($info, $select_func, $N, $func, $algo) = @_;
  return unless $info->max > 0 && $_laerror;
  my $index = which((($info > 0)+($info <=$N))==2);
  if (!$index->isempty) {
    laerror("$func: The $algo algorithm failed to converge for matrix (PDL(s) @{[$index->list]}): \$info = $info");
    print "Returning converged eigenvalues\n";
  }
  return if !$select_func;
  if (!($index = which($info == $N+1))->isempty) {
    if ($algo eq 'QR') {
      laerror("$func: The eigenvalues could not be reordered because some\n".
	"eigenvalues were too close to separate (the problem".
	" is very ill-conditioned) for PDL(s) @{[$index->list]}: \$info = $info");
    } else {
      laerror("$func: Error in hgeqz for matrix (PDL(s) @{[$index->list]}): \$info = $info");
    }
  }
  if (!($index = which($info == $N+2))->isempty) {
    warn("$func: The Schur form no longer satisfy select_func = 1\n because of roundoff".
      " or underflow (PDL(s) @{[$index->list]})\n");
  }
}
sub PDL::_wrap_select_func {
  my ($m, $select_func) = @_;
  return $select_func if !defined $select_func or $m->_is_complex;
  sub { &$select_func(_ecplx(@_[0,1]), @_>2 ? PDL->topdl($_[2]) : ()) };
}

*issym = \&PDL::issym;
sub PDL::issym {
	&_square;
	my ($m, $tol, $conj) = @_;
	$tol //= ($m->type >= double) ? 1e-8 : 1e-5;
	$m = $m - $m->t($conj);
	my ($min,$max) = PDL::Ufunc::minmaximum($m);
	$min = $min->minimum;
	$max = $max->maximum;
	return  (((abs($max) > $tol) + (abs($min) > $tol)) == 0);
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

*diag = \&PDL::diag;
sub PDL::diag {
	my $di = $_[0]->dims_internal;
	my @diag_args = ($di, $di+1);
	my $slice_prefix = ',' x $di;
	my ($a,$i, $vec) = @_;
	my $z;
	my @dims = $a->dims;
	my $diag = ($i < 0) ? -$i : $i ;
	if (@dims == $di+1 || $vec){
		my $dim = $dims[0];
		my $zz = $dim + $diag;
		my $v = $z = $a->_similar($zz,$zz,@dims[$di+1..$#dims]);
		$v = ($i < 0) ? $v->slice("$slice_prefix:@{[$dim-1]},$diag:") : $v->slice("$slice_prefix$diag:,:@{[$dim-1]}") if $i;
		$v->diagonal(@diag_args) .= $a;
	}
	elsif($i < 0){
		$z = $a->slice("$slice_prefix:-@{[$diag+1]} , $diag:")->diagonal(@diag_args);
	}
	elsif($i){
		$z = $a->slice("$slice_prefix$diag:, :-@{[$diag+1]}")->diagonal(@diag_args);
	}
	else{$z = $a->diagonal(@diag_args);}
	$z;
}
use attributes 'PDL', \&PDL::diag, 'lvalue';

=head2 tritosym

=for ref

Returns symmetric or Hermitian matrix from lower or upper triangular matrix.
Supports inplace and threading.

=for usage

 PDL = tritosym(PDL, SCALAR(uplo), SCALAR(conj))
 uplo : UPPER = 0 | LOWER = 1, default = 0
 conj : Hermitian = 1 | Symmetric = 0, default = 0;

=for example

 # Assume $a is symmetric triangular
 my $a = random(10,10);
 my $b = tritosym($a);

=cut

*tritosym = \&PDL::tritosym;
sub PDL::tritosym {
	&_square;
	my ($m, $upper, $conj) = @_;
	my $b = $m->is_inplace ? $m->t : $m->_similar_null;
	($conj ? $m->conj : $m)->tricpy($upper, $b);
	$m->tricpy($upper, $b->t) unless (!$conj && $m->is_inplace(0));
	$b->im->diagonal(0,1) .= 0 if $conj;
	$b;
}

=head2 positivise

=for ref

Returns entry pdl with changed sign by row so that average of positive sign > 0.
In other words threads among dimension 1 and row  =  -row if sum(sign(row)) < 0.
Only makes sense for real ndarrays.
Works inplace.

=for example

 my $a = random(10,10);
 $a -= 0.5;
 $a->xchg(0,1)->inplace->positivise;

=cut

*positivise = \&PDL::positivise;
sub PDL::positivise{
	my $m = shift->new_or_inplace;
	my $tmp;
	$tmp = $m->dice('X', which(($m->lt(0,0)->sumover > ($m->dim(0)/2))>0));
	$tmp->inplace->mult(-1,0);
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

sub PDL::_call_method {
  my ($m, $method, @args) = @_;
  $method = [$method, "c$method"] if !ref $method;
  $method = $method->[!$m->type->real ? 1 : 0];
  $m->$method(@args);
}
*mcrossprod = \&PDL::mcrossprod;
sub PDL::mcrossprod {
	&_2d_array;
	my($a, $b) = @_;
	$b = $a unless defined $b;
	$a->_call_method('crossprod', $b);
}

=head2 mrank

=for ref

Computes the rank of a matrix, using a singular value decomposition,
returning a Perl scalar.
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
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my($m, $tol) = @_;
	my(@dims) = $m->dims;
	my $err = setlaerror(NO);
	# Sometimes mdsvd bugs for  float (SGEBRD)
	# ($sv, $info) = $m->msvd(0, 0);
	my ($sv, $info) = $m->mdsvd(0);
	setlaerror($err);
	barf("mrank: SVD algorithm did not converge\n") if $info;
	unless (defined $tol){
		$tol =  ($dims[$di+1] > $dims[$di] ? $dims[$di+1] : $dims[$di]) * $sv((0)) * lamch(3);
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

my %norms = (inf=>0, one=>1, two=>2, fro=>3);
my %norm2arg = (0=>1, 1=>2, 3=>3);
*mnorm = \&PDL::mnorm;
sub PDL::mnorm {
	my ($m, $ord) = @_;
	$ord //= 2;
	$ord = $norms{$ord} if exists $norms{$ord};
	return $m->_call_method('lange', $norm2arg{$ord}) if exists $norm2arg{$ord};
	my $err = setlaerror(NO);
	my ($sv, $info) = $m->msvd(0, 0);
	setlaerror($err);
	_error($info, "mnorm: SVD algorithm did not converge for matrix (PDL(s) %s");
	$sv->slice('(0)')->reshape(-1)->sever;
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

*mdet = \&PDL::mdet;
sub PDL::mdet {
	&_square;
	my $di = $_[0]->dims_internal;
	my $m_orig = my $m = shift->copy;
	$m->_call_method('getrf', my $ipiv = null, my $info = null);
	$m = $m->diagonal($di,$di+1);
	$m = $m->prodover;
	$m = $m * ((PDL::Ufunc::sumover(sequence($ipiv->dim(0))->plus(1,0) != $ipiv)%2)*(-2)+1);
	$info = which($info != 0);
	$m->flat->index($info) .= 0 if !$info->isempty;
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

*mposdet = \&PDL::mposdet;
sub PDL::mposdet {
	&_square;
	my ($m, $upper) = @_;
	$m = $m->copy;
	$m->_call_method('potrf', $upper, my $info = null);
	_error($info, "mposdet: Matrix (PDL(s) %s) is/are not positive definite (after potrf factorization)");
	$m = $m->re if $m->_is_complex;
	$m = $m->diagonal(0,1)->prodover->pow(2);
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

*mcond = \&PDL::mcond;
sub PDL::mcond {
	&_2d_array;
	my $m = shift;
	my @dims = $m->dims;
	my $err = setlaerror(NO);
	my ($sv, $info) = $m->msvd(0, 0);
	setlaerror($err);
	_error($info, "mcond: Algorithm did not converge for matrix (PDL(s) %s)");
	my $temp = $sv->slice('(0)');
        my $ret = $temp/$sv->((-1));
	$info = $ret->flat->index(which($temp == 0));
	$info .= inf() unless $info->isempty;
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

*mrcond = \&PDL::mrcond;
sub PDL::mrcond {
	&_square;
	my ($m,$anorm) = @_;
	$anorm = 0 unless defined $anorm;
	$_ = null for my ($ipiv, $info, $rcond);
	my $norm = $m->mnorm($anorm);
	$m = $m->t->copy();
	$m->_call_method('getrf', $ipiv, $info);
	_error($info, "mrcond: Factor(s) U (PDL(s) %s) is/are singular (after getrf factorization)");
	$m->_call_method('gecon',$anorm,$norm,$rcond,$info);
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
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my ($m, $tol) = @_;
	$tol =  (defined $tol) ? $tol  : ($m->type == double) ? 1e-8 : 1e-5;
	(my $u, my $s, undef, my $info) = $m->mdsvd;
	barf("morth: SVD algorithm did not converge\n") if $info;
	my $rank = (which($s > $tol))->dim(0) - 1;
	$rank < 0 ? $m->_similar_null : $u->slice("$slice_prefix:$rank,")->sever;
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
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	$tol //= ($m->type == double) ? 1e-8 : 1e-5;
	(undef, my $s, my $v, my $info) = $m->mdsvd;
	barf("mnull: SVD algorithm did not converge\n") if $info;
	#TODO: USE TRANSPOSED A
	my $rank = (which($s > $tol))->dim(0);
	$rank < $dims[$di] ? $v->t->slice("$slice_prefix$rank:")->sever : $m->_similar_null;
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

*minv = \&PDL::minv;
sub PDL::minv {
	&_square;
	my $m = shift->new_or_inplace;
	$_ = null for my ($ipiv, $info);
	$m->_call_method('getrf', $ipiv, $info);
	_error($info, "minv: Factor(s) U (PDL(s) %s) is/are singular (after getrf factorization)");
	$m->_call_method('getri', $ipiv, $info);
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

*mtriinv = \&PDL::mtriinv;
sub PDL::mtriinv{
	&_square;
	my $m = shift->new_or_inplace;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	my $diag = shift;
	my $info = PDL->null;
	$m->_call_method('trtri', $upper, $diag, $info);
	_error($info, "mtriinv: Matrix (PDL(s) %s) is/are singular");
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

*msyminv = \&PDL::msyminv;
sub PDL::msyminv {
	&_square;
	my $di = $_[0]->dims_internal;
	my $m = shift->new_or_inplace;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	$m->_call_method('sytrf', $upper, my $ipiv=null, my $info=null);
	_error($info, "msyminv: Block diagonal matrix D (PDL(s) %s) is/are singular (after sytrf factorization)");
	$m->_call_method('sytri',$upper,$ipiv,$info);
	$m = $m->t->tritosym($upper, 0);
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

*mposinv = \&PDL::mposinv;
sub PDL::mposinv {
	&_square;
	my $di = $_[0]->dims_internal;
	my $m = shift->new_or_inplace;
	my $upper = @_ ? (1 - shift)  : pdl (long,1);
	$m->_call_method('potrf', $upper, my $info=null);
	_error($info, "mposinv: matrix (PDL(s) %s) is/are not positive definite (after potrf factorization)");
	$m->_call_method('potri', $upper, $info);
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
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	my $err = setlaerror(NO);
	#TODO: don't transpose
	my ($u, $s, $v, $info) = $m->mdsvd(2);
	setlaerror($err);
	_error($info, "mpinv: SVD algorithm did not converge (PDL %s)");
	unless (defined $tol){
		$tol =  ($dims[$di+1] > $dims[$di] ? $dims[$di+1] : $dims[$di]) * $s((0)) * lamch(3);
	}
	my ($ind, $cind) = which_both( $s > $tol );
	$s->index($cind) .= 0 if defined $cind;
	$s->index($ind)  .= 1/$s->index($ind) ;
	$ind = ($v->t * ($m->_is_complex ? $s->r2C : $s)) x $u->t;
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
	my $di = $_[0]->dims_internal;
	&_2d_array;
	my $m = shift;
	my @dims = $m->dims;
        $m = $m->copy;
	$m->t->_call_method('getrf',my $ipiv=null,my $info = null);
	if($info > 0) {
		$info--;
		laerror("mlu: Factor U is singular: U($info,$info) = 0 (after cgetrf factorization)");
		return $m, $m, $ipiv, $info;
	}
	my $u = $m->mtri;
	my $l = $m->mtri(1);
	my $slice_prefix = ',' x $di;
	my $smallerm1 = ($dims[$di] < $dims[$di+1] ? $dims[$di] : $dims[$di+1]) - 1;
	if ($dims[$di+1] > $dims[$di]) {
		$u = $u->slice("$slice_prefix,:$smallerm1")->sever;
		$l->slice("$slice_prefix :$smallerm1, :$smallerm1")->diagonal($di,$di+1) .= 1;
	} else {
		$l = $l->slice("$slice_prefix:$smallerm1")->sever if $dims[$di+1] < $dims[$di];
		$l->diagonal($di,$di+1) .= 1;
	}
	$l, $u, $ipiv, $info;
}

=head2 mchol

=for ref

Computes Cholesky decomposition of a symmetric matrix also known as symmetric square root.
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

*mchol = \&PDL::mchol;
sub PDL::mchol {
	&_square;
	my $di = $_[0]->dims_internal;
	my($m, $upper) = @_;
	my(@dims) = $m->dims;
	$m = $m->mtri($upper) unless $m->is_inplace(0);
	@dims = @dims[2+$di..$#dims];
	my $uplo =  1 - $upper;
	$m->_call_method('potrf',$uplo,my $info=null);
	_error($info, "mchol: matrix (PDL(s) %s) is/are not positive definite (after potrf factorization)");
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
	&_square;
	my $di = $_[0]->dims_internal;
	my @diag_args = ($di, $di+1);
	my $slice_arg = (',' x $di) . ":-2, 1:";
	my $m = shift;
	my(@dims) = $m->dims;
	$m = $m->t->copy;
	$m->_call_method('gehrd',1,$dims[$di], my $tau = $m->_similar($dims[$di]-1),my $info = null);
	(my $q = $m->copy)->_call_method(['orghr','cunghr'], 1, $dims[$di], $tau, $info) if wantarray;
	my $h = ($m = $m->t)->mtri;
	$h->slice($slice_arg)->diagonal(@diag_args) .= $m->slice($slice_arg)->diagonal(@diag_args);
	wantarray ? return ($h, $q->t->sever) : $h;
}

=head2 mschur

=for ref

Computes Schur form, works inplace.

	A = Z x T x Z'

Supports threading for unordered eigenvalues.
Uses L<gees|PDL::LinearAlgebra::Real/gees> or L<cgees|PDL::LinearAlgebra::Complex/cgees>
from Lapack and returns schur(T) in scalar context.
Works on transposed array(s).

=for usage

 ( PDL(schur), (PDL(eigenvalues), (PDL(left schur vectors), PDL(right schur vectors), $sdim), $info) ) = mschur(PDL(A), SCALAR(schur vector),SCALAR(left eigenvector), SCALAR(right eigenvector),SCALAR(select_func), SCALAR(backtransform), SCALAR(norm))
 schur vector	     : Schur vectors returned, none = 0 | all = 1 | selected = 2, default = 0
 left eigenvector    : Left eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 right eigenvector   : Right eigenvectors returned, none = 0 | all = 1 | selected = 2, default = 0
 select_func	     : Select_func is used to select eigenvalues to sort
		       to the top left of the Schur form.
		       An eigenvalue is selected if PerlInt select_func(w) is true;
		       (the inputs are converted to complex ndarrays for you)
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func(w) = 1 after ordering, since
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
	my $w = shift;
	# select "discrete time" eigenspace
	return $w->Cabs < 1 ? 1 : 0;
 }
 my ($schur,$eigen,$svectors,$evectors)  = mschur($a,1,1,0,\&select);

=cut

sub _eigen_extract {
  my ($jobvl, $jobvr, $vl, $vr, @w) = @_;
  return ($w[0], $vl, $vr) if @w == 1;
  my $w;
  ($w, $vl) = cplx_eigen(@w, $vl, 1) if $jobvl;
  ($w, $vr) = cplx_eigen(@w, $vr, 1) if $jobvr;
  $w = _ecplx(@w) if !defined $w;
  ($w, $vl, $vr);
}

sub _eigen_one {
  my ($mm, $select_func, $jobv, $jobvl, $jobvr, $mult, $norm, $mdim, $sdim, @w) = @_;
  my $job = $jobvr && $jobvl ? undef : $jobvl ? 2 : 1;
  my $is_mult = $jobvl == 1 || $jobvr == 1 || $mult;
  $_ = $mm->_similar_null for my ($vl, $vr);
  $mult = ($select_func && !$is_mult) ? 2 : !$jobv ? 0 : $mult;
  my $sel = ($select_func && !$is_mult) ? zeroes($mdim) : undef;
  $sel(:($sdim-1)) .= 1 if defined $sel;
  $mm->_call_method('trevc', $job, $mult, $sel, $vl, $vr, $sdim, my $infos=null);
  @w = map $is_mult || !$select_func ? $_ : $_(:($sdim-1)), @w if @w == 2;
  my @ret;
  for ([$jobvr,$vr], [$jobvl,$vl]) {
    unshift(@ret, undef), next if !$_->[0];
    my $val;
    if (@w == 2) {
      (undef,$val) = cplx_eigen(@w,$norm?($_->[1],1):($_->[1]->t,0));
    } else {
      $val = $_->[1];
    }
    unshift(@ret, $norm ? $val->_norm(1,1) : $val), next if !$is_mult or !$select_func;
    my $di = $val->dims_internal;
    my $slice_prefix = ',' x $di;
    $val = $val->slice("$slice_prefix,:@{[$sdim-1]}")->sever if $_->[0] == 2;
    $val = $val->_norm(1,1) if $norm;
    unshift @ret, $val;
  }
  @ret;
}

*mschur = \&PDL::mschur;
sub PDL::mschur {
	&_square;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my ($m, $jobv, $jobvl, $jobvr, $select_func, $mult, $norm) = @_;
	my @dims = $m->dims;
	barf("mschur: threading not supported for selected vectors")
		if $select_func && @dims > 2+$di
		  && (grep $_ == 2, $jobv, $jobvl, $jobvr);
	$mult //= 1;
	$norm //= 1;
	$jobv = $jobvl = $jobvr = 0 unless wantarray;
	my $mm = $m->new_or_inplace->t;
	my $v = $m->_similar_null;
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	my $select_f = $m->_wrap_select_func($select_func);
	$mm->_call_method('gees',
		$jobv, $select_func ? 1 : 0, @w,
		$v, my $sdim = null, my $info = null, $select_f
	);
	_error_schur($info, $select_func, $dims[$di], 'mschur', 'QR');
	my @ret = !$select_func || $sdim ? () : map _complex_null(), grep $_ == 2, $jobvl, $jobvr;
	push @ret, $sdim if $select_func;
	$_ = 0 for grep $select_func && $_ == 2 && !$sdim, $jobvl, $jobvr;
	my $w = @w == 2 ? _ecplx(@w) : @w[0];
	if ($jobvl || $jobvr){
		unshift @ret, grep defined, _eigen_one(
		  $mm, $select_func, $jobv, $jobvl, $jobvr,
		  $mult, $norm, $dims[$di+1], $sdim, @w
		);
	}
	if ($jobv == 2 && $select_func) {
		unshift @ret, $sdim > 0 ? $v->t->slice("$slice_prefix:@{[$sdim-1]}")->sever : $m->_similar_null;
	}
	elsif($jobv){
		unshift @ret, $v->t->sever;
	}
	$m = $mm->t->sever unless $m->is_inplace(0);
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
		       An eigenvalue is selected if PerlInt select_func(w) is true;
		       (the inputs are converted to complex ndarrays for you)
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func(w) = 1 after ordering, since
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
sub PDL::mschurx {
	&_square;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my($m, $jobv, $jobvl, $jobvr, $select_func, $sense, $mult,$norm) = @_;
	my(@dims) = $m->dims;
	$mult //= 1;
	$norm //= 1;
	$jobv = $jobvl = $jobvr = 0 unless wantarray;
	my $select = long($select_func ? 1 : 0);
	$sense = pdl(long,0) if !$select_func;
	$_ = null for my ($info, $sdim, $rconde, $rcondv);
	my $mm = $m->new_or_inplace->t;
	my $v = $m->_similar_null;
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	my $select_f = $m->_wrap_select_func($select_func);
	$mm->_call_method('geesx', $jobv, $select, $sense, @w, $v, $sdim, $rconde, $rcondv,$info, $select_f);
	_error_schur($info, $select_func, $dims[$di], 'mschurx', 'QR');
	my @vl = ('VL', $jobvl);
	my @vr = ('VR', $jobvr);
	my %ret;
	$ret{$_->[0]} = _complex_null(), $_->[1]=0 for grep $select_func && !$sdim && $_->[1] == 2, \@vl, \@vr;
	$ret{n} = $sdim if $select_func;
	if ($vl[1] || $vr[1]) {
		my ($vl, $vr) = _eigen_one(
		  $mm, $select_func, $jobv, $vl[1], $vr[1],
		  $mult, $norm, $dims[$di+1], $sdim, @w
		);
		$ret{$_->[0]} = $_->[1] for grep defined $_->[1], ['VL',$vl], ['VR',$vr];
	}
	my $w = _ecplx(@w);
	if ($jobv == 2 && $select_func) {
		$v = $sdim > 0 ? $v->t->slice("$slice_prefix:@{[$sdim-1]},")->sever : $m->_similar_null;
	}
	elsif($jobv){
		$v =  $v->t->sever;
	}
	$ret{info} = $info;
	$ret{rconde} = $rconde if $sense & 1;
	$ret{rcondv} = $rcondv if $sense & 2;
	$m = $mm->t->sever unless $m->is_inplace(0);
	!wantarray ? $m : ($m, $w, ($jobv ? $v : ()), %ret);
}

# scale by max(abs(real)+abs(imag))
sub magn_norm {
	my ($m, $trans) = @_;
	# If trans == true => transpose output matrix
	my $ret = PDL::cat(map $m->$_, qw(re im))->mv(-1,0)->abs->sumover->maxover->dummy(0);
	$m = $m->t, $ret = $ret->t if $trans;
	($m/$ret)->reshape(-1);
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
		       PerlInt select_func(alpha,beta) is true;
		       (the inputs are converted to complex ndarrays for you)
		       Note that a selected complex eigenvalue may no longer
		       satisfy select_func = 1 after ordering, since
		       ordering may change the value of complex eigenvalues
		       (especially if the eigenvalue is ill-conditioned).
		       All eigenvalues/vectors are selected if select_func is undefined.
 backtransform	     : Whether or not backtransforms eigenvectors to those of (A,B).
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

sub _eigen_pair {
  my (
    $mm, $pp, $select_func, $jobvl, $jobvr, $jobvsl, $jobvsr, $vsl, $vsr,
    $mult, $norm, $mdim, $sdim, @w
  ) = @_;
  my $job = !($jobvr && $jobvl) ? $jobvl ? 2 : 1 : undef;
  $_ = $mm->_similar_null for my ($vl, $vr);
  $mult = 0 if ($jobvl && !$jobvsl) || ($jobvr && !$jobvsr);
  if (!$select_func || ($jobvl == 1 || $jobvr == 1 || $mult)) {
    $vl .= $vsl if $jobvl && $jobvsl;
    $vr .= $vsr if $jobvr && $jobvsr;
  }
  my ($sdim_in, $sel) = $sdim;
  if ($select_func) {
    if ($jobvl == 1 || $jobvr == 1 || $mult) {
      $sdim_in = null;
    } else {
      $sel = zeroes($mdim);
      $sel(:($sdim-1)) .= 1;
      $mult = 2;
      @w = map $_(:($sdim-1)), @w;
    }
  }
  $mm->_call_method('tgevc', $job, $mult, $pp, $sel, $vl, $vr, $sdim_in, my $infos=null);
  if (@w == 2) {
    (undef,$vl) = cplx_eigen(@w,$vl->t,0) if $jobvl;
    (undef,$vr) = cplx_eigen(@w,$vr->t,0) if $jobvr;
  }
  if ($select_func && ($jobvl == 1 || $jobvr == 1 || $mult)) {
    $vr = $vr(,:($sdim-1))->sever if $jobvr == 2;
    $vl = $vl(,:($sdim-1))->sever if $jobvl == 2;
  }
  $vl = magn_norm($vl,1) if $jobvl and $norm;
  $vr = magn_norm($vr,1) if $jobvr and $norm;
  ($vl, $vr);
}

*mgschur = \&PDL::mgschur;
sub PDL::mgschur {
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	&_square_same;
	my($m, $p, $jobvsl, $jobvsr, $jobvl, $jobvr, $select_func, $mult, $norm) = @_;
	my @mdims  = $m->dims;
	$_ = $_->new_or_inplace->t for $m, $p;
	barf("mgschur: threading isn't supported for selected vectors")
		if ($select_func && ((@mdims > 2+$di) || ($p->ndims > 2+$di)) &&
			($jobvsl == 2 || $jobvsr == 2 || $jobvl == 2 || $jobvr == 2));
	$mult //= 1;
	$norm //= 1;
	my $select = $select_func ? pdl(long,1) : pdl(long,0);
	$_ = null for my ($info, $sdim);
	my $select_f = $m->_wrap_select_func($select_func);
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	$_ = $m->_similar_null for my ($beta, $vsl, $vsr);
	$m->_call_method('gges', $jobvsl, $jobvsr, $select, $p, @w, $beta, $vsl, $vsr, $sdim, $info, $select_f);
	_error_schur($info, $select_func, $mdims[$di], 'mgschur', 'QZ');
	my @vl = ('VL', $jobvl);
	my @vr = ('VR', $jobvr);
	my %ret;
	$ret{$_->[0]} = _complex_null(), $_->[1]=0 for grep $select_func && !$sdim && $_->[1] == 2, \@vl, \@vr;
	$ret{n} = $sdim if $select_func;
	if ($vl[1] || $vr[1]) {
		my ($vl, $vr) = _eigen_pair(
		  $m, $p, $select_func, $vl[1], $vr[1], $jobvsl, $jobvsr, $vsl, $vsr,
		  $mult, $norm, $mdims[$di+1], $sdim, @w
		);
		$ret{$_->[0]} = $_->[1] for grep defined $_->[1], ['VL',$vl], ['VR',$vr];
	}
	my $w = @w == 2 ? _ecplx(@w) : @w[0];
	if ($jobvsl == 2 && $select_func) {
		$ret{SL} = $sdim ? $vsl->t->slice("$slice_prefix:@{[$sdim-1]},")->sever : $m->_similar_null;
	}
	elsif($jobvsl){
		$ret{SL} = $vsl->t->sever;
	}
	if ($jobvsr == 2 && $select_func) {
		$ret{SR} = $sdim ? $vsr->t->slice("$slice_prefix:@{[$sdim-1]},")->sever : $m->_similar_null;
	}
	elsif($jobvsr){
		$ret{SR} = $vsr->t->sever;
	}
	$ret{info} = $info;
	return ($m->t, $p->t, $w, $beta, %ret);
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
		       PerlInt select_func(alpha,beta) is true;
		       (the inputs are converted to complex ndarrays for you)
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

 backtransform	     : Whether or not backtransforms eigenvectors to those of (A,B).
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
sub PDL::mgschurx {
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	&_square_same;
	my($m, $p, $jobvsl, $jobvsr, $jobvl, $jobvr, $select_func, $sense, $mult, $norm) = @_;
	my (@mdims) = $m->dims;
	$_ = $_->new_or_inplace->t for $m, $p;
	$mult //= 1;
	$norm //= 1;
	my $select = $select_func ? 1 : 0;
	$sense = 0 if !$select_func;
	$_ = null for my ($info, $rconde, $rcondv, $sdim);
	$_ = $m->_similar_null for my ($beta, $vsl, $vsr);
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	my $select_f = $m->_wrap_select_func($select_func);
	$m->_call_method('ggesx', $jobvsl, $jobvsr, $select, $sense, $p, @w, $beta, $vsl, $vsr, $sdim, $rconde, $rcondv,$info, $select_f);
	_error_schur($info, $select_func, $mdims[$di], 'mgschurx', 'QZ');
	my @vl = ('VL', $jobvl);
	my @vr = ('VR', $jobvr);
	my %ret;
	$ret{$_->[0]} = _complex_null(), $_->[1]=0 for grep $select_func && !$sdim && $_->[1] == 2, \@vl, \@vr;
	$ret{n} = $sdim if $select_func;
	if ($vl[1] || $vr[1]) {
		my ($vl, $vr) = _eigen_pair(
		  $m, $p, $select_func, $vl[1], $vr[1], $jobvsl, $jobvsr, $vsl, $vsr,
		  $mult, $norm, $mdims[$di+1], $sdim, @w
		);
		$ret{$_->[0]} = $_->[1] for grep defined $_->[1], ['VL',$vl], ['VR',$vr];
	}
	if ($jobvsl == 2 && $select_func) {
		$ret{SL} = $sdim ? $vsl->t->slice("$slice_prefix:@{[$sdim-1]},")->sever : $m->_similar_null;
	}
	elsif($jobvsl){
		$ret{SL} = $vsl->t->sever;
	}
	if ($jobvsr == 2 && $select_func) {
		$ret{SR} = $sdim ? $vsr->t->slice("$slice_prefix:@{[$sdim-1]},")->sever : $m->_similar_null;
	}
	elsif($jobvsr){
		$ret{SR} = $vsr->t->sever;
	}
	my $w = @w == 2 ? _ecplx(@w) : @w[0];
	$ret{info} = $info;
	$ret{rconde} = $rconde if $sense & 1;
	$ret{rcondv} = $rcondv if $sense & 2;
	return ($m->t, $p->t, $w, $beta, %ret);
}

=head2 mqr

=for ref

Computes QR decomposition.
Handles complex data.
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

*mqr = \&PDL::mqr;
sub PDL::mqr {
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my @di_vals = $_[0]->dims_internal_values;
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	$m = $m->t->copy;
	my $min = $dims[$di] < $dims[$di+1] ? $dims[$di] : $dims[$di+1];
	my $slice_arg = (',' x $di) . ",:@{[$min-1]}";
	my $tau = $m->_similar($min);
	$m->_call_method('geqrf', $tau, my $info = null);
	if ($info){
		laerror ("mqr: Error $info in geqrf\n");
		return ($m->t->sever, $m, $info);
	}
	my $q = ($dims[$di] > $dims[$di+1] ? $m->slice($slice_arg) : $m)->copy;
	$q->reshape(@di_vals, @dims[$di+1,$di+1]) if $full && $dims[$di] < $dims[$di+1];
	$q->_call_method(['orgqr','cungqr'], $tau, $info);
	return $q->t->sever unless wantarray;
	my $r = (($dims[$di] < $dims[$di+1] && !$full) ? $m->t->slice($slice_arg) : $m->t)->tricpy(0);
	return ($q->t->sever, $r, $info);
}

=head2 mrq

=for ref

Computes RQ decomposition.
Handles complex data.
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

*mrq = \&PDL::mrq;
sub PDL::mrq {
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my @diag_args = ($di, $di+1);
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $r);
        $m = $m->t->copy;
	my $min = $dims[$di] < $dims[$di+1] ? $dims[$di] : $dims[$di+1];
	my $tau = $m->_similar($min);
	$m->_call_method('gerqf', $tau, my $info = null);
	if ($info){
		laerror ("mrq: Error $info in gerqf\n");
		return ($m, $m->t->sever, $info);
	}
	if ($dims[$di] > $dims[$di+1] && $full){
		$q = $m->_similar(@dims[$di,$di]);
		$q->slice("$slice_prefix@{[$dims[$di] - $dims[$di+1]]}:") .= $m;
	}
	elsif ($dims[$di] < $dims[$di+1]){
		$q = $m->slice("$slice_prefix@{[$dims[$di+1] - $dims[$di]]}:")->copy;
	}
	else{
		$q = $m->copy;
	}
	$q->_call_method(['orgrq','cungrq'], $tau, $info);
	return $q->t->sever unless wantarray;
	if ($dims[$di] > $dims[$di+1] && $full){
		$r = $m->t->tricpy(0);
		$r->slice("$slice_prefix:@{[$min-1]},:@{[$min-1]}")->diagonal(@diag_args) .= 0;
	}
	elsif ($dims[$di] < $dims[$di+1]){
		my $temp = $m->_similar(@dims[$di+1,$di+1]);
		$temp->slice("$slice_prefix-$min:") .= $m->t;
		$r = $temp->tricpy(0);
		$r = $r->slice("$slice_prefix-$min:")->sever;
	}
	else{
		$r = $m->t->slice("$slice_prefix@{[$dims[$di] - $dims[$di+1]]}:")->tricpy(0);
	}
	return ($r, $q->t->sever, $info);
}

=head2 mql

=for ref

Computes QL decomposition.
Handles complex data.
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

*mql = \&PDL::mql;
sub PDL::mql {
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my @diag_args = ($di, $di+1);
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q, $l);
        $m = $m->t->copy;
	my $min = $dims[$di] < $dims[$di+1] ? $dims[$di] : $dims[$di+1];
	my $tau = $m->_similar($min);
	$m->_call_method('geqlf', $tau, my $info = null);
	if ($info){
		laerror("mql: Error $info in geqlf\n");
		return ($m->t->sever, $m, $info);
	}
	if ($dims[$di] < $dims[$di+1] && $full){
		$q = $m->_similar(@dims[$di+1,$di+1]);
		$q->slice("$slice_prefix:,-$dims[$di]:") .= $m;
	}
	elsif ($dims[$di] > $dims[$di+1]){
		$q = $m->slice("$slice_prefix:,-$min:")->copy;
	}
	else{
		$q = $m->copy;
	}
	$q->_call_method(['orgql','cungql'], $tau, $info);
	return $q->t->sever unless wantarray;
	if ($dims[$di] < $dims[$di+1] && $full){
		$l = $m->t->tricpy(1);
		$l->slice("$slice_prefix:@{[$min-1]},:@{[$min-1]}")->diagonal(@diag_args) .= 0;
	}
	elsif ($dims[$di] > $dims[$di+1]){
		my $temp = $m->_similar(@dims[$di,$di]);
		$temp->slice("$slice_prefix:,-$dims[$di+1]:") .= $m->t;
		$l = $temp->tricpy(0);
		$l = $l->slice("$slice_prefix:,-$dims[$di+1]:");
	}
	else{
		$l = $m->t->slice("$slice_prefix:,@{[$dims[$di+1] - $min]}:")->tricpy(1);
	}
	return ($q->t->sever, $l, $info);
}

=head2 mlq

=for ref

Computes LQ decomposition.
Handles complex data.
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

*mlq = \&PDL::mlq;
sub PDL::mlq {
	&_2d_array;
	my $di = $_[0]->dims_internal;
	my($m, $full) = @_;
	my(@dims) = $m->dims;
	my ($q);
	$m = $m->t->copy;
	my $min = $dims[$di] < $dims[$di+1] ? $dims[$di] : $dims[$di+1];
	my $slice_arg = (',' x $di) . ":@{[$min-1]}";
	my $tau = $m->_similar($min);
	$m->_call_method('gelqf', $tau, my $info = null);
	if ($info){
		laerror("mlq: Error $info in gelqf\n");
		return ($m, $m->t->sever, $info);
	}
	if ($dims[$di] > $dims[$di+1] && $full){
		$q = $m->_similar(@dims[$di,$di]);
		$q->slice($slice_arg) .= $m;
	}
	elsif ($dims[$di] < $dims[$di+1]){
		$q = $m->slice($slice_arg)->copy;
	}
	else{
		$q = $m->copy;
	}
	$q->_call_method(['orglq','cunglq'], $tau, $info);
	return $q->t->sever unless wantarray;
	my $l = (($dims[$di] > $dims[$di+1] && !$full) ? $m->t->slice($slice_arg) : $m->t)->tricpy(1);
	return ($l, $q->t->sever, $info);
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

*msolve = \&PDL::msolve;
sub PDL::msolve {
	&_square;
	&_matrices_match;
	&_same_dims;
	my($a, $b) = @_;
	$a = $a->t->copy;
	my $c = $b->new_or_inplace->t;
	$a->_call_method('gesv', $c, my $ipiv = null, my $info = null);
	_error($info, "msolve: Can't solve system of linear equations (after getrf factorization): matrix (PDL(s) %s) is/are singular");
	$b = $c->t->sever if !$b->is_inplace(0);
	wantarray ? ($b, $a->t->sever, $ipiv, $info) : $b;
}

=head2 msolvex

=for ref

Solves linear system of equations using LU decomposition.

	A * X = B

Can optionally equilibrate the matrix.
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
 LU:		returns lu decomposition in HASH{LU}
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
	&_square;
	&_matrices_match;
	my $di = $_[0]->dims_internal;
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	$a = $a->t->copy;
	$b = $b->t->copy;
	my $x = $a->_similar_null;
	my $af = PDL::zeroes $a;
	$_ = null for my ($info, $rcond, $rpvgrw, $ferr, $berr);
	my $equed = pdl(long, 0);
	my $ipiv = zeroes(long, $adims[$di]);
	$a->_call_method('gesvx', $opt{transpose}, $opt{equilibrate} ? 2 : 1, $b, $af, $ipiv, $equed, my $r = null, my $c = null, $x, $rcond, $ferr, $berr, $rpvgrw,$info);
	if( $info < $adims[$di] && $info > 0){
		$info--;
		laerror("msolvex: Can't solve system of linear equations:\nfactor U($info,$info)".
		" of coefficient matrix is exactly 0");
	}
	elsif ($info != 0 and $_laerror){
		warn ("msolvex: The matrix is singular to working precision");
	}
	return $x->t->sever unless wantarray;
	my %result = (rcondition => $rcond, ferror => $ferr, berror => $berr);
	if ($opt{equilibrate}){
		$result{equilibration} = $equed;
		$result{row} = $r if $equed & 1;
		$result{column} = $c if $equed & 2;
		if ($equed){
			$result{A} = $a->t->sever if $opt{A};
			$result{B} = $b->t->sever if $opt{B};
		}
	}
	@result{qw(pivot rpvgrw info)} = ($ipiv, $rpvgrw, $info);
        $result{LU} = $af->t->sever if $opt{LU};
	return ($x->t->sever, %result);
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

*mtrisolve = \&PDL::mtrisolve;
sub PDL::mtrisolve{
	&_square;
	my $uplo = splice @_, 1, 1;
	&_matrices_match;
	&_same_dims;
	my($a, $b, $trans, $diag) = @_;
	$uplo = 1 - $uplo;
	$trans = 1 - $trans;
	my $c = $b->new_or_inplace->t;
	$a->_call_method('trtrs', $uplo, $trans, $diag, $c, my $info = null);
	_error($info, "mtrisolve: Can't solve system of linear equations: matrix (PDL(s) %s) is/are singular");
	$b = $c->t->sever if !$b->is_inplace(0);
	wantarray ? ($b, $info) : $b;
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

*msymsolve = \&PDL::msymsolve;
sub PDL::msymsolve {
	&_square;
	my $uplo = splice @_, 1, 1;
	&_matrices_match;
	&_same_dims;
	my($a, $b) = @_;
	$uplo = 1 - $uplo;
	$a = $a->copy;
	my $c = $b->new_or_inplace->t;
	$a->_call_method('sysv', $uplo, $c, my $ipiv = null, my $info = null);
	_error($info, "msymsolve: Can't solve system of linear equations (after sytrf factorization): matrix (PDL(s) %s) is/are singular");
	$b = $c->t->sever if !$b->is_inplace(0);
	wantarray ? ($b, $a, $ipiv, $info) : $b;
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
	&_square;
	my $uplo = splice @_, 1, 1;
	&_matrices_match;
	my $di = $_[0]->dims_internal;
	my($a, $b, $d) = @_;
	my(@adims) = $a->dims;
	$uplo = 1 - $uplo;
	$b = $b->t;
	my $x = $a->_similar_null;
	my $af =  PDL::zeroes $a;
	$_ = null for my ($info, $rcond, $ferr, $berr);
	my $ipiv = zeroes(long, $adims[$di]);
	$a->_call_method('sysvx', $uplo, 0, $b, $af, $ipiv, $x, $rcond, $ferr, $berr, $info);
	if( $info < $adims[$di] && $info > 0){
		$info--;
		laerror("msymsolvex: Can't solve system of linear equations:\nfactor D($info,$info)".
		" of coefficient matrix is exactly 0");
	}
	elsif ($info != 0 and $_laerror){
		warn("msymsolvex: The matrix is singular to working precision");
	}
	my %result = (rcondition => $rcond, ferror => $ferr, berror => $berr, info => $info);
	@result{qw(pivot D)} = ($ipiv, $af) if $d;
	wantarray ? ($x->t->sever, %result): $x->t->sever;
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


*mpossolve = \&PDL::mpossolve;
sub PDL::mpossolve {
	&_square;
	my $uplo = splice @_, 1, 1;
	&_matrices_match;
	&_same_dims;
	my($a, $b) = @_;
	$uplo = 1 - $uplo;
	$a = $a->copy;
	my $c = $b->new_or_inplace->t;
	$a->_call_method('posv', $uplo, $c, my $info=null);
	_error($info, "mpossolve: Can't solve system of linear equations: matrix (PDL(s) %s) is/are not positive definite");
	wantarray ? $b->is_inplace(0) ? ($b, $a,$info) : ($c->t->sever , $a,$info) : $b->is_inplace(0) ? $b : $c->t->sever;
}

=head2 mpossolvex

=for ref

Solves linear system of equations using Cholesky decomposition with
symmetric positive definite matrix A

	A * X = B

Can optionally equilibrate the matrix.
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
 U|L:		returns Cholesky factorization in HASH{U} or HASH{L}
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
	&_square;
	my $uplo = splice(@_, 1, 1) ? 0 : 1;
	&_matrices_match;
	my $di = $_[0]->dims_internal;
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my $equilibrate = $opt{'equilibrate'} ? 2: 1;
	$a = $a->copy;
	$b = $b->t->copy;
	my $x = $a->_similar_null;
	my $af = PDL::zeroes $a;
	my $equed = pdl(long, 0);
	$a->_call_method('posvx', $uplo, $equilibrate, $b, $af, $equed, my $s = null, $x, my $rcond=null, my $ferr=null, my $berr=null, my $info=null);
	if( $info < $adims[$di] && $info > 0){
		$info--;
		barf("mpossolvex: Can't solve system of linear equations:\n".
			"the leading minor of order $info of A is".
                         " not positive definite");
		return;
	}
	elsif ( $info  and $_laerror){
		warn("mpossolvex: The matrix is singular to working precision");
	}
	my %result = (rcondition=>$rcond, ferror=>$ferr, berror=>$berr);
	if ($opt{equilibrate}){
		$result{equilibration} = $equed;
		if ($equed){
			$result{scale} = $s if $equed;
			$result{A} = $a if $opt{A};
			$result{B} = $b->t->sever if $opt{B};
		}
	}
	$result{info} = $info;
        $result{L} = $af if $opt{L};
        $result{U} = $af if $opt{U};
	wantarray ? ($x->t->sever, %result): $x->t->sever;
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
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	&_matrices_matchrows;
	my($a, $b, $trans) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my $x;
	$a = $a->copy;
	if ( $adims[$di+1] < $adims[$di]) {
		$x = $a->_similar($adims[$di], $bdims[$di]);
		$x->slice("$slice_prefix:@{[$bdims[$di+1]-1]}, :@{[$bdims[$di]-1]}") .= $b->t;
	} else {
		$x = $b->t->copy;
	}
	$a->_call_method('gels', $trans ? 0 : 1, $x, my $info = null);
	$x = $x->t;
	return $x->sever if $adims[$di+1] <= $adims[$di];
	my $sliced = $x->slice("$slice_prefix, :@{[$adims[$di]-1]}")->sever;
	return $sliced if !wantarray;
	my $power = $a->_similar(1); $power .= 2;
	($sliced, ($x->slice("$slice_prefix, $adims[$di]:")->t ** $power)->sumover);
}

=head2 mllsy

=for ref

Computes the minimum-norm solution to a real linear least squares problem
using a complete orthogonal factorization.

Uses L<gelsy|PDL::LinearAlgebra::Real/gelsy> or L<cgelsy|PDL::LinearAlgebra::Complex/cgelsy>
from Lapack. Works on transposed arrays.

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
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	&_matrices_matchrows;
	my($a, $b) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my $rcond = lamch(0);
	$rcond = $rcond->sqrt - ($rcond->sqrt - $rcond) / 2;
	$a = $a->t->copy;
	my ($x);
	if ( $adims[1+$di] < $adims[0+$di]){
		$x = $a->_similar($adims[$di], $bdims[$di]);
		$x->slice("$slice_prefix:@{[$bdims[$di+1]-1]}, :@{[$bdims[$di]-1]}") .= $b->t;
	}
	else{
		$x = $b->t->copy;
	}
	my $info = null;
	my $rank = null;
	my $jpvt = zeroes(long, $adims[$di]);
	$a->_call_method('gelsy', $x,  $rcond, $jpvt, $rank, $info);
	my %ret = !wantarray ? () : ('A'=> $a->t->sever, 'rank' => $rank, 'jpvt'=>$jpvt);
	return wantarray ? ($x->t->sever, %ret) : $x->t->sever if $adims[$di+1] <= $adims[$di];
	$x = $x->t->slice("$slice_prefix, :@{[$adims[$di]-1]}")->sever;
	wantarray ? ($x, %ret) : $x;
}

=head2 mllss

=for ref

Computes the minimum-norm solution to a real linear least squares problem
using a singular value decomposition.

Uses L<gelss|PDL::LinearAlgebra::Real/gelss> or L<gelsd|PDL::LinearAlgebra::Real/gelsd> from Lapack.
Works on transposed arrays.

=for usage

 ( PDL(X), ( HASH(result) ) )= mllss(PDL(A), PDL(B), SCALAR(method))
 method: specifies which method to use (see Lapack for further details)
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
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	&_matrices_matchrows;
	my($a, $b, $method) = @_;
	my @adims = $a->dims;
	my @bdims = $b->dims;
	#TODO: Add this in option
	my $rcond = lamch(0);
	$rcond = $rcond->sqrt - ($rcond->sqrt - $rcond) / 2;
	$a = $a->t->copy;
	my $x;
	if ($adims[1+$di] < $adims[0+$di]){
		$x = $a->_similar($adims[$di], $bdims[$di]);
		$x->slice("$slice_prefix:@{[$bdims[$di+1]-1]}, :@{[$bdims[$di]-1]}") .= $b->t;
	}
	else{
		$x = $b->t->copy;
	}
	$_ = null for my ($info, $rank, $s);
	my $min = ($adims[$di] > $adims[$di+1]) ? $adims[$di+1] : $adims[$di];
	$method ||= 'gelsd';
	$a->_call_method($method, $x,  $rcond, $s, $rank, $info);
	laerror("mllss: The algorithm for computing the SVD failed to converge\n") if $info;
	$x = $x->t;
	my %ret = !wantarray ? () : (rank => $rank, s=>$s, info=>$info);
	$ret{V} = $a if wantarray and $method =~ /gelss/;
	return wantarray ? ($x->sever, %ret) : $x->sever if $adims[1+$di] <= $adims[0+$di];
	if (wantarray and $rank == $min) {
		my $power = $a->_similar(1); $power .= 2;
		$ret{res} = ($x->slice("$slice_prefix, $adims[$di]:")->t ** $power)->sumover;
	}
	$x = $x->slice("$slice_prefix, :@{[$adims[$di]-1]}")->sever;
	wantarray ? ($x->sever, %ret) : $x->sever;
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

*mglm = \&PDL::mglm;
sub PDL::mglm{
	my($a, $b, $d) = @_;
	my $di = $_[0]->dims_internal;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my(@ddims) = $d->dims;
	barf("mglm: Require arrays with equal number of rows")
		unless( @adims >= 2+$di && @bdims >= 2+$di && $adims[1+$di] == $bdims[1+$di]);
	barf "mglm: Require that column(A) <= row(A) <= column(A) + column(B)" unless
		( ($adims[0+$di] <= $adims[1+$di] ) && ($adims[1+$di] <= ($adims[0+$di] + $bdims[0+$di])) );
	barf("mglm: Require vector(s) with size equal to number of rows of A")
		unless( @ddims >= 1+$di  && $adims[1+$di] == $ddims[0+$di]);
	$a = $a->t->copy;
	$b = $b->t->copy;
	$d = $d->copy;
	my ($x, $y, $info) = $a->_call_method('ggglm', $b, $d);
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
 c	: The right hand side vector for the
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
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my($a, $b, $c, $d) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	my(@cdims) = $c->dims;
	my(@ddims) = $d->dims;
	&_matrices_matchcolumns;
	barf("mlse: Require 1D vector C with size equal to number of A rows")
		unless( (@cdims == $di+1)&& $adims[$di+2] == $cdims[$di+2]);
	barf("mlse: Require 1D vector D with size equal to number of B rows")
		unless( (@ddims == $di+1)&& $bdims[$di+2] == $ddims[$di+2]);
	barf "mlse: Require that row(B) <= column(A) <= row(A) + row(B)" unless
		( ($bdims[$di+1] <= $adims[$di] ) && ($adims[$di] <= ($adims[$di+1]+ $bdims[$di+1])) );
	$a = $a->t->copy;
	$b = $b->t->copy;
	$c = $c->copy;
	$d = $d->copy;
	my ($x, $info) = $a->_call_method('gglse', $b, $c, $d);
	my $power = $a->_similar(1); $power .= 2;
	my $sumsq = ($c->slice("$slice_prefix @{[$adims[$di]-$bdims[$di+1]]}:@{[$adims[$di+1]-1]}") ** $power)->sumover;
	wantarray ? ($x, $sumsq) : $x;
}

=head2 meigen

=for ref

Computes eigenvalues and, optionally, the left and/or right eigenvectors of a general square matrix
(spectral decomposition).
Eigenvectors are normalized (Euclidean norm = 1) and largest component real.
The eigenvalues and eigenvectors returned are complex ndarrays.
If only eigenvalues are requested, info is returned in array context.
Supports threading.
Uses L<geev|PDL::LinearAlgebra::Real/geev> or L<cgeev|PDL::LinearAlgebra::Complex/cgeev> from Lapack.
Works on transposed arrays.

=for usage

 (PDL(values), (PDL(LV),  (PDL(RV)), (PDL(info)))) = meigen(PDL, SCALAR(left vector), SCALAR(right vector))
 left vector  : FALSE = 0 | TRUE = 1, default = 0
 right vector : FALSE = 0 | TRUE = 1, default = 0

=for example

 my $a = random(10,10);
 my ( $eigenvalues, $left_eigenvectors, $right_eigenvectors )  = meigen($a,1,1);

=cut

*meigen = \&PDL::meigen;
sub PDL::meigen {
	&_square;
	my ($m,$jobvl,$jobvr) = @_;
	$_ = null for my ($info, $sdim);
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	$_ = $m->_similar_null for my ($vl, $vr);
	$m->t->_call_method('geev', $jobvl, $jobvr, @w, $vl, $vr, $info);
	_error($info, "meigen: The QR algorithm failed to converge for PDL(s) %s");
	(my $w, $vl, $vr) = _eigen_extract($jobvl, $jobvr, $vl, $vr, @w);
	return $w if !wantarray;
	($w, ($jobvl?$vl->t->sever:()), ($jobvr?$vr->t->sever:()), $info);
}

=head2 meigenx

=for ref

Computes eigenvalues, one-norm and, optionally, the left and/or right eigenvectors of a general square matrix
(spectral decomposition).
Eigenvectors are normalized (Euclidean norm = 1) and largest component real.
The eigenvalues and eigenvectors returned are complex ndarrays.
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
 error:      specifies whether or not it computes the error bounds (returned in HASH{'eerror'} and HASH{'verror'})
	     error bound = EPS * One-norm / rcond(e|v)
	     (reciprocal condition numbers for eigenvalues or eigenvectors must be computed).
		1: returns error bounds
		0: not computed
 scale:      specifies whether or not it diagonaly scales the entry matrix
	     (scale details returned in HASH : 'scale')
		1: scales
		0: Doesn't scale (default)
 permute:    specifies whether or not it permutes row and columns
	     (permute details returned in HASH{'balance'})
		1: permutes
		0: Doesn't permute (default)
 schur:      specifies whether or not it returns the Schur form (returned in HASH{'schur'})
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
             schur => 1
             );
 my ( $eigenvalues, $left_eigenvectors, $right_eigenvectors, %result)  = meigenx($a,%options);
 print "Error bounds for eigenvalues:\n $eigenvalues\n are:\n". transpose($result{'eerror'}) unless $info;

=cut

my %rcondition2sense = (value => 1, vector => 2, all => 3);
my %vector2jobvl = (left => 1, all => 1);
my %vector2jobvr = (right => 1, all => 1);
*meigenx = \&PDL::meigenx;
sub PDL::meigenx {
	&_square;
	my($m, %opt) = @_;
	my (%result);
	$m = $m->copy;
	$_ = null for my ($info, $ilo, $ihi, $abnrm, $scale, $rconde, $rcondv);
	$_ = $m->_similar_null for my ($vl, $vr);
	my @w = map $m->_similar_null, $m->_is_complex ? 1 : 1..2;
	my $balanc = ($opt{'scale'}?2:0) | ($opt{permute}?1:0);
	my $jobvl = $vector2jobvl{$opt{vector}} || $opt{rcondition} ? 1 : 0;
	my $jobvr = $vector2jobvr{$opt{vector}} || $opt{rcondition} ? 1 : 0;
	my $sense = $rcondition2sense{$opt{rcondition}} || 0;
	$m->t->_call_method('geevx', $jobvl, $jobvr, $balanc, $sense, @w, $vl, $vr, $ilo, $ihi, $scale, $abnrm, $rconde, $rcondv, $info);
	(my $w, $vl, $vr) = _eigen_extract($jobvl, $jobvr, $vl, $vr, @w);
	if ($info){
		laerror("meigenx: The QR algorithm failed to converge");
		print "Returning converged eigenvalues\n" if $_laerror;
	}
	$result{'schur'} = $m if $opt{'schur'};
	$result{'balance'} = cat $ilo, $ihi if $opt{'permute'};
	@result{qw(info norm)} = ($info, $abnrm);
	$result{'scale'} =  $scale if $opt{'scale'};
	if ($sense & 2) {
		$result{'rcondv'} =  $rcondv;
		$result{'verror'} = (lamch(0)* $abnrm /$rcondv  ) if $opt{'error'};
	}
	if ($sense & 1) {
		$result{'rconde'} =  $rconde;
		$result{'eerror'} = (lamch(0)* $abnrm /$rconde  ) if $opt{'error'};
	}
	($w, ($vector2jobvl{$opt{vector}}?$vl->t->sever:()), ($vector2jobvr{$opt{vector}}?$vr->t->sever:()), %result);
}

=head2 mgeigen

=for ref

Computes generalized eigenvalues and, optionally, the left and/or right generalized eigenvectors
for a pair of N-by-N real nonsymmetric matrices (A,B) .
The alpha from ratio alpha/beta is a complex ndarray.
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

*mgeigen = \&PDL::mgeigen;
sub PDL::mgeigen {
	&_square_same;
	&_same_dims;
	my ($a,$b,$jobvl,$jobvr) = @_;
	$_ = $_->new_or_inplace->t for $a, $b;
	$_ = null for my ($info, $sdim);
	my @w = map $a->_similar_null, $a->_is_complex ? 1 : 1..2;
	$_ = $a->_similar_null for my ($vl, $vr, $beta);
	$a->_call_method('ggev', $jobvl, $jobvr, $b, @w, $beta, $vl, $vr, $info);
	_error($info, "mgeigen: Can't compute eigenvalues/vectors for PDL(s) %s");
	(my $w, $vl, $vr) = _eigen_extract($jobvl, $jobvr, $vl, $vr, @w);
	($w, $beta, ($jobvl?$vl->t->sever:()), ($jobvr?$vr->t->sever:()), $info);
}

=head2 mgeigenx

=for ref

Computes generalized eigenvalues, one-norms and, optionally, the left and/or right generalized
eigenvectors for a pair of N-by-N real nonsymmetric matrices (A,B).
The alpha from ratio alpha/beta is a complex ndarray.
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
 error:      specifies whether or not it computes the error bounds (returned in HASH{'eerror'} and HASH{'verror'})
	     error bound = EPS * sqrt(one-norm(a)**2 + one-norm(b)**2) / rcond(e|v)
	     (reciprocal condition numbers for eigenvalues or eigenvectors must be computed).
		1: returns error bounds
		0: not computed
 scale:      specifies whether or not it diagonaly scales the entry matrix
	     (scale details returned in HASH : 'lscale' and 'rscale')
		1: scales
		0: doesn't scale (default)
 permute:    specifies whether or not it permutes row and columns
	     (permute details returned in HASH{'balance'})
		1: permutes
		0: Doesn't permute (default)
 schur:      specifies whether or not it returns the Schur forms (returned in HASH{'aschur'} and HASH{'bschur'})
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
             schur => 1
             );
 ($alpha, $beta, $left_eigenvectors, $right_eigenvectors, %result)  = mgeigenx($a, $b,%options);
 print "Error bounds for eigenvalues:\n $eigenvalues\n are:\n". transpose($result{'eerror'}) unless $info;

=cut

*mgeigenx = \&PDL::mgeigenx;
sub PDL::mgeigenx {
	&_square_same;
	my $di = $_[0]->dims_internal;
	my ($a, $b, %opt) = @_;
	my @adims = $a->dims;
	$_ = $_->new_or_inplace->t for $a, $b;
	my (%result);
	$_ = $a->_similar_null for my ($vl, $vr, $beta);
	my @w = map $a->_similar_null, $a->_is_complex ? 1 : 1..2;
	$_ = null for my ($rconde, $rcondv, $info, $ilo, $ihi, $rscale, $lscale, $abnrm, $bbnrm);
	my $jobvl = $vector2jobvl{$opt{vector}} || $opt{rcondition} ? 1 : 0;
	my $jobvr = $vector2jobvr{$opt{vector}} || $opt{rcondition} ? 1 : 0;
	my $sense = $rcondition2sense{$opt{rcondition}} || 0;
	my $balanc = ($opt{scale}?2:0) | ($opt{permute}?1:0);
	$a->_call_method('ggevx', $balanc, $jobvl, $jobvr, $sense, $b, @w,
	  $beta, $vl, $vr, $ilo, $ihi, $lscale, $rscale,
	  $abnrm, $bbnrm, $rconde, $rcondv, $info);
	(my $w, $vl, $vr) = _eigen_extract($jobvl, $jobvr, $vl, $vr, @w);
	if ($info > 0 && $info < $adims[$di+1]) {
		laerror("mgeigenx: The QZ algorithm failed to converge");
		print "Returning converged eigenvalues\n" if $_laerror;
	} elsif ($info) {
		laerror("mgeigenx: Error from hgeqz or tgevc");
	}
	$result{qw(aschur bschur)} = map $_->t, $a, $b if $opt{schur};
	$result{balance} = cat $ilo, $ihi if $opt{permute};
	@result{qw(info anorm bnorm)} = ($info, $abnrm, $bbnrm);
	@result{qw(lscale rscale)} =  ($lscale, $rscale) if $opt{scale};
	# Doesn't use lacpy2 =(sqrt **2 , **2) without unnecessary overflow
	if ($sense & 2) {
		$result{rcondv} =  $rcondv;
		$result{verror} = lamch(0) * sqrt($abnrm->pow(2) + $bbnrm->pow(2)) /$rcondv if $opt{error};
	}
	if ($sense & 1) {
		$result{rconde} =  $rconde;
		$result{eerror} = lamch(0) * sqrt($abnrm->pow(2) + $bbnrm->pow(2)) /$rconde if $opt{error};
	}
	($w, $beta, ($vector2jobvl{$opt{vector}}?$vl->t:()), ($vector2jobvr{$opt{vector}}?$vr->t:()), %result);
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

*msymeigen = \&PDL::msymeigen;
sub PDL::msymeigen {
	&_square;
	my($m, $upper, $jobv, $method) = @_;
	my ($w, $info) = (null, null);
	$method //= [ 'syevd', 'cheevd' ];
	$m = $m->copy unless ($m->is_inplace(0) and $jobv);
	$m->t->_call_method($method, $jobv, $upper, $w, $info);
	_error($info, "msymeigen: The algorithm failed to converge for PDL(s) %s");
	!wantarray ? $w : ($w, ($jobv?$m:()), $info);
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
 range:		PDL(2), lower and upper bounds interval or smallest and largest indices
		1<=range<=N for indice
 abstol:        specifies error tolerance for eigenvalues
 method:        specifies which method to use (see Lapack for further details)
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

my %range_type2range = (interval => 1, indice => 2);
sub PDL::msymeigenx {
	&_square;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my($m, $upper, $jobz, %opt) = @_;
	my(@dims) = $m->dims;
	my $range = $range_type2range{$opt{range_type}} || 0;
	if ((ref $opt{range}) ne 'PDL'){
		$opt{range} = pdl([0,0]);
		$range = 0;
	}
	elsif ($range == 2){
		barf "msymeigenx: Indices must be > 0" unless $opt{range}->(0) > 0;
		barf "msymeigenx: Indices must be <= $dims[$di+1]" unless $opt{range}->(1) <= $dims[$di+1];
	}
	elsif ($range == 1){
		barf "msymeigenx: Interval limits must be different" unless ($opt{range}->(0) !=  $opt{range}->(1));
	}
	$_ = null for my ($w, $n, $support, $info);
	my $z = $m->_similar_null;
	if (!defined $opt{'abstol'})
	{
		my $unfl = lamch(1);
		$unfl->labad(lamch(9));
		$opt{'abstol'} = $unfl + $unfl;
	}
	my $method = $opt{'method'} || ['syevx','cheevx'];
	$upper = $upper ? 0 : 1;
	$m = $m->copy;
	$m->_call_method($method, $jobz, $range, $upper, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
		 $opt{'abstol'}, $n, $w, $z , $support, $info);
	if ($info){
		laerror("msymeigenx: The algorithm failed to converge.");
		print ("See support for details.\n") if $_laerror;
	}
	if ($jobz){
		return ($w, $z->t->sever, $n, $info, $support) if $info;
		return (undef,undef,$n,$info,$method =~ qr/evr/?$support:()) if $n == 0;
		return ($w(:$n-1)->sever, $z->t->slice("$slice_prefix:@{[$n->sclr-1]}")->sever, $n, $info, $method =~ qr/evr/?$support:());
	}
	else{
		return $w if !wantarray;
		if ($info){
			($w, $n, $info, $support);
		}
		else{
			($w(:$n-1)->sever, $n, $info, $method =~ qr/evr/?$support:());
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

*msymgeigen = \&PDL::msymgeigen;
sub PDL::msymgeigen {
	&_square_same;
	&_same_dims;
	my($a, $b, $upper, $jobv, $type, $method) = @_;
	$type ||= 1;
	$method //= [ 'sygvd', 'chegvd' ];
	$upper = 1-$upper;
	$a = $a->copy;
	$b = $b->copy;
	$a->_call_method($method, $type, $jobv, $upper, $b, my $w = null, my $info = null);
	_error($info, "msymgeigen: Can't compute eigenvalues/vectors: matrix (PDL(s) %s) is/are not positive definite or the algorithm failed to converge");
	!wantarray ? $w : ($w, $jobv?$a->t->sever:(), $info);
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
 range:		PDL(2), lower and upper bounds interval or smallest and largest indices
		1<=range<=N for indice
 abstol:        specifies error tolerance for eigenvalues
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
	&_square_same;
	my $di = $_[0]->dims_internal;
	my($a, $b, $upper, $jobv, %opt) = @_;
	my(@adims) = $a->dims;
	my $range = $range_type2range{$opt{range_type}} || 0;
	if (!UNIVERSAL::isa($opt{range},'PDL')){
		$opt{range} = pdl([0,0]);
		$range = 0;
	}
	$opt{type} //= 1;
	$_ = null for my ($w, $n, $support, $info);
	if (!defined $opt{'abstol'}){
		my $unfl = lamch(1);
		my $ovfl = lamch(9);
		$unfl->labad($ovfl);
		$opt{'abstol'} = $unfl + $unfl;
	}
	my $z = $a->_similar_null;
	$upper = $upper ? 0 : 1;
	$a = $a->copy;
	$b = $b->copy;
	$a->_call_method(['sygvx','chegvx'], $opt{type}, $jobv, $range, $upper,
	  $b, $opt{range}->(0), $opt{range}->(1),$opt{range}->(0),$opt{range}->(1),
	  $opt{'abstol'}, $n, $w, $z ,$support, $info);
	if ( ($info > 0) && ($info < $adims[$di+1])){
		laerror("msymgeigenx: The algorithm failed to converge");
		print("see support for details\n") if $_laerror;
	}
	elsif($info){
		$info = $info - $adims[$di+1] - 1;
		barf("msymgeigenx: The leading minor of order $info of B is not positive definite\n");
	}
	return $w if !wantarray;
	($w, $jobv?$z->t->sever:(), $n, $info, $info?$support:());
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

*mdsvd = \&PDL::mdsvd;
sub PDL::mdsvd {
	my $di = $_[0]->dims_internal;
	my($m, $jobz) = @_;
	my(@dims) = $m->dims;
	$jobz = !wantarray ? 0 : $jobz // 1;
	my $min = $dims[$di] > $dims[1+$di] ? $dims[1+$di]: $dims[$di];
	$m = $m->copy;
	$_ = $m->_similar_null for my ($u, $v);
	$m->_call_method('gesdd', $jobz, my $s = null, $u, $v, my $info = null);
	_error($info, "mdsvd: Matrix (PDL(s) %s) is/are singular");
	return ($u, $s, $v, $info) if $jobz;
	wantarray ? ($s, $info) : $s;
}

=head2 msvd

=for ref

Computes SVD.
Can compute singular values, either U or V or neither.
Return singular values in scalar context else left (U),
singular values, right (V' (hermitian for complex) singular vector and info.
Supports threading.
If only singular values are requested, info is returned in array context.
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

*msvd = \&PDL::msvd;
sub PDL::msvd {
	my ($m, $jobu, $jobv) = @_;
	$jobu = !wantarray ? 0 : $jobu // 1;
	$jobv = !wantarray ? 0 : $jobv // 1;
	$m = $m->copy;
	$_ = $m->_similar_null for my ($u, $v);
	$m->_call_method('gesvd', $jobv, $jobu,my $s = null, $u, $v, my $info = null);
	_error($info, "msvd: Matrix (PDL(s) %s) is/are singular");
	wantarray ? ($jobu?$u:(), $s, $jobv?$v:(), $info) : $s;
}

=head2 mgsvd

=for ref

Computes generalized (or quotient) singular value decomposition.
If the effective rank of (A',B')' is 0 return only unitary V, U, Q.
Handles complex data.
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

my @gsvd_opts = qw(V U Q D1 D2 0R R X);
*mgsvd = \&PDL::mgsvd;
sub PDL::mgsvd {
	&_matrices_matchcolumns;
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my @diag_args = ($di, $di+1);
	my($a, $b, %opt) = @_;
	my(@adims) = $a->dims;
	my(@bdims) = $b->dims;
	@opt{@gsvd_opts} = (1) x @gsvd_opts if $opt{all};
	my $type = $a->type;
	my $jobqx = ($opt{Q} || $opt{X}) ? 1 : 0;
	$a = $a->copy;
	$b = $b->t->copy;
	$_ = null for my ($k, $l, $alpha, $beta, $iwork, $info);
	$_ = $a->_similar_null for my ($U, $V, $Q);
	$a->t->_call_method('ggsvd', $opt{U}, $opt{V}, $jobqx, $b, $k, $l, $alpha, $beta, $U, $V, $Q, $iwork, $info);
	laerror("mgsvd: The Jacobi procedure fails to converge") if $info;
	my %ret = (rank=>$k + $l, info=>$info);
	warn "mgsvd: Effective rank of 0 in mgsvd" if (!$ret{rank} and $_laerror);
	if (%opt) {
		$Q = $Q->t->sever if $jobqx;
		if (($adims[$di+1] - $k - $l)  < 0  && $ret{rank}){
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape((map $a->dim($_-1), 1..$di), $adims[$di], ($k + $l));
				# Slice $a ???  => always square ??
				$a->slice("$slice_prefix@{[$adims[$di] - ($k+$l-$adims[$di+1])]} : , $adims[$di+1]:") .=
						$b->slice("$slice_prefix@{[$adims[$di+1]-$k]}:@{[$l-1]},@[[$adims[$di]+$adims[$di+1]-$k - $l]}:@{[$adims[$di]-1]}")->t;
				$ret{'0R'} = $a if $opt{'0R'};
			}
			if ($opt{'D1'}){
				my $D1 = zeroes($type, $adims[$di+1], $adims[$di+1]);
				$D1->diagonal(0,1) .= $alpha(:($adims[$di+1]-1));
				$D1 = $D1->t->reshape($adims[$di+1] , ($k+$l))->t->sever;
				$ret{'D1'} = $D1;
			}
		}
		elsif ($ret{rank}){
			if ( $opt{'0R'} || $opt{R} || $opt{X}){
				$a->reshape((map $a->dim($_-1), 1..$di), $adims[$di], ($k + $l));
				$ret{'0R'} = $a if $opt{'0R'};
			}
			if ($opt{'D1'}){
				my $D1 = zeroes($type, ($k + $l), ($k + $l));
				$D1->diagonal(0,1) .=  $alpha(:($k+$l-1));
				$D1->reshape(($k + $l), $adims[$di+1]);
				$ret{'D1'} = $D1;
			}
		}
		if ($opt{'D2'} && $ret{rank}){
			my $work = zeroes($b->type, $l, $l);
			$work->diagonal(0,1) .=  $beta($k:($k+$l-1));
			my $D2 = zeroes($b->type, ($k + $l), $bdims[$di+1]);
			$D2( $k:, :($l-1)  ) .= $work;
			$ret{'D2'} = $D2;
		}
		if ( $ret{rank} && ($opt{X} || $opt{R}) ){
			my $work = $a->slice("$slice_prefix@{[-($k + $l)]}:");
			$ret{R} = $work if $opt{R};
			if ($opt{X}){
				my $X = $a->_similar(@adims[$di,$di]);
				$X->diagonal(@diag_args) .= 1 if ($adims[$di] > ($k + $l));
				$X->slice("$slice_prefix@{[-($k + $l)]}:, @{[-($k + $l)]}:") .= mtriinv($work);
				$ret{X} = $Q x $X;
			}
		}
		$ret{U} = $U->t->sever if $opt{U};
		$ret{V} = $V->t->sever if $opt{V};
		$ret{Q} = $Q if $opt{Q};
	}
	$ret{rank} ? return ($alpha($k:($k+$l-1))->sever, $beta($k:($k+$l-1))->sever, %ret ) : (undef, undef, %ret);
}

#TODO

# Others things

#	rectangular diag
#	usage
#	is_inplace and function which modify entry matrix
#	threading support
#	automatically create PDL
#	inplace operation and memory
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
