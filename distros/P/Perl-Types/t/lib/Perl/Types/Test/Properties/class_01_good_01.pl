#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: '2' >>>
# <<< EXECUTE_SUCCESS: '3' >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.000_010;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::Properties::Class_01_Good;

# [[[ OPERATIONS ]]]
my Perl::Types::Test::Properties::Class_01_Good $test_object = Perl::Types::Test::Properties::Class_01_Good->new({});
print $test_object->{foo} . "\n";
print $test_object->{bar} . "\n";
