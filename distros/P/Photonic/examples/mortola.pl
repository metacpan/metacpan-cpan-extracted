#! /usr/bin/env perl
# Proof of Spinor (S) module using Mortola results

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
use feature qw(say);

#use DBI;

use Getopt::Long;
use List::Util;

use lib qw(../../Photonic/lib);
use Photonic::Geometry::FromEpsilon;
use Photonic::LE::S::AllH;
use Photonic::LE::S::EpsL;
use PDL;
use PDL::NiceSlice;
use PDL::Complex;

set_autopthread_targ(4);;
set_autopthread_size(4);;


my $nh=20;
my $seed=12345;
srand $seed;
my $N=100;
my $l=1;
my $epsA=pdl(sprintf("%.2f %.2f", rand(),rand()))->complex;
my $epsB=pdl(sprintf("%.2f %.2f", rand(),rand()))->complex;
my $epsC=pdl(sprintf("%.2f %.2f", rand(),rand()))->complex;
my $epsD=pdl(sprintf("%.2f %.2f", rand(),rand()))->complex;
my $e=FourPhases($N,$epsA,$epsB,$epsC,$epsD);

my %epsM=(
xx=>sqrt($epsA*$epsB*$epsC*$epsD*(1/$epsA+1/$epsB+1/$epsC+1/$epsD)*($epsA+$epsB)*($epsC+$epsD)/(($epsA+$epsB+$epsC+$epsD)*($epsA+$epsD)*($epsC+$epsB))),
yy=>sqrt($epsA*$epsB*$epsC*$epsD*(1/$epsA+1/$epsB+1/$epsC+1/$epsD)*($epsA+$epsD)*($epsC+$epsB)/(($epsA+$epsB+$epsC+$epsD)*($epsA+$epsB)*($epsC+$epsD)))
);

my $filename="epsM_S_${seed}_eA${epsA}_eB${epsB}_eC${epsC}_eD${epsD}_N${N}_Nh${nh}"; $filename=~s/\./_/g; $filename.=".dat";
open(OUT, ">", "../data/$filename") or die "Couldn't open $filename for writing. $!";
print OUT "#  dir epsM_re (Mortola)  epsM_im (Mortola)  epsM_re (Spinor)    epsM_im (Spinor) \n";
my ($g,$allh,$nr)=(PDL->null,PDL->null,PDL->null);

my %dir=(xx=>pdl(1,0),yy=>pdl(0,1));
foreach my $x (keys %dir){
    $g=Photonic::Geometry::FromEpsilon->new(epsilon=>$e,L=>pdl($l,$l),Direction0=>$dir{$x});
    $allh=Photonic::LE::S::AllH->new(geometry=>$g, nh=>$nh);
    $nr=Photonic::LE::S::EpsL->new(nr=>$allh,nh=>$nh);
    say OUT join " ", $x, $epsM{$x}->re, $epsM{$x}->im, $nr->epsL->re, $nr->epsL->im;

}

sub checkerboard {
    my $N=shift;
    my $B=zeroes(2*$N+1,2*$N+1);
    my $c=$B->ndcoords-pdl($N,$N);
    my $i=whereND($B, $c->((0))->abs > $c->((1))->abs);
    $i.=1;
    #$i=wheLreND($B, $c->((0))->abs == $c->((1))->abs);
    #$i.=0.5; #esto vuelve isotrópico al sistema, pero ya no es binario
    return $B;
}

sub ajedrez { #checkboard
    my $N=shift;
    my $z=zeroes(2*$N+1,2*$N+1); #change to admit arbitrary lattice
    my $r=$z->ndcoords-pdl($N,$N);
    my $signopos=$r->((1))*$r->((0))>0;
#    my $t=$q<(.75+0*cos(3*$theta))*$N;
    return $signopos;
}

sub FourPhases { #checkboard
    my $N=shift;
    my $eA=shift;
    my $eB=shift;
    my $eC=shift;
    my $eD=shift;
#    my $z=zeroes(2*$N+1,2*$N+1); #change to admit arbitrary lattice
    $eB=($eB*ones($N,$N))->mv(0,-1);
    my $z=$eB->glue(1,($eA*ones($N,$N+1))->mv(0,-1));
    $eC=($eC*ones($N+1,$N))->mv(0,-1);
    $z=$z->glue(0,($eC->glue(1,($eD*ones($N+1,$N+1))->mv(0,-1))));
    $z=$z->mv(-1,0);
    $z(,,$N).=($z(,,$N+1)+$z(,,$N-1))/2;
    $z(,$N,).=($z(,$N+1,)+$z(,$N-1,))/2;
    return $z;
}


sub eps{
    my $epsi=shift;
    my $epsilonIn;
    if($epsi eq "au"){
	$epsilonIn="/home/gortiz/Metas/data/eps_au.d";
    }
    open(fileEpsIn,'<',"$epsilonIn") || die "can't open $epsilonIn:\n";
    (my $h_nu,my $eps_re,my $eps_im) = rcols *fileEpsIn;
    close(fileEpsIn);
    my $eps=$eps_re+i*$eps_im;
    return ($h_nu, $eps);
}



