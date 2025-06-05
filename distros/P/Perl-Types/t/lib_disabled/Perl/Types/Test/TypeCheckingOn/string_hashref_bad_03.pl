#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EHVRVPV03, TYPE-CHECKING MISMATCH' >>>
# <<< EXECUTE_ERROR: "string value expected but non-string value found at key 'd'" >>>

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
check_hashref_string( { a => 'hello', b => 'howdy', c => 'ahoy', d => { a => 0, b => 1, c => 2 } } );
