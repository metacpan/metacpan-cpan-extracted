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
my @cli_params = ("verbose", "logging");
plan tests => 1 + (scalar @top_level_params)*10 + (scalar @cli_params)*3;

# make sure we're getting enough data from PiFlash::state_categories()
ok((scalar @top_level_params) >= 8, "PiFlash::state_categories provides at least 8 entries");

# test top-level program state entries
foreach my $tlp_name (@top_level_params) {
	# dynamic method existence tests
	can_ok("PiFlash::State", $tlp_name);
	can_ok("PiFlash::State", "has_".$tlp_name);

	# top-level hash existence tests
	ok(exists $PiFlash::State::state->{$tlp_name}, "state{$tlp_name} exists");
	is(ref $PiFlash::State::state->{$tlp_name}, "HASH", "state{$tlp_name} is a hash ref");
	my $hashref = $PiFlash::State::{$tlp_name}();
	is(ref $hashref, "HASH", "HASH ref for $tlp_name");
	is(scalar keys %$hashref, 0, "empty hash for $tlp_name by default");

	# accessor tests
	## no critic (ProhibitStringyEval)
	my $test_sub_accessor = sub { return eval "PiFlash::State::$tlp_name(\@_)"; };
	my $test_sub_has = sub { return eval "PiFlash::State::has_$tlp_name(\@_)"; };
	## use critic (ProhibitStringyEval)
	ok(!$test_sub_has->("foo"), "$tlp_name\{foo\} undefined by default");
	$test_sub_accessor->("foo", 1);
	ok($test_sub_has->("foo"), "$tlp_name\{foo\} defined after assignment");
	is($test_sub_has->("foo"), 1, "$tlp_name\{foo\} correct value after assignment");
	is(scalar keys %$hashref, 1, "1 entry in $tlp_name hash after test");
}

# CLI-specific parameter (verbose/logging) tests
foreach my $cli_param (@cli_params) {
	## no critic (ProhibitStringyEval)
	my $test_sub_cli_param = sub { return eval "PiFlash::State::$cli_param()"; };
	## use critic (ProhibitStringyEval)
	is($test_sub_cli_param->(), 0, "$cli_param is false by default");
	PiFlash::State::cli_opt($cli_param, 1);
	is($test_sub_cli_param->(), 1, "$cli_param is true when set to 1");
	PiFlash::State::cli_opt($cli_param, 0);
	is($test_sub_cli_param->(), 0, "$cli_param is false when set to 0");
}

1;
