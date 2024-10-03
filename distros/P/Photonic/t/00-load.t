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

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    # refresh with: git grep -h '^package' lib/|sed -e 's/.* //' -e 's/;//'
    my @mods= qw(
Photonic
Photonic::CharacteristicFunctions
Photonic::Geometry::FromB
Photonic::Geometry::FromEpsilon
Photonic::Geometry::FromEpsilonTensor
Photonic::Geometry::FromImage2D
Photonic::LE::NP::EpsL
Photonic::LE::NP::EpsTensor
Photonic::LE::NP::Haydock
Photonic::LE::NR2::EpsL
Photonic::LE::NR2::EpsTensor
Photonic::LE::NR2::Field
Photonic::LE::NR2::Haydock
Photonic::LE::NR2::SH
Photonic::LE::NR2::SHChiTensor
Photonic::LE::NR2::SHP
Photonic::LE::S::EpsL
Photonic::LE::S::EpsTensor
Photonic::LE::S::Field
Photonic::LE::S::Haydock
Photonic::LE::ST::EpsL
Photonic::LE::ST::EpsTensor
Photonic::LE::ST::Field
Photonic::LE::ST::Haydock
Photonic::Roles::EpsFromGeometry
Photonic::Roles::EpsL
Photonic::Roles::EpsTensor
Photonic::Roles::Field
Photonic::Roles::Geometry
Photonic::Roles::Haydock
Photonic::Roles::KeepStates
Photonic::Roles::Metric
Photonic::Roles::Reorthogonalize
Photonic::Roles::UseMask
Photonic::Types
Photonic::Utils
Photonic::WE::R2::Field
Photonic::WE::R2::Green
Photonic::WE::R2::GreenP
Photonic::WE::R2::Haydock
Photonic::WE::R2::Metric
Photonic::WE::S::Field
Photonic::WE::S::Green
Photonic::WE::S::GreenP
Photonic::WE::S::Haydock
Photonic::WE::S::Metric
Photonic::WE::ST::Field
Photonic::WE::ST::Green
Photonic::WE::ST::GreenP
Photonic::WE::ST::Haydock
Photonic::WE::ST::Metric
	);


    foreach(@mods){
	use_ok( $_ ) || print "Bail out!\n";
    }

}

diag( "Testing Photonic $Photonic::VERSION, Perl $], $^X" );
done_testing();
