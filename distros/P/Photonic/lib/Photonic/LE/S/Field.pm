package Photonic::LE::S::Field;
$Photonic::LE::S::Field::VERSION = '0.021';

=encoding UTF-8

=head1 NAME

Photonic::LE::S::Field

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

   use Photonic::LE::S::Field;
   my $nrf=Photonic::LE::S::Field->new(...);
   my $field=$nrf->evaluate();

=head1 DESCRIPTION

Calculates the non retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

=head1 METHODS

=over 4

=item * new(haydock=>$haydock, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$haydock Photonic::LE::S::Haydock is a Haydock calculator for the
structure, *initialized* with the flag keepStates=>1
(Photonic::Types::HaydockSave, as defined in Photonic::Types).

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criteria of convergence (default 1e-7) for
Field calculations

=item * evaluate()

Returns the microscopic electric field.

=back

=head1 ACCESSORS (read only)

=over 4

=item * haydock

Photonic::LE::S::Haydock structure

=item * nh

Maximum number of Haydock coefficients to use.

=item * smallE

Criteria of convergence. 0 means don't check.

=item * epsA

Dielectric function of component A

=item * epsB

Dielectric function of componente B

=item * u

Spectral variable

=item * Es

Array of field coefficients

=item * filter

optional reciprocal space filter

=item * field

real space field in format cartesian, nx, ny,...

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
use Photonic::LE::S::Haydock;
use Photonic::Utils qw(cgtsv GtoR);
use Photonic::Types;
use Photonic::Iterator;
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
# Not needed for spinor calculation
#has 'epsA'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsA',
#    documentation=>'Dielectric function of host');
#has 'epsB'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_epsB',
#        documentation=>'Dielectric function of inclusions');
#has 'u'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef, writer=>'_u',
#    documentation=>'Spectral variable');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub evaluate {
    my $self=shift;
    my $as=$self->haydock->as;
    my $bs=$self->haydock->bs;
    my $stateit=$self->haydock->state_iterator;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->haydock->iteration if $nh>$self->haydock->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=$bs->(0:$nh-1)->rotate(-1);
    my $supradiag=$subdiag;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my $result = cgtsv($subdiag, $diag, $supradiag, $rhs);
    # Obtain longitudinal macroscopic response from result
    # Add spinor normalization.
    $self->_epsL(my $epsL=sqrt(2)/$result->((0)));
    # Normalize result so macroscopic field is 1.
    my $Es = $result*$epsL;
    #states are nx,ny...
    #field is xy,pm,nx,ny...
    my @dims=$self->haydock->B->dims; # actual dims of space
    my $ndims=@dims; # num. of dims of space
    my $field_G=PDL->zeroes($ndims, 2, @dims)->r2C;
    for(my $n=0; $n<$nh; ++$n){
	#state is pm,nx,ny...
	#pmGnorm is xy,pm,nx,ny...
	#$Gpsi_G is xy,pm,nx,ny
	my $GPsi_G=($self->haydock->pmGNorm->mv(0,-1)*$stateit->nextval)
	    ->mv(-1,0); #^G|psi_n>
	my $EnGPsi_G=$Es->($n)*$GPsi_G; #En ^G|psi_n>
	$field_G+=$EnGPsi_G; #xy,pm,nx,ny...
    }
    #Choose +k
    my $Esp=$field_G->(:,(0)); #xy,nx,ny
    $Esp *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($Esp, $ndims, 1);
    $field_R*=$self->haydock->B->nelem; #scale to have unit macroscopic field
    #result is xy,nx,ny,...
    $self->_field($field_R);
    return $field_R;
}

__PACKAGE__->meta->make_immutable;

1;
