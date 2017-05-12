use warnings;
use strict;

use Test::More tests => 14;

our $t = "abcdefghijkl";

use String::Base +3;

is index($t, "cdef"), 5;
is index($t, "cdef", 3), 5;
is index($t, "cdef", 4), 5;
is index($t, "cdef", 5), 5;
is index($t, "cdef", 6), 2;
is index($t, "cdef", 7), 2;

is rindex($t, "cdef"), 5;
is rindex($t, "cdef", 3), 2;
is rindex($t, "cdef", 4), 2;
is rindex($t, "cdef", 5), 5;
is rindex($t, "cdef", 6), 5;
is rindex($t, "cdef", 7), 5;

$t .= $t;
is index($t, "cdef"), 5;
is rindex($t, "cdef"), 17;

1;
