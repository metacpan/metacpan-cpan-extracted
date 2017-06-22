use warnings;
use strict;

use Test::More;

plan tests => 21;

use Perl6::Controls;

for my $n (1..10) {
    LAST { ok $n == 10 => 'OUTER LAST' }
    my $m = 1;
    while (1) {
        LAST { ok $m == 2 => 'INNER LAST'  }
        $m = 2;
        last;
    }
    ok $n > 0 => 'AFTER LAST';
}


done_testing();


