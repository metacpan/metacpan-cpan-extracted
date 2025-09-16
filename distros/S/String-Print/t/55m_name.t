#!/usr/bin/env perl
# Test the 'undef default' modifier

use warnings;
use strict;
use utf8;

use Test::More;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

### these are all examples from the manual page

is $f->sprinti("visitors: {count=}", count => 1), "visitors: count=1", 'simple';
is $f->sprinti("visitors: {count%05d =}", count => 2), "visitors: count=00002", 'stack';
is $f->sprinti("visitors: {count %-8,d =}X", count => 10_000), "visitors: count=10,000  X";

done_testing;
