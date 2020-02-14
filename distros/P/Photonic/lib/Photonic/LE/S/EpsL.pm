package Photonic::LE::S::EpsL;
$Photonic::LE::S::EpsL::VERSION = '0.011';

=encoding UTF-8

=head1 NAME

Photonic::LE::S::EpsL

=head1 VERSION

version 0.011

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

   use Photonic::LE::S::EpsL;
   my $eps=Photonic::LE::S::EpsL->new(nr=>$nr, nh=>$nh);
   my $epsilonLongitudinal=$eps->epsL;

=head1 DESCRIPTION

Calculates the macroscopic longitudinal dielectric function for a given fixed
Photonic::LE::S::AllH structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(nr=>$nr, nh=>$nh, smallE=>$smallE)

Initializes the structure.

$nr is a Photonic::LE::S::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence for the continued fraction
(defaults to 1e-7)

=back

=head1 ACCESORS (read only)

=over 4

=item * epsL

The longitudinal macroscopic function.

=item * nr

The NonRetarded::LE::S::AllH structure

=item * nh

The maximum number of Haydock coefficients to use.

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * smallE

Criteria of convergence for continued fraction. 0 means don't
check.

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::LE::S::AllH;
use Photonic::Types;
use Photonic::Utils qw(lentzCF);
use List::Util qw(min);
use Moose;
use Moose;
use MooseX::StrictConstructor;

has 'nr' =>(is=>'ro', isa=>'Photonic::LE::S::AllH', required=>1);
has 'epsL'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsL');
has 'nhActual'=>(is=>'ro', isa=>'Num', init_arg=>undef,
                 writer=>'_nhActual');
has 'converged'=>(is=>'ro', isa=>'Num', init_arg=>undef, writer=>'_converged');
with 'Photonic::Roles::EpsL';

after BUILD => sub {
    my $self=shift;
    my $as=$self->nr->as;
    my $b2s=$self->nr->b2s;
    my $min= min($self->nh, $self->nr->iteration);
    my ($fn, $n)=lentzCF($as, [map {-$_} @$b2s], $min, $self->smallE);
    # Check this logic:
    my $converged=$n<$min || $self->nr->iteration<=$self->nh;
    $self->_converged($converged);
    $self->_nhActual($n);
    $self->_epsL($fn);
    return $fn;
};

__PACKAGE__->meta->make_immutable;

1;
