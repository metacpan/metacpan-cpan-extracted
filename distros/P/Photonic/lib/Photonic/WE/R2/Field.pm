package Photonic::WE::R2::Field;
$Photonic::WE::R2::Field::VERSION = '0.017';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::Field

=head1 VERSION

version 0.017

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

   use Photonic::WE::R2::Field;
   my $nrf=Photonic::WE::R2::Field->new(...);
   my $field=$nrf->evaluate($epsA, $epsB);

=head1 DESCRIPTION

Calculates the retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr Photonic::WE::R2::AllH is a Haydock calculator for the
structure, *initialized* with the flag keepStates=>1
(Photonic::Types::AllHSave, as defined in Photonic::Types).

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criteria of convergence (default 1e-7) for
Field calculations

=item * evaluate($epsA, $epsB...)

Returns the microscopic electric field for given
dielectric functions of the host $epsA and the particle $epsB.

=back

=head1 ACCESSORS (read only)

=over 4

=item * nr

Photonic::WE::R2::AllH structure

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

real space field in format RorI, cartesian, nx, ny,...

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut


use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::WE::R2::AllH;
use Photonic::Utils qw(cgtsv GtoR);
use Photonic::Types;
use Photonic::Iterator;
use Moose;
use MooseX::StrictConstructor;

has 'nr'=>(is=>'ro', isa=>'Photonic::Types::AllHSave', required=>1,
           documentation=>'Haydock recursion calculator');
has 'Es'=>(is=>'ro', isa=>'ArrayRef[Photonic::Types::PDLComplex]', init_arg=>undef,
           writer=>'_Es', documentation=>'Field coefficients');
has 'filter'=>(is=>'ro', isa=>'PDL', predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'field'=>(is=>'ro', isa=>'Photonic::Types::PDLComplex', init_arg=>undef,
           writer=>'_field', documentation=>'Calculated real space field');
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
    $self->nr->run unless $self->nr->iteration;
}

sub evaluate {
    my $self=shift;
    $self->_epsB(my $epsB=shift);
    $self->_epsA(my $epsA=$self->nr->epsilon->r2C);
    $self->_u(my $u=1/(1-$epsB/$epsA));
    my $as=$self->nr->as;
    my $bs=$self->nr->bs;
    my $cs=$self->nr->cs;
    my $stateit=$self->nr->state_iterator;
    my $nh=$self->nh; #desired number of Haydock terms
    #don't go beyond available values.
    $nh=$self->nr->iteration if $nh>$self->nr->iteration;
    # calculate using lapack for tridiag system
    my $diag=$u - $as->(0:$nh-1);
    # rotate complex zero from first to last element.
    my $subdiag=-$bs->(0:$nh-1)->rotate(-1)->r2C;
    my $supradiag=-$cs->(0:$nh-1)->rotate(-1)->r2C;
    my $rhs=PDL->zeroes($nh); #build a nh pdl
    $rhs->slice((0)).=1;
    $rhs=$rhs->r2C;
    #coefficients of g^{-1}E
    my $giEs = cgtsv($subdiag, $diag, $supradiag, $rhs);
    #states are xy,nx,ny...
    #field is xy,nx,ny...
    my @dims=$self->nr->B->dims; # actual dims of space
    my $ndims=@dims; # num. of dims of space
    my $field_G=PDL->zeroes($ndims, @dims)->r2C;
    #print $field_G->info, "\n";
    #field is cartesian, nx, ny...
    for(my $n=0; $n<$nh; ++$n){
	my $giE_G=$giEs->($n)*$stateit->nextval; #En ^G|psi_n>
	$field_G+=$giE_G;
    }
    #
    my $Es=$self->nr->applyMetric($field_G);
    my $e_0=1/($Es->slice(":" . ",(0)" x $ndims)
	       *$self->nr->polarization->conj)->sumover;
    # Normalize result so macroscopic field is 1.
    $Es*=$e_0;
    $Es *= $self->filter if $self->has_filter;
    ##get cartesian out of the way, fourier transform, put cartesian.
    my $field_R=GtoR($Es, $ndims, 1);
    $field_R*=$self->nr->B->nelem; #scale to have unit macroscopic field
    #result is cartesian, nx, ny,...
    $self->_field($field_R);
    return $field_R;
}

__PACKAGE__->meta->make_immutable;

1;
