#!/usr/bin/env perl

use 5.008004;
use utf8;
use strict;
use warnings;


use Readonly;


use version; our $VERSION = qv('v0.999.3');


use TeamCity::BuildMessages qw< teamcity_escape >;


use Test::More;


## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash my %EXPECTED_FOR_INPUT => (
    q<blah>                         => q<blah>,
    qq< \n >                        => q< |n >,
    q< \n >                         => q< \n >,
    qq< \r >                        => q< |r >,
    q< \r >                         => q< \r >,
    q< ' >                          => q< |' >,
    q< | >                          => q< || >,
    q< ] >                          => q< |] >,
    qq< foo \r\n 'bar' | [ baz ] >  => q< foo |r|n |'bar|' || [ baz |] >,
);
## use critic

plan tests => scalar keys %EXPECTED_FOR_INPUT;


foreach my $input (sort keys %EXPECTED_FOR_INPUT) {
    my $expected = $EXPECTED_FOR_INPUT{$input};

    is( teamcity_escape($input), $expected, qq<teamcity_escape('$input')> );
} # end foreach


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
