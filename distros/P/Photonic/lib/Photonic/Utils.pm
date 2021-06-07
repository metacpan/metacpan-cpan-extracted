package Photonic::Utils;
$Photonic::Utils::VERSION = '0.016';

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


# Collection of subroutines. Thus, no Moose
require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw(vectors2Dlist tile RtoG GtoR
    HProd MHProd EProd VSProd SProd
    linearCombineIt lentzCF any_complex tensor
    make_haydock make_greenp
    wave_operator apply_longitudinal_projection
    cgtsv lu_decomp lu_solve
);
use PDL::LiteF;
use PDL::FFTW3;
use PDL::Complex;
require PDL::MatrixOps;
use Photonic::Iterator qw(nextval);
use Carp;
use Storable qw(dclone);
require PDL::LinearAlgebra::Real;
require PDL::LinearAlgebra::Complex;
use warnings;
use strict;

sub linearCombineIt { #complex linear combination of states from iterator
    my $coefficients=shift; #arrayref of complex coefficients
    my $stateit=shift; #iterator of complex states
    my $numCoeff=$coefficients->dim(-1);
    my $result=r2C(0);
    foreach(0..$numCoeff-1){
	my $s=nextval($stateit);
	croak "More coefficients than states in basis" unless defined $s;
	$result = $result + $coefficients->slice(":,$_")*$s;
    }
    return $result;
}

sub any_complex {
    grep ref $_ && (ref $_ eq 'PDL::Complex' or !$_->type->real), @_;
}

sub wave_operator {
    my ($green, $nd) = @_;
    lu_solve([lu_decomp($green)], r2C(PDL::MatrixOps::identity($nd)));
}

sub tensor {
    my ($data, $decomp, $nd, $dims, $after_cb) = @_;
    my $backsub = lu_solve($decomp, $data);
    $backsub = $after_cb->($backsub) if $after_cb;
    my $tensor = PDL->zeroes(($nd) x $dims)->r2C;
    my $n = 0;
    my $slice_prefix = ':,' x ($dims-1);
    for my $i(0..$nd-1){
        for my $j($i..$nd-1){
            my $bslice = $backsub->slice(":,($n)");
            $tensor->slice("$slice_prefix($i),($j)") .= $bslice;
            $tensor->slice("$slice_prefix($j),($i)") .= $bslice;
            ++$n;
        }
    }
    $tensor;
}

my @HAYDOCK_PARAMS = qw(
  nh keepStates smallH reorthogonalize use_mask mask
);
sub make_haydock {
  my ($self, $class, $add_geom, @extra_attributes) = @_;
  # This must change if G is not symmetric
  [ map $class->new(
      _haydock_extra($self, $_, $add_geom),
      map +($_ => $self->$_), @HAYDOCK_PARAMS, @extra_attributes
    ), @{$self->geometry->unitPairs}
  ];
}

sub _haydock_extra {
  my ($self, $u, $add_geom) = @_;
  my $obj = dclone($add_geom ? $self->geometry : $self->metric);
  $obj->Direction0($u) if $add_geom; #add G0 direction
  $add_geom ? (geometry=>$obj) : (metric=>$obj, polarization=>$u->r2C);
}

my @GREENP_PARAMS = qw(nh smallE);
sub make_greenp {
  my ($self, $class) = @_;
  [ map $class->new(
      haydock=>$_,
      map +($_ => $self->$_), @GREENP_PARAMS), @{$self->haydock}
  ];
}

sub HProd { #Hermitean product between two fields. skip first 'skip' dims
    my $first=shift;
    my $second=shift;
    my $skip=shift//0;
    my $ndims=$first->ndims;
    confess "Dimensions should be equal, instead: first=", $first->info, " second=", $second->info
	unless $ndims == $second->ndims;
    my $prod=$first->Cconj*$second;
    # clump all except skip dimensions, protecto RorI index and sum.
    my $result=$prod->reorder($skip+1..$ndims-1,1..$skip,0)->clump(-1-$skip-1)
	->mv(-1,0)->sumover;
    return $result;
}

sub MHProd { #Hermitean product between two fields with metric. skip
	     #first 'skip' dims
    my $first=shift;
    my $second=shift;
    my $metric=shift;
    # pass $metric->value  xyz xyz nx ny nz
    my $skip=shift//0;
    my $ndims=$first->ndims;
    die "Dimensions should be equal" unless $ndims == $second->ndims;
    carp "We don't trust the skip argument in MHProd yet" if $skip;
    # I'm not sure about the skiped dimensions in the next line. Is it right?
    my $mprod=($metric*$second->dummy(2))->sumover;
    die "Dimensions should be equal" unless $ndims == $mprod->ndims;
    my $prod=$first->Cconj*$mprod;
    my $result=$prod->reorder($skip+1..$ndims-1,1..$skip,0)->clump(-1-$skip-1)
	->mv(-1,0)->sumover;
    return $result;
}

sub EProd { #Euclidean product between two fields in reciprocal
	    #space. Have to map G->-G. skip
	    #first 'skip' dims
    my $first=shift;
    my $second=shift;
    my $skip=shift//0;
    my $ndims=$first->ndims;
    die "Dimensions should be equal" unless $ndims == $second->ndims;
    #First reverse all reciprocal dimensions
    my $sl=join ',',
	":", #slice to skip complex dimension
	((":") x $skip), #skip dimensions
	(("-1:0") x ($ndims-1-$skip)); #and reverse the rest
    my $first_mG=$first->slice($sl);
    #Then rotate psi_{G=0} to opposite corner with coords. (0,0,...)
    foreach($skip+1..$ndims-1){
	$first_mG=$first_mG->mv($_,0)->rotate(1)->mv(0,$_);
    }
    my $prod=$first_mG*$second;
    # clump all except skip dimensions, protecto RorI index and sum.
    my $result=$prod #ri:s1:s2:nx:ny
	->reorder($skip+1..$ndims-1,1..$skip,0) #nx:ny:s1:s2:ri
	->clump(-1-$skip-1) #nx*ny:s1:s2:ri
	->mv(-1,0) #ri:nx*ny,s1,s2
	->sumover; #ri:s1:s2
    return $result;
}

sub SProd { #Spinor product between two fields in reciprocal
	    #space. Have to map G->-G. skip first 'skip' dims (after
	    #complex and spinor dimension)
    my $first=shift;
    my $second=shift;
    my $skip=shift//0;
    my $ndims=$first->ndims;
    die "Dimensions should be equal" unless $ndims == $second->ndims;
    #dimensions are like rori, pmk, s1,s2, nx,ny
    #First reverse all reciprocal dimensions
    my $sl=join ',',
	":", #slice to keep complex dimension
	"-1:0", #interchange spinor components +- to -+
	((":") x $skip), #keep skip dimensions
	(("-1:0") x ($ndims-1-1-$skip)); #and reverse G indices
    my $first_mG=$first->slice($sl); #rori,pmk,s1,s2,nx,ny
    #Then rotate psi_{G=0} to opposite corner with coords. (0,0,...)
    foreach($skip+2..$ndims-1){
	$first_mG=$first_mG->mv($_,0)->rotate(1)->mv(0,$_);
    }
    my $prod=$first_mG*$second; #rori,pmk,s1,s2,nx,ny
    # clump all except skip dimensions, protect RorI index and sum.
    my $result=$prod #rori,pmk, s1,s2,nx,ny
	->reorder($skip+2..$ndims-1,1..$skip+1,0) #nx,ny,pmk,s1,s2,rori
	->clump(-1-$skip-1)  #nx*ny*pmk, s1, s2, rori
	->mv(-1,0) #rori,nx*ny*pmk, s1,s2
	->sumover; #rori, s1, s2
    return $result;
}

sub VSProd { #Vector-Spinor product between two vector fields in reciprocal
             #space. Indices are ri:xy:pm:nx:ny...
    my $first=shift;
    my $second=shift;
    my $ndims=$first->ndims;
    die "Dimensions should be equal" unless $ndims == $second->ndims;
    #dimensions are like ri:xy:pm:nx:ny
    #First reverse all reciprocal dimensions
    my $sl=join ',',
	(":",":"), #slice to keep complex and vector dimension
	"-1:0", #interchange spinor components +- to -+
	(("-1:0") x ($ndims-3)); #and reverse G indices
    my $first_mG=$first->slice($sl); #ri:xy:pm:nx:ny
    #Then rotate psi_{G=0} to opposite corner with coords. (0,0,...)
    foreach(3..$ndims-1){ # G indices start after ri:xy:pm
	$first_mG=$first_mG->mv($_,0)->rotate(1)->mv(0,$_);
    }
    my $prod=$first_mG*$second; #ri:xy:pm:nx:ny
    # clump all except ri:xy.
    my $result=$prod #ri:xy:pm::nx:ny
	->reorder(3..$ndims-1,1,2,0) #nx:ny:xy:pm:ri
	->clump(-2)  #nx*ny*xy*pm:ri
	->mv(-1,0) #ri:nx*ny*xy*pm
	->sumover; #ri
    return $result;
}

sub RtoG { #transform a 'complex' scalar, vector or tensorial field
	   #from real to reciprocal space
    my $field=shift; #field to fourier transform
    my $ndims=shift; #number of dimensions to transform
    my $skip=shift; #dimensions to skip
    my $moved=$field;
    $moved=$moved->mv(1,-1) foreach(0..$skip-1);
    my $transformed=fftn($moved, $ndims);
    my $result=$transformed;
    $result=$result->mv(-1,1) foreach(0..$skip-1);
    return $result;
}

sub GtoR { #transform a 'complex' scalar, vector or tensorial field from
	   #reciprocal to real space
    my $field=shift; #field to fourier transform
    my $ndims=shift; #number of dimensions to transform
    my $skip=shift; #dimensions to skip
    my $moved=$field;
    $moved=$moved->mv(1,-1) foreach(0..$skip-1);
    my $transformed=ifftn($moved, $ndims);
    my $result=$transformed;
    $result=$result->mv(-1,1) foreach(0..$skip-1);
    return $result;
}

sub lentzCF {
    # continued fraction using lentz method Numerical Recipes
    # p. 171. Arguments are as, bs, maximum number of iterations and
    # smallness parameter
    # a0+b1/a1+b2+...
    my $as=shift;
    my $bs=shift;
    my $max=shift;
    my $small=shift;
    my $tiny=r2C(1.e-30);
    my $converged=0;
    my $fn=$as->slice(":,0");
    $fn=$tiny if all($fn==0);
    my $n=1;
    my ($fnm1, $Cnm1, $Dnm1)=($fn, $fn, r2C(0)); #previous coeffs.
    my ($Cn, $Dn); #current coeffs.
    my $Deltan;
    while($n<$max){
	$Dn=$as->slice(":,$n")+$bs->slice(":,$n")*$Dnm1;
	$Dn=$tiny if all($Dn==0);
	$Cn=$as->slice(":,$n")+$bs->slice(":,$n")/$Cnm1;
	$Cn=$tiny if all($Cn==0);
	$Dn=1/$Dn;
	$Deltan=$Cn*$Dn;
	$fn=$fnm1*$Deltan;
	last if $converged=$Deltan->approx(1, $small)->all;
	$fnm1=$fn;
	$Dnm1=$Dn;
	$Cnm1=$Cn;
	$n++;
    }
    $fn = $fn->slice(":,(0)");
    return wantarray? ($fn, $n): $fn;
}

sub tile { # repeat field Nx X Ny X... times
    my $f=shift;
    my @n=@_; #number of repetitions along dimension
    my $sl = join ',', map ":,*$_", @n; # insert right-size dummy after each real
    my $r = $f->slice($sl); #result
    $r = $r->clump($_, $_+1) for 0..$#n;
    $r;
}

sub vectors2Dlist { #2D vector fields ready for gnuploting
    my $f=shift; #vector field
    my $s=shift; #scale
    my $d=shift; #decimation
    my $f1=$s*$f->slice(":,0:-1:$d, 0:-1:$d"); #decimate two dimensions
    my $coords=$d*PDL::ndcoords(@{[$f1->dims]}[1,2]);
    ( #basex, basey, vectorx vectory
	($coords-.5*$f1)->mv(0,-1)->clump(-2)->dog,
	$f1->mv(0,-1)->clump(-2)->dog);
}

sub cgtsv {
    confess "Wrong number of arguments" unless scalar(@_)==4;
    my ($c, $d, $e, $b) = @_;
    my $i = PDL->null;
    for (grep $_->is_inplace, $c, $d, $e, $b) {
        $_ = $_->copy;
        $_->set_inplace(0);
    }
    PDL::LinearAlgebra::Complex::cgtsv($c, $d, $e, $b, $i);
    confess "Error solving tridiag system" unless $i == 0;
    $b->isa("PDL::Complex") ? $b->complex : $b;
}

sub lu_decomp {
    confess "Wrong number of arguments" unless scalar(@_)==1;
    my ($data) = @_;
    my ($lu, $perm, $info) = ($data->copy, null, null);
    if (any_complex($data)) {
	PDL::LinearAlgebra::Complex::cgetrf($lu, $perm, $info);
    } else {
	PDL::LinearAlgebra::Real::getrf($lu, $perm, $info); # uncoverable statement
    }
    confess 'Decomposition failed' unless all($info == 0); # can be vector
    ($lu, $perm);
}

sub lu_solve {
    confess "Wrong number of arguments" unless scalar(@_)==2;
    my ($decomp, $B) = @_;
    my ($lu, $perm, $info, $x) = (@$decomp, null, $B->copy);
    if (any_complex($x)) {
	PDL::LinearAlgebra::Complex::cgetrs($lu, 1, $x, $perm, $info);
    } else {
	PDL::LinearAlgebra::Real::getrs($lu, 1, $x, $perm, $info); # uncoverable statement
    }
    confess 'Solving failed' unless all($info == 0); # can be vector
    $x;
}

sub apply_longitudinal_projection {
    my ($psi_G, $gnorm, $ndims, $coeff) = @_;
    #state is ri:nx:ny... gnorm=i:nx:ny...
    #Multiply by vector ^G.
    #Have to get cartesian out of the way, thread over it and iterate
    #over the rest
    my $Gpsi_G=$psi_G->dummy(1)*$gnorm; #^G |psi>
    #the result is complex ri:i=cartesian:nx:ny...
    #Take inverse Fourier transform over all space dimensions,
    #move cartesian indices, thread, move back
    my $Gpsi_R=ifftn($Gpsi_G->mv(1,-1), $ndims)->mv(-1,1);
    # $Gpsi_R is ri:i:nx:ny:...
    # Multiply by the coefficient in Real Space.
    my $eGpsi_R=$coeff->dummy(1)*$Gpsi_R;
    # $eGpsi_R is ri:i:nx:ny...
    #Transform to reciprocal space
    #move cartesian indices, thread, move back
    my $eGpsi_G=fftn($eGpsi_R->mv(1,-1), $ndims)->mv(-1,1);
    # $eGpsi_G is ri:i:nx:ny:...
    #Scalar product with Gnorm
    ($eGpsi_G*$gnorm) #^Ge^G|psi>
	# ri:i:nx:ny:...
	->sumover; #^G.epsilon^G|psi>
    #Result is ^G.epsilon^G|psi>, ri:nx:ny...
}

1;

__END__


=head1 NAME

Photonic::Utils

=head1 VERSION

version 0.016

=head1 SYNOPSIS

    use Photonic::Utils qw(cmatmult);
    $c=cmatmult($a, $b);

=head1 DESCRIPTION

Utility functions that may be useful.

=head1 Exportable Functions

=over 4

=item * $r=linearCombineIt($c, $it)

Complex linear combination of states from iterator. $c is a 'complex'
ndarray and $it is an iterator for the corresponding states.

=item * $p=HProd($a, $b, $skip)

Hermitean product <a|b> of two 2x.... 'complex' multidimensional
pdls $a and $b. If $skip is present, preserve the first 1+$skip
_dimensions (the first dimension is RorI) before adding up.

=item * $p=MHProd($a, $b, $m, $skip)

Hermitean product <a|m|b> of two 2x.... 'complex' multidimensional
pdls $a and $b representing vector fields using metric $m. If $skip is
present, preserve the first 1+$skip dimensions (the first dimension
is RorI) before adding up. (Might not be functional yet, or might be wrong)

=item * $p=EProd($a, $b, $skip)

Euclidean product <a|b> of two 2x.... 'complex' multidimensional
pdls $a and $b in reciprocal space. If $skip is present, preserve the
first 1+$skip dimensions (the first dimension is RorI) before adding up.

=item * $p=SProd($a, $b, $skip)

Spinor product <a|b> of two 2x.... 'complex' multidimensional
pdls $a and $b in reciprocal space. If $skip is present, preserve the
first 2+$skip dimensions (the first dimension is RorI and the second
the spinor dimension) before adding up.

=item * $p=VSProd($a, $b)

Vector-Spinor product <a|b> of two 2x...'complex' multidimensional
pdls $a and $b in reciprocal space. For the vector-spinor field
dimensions are like ri:xy:pm:nx:ny.

=item * $psiG = RtoG($psiR, $ndims, $skip)

Transforms a $ndims-dimensional 'complex' scalar, vector or tensor
field $psiR that is a function of position within the unit cell to a
complex field $psiG that is a function of the reciprocal vectors. The
first dimension must be 2, as the values are complex. The next $skip
dimensions are skiped (0 for a scalar, 1 for a vector, 2 for a
2-tensor field). The Fourier transform is performed over the
following $ndims dimensions.

=item * $psiR = GtoR($psiG, $ndims, $skip)

The opposite transformation to RtoG. Transform a 'complex' scalar,
vector or tensorial field from reciprocal to real space.

=item * $c=lentzCF($as, $bs, $max, $small)

Compute a continued fraction a0+b1/a1+b2+... using the Lentz
algorithm. $as and $bs are given in a PDL. $max is maximum number of
iterations. $small is a small convergence criterium.

=item * $b=tile($a, $nx, $ny,...)

Returns $a repeated periodically $nx times along the x direction, $ny
along the y direction, etc. Useful for making plots.

=item * @l=vectors2Dlist($f, $s, $d)

Returns a 2D vector field ready for gnuplotting from a vector field $f
scaling the result by $s and decimating the field by $d. The vectors
are centered on the decimated lattice points.

=item * any_complex

True if any of the args are a complex PDL.

=item * tensor

Given a complex PDL, an LU decomposition array-ref as returned by
L</lu_decomp>, and the size of the tensor, returns the tensor.

=item * wave_operator

Given a Green tensor and number of dimension in the geometry, returns
a wave operator.

=item * make_haydock

=item * make_greenp

Given an object and a classname, construct an array-ref of objects of
that class, with relevant fields copied from the object.

=item * cgtsv

Solves a general complex tridiagonal system of equations.

       $b = cgtsv($c, $d, $e, $b);

where C<$c(2,0..$n-2)> is the subdiagonal, C<$d(2,0..$n-1)> the diagonal and
C<$e(2,0..$n-2)> the supradiagonal of an $nX$n tridiagonal complex
double precision matrix. C<$b(2,0..$n-1)> is the right hand side
vector. C<$b> is replaced by the solution. Dies if gets an error.

=item * lu_decomp

Uses the appropriate LU decomposition function (real vs complex,
detected) for L</lu_solve>. Returns list of LU, permutations. Dies if
decomposition failed.

=item * lu_solve

Uses the appropriate LU solver function (real vs complex,
detected). Given an array-ref with the return values of L</lu_decomp>, and
a transposed C<B> matrix, returns transposed C<x>. Dies if solving failed.

=item * apply_longitudinal_projection

Given a C<psi_G> state, a C<GNorm>, the number of dimensions, and a
real-space coefficient, transforms the C<psi_G> field from reciprocal to
real space, multiplies by the coefficient, transforms back to reciprocal
space.

=back
