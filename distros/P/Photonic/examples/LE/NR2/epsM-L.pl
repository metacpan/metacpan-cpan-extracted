#! /usr/bin/env perl
# run this code form the command line: perl -Mlib=<path-to>lib epsM-L.pl

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
use List::Util;

use Photonic::Geometry::FromB;
use Photonic::LE::NR2::EpsL;

use PDL;
use PDL::NiceSlice;
use PDL::Complex;


# It is a M-dimensional problem where the macroscopic dielectric
# tensor components are calculated into the polarization direction
# (Direction0) given by this code as the input parameter $pdir.

# This example is about two phase system defined by a square unit cell
# of size $l with 2*$N+1 points per side. Haydock recursion method
# is used. The number of Haydock coefficients will be no more than $nh.
my $nh=30;
my $N=30;
my $l=10; # in nm

# Geometrical parameters that define the characteristic function B for
# the two phases system are given as input parameters. For this
# example to consider:

my $B=pdl();
# uncomment only one of the next three lines for M=1,2 or 3
#$B=zeroes(2*$N+1); #M=1
$B=zeroes(2*$N+1,2*$N+1); #M=2
#$B=zeroes(2*$N+1,2*$N+1,2*$N+1); #M=3
# further you can still do M >3 !!
my $r=0.45*(2*$N+1); # particle's radius $r in units of $l
$B=$B->rvals < $r;

# Further, by negating of $B, it allow us to explore a hole in
# metal case, then uncomment the next line
#$B=!$B;

# Material of phase A has a real dielectric constant $epsA.  Material
# of phase B has a complex dielectric function $epsBall that depends
# on the frequency $hnu_all in eV units. Under Non Retarded method (NR#)
# the wavelength of the probing light is very large compared with $l.

my $epsA=pdl(4); # used for host A and for metric
my ($hnu_all,$epsBall)=eps("au"); # used for particle B, gold in this example.
# in DATA below this file end
my $elem=$epsBall->dim(1); # how many frequencies for calculation

# In this example the Longitudinal Epsilon (LE) is a Photonic::LE::NR2
# perl-PDL module that heritates to the AllH and EpsL module that
# it is implemented.  The object $gmtnr has access to geometry (B),
# cell size (L), and polarization direction (Direction0) $pdir.
my $pdir=();
# uncomment only one of the next three lines for M=1,2 or 3
#$pdir=pdl([1]); #M=1 [] to force one dimensional vector
$pdir=pdl(0,1); #M=2
#$pdir=pdl(0,0,1); #M=3

# it is \hat x, y, and z direction. Take the corresponding in M=2 dimensions !

my $L=();
# take the corresponding cell for M=1, 2 or 3
#$L=pdl($l);
$L=pdl($l,$l);
#$L=pdl($l,$l,$l);

my $gmtnr=Photonic::Geometry::FromB->new(B=>$B,L=>$L,Direction0=>$pdir);
# object $allh has access to Haydock's coefficientes
my $allh=Photonic::LE::NR2::AllH->new(geometry=>$gmtnr, nh=>$nh);
# object $nr has access to longitudinal components of macrsocopic
# tensor via EpsL attribute
my $epsM_L=Photonic::LE::NR2::EpsL->new(nr=>$allh, nh=>$nh);
# where $epsM_L is a EpsL object that will be used to calculate the
# macroscopic dielectric tensor component in Direction0 polarization
# direction for different frequency

#--------------------------------------------
my @out=(); # list for the output results
#--------------------------------------------

#------------------------------------------------------------
for(my $j=0;$j<$elem;$j++){
    my $epsB=$epsBall(,($j),(0));
    my $hnu=$hnu_all(($j),(0));
#----------------------------------------------------------------------------------
# Non Retarded calculation throw the $epsM_L object of Photonic::LE::NR2::EpsL
#----------------------------------------------------------------------------------
# with the NR2 evaluate method the same Haydock coefficients are used
# for all frequencies. The object $epsM_L knows about it.
# First argument is the host (epsA)
    my $epsM_pdir=$epsM_L->evaluate($epsA->r2C,$epsB);
# $epsM_L is the macroscopic dielectric tensor (complex number) in \hat y=(0,1) Direction0
#----------------------------------------------------------------------------------

    my $linea=pdl($hnu, $epsM_pdir->re, $epsM_pdir->im);
    push @out, $linea;
}
#----------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
# Displays results to graphical terminal 'qt', try with other that you have installed
#----------------------------------------------------------------------------------
use PDL::Graphics::Gnuplot;
my $o=pdl(@out)->mv(-1,0);
print $o->info,"\n";
my $x=$o(,0);
my $y=$o->(:,1:-1);
my $wgp=gpwin('qt');
$wgp->plot(xr=>[1.2,3],legend=>['Re','Im'],with=>'lines',lw=>2,$x,$y);
#------------------------------------------------------------


sub eps{
    my $epsi=shift;
    my @eps=();
    die "This example is prepared only for epsB=au (gold)" unless $epsi eq "au";
    while(<main::DATA>){
	(my $h_nu,my $eps_re,my $eps_im) = split;
	my $linea=pdl($h_nu,$eps_re,$eps_im);
	push @eps, $linea;
    }
    my $eps=pdl(@eps)->mv(-1,0)->(,1)+i*pdl(@eps)->mv(-1,0)->(,2);
    return (pdl(@eps)->mv(-1,0)->(,0), $eps);
}

__END__
1.000000e+00 -6.935081e+01 6.059344e+00
1.015000e+00 -6.698237e+01 5.790180e+00
1.030000e+00 -6.472860e+01 5.525760e+00
1.045000e+00 -6.258401e+01 5.267017e+00
1.060000e+00 -6.054108e+01 5.015509e+00
1.075000e+00 -5.859222e+01 4.772802e+00
1.090000e+00 -5.672987e+01 4.540463e+00
1.105000e+00 -5.494645e+01 4.320060e+00
1.120000e+00 -5.323440e+01 4.113158e+00
1.135000e+00 -5.158615e+01 3.921325e+00
1.150000e+00 -4.999468e+01 3.745940e+00
1.165000e+00 -4.845940e+01 3.586198e+00
1.180000e+00 -4.698388e+01 3.439885e+00
1.195000e+00 -4.557178e+01 3.304765e+00
1.210000e+00 -4.422671e+01 3.178600e+00
1.225000e+00 -4.295233e+01 3.059152e+00
1.240000e+00 -4.175228e+01 2.944186e+00
1.255000e+00 -4.063018e+01 2.831462e+00
1.270000e+00 -3.958850e+01 2.718917e+00
1.285000e+00 -3.861593e+01 2.606477e+00
1.300000e+00 -3.769232e+01 2.495355e+00
1.315000e+00 -3.679733e+01 2.386785e+00
1.330000e+00 -3.591066e+01 2.282001e+00
1.345000e+00 -3.501197e+01 2.182239e+00
1.360000e+00 -3.408096e+01 2.088731e+00
1.375000e+00 -3.309730e+01 2.002714e+00
1.390000e+00 -3.204067e+01 1.925420e+00
1.405000e+00 -3.090499e+01 1.857806e+00
1.420000e+00 -2.974113e+01 1.799712e+00
1.435000e+00 -2.861417e+01 1.750701e+00
1.450000e+00 -2.758921e+01 1.710334e+00
1.465000e+00 -2.673134e+01 1.678175e+00
1.480000e+00 -2.610567e+01 1.653785e+00
1.495000e+00 -2.577729e+01 1.636726e+00
1.510000e+00 -2.581129e+01 1.626560e+00
1.525000e+00 -2.624161e+01 1.622527e+00
1.540000e+00 -2.697751e+01 1.622574e+00
1.555000e+00 -2.789711e+01 1.624325e+00
1.570000e+00 -2.887852e+01 1.625405e+00
1.585000e+00 -2.979984e+01 1.623437e+00
1.600000e+00 -3.053919e+01 1.616047e+00
1.615000e+00 -3.097467e+01 1.600858e+00
1.630000e+00 -3.098440e+01 1.575494e+00
1.645000e+00 -3.044805e+01 1.537617e+00
1.660000e+00 -2.933966e+01 1.487016e+00
1.675000e+00 -2.777950e+01 1.426787e+00
1.690000e+00 -2.590040e+01 1.360311e+00
1.705000e+00 -2.383522e+01 1.290966e+00
1.720000e+00 -2.171680e+01 1.222133e+00
1.735000e+00 -1.967799e+01 1.157191e+00
1.750000e+00 -1.785164e+01 1.099519e+00
1.765000e+00 -1.636936e+01 1.052471e+00
1.780000e+00 -1.528872e+01 1.017783e+00
1.795000e+00 -1.455250e+01 9.946848e-01
1.810000e+00 -1.409362e+01 9.821913e-01
1.825000e+00 -1.384500e+01 9.793174e-01
1.840000e+00 -1.373956e+01 9.850780e-01
1.855000e+00 -1.371022e+01 9.984878e-01
1.870000e+00 -1.368988e+01 1.018562e+00
1.885000e+00 -1.361199e+01 1.044316e+00
1.900000e+00 -1.344051e+01 1.074857e+00
1.915000e+00 -1.318676e+01 1.109432e+00
1.930000e+00 -1.286612e+01 1.147298e+00
1.945000e+00 -1.249400e+01 1.187716e+00
1.960000e+00 -1.208577e+01 1.229942e+00
1.975000e+00 -1.165683e+01 1.273235e+00
1.990000e+00 -1.122257e+01 1.316855e+00
2.005000e+00 -1.079838e+01 1.360059e+00
2.020000e+00 -1.039872e+01 1.402139e+00
2.035000e+00 -1.002727e+01 1.442761e+00
2.050000e+00 -9.680728e+00 1.481835e+00
2.065000e+00 -9.355695e+00 1.519276e+00
2.080000e+00 -9.048763e+00 1.554997e+00
2.095000e+00 -8.756528e+00 1.588912e+00
2.110000e+00 -8.475584e+00 1.620935e+00
2.125000e+00 -8.202525e+00 1.650980e+00
2.140000e+00 -7.934104e+00 1.679012e+00
2.155000e+00 -7.668919e+00 1.705595e+00
2.170000e+00 -7.406758e+00 1.731681e+00
2.185000e+00 -7.147427e+00 1.758225e+00
2.200000e+00 -6.890735e+00 1.786185e+00
2.215000e+00 -6.636489e+00 1.816517e+00
2.230000e+00 -6.384497e+00 1.850179e+00
2.245000e+00 -6.134565e+00 1.888128e+00
2.260000e+00 -5.886502e+00 1.931319e+00
2.275000e+00 -5.640115e+00 1.980711e+00
2.290000e+00 -5.395211e+00 2.037260e+00
2.305000e+00 -5.151598e+00 2.101923e+00
2.320000e+00 -4.909084e+00 2.175657e+00
2.335000e+00 -4.667476e+00 2.259419e+00
2.350000e+00 -4.426581e+00 2.354165e+00
2.365000e+00 -4.186207e+00 2.460853e+00
2.380000e+00 -3.946161e+00 2.580440e+00
2.395000e+00 -3.706766e+00 2.713289e+00
2.410000e+00 -3.470406e+00 2.857391e+00
2.425000e+00 -3.239979e+00 3.010146e+00
2.440000e+00 -3.018384e+00 3.168951e+00
2.455000e+00 -2.808519e+00 3.331204e+00
2.470000e+00 -2.613282e+00 3.494305e+00
2.485000e+00 -2.435573e+00 3.655651e+00
2.500000e+00 -2.278289e+00 3.812640e+00
2.515000e+00 -2.143562e+00 3.963042e+00
2.530000e+00 -2.030452e+00 4.106106e+00
2.545000e+00 -1.937249e+00 4.241454e+00
2.560000e+00 -1.862247e+00 4.368707e+00
2.575000e+00 -1.803738e+00 4.487486e+00
2.590000e+00 -1.760013e+00 4.597412e+00
2.605000e+00 -1.729363e+00 4.698104e+00
2.620000e+00 -1.710083e+00 4.789186e+00
2.635000e+00 -1.700462e+00 4.870289e+00
2.650000e+00 -1.698767e+00 4.941754e+00
2.665000e+00 -1.703226e+00 5.005019e+00
2.680000e+00 -1.712062e+00 5.061618e+00
2.695000e+00 -1.723500e+00 5.113083e+00
2.710000e+00 -1.735763e+00 5.160948e+00
2.725000e+00 -1.747076e+00 5.206744e+00
2.740000e+00 -1.755663e+00 5.252006e+00
2.755000e+00 -1.759765e+00 5.298249e+00
2.770000e+00 -1.758688e+00 5.346040e+00
2.785000e+00 -1.753383e+00 5.394470e+00
2.800000e+00 -1.744944e+00 5.442502e+00
2.815000e+00 -1.734468e+00 5.489101e+00
2.830000e+00 -1.723046e+00 5.533231e+00
2.845000e+00 -1.711775e+00 5.573857e+00
2.860000e+00 -1.701747e+00 5.609941e+00
2.875000e+00 -1.694058e+00 5.640449e+00
2.890000e+00 -1.689706e+00 5.664448e+00
2.905000e+00 -1.688577e+00 5.682204e+00
2.920000e+00 -1.689840e+00 5.694758e+00
2.935000e+00 -1.692652e+00 5.703164e+00
2.950000e+00 -1.696170e+00 5.708476e+00
2.965000e+00 -1.699550e+00 5.711747e+00
2.980000e+00 -1.701949e+00 5.714030e+00
2.995000e+00 -1.702523e+00 5.716380e+00
3.010000e+00 -1.700504e+00 5.719768e+00

