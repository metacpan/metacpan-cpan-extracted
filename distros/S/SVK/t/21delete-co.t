#!/usr/bin/perl -w
use Test::More tests => 3;
use strict;
use File::Path;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
$svk->mkdir ('-m', 'init', '//V');
my $tree = create_basic_tree ($xd, '//V');
my ($copathX, $corpathX) = get_copath ('');
my ($copathA, $corpathA) = get_copath ('delco-one');
my ($copathB, $corpathB) = get_copath ('delco-two');
my ($copathC, $corpathC) = get_copath ('delco-canary');
$svk->checkout ('//V', $copathA);
$svk->checkout ('//', $copathB);
my $canary = "tweet tweet";
append_file ($copathC, $canary);

# Maybe (probably?) deleting the checkout root should just result in an
# error. Either way, the current behaviour seems to range from Bad to
# Disasterous.

TODO: {
local $TODO = 'Don\'t break horribly upon "svk rm COPATH"';

is_output ($svk, 'rm', [$copathA],
	   [__"D   $copathA/A/Q/qu",
	    __"D   $copathA/A/Q/qz",
	    __"D   $copathA/A/Q",
	    __"D   $copathA/A/be",
	    __"D   $copathA/A",
	    __"D   $copathA/B/S/P/pe",
	    __"D   $copathA/B/S/P",
	    __"D   $copathA/B/S/Q/qu",
	    __"D   $copathA/B/S/Q/qz",
	    __"D   $copathA/B/S/Q",
	    __"D   $copathA/B/S/be",
	    __"D   $copathA/B/S",
	    __"D   $copathA/B/fe",
	    __"D   $copathA/B",
	    __"D   $copathA/C/R",
	    __"D   $copathA/C",
	    __"D   $copathA/D/de",
	    __"D   $copathA/D",
	    __"D   $copathA/me",
	    __"D   $copathA",
	   ]);

is_output ($svk, 'rm', [$copathB],
	   [__"D   $copathB/V/A/Q/qu",
	    __"D   $copathB/V/A/Q/qz",
	    __"D   $copathB/V/A/Q",
	    __"D   $copathB/V/A/be",
	    __"D   $copathB/V/A",
	    __"D   $copathB/V/B/S/P/pe",
	    __"D   $copathB/V/B/S/P",
	    __"D   $copathB/V/B/S/Q/qu",
	    __"D   $copathB/V/B/S/Q/qz",
	    __"D   $copathB/V/B/S/Q",
	    __"D   $copathB/V/B/S/be",
	    __"D   $copathB/V/B/S",
	    __"D   $copathB/V/B/fe",
	    __"D   $copathB/V/B",
	    __"D   $copathB/V/C/R",
	    __"D   $copathB/V/C",
	    __"D   $copathB/V/D/de",
	    __"D   $copathB/V/D",
	    __"D   $copathB/V/me",
	    __"D   $copathB/V",
	   ]);

is_file_content ($copathC, $canary, "Files outside the checkout should be untouched");

}

