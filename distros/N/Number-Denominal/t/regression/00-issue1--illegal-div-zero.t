#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Number::Denominal;

###
### This is a regression test for Issue #1: Illegal Division by Zero fatal
### https://github.com/zoffixznet/Number-Denominal/issues/1
###

my @failing_values = 697271 .. 697525;

local $@;
for ( @failing_values ) {
    eval { denominal( $_, \'time', { precision => 1 } ); 1; };
    $@ and BAIL_OUT "[$_]; Got fatal error: $@";
}

ok(1);
done_testing();