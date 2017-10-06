# Test the function ExtraUtils function cgtsl

use strict;
use warnings;
use PDL;
use PDL::Complex;
use PDL::NiceSlice;
use Photonic::ExtraUtils;
use feature qw(say);
use constant N=>10;
use Test::More tests => 2*N+2;

for my $D (3..N+2){ #first differencess
    #solve (1+i)(b_{n+1}-b_n)=1-i with homogeneous BCs
    my $c=zeroes($D)+0*i;
    my $d=-ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $b=ones($D)*(1-i); $b->(,(-1)).=(1-$D)*(1-i);
    my $info=pdl(short,0);
    cgtsl($c, $d, $e, $b, my $y=null, $info);
    my $r=sequence($D)*(1-i)/(1+i);
    ok($y->complex->approx($r)->all, "1st diff. dgtsl in $D-D");
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D)*(1+i); $c->(,(0)).=0+0*i;
    my $d=-2*ones($D)*(1+i);
    my $e=ones($D)*(1+i); $e->(,(-1)).=0+0*i;
    my $y=ones($D)*(1-i);
    my $info=pdl(short,0);
    cgtsl($c, $d, $e, $y, my $b=null, $info);
    my $x=sequence($D)+0*i;
    my $r=(-$D/2-($D-1)/2*$x+1/2*$x*$x)*(1-i)/(1+i);
    ok($b->complex->approx($r)->all, "2nd diff. cgtsl in $D-D");
}

#solve (1+i)(b_{n+1}-b_n)=1-i with homogeneous BCs
my $c=zeroes(3)+0*i;
my $d=-ones(3)*(1+i);
my $e=ones(3)*(1+i); $e->(,(-1)).=0+0*i;
my $b=ones(3)*(1-i); $b->(,(-1)).=(1-3)*(1-i);
my ($y, $info)=cgtsl($c, $d, $e, $b);
my $r=sequence(3)*(1-i)/(1+i);
ok($y->complex->approx($r)->all, "Omit output arguments");
cgtsl($c, $d, $e, $b->inplace);
print "b $b\n r $r\n";
ok($b->complex->approx($r)->all, "Inplace");


