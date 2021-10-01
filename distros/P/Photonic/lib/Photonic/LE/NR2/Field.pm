package Photonic::LE::NR2::Field;
$Photonic::LE::NR2::Field::VERSION = '0.021';


=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::Field

=head1 VERSION

version 0.021

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

=head1 SYNOPSIS

   use Photonic::LE::NR2::Field;
   my $nrf=Photonic::LE::NR2::Field->new(...);
   my $field=$nrf->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the non retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

=head1 METHODS

=over 4

=item * new(haydock=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr Photonic::LE::NR2::Haydock is a Haydock calculator for the
structure, *initialized* with the flag keepStates=>1
(Photonic::Types::HaydockSave, as defined in Photonic::Types).

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criteria of convergence (default 1e-7) for
Field calculations

=item * evaluate($epsA, $epsB...)

Returns the microscopic electric field for given
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESSORS (read only)

=over 4

=item * haydock

Photonic::LE::NR2::Haydock structure

=item * nh

Maximum number of Haydock coefficients to use.

=item * smallE

Criteria of convergence. 0 means don't check.
* check remark *

=item * epsA

Dielectric function of component A

=item * epsB

Dielectric function of componente B

=item * u

Spectral variable

=item * Es

Array of field coefficients

=item * filter

Optional reciprocal space filter

=item * field

Real space field in format ri,xy,nx,ny,...

=item * epsL

Longitudinal dielectric response, obtained colaterally from last
evaluation of the field

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::LE::NR2::Haydock;
use Photonic::Utils qw(cgtsv GtoR);
use Photonic::Types;
use Photonic::Iterator qw(nextval);
use Moose;
use MooseX::StrictConstructor;

has 'haydock'=>(is=>'ro', isa=>'Photonic::Types::HaydockSave', required=>1,
           documentation=>'Haydock recursion calculator');
has 'Es'=>(is=>'ro', isa=>'ArrayRef[Photonic::Types::PDLComplex]', init_arg=>undef,
           writer=>'_Es', documentation=>'Field coefficients');
has 'filter'=>(is=>'ro', isa=>'PDL', predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'field'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
           writer=>'_field', documentation=>'Calculated real space field');
has 'epsL' =>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
		 writer=>'_epsL',
		 documentation=>'Longitudinal dielectric response');
has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');


sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=shift);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=$self->haydock->as;
    my $bs=$self->haydock->bs;
    my $stateit=$self->haydock->state_iterator;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->haydock->iteration if $nh>=$self->haydock->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$u - $as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-$bs->(0:$nh-1)->rotate(-1)->r2C;
    my $supradiag=$subdiag;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my $result = cgtsv($subdiag, $diag, $supradiag, $rhs);
    # Obtain longitudinal macroscopic response from result
    $self->_epsL(my $epsL=1/$result->((0)));
    # Normalize result so macroscopic field is 1.
    my $Es= $result*$epsL;
    #states are nx,ny...
    #field is cartesian,nx,ny...
    my @dims=$self->haydock->B->dims; # actual dims of space
    my $ndims=@dims; # num. of dims of space
    my $field_G=PDL->zeroes($ndims, @dims)->r2C;
    #field is cartesian, nx, ny...
    my $nrGnorm = $self->haydock->GNorm->r2C;
    for(my $n=0; $n<$nh; ++$n){
	my $GPsi_G=($stateit->nextval->dummy(0) * $nrGnorm);#^G|psi_n>
	#the result is cartesian, nx, ny,...
	my $EnGPsi_G=$GPsi_G*$Es->($n); #En ^G|psi_n>
	$field_G+=$EnGPsi_G;
    }
    $field_G *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($field_G, $ndims, 1);
    $field_R*=$self->haydock->B->nelem; #scale to have unit macroscopic field
    #result is cartesian, nx, ny,...
    $self->_field($field_R);
    return $field_R;
}

__PACKAGE__->meta->make_immutable;

1;
