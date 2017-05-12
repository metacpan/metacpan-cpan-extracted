#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 500_usage_xxx-parse.t`
#
# Various tests of usage_xxx routines using  fake_sshare to test parsing of sshare output
#

use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;
my $default_user = 'george';
my $default_cluster = 'yottascale';


require "${testDir}/helpers/parse-help.pl";

my $sa = 'Slurm::Sshare';
$sa->sshare("${testDir}/helpers/fake_sshare");
my $DEBUG;
#$DEBUG=1;

#$sa->verbose(1);

#---------------------------------------------------------
#	More helper routines
#---------------------------------------------------------

sub sum_list_over_hash_key($$)
#Takes a list ref of hash refs, and returns the numerical
#sum of the values of specified key over all hash refs
{	my $hlist = shift || [];
	my $key = shift;

	my $sum = 0.0;

	HREF: foreach my $href (@$hlist)
	{	next HREF unless defined $href;
		my $hval = $href->{$key};
		next HREF unless defined $hval;
		$sum += $hval;
	}

	return $sum;
}

sub expected_usage_by_user($$$)
#Uses perlish data in parse-help.pl to compute expected usage
{	my $cluster = shift;
	my $account = shift;
	my $user = shift;

	my $hlist = filtered_test_data( 
		cluster=>$cluster, account=>$account, user=>$user);

	my $expected = sum_list_over_hash_key($hlist, 'raw_usage');
	diag("cluster=$cluster, account=$account, user=$user, expected raw_usage=$expected") if $DEBUG;
	return $expected;
}

sub expected_usage_by_account($$)
{	my $cluster = shift;
	my $account = shift;
	my $me = 'expected_usage_by_account';

	my $cpusec_used = 0;
	my $cpumin_limit = 0;
	my $cpumin_unused = 0;

	my $hlist = filtered_test_data( 
		cluster=>$cluster, account=>$account);
	$hlist = [ grep { ! $_->{user} } @$hlist ];

	return [ $cpusec_used, $cpumin_limit, $cpumin_unused ] unless scalar(@$hlist);
	die "$me: Multiple lines for cluster=$cluster, account=$account, user=NULL, cannot handle at "
		if scalar(@$hlist) > 1;

	my $href = $hlist->[0];
	$cpusec_used = $href->{raw_usage} || 0;
	$cpumin_limit = $href->{grpcpumins} || 0;
	$cpumin_unused = ( 60 * $cpumin_limit - $cpusec_used)/60;
	diag("cluster=$cluster, account=$account, exp raw_usage=$cpusec_used, exp cpumin_lim=$cpumin_limit") if $DEBUG;
	return [ $cpusec_used, $cpumin_limit, $cpumin_unused ];
}

sub all_users_for_cluster_account($$)
#Returns list ref of all known users for cluster/account
#based on stashed data
{	my $cluster = shift;
	my $account = shift;

	my $hlist = filtered_test_data( 
		cluster=>$cluster, account=>$account);
	my @hlist = grep { $_->{user} } @$hlist;
	my @ulist = map { $_->{user} } @hlist;
	return [ @ulist ];
}

my ($cluster, $account, $user, $ulist, $rec, $ustr);
my $nowarnings;
my ($results, $expected);
my (%filter, $hlist, $exp2);

my @slurm_versions = ( '14', '15.08.2', );

#---------------------------------------------------------
#	Tests on usage_for_user_account_in_cluster
#---------------------------------------------------------

#Tests to run for usage_for_user_account_in_cluster
#Array refs are [ cluster, account, user, nowarnings ]
my @tests_for_user_usage =
(	[ 'yottascale', 'abc124', 'payerle' ],
	[ 'yottascale', 'abc124', 'kevin' ],
	[ 'yottascale', 'abc124', 'george' ],
	[ 'yottascale', 'fbi',    'george' ],
	[ 'yottascale', 'fbi',    'kevin', 1 ],
	[ 'yottascale', 'fbi',    'payerle' ],
	[ 'yottascale', 'nsa',    'george' ],
	[ 'yottascale', 'nsa',    'kevin', 1 ],
	[ 'yottascale', 'nsa',    'payerle', 1 ],
	[ 'test'      , 'abc124', 'payerle' ],
	[ 'test',       'abc124', 'kevin', 1 ],
	[ 'test',       'abc124', 'george' ],
	[ 'test',       'fbi',    'george', 1 ],
	[ 'test',       'fbi',    'kevin', 1 ],
	[ 'test',       'fbi',    'payerle', 1 ],
	[ 'test',       'nsa',    'george', 1 ],
	[ 'test',       'nsa',    'kevin', 1 ],
	[ 'test',       'nsa',    'payerle', 1 ],
);


foreach my $vers (@slurm_versions)
{   #Tell package what version to expect
    $sa->sshare("${testDir}/helpers/fake_sshare", $vers);
    #Tell fake_sshare what version to emulate
    $ENV{FAKESSHARE_EMULATE_VERSION} = $vers;

    my $vstr = "(emulating $vers)";

    foreach $rec (@tests_for_user_usage)
    {	($cluster, $account, $user, $nowarnings) = @$rec;
	$expected = expected_usage_by_user($cluster, $account, $user);
	$results = $sa->usage_for_user_account_in_cluster(
		cluster=>$cluster, account=>$account, user=>$user,
		nowarnings=>$nowarnings);
	if ( defined $expected && defined $results )
	{	cmp_ok($results, '==', $expected, 
			"usage_for_user_account_in_cluster( $cluster, $account, $user) $vstr" );
	} else
	{	is($results, $expected, "usage_for_user_account_in_cluster( $cluster, $account, $user) $vstr" );
	}
	$num_tests_run++;
    }
}

#---------------------------------------------------------
#	Tests on usage_for_account_in_cluster
#---------------------------------------------------------

#Tests to run for usage_for_account_in_cluster
#Array refs are [ cluster, account, ulist, nowarnings ]
my @tests_for_account_usage =
(	[ 'yottascale', 'abc124', [], ], #no users
	[ 'yottascale', 'abc124',  ], #all users
	[ 'yottascale', 'abc124', ['payerle'] ], #1 user
	[ 'yottascale', 'abc124', ['payerle', 'kevin'] ], #2 users
	[ 'yottascale', 'fbi',  ], #all users
	[ 'yottascale', 'nsa',  ], #all users
	[ 'yottascale', 'cia', undef, 1 ], #no such account
	[ 'test', 'abc124',  ], #all users
);


foreach my $vers (@slurm_versions)
{   #Tell package what version to expect
    $sa->sshare("${testDir}/helpers/fake_sshare", $vers);
    #Tell fake_sshare what version to emulate
    $ENV{FAKESSHARE_EMULATE_VERSION} = $vers;

    my $vstr = "(emulating $vers)";

    foreach $rec (@tests_for_account_usage)
    {	($cluster, $account, $ulist, $nowarnings) = @$rec;

	$expected = expected_usage_by_account($cluster, $account);
	my $tmpulist = $ulist;
	if  ( $ulist && ref($ulist) eq 'ARRAY' )
	{	$ustr = join ',', @$ulist;
		if ( $ustr )
		{	$ustr = "[ $ustr ]";
		} else
		{	$ustr = "no users";
		}
	} else
	{	#No user list given, default to all users known about
		$tmpulist = all_users_for_cluster_account($cluster, $account);
	}

	#Generate user usage hash
	$exp2 = {};
	foreach $user (@$tmpulist)
	{	my $temp = expected_usage_by_user($cluster, $account, $user);
		$exp2->{$user} = $temp;
	}
	$exp2 = undef unless scalar(%$exp2);
	push @$expected, $exp2;

	$results = $sa->usage_for_account_in_cluster(
		cluster=>$cluster, account=>$account, users=>$ulist, nowarnings=>$nowarnings );

	is_deeply($results, $expected, "usage_for_account_in_cluster($cluster, $account, $ustr) $vstr");
	$num_tests_run++;
    }
}
	

	


#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);

