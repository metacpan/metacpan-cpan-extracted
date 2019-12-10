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

=encoding Latin-1

=head1 NAME

PDL::LinearAlgebra::Special - Special matrices for PDL

=head1 SYNOPSIS

 use PDL::LinearAlgebra::Mtype;

 $a = mhilb(5,5);

=head1 DESCRIPTION

This module provides some constructors of well known matrices.

=head1 FUNCTIONS

=head2 mhilb

=for ref

Contruct Hilbert matrix from specifications list or template piddle

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
	my ($m, $upper) = @_;
	my(@dims) = $m->dims;

	barf("mtri requires a 2-D matrix")
		unless( @dims >= 2);

	my $b = PDL::zeroes $m;
	$m->tricpy($upper, $b);
	$b;
}

sub PDL::Complex::mtri {
	my ($m, $upper) = @_;
	my(@dims) = $m->dims;

	barf("mtri requires a 2-D matrix")
		unless( @dims >= 3);

	my $b = PDL::zeroes $m;
	$m->ctricpy($upper, $b);
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
	my ($m, $conj) = @_;
	my @dims = $m->dims;

	barf("mpart requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	# antisymmetric and symmetric part
        return (0.5* ($m - $m->t($conj))),(0.5* ($m + $m->t($conj)));

}

=head2 mhankel

=for ref

Return Hankel matrix also known as persymmetric matrix.
For complex, needs object of type PDL::Complex.

=for usage

 mhankel(c,r), where c and r are vectors, returns matrix whose first column 
 is c and whose last row is r. The last element of c prevails.
 mhankel(c) returns matrix whith element below skew diagonal (anti-diagonal) equals
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
	my ($m, $n) = @_;
	$m = xvals($m) + 1 unless ref($m);
	my @dims = $m->dims;

	$n = PDL::zeroes($m) unless defined $n;
	my $index = xvals($dims[-1]);
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
For complex need object of type PDL::Complex.

=for usage

 mtoeplitz(c,r), where c and r are vectors, returns matrix whose first column 
 is c and whose last row is r. The last element of c prevails.
 mtoeplitz(c) returns symmetric matrix.

=cut

*mtoeplitz = \&PDL::mtoeplitz;
sub PDL::mtoeplitz {
	my ($m, $n) = @_;
	my($res, $min);
	
	$n = $m->copy unless defined $n;
	my $mdim= $m->dim(-1);
	my $ndim= $n->dim(-1);
	$res = PDL::new_from_specification('PDL',$m->type,$ndim,$mdim);

	$ndim--;
	$min = $mdim <= $ndim ? $mdim : $ndim;
	if(UNIVERSAL::isa($m,'PDL::Complex')){
		$res= $res->r2C;
		for(1..$min){
			$res(,$_:,($_-1)) .= $n(,1:$ndim-$_+1);
		}
		$mdim--;
		$min = $mdim < $ndim ? $mdim : $ndim;
		for(0..$min){
			$res(,($_),$_:) .= $m(,:$mdim-$_);
		}	
	}
	else{
		for(1..$min){
			$res($_:,($_-1)) .= $n(1:$ndim-$_+1);
		}
		$mdim--;
		$min = $mdim < $ndim ? $mdim : $ndim;
		for(0..$min){
			$res(($_),$_:) .= $m(:$mdim-$_);
		}
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
The symmetric Pascal is positive definite, it's inverse has integer entries.

Their determinants are all equal to one and:

	S = L * U
	where S, L, U are symmetric, lower and upper pascal matrix respectively.


=cut

*mpascal = \&PDL::mpascal;
sub PDL::mpascal {
	my ($m, $n) = @_;
	my ($mat, $error, $warning);
	
	$mat = eval{
		require PDL::Stat::Distributions;
		$mat = xvals($m);
		if ($n > 1){
			return (PDL::Stat::Distributions::choose($mat + $mat->dummy(0),$mat))[0];		
		}
		else{
			$mat = PDL::Stat::Distributions::choose($mat,$mat->dummy(0));
			return $n ? $mat->xchg(0,1)->mtri(1) : $mat->mtri;
		}
	};
	if ($@){
		$mat = eval{
			require PDL::GSLSF::GAMMA;
			if ($n > 1){
				$mat = xvals($m);
				return (PDL::GSLSF::GAMMA::gsl_sf_choose($mat + $mat->dummy(0),$mat))[0];					
			}else{
				$mat = xvals($m, $m);
				return (PDL::GSLSF::GAMMA::gsl_sf_choose($mat->tritosym,$mat->xchg(0,1)->tritosym))[0]->mtri($n);
			}
		};
		if ($@){
			warn("mpascal: can't compute binomial coefficients with neither".
				" PDL::Stat::Distributions nor PDL::GSLSF::GAMMA\n");
			return;
		}
	}
	$mat;
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
	my ($m, $char) = @_;
	my( @dims, $dim, $ret);
	$m = $m->{PDL} if (UNIVERSAL::isa($m, 'HASH') && exists $m->{PDL});
	@dims = $m->dims;
	$dim = $dims[-1] - 1;
	if (@dims == 2){
		if($char){
			$ret = (-$m->slice(",1:$dim")->dummy(2)/$m->slice(",0"))->cmstack(identity($dim-1)->r2C->mstack(zeroes(2,$dim-1)->dummy(1)));
		}
		else{
			#zeroes($dim-1)->dummy(0)->augment(identity($dim-1))->mstack(-$m->slice("$dim:1")->dummy(-1)/$m->slice("(0)"));
			$ret = zeroes($dim-1)->r2C->dummy(2)->cmstack(identity($dim-1)->r2C)->mstack(-$m->slice(",$dim:1")->dummy(1)/$m->slice(",(0)"));
		}	
	}
	else{
		if($char){
			$ret = (-$m->slice("1:$dim")->dummy(-1)/$m->slice("0"))->mstack(identity($dim-1)->augment(zeroes($dim-1)->dummy(0)));
		}
		else{
			#zeroes($dim-1)->dummy(0)->augment(identity($dim-1))->mstack(-$m->slice("$dim:1")->dummy(-1)/$m->slice("(0)"));
			$ret = zeroes($dim-1)->dummy(-1)->mstack(identity($dim-1))->augment(-$m->slice("$dim:1")->dummy(0)/$m->slice("(0)"));
		}
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

