package Photonic::WE::S::EpsilonP;
$Photonic::WE::S::EpsilonP::VERSION = '0.014';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::EpsilonP

=head1 VERSION

version 0.014

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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

   use Photonic::WE::S::EpsilonP;
   my $eps=Photonic::WE::S::EpsilonP->new(haydock=>$h, nh=>$nh);
   my $EpsTensor=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor component for a given fixed
Photonic::WE::S::AllH structure as a function of the dielectric
functions of the components.

NOTE: Only works for polarizations along principal directions.

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$h Photonic::WE::S::AllH describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criterium of convergence (default 1e-7) for
Haydock coefficients and for the continued fraction.

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic dielectric component for a given value of the
dielectric function of the particle $epsB. The host's
response $epsA is taken from the AllH structure.

NOTE: Only works along principal directions.

=back

=head1 ACCESORS (read only)

=over 4

=item * epsilon

The macroscopic dielectric projection of the last operation

=item * All accesors of Photonic::WE::S::Wave


=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
#use Storable qw(dclone);
#use PDL::IO::Storable;
#use Photonic::WE::S::AllH;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::WE::S::WaveP';

has 'epsilon' =>  (is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
		   lazy=>1, builder=>'_build_epsilon',
		   documentation=>'Projected dielectric function');

sub _build_epsilon {
    my $self=shift;
    my $wave=$self->waveOperator;
    my $q=$self->haydock->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->haydock->metric->wavevector;
    my $k2=($k*$k)->sumover; #inner. my $k2=$k->inner($k); only works on real
    my $p=$self->haydock->normalizedPolarization;
    #Note $p->inner($p) might be complex, so is not necessarily 1.
    my $p2=($p*$p)->sumover;
    my $pk=($p*$k)->sumover;
    my $proj=$p2*$k2/$q2 - $pk*$pk/$q2;
    my $eps=$wave+$proj;
    return $eps;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
