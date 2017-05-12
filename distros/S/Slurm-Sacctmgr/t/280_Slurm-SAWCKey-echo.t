#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 250_Slurm-SAWCKey-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::WCKey;
my $entity = 'Slurm::Sacctmgr::WCKey';
my $entname = 'wckey';

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;
require "$testDir/helpers/echo-help.pl";

my $fake_sa = "${testDir}/helpers/echo_cmdline";


#=======================================================================
#		Define our tests
#=======================================================================

my @tests = 
(	{	name => "sacctmgr_list $entname single field",
		args2use => [ user => 'payerle' ],
	},

	{	name => "sacctmgr_list $entname, multiple fields",
		args2use => [ user=>'payerle', cluster=>'yottascale'],
	},
);

sub do_run_tests($$)
#Run tests for given slurm version/dryrun
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	$setname .= $dryrun?'DRYRUN':'no dryrun';
	
	my $sa = Slurm::Sacctmgr->new(sacctmgr=>$fake_sa,
		slurm_version => $slurm_version );
	$sa->dryrun($dryrun);
	#$sa->verbose(1);

	my @cmdargs1 = ( 'list', $entname , );
	my @cmdargs2 = ( '--parsable2', '--noheader', '--readonly' );
	my @format_common = qw(wckey cluster user);

	my @format = @format_common;
	my $fmtstr = join ',', @format;

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $args2use = $test->{args2use};
		my $testname = "$test ($setname)";

		my $exp = [ @cmdargs1, "format=$fmtstr",
			hash_to_arglist_lexical(@$args2use),
			@cmdargs2 ];

		$entity->sacctmgr_list($sa, @$args2use);
		my $got = $entity->_eblist_last_raw_output;

		check_results($exp, $got, $testname);
	}
}

#=======================================================================
#		Run the tests
#=======================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

