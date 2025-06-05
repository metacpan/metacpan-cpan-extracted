#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::object' => [{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::object' => [{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref' => [{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleB','drup' => 'integer'}}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref::object' => [{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}]};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'arrayref' => [{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleB','drup' => 'integer'}},{'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}]};" >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Types::Test::SimpleA;
use Perl::Types::Test::SimpleB;

# [[[ OPERATIONS ]]]

$Data::Dumper::Indent = 0;
my arrayref $u = [ Perl::Types::Test::SimpleA->new() ];
print Dumper( types($u) ) . "\n";

$u = [ Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleA->new() ];
print Dumper( types($u) ) . "\n";
$u = [ Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleB->new() ];
print Dumper( types($u) ) . "\n";

$u = [
    Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleA->new(),
    Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleA->new(),
    Perl::Types::Test::SimpleA->new()
];
print Dumper( types($u) ) . "\n";

$u = [
    Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleA->new(),
    Perl::Types::Test::SimpleA->new(), Perl::Types::Test::SimpleB->new(),
    Perl::Types::Test::SimpleA->new()
];
print Dumper( types($u) ) . "\n";
