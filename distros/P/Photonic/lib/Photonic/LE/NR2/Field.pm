package Photonic::LE::NR2::Field;
$Photonic::LE::NR2::Field::VERSION = '0.015';


=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::Field

=head1 VERSION

version 0.015

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

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr Photonic::LE::NR2::AllH is a Haydock calculator for the
structure, *initialized* with the flag keepStates=>1
(Photonic::Types::LE::NR2::AllHSave, as defined in Photonic::Types).

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criteria of convergence (default 1e-7) for
Field calculations

=item * evaluate($epsA, $epsB...)

Returns the microscopic electric field for given
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESORS (read only)

=over 4

=item * nr

Photonic::LE::NR2::AllH structure

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

Longitudinal dielectric response, obtained colateraly from last
evaluation of the field

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::FFTW3;
use Photonic::LE::NR2::AllH;
use Photonic::ExtraUtils qw(cgtsv);
use Photonic::Types;
use Photonic::Iterator qw(nextval);
use Moose;
use MooseX::StrictConstructor;

has 'nr'=>(is=>'ro', isa=>'Photonic::Types::LE::NR2::AllHSave', required=>1,
           documentation=>'Haydock recursion calculator');
has 'Es'=>(is=>'ro', isa=>'ArrayRef[PDL::Complex]', init_arg=>undef,
           writer=>'_Es', documentation=>'Field coefficients');
has 'filter'=>(is=>'ro', isa=>'PDL', predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'field'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
           writer=>'_field', documentation=>'Calculated real space field');
has 'epsL' =>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
		 writer=>'_epsL',
		 documentation=>'Longitudinal dielectric response');
has 'nh' =>(is=>'ro', isa=>'Num', required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');


sub BUILD {
    my $self=shift;
    $self->nr->run unless $self->nr->iteration;
}

sub evaluate {
    my $self=shift;
    $self->_epsA(my $epsA=shift);
    $self->_epsB(my $epsB=shift);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=$self->nr->as;
    my $bs=$self->nr->bs;
    my $stateit=$self->nr->state_iterator;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->nr->iteration if $nh>=$self->nr->iteration;
    # calculate using lapack for tridiag system
    # solve \epsilon^LL \vec E^L=D^L.
    # At first take D=|0>
    my $diag=$u->complex - PDL->pdl($as)->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-PDL->pdl($bs)->(0:$nh-1)->r2C->real
      ->mv(0,-1)->rotate(-1)->mv(-1,0)
      ->complex;
    my $supradiag=$subdiag;
    my $rhs=PDL->zeroes($nh);
    $rhs->((0)).=1;
    $rhs=$rhs->r2C;
    my ($result, $info)= cgtsv($subdiag, $diag, $supradiag, $rhs);
    die "Error solving tridiag system" unless $info == 0;
    # Obtain longitudinal macroscopic response from result
    $self->_epsL(my $epsL=1/$result->(:,(0)));
    # Normalize result so macroscopic field is 1.
    $result*=$epsL;
    my @Es= map {PDL->pdl($_)->complex} @{$result->unpdl};
    #states are RorI,nx,ny...
    #field is RorY,cartesian,nx,ny...
    my $ndims=$self->nr->B->ndims; # num. of dims of space
    my @dims=$self->nr->B->dims; # actual dims of space
    my $field_G=PDL->zeroes(2, $ndims, @dims)->complex;
    #field is RorI, cartesian, nx, ny...
    for(my $n=0; $n<$nh; ++$n){
	my $GPsi_G=Cscale($stateit->nextval,
			  $self->nr->GNorm->mv(0,-1))->mv(-1,1);#^G|psi_n>
	#the result is RorI, cartesian, nx, ny,...
	my $EnGPsi_G=Cmul($GPsi_G,$Es[$n]); #En ^G|psi_n>
	$field_G+=$EnGPsi_G;
    }
    #filter RandI for each cartesian
    $field_G *= $self->filter->(*1) if $self->has_filter;
    #get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=ifftn($field_G->mv(1,-1)->real, $ndims)->mv(-1,1)->complex;
    $field_R*=$self->nr->B->nelem; #scale to have unit macroscopic field
    #result is RorI, cartesian, nx, ny,...
    $self->_field($field_R);
    #my $EM=$field_R->mv(0,-1)->mv(0,-1)->clump(-3)->mv(-2,0)->sumover->mv(-1,1)/$self->nr->B->nelem;
    #print "EM=$EM\n";
    return $field_R;
}


__PACKAGE__->meta->make_immutable;

1;
