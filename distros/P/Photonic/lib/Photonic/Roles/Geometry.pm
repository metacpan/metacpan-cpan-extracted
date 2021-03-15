package Photonic::Roles::Geometry;
$Photonic::Roles::Geometry::VERSION = '0.015';

=encoding UTF-8

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut


use Moose::Role;

use PDL::Lite;
use PDL::NiceSlice;
use PDL::MatrixOps;
use PDL::Complex;
use Photonic::Types;
use Carp;
use constant PI=>4*atan2(1,1);

requires 'B'; #characteristic function

has 'L' =>(is=>'ro', isa => 'PDL', lazy=>1, builder=>'_build_L',
	   documentation=>'array of unit cell size');
has 'units'=>(is=>'ro', isa=>'ArrayRef[PDL]', lazy=>1,
     builder=>'_build_units',
     documentation=>'Basis of unit vectors');
has 'primitive'=>(is=>'ro', isa=>'PDL', required=>1, lazy=>1,
		  builder=>'_build_primitive',
		  documentation=>'Primitive directions');
has 'primitiveNorm'=>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
		  builder=>'_build_primitiveNorm',
		  documentation=>'Normalized primitive vectors');
has 'dualNorm'=>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
		 builder=>'_build_dualNorm',
		 documentation=>'Normalized reciprocal primitive vectors');
has 'dims' =>(is=>'ro', isa=>'ArrayRef[Int]',
           init_arg=>undef, lazy=>1, builder=>'_build_dims',
           documentation=>'list of dimensions of B');
has 'ndims' =>(is=>'ro', isa=>'Int',
           init_arg=>undef, lazy=>1, builder=>'_build_ndims',
           documentation=>'number of dimensions of B');
has 'npoints' =>(is=>'ro', isa=>'Int',
           init_arg=>undef, lazy=>1, builder=>'_build_npoints',
           documentation=>'number of points within B');
has 'scale'=>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
              builder=>'_build_scale',
	      documentation=>'distances between pixels');
has 'r' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
           builder=>'_build_r',
	   documentation=>'array of positions x_or_y, nx, ny');
has 'G' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1, builder=>'_build_G',
	   documentation=>'array of reciprocal vectors xy,nx,ny...');
has 'GNorm' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
     builder=>'_build_GNorm',
     documentation=>'array of unit norm reciprocal vectors xy,nx,ny...');
has 'mGNorm' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
     builder=>'_build_mGNorm',
     documentation=>
	  'array of negated unit norm reciprocal vectors xy,nx,ny...');
has 'pmGNorm' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
     builder=>'_build_pmGNorm',
     documentation=>
       'array of spinors of +- unit norm reciprocal vectors xy,pm,nx,ny');
has 'f'=>(is=>'ro', init_arg=>undef, lazy=>1, builder=>'_build_f',
     documentation=>'filling fraction of B region');
has 'unitPairs'=>(is=>'ro', isa=>'ArrayRef[PDL]', init_arg=>undef, lazy=>1,
     builder=>'_build_unitPairs',
     documentation=>'Normalized sum of pairs of basis vectors');
has 'cUnitPairs'=>(is=>'ro', isa=>'ArrayRef[PDL]', init_arg=>undef, lazy=>1,
     builder=>'_build_cUnitPairs',
     documentation=>'Normalized complex sum of pairs of basis vectors');
has 'unitDyads'=>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
     builder=>'_build_unitDyads',
     documentation=>'Matrix of dyads of unit vector pairs');
has 'unitDyadsLU'=>(is=>'ro', isa=>'ArrayRef', lazy=>1,
     builder=>'_build_unitDyadsLU',
     documentation=>'LU decomposition of unitDyads');
has 'Direction0' =>(is => 'rw', isa => 'PDL', trigger=>\&_G0,
     predicate=>'has_Direction0');

sub _build_L {
    my $self=shift;
    my $L=PDL->pdl($self->dims);
    return $L;
}

sub _build_units {
    my $self=shift;
    my @units; # unit vectors
    my $nd=$self->ndims;
    foreach(0..$nd-1){ #build unit vectors
	my $e=PDL->zeroes($nd);
	$e->(($_)).=1;
	push @units, $e;
    }
    return [@units];
}

sub _build_primitive {
    my $self=shift;
    return PDL->pdl($self->units); #xy:n
}

sub _build_primitiveNorm {
    my $self=shift;
    return $self->primitive->norm;
}

sub _build_dualNorm {
    my $self=shift;
    my $pn=$self->primitiveNorm; #xy:n
    my $dual=$pn->inv->transpose->norm; #xy:n
}

sub _build_dims {
    my $self=shift;
    return [$self->B->dims];
}

sub _build_ndims {
    my $self=shift;
    return $self->B->ndims;
}

sub _build_npoints {
    my $self=shift;
    return $self->B->nelem;
}

sub _build_scale {
    my $self=shift;
    return $self->L/PDL->pdl($self->dims);
}

sub _build_r {
    my $self=shift;
    my $coords=$self->B->ndcoords; #i:nx:ny
    my $pr=$self->scale->(*1)*$self->primitiveNorm; #xy:i
    my $r=(
	$coords->(:,*1) #i:*:nx:ny
	*$pr->transpose #i:xy
	)->sumover; #xy:nx:ny
    return $r;
}

sub _build_G {
    my $self=shift;
    my @N=map {($_-($_%2))/2} @{$self->dims}; #N
    my $coords=($self->B->ndcoords)-(PDL->pdl(@N)); #vector from center.
    my $rec=(2*PI/$self->L)->(*1)*$self->dualNorm;
    my $G=(
	$coords->(:,*1) #i:*:nx:ny
	*$rec->transpose #i:xy
	)->sumover; #xy:nx:ny
    foreach(1..$G->ndims-1){
	$G=$G->mv($_,0)
	    ->rotate(-$N[$_-1])->mv(0,$_); #move origin to 0,0
    }
    return $G;
}


sub _build_GNorm { #origin set to zero here.
    my $self=shift;
    croak "Can't normalize reciprocal lattice unless Direction0 is set"
	unless $self->has_Direction0;
    return $self->G->norm;
}

sub _build_mGNorm { #normalized negated reciprocal lattice. Leave
    #direction 0 invariant. See _G0.
    my $self=shift;
    return -$self->GNorm;
}
sub _build_pmGNorm { #normalized +- reciprocal lattice. Leave
    #direction 0 invariant. See _G0.
    #xy,pm,nx,ny
    my $self=shift;
    return PDL->pdl($self->GNorm, $self->mGNorm)->mv(-1,1);
}

sub _build_f { #calculate filling fraction
    my $self=shift;
    return $self->B->sum/$self->B->nelem;
}

sub _build_unitPairs {
    my $self=shift;
    my $nd=$self->ndims;
    my $units=$self->units;
    my @pairs;
    for my $i(0..$nd-1){ #build pairs of vectors
	for my $j($i..$nd-1){
	    my $v=($units->[$i]+$units->[$j])->norm;
	    push @pairs, $v;
	}
    }
    return [@pairs];
}

sub _build_cUnitPairs {
    my $self=shift;
    my $nd=$self->ndims;
    my $units=$self->units;
    my @cpairs;
    for my $i(0..$nd-1){ #build pairs of vectors
	for my $j($i+1..$nd-1){
	    my $vc=($units->[$i]+i*$units->[$j]);
	    my $vcn=sqrt(($units->[$i]+i*$units->[$j])->Cabs2->sumover);
	    my $vp=$vc*(1/$vcn);
	    push @cpairs, $vp;
	}
    }
    return [@cpairs];
}

sub _build_unitDyads {
    my $self=shift;
    my $nd=$self->ndims; #Number of dimensions
    my $ne=$nd*($nd+1)/2; #number of symetric matrix elements
    my $matrix=PDL->zeroes($ne,$ne);
    my $n=0; #run over vector pairs
    for my $i(0..$nd-1){
	for my $j($i..$nd-1){
	    my $m=0; #run over components of dyads
	    for my $k(0..$nd-1){
		for my $l($k..$nd-1){
		    my $factor=$k==$l?1:2;
		    $matrix->(($m),($n)) .= #pdl order!
			$factor*$self->unitPairs->[$n]->(($k)) *
			$self->unitPairs->[$n]->(($l));
		    ++$m;
		}
	    }
	    ++$n;
	}
    }
    return $matrix;
}

sub _build_unitDyadsLU {
    my $self=shift;
    my ($lu, $perm, $parity) = lu_decomp($self->unitDyads);
    die 'Unit Dyad not invertible' unless defined $lu;
    return [($lu, $perm, $parity)];
}

sub _G0 {
    my $self=shift;
    my $value=shift;
    croak "Direction0 must be ".$self->ndims."-dimensional vector" unless
	[$value->dims]->[0]==$self->ndims and $value->ndims==1;
    croak "Direction must be non-null" unless $value->inner($value)>0;
    my $arg=":". (",(0)" x $self->ndims); #:,(0),... dimension of space times
    $value=$value->norm; #normalize
    #Set element 0,0 for normalized arrays.
    $self->GNorm->slice($arg).=$value; #Normalized 0.
    $self->mGNorm->slice($arg).=$value; #Don't change sign for mGNorm!
    $self->pmGNorm->mv(1,-1)->slice($arg).=$value;
}

sub Vec2LC_G { #longitudinal component of 'complex' vector field in
               #reciprocal space
    my $self=shift;
    my $field=shift; # vector field to project
    croak "Can't project unless Direction0 is set" unless
	$self->has_Direction0;
    my $iscomplex=ref $field eq 'PDL::Complex';
    $field=$field->complex unless $iscomplex;
    my $gnorm=$self->GNorm;
    my $result=Cscale($field, $gnorm)->sumover;
    $result=$result->real unless $iscomplex;
    return $result;
}

sub LC2Vec_G { #longitudinal vector field from its longitudinal
	       #components in reciprocal space
    my $self=shift;
    my $field=shift; # scalar field of longitudinal components
    croak "Can't project unless Direction0 is set" unless
	$self->has_Direction0;
    my $iscomplex=ref $field eq 'PDL::Complex';
    $field=$field->complex unless $iscomplex;
    my $gnorm=$self->GNorm;
    #$gnorm is XorY nx, ny...
    #$field is RoI nx ny nz
    #$result RoI XoY nx ny nz
    my $result=$field->(,*1)*$gnorm;
    $result=$result->real unless $iscomplex;
    return $result;
}

no Moose::Role;

1;


=head1 NAME

Photonic::Roles::Geometry

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Photonic::Geometry::FromB;
    $g=Photonic::Geometry->new(B=>$pdl);
    $B=$g->B;
    $G=$g->G;

=over 4

=item (for developers)

    package Photonic::Geometry::FromB;
    $Photonic::Geometry::Geometry::VERSION = '0.015';
    use namespace::autoclean;
    use Moose;
    has 'B' =>(is=>'ro', isa=>'PDL', required=>1,
	       documentation=>'charateristic function');
    with 'Photonic::Roles::Geometry';

=back

=head1 DESCRIPTION

Roles consumed by geometry objects to be used in a Photonic
calculation. See also the specific implementations under
L<Photonic::Geometry>.

=head1 ACCESORS (defined by the implementation)

=over 4

=item * B

The characteristic function as PDL

=back

=head1 ACCESORS (read write)

=over 4

=item * Direction0

Direction of the zero length wavevector

=back

=head1 ACCESORS (read only)

=over 4

=item * L

Unit cell sizes as a ndims pdl.

=item * units

Basis C<e>_i of basis vectors for the lattice

=item * dims

The dimensions [$X, $Y...] of the PDL B

=item * ndims

The number of dimensions of the PDL B, i.e., the dimensionality of
space.

=item * npoints

Number of points within unit cell.

=item * scale

The distance between neighbor pixels along the axes.

=item * r

The position coordinates. In 2D, a 2,$X,$Y pdl. In 3D, a 3,$X,$Y,$Z pdl.

=item * G

The reciprocal lattice. In 2D, a 2, $X, $Y pdl. B<G>.B<R>=multiple of 2\pi.

=item * GNorm

The reciprocal lattice, normalized to 1. In 2D, a 2, $X, $Y pdl.

=item * f

Filling fraction of B region

=item * unitPairs

Normalized sum of pairs of unit vectors B<u>_{(ij)}=normalized
B<e>_ i+B<e>_j.

=item * unitDyads

Matrix of dyads of unit vector pairs
B<d>^{ij}_{kl}=B<u>^{i}_{kl}B<u>^{j}_{kl} as 2d matrix, adjusted for symmetry

=item * unitDyadsLU

LU decomposition of unitDyads. Used to obtain cartesian components of
dielectric tensor from longitudinal dielectric functions along the
directions given by unitPairs

=back

=head1 METHODS

=over 4

=item * Vec2LC_G($v_G)

Returns the longitudinal component of a 'complex' vector field $v_G in
reciprocal space.

=item * LC2Vec_G($s_G)

Longitudinal vector field from its longitudinal components in
reciprocal space. Scalar field to vector field.

=back

=head1 PREDICATES

=over 4

=item has_Direction0

Test if Direction0 has been set.

=back

=begin Pod::Coverage

=head2 PI

=end  Pod::Coverage

=cut
