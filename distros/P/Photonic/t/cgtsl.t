# Test the function ExtraUtils function cgtsl

use strict;
use warnings;
use PDL;
use PDL::Complex;
use PDL::NiceSlice;
use Photonic::ExtraUtils;
use feature qw(say);
use constant N=>10;
use Test::More tests => 2*N;

for my $D (3..N+2){ #first differencess
    #solve (1+i)(b_{n+1}-b_n)=1-i with homogeneous BCs
    my $c=zeroes($D)+0*i;
    my $d=-ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $b=ones($D)*(1-i); $b->(,(-1)).=(1-$D)*(1-i);
    my $info=pdl(short,0);
    cgtsl($c, $d, $e, $b, $info);
    my $r=sequence($D)*(1-i)/(1+i);
    ok($b->approx($r)->all, "1st diff. dgtsl in $D-D");
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D)*(1+i); $c->(,(0)).=0+0*i;
    my $d=-2*ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $b=ones($D)*(1-i);
    my $info=pdl(short,0);
    cgtsl($c, $d, $e, $b, $info);
    my $x=sequence($D)+0*i;
    my $r=(-$D/2-($D-1)/2*$x+1/2*$x*$x)*(1-i)/(1+i);
    ok($b->approx($r)->all, "2nd diff. cgtsl in $D-D");
}

