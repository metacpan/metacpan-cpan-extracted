#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 510_Slurm-SACluster-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Cluster;

my $testDir = dirname(abs_path($0));
my $num_tests_run = 0; 

my $entity = 'Slurm::Sacctmgr::Cluster';
my $entname = 'cluster';

#==================================================================================================
#		Setup expected results
#==================================================================================================

our @fake_cluster_data;
require "${testDir}/helpers/fake-cluster-data.pl";

sub filter_fake_data($$)
{	my $fake_data = shift || [];
	my $filter = shift || {};

	my @data = @$fake_data;
	foreach my $fkey (keys %$filter)
	{	my $fval = $filter->{$fkey};
		$fkey = $entname if $fkey eq 'name';
		@data = grep { $_->$fkey eq $fval } @data;
	}

	return [ @data ];
}

#==================================================================================================
#		Define tests
#==================================================================================================

my @tests = 
(	{	name => "list all ${entname}s",
		filter => undef,
	},

	{	name => "list $entname by name (yottascale)",
		filter => { name => 'yottascale' },
	},

	{	name => "list $entname by name (test1)",
		filter => { $entname => 'test1' },
	},

	{	name => "list $entname by name, no match",
		filter => { $entname => 'zzzNOMATCH' },
	},
);

sub do_run_tests($$)
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>"${testDir}/helpers/fake_sacctmgr_cluster",
		slurm_version => $slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	#Need to regernate as strip* functon modify fake data objects
	my $fake_data = generate_fake_objs();

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $args = $test->{filter} || {};

		my $testname = "$tname ($setname)";

		my $filter = { %$args };
		my $exp = filter_fake_data($fake_data, $filter);
		strip_all_tres_but_cpu_nodes($exp) if $slurm_version eq '14';


		my $got = $entity->sacctmgr_list($sa, %$args);


		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

#=================================================================
#               Actually run tests
#=================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

