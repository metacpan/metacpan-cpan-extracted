#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 3;

use POSIX::1003::Math qw(sin floor FLT_MAX);

# simply from core
cmp_ok(sin(2), '<', 2, 'sin');

# function from POSIX.xs
cmp_ok(floor(3.14), '==', 3.0, 'floor');

# constant from POSIX.xs
cmp_ok(FLT_MAX, '>', 1000, 'FLT_MAX='.FLT_MAX);

use POSIX::1003::Math;  # load all
