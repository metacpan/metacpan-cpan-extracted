#!/usr/bin/env perl

# Learning Perl::Types, Section 3.1: Lists vs Arrays

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$variable_storing_array_by_reference = [ 'list', 'enclosed', 'within', 'square', 'brackets' ]" >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

my arrayref::string $variable_storing_array_by_reference = ['list', 'enclosed', 'within', 'square', 'brackets'];
print '$variable_storing_array_by_reference = ', arrayref_string_to_string($variable_storing_array_by_reference), "\n";
