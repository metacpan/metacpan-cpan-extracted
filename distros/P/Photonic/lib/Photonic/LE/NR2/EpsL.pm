package Photonic::LE::NR2::EpsL;
$Photonic::LE::NR2::EpsL::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::EpsL

=head1 VERSION

version 0.022

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

   use Photonic::LE::NR2::EpsL;
   my $eps=Photonic::LE::NR2::EpsL->new(haydock=>$haydock, nh=>$nh);
   my $epsilonLongitudinal=$eps->epsL;

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a given fixed
Photonic::LE::NR2::Haydock structure as a function of the dielectric
functions of the components. Nonretarded calculation for binary metamaterials.

Consumes L<Photonic::Roles::EpsL>
- please see those for attributes.

=head1 ATTRIBUTES

=over 4

=item * epsA epsB

The dielectric functions of component A and component B used in the
last calculation.

=item * u

The spectral variable used in the last calculation

=back

=cut

use namespace::autoclean;
use Photonic::Types -all;
use Photonic::Utils qw(lentzCF);

use List::Util qw(min);

use Moo;
use MooX::StrictConstructor;

with 'Photonic::Roles::EpsL';

has 'epsA'=>(is=>'ro', isa=>PDLComplex, required => 1,
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>PDLComplex, required => 1,
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'lazy', isa=>PDLComplex,
    documentation=>'Spectral variable');

sub _build_u {
    my $self=shift;
    1/(1-$self->epsB/$self->epsA);
}

sub _build_epsL {
    my $self=shift;
    my $as=PDL::r2C($self->haydock->as);
    my $b2s=PDL::r2C($self->haydock->b2s);
    my $min= min($self->nh, $self->haydock->iteration);
    my ($fn, $n)=lentzCF((my $u = $self->u)-$as, -$b2s, $min, $self->smallE);
    # Check this logic:
    $self->_converged($n<$min || $self->haydock->iteration<=$self->nh);
    $self->_nhActual($n);
    $self->epsA*$fn/$u;
}

__PACKAGE__->meta->make_immutable;

1;
