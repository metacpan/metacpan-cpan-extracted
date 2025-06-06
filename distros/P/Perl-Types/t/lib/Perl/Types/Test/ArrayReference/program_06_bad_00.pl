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

my arrayref::string $s_array_0 = [ 'a', 'b', 'c' ];
my arrayref::string $s_array_1 = [ 'd', 'e', 'f' ];
my arrayref::string $s_array_2 = [ 'g', 'h', 'i' ];
my arrayref::string $s_array_all = [ @{$s_array_0}, 'howdy' x 3, @{$s_array_1}, 'doody' x 2, @{$s_array_2}, ];
