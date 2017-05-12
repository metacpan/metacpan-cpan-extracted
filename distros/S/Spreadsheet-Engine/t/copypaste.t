#!/usr/bin/perl

use strict;
use warnings;
use lib ('lib', 't/lib');

use SheetTest;
use Test::More 'no_plan';

run_tests();

__DATA__
set A1 value n 2
set A2 value n 3
set A3 value n 4
copy A1:A3 all
paste A4:A6 all
recalc
test A3 4
test A4 2
test A5 3
test A6 4
