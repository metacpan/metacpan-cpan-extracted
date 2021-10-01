#Test non cartesian primitive vectors.

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
use Photonic::LE::NR2::EpsL;

use Test::More tests => 6;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
#Check haydock coefficients for simple 1D system
my $B=zeroes(1,11)->yvals<5; #1D system
my $gl=Photonic::Geometry::FromB->new(B=>$B,
   primitive=>pdl([1,1],[1,-1]), Direction0=>pdl([1,-1])); #long
my $al=Photonic::LE::NR2::Haydock->new(geometry=>$gl, nh=>10);
my $elo=Photonic::LE::NR2::EpsL->new(haydock=>$al, nh=>10, epsA=>$ea, epsB=>$eb);
my $elv=$elo->epsL;
my $elx=1/((1-$gl->f)/$ea+$gl->f/$eb);
ok(Cagree($elv, $elx), "1D long epsilon");
#diag($elv);
#diag($elx);
is($elo->converged,1, "Converged");

#View 1D system as 2D. Transverse direction
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt,
   primitive=>pdl([1,1],[1,-1]), Direction0=>pdl([1,1])); #trans
my $at=Photonic::LE::NR2::Haydock->new(geometry=>$gt, nh=>10);
my $eto=Photonic::LE::NR2::EpsL->new(haydock=>$at, nh=>10, epsA=>$ea, epsB=>$eb);
my $etv=$eto->epsL;
my $etx=(1-$gt->f)*$ea+$gt->f*$eb;
ok(Cagree($etv, $etx), "1D trans epsilon");
#diag($etv);
#diag($etx);
is($eto->converged,1, "Converged");

#Test chess nonorthogonal basis.
my $N=10;
my $Bc=zeroes(2*$N,2*$N);
#use (1,0) and (1,1) as primitive vectors.
$Bc=((((($Bc->xvals+$Bc->yvals) % (2*$N)) <$N) & ($Bc->yvals<$N))
     | (((($Bc->xvals+$Bc->yvals) % (2*$N)) >= $N) & ($Bc->yvals>=$N)));
my $gc=Photonic::Geometry::FromB->new(
    B=>$Bc, L=>pdl(1, sqrt(2)), primitive=>pdl([1,0],[1,1]),
    Direction0=>pdl([1,0]));
my $ac=Photonic::LE::NR2::Haydock->new(geometry=>$gc, nh=>2000,
				    reorthogonalize=>1);
my $eco=Photonic::LE::NR2::EpsL->new(haydock=>$ac, nh=>10000, epsA=>$ea, epsB=>$eb);
my $ecv=$eco->epsL;
my $ecx=sqrt($ea*$eb);
#diag($ecv);
#diag($ecx);
#diag($Bc);
ok(Cagree($ecv, $ecx, 1e-4), "Chess board");
#diag("O: ". $ac->orthogonalizations. " I: ".$ac->iteration);
is($eco->converged,1, "Converged");
