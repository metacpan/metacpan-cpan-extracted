#!/usr/bin/env perl

# Script that runs the whole test suite for pbs.

use strict;
use warnings;

use Test::Harness '&runtests', '$verbose';

my $verbose_level = undef;
if ($#ARGV == -1) {
    $verbose_level = 1;
} elsif ($#ARGV == 0) {
    if ($ARGV[0] eq '--help') {
	print "$0: Run the whole test suite for pbs\n";
	print "\n";
	print "Options: --help\t\tPrint this message.\n";
	print "         --v0\t\tSet verbosity level 0\n";
	print "         --v1\t\tSet verbosity level 1 (default)\n";
	print "         --v2\t\tSet verbosity level 2\n";
    } elsif ($ARGV[0] eq '--v0') {
	$verbose_level = 0;
    } elsif ($ARGV[0] eq '--v1') {
	$verbose_level = 1;
    } elsif ($ARGV[0] eq '--v2') {
	$verbose_level = 2;
    } else {
	print "Error: unknown argument.\n";
        print "Run '$0 --help' for help.\n";
    }
} elsif ($#ARGV >= 1) {
    print "Error: wrong number of arguments.\n";
    print "Run '$0 --help' for help.\n";
}

if (defined $verbose_level) {
    if ($verbose_level == 0) {
	$verbose = 0;
	$ENV{"TEST_VERBOSE"} = 0;
    } elsif ($verbose_level == 1) {
	$verbose = 0;
	$ENV{"TEST_VERBOSE"} = 1;
    } elsif ($verbose_level == 2) {
	$verbose = 1;
	$ENV{"TEST_VERBOSE"} = 1;
    }
    runtests(<t/*.t>);
}
