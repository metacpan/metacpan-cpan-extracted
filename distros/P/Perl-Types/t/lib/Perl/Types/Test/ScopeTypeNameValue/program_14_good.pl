#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref_hashref_string_arrayref' => [{'arrayref_hashref_string' => [{'string_hashref' => {'g' => 'string','h' => 'string'}}]},{'arrayref_hashref_string' => [{'string_hashref' => {'mm' => 'string','n' => 'string'}}]},{'arrayref_hashref_string' => [{'string_hashref' => {'a' => 'string','b' => 'string'}}]}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref_arrayref_arrayref' => [{'arrayref_hashref_string' => [{'string_hashref' => {'g' => 'string','h' => 'string'}}]},{'arrayref_hashref_string' => [{'string_hashref' => {'mm' => 'string','n' => 'string'}}]},{'hashref_arrayref' => [{'hashref' => {'a' => 'string','b' => 'integer'}}]}]};" >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
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
