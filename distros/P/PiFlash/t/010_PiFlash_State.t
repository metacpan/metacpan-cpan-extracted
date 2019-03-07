#!/usr/bin/perl
# 010PiFlash_State.t - tests for PiFlash::State module

use strict;
use warnings;
use autodie;

use Test::More;
use PiFlash;
use PiFlash::State;

# initialize program state storage
my @top_level_params = PiFlash::state_categories();
PiFlash::State->init(@top_level_params);
plan tests => (scalar @top_level_params) * 6 + 6;

# test existence of symtab entries
foreach my $tlp_name (@top_level_params) {
	can_ok("PiFlash::State", $tlp_name);
	can_ok("PiFlash::State", "has_".$tlp_name);
	ok(exists $PiFlash::State::state->{$tlp_name}, "state{$tlp_name} exists");
	is(ref $PiFlash::State::state->{$tlp_name}, "HASH", "state{$tlp_name} is a hash ref");
	my $hashref = $PiFlash::State::{$tlp_name}();
	is(ref $hashref, "HASH", "HASH ref for $tlp_name");
	is(scalar keys %$hashref, 0, "empty hash for $tlp_name by default");
}

# accessor tests
ok(!PiFlash::State::has_log("foo"), "log{foo} undefined by default");
PiFlash::State::log("foo", 1);
ok(PiFlash::State::has_log("foo"), "log{foo} defined after assignment");
is(PiFlash::State::log("foo"), 1, "log{foo} correct value after assignment");


# verbose() tests
is(PiFlash::State::verbose(), 0, "verbose is false by default");
PiFlash::State::cli_opt("verbose", 1);
is(PiFlash::State::verbose(), 1, "verbose is true when set to 1");
PiFlash::State::cli_opt("verbose", 0);
is(PiFlash::State::verbose(), 0, "verbose is false when set to 0");

1;
