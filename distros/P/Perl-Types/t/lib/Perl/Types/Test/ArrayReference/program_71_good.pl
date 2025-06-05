#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_compact($array_1D) = [0.001_002,2,45_676.555_444_321,6,-8.01]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string($array_1D)         = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_pretty($array_1D)  = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_expand($array_1D)  =" >>>
# <<< EXECUTE_SUCCESS: "[" >>>
# <<< EXECUTE_SUCCESS: "    0.001_002," >>>
# <<< EXECUTE_SUCCESS: "    2," >>>
# <<< EXECUTE_SUCCESS: "    45_676.555_444_321," >>>
# <<< EXECUTE_SUCCESS: "    6," >>>
# <<< EXECUTE_SUCCESS: "    -8.01" >>>
# <<< EXECUTE_SUCCESS: "]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D, -2, 0) = [0.001_002,2,45_676.555_444_321,6,-8.01]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D, -1, 0) = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D,  0, 0) = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D,  1, 0) =" >>>
# <<< EXECUTE_SUCCESS: "[" >>>
# <<< EXECUTE_SUCCESS: "    0.001_002," >>>
# <<< EXECUTE_SUCCESS: "    2," >>>
# <<< EXECUTE_SUCCESS: "    45_676.555_444_321," >>>
# <<< EXECUTE_SUCCESS: "    6," >>>
# <<< EXECUTE_SUCCESS: "    -8.01" >>>
# <<< EXECUTE_SUCCESS: "]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D, -2, 1) = [0.001_002,2,45_676.555_444_321,6,-8.01]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D, -1, 1) = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D,  0, 1) = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ]" >>>
# <<< EXECUTE_SUCCESS: "have arrayref_number_to_string_format($array_1D,  1, 1) =" >>>
# <<< EXECUTE_SUCCESS: "    [" >>>
# <<< EXECUTE_SUCCESS: "        0.001_002," >>>
# <<< EXECUTE_SUCCESS: "        2," >>>
# <<< EXECUTE_SUCCESS: "        45_676.555_444_321," >>>
# <<< EXECUTE_SUCCESS: "        6," >>>
# <<< EXECUTE_SUCCESS: "        -8.01" >>>
# <<< EXECUTE_SUCCESS: "    ]" >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

my arrayref::number $array_1D = [ 0.001_002, 2, 45_676.555_444_321, 6, -8.01 ];

print 'have arrayref_number_to_string_compact($array_1D) = ', arrayref_number_to_string_compact($array_1D), "\n";
print 'have arrayref_number_to_string($array_1D)         = ', arrayref_number_to_string($array_1D), "\n";
print 'have arrayref_number_to_string_pretty($array_1D)  = ', arrayref_number_to_string_pretty($array_1D), "\n";
print 'have arrayref_number_to_string_expand($array_1D)  = ', "\n", arrayref_number_to_string_expand($array_1D), "\n";

print 'have arrayref_number_to_string_format($array_1D, -2, 0) = ', arrayref_number_to_string_format($array_1D, -2, 0), "\n";
print 'have arrayref_number_to_string_format($array_1D, -1, 0) = ', arrayref_number_to_string_format($array_1D, -1, 0), "\n";
print 'have arrayref_number_to_string_format($array_1D,  0, 0) = ', arrayref_number_to_string_format($array_1D, 0, 0), "\n";
print 'have arrayref_number_to_string_format($array_1D,  1, 0) = ', "\n", arrayref_number_to_string_format($array_1D, 1, 0), "\n";

print 'have arrayref_number_to_string_format($array_1D, -2, 1) = ', arrayref_number_to_string_format($array_1D, -2, 1), "\n";
print 'have arrayref_number_to_string_format($array_1D, -1, 1) = ', arrayref_number_to_string_format($array_1D, -1, 1), "\n";
print 'have arrayref_number_to_string_format($array_1D,  0, 1) = ', arrayref_number_to_string_format($array_1D, 0, 1), "\n";
print 'have arrayref_number_to_string_format($array_1D,  1, 1) = ', "\n", arrayref_number_to_string_format($array_1D, 1, 1), "\n";
