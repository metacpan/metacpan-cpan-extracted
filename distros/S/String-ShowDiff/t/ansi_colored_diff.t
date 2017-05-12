#!/usr/bin/perl
use strict;

use String::ShowDiff qw/ansi_colored_diff/;
use Term::ANSIColor qw/:constants uncolor colored/;

use constant TEST_STRINGS => (
	["", "abcehjlmnpt", [split //, "abcehjlmnpt"],
	                    [split //, "+++++++++++"]],
	
	["abcehjlmnpt", "", [split //, "abcehjlmnpt"],
	                    [split //, "-----------"]],
	
	["abcehjlmnpt", "bcdefjklmrst", [split //, "abcdehfjklmnprst"],
	                                [split //, "-uu+u-+u+uu--++u"]],

	["abcehjlmnp", "bcdefjklmrst", [split //, "abcdehfjklmnprst"],
	                               [split //, "-uu+u-+u+uu--+++"]],
);

use constant TEST_OPTIONS => (
	[undef,              {'-' => 'on_red',  '+' => 'on_green', 'u' => 'reset'}],
	[{'-' => 'on_blue'}, {'-' => 'on_blue', '+' => 'on_green', 'u' => 'reset'}], 
	[{'-' => 'on_blue', '+' => 'on_yellow', 'u' => 'on_white'}, 
	 {'-' => 'on_blue', '+' => 'on_yellow', 'u' => 'on_white'}],
);

use Test::More tests => 12;

foreach (TEST_OPTIONS) {
	my ($options, $colors) = @$_; 
	foreach (TEST_STRINGS) {
		my ($s1, $s2, $s12, $mod) = @$_;
		is ansi_colored_diff($s1, $s2,$options),
		   join("", map {colored($s12->[$_],$colors->{$mod->[$_]})} (0 .. @{$mod}-1)),
		   "Comparing $s1 and $s2";
	}
}

print RESET;    
