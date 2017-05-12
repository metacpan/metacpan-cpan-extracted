#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2014 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;
use Config;

BEGIN { plan tests => 1 }
BEGIN { require "t/test_utils.pl"; }

my @files = glob("src/*.h src/*.cpp");

print "Test every file can get compiled independently\n";
if ($Config{archname} !~ /linux/
    || (!$ENV{SYSTEMC} && !$ENV{SYSTEMC_INCLUDE})) {
    skip("skip Harmless; Not linux or missing SystemC",1);
} elsif (!$ENV{VERILATOR_AUTHOR_SITE}) {
    skip("author only test (harmless)",1);
} else {
    my @objs;
    foreach my $file (@files) {
	$file =~ s!.*/!!;
	(my $basename = $file) =~ s!\.[a-z]*$!!;
	if ($file =~ m!\.h!) {
	    my $c = "$basename-inc.cpp";
	    my $fh = IO::File->new(">test_dir/$c") or die "%Error: $! writing test_dir/$c,";
	    print $fh qq{#include "$file"\n};
	    print $fh qq{void boo() {}\n};
	    $fh->close;
	    push @objs, "$basename-inc.o";
	} else {
	    push @objs, "$basename.o";
	}
    }
    # Run all targets at once, so can parallelize
    run_system ("cd test_dir && make -j 3 -f ../example/Makefile_obj ".join(' ',@objs));
    ok (1);
}

1;
