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

use Test::More tests => 1;

#my $pi=4*atan2(1,1);

sub Cagree {
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)->Cabs2)->sum<=1e-7;
}

my $ea=1+2*i;
my $eb=3+4*i;
my $Nk=3;
my $Bk=zeroes(2*$Nk+1,2*$Nk+1);
$Bk=((($Bk->xvals<$Nk) & ($Bk->yvals<$Nk))
   | (($Bk->xvals>$Nk) & ($Bk->yvals>$Nk)));
my $gk=Photonic::Geometry::FromB->new(B=>$Bk); #trans
my $eko=Photonic::LE::NR2::EpsTensor->new(geometry=>$gk, nh=>1000, reorthogonalize=>1);
my $etva=$eko->evaluate($ea, $eb);
my $etvb=$eko->evaluate($eb, $ea);
#warn($etva); warn($etvb);
my $R=pdl(pdl(0,1),pdl(-1,0));
my $mt=(($R(*1)*$etvb(:,:,:,*1))->mv(2,1))->sumover;
my $Rt=$R->mv(1,0);
my $etvbR=(($mt(:,*1,:,:)*$Rt(,,*1))->mv(2,1))->sumover;
my $etvab=($etva->(:,*1,:,:)*$etvbR->(:,:,:,*1))->mv(2,1)->sumover;
ok(Cagree($etvab,$ea*$eb*identity(2)),"Keller verified");
#warn($etvab);
#warn($ea*$eb*identity(2));