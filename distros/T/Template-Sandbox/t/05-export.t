#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox qw/:function_sugar/;

my ( @function_sugar );

@function_sugar = qw(
            inconstant
            needs_template
            undef_ok
            has_args no_args
            one_arg two_args three_args any_args
            );

plan tests => scalar( @function_sugar );

foreach my $exported ( @function_sugar )
{
    ok( exists( ${main::}{ $exported } ), "function $exported exported" );
}

#  TODO:  test def_func
