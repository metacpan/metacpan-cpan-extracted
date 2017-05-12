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

use Test::More tests=>1;

my $modrep = $EXTRA_MODULE_REPORT;
$modrep =~ s/^/    /mg;
diag $modrep;

if ($HAVE_ALL_EXTRAS) {
	diag '--> OK, will be able to fully test Shell::Tools::Extra';
}
elsif ($HAVE_REQUIRED_EXTRAS) {
	diag '--> Will be able to test Shell::Tools::Extra WITHOUT some/all optional modules';
}
else {
	diag '--> WARNING: Will NOT be able to test Shell::Tools::Extra !';
}

BAIL_OUT 'All extra modules are required during author testing'
	if $AUTHOR_TESTS && !$HAVE_ALL_EXTRAS;

ok 1, 'extra module report';

