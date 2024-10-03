package Photonic::LE::S::EpsL;
$Photonic::LE::S::EpsL::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::LE::S::EpsL

=head1 VERSION

version 0.023

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

   use Photonic::LE::S::EpsL;
   my $eps=Photonic::LE::S::EpsL->new(haydock=>$haydock, nh=>$nh);
   my $epsilonLongitudinal=$eps->epsL;

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a given fixed
Photonic::LE::S::Haydock structure as a function of the dielectric
functions of the components.

Consumes L<Photonic::Roles::EpsL>
- please see those for attributes.

=cut

use namespace::autoclean;
use Photonic::Utils qw(lentzCF);
use List::Util qw(min);
use Moo;
use MooX::StrictConstructor;

with 'Photonic::Roles::EpsL';

sub _build_epsL {
    my $self=shift;
    my $as=$self->haydock->as;
    my $b2s=$self->haydock->b2s;
    my $min= min($self->nh, $self->haydock->iteration);
    my ($fn, $n)=lentzCF($as, -$b2s, $min, $self->smallE);
    # Check this logic:
    $self->_converged($n<$min || $self->haydock->iteration<=$self->nh);
    $self->_nhActual($n);
    return $fn;
};

__PACKAGE__->meta->make_immutable;

1;
