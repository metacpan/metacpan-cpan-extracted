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

my arrayref::integer $i_array = [ 17, 23, 42, 1_701, 2_112 ];
foreach my integer $i ( @{$i_array} ) {
    print '$i = ', $i, "\n";
}

print 'have arrayref_integer_to_string_compact($i_array) = ', "\n", arrayref_integer_to_string_compact($i_array), "\n";

print 'have arrayref_integer_to_string($i_array) = ', "\n", arrayref_integer_to_string($i_array), "\n";

print 'have arrayref_integer_to_string_pretty($i_array) = ', "\n", arrayref_integer_to_string_pretty($i_array), "\n";

print 'have arrayref_integer_to_string_expand($i_array) = ', "\n", arrayref_integer_to_string_expand($i_array), "\n";

