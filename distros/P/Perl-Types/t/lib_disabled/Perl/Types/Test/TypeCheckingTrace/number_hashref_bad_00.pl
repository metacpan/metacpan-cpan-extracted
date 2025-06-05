#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EHVRVNV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: "number value expected but non-number value found at key 'd'" >>>
# <<< EXECUTE_ERROR: 'in variable $input_1 from subroutine check_hashref_number()' >>>

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
check_hashref_number( { a => -999_999, b => 3, c => 4, d => 'howdy' } );
