#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EAVRVNV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: 'number value expected but non-number value found at index 1' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.000_001;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::TypeCheckingOn::AllTypes;

# [[[ OPERATIONS ]]]
my arrayref::number $input_1 = [ -999_999,         3.0,      4.0,  12.0 ];
my arrayref::number $input_2 = [ -999_999,         3.0,      4.0,  -12.0 ];
my arrayref::number $input_3 = [ -999_999.123_456, "23.0\n", 42.0, -2112.0 ];
check_arrayref_number_multiple( $input_1, $input_2, $input_3 );
