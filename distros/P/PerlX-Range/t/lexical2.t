#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use Test::More;

use PerlX::Range;
use TestPerlXRangeLexical;

{
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

ok(TestPerlXRangeLexical::test_range_ref());

done_testing;
