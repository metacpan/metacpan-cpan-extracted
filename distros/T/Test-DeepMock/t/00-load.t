#!perl -T
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::DeepMock' );
}
