#!/usr/bin/perl
# SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
# SPDX-License-Identifier: Artistic-2.0

use 5.012;
use strict;
use warnings;

use Test::More 0.98;

our $VERSION = v0.1.0;

my @modules = qw(
	MooX::Role::CloneSet
);
my @buildargs_modules = qw(
	MooX::Role::CloneSet::BuildArgs
);

plan tests => scalar @modules + scalar @buildargs_modules;

for (@modules) {
	use_ok $_;
}

SKIP:
{

	if (
		!eval {
			require MooX::BuildArgs;
			1;
		}
		)
	{
		skip 'MooX::BuildArgs is not installed', scalar @buildargs_modules;
	}

	for (@buildargs_modules) {
		use_ok $_;
	}
}
