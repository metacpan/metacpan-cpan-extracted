#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR ECOOOCO02' >>>
# <<< EXECUTE_ERROR: 'Attempted initialization of invalid property' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.000_010;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::Properties::Class_01_Good;

# [[[ OPERATIONS ]]]
my Perl::Types::Test::Properties::Class_01_Good $test_object = Perl::Types::Test::Properties::Class_01_Good->new({ fop => 200 });
print $test_object->{foo} . "\n";
print $test_object->{bar} . "\n";
