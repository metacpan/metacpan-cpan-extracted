use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

# Simple recursion, where each candidate dispatches to a specific
# other candidate.
{
    package main::pascal;   # Pascal's triangle
    use Sub::Multi::Tiny qw($n $k);

    sub main :M($n, $k) { # sub's name will be ignored
        return 1 if $k==0 || $k==$n;
        return pascal($n-1, $k-1) + pascal($n-1, $k);
    }

    sub base :M($n) {
        return pascal($n, $n);
    }

}

ok do { no strict 'refs'; defined *{"main::pascal"}{CODE} }, 'pascal() exists';
ok do { no strict 'refs'; !defined *{"main::nonexistent"}{CODE} }, 'sanity check';

cmp_ok pascal(1), '==', 1, '(1) - delegates to (1,1)';
cmp_ok pascal(2), '==', 1, '(2) - delegates to (2,2)';
cmp_ok pascal(3, 1), '==', 3, '(3,1)';
cmp_ok pascal(4, 4), '==', 1, '(4,4)';

done_testing;
