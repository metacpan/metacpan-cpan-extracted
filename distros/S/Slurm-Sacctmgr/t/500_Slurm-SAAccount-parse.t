#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 500_Slurm-SAAccount-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Account;

my $testDir = dirname(abs_path($0));
my $num_tests_run = 0; 

#=================================================================
#		Set up expected results
#=================================================================

our @fake_account_data;
require "${testDir}/helpers/fake-account-data.pl";

my $entity = 'Slurm::Sacctmgr::Account';
my $entname = 'account';

sub generate_fake_objs()
{	my $objs = [];

	foreach my $record (@fake_account_data)
	{	my $obj = $entity->new(%$record);
		push @$objs, $obj;
	}

	#Make sure fake_data is alphabetically by account name
	$objs = [ sort { $a->account cmp $b->account } @$objs ];
	return $objs;
}

sub filter_fake_data($$)
{	my $fake_data = shift || [];
	my $filter = shift || {};

	my @data = ( @$fake_data );
	foreach my $fkey (keys %$filter)
	{	my $fval = $filter->{$fkey};
		$fkey = $entname if $fkey eq 'name';

		@data = grep { $_->$fkey eq $fval } @data;
	}
	return [ @data ];
}


#=================================================================
#		Set up tests
#=================================================================

my @tests = 
(	{	name => "list all ${entname}s",
		filter => undef,
	},

	{ 	name => "list $entname by name",
		filter => { name => 'bbb' },
	},

	{	name => "list $entname by org (single $entname)",
		filter => { organization => 'bb' },
	},

	{	name => "list $entname by org (multiple)",
		filter => { organization => 'aa', },
	},

	{ 	name => "list $entname by name (no match)",
		filter => { name => 'zzzNO_SUCH_ACCT' },
	},
);

sub do_run_tests($$)
#Run tests for given slurm_version and dryrun mode
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>"${testDir}/helpers/fake_sacctmgr_acct",
		slurm_version => $slurm_version );
	$sa->dryrun($dryrun);
	#$sa->verbose(1)

	#Need to regenerate as strip* functions will modify fake data objects
	my $fake_data = generate_fake_objs;


	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $args = $test->{filter} || {};

		my $testname = "$tname ($setname)";

		my $got = $entity->sacctmgr_list($sa, %$args);

		my $filter = { %$args };
		my $exp = filter_fake_data($fake_data, $filter);

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}


#=================================================================
#		Run tests
#=================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

