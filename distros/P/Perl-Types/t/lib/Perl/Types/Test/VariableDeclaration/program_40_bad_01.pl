#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< GENERATE_ERROR: 'P020, CODE GENERATOR, ABSTRACT SYNTAX TO' >>>
# <<< GENERATE_ERROR: "'Perl::Types' type is different than 'Perl::Types::Test' constructor type" >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Types::Test;

# [[[ OPERATIONS ]]]

my Perl::Types $foo = Perl::Types::Test->new();

