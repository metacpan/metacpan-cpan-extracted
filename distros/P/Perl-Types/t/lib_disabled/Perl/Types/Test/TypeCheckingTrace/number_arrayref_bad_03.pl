#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EAVRVNV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: 'number value expected but non-number value found at index 3' >>>
# <<< EXECUTE_ERROR: 'in variable $input_1 from subroutine check_arrayref_number()' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.000_001;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::TypeCheckingTrace::AllTypes;

# [[[ OPERATIONS ]]]
check_arrayref_number( [ -999_999, 3, 4, { a => 0, b => 1, c => 2 } ] );
