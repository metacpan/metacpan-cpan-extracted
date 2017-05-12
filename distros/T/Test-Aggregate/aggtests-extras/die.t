#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

ok 1, "$0 ***** 1";

die "Ensure exceptions are not hidden during aggregate tests";

done_testing();
