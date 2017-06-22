use warnings;
use strict;

use Test::More;

use Perl6::Controls;

my $n;

$n = 0;
repeat { $n++ } until $n > 10;
ok $n > 10 => 'repeat...until';

$n = 0;
repeat until $n > 10 { $n++ }
ok $n > 10 => 'repeat until...';

$n = 0;
repeat { $n++ } while $n < 10;
ok $n == 10 => 'repeat...while';

$n = 0;
repeat while $n < 10 { $n++ }
ok $n == 10 => 'repeat while...';

done_testing();

