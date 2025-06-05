#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EAVRVPV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: 'string value expected but non-string value found at index 3' >>>
# <<< EXECUTE_ERROR: 'in variable $input_1 from subroutine check_arrayref_string()' >>>

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
check_arrayref_string( [ 'hello', 'howdy', 'ahoy', -999_999.123_456 ] );
