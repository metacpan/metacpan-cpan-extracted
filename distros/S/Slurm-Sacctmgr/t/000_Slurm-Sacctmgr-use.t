#!/usr/bin/env perl
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 000_Slurm-Sacctmgr-use.t'

#Just check module loads
use strict;
use warnings;

our @subclasses;
our $num_tests;

BEGIN {
	@subclasses=qw(
		EntityBase
		EntityBaseAddDel
		EntityBaseListable
		EntityBaseModifiable
		EntityBaseRW

		Account
		Association
		Cluster
		Event
		Qos
		Transaction
		Tres
		User
		WCKey
	);

	$num_tests = scalar(@subclasses) + 1;
}
		
use Test::More tests => $num_tests;
BEGIN { use_ok('Slurm::Sacctmgr') };

foreach my $sclass (@subclasses)
{	use_ok('Slurm::Sacctmgr::' . $sclass);
}

