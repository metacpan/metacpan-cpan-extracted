package Photonic::Roles::Field;
$Photonic::Roles::Field::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::Roles::Field

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

   use Photonic::LE::NR2::Field;
   my $nrf=Photonic::LE::NR2::Field->new(...);
   my $field=$eps->field;

=over 4

=item (for developers)

    package Photonic::LE::NR2::Field;
    use namespace::autoclean;
    use Moo;
    with 'Photonic::Roles::Field';
    has...

=back

=head1 DESCRIPTION

Calculates the non retarded electric field for a given fixed
Photonic::Geometry structure and given dielectric functions of
the components.

The consuming class needs to supply these methods to inform lazy-building
of C<field>:

=over 4

=item * _build_field

=back

=head1 ATTRIBUTES

=over 4

=item * haydock

Haydock structure initialized with the flag keepStates=>1
(L<Photonic::Types/HaydockSave>).

=item * filter

optional reciprocal space filter

=item * field

real space field in format cartesian, nx, ny,... (lazy-built).

=item * nh

The maximum number of Haydock coefficients to use.

=back

=cut

use Moo::Role;
use Photonic::Types -all;

requires '_build_field';

has 'haydock'=>(is=>'ro', isa=>HaydockSave, required=>1,
           documentation=>'Haydock recursion calculator');
has 'filter'=>(is=>'ro', isa=>PDLObj, predicate=>'has_filter',
               documentation=>'Optional reciprocal space filter');
has 'field'=>(is=>'lazy', isa=>PDLComplex,
           documentation=>'Calculated real space field');
has 'nh' =>(is=>'lazy', isa=>Num, builder=>'_build_nh',
            documentation=>'Desired no. of Haydock coefficients');

sub BUILD {
    my $self=shift;
    $self->haydock->run unless $self->haydock->iteration;
}

sub _build_nh { #build desired number of Haydock coeffs to use.
    my $self=shift;
    return $self->haydock->nh; #defaults to coefficients desired
}

no Moo::Role;

1;
