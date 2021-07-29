package Photonic::LE::NR2::AllH;
$Photonic::LE::NR2::AllH::VERSION = '0.018';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::AllH

=head1 VERSION

version 0.018

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

   use Photonic::LE::NR2::AllH;
   my $iter=Photonic::LE::NR2::AllH->new(geometry=>$geometry,nh=>$Nh);
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;

=head1 DESCRIPTION

Implements the calculation of Haydock coefficients and saves them for
later retrieval for the nonretarded calculation of the macroscopic longitudinal
in a binary metamaterial.

=head1 METHODS

=over 4

=item * new(geometry=>$g, nh=>$nh)

Initializes an Ph::LE::NR2::AllH object.
$nh is the maximum number of desired coefficients.
All other arguments are as in Photonic::LE::NR2::OneH.

=item * run

Runs the iteration to completion. Calculates and saves Haydock
coefficients and states (if desired).

=item * All the Photonic::LE::NR2::OneH methods

They implement the calculation of one Haydock coefficient and state at
a time. See L<Photonic::LE::NR2::OneH> methods.

=item * All the Photonic::Roles::AllH methods

Iterate the calculation of Haydock coefficients and states. See L<Photonic::Roles::AllH>

=back

=head1 ACCESSORS (read only)

=over 4

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less.

=item * as

Array of Haydock a coefficients

=item * bs

Array of Haydock b coefficients

=item * b2s

Array of Haydock b coefficients squared

=back

=cut

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
extends 'Photonic::LE::NR2::OneH';
with 'Photonic::Roles::AllH', 'Photonic::Roles::ReorthogonalizeR';

__PACKAGE__->meta->make_immutable;

1;
