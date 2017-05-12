#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 230_Slurm-SAEvent-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Event;

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

my $sa;
my $fake_sa = "${testDir}/helpers/echo_cmdline";
my $entity = 'Slurm::Sacctmgr::Event';
my $entname = "event";


#####################################################################################
#		Test definitions
#####################################################################################

my @tests = 
(	{	testname => "sacctmgr_list $entname single field, 1 record",
		args2use => [ cluster => "test1" ],
	},
	{	testname => "sacctmgr_list $entname single field, mutliple records",
		args2use => [ cluster => "yottascale" ],
	},
	{	testname => "sacctmgr_list $entname multiple fields",
		args2use => [ cluster => "yottascale", user => "root" ],
	},
	{	testname => "sacctmgr_list $entname (all)",
	},
);


sub do_run_tests($$)
#Run tests for given slurm version/dryrun mode
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= ($dryrun)?'DRYRUN':' no dryrun';

	my $sa = Slurm::Sacctmgr->new(
		sacctmgr=>$fake_sa, slurm_version=>$slurm_version);
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	my @cmdargs1_common = ( 'list', $entname );
	my @cmdargs2 = ( '--parsable2', '--noheader', '--readonly' );

	#Format strings we expect
	my @format_common = qw (cluster clusternodes duration end 
		event eventraw nodename reason start state stateraw user);
	my @format_preTRES = qw (cpus);
	my @format_postTRES = qw (tres);

	my @format = @format_common;
	if ( $slurm_version eq '14' )
	{	push @format, @format_preTRES;
	} else
	{	push @format, @format_postTRES;
	}
	my $fmtstr = join ",", @format;

	foreach my $test (@tests)
	{	my $tname = $test->{testname};
		my $args2use = $test->{args2use} || [];

		my $testname = "$tname ($setname)";

		my $exp = [ @cmdargs1_common,
			"format=$fmtstr",
			hash_to_arglist_lexical(@$args2use),
			@cmdargs2,
		];
	
		$entity->sacctmgr_list($sa, @$args2use);
		my $got = $entity->_eblist_last_raw_output;

		check_results($exp, $got, $testname);
	}
}

#####################################################################################
#		Actually run the tests
#####################################################################################

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);
