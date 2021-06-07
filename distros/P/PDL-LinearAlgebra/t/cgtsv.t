# modified from t/cgtsl.t in Photonic by W. Luis Mochán

use strict;
use warnings;
use PDL;
use PDL::Complex ();
use PDL::NiceSlice;
use PDL::LinearAlgebra::Complex;
use constant N=>10;
use Test::More;

my $PCi = PDL::Complex::i();

for my $D (3..N+2) { #first differences
    #solve (1+i)(b_{n+1}-b_n)=1-i with homogeneous BCs
    my $c=zeroes(2, $D)->complex;
    my $d=-ones($D)*(1+$PCi);
    my $e=ones($D)*(1+$PCi); $e->(,(-1)).=0;
    my $b=ones($D)*(1-$PCi); $b->(,(-1)).=(1-$D)*(1-$PCi);
    my $info=pdl(short,0);
    cgtsv($c, $d, $e, $b, $info);
    my $r=sequence($D)*(1-$PCi)/(1+$PCi);
    ok($b->complex->approx($r)->all, "1st diff. cgtsv in D=$D")
      or diag "info: ", $info, "\nGot: ", $b, "\nExpected: ", $r;

    $c=zeroes(cdouble, $D);
    $d=-ones($D)*czip(1, 1);
    $e=ones($D)*czip(1, 1); $e->((-1)).=0;
    $b=ones($D)*czip(1, -1); $b->((-1)).=(1-$D)*czip(1, -1);
    $info=pdl(short,0);
    cgtsv($c, $d, $e, $b, $info);
    $r=sequence($D)*czip(1, -1)/czip(1, 1);
    ok($b->approx($r)->all, "1st diff. native cgtsv in D=$D")
      or diag "info: ", $info, "\nGot: ", $b, "\nExpected: ", $r;
}

for my $D (3..N+2){ #second differences
    #solve b_{n+1}-2{b_n}+b_{n-1}=1 with kinda homogeneous BCs
    my $c=ones($D)*(1+$PCi); $c->(,(-1)).=0;
    my $d=-2*ones($D)*(1+$PCi);
    my $e=ones($D)*(1+$PCi); $e->(,(-1)).=0;
    my $b=ones($D)*(1-$PCi);
    my $info=pdl(short,0);
    cgtsv($c, $d, $e, $b, $info);
    my $x=sequence($D)+0*$PCi;
    my $r=(-$D/2-($D-1)/2*$x+1/2*$x*$x)*(1-$PCi)/(1+$PCi);
    ok($b->complex->approx($r)->all, "2nd diff. cgtsv in D=$D")
      or diag "info: ", $info, "\nGot: ", $b, "\nExpected: ", $r;
}

done_testing;
