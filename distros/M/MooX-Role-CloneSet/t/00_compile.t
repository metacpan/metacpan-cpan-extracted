#!/usr/bin/perl

use v5.12;
use strict;
use warnings;

use Test::More 0.98;

my @modules = qw(
	MooX::Role::CloneSet
);
my @buildargs_modules = qw(
	MooX::Role::CloneSet::BuildArgs
);

plan tests => scalar @modules + scalar @buildargs_modules;

use_ok $_ for @modules;

SKIP:
{

	my $have_buildargs;
	eval {
		require MooX::BuildArgs;
		$have_buildargs = 1;
	};
	skip 'MooX::BuildArgs is not installed', scalar @buildargs_modules
	    unless $have_buildargs;

	use_ok $_ for @buildargs_modules;
}
