package Photonic::LE::NP::EpsL;
$Photonic::LE::NP::EpsL::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::LE::NP::EpsL

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

   use Photonic::LE::NP::EpsL;
   my $eps=Photonic::LE::NP::EpsL->new(haydock=>$nr, nh=>$nh);
   my $epsilonLongitudinal=$eps->epsL;

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a given fixed
Photonic::LE::NP::Haydock structure as a function of the dielectric
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
#    b0+a1/b1+a2/...
#	lo debo convertir a
#	a0-b1^2/a1-b2^2/
#	entonces bn->an y an->-b_n^2
    my ($fn, $n)=lentzCF($as, -$b2s, $min, $self->smallE);
    #If there are less available coefficients than $self->nh and all
    #of them were used, there is no remaining work to do, so, converged
    $self->_converged($n<$min || $self->haydock->iteration<=$self->nh);
    $self->_nhActual($n);
    $fn;
}

__PACKAGE__->meta->make_immutable;

1;
