#! /usr/bin/env perl
# run this code form the command line: perl -Mlib=<path-to>lib Ring.pl

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
use Getopt::Long;
use constant PI=>4*atan2(1,1);

use Photonic::Geometry::FromB;
use Photonic::LE::NR2::EpsL;
use Photonic::WE::R2::Metric;
use Photonic::WE::R2::AllH;
use Photonic::WE::R2::EpsilonP;
use PDL;
use PDL::NiceSlice;

set_autopthread_targ(4);
set_autopthread_size(4);

# It is a bidimensional problem where the macroscopic dielectric
# tensor components are calculated into the polarization direction
# (Direction0) given by this code as an input parameter. This example
# are about two phase system defined by a square unit cell of size $l
# with 2*$N+1 points per side. Haydock recursion method under two
# formulations are implemented for comparison. The number of Haydock
# coefficients will be no more than $nh for both cases.
my $nh=30;
my $N=30;
my $l=1; # in nm

# Geometrical parameters that define the characteristic function B for
# the two phases system are given as input parameters. For this
# example it is a hole ring with radius r such that $r0 < r < $r1
my $r0=0; # small radius in units of $l
my $r1= 0.45; #large radius in units of $l
my $B=!ring($N,$r0,$r1);# negated of ring
# Further exploration for particle case would be to consider by removing "!"
#

# Material of phase A has a real dielectric constant $epsA.  Material
# of phase B has a complex dielectric function $epsBall that depends
# on the frequency $hnu_all in eV units. Units of the wavelength \lambda are nm
# and in the VIS-NIR range (400, 1000) that will be compared against $l via $a
my $a=10; # Such small $a (10 nm) compared with \lambda means that non retarded
# and retarded case should give equivalent results. Try with large value of
# $a to see retarded effects
my $epsA=pdl(4); # used for host A and for metric
my ($hnu_all,$epsBall)=eps("au"); # used for particle B, gold in this example.
my $k=0.01; # wave vector component used below in xx direction
# Units of $k are nm^{-1}. In de middle of VIS-NIR range it is approx
# 2*PI/\lambda
my $c=197.32; # it is \h c in q=\hbar\omega/\hbar c
my $elem=$epsBall->dim(0); # how many frequencies for calculation

# If you have not Gnuplot and Gnuplot pdl module intalled, the lines below
# commnented with ## would be useful for writing output data to a file named $filename
##my $filename="Au_cyl_r${r1}_k${k}_N${N}_Nh${nh}"; $filename=~s/\./_/g; $filename.=".dat";
##open(OUT, ">", "$filename") or die "Couldn't open $filename for writing. $!";
##print OUT "#   hnu       epsNR-L_re  epsNR-L_im   epsR-T_re    epsR-T_im \n";

#---------------------
# Non Retarded Approx.
#--------------------
# One computation is performed in the Non Retarded
# approximation. Longitudinal Epsilon (LE) is a Photonic::LE::NR2
# perl-PDL module that heritates to the AllH and EpsL module that
# it is implemented in this example.  The object $gmtnr has access to geometry (B),
# cell size (L), and polarization direction (Direction0).
# Note that in Non-Retarded (NR#) approximation wavelength size $a
# is very large compared with L
my $gmtnr=Photonic::Geometry::FromB->new(B=>$B,L=>pdl($l*$a,$l*$a),Direction0=>pdl(0,1));
# object $allh has access to Haydock's coefficientes
my $allh=Photonic::LE::NR2::AllH->new(geometry=>$gmtnr, nh=>$nh);
# object $nr has access to longitudinal components of macrsocopic
# tensor via EpsL attribute
my $nr=Photonic::LE::NR2::EpsL->new(nr=>$allh, nh=>$nh);
# that will be used to evaluate $er for different frequency below
# where $er is the macroscopic dielectric tensor component in Direction0
# polarization direction
#---------------------------

#---------------------
# Retarded Calculation
#--------------------
# Another computation is performed for all wavelength sizes
# object $gmtr has access to geometry (B), and cell size (L)
my $gmtr=Photonic::Geometry::FromB->new(B=>$B,L=>pdl($l*$a,$l*$a));
#--------------------------------------------

#--------------------------------------------
my @out=(); # list for the output results
#--------------------------------------------

#------------------------------------------------------------
# Begining of both Non Retarded (NR#) and Retarded (R#) caclulation
# for each frequency
#------------------------------------------------------------
for(my $j=0;$j<$elem;$j++){
    my $epsB=$epsBall(($j),(0));
    my $hnu=$hnu_all(($j),(0));
    my $q=$hnu/$c;
#----------------------------------------------------------------------------------
# Non Retarded calculation throw the $nr object of Photonic::LE::NR2::EpsL
#----------------------------------------------------------------------------------
# with the NR2 evaluate method the same Haydock coefficients are used
# for all frequencies. The object $nr knows about it.
# First argument is the host (epsA)
    my $enr=$nr->evaluate($epsA->r2C,$epsB);
# $enr is the macroscopic dielectric tensor (complex number) in \hat y=(0,1) Direction0
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
# Retarded calculation throw $e object of Photonic::WE::R2::EpsilonP
#----------------------------------------------------------------------------------
# Photonic::WE::R2 perl-PDL module has implemented Metric, AllH, and EpsilonP modules
# for the Retarded approximation case.
    my $m=Photonic::WE::R2::Metric->new(geometry=>$gmtr, epsilon=>$epsA,
					  wavenumber=>pdl($q),
					  wavevector=>pdl([$k,0]));
    my $h=Photonic::WE::R2::AllH->new(metric=>$m,
					polarization=>pdl(0,1)->r2C, nh=>$nh);
    my $e=Photonic::WE::R2::EpsilonP->new(haydock=>$h, nh=>$nh);
    my $er=$e->evaluate($epsB);
##    say OUT join " ", $hnu, $enr->re, $enr->im, $er->re, $er->im;
    my $linea=pdl($hnu, $enr->re, $enr->im, $er->re, $er->im);
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
$wgp->plot(xr=>[1.2,3],with=>'lines',lw=>2,$x,$y);
#------------------------------------------------------------

sub ring {
    my $N=shift;
    my $ra=(shift)*(2*$N+1);  #Note: it was $N
    my $rb=(shift)*(2*$N+1);
    my $z=zeroes(2*$N+1, 2*$N+1);
    my $B=($z->rvals<=$rb) & ($z->rvals >= $ra);
    return $B;
}

sub eps{
    my $epsi=shift;
    die "This example is prepared only for epsB=au (gold)" unless $epsi eq "au";
    my (@h_nu, @re, @im);
    while(<main::DATA>){
	my ($h_nu, $eps_re, $eps_im) = split;
        push @h_nu, $h_nu;
        push @re, $eps_re;
        push @im, $eps_im;
    }
    (pdl(\@h_nu), pdl(\@re) + pdl(\@im) * i);
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

