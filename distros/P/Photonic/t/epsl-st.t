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
use Photonic::Geometry::FromEpsilonTensor;
use Photonic::LE::ST::Haydock;
use Photonic::LE::ST::EpsL;

use Test::More;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $f=$B->sumover/$B->nelem;
my $epsilon=($ea*(1-$B)+$eb*$B)->slice("*1,*1"); # *identity(1);
my $gl=Photonic::Geometry::FromEpsilonTensor->new(epsilon=>$epsilon,
					    Direction0=>pdl([1])); #long
my $al=Photonic::LE::ST::Haydock->new(geometry=>$gl, nh=>10, epsilon=>$epsilon);
my $elo=Photonic::LE::ST::EpsL->new(haydock=>$al, nh=>10);
my $elv=$elo->epsL;
my $elx=1/((1-$f)/$ea+$f/$eb);
ok(Cagree($elv, $elx), "1D long epsilon");
is($elo->converged,1, "Converged");

#View 1D system as 2D. Transverse direction
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $epsilont=($ea*(1-$Bt)+$eb*$Bt)->slice("*1,*1")*identity(2);
my $gt=Photonic::Geometry::FromEpsilonTensor->new(epsilon=>$epsilont,
					    Direction0=>pdl([1,0])); #trans
my $at=Photonic::LE::ST::Haydock->new(geometry=>$gt, nh=>10);
my $eto=Photonic::LE::ST::EpsL->new(haydock=>$at, nh=>10);
my $etv=$eto->epsL;
my $etx=(1-$f)*$ea+$f*$eb;
ok(Cagree($etv, $etx), "1D trans epsilon");
is($eto->converged,1, "Converged");

#Test chess board
my $N=8;
my $Bc=zeroes(2*$N,2*$N);
$Bc=((($Bc->xvals<$N) & ($Bc->yvals<$N))
   | (($Bc->xvals>=$N) & ($Bc->yvals>=$N)));
my $epsilonc=($ea*(1-$Bc)+$eb*$Bc)->slice("*1,*1")*identity(2);
my $gc=Photonic::Geometry::FromEpsilonTensor->new(epsilon=>$epsilonc,
   Direction0=>pdl([1,0]));
my $ac=Photonic::LE::ST::Haydock->new(geometry=>$gc, nh=>2000,
   reorthogonalize=>1);
my $eco=Photonic::LE::ST::EpsL->new(haydock=>$ac, nh=>2000);
my $ecv=$eco->epsL;
my $ecx=sqrt($ea*$eb);
ok(Cagree($ecv, $ecx, 1e-4), "Chess board");
#diag("O: ".$ac->orthogonalizations." I: ". $ac->iteration);
#diag($ecv);
#diag($ecx);
#diag($ac->iteration);
#diag($ac->orthogonalizations);
#diag($ac->as);
#diag($ac->bs);
is($eco->converged,1, "Converged");

#Test mortola. By Guille.
{
    my $nh=300;
    $N=7;
    my $l=1;
    my $epsA=1+1.5*i;
    my $epsB=2+2.5*i;
    my $epsC=3+3.5*i;
    my $epsD=4+4.5*i;
    my $eimpar=FourPhasesImpar($N,$epsA,$epsB,$epsC,$epsD)->slice("*1,*1")*identity(2);
    my $epar=FourPhasesPar($N,$epsA,$epsB,$epsC,$epsD)->slice("*1,*1")*identity(2);
    my $v = $epsA*$epsB*$epsC*$epsD * (1/$epsA + 1/$epsB + 1/$epsC + 1/$epsD);
    my $v_sum = $epsA + $epsB + $epsC + $epsD;
    my %epsM=(
	xx=>sqrt($v * ($epsA+$epsB) * ($epsC+$epsD)
		 / ($v_sum * ($epsA+$epsD) * ($epsC+$epsB))),
	yy=>sqrt($v * ($epsA+$epsD) * ($epsC+$epsB)
		 / ($v_sum * ($epsA+$epsB) * ($epsC+$epsD)))
    );
    my %dir=(xx=>pdl(1,0),yy=>pdl(0,1));
    my %e=(neven => $epar,nodd =>$eimpar);
    foreach my $np (qw(neven nodd)){
	foreach my $dir (qw(xx yy)){
	    my $g=Photonic::Geometry::FromEpsilonTensor->new(
		epsilon=>$e{$np},L=>pdl($l,$l),Direction0=>$dir{$dir});
	    my $allh=Photonic::LE::ST::Haydock->new(
		geometry=>$g, nh=>$nh,reorthogonalize=>1);
	    my $epsL=Photonic::LE::ST::EpsL->new(haydock=>$allh,nh=>$nh);
	    ok(Cagree($epsM{$dir},$epsL->epsL,1e-2),
	       "Mortola -dir: $dir, -N: $np");
	}
    }
}

done_testing;

sub checkerboard {
    my ($N, $N1, $eA, $eB, $eC, $eD) = @_;
    $eB=($eB*ones($N,$N));
    my $z=$eB->glue(1,($eA*ones($N,$N1)));
    $eC=($eC*ones($N1,$N));
    $z=$z->glue(0,($eC->glue(1,($eD*ones($N1,$N1)))));
    $z(,$N).=($z(,$N1)+$z(,$N-1))/2;
    $z($N,).=($z($N1,)+$z($N-1,))/2;
    return $z;
}

sub FourPhasesImpar { #checkerboard
    my ($N, $eA, $eB, $eC, $eD) = @_;
    checkerboard($N, $N+1, $eA, $eB, $eC, $eD);
}

sub FourPhasesPar { #checkerboard
    my ($N, $eA, $eB, $eC, $eD) = @_;
    checkerboard($N, $N, $eA, $eB, $eC, $eD);
}
