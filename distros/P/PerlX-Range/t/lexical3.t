#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use PerlX::Range;
use Test::More;

{
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

package TestPerlXRangeLexical;
no PerlX::Range;

sub test_range_ref {
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

package main;
use PerlX::Range;
{
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

done_testing;
