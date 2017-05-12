#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;

use PerlX::Range;
{
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

no PerlX::Range;
{
    my @a = (1..10);
    is(scalar(@a), 10);
    is(ref($a[0]), "");
}

use PerlX::Range;
{
    my @a = (1..10);
    is(scalar(@a), 1);
    is(ref($a[0]), "PerlX::Range");
}

done_testing;
