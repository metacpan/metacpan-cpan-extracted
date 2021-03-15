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
use PDL::Complex;
use Photonic::Geometry::FromEpsilon;
use Photonic::LE::S::AllH;
use Photonic::LE::S::EpsL;

use Test::More tests => 10;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $f=$B->sumover/$B->nelem;
my $epsilon=$ea*(1-$B)+$eb*$B;
my $gl=Photonic::Geometry::FromEpsilon->new(epsilon=>$epsilon,
					    Direction0=>pdl([1])); #long
my $al=Photonic::LE::S::AllH->new(geometry=>$gl, nh=>10, epsilon=>$epsilon);
my $elo=Photonic::LE::S::EpsL->new(nr=>$al, nh=>10);
my $elv=$elo->epsL;
my $elx=1/((1-$f)/$ea+$f/$eb);
ok(Cagree($elv, $elx), "1D long epsilon");
is($elo->converged,1, "Converged");

#View 1D system as 2D. Transverse direction
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $epsilont=$ea*(1-$Bt)+$eb*$Bt;
my $gt=Photonic::Geometry::FromEpsilon->new(epsilon=>$epsilont,
					    Direction0=>pdl([1,0])); #trans
my $at=Photonic::LE::S::AllH->new(geometry=>$gt, nh=>10);
my $eto=Photonic::LE::S::EpsL->new(nr=>$at, nh=>10);
my $etv=$eto->epsL;
my $etx=(1-$f)*$ea+$f*$eb;
ok(Cagree($etv, $etx), "1D trans epsilon");
is($eto->converged,1, "Converged");

#Test chess board
my $N=8;
my $Bc=zeroes(2*$N,2*$N);
$Bc=((($Bc->xvals<$N) & ($Bc->yvals<$N))
   | (($Bc->xvals>=$N) & ($Bc->yvals>=$N)));
my $epsilonc=$ea*(1-$Bc)+$eb*$Bc;
my $gc=Photonic::Geometry::FromEpsilon->new(epsilon=>$epsilonc,
   Direction0=>pdl([1,0]));
my $ac=Photonic::LE::S::AllH->new(geometry=>$gc, nh=>2000,
   reorthogonalize=>1);
my $eco=Photonic::LE::S::EpsL->new(nr=>$ac, nh=>2000);
my $ecv=$eco->epsL;
my $ecx=sqrt($ea*$eb);
ok(Cagree($ecv, $ecx, 1e-4), "Chess board");
#diag("O: ".$ac->orthogonalizations." I: ". $ac->iteration);
#diag($ecv);
#diag($ecx);
#diag($ac->iteration);
#diag($ac->orthogonalizations);
#diag(pdl($ac->as)->complex);
#diag(pdl($ac->bs)->complex);
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
    my $eimpar=FourPhasesImpar($N,$epsA,$epsB,$epsC,$epsD);
    my $epar=FourPhasesPar($N,$epsA,$epsB,$epsC,$epsD);

    my %epsM=(
	xx=>sqrt($epsA*$epsB*$epsC*$epsD
		 * (1/$epsA + 1/$epsB +
		    1/$epsC+1/$epsD)*($epsA+$epsB)*($epsC+$epsD) /
		 (($epsA + $epsB + $epsC + $epsD) * ($epsA + $epsD) *
		  ($epsC+$epsB))),
	yy=>sqrt($epsA*$epsB*$epsC*$epsD
		 * (1/$epsA + 1/$epsB + 1/$epsC + 1/$epsD)
		 * ($epsA+$epsD) * ($epsC+$epsB)
		 / (($epsA + $epsB + $epsC + $epsD) * ($epsA+$epsB) *
		    ($epsC+$epsD)))
	);
    my ($g,$allh,$nr)=(PDL->null,PDL->null,PDL->null);
    my %dir=(xx=>pdl(1,0),yy=>pdl(0,1));
    my %e=(neven => $epar,nodd =>$eimpar);
    foreach my $np (qw(neven nodd)){
	foreach my $dir (qw(xx yy)){
	    $g=Photonic::Geometry::FromEpsilon->new(
		epsilon=>$e{$np},L=>pdl($l,$l),Direction0=>$dir{$dir});
	    $allh=Photonic::LE::S::AllH->new(
		geometry=>$g, nh=>$nh,reorthogonalize=>1);
	    $nr=Photonic::LE::S::EpsL->new(nr=>$allh,nh=>$nh);
	    ok(Cagree($epsM{$dir},$nr->epsL,1e-2),
	       "Mortola -dir: $dir, -N: $np");
	}
    }
    sub FourPhasesImpar { #checkerboard
	my $N=shift;
	my $eA=shift;
	my $eB=shift;
	my $eC=shift;
	my $eD=shift;
	$eB=($eB*ones($N,$N))->mv(0,-1);
	my $z=$eB->glue(1,($eA*ones($N,$N+1))->mv(0,-1));
	$eC=($eC*ones($N+1,$N))->mv(0,-1);
	$z=$z->glue(0,($eC->glue(1,($eD*ones($N+1,$N+1))->mv(0,-1))));
	$z=$z->mv(-1,0);
	$z(,,$N).=($z(,,$N+1)+$z(,,$N-1))/2;
	$z(,$N,).=($z(,$N+1,)+$z(,$N-1,))/2;
	return $z;
    }
    sub FourPhasesPar { #checkerboard
	my $N=shift;
	my $eA=shift;
	my $eB=shift;
	my $eC=shift;
	my $eD=shift;
	$eB=($eB*ones($N,$N))->mv(0,-1);
	my $z=$eB->glue(1,($eA*ones($N,$N))->mv(0,-1));
	$eC=($eC*ones($N,$N))->mv(0,-1);
	$z=$z->glue(0,($eC->glue(1,($eD*ones($N,$N))->mv(0,-1))));
	$z=$z->mv(-1,0);
	$z(,,$N).=($z(,,$N)+$z(,,$N-1))/2;
	$z(,$N,).=($z(,$N,)+$z(,$N-1,))/2;
	return $z;
    }
}
