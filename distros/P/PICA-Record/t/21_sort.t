use strict;

use Test::More;
use PICA::Record;

my @tests = 
    map { PICA::Record->new($_) } 
    do { local $/; split /^-+$/ms, <DATA>; };

while (@tests) {
    my $given  = shift @tests;
    my $expect = shift @tests;

    is $given->sort->string, $expect->string;
}

done_testing;

__DATA__
101@ $a123
203@/02 $0543210
209A/01 $ajur
203@/01 $0123456
021A $abla
101@ $a12
208@/01 $a01-12-09
203@/01 $0666666
102A $0x$a11
---
021A $abla
101@ $a12
102A $0x$a11
203@/01 $0666666
208@/01 $a01-12-09
101@ $a123
203@/01 $0123456
209A/01 $ajur
203@/02 $0543210
----
021A $aHello
003@ $0123
101@ $a50$cPICA
144Z $axx
101@ $a20$cPICA
144Z $all
----
003@ $0123
021A $aHello
101@ $a20$cPICA
144Z $all
101@ $a50$cPICA
144Z $axx
