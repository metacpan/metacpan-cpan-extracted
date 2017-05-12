#! perl -w

use strict;
use warnings;

use Test::More tests => 10;

pass() for 1 .. 9;
is( 'foo', 'bar', 'no, it is not' );
