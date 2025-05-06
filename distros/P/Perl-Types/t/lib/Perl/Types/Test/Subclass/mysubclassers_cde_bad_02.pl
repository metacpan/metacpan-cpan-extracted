#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'No such class Perl::Types::Test::Subclass::MySubclasserE_Good_hashrefd' >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::Subclass::MySubclassersCDE_Good;

# [[[ OPERATIONS ]]]
my Perl::Types::Test::Subclass::MySubclassersCDE_Good_arrayref $foo_a = [];
my Perl::Types::Test::Subclass::MySubclassersCDE_Good_hashref $foo_h = {};
my Perl::Types::Test::Subclass::MySubclasserC_Good_arrayref $bar_a = [];
my Perl::Types::Test::Subclass::MySubclasserC_Good_hashref $bar_h = {};
my Perl::Types::Test::Subclass::MySubclasserD_Good_arrayref $bat_a = [];
my Perl::Types::Test::Subclass::MySubclasserD_Good_hashref $bat_h = {};
my Perl::Types::Test::Subclass::MySubclasserE_Good_arrayref $baz_a = [];
my Perl::Types::Test::Subclass::MySubclasserE_Good_hashrefd $baz_h = {};
print 'no errors' . "\n";
