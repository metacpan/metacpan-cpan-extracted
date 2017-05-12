# Test the function ExtraUtils function dgtsl

use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Photonic::ExtraUtils;
use feature qw(say);
use constant N=>10;
use Test::More tests => 2*N;

for my $D (3..N+2){ #first differencess
    #solve b_{n+1}-b_n=1 with homogeneous BCs
    my $c=zeroes($D);
    my $d=-ones($D);
    my $e=ones($D); $e->((-1)).=0;
    my $b=ones($D); $b->((-1)).=1-$D;
    my $info=pdl(short,0);
    dgtsl($c, $d, $e, $b, $info);
    my $r=sequence($D);
    ok($b->approx($r)->all, "1st diff. dgtsl in $D-D");
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D); $c->((0)).=0;
    my $d=-2*ones($D);
    my $e=ones($D); $e->((-1)).=0;
    my $b=ones($D);
    my $info=pdl(short,0);
    dgtsl($c, $d, $e, $b, $info);
    my $x=sequence($D);
    my $r=-$D/2-($D-1)/2*$x+1/2*$x*$x;
    ok($b->approx($r)->all, "2nd diff. dgtsl in $D-D");
}
