#!/usr/bin/env perl
# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

foreach my integer $i (
    @{ my arrayref::integer $TYPED_i_array = [ 10, 20, 30, 40, 50 ] } )
{
    print '$i = ', $i, "\n";
}
