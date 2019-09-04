use 5.010001;
use strict;
use warnings;
use Test::Fatal;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 2; }

# --- Attempts to call with an unsupported arity -----------------------
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

ok eval { \&main::my_multi }, 'my_multi() exists';

like exception { my_multi; }, qr/No candidate.*arity 0/, 'arity 0';
like exception { my_multi(1,2,3); }, qr/No candidate.*arity 3/, 'arity 3';

done_testing;
