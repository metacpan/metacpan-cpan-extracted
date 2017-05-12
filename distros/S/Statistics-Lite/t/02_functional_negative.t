#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok( 'Statistics::Lite', ':all' ); }

# basic functional interface continued: negative numbers

is(min(1,-5,8), -5, "call min with negative numbers" );
is(range(-6,-9), 3, "call range with negative values" );
is(range(6,-9), 15, "call range with data crossing 0" );

