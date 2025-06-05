#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  }' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

my hashref::string $s_hash_0 = { alpha => 'a', bravo => 'b', charlie => 'c' };
my hashref::string $s_hash_1 = { delta => 'd', echo => 'e', foxtrot => 'f' };
my hashref::string $s_hash_2 = { golf => 'g', hotel => 'h', india => 'i' };
my hashref::string $s_hash_all = { subhash_0 => $s_hash_0, subhash_1 => $s_hash_1, subhash_2 => $s_hash_2, };
print Dumper($s_hash_all);
