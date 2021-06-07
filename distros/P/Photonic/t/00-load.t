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
    my @mods= qw(
	     Photonic
	     Photonic::Geometry
	     Photonic::OneH
	     Photonic::LE
	     Photonic::Geometry::FromEpsilon
	     Photonic::Geometry::FromB
	     Photonic::Geometry::FromImage2D
	     Photonic::Utils
	     Photonic::CharacteristicFunctions
	     Photonic::LE::NR2::OneH
	     Photonic::LE::NR2::SHP
	     Photonic::LE::NR2::EpsTensor
	     Photonic::LE::NR2::Field
	     Photonic::LE::NR2::EpsL
	     Photonic::LE::NR2::SHChiTensor
	     Photonic::LE::NR2::SH
	     Photonic::LE::NR2::AllH
	     Photonic::LE::S
	     Photonic::LE::NP
	     Photonic::LE::NR2
	     Photonic::LE::NP::OneH
	     Photonic::LE::NP::EpsTensor
	     Photonic::LE::NP::EpsL
	     Photonic::LE::NP::AllH
	     Photonic::LE::S::OneH
	     Photonic::LE::S::EpsTensor
	     Photonic::LE::S::EpsL
	     Photonic::LE::S::AllH
	     Photonic::WE::R2::EpsilonTensor
	     Photonic::WE::R2::OneH
	     Photonic::WE::R2::GreenP
	     Photonic::WE::R2::WaveP
	     Photonic::WE::R2::EpsilonP
	     Photonic::WE::R2::Green
	     Photonic::WE::R2::WaveF
	     Photonic::WE::R2::Field
	     Photonic::WE::R2::GreenF
	     Photonic::WE::R2::Wave
	     Photonic::WE::R2::EpsilonTensorF
	     Photonic::WE::R2::Metric
	     Photonic::WE::R2::AllH
	     Photonic::WE::S::EpsilonTensor
	     Photonic::WE::S::OneH
	     Photonic::WE::S::GreenP
	     Photonic::WE::S::WaveP
	     Photonic::WE::S::EpsilonP
	     Photonic::WE::S::Green
	     Photonic::WE::S::Field
	     Photonic::WE::S::Wave
	     Photonic::WE::S::Metric
	     Photonic::WE::S::AllH
	     Photonic::Roles::Geometry
	     Photonic::Roles::OneH
	     Photonic::Roles::KeepStates
	     Photonic::Roles::ReorthogonalizeR
	     Photonic::Roles::EpsL
	     Photonic::Roles::ReorthogonalizeC
	     Photonic::Roles::EpsParams
	     Photonic::Roles::UseMask
	     Photonic::Roles::Metric
	     Photonic::Roles::AllH
	     Photonic::WE
	     Photonic::Types
	     Photonic::AllH
	);
    foreach(@mods){
	use_ok( 'Photonic' ) || print "Bail out!\n";
    }

}

diag( "Testing Photonic $Photonic::VERSION, Perl $], $^X" );
done_testing();
