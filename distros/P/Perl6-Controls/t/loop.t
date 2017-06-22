use warnings;
use strict;

use Test::More;

plan tests => 10;

use Perl6::Controls;

my $n = 0;
loop {
    $n++;
    last if $n > 9;
    ok 1 => 'loop'
}

ok $n == 10 => 'done';

done_testing();




