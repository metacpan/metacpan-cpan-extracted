#!/usr/bin/env perl

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

use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::Graphics::Gnuplot;

use Photonic::Geometry::FromB;
use Photonic::CharacteristicFunctions qw(triangle isosceles ellipse);
use Photonic::WE::R2::Metric;
use Photonic::WE::R2::AllH;
use Photonic::WE::R2::Field;
use Photonic::Utils qw(tile vectors2Dlist);

my $N=200;# L=2*N+1 puntos por lado
my $f=0.74;
my $nh=100;
my $small=1e-05;
my $epsA=pdl(1.0);
my $titulo="-22.0";
my $epsB=r2C($titulo)+i*0.01;

my $pdir=pdl([0,1]);
my $l=10;#nm
my $L=pdl($l,$l);
my $B=ellipse($N,$f,1.0);
my $circle=Photonic::Geometry::FromB->new(B=>$B,L=>$L,Direction0=>$pdir);
my $m=Photonic::WE::R2::Metric->new(geometry=>$circle, epsilon=>$epsA,
					  wavenumber=>pdl(0.1),
					  wavevector=>pdl([0.01,0]));
my $nr=Photonic::WE::R2::AllH->new(metric=>$m,keepStates=>1,
					polarization=>$pdir->r2C, nh=>$nh);
#my $nr=Photonic::WE::R2::AllH->new(geometry=>$circle,nh=>$nh,keepStates=>1);
my $nrf=Photonic::WE::R2::Field->new(nr=>$nr, nh=>$nh, small=>$small,keepStates=>1);
my $field=$nrf->evaluate($epsA->r2C, $epsB);
say $field->info;

my $wf=gpwin('x11', size=>[8,8],persist=>1,wait=>60); #initialice windows

plotfield($titulo, $field);

sub plotfield {
    my $titulo=shift;
    my $field=shift;
    my $fieldt=tile($field->mv(0,-1)->mv(0,-1),	3,3)->mv(-1,0)->mv(-1,0);
    my $fieldabs=$fieldt->Cabs2->sumover->sqrt;
#    my $fieldR=$fieldt->((0))->real/$fieldabs->(*1); #real part
#    my $fieldI=$fieldt->((1))->real/$fieldabs->(*1); #imaginary part
    my $fieldR=$fieldt->re->norm; #real part normalized
    my $fieldI=$fieldt->im->norm; #imaginary part normalized
    $wf->plot(
	{
	    cbrange=>[0,100],
	    square=>1,
	    xr=>[$N,5*$N+2], yr=>[$N,5*$N+2], title=>"$titulo",
	xtics=>0, ytics=>0},
	with=>'image',$fieldabs,
	#{lt=> 1, lc=>2,lw=>1.5},
	#with=>'vectors',
	#vectors2Dlist($fieldR, int(8/50*$N), int(7/50*$N)),
	{lc=>3, lt=>1},
	with=>'vectors',
	vectors2Dlist($fieldI, int(8/50*$N), int(7/50*$N)),
	);
}
