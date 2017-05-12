#!perl -w

use strict;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 1;

my @import = qw(
    is_numeric
    is_float
    is_decimal
    is_integer
    is_int
    is_int8
    is_int16
    is_int32
    is_int64
    is_int128
    is_uint
    is_uint8
    is_uint16
    is_uint32
    is_uint64
    is_uint128
);

BEGIN {
    use_ok('String::Numeric', @import);
}


