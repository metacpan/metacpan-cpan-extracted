#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: 'our hashref::integer $properties = {'some_integer' => 23};' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Types::Test::ScopeTypeNameValue::Class_00_Good;

# [[[ OPERATIONS ]]]

$Data::Dumper::Indent = 0;
print Perl::Types::Test::ScopeTypeNameValue::Class_00_Good::properties_stnv()
    . "\n";
