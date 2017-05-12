#!/usr/bin/env perl
# NO warnings and strict since that's what we're testing
## no critic (RequireUseWarnings, RequireUseStrict)

# Tests for the Perl module Shell::Tools
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use Shell::Tools;

# first, when *only* Shell::Tools is imported, warnings & strict should be on
# and FindBin should be loaded

my @warn;
BEGIN {
	local $SIG{__WARN__} = sub { push @warn, shift };
	my $x = 0 + undef;
}

my @strict;
BEGIN {
	eval { my $x = ${"foo"}; };  ## no critic (RequireCheckingReturnValueOfEval)
	push @strict, $@;
}

my $script;
BEGIN { $script = $FindBin::Script }

# ok, *now* load Test::More and check the results of the above

use Test::More tests=>5;

is @warn, 1, 'correct nr. of warns';
like $warn[0], qr/\bUse of uninitialized value\b/i, 'warn 1 correct';

is @strict, 1, 'correct nr. of strict errors';
like $strict[0], qr/\bCan't use string.*? as a SCALAR ref/i, 'strict err 1 correct';

is $script, '20_warn_strict_findbin.t', '$FindBin::Script is correct';

