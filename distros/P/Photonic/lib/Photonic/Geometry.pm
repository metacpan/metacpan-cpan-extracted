package Photonic::Geometry;
$Photonic::Geometry::VERSION = '0.010';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::MatrixOps;
use PDL::Complex;
use Moose;
use Photonic::Types;
use Carp;
use constant PI=>4*atan2(1,1);

has 'B' =>(is=>'ro', isa=>'PDL', required=>1,
	   documentation=>'charateristic function');
          #should check 0's and 1's?
has 'L' =>(is=>'ro', isa => 'PDL', lazy=>1, builder=>'_build_L', 
	   documentation=>'array of unit cell size');
has 'units'=>(is=>'ro', isa=>'ArrayRef[PDL]', lazy=>1,
     trigger=>\&_set_units, builder=>'_build_units',
     documentation=>'Basis of unit vectors');
has 'dims' =>(is=>'ro', isa=>'Photonic::Types::ArrayOfOddInts',
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
	   documentation=>'array of reciprocal vectors x_or_y, nx, ny');
has 'GNorm' =>(is=>'ro', isa=>'PDL', init_arg=>undef, lazy=>1,
     builder=>'_build_GNorm', 
     documentation=>'array of unit norm reciprocal vectors x_or_y, nx, ny');
has 'f'=>(is=>'ro', init_arg=>undef, lazy=>1, builder=>'_build_f',
     documentation=>'filling fraction of B region');
has 'unitPairs'=>(is=>'ro', isa=>'ArrayRef[PDL]', init_arg=>undef, lazy=>1,
     builder=>'_build_unitPairs', 
     documentation=>'Normalized sum of pairs of basis vectors');
has 'CunitPairs'=>(is=>'ro', isa=>'ArrayRef[PDL]', init_arg=>undef, lazy=>1,
     builder=>'_build_CunitPairs',
     documentation=>'Normalized complex sum of pairs of basis vectors');
has 'CCunitPairs'=>(is=>'ro', isa=>'ArrayRef[PDL]', init_arg=>undef, lazy=>1,
     builder=>'_build_CCunitPairs',
     documentation=>'Normalized complex-conjugate sum of pairs
     of basis vectors');
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

sub _set_units {
    #check the dimensions and number of units
    my ($self, $new, $old)=@_;
    croak "Wrong number of vectors" if 0+@$new != $self->ndims;
    foreach(@$new){
	croak "wrong dimension of unit vector $_" if [$_->dims]->[0] !=
	    $self->ndims;
    }
    die "writing units is not implemented yet, sorry";
}

sub _build_units {
    my $self=shift;
    my @units; # unit vectors
    my $nd=$self->B->ndims;
    foreach(0..$nd-1){ #build unit vectors
	my $e=PDL->zeroes($nd);
	$e->(($_)).=1;
	push @units, $e;
    }
    return [@units];
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
    my $scale=$self->scale;
    return $self->scale*$self->B->ndcoords;
}

sub _build_G {
    my $self=shift;
    my @N=map {($_-1)/2} @{$self->dims}; #N in 2N+1
    my $G=($self->B->ndcoords)-(PDL->pdl(@N)); #vector from center.
    foreach(1..$G->ndims-1){
	$G=$G->mv($_,0)->rotate(-$N[$_-1])->mv(0,$_); #move origin to 0,0
    }
    return 2*PI/$self->L*$G; #reciprocal vectors.
}

sub _build_GNorm { #origin set to zero here.
    my $self=shift;
    croak "Can't normalize reciprocal lattice unless Direction0 is set" 
	unless $self->has_Direction0;
    return $self->G->norm;
}

sub _build_f { #calculate filling fraction
    my $self=shift;
    return $self->B->sum/$self->B->nelem;
}

sub _build_unitPairs {
    my $self=shift;
    my $nd=$self->B->ndims;
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

sub _build_CunitPairs {
    my $self=shift;
    my $nd=$self->B->ndims;
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


sub _build_CCunitPairs {
    my $self=shift;
    my $nd=$self->B->ndims;
    my $units=$self->units;
    my @ccpairs;
    for my $i(0..$nd-1){ #build pairs of vectors
	for my $j($i+1..$nd-1){
	    my $vcc=($units->[$i]-i*$units->[$j]);
	    my $vccn=sqrt(($units->[$i]-i*$units->[$j])->Cabs2->sumover);
	    my $vm=$vcc*(1/$vccn);
	    push @ccpairs, $vm;
	}
    }    
    return [@ccpairs];
}

sub _build_unitDyads {
    my $self=shift;
    my $nd=$self->B->ndims; #Number of dimensions
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
    my $arg=":". (",(0)" x $self->B->ndims); #:,(0),... dimension of space times
    $value=$value->norm; #normalize
    $self->GNorm->slice($arg).=$value; 
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


__PACKAGE__->meta->make_immutable; #faster execution

1;


=head1 NAME

Photonic::Geometry

=head1 VERSION

version 0.010

=head1 SYNOPSIS

     use Photonic::Geometry;
     $g=Photonic::Geometry->new(B=>$pdl);
     $B=$g->B;
     $G=$g->G;

=head1 DESCRIPTION

Create a geometry object to be used in a Photonic
calculation. 

You might want to use the related package
Photonic::Geometry::FromImage2D

=head1 METHODS

=over 4

=item * new(B=>$pdl[, L=>$L][, units=>$units])

Creates a new Ph::G object

$pdl is a boolean array with 1's and 0's representing the characteriztic
function within the unit cell. Its dimensions must be odd. Its number
of dimensions is the dimension of space

$L is the size of the unit cell along the cartesian axes. By
default, it is the number of pixels.

$units is an arrayref of pdl's, one for each basis vector of the
lattice. It defaults to cartesian unit vectors. B<Note:> Non-default
$units are not yet implemented.

=item * Vec2LC_G($v_G)

Returns the longitudinal component of a 'complex' vector field $v_G in
reciprocal space 

=item * LC2Vec_G($s_G)

longitudinal vector field from its longitudinal components in
reciprocal space. Scalar field to vector field.

=back

=head1 ACCESORS (read only)

=over 4

=item * B 

The characteristic function as PDL

=item * L 

Unit cell sizes as a B->ndims pdl.

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

=head1 ACCESORS (read write)

=over 4

=item Direction0

Direction of the zero length wavevector

=back

=head1 PREDICATES

=over 4

=item has_Direction0

Test if Direction0 has been set.

=back

=for Pod::Coverage

=head2    PI


=cut
