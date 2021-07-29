package Photonic::WE::R2::AllH;
$Photonic::WE::R2::AllH::VERSION = '0.018';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::AllH

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

   use Photonic::WE::R2::AllH;
   my $iter=Photonic::WE::R2::AllH->new(metric=>$metric,
            nh=>$Nh, polarization=>$p, keepStates=>$save);
   $iter->run;
   my $haydock_as=$iter->as;
   my $haydock_bs=$iter->bs;
   my $haydock_b2s=$iter->b2s;
   my $haydock_b2s=$iter->b2s;
   my $haydock_b2s=$iter->b2s;
   my $haydock_cs=$iter->cs;
   my $haydock_bcs=$iter->bcs;
   my $haydock_gs=$iter->gs;

=head1 DESCRIPTION

Iterates the calculation of Haydock coefficients and states in the
retarded regime and saves them for later retrieval.

=head1 METHODS

=over 4

=item * new(metric=>$m, polarization=>$p, nh=>$nh[, keepStates=>$k, smallH=>$s])

Initializes an Ph::WE::R2::AllH object. $m is the retarded metric to use,
$p is the polarization of the field, $nh is the maximum number of desired
coefficients to calculate, $k is a flag, non zero to save the Haydock
states, $s is a number to be considered negligible. Other arguments
are as in Photonic::WE::R2::OneH.

=item * run

Runs the iteration to completion.

=item * All the Photonic::WE::R2::OneH methods

=back

=head1 ACCESSORS (read only)

=over 4

=item * nh

Maximum number of desired Haydock 'a' coefficients and states. The
number of b coefficients is one less.

=item * keepStates

Flag to keep (1) or discard (0) Haydock states

=item * states

Array of Haydock states

=item * as

Array of Haydock a coefficients

=item * bs

Array of Haydock b coefficients

=item * b2s

Array of Haydock b coefficients squared

=item * cs

Array of Haydock c coefficients

=item * bcs

Array of Haydock b times c coefficients

=item * gs

Array of Haydock g coefficients

=item * All the Photonic::WE::R2::OneH methods

=back

=begin Pod::Coverage

=head2 BUILD

=end Pod::Coverage


=cut

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::WE::R2::OneH';
with 'Photonic::Roles::AllH', 'Photonic::Roles::ReorthogonalizeR';

__PACKAGE__->meta->make_immutable;

1;
