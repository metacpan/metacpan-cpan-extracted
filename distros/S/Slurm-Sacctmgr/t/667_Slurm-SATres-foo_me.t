#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 667_Slurm-SATres-foo_me.t'
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
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";
our @fake_tres_data;
require "$testDir/helpers/fake-tres-data.pl";

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
	$setname .= $dryrun?'DRYRUN':'no dryrun';

	my $sa = Slurm::Sacctmgr->new(sacctmgr=>"$fake_sa", 
		slurm_version=>$slurm_version);
	$sa->dryrun($dryrun?1:0);
	#$sa->verbose(1);

	my $fakedata = generate_fake_data();

	foreach my $test (@$fakedata)
	{	my $exp = $test;

		my $id = $exp->id;

		my $testname = "list_me for $entname ($id)";
		my $inst = $entity->new( id => $id,);
		my $got = $inst->sacctmgr_list_me($sa);

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

	
#================================================================================
#		Test various commands for slurm version, dryrun modes
#================================================================================

#Only supported for version 15.08 and greater
#my @slurm_versions = ( '14', '15.08.2' );
my @slurm_versions = ( '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	
		do_list_me_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

