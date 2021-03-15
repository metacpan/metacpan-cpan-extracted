#!/usr/bin/env perl

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
use feature qw(say);

use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::Graphics::Gnuplot;

use Photonic::Geometry::FromB;
use Photonic::CharacteristicFunctions qw(triangle isosceles ellipse);
use Photonic::LE::NR2::AllH;
use Photonic::LE::NR2::Field;
use Photonic::Utils qw(tile vectors2Dlist);

my $N=200;# L=2*N+1 puntos por lado
my $f=0.5;
my $nh=100;
my $small=1e-05;
my $epsA=r2C(1.0);
my $epsBreal=-2;
my $titulo=$epsBreal;
my $epsB=r2C($epsBreal)+i*0.01;

my $pdir=pdl([0,1]);
my $l=10;
my $L=pdl($l,$l);
my $B=ellipse($N,$f,.7);
my $circle=Photonic::Geometry::FromB->new(B=>$B,L=>$L,Direction0=>$pdir);
my $nr=Photonic::LE::NR2::AllH->new(geometry=>$circle,nh=>$nh,keepStates=>1);
my $nrf=Photonic::LE::NR2::Field->new(nr=>$nr, nh=>$nh);
my $field=$nrf->evaluate($epsA, $epsB);

my $wf=gpwin('x11', size=>[8,8],persist=>1,wait=>60); #initialice windows

plotfield($titulo, $field);

sub plotfield {
    my $titulo=shift;
    my $field=shift;
    my $fieldt=tile($field->mv(0,-1)->mv(0,-1),	3,3)->mv(-1,0)->mv(-1,0);
    my $fieldabs=$fieldt->Cabs2->sumover->sqrt;
    my $fieldR=$fieldt->re->norm; #real part normalized
    my $fieldI=$fieldt->im->norm; #imaginary part normalized
    $wf->plot(
	{   cbrange=>[0,80],
	    square=>1,
	    xr=>[$N,5*$N+2], yr=>[$N,5*$N+2], title=>"$titulo",
	    xtics=>0, ytics=>0
	},
	with=>'image',$fieldabs,
	{lc=>3, lt=>1, dt=>1},
	with=>'vectors',
	vectors2Dlist($fieldI, int(3/50*$N), int(5/50*$N)),
	);
}
