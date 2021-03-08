# modified from t/cgtsl.t in Photonic by W. Luis Mochán

use strict;
use warnings;
use PDL;
use PDL::Complex;
use PDL::NiceSlice;
use PDL::LinearAlgebra::Complex;
use constant N=>10;
use Test::More tests => 2*N;

for my $D (3..N+2) { #first differencess
    #solve (1+i)(b_{n+1}-b_n)=1-i with homogeneous BCs
    my $c=zeroes($D)+0*i;
    my $d=-ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $b=ones($D)*(1-i); $b->(,(-1)).=(1-$D)*(1-i);
    my $info=pdl(short,0);
    cgtsv($c, $d, $e, $b, $info);
    my $r=sequence($D)*(1-i)/(1+i);
    ok($b->complex->approx($r)->all, "1st diff. cgtsv in D=$D")
      or diag "info: ", $info, "\nGot: ", $b, "\nExpected: ", $r;
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2{b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D)*(1+i); $c->(,(-1)).=0+0*i;
    my $d=-2*ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $b=ones($D)*(1-i);
    my $info=pdl(short,0);
    cgtsv($c, $d, $e, $b, $info);
    my $x=sequence($D)+0*i;
    my $r=(-$D/2-($D-1)/2*$x+1/2*$x*$x)*(1-i)/(1+i);
    ok($b->complex->approx($r)->all, "2nd diff. cgtsv in D=$D")
      or diag "info: ", $info, "\nGot: ", $b, "\nExpected: ", $r;
}
