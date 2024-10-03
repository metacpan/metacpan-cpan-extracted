package Photonic::LE::NR2::SHP;
$Photonic::LE::NR2::SHP::VERSION = '0.023';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::SHP

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

   use Photonic::LE::NR2::SHP;
   my $nrshp=Photonic::LE::NR2::SHP->new(
             haydock=>$nt, nh=>10, densityA=>$dA, densityB=>$dB);

=head1 DESCRIPTION

Prepares the data for the calculation of the non retarded SH
polarization of an arbitrary periodic composite made up of
centrosymmetric isotropic component materials, using the continuous
dipolium model.

=head1 METHODS

=over 4

=item * make_field

Makes L<Photonic::LE::NR2::Field> Haydock field calculator for the
structure.

=back

=head1 ATTRIBUTES

=over 4

=item * haydock filter nh

Information to make L<Photonic::LE::NR2::Field> Haydock field calculator

=item * densityA, densityB

Normalized (to what?) density of polarizable entities in media A and B

=item * density

Density field over unit cell calculated from densities A and B

=item * ndims

Number of dimensions of the system, calculated from C<haydock>

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Moo;
use Photonic::Types -all;
use MooX::StrictConstructor;
use Photonic::LE::NR2::Field;
use Photonic::Utils qw(incarnate_as);

# to make Field object
has 'haydock'=>(is=>'ro', isa=>HaydockSave, required=>1,
           documentation=>'Haydock recursion calculator');
has 'filter'=>(is=>'ro', isa=>PDLObj, predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'nh' =>(is=>'ro', isa=>Num, required=>1,
            documentation=>'Desired no. of Haydock coefficients');

has 'densityA'=>(is=>'ro', isa=>Num, required=>1,
         documentation=>'Normalized dipole entities density in medium A');
has 'densityB'=>(is=>'ro', isa=>Num, required=>1,
         documentation=>'Normalized dipole entities density in medium B');
has 'density'=>(is=>'ro', isa=>PDLObj, writer=>'_density', init_arg=>undef,
         documentation=>'Normalized dipole entities density over unit cell');
has 'ndims' =>(is=>'lazy', isa=>Int, init_arg=>undef,
         documentation=>'Number of dimensions of system');

sub BUILD {
    my $self=shift;
    my $B=$self->haydock->B;
    $self->_density($self->densityA*(1-$B)+$self->densityB*$B);
}

sub _build_ndims {
    my $self=shift;
    return $self->haydock->B->ndims;
}

my @FIELD_ATTRS = qw(haydock nh);
sub make_field {
    my $self=shift;
    incarnate_as('Photonic::LE::NR2::Field', $self, \@FIELD_ATTRS, @_, $self->has_filter ? (filter=>$self->filter) : ());
}

__PACKAGE__->meta->make_immutable;

1;
