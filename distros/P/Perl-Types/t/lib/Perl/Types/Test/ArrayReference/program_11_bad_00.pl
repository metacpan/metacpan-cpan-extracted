#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  ]' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

# homogeneous 2-dimensional array of arrays, using outer type
my arrayref::arrayref::integer $array_array = [ [ 17, -23, 1_701 ], [ -1, 444, 2_987 ], [ -321, 7, 24_851 ], ];
