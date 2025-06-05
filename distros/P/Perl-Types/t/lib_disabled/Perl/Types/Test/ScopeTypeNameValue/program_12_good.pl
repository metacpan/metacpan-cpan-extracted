#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref::hashref::string' => {'x' => {'hashref::string' => {'a' => 'string','b' => 'string'}},'y' => {'hashref::string' => {'mm' => 'string','n' => 'string'}},'z' => {'hashref::string' => {'g' => 'string','h' => 'string'}}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref::hashref' => {'x' => {'hashref' => {'a' => 'string','b' => 'integer'}},'y' => {'hashref::string' => {'mm' => 'string','n' => 'string'}},'z' => {'hashref::string' => {'g' => 'string','h' => 'string'}}}};" >>>

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
my hashref $u = { z => { g => q{11}, h => '2' }, y => { mm => '23.3', n => '1' }, x => { a => '23', b => '3' } };
print Dumper( types($u) ) . "\n";

$u = { z => { g => q{11}, h => '2' }, y => { mm => '23.3', n => '1' }, x => { a => '23', b => 3 } };
print Dumper( types($u) ) . "\n";
