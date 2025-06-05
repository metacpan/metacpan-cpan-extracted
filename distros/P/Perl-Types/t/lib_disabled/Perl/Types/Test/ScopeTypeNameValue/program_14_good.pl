#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::arrayref::hashref::string' => [{'arrayref::hashref::string' => [{'hashref::string' => {'g' => 'string','h' => 'string'}}]},{'arrayref::hashref::string' => [{'hashref::string' => {'mm' => 'string','n' => 'string'}}]},{'arrayref::hashref::string' => [{'hashref::string' => {'a' => 'string','b' => 'string'}}]}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::arrayref::hashref' => [{'arrayref::hashref::string' => [{'hashref::string' => {'g' => 'string','h' => 'string'}}]},{'arrayref::hashref::string' => [{'hashref::string' => {'mm' => 'string','n' => 'string'}}]},{'arrayref::hashref' => [{'hashref' => {'a' => 'string','b' => 'integer'}}]}]};" >>>

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
my arrayref $u = [
    [ { g => q{11},  h => '2' } ],
    [ { mm => '23.3', n => '1' } ],
    [ { a => '23',   b => '3' } ]
];
print Dumper( types($u) ) . "\n";

$u = [
    [ { g => q{11},  h => '2' } ],
    [ { mm => '23.3', n => '1' } ],
    [ { a => '23',   b => 3 } ]
];
print Dumper( types($u) ) . "\n";
