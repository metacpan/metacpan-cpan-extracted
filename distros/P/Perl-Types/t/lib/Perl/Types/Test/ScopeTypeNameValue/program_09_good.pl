#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: "$VAR1 = {'object_hashref' => {'a' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'object_hashref' => {'a' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'b' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref' => {'a' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'b' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleB','drup' => 'integer'}}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'object_hashref' => {'a' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'b' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'c' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'d' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'e' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}}};" >>>
# <<< EXECUTE_SUCCESS: "$VAR1 = {'hashref' => {'a' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'b' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'c' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}},'d' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleB','drup' => 'integer'}},'e' => {'object' => {'__CLASS' => 'Perl::Types::Test::SimpleA','purd' => 'integer'}}}};" >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Types::Test::SimpleA;
use Perl::Types::Test::SimpleB;

# [[[ OPERATIONS ]]]

$Data::Dumper::Indent = 0;
my hashref $u = { a => Perl::Types::Test::SimpleA->new() };
print Dumper( types($u) ) . "\n";

$u = { a => Perl::Types::Test::SimpleA->new(), b => Perl::Types::Test::SimpleA->new() };
print Dumper( types($u) ) . "\n";

$u = { a => Perl::Types::Test::SimpleA->new(), b => Perl::Types::Test::SimpleB->new() };
print Dumper( types($u) ) . "\n";

$u = {
    a => Perl::Types::Test::SimpleA->new(),
    b => Perl::Types::Test::SimpleA->new(),
    c => Perl::Types::Test::SimpleA->new(),
    d => Perl::Types::Test::SimpleA->new(),
    e => Perl::Types::Test::SimpleA->new()
};
print Dumper( types($u) ) . "\n";

$u = {
    a => Perl::Types::Test::SimpleA->new(),
    b => Perl::Types::Test::SimpleA->new(),
    c => Perl::Types::Test::SimpleA->new(),
    d => Perl::Types::Test::SimpleB->new(),
    e => Perl::Types::Test::SimpleA->new()
};
print Dumper( types($u) ) . "\n";
