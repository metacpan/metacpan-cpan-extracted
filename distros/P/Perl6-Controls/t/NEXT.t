use warnings;
use strict;

use Test::More;

plan tests => 30;

use Perl6::Controls;


for my $n (1..10) {
    NEXT { ok $n <= 10 => 'OUTER NEXT' }
    my $m = 1;
    while (1) {
        NEXT { ok $m <= 2 => 'INNER NEXT'  }
        $m++;
        last if $m > 2
    }
    ok $n > 0 => 'AFTER NEXT';
}


done_testing();



