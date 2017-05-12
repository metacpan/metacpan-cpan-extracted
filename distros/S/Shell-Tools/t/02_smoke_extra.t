#!/usr/bin/env perl
use warnings;
use strict;

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

use FindBin ();
use lib $FindBin::Bin;
use Shell_Tools_Testlib;

use Test::More $HAVE_REQUIRED_EXTRAS ? (tests=>5)
	: (skip_all=>'not all extra modules are installed');

BEGIN {
	use_ok 'Shell::Tools::Extra';
}
is $Shell::Tools::Extra::VERSION, '0.04', 'version matches tests';

# check Shell::Tools exports, since Shell::Tools::Extra is supposed to export those too
ok defined(&tempfile), 'tempfile (File::Temp) present';
my ($fh, $fn) = tempfile(UNLINK=>1);
close $fh or fail "problem closing temp file: $!";
ok -f $fn, 'tempfile file was created';

try { croak "FooBar" }
catch {
	like $_, qr/^FooBar/, "Try::Tiny present and working";
};

