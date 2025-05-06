#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: 'MODE_ID = 0' >>>
# <<< EXECUTE_SUCCESS: "ops = 'PERL'" >>>
# <<< EXECUTE_SUCCESS: "types = 'PERL'" >>>

# [[[ HEADER ]]]
use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.000_010;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Class::Template;

# [[[ OPERATIONS ]]]

#print '%main:: = ', "\n", Dumper( \%main:: ), "\n";

print 'MODE_ID = ', Perl::Types__CompileUnit__Module__Class__CPP__Template__MODE_ID(), "\n";
print q{ops = '}, $Perl::Types::MODES->{Perl::Types__CompileUnit__Module__Class__CPP__Template__MODE_ID()}->{ops}, q{'}, "\n";
print q{types = '}, $Perl::Types::MODES->{Perl::Types__CompileUnit__Module__Class__CPP__Template__MODE_ID()}->{types}, q{'}, "\n";
