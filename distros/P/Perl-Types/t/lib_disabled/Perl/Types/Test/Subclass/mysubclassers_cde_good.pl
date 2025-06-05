#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: 'no errors' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use Perl::Types::Test::Subclass::MySubclassersCDE_Good;

# [[[ OPERATIONS ]]]
my arrayref::Perl::Types::Test::Subclass::MySubclassersCDE_Good $foo_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclassersCDE_Good $foo_h = {};
my arrayref::Perl::Types::Test::Subclass::MySubclasserC_Good $bar_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclasserC_Good $bar_h = {};
my arrayref::Perl::Types::Test::Subclass::MySubclasserD_Good $bat_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclasserD_Good $bat_h = {};
my arrayref::Perl::Types::Test::Subclass::MySubclasserE_Good $baz_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclasserE_Good $baz_h = {};
print 'no errors' . "\n";
