#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 1 };

{
	package
		t::constants;

	# Store all the keys in the stash before import
	my %prev_stash; %prev_stash = map { $_ => 1 } keys %t::constants::;

	# Import constants into this clean package
	use Net::TacacsPlus::Constants;

	# Check all package symbols for typos
	main::ok(grep { /^TAC_PLUS_/ || exists $prev_stash{$_} } keys %t::constants::, 'No constant typos');
}
