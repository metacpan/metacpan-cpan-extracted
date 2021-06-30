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

use strict;
use warnings;
use PDL;
use Photonic::WE::S::AllH;
use Photonic::WE::S::Metric;
use Photonic::WE::S::Field;

use Test::More tests => 2;
use lib 't/lib';
use TestUtils;

my $ea=r2C(1);
my $eb=3+4*i;

#Check field for simple 1D system. Longitudinal case
my $B=zeroes(11)->xvals<5; #1D system
my $epsilon=$ea*(1-$B)+$eb*$B;
my $gl=Photonic::Geometry::FromB->new(B=>$B); #long
my $ml=Photonic::WE::S::Metric->new(geometry=>$gl, epsilon=>pdl(1),
   wavenumber=>pdl(1), wavevector=>pdl([0.01]));
my $nr=Photonic::WE::S::AllH->new(
   metric=>$ml, nh=>10, keepStates=>1, polarization=>pdl([1])->r2C,
   epsilon=>$epsilon);
my $flo=Photonic::WE::S::Field->new(nr=>$nr, nh=>10);
my $flv=$flo->evaluate();
my $fla=1/$ea;
my $flb=1/$eb;
my $fproml=$fla*(1-$gl->f)+$flb*($gl->f);
($fla, $flb)=map {$_/$fproml} ($fla, $flb);
my $flx=($fla*(1-$B)+$flb*$B)->transpose;
ok(Cagree($flv, $flx), "1D long field");

#View 2D from 1D superlattice. Long wavelength transverse case
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $epsilont=$ea*(1-$Bt)+$eb*$Bt;
my $gt=Photonic::Geometry::FromB->new(B=>$Bt); #trans
my $mt=Photonic::WE::S::Metric->new(geometry=>$gt, epsilon=>pdl(1),
   wavenumber=>pdl(0.001), wavevector=>pdl([0,0.0001]));
my $nt=Photonic::WE::S::AllH->new(
   metric=>$mt, nh=>10, keepStates=>1, polarization=>pdl([1,0])->r2C,
   epsilon=>$epsilont);
my $fto=Photonic::WE::S::Field->new(nr=>$nt, nh=>10);
my $ftv=$fto->evaluate();
my $ftx=r2C(pdl [1, 0]);
ok(Cagree($ftv, $ftx), "1D trans field");
