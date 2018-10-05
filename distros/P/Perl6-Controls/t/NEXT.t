use warnings;
use strict;

use Test::More;

plan tests => 47;

use Perl6::Controls;


for my $n (1..10) {
    LEAVE { ok $n <= 10 => "OUTER LEAVE n=$n" }
    my $m = 1;
    while (1) {
        LEAVE { ok $m <= 3 => "INNER LEAVE m=$m" }
        $m++;
        last if $m > 2
    }
    ok $n > 0 => 'AFTER LEAVE';
}

sub foo {
    my ($arg, $expect) = @_;
    LEAVE { is $arg, $expect, "LEAVE foo() expect=$expect" }

    if ($arg < 10) { $arg *= 2; return }
    $arg += 100;
    if ($arg < 200) { return }
    $arg = 1000;
    die;
}

sub bar {
    LEAVE { pass 'Fell out of bar()' }
}

foo(1,2);
foo(2,4);
foo(9,18);
foo(10,110);
foo(99,199);
eval{ foo(100,1000) };

bar();


done_testing();



