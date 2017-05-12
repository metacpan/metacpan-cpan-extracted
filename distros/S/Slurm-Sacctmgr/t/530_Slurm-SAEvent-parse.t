#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 505_Slurm-SAAssoc-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
#use Data::Dumper;

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Event;
my $entity = "Slurm::Sacctmgr::Event";
my $entname = 'event';

my $testDir = dirname(abs_path($0));
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_event";

my $num_tests_run = 0; 

our @fake_event_data;
require "${testDir}/helpers/fake-event-data.pl";

#############################################################################
#		Filter expected results
#############################################################################

sub filter_test_results($;$)
#Takes a filter and optionally a list ref of test data
{	my $rawfilter = shift;
	my $data = shift;
	$data = generate_fake_data() unless $data && ref($data) eq 'ARRAY';

	return $data unless $rawfilter && ref($rawfilter) eq 'ARRAY';
	my $filter = { @$rawfilter };

	my @filterable_fields = qw( cluster user);
	my @data = @$data;

	FILTER_FIELD: foreach my $fld (@filterable_fields)
	{	next FILTER_FIELD unless exists $filter->{$fld};
		my $val = delete $filter->{$fld};
		next FILTER_FIELD unless defined $val;

		@data = grep { $_->{$fld} eq $val } @data;
	}

	if ( %$filter )
	{	my @tmp = keys %$filter;
		my $tmp = join ", ", @tmp;
		die "Extraneous keys [ $tmp ] in filter at ";
	}

	return [ @data ];
}
	

#############################################################################
#		Setup the tests
#############################################################################

my @tests = 
(	{	testname => "list all ${entname}s",
		filter => undef,
	},

	{	testname => "list $entname by cluster (test1)",
		filter => [ cluster => 'test1' ],
	},

	{	testname => "list $entname by cluster (yottascale)",
		filter => [ cluster => 'yottascale' ],
	},

	{	testname => "list $entname by cluster/user (yottascale/root)",
		filter => [ cluster => 'yottascale', user => 'root' ],
	},

	{	testname => "list $entname by cluster (no match)",
		filter => [ cluster => 'No-such-cluster' ],
	},
);

sub do_run_tests($$)
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);

	my $fake_data = generate_fake_data();

	foreach my $test (@tests)
	{	my $tname = $test->{testname};
		my $filter = $test->{filter} || [];
		my $testname = "$tname ($setname)";

		my $got = $entity->sacctmgr_list($sa, @$filter);
		my $exp = filter_test_results($filter, $fake_data);


		if ( $slurm_version eq '14' )
		{	$exp = strip_all_tres_but_cpu($exp);
		}

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

#===============================================================
#	Run tests
#===============================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);
