#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::arrayref::string' => [{'arrayref::string' => ['string','string']},{'arrayref::string' => ['string','string']},{'arrayref::string' => ['string','string']}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::arrayref' => [{'arrayref::string' => ['string','string']},{'arrayref::string' => ['string','string']},{'arrayref' => ['string','integer']}]};" >>>

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
my arrayref $u = [ [ q{11}, '2' ], [ '23.3', '1' ], [ '23', '3' ] ];
print Dumper( types($u) ) . "\n";

$u = [ [ q{11}, '2' ], [ '23.3', '1' ], [ '23', 3 ] ];
print Dumper( types($u) ) . "\n";
