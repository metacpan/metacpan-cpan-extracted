#!perl -w
use strict;
use Test;
BEGIN { plan tests => 2 };

`$^X t/djbish.plx 1< t/djbish.plx`;
ok($? >> 8, 20);

`./pperl -Mlib=blib/lib,blib/arch t/djbish.plx 1< t/djbish.plx`;
ok($? >> 8, 20);

`./pperl -k t/djbish.plx`;
