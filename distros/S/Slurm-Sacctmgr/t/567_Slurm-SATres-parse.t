#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 570_Slurm-SAWCKey-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Tres;
my $entity = 'Slurm::Sacctmgr::Tres';
my $entname = 'tres';

my $testDir = dirname(abs_path($0));
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_tres";

my $num_tests_run = 0; 

#====================================================================
#		Set up expected results
#====================================================================

our @fake_wckey_tests;
require "${testDir}/helpers/fake-tres-data.pl";

sub filter_test_results($;$)
#Takes a filter and optionally a list ref of test data
{	my $rawfilter = shift;
	my $data = shift;
	$data = generate_fake_data() unless $data && ref($data) eq 'ARRAY';

	return $data unless $rawfilter && ref($rawfilter) eq 'HASH';
	my $filter = { %$rawfilter };

	my @filterable_fields = qw(type name id);
	FIELD: foreach my $ffld (@filterable_fields)
	{	next FIELD unless exists $filter->{$ffld};
		my $ffval = $filter->{$ffld};
		my $meth = $ffld;
		$data = [ grep { defined $_->$meth && $_->$meth eq $ffval } @$data ];
	}

	return $data;
}


#====================================================================
#		Set up tests
#====================================================================

my @tests = 
(	{	name => "list all ${entname}s",
		filter => undef,
	},

	{	name => "list $entname by type (cpu)",
		filter => { wckey => 'cpu' },
	},

	{	name => "list $entname by type (gres)",
		filter => { wckey => 'gres' },
	},

	{	name => "list $entname by id (4)",
		filter => { id => 4 },
	},

	{	name => "list $entname by name (gpu)",
		filter => { name => 'gpu' },
	},

	{	name => "list $entname by type/name (gres/gpu)",
		filter => { type => 'gres', name => 'gpu' },
	},

	{	name => "list $entname by type (no match)",
		filter => { type => 'xxx-NO-SUCH-TRES', },
	},
);

#====================================================================
#		Routine to run tests
#====================================================================

sub do_run_tests($$)
#Run tests for given slurm version/dryrun
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new( sacctmgr=>$fake_sa,
		slurm_version => $slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $filter = $test->{filter};
		my $testname = "$tname ($setname)";

		my $exp = filter_test_results($filter);
		my $got = $entity->sacctmgr_list($sa, %$filter);


		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

#===============================================================
#			Run tests
#===============================================================

#Only run on version 15.08 or newer
#my @slurm_versions = ( '14', '15.08.2' );
my @slurm_versions = ( '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

