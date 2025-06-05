#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref::arrayref::string' => {'a' => {'arrayref::string' => ['string','string']},'b' => {'arrayref::string' => ['string','string']},'c' => {'arrayref::string' => ['string','string']}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref::arrayref' => {'a' => {'arrayref::string' => ['string','string']},'b' => {'arrayref::string' => ['string','string']},'c' => {'arrayref' => ['string','integer']}}};" >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OPERATIONS ]]]

$Data::Dumper::Indent = 0;
my hashref $u = { a => [ q{11}, '2' ], b => [ '23.3', '1' ], c => [ '23', '3' ] };
print Dumper( types($u) ) . "\n";

$u = { a => [ q{11}, '2' ], b => [ '23.3', '1' ], c => [ '23', 3 ] };
print Dumper( types($u) ) . "\n";
