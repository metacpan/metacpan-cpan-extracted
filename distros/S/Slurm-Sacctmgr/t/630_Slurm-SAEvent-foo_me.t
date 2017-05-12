#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 630_Slurm-SAEvent-foo_me.t'
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
our @fake_assoc_data;
require "$testDir/helpers/fake-event-data.pl";


my $entity = 'Slurm::Sacctmgr::Event';
my $entname = 'event';

my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

#================================================================================
#		Test definitions, subroutines
#================================================================================

sub do_list_me_tests($$)
#Given version number and dryrun flag, do set of tests
#on sacctmgr_list_me
{	my $slurm_version = shift;
	my $dryrun = shift;

	my $setname = "slurm $slurm_version, ";
	if ( $dryrun )
	{	$setname .= "dryrun";
	} else
	{	$setname .= "no dryrun";
	}

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);

	my $fakedata = generate_fake_data();

	my $i = 0;
	foreach my $test (@$fakedata)
	{	$i++;
		my $exp = $test;
		my $testname = "list_me for event #$i ($setname)";

		my $got = $exp->sacctmgr_list_me($sa);
		if ( $slurm_version eq '14' )
		{	strip_all_tres_but_cpu_from_obj($exp);
		}

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

	
#================================================================================
#		Test various commands for slurm version, dryrun modes
#================================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	
		do_list_me_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

