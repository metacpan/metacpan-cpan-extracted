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
use PDL::NiceSlice;
use Photonic::LE::NR2::EpsTensor;

use Test::More;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
my $Nk=3;
my $Bk=zeroes(2*$Nk+1,2*$Nk+1);
$Bk=((($Bk->xvals<$Nk) & ($Bk->yvals<$Nk))
   | (($Bk->xvals>$Nk) & ($Bk->yvals>$Nk)));
my $gk=Photonic::Geometry::FromB->new(B=>$Bk); #trans
my $ekoa=Photonic::LE::NR2::EpsTensor->new(geometry=>$gk, nh=>1000, reorthogonalize=>1, epsA=>$ea, epsB=>$eb);
my $ekob=Photonic::LE::NR2::EpsTensor->new(geometry=>$gk, nh=>1000, reorthogonalize=>1, epsA=>$eb, epsB=>$ea);
my $etva=$ekoa->epsTensor;
my $etvb=$ekob->epsTensor;
#warn "etva=$etva\n"; warn "etvb=$etvb\n";
my $R=pdl([0,1],[-1,0]);
my $mt=(($R(*1)*$etvb(:,:,*1))->transpose)->sumover;
my $Rt=$R->transpose;
my $etvbR=(($mt(*1)*$Rt(,,*1))->transpose)->sumover;
my $etvab=($etva->(*1)*$etvbR->(:,:,*1))->transpose->sumover;
ok(Cagree($etvab,$ea*$eb*identity(2)),"Keller verified") or diag "got:$etvab\nexpected:", $ea*$eb*identity(2);

done_testing;
