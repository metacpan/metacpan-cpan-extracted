#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 205_Slurm-SAAssoc-echo.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Association;

my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

my $sa;
my $entity = 'Slurm::Sacctmgr::Association';
my $fake_sa = "${testDir}/helpers/echo_cmdline";

my @tests = 
(	{ 	name => 'sacctmgr_list assoc single field',
		args2use => [ cluster => 'yottascale' ],
	},
	{	name => 'sacctmgr_list assoc multi-fields',
		args2use => [ 	cluster=>'yottascale',
				accounts => 'abc124',
				users => 'payerle',
				partition => 'gpu',
			],
	},
);

sub do_run_tests($$)
#Given slurm_version, dryrun flag, run the tests
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

	my @cmdargs1_common = ( 'list', 'association' );
	my @cmdargs2 = ( '--parsable2', '--noheader', '--readonly' );

	#Format strings we expect
	my @format_common = qw (account cluster defaultqos fairshare grpjobs 
				grpsubmitjobs grpwall id lft maxjobs maxsubmitjobs 
				maxwall parentid parentname partition qos rgt user );
	my @format_preTRES = qw (	grpcpumins grpcpurunmins grpcpus grpnodes 
					maxcpumins maxcpus maxnodes );
	my @format_postTRES = qw (	grptresmins grptresrunmins grptres 
					maxtresmins maxtres maxtrespernode );

	my @format = @format_common;
	if ( $slurm_version eq '14' )
	{	push @format, @format_preTRES;
	} else
	{	push @format, @format_postTRES;
	}
	my $fmtstr = join ',', @format;

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $args2use = $test->{args2use};

		my $testname = "$tname ($setname)";

		$entity->sacctmgr_list($sa, @$args2use);
		my $got = $entity->_eblist_last_raw_output;

		my $exp = [ @cmdargs1_common, "format=$fmtstr",
			hash_to_arglist_lexical(@$args2use),
			@cmdargs2 ];

		check_results($exp, $got, $testname);
	}
}
		


#================================================================================
#		Test various commands with echo sacctmgr
#================================================================================


my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

