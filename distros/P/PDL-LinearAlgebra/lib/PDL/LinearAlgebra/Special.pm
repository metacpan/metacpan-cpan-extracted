package PDL::LinearAlgebra::Special;
use PDL::Core;
use PDL::NiceSlice;
use PDL::Slices;
use PDL::Basic qw (sequence xvals yvals);
use PDL::MatrixOps qw (identity);
use PDL::LinearAlgebra qw ( );
use PDL::LinearAlgebra::Real;
use PDL::LinearAlgebra::Complex;
use PDL::Exporter;
no warnings 'uninitialized';
@EXPORT_OK  = qw( mhilb mvander mpart mhankel mtoeplitz mtri mpascal mcompanion);
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

our $VERSION = '0.14';
$VERSION = eval $VERSION;

our @ISA = ( 'PDL::Exporter');

use strict;

=encoding utf8

=head1 NAME

PDL::LinearAlgebra::Special - Special matrices for PDL

=head1 SYNOPSIS

 use PDL::LinearAlgebra::Special;

 $a = mhilb(5,5);

=head1 DESCRIPTION

This module provides some constructors of well known matrices.

=head1 FUNCTIONS

=head2 mhilb

=for ref

Construct Hilbert matrix from specifications list or template ndarray

=for usage

 PDL(Hilbert)  = mpart(PDL(template) | ARRAY(specification))

=for example

 my $hilb   = mhilb(float,5,5);

=cut

sub mhilb {
	if(ref($_[0]) && ref($_[0]) eq 'PDL'){
		 my $pdl = shift;
		 $pdl->mhilb(@_);
	}
	else{
		PDL->mhilb(@_);
	}
}
sub PDL::mhilb {
	my $class = shift;
	my $pdl1 = scalar(@_)? $class->new_from_specification(@_) : $class->copy;
	my $pdl2 = scalar(@_)? $class->new_from_specification(@_) : $class->copy;
	1 /  ($pdl1->inplace->axisvals +  $pdl2->inplace->axisvals(1) + 1);
}

=head2 mtri

=for ref

Return zeroed matrix with upper or lower triangular part from another matrix.
Return trapezoid matrix if entry matrix is not square.
Supports threading.
Uses L<tricpy|PDL::LinearAlgebra::Real/tricpy> or L<tricpy|PDL::LinearAlgebra::Complex/ctricpy>.

=for usage

 PDL = mtri(PDL, SCALAR)
 SCALAR : UPPER = 0 | LOWER = 1, default = 0

=for example

 my $a = random(10,10);
 my $b = mtri($a, 0);

=cut

sub mtri{
	my $m = shift;
	$m->mtri(@_);
}

sub PDL::mtri {
	&PDL::LinearAlgebra::_2d_array;
	my ($m, $upper) = @_;
	$m->tricpy($upper, my $b = $m->_similar_null);
	$b;
}

=head2 mvander

Return (primal) Vandermonde matrix from vector.

=for ref

mvander(M,P) is a rectangular version of mvander(P) with M Columns.

=cut

sub mvander($;$) {
	my $exp =  @_ == 2 ? sequence(shift) : sequence($_[0]->dim(-1));
	$_[0]->dummy(-2)**$exp;
}

=head2 mpart

=for ref

Return antisymmetric and symmetric part of a real or complex square matrix.

=for usage

 ( PDL(antisymmetric), PDL(symmetric) )  = mpart(PDL, SCALAR(conj))
 conj : if true Return AntiHermitian, Hermitian part.

=for example

 my $a = random(10,10);
 my ( $antisymmetric, $symmetric )  = mpart($a);

=cut

*mpart = \&PDL::mpart;

sub PDL::mpart {
	&PDL::LinearAlgebra::_square;
	my ($m, $conj) = @_;
	# antisymmetric and symmetric part
        return (0.5* ($m - $m->t($conj))),(0.5* ($m + $m->t($conj)));
}

=head2 mhankel

=for ref

Return Hankel matrix also known as persymmetric matrix.
Handles complex data.

=for usage

 mhankel(c,r), where c and r are vectors, returns matrix whose first column
 is c and whose last row is r. The last element of c prevails.
 mhankel(c) returns matrix with element below skew diagonal (anti-diagonal) equals
 to zero. If c is a scalar number, make it from sequence beginning at one.

=for ref

The elements are:

	H (i,j) = c (i+j),  i+j+1 <= m;
	H (i,j) = r (i+j-m+1),  otherwise
	where m is the size of the vector.

If c is a scalar number, it's determinant can be computed by:

			floor(n/2)    n
	Det(H(n)) = (-1)      *      n

=cut

*mhankel = \&PDL::mhankel;

sub PDL::mhankel {
	my $di = $_[0]->dims_internal;
	my ($m, $n) = @_;
	$m = xvals($m) + 1 unless ref($m);
	my @dims = $m->dims;
	$n = PDL::zeroes($m) unless defined $n;
	my $index = xvals($dims[$di]);
	$index = $index->dummy(0) + $index;
	if (@dims == 2){
		$m = mstack($m,$n(,1:));
		$n = $m->re->index($index)->r2C;
		$n((1),).= $m((1),)->index($index);
		return $n;
	}
	else{
		$m = augment($m,$n(1:));
		return $m->index($index)->sever;
	}
}

=head2 mtoeplitz

=for ref

Return toeplitz matrix.
Handles complex data.

=for usage

 mtoeplitz(c,r), where c and r are vectors, returns matrix whose first column
 is c and whose last row is r. The last element of c prevails.
 mtoeplitz(c) returns symmetric matrix.

=cut

*mtoeplitz = \&PDL::mtoeplitz;
sub PDL::mtoeplitz {
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my ($m, $n) = @_;
	$n = $m->copy unless defined $n;
	my $mdim= $m->dim(-1);
	my $ndim= $n->dim(-1);
	my $res = $m->_similar($ndim,$mdim);
	$ndim--;
	my $min = $mdim <= $ndim ? $mdim : $ndim;
	for(1..$min) {
		$res->slice("$slice_prefix$_:,(@{[$_-1]})") .= $n->slice("${slice_prefix}1:@{[$ndim-$_+1]}");
	}
	$mdim--;
	$min = $mdim < $ndim ? $mdim : $ndim;
	for(0..$min){
		$res->slice("${slice_prefix}($_),$_:") .= $m->slice("${slice_prefix}:@{[$mdim-$_]}");
	}
	return $res;
}

=head2 mpascal

Return Pascal matrix (from Pascal's triangle) of order N.

=for usage

 mpascal(N,uplo).
 uplo:
 	0 => upper triangular (Cholesky factor),
 	1 => lower triangular (Cholesky factor),
 	2 => symmetric.

=for ref

This matrix is obtained by writing Pascal's triangle (whose elements are binomial
coefficients from index and/or index sum) as a matrix and truncating appropriately.
The symmetric Pascal is positive definite, its inverse has integer entries.

Their determinants are all equal to one and:

	S = L * U
	where S, L, U are symmetric, lower and upper pascal matrix respectively.


=cut

*mpascal = \&PDL::mpascal;
sub PDL::mpascal {
	my ($m, $n) = @_;
	my $mat = eval {
		require PDL::GSLSF::GAMMA;
		if ($n > 1){
			my $mat = xvals($m);
			return (PDL::GSLSF::GAMMA::gsl_sf_choose($mat + $mat->dummy(0),$mat))[0];
		}else{
			my $mat = xvals($m, $m);
			return (PDL::GSLSF::GAMMA::gsl_sf_choose($mat->tritosym,$mat->xchg(0,1)->tritosym))[0]->mtri($n);
		}
	};
	return $mat if !$@;
	warn("mpascal: can't compute binomial coefficients without".
		" PDL::GSLSF::GAMMA\n");
	return;
}

=head2 mcompanion

Return a matrix with characteristic polynomial equal to p if p is monic.
If p is not monic the characteristic polynomial of A is equal to p/c where c is the
coefficient of largest degree in p (here p is in descending order).

=for usage

 mcompanion(PDL(p),SCALAR(charpol)).
 charpol:
 	0 => first row is -P(1:n-1)/P(0),
 	1 => last column is -P(1:n-1)/P(0),

=cut

*mcompanion = \&PDL::mcompanion;
sub PDL::mcompanion{
	my $di = $_[0]->dims_internal;
	my $slice_prefix = ',' x $di;
	my ($m, $char) = @_;
	my( @dims, $dim, $ret);
	$m = $m->{PDL} if (UNIVERSAL::isa($m, 'HASH') && exists $m->{PDL});
	@dims = $m->dims;
	$dim = $dims[-1] - 1;
	my $id = identity($dim-1); $id = $id->r2C if $m->_is_complex;
	if($char){
		$ret = (-$m->slice("${slice_prefix}1:$dim")->dummy($di+1)/$m->slice("${slice_prefix}0"))->_call_method('mstack', $id->mstack(zeroes($m->dims_internal_values,$dim-1)->dummy($di)));
	}
	else{
		$ret = $m->_similar($dim-1)->dummy($di+1)->_call_method('mstack', $id)->mstack(-$m->slice("${slice_prefix}$dim:1")->dummy($di)/$m->slice("${slice_prefix}(0)"));
	}
	$ret->sever;
}


=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2007.

This library is free software; you can redistribute it and/or modify
it under the terms of the artistic license as specified in the Artistic
file.

=cut

# Exit with OK status

1;
