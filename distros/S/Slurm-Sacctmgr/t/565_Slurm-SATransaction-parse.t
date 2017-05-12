#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 560_Slurm-SATransaction-parse.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Transaction;
my $entity = 'Slurm::Sacctmgr::Transaction';
my $entname = 'transaction';

my $testDir = dirname(abs_path($0));
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_$entname";

my $num_tests_run = 0; 

#============================================================================
#			Set up expected results
#============================================================================

our @fake_trans_data;
require "${testDir}/helpers/fake-${entname}-data.pl";

sub filter_test_results($;$)
#Takes a filter and optionally a list ref of test data
{	my $rawfilter = shift;
	my $data = shift;
	$data = generate_fake_data() unless $data && ref($data) eq 'ARRAY';

	return $data unless $rawfilter && ref($rawfilter) eq 'HASH';

	my $filter = { %$rawfilter };

	my @fields = qw(actor action info timestamp where);

	FIELD: foreach my $fld (@fields)
	{	my $fval = delete $filter->{$fld};
		next FIELD unless defined $fval;

		my $meth = $fld;
		$data = [ grep { $_->$meth eq $fval } @$data ];
	}

	if ( %$filter )
	{	my @tmp = keys %$filter;
		my $tmp = join ", ", @tmp;
		die "Extraneous keys [ $tmp ] in filter at ";
	}

	return $data;
}

#============================================================================
#			Set up tests
#============================================================================

my @tests = 
(	{	name => "list all $entname",
		filter => undef,
	},

	{	name => "list $entname by actor (slurm)",
		filter => { actor => 'slurm' },
	},

	{	name => "list $entname by actor (root)",
		filter => { actor => 'root' },
	},

	{	name => "list $entname by actor (no match)",
		filter => { actor => 'zzzNO-MATCH' },
	},
);

#============================================================================
#			Run test routine
#============================================================================

sub do_run_tests($$)
#Given slurm_version, dryrun, run our tests
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>$fake_sa, slurm_version=>$slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $filter = $test->{filter};
		my $testname = "$tname ($setname)";

		my $exp = filter_test_results($filter);
		#if ( $slurm_version eq '14' )
		#{	#Nothing to do here
		#	$exp = strip_all_tres_but_cpu_nodes($exp);
		#}

		my $got = $entity->sacctmgr_list($sa, %$filter);

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

#============================================================================
#			Run tests
#============================================================================


my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

