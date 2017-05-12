#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 800_Slurm-SAAccount-extra.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Account;


my $testDir = dirname(abs_path($0));
our $num_tests_run = 0;

require "$testDir/helpers/echo-help.pl";

my $entity = 'Slurm::Sacctmgr::Account';
my $entname = 'account';

my $fake_sa = "${testDir}/helpers/fake_sacctmgr_show+echo";

#================================================================================
#		Test definitions, subroutines
#================================================================================

my @zero_usage_tests =
(	{	testname => 'Zero usage on yottascale/abc124',
		args => [ 'abc124', 'yottascale' ],
	},
	{	testname => 'Zero usage on test-account/test-cluster',
		args => [ 'test-account', 'test-cluster' ],
	},
);

sub do_zero_usage_tests($$)
#Given version number and dryrun flag, do set of tests
#on szero_usage_on_account_cluster
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

	foreach my $test (@zero_usage_tests)
	{	my $tname = $test->{testname};
		my $args = $test->{args};
		my $account = $args->[0];
		my $cluster = $args->[1];

		my $testname = "$setname, $tname";
		my $exp = [ '-i', 'modify', 'account', 'where', 
			#Do not put extra quotes around $cluster, $account, or 0.
			#We do not get interpolated by shell, so not needed
			"cluster=$cluster",
			"name=$account",
			'set', "rawusage=0",
			];

		note("Ignore following [DRYRUN] output; this is normal") if $dryrun;
		$entity->zero_usage_on_account_cluster($sa, $account, $cluster, 1);
		my $got = $entity->_ebmod_last_raw_output;

		if ( $dryrun )
		{	is_deeply($got, [], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got, $testname); 
		}
	}
}

my @set_grptresmins_tests =
(	{	testname => 'Setting grpcpumin old way',
		cluster => 'yottascale',
		account => 'abc124',
		tresmin => '13571024',
		#Do not put extra quotes around values; we do not 
		#get interpolated by shell, so not needed
		exp_pretres => "grpcpumins=13571024",
		exp_posttres => "grptresmins=cpu=13571024",
	},
	{	testname => 'Setting grpcpumin new way (tres hash)',
		cluster => 'yottascale',
		account => 'abc124',
		tresmin => { cpu => '13571025', },
		#Do not put extra quotes around values; we do not 
		#get interpolated by shell, so not needed
		exp_pretres => "grpcpumins=13571025",
		exp_posttres => "grptresmins=cpu=13571025",
	},
	{	testname => 'Setting grpcpumin new way (tres string)',
		cluster => 'yottascale',
		account => 'abc124',
		tresmin => 'cpu=13571026', 
		#Do not put extra quotes around values; we do not 
		#get interpolated by shell, so not needed
		exp_pretres => "grpcpumins=13571026",
		exp_posttres => "grptresmins=cpu=13571026",
	},
	{	testname => 'Setting grpcpumin + grpmemmins new way (tres hash)',
		cluster => 'yottascale',
		account => 'abc124',
		tresmin => { cpu => '13571027', mem => 100000, },
		#Do not put extra quotes around values; we do not 
		#get interpolated by shell, so not needed
		exp_pretres => "grpcpumins=13571027",
		exp_posttres => "grptresmins=cpu=13571027,mem=100000",
		tres_warning => 1,
	},
);

sub do_grptresmins_tests($$)
#Given version number and dryrun flag, do set of tests
#on szero_usage_on_account_cluster
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

	foreach my $test (@set_grptresmins_tests)
	{	my $tname = $test->{testname};
		my $account = $test->{account};
		my $cluster = $test->{cluster};
		my $tresmin = $test->{tresmin};

		my $exp_pretres = $test->{exp_pretres};
		my $exp_posttres = $test->{exp_posttres};
		my $tres_warnings = $test->{tres_warning};

		my $testname = "$setname, $tname";

		my $exp = [ '-i', 'modify', 'account', 'where',
			#Do not put extra quotes around values; we do not 
			#get interpolated by shell, so not needed
			"cluster=$cluster",
			"name=$account",
			'set',
		];

		if ( $slurm_version eq '14' )
		{	push @$exp, $exp_pretres;
		} else
		{	push @$exp, $exp_posttres;
		}

		note("Ignore warning re unsupported TRESes") if $tres_warnings && $slurm_version eq '14';
		note("Ignore following [DRYRUN] output; this is normal") if $dryrun;
		$entity->set_grptresmin_on_account_cluster($sa, $account, $cluster, $tresmin, 1);
		my $got = $entity->_ebmod_last_raw_output;

		if ( $dryrun )
		{	is_deeply($got, [], $testname);
			$num_tests_run++;
		} else
		{ 	check_results($exp, $got, $testname); 
		}
	}
}


#================================================================================
#		Test various commands for slurm version, dryrun modes
#================================================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_zero_usage_tests($slurm_version, $dryrun);
		do_grptresmins_tests($slurm_version, $dryrun);
	}
}


done_testing($num_tests_run);

