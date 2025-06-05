#!/usr/bin/env perl

# Learning Perl::Types, Section 3.5: 2-D Array Data Types & Nested Arrays

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "have $row_3_column_0_combined = 9" >>>
# <<< EXECUTE_SUCCESS: "have $row_3 = [ 9, 8, 7, 6, 5 ]" >>>
# <<< EXECUTE_SUCCESS: "have $row_3_column_0_separated = 9" >>>

# [[[ HEADER ]]]
#use perltypes;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

# fine in Perl::Types, multiple rows and columns on multiple lines
my arrayref::arrayref::integer $rows_and_columns_2D = [
    [ 0, 2, 4, 6, 8 ],
    [ 1, 3, 5, 7, 9 ],
    [ 4, 3, 2, 1, 0 ],
    [ 9, 8, 7, 6, 5 ],
    [ 5, 5, 5, 5, 5 ],
    [ 0, 2, 4, 6, 8 ],
    [ 1, 3, 5, 7, 9 ],
    [ 4, 3, 2, 1, 0 ],
    [ 9, 8, 7, 6, 5 ],
    [ 5, 5, 5, 5, 5 ]
];

my arrayref::arrayref::integer $rows_and_columns_1D = [
    0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1,
    3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9
];
my arrayref::arrayref::integer $rows_and_columns_xD = [
    [   0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1,
        3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, 1, 3, 5, 7, 9
    ]
];

my integer $row_3_column_0_combined = $rows_and_columns_2D->[3]->[0];    # row and column dereferences, combined in one statement
print 'have $row_3_column_0_combined = ', $row_3_column_0_combined, "\n";

my arrayref::integer $row_3 = $rows_and_columns_2D->[3];                  # row dereference only
print 'have $row_3 = ', arrayref_integer_to_string($row_3), "\n";
my integer $row_3_column_0_separated = $row_3->[0];                      # column dereference only
print 'have $row_3_column_0_separated = ', $row_3_column_0_separated, "\n";
