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
use Photonic::LE::NR2::EpsTensor;

use Machine::Epsilon;
use List::Util;

use Test::More tests => 5;

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
my $gl=Photonic::Geometry::FromB->new(B=>$B); #long
my $elo=Photonic::LE::NR2::EpsTensor->new(geometry=>$gl, nh=>10);
my $elv=$elo->evaluate($ea, $eb);
my $elx=1/((1-$gl->f)/$ea+$gl->f/$eb);
ok(Cagree($elv, $elx), "1D long epsilon");
is($elo->converged,1, "Converged");

#View 2D from 1D superlattice.
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt); #trans
my $eto=Photonic::LE::NR2::EpsTensor->new(geometry=>$gt, nh=>10);
my $etv=$eto->evaluate($ea, $eb);
my $etx=(1-$gt->f)*$ea+$gt->f*$eb;
my $etenx=pdl([$etx, 0+0*i],[0+0*i, $elx])->complex;
ok(Cagree($etv, $etenx), "1D trans epsilon");
is($eto->converged,1, "Converged");

#Keller
my $Nk=6;
my $Bk=zeroes(2*$Nk,2*$Nk);
$Bk=((($Bk->xvals<$Nk) & ($Bk->yvals<$Nk))
   | (($Bk->xvals>=$Nk) & ($Bk->yvals>=$Nk)));
my $gk=Photonic::Geometry::FromB->new(B=>$Bk); #trans
my $eko=Photonic::LE::NR2::EpsTensor->new(
    geometry=>$gk, nh=>1000, reorthogonalize=>1, use_mask=>1);
my $etva=$eko->evaluate($ea, $eb);
my $etvb=$eko->evaluate($eb, $ea);
my $etvr=zeroes(2,2,2)->complex;
$etvr->(:,(0),(0)).= $etvb->(:,(1),(1));
$etvr->(:,(0),(1)).=-$etvb->(:,(1),(0));
$etvr->(:,(1),(0)).=-$etvb->(:,(0),(1));
$etvr->(:,(1),(1)).= $etvb->(:,(0),(0));
my $etvar=($etva->(:,*1,:,:)*$etvr->(:,:,:,*1))->mv(2,1)->sumover;
ok(Cagree($etvar,$ea*$eb*identity(2), 1e-3), "Keller");
