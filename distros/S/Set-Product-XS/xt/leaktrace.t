use strict;
use warnings;
use Test::More;
use Set::Product::XS qw(product);

BEGIN {
    eval "use Test::LeakTrace; 1" or do {
        plan skip_all => 'Test::LeakTrace is not installed.';
    };
}

no_leaks_ok {
    product { my $v = 1 } [1,2], [3,4];
} 'vars leaking outside scope of code block';

no_leaks_ok {
    product { } [1,2], [3,4]
} 'vals leaking from @_';

no_leaks_ok {
    eval { product { die } [1,2], [3,4] };
} 'die in block causes leak';

done_testing;
