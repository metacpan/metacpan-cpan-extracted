#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR ENVAVRV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: 'number value expected but non-number value found at index 3' >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.000_001;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::TypeCheckingOn::AllTypes;

# [[[ OPERATIONS ]]]
my arrayref::number $input_1 = [ -999_999,         3.0,  4.0,  'howdy' ];
my arrayref::number $input_2 = [ -999_999,         3.0,  4.0,  -12.0 ];
my arrayref::number $input_3 = [ -999_999.123_456, 23.0, 42.0, -2112.0 ];
check_number_arrayrefs( $input_1, $input_2, $input_3 );
