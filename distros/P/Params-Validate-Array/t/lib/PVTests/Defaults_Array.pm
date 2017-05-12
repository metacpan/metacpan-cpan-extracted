package PVTests::Defaults_Array;

use strict;
use warnings;

use Params::Validate::Array qw(:all);

use PVTests;
use Test::More;

sub run_tests {
    {
        my %def = eval { foo() };

        is(
            $@, q{},
            'No error calling foo()'
        );

        is(
            $def{a}, 1,
            q|Parameter 'a' was not altered|
        );

        is(
            $def{b}, 2,
            q|Parameter 'b' was not altered|
        );

        is(
            $def{c}, 42,
            q|Correct default assigned for parameter 'c'|
        );

        is(
            $def{d}, 0,
            q|Correct default assigned for parameter 'd'|
        );
    }

    {
        my $def = eval { foo() };

        is(
            $@, q{},
            'No error calling foo()'
        );

        is(
            $def->{a}, 1,
            q|Parameter 'a' was not altered|
        );

        is(
            $def->{b}, 2,
            q|Parameter 'b' was not altered|
        );

        is(
            $def->{c}, 42,
            q|Correct default assigned for parameter 'c'|
        );

        is(
            $def->{d}, 0,
            q|Correct default assigned for parameter 'd'|
        );
    }

    done_testing();
}

sub foo {
    my @params = ( a => 1, b => 2 );
    return validate(
        @params, {
            a => 1,
            b => { default => 99 },
            c => { optional => 1, default => 42 },
            d => { default => 0 },
        }
    );
}

1;
##### SUBROUTINE INDEX #####
#                          #
#   gen by index_subs.pl   #
#   on 24 Feb 2014 20:54   #
#                          #
############################


####### Packages ###########

# PVTests::Defaults_Array ............ 1
#   foo .............................. 2
#   run_tests ........................ 1

