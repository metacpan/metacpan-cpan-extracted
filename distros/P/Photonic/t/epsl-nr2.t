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

use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::AllH;
use Photonic::LE::NR2::EpsL;

use Machine::Epsilon;
use List::Util;

use Test::More tests => 6;

#my $pi=4*atan2(1,1);

sub Cagree {
    my $a=shift;
    my $b=shift//0;
    my $prec=shift//1e-7;
    return (($a-$b)->Cabs2)->sum<=$prec;
}

my $ea=1+2*i;
my $eb=3+4*i;
#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $gl=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
my $al=Photonic::LE::NR2::AllH->new(geometry=>$gl, nh=>10);
my $elo=Photonic::LE::NR2::EpsL->new(nr=>$al, nh=>10);
my $elv=$elo->evaluate($ea, $eb);
my $elx=1/((1-$gl->f)/$ea+$gl->f/$eb);
ok(Cagree($elv, $elx), "1D long epsilon");
is($elo->converged,1, "Converged");

#View 1D system as 2D. Transverse direction
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt, Direction0=>pdl([1,0])); #trans
my $at=Photonic::LE::NR2::AllH->new(geometry=>$gt, nh=>10);
my $eto=Photonic::LE::NR2::EpsL->new(nr=>$at, nh=>10);
my $etv=$eto->evaluate($ea, $eb);
my $etx=(1-$gt->f)*$ea+$gt->f*$eb;
ok(Cagree($etv, $etx), "1D trans epsilon");
is($eto->converged,1, "Converged");

#Test chess board
my $N=8;
my $Bc=zeroes(2*$N,2*$N);
$Bc=((($Bc->xvals<$N) & ($Bc->yvals<$N))
   | (($Bc->xvals>=$N) & ($Bc->yvals>=$N)));
my $gc=Photonic::Geometry::FromB->new(B=>$Bc, Direction0=>pdl([1,0]));
my $ac=Photonic::LE::NR2::AllH->new(geometry=>$gc, nh=>2000,
				    reorthogonalize=>1);
my $eco=Photonic::LE::NR2::EpsL->new(nr=>$ac, nh=>10000);
my $ecv=$eco->evaluate($ea, $eb);
my $ecx=sqrt($ea*$eb);
ok(Cagree($ecv, $ecx, 1e-4), "Chess board");
#diag("O: ". $ac->orthogonalizations. " I: ".$ac->iteration);
is($eco->converged,1, "Converged");
