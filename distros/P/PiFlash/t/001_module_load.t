#!/usr/bin/perl
# 001module_load.t - basic test that the modules all load

use strict;
use warnings;
use Test::More;

my @classes = qw(
	PiFlash::Command
	PiFlash::Hook
	PiFlash::Inspector
	PiFlash::MediaWriter
	PiFlash::Object
	PiFlash::Plugin
	PiFlash::State
	PiFlash
	);
plan tests => scalar @classes;

foreach my $class (@classes) {
	require_ok($class);
}

1;
