use warnings;
use strict;

use Test::More;

plan tests => 21;

use Perl6::Controls;

for my $n (1..10) {
    FIRST { ok $n == 1 => 'OUTER FIRST' }
    while (1) {
        FIRST { ok $n > 0 => 'INNER FIRST'  }
        last;
    }
    ok $n > 0 => 'AFTER FIRST';
}


done_testing();

