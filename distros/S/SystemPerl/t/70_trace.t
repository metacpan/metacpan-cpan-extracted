#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;
use Config;
use Cwd;

BEGIN { plan tests => 3 }
BEGIN { require "t/test_utils.pl"; }

# We need 8GB on this file system
our $Large_Temp_Dir = "/local/test_dir";

print "Building example...\n";
if ($Config{archname} !~ /linux/) {
    # Test doesn't need SystemC
    print "Skipping: Harmless; Not linux\n";
    skip("skip Harmless; Not linux",1);
    skip("skip Harmless; Not linux",1);
    skip("skip Harmless; Not linux",1);
} else {
    run_system ("cd test_dir "
		."&& g++ -ggdb -D_LARGEFILE64_SOURCE -DSPTRACEVCD_TEST ../src/SpTraceVcdC.cpp -o SpTraceVcdC "
		."&& ./SpTraceVcdC");
    ok(1);
    ok(-r "test_dir/test.vcd");
    if (!$ENV{SPTRACEVCD_TEST_64BIT}) {
	skip("skip Harmless; SPTRACEVCD_TEST_64BIT not set - note this test makes a >4GB file!",1);
    } else {
	my $cwd = getcwd();
	system("mkdir -p $Large_Temp_Dir");
	run_system ("cd test_dir "
		    ."&& g++ -m32 -ggdb -D_LARGEFILE64_SOURCE -DSPTRACEVCD_TEST -DSPTRACEVCD_TEST_64BIT ../src/SpTraceVcdC.cpp -o SpTraceVcdC ");
	run_system ("cd $Large_Temp_Dir "
		    ."&& $cwd/test_dir/SpTraceVcdC");
	run_system ("ls -la $Large_Temp_Dir");
	ok(-s "$Large_Temp_Dir/test.vcd");
	unlink("$Large_Temp_Dir/test.vcd");
    }
}
