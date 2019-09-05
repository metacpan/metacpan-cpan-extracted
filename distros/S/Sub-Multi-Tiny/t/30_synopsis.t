use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

{
    package main::my_multi;     # We're making main::my_multi()
    use Sub::Multi::Tiny qw($foo $bar);    # All possible params

    sub first :M($foo, $bar) { # sub's name will be ignored
        return $foo ** $bar;
    }

    sub second :M($foo) {
        return $foo + 42;
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

cmp_ok my_multi(2, 5), '==', 32, 'two-parameter';
cmp_ok my_multi(5, 2), '==', 25, 'two-parameter, checking arg order';
cmp_ok my_multi(1337), '==', 1379, 'one-parameter';

done_testing;
