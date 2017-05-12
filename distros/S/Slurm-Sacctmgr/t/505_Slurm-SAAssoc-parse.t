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

use Slurm::Sacctmgr;
use Slurm::Sacctmgr::Association;
my $entity='Slurm::Sacctmgr::Association';


my $testDir = dirname(abs_path($0));
my $fake_sa = "${testDir}/helpers/fake_sacctmgr_assoc";
my $num_tests_run = 0; 
our @fake_assoc_data;
require "${testDir}/helpers/fake-assoc-data.pl";


#===============================================================
#		Set up expected results
#===============================================================

#------	Routine to filter test results

sub filter_test_results($;$)
#Takes a filter and optionally a list ref of test data
{	my $rawfilter = shift;
	my $data = shift;
	$data = generate_fake_data() unless $data && ref($data) eq 'ARRAY';
	

	return $data unless $rawfilter && ref($rawfilter) eq 'HASH';

	my $filter = { %$rawfilter };

	my $account = delete $filter->{account};
	if ( $account )
	{	$data = [ grep { $_->account eq $account } @$data ];
	}

	my $user = delete $filter->{user};
	if ( $user )
	{	$data = [ grep { $_->user && $_->user eq $user } @$data ];
	}

	if ( %$filter )
	{	my @tmp = keys %$filter;
		my $tmp = join ", ", @tmp;
		die "Extraneous keys [ $tmp ] in filter at ";
	}

	return $data;
}
		

#===============================================================
#		Setup tests
#===============================================================
my @tests = 
(	{	name=>'list all assocs',
		filter => undef,
	},

	{	name=>'list assoc by account/user (root)',
		filter => { account=>'root', user=>'root', },
	},

	{	name=>'list assoc by account (root)',
		filter => { account => 'root' },
	},

	{	name=> 'list assoc by account/user (acc124/payerle)',
		filter => { account => 'abc124', user=>'payerle' },
	},

	{	name=> 'list assoc by account (abc124)',
		filter => { account => 'abc124', },
	},

	{	name => 'list assoc by user (payerle)',
		filter => { user => 'payerle', },
	},

	{	name => 'list assoc by user (no match)',
		filter => { user => 'zzz', },
	},
);


#===============================================================
#		Run tests method
#===============================================================

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
	#$sa->verbose(1);

	foreach my $test (@tests)
	{	my $tname = $test->{name};
		my $filter = $test->{filter};
		my $testname = "$tname ($setname)";

		my $got = $entity->sacctmgr_list($sa, %$filter);
		my $exp = filter_test_results($filter);
		if ( $slurm_version eq '14' )
		{	$exp = strip_all_tres_but_cpu_nodes($exp);
		}

		is_deeply($got, $exp, $testname);
		$num_tests_run++;
	}
}

#===============================================================
#		Run tests
#===============================================================

my @slurm_versions = ( '14', '15.08.2' );

foreach my $slurm_version (@slurm_versions)
{	foreach my $dryrun (0, 1)
	{	do_run_tests($slurm_version, $dryrun);
	}
}

done_testing($num_tests_run);

