#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 250_sshare_usage-echo.t`
#
# Various tests of sshare_list using 'echo' version of sshare
#

use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;


require "${testDir}/helpers/echo-help.pl";

my $sa = 'Slurm::Sshare';
$sa->sshare("${testDir}/helpers/echo_cmdline");


my $results;
my $args;
my $err;
my $argstr;
my (@temp, @temp2);


my @stdargs = ('--parsable2',  '--noheader', '--long' );

my (@ulist, @alist, @clist);
my (@args);

#---------------------------------------------------------
#	More helper routines
#---------------------------------------------------------

sub check_cluster_results($$$$)
#Checks with cluster args require a bit more work; each invocation
#of sshare_list will result in the 'sshare' command being invoked
#once for each cluster given.  Our standard check_results assumes a single
#invocation of sshare, so we split the results (2 lines per cluster)
{	my $name = shift;
	my $results = shift; #array ref
	my $clusters = shift; #array ref
	my $otherargs = shift;

	die "Invalid results $results, expecting array ref at "
		unless $results && ref($results) eq 'ARRAY';
	die "Invalid clusters $clusters, expecting array ref at "
		unless $clusters && ref($clusters) eq 'ARRAY';
	die "Invalid otherargs $otherargs, expecting array ref at "
		unless $otherargs && ref($otherargs) eq 'ARRAY';

	my $numclusters = scalar(@$clusters);
	
        subtest $name => sub {
                plan tests => $numclusters;

		foreach my $clus ( @$clusters )
		{	my $tmpline1 = shift @$results;
			my $tmpline2 = shift @$results;
			my $tmpres = [ $tmpline1, $tmpline2 ];
			my $tmpname = "${name}: cluster $clus";

			my $tmpargs = [ @$otherargs ];
			unshift @$tmpargs, "--clusters=$clus";
			
			check_results($tmpargs, $tmpres, $tmpname);
			$num_tests_run--; #Undo increment in check_results
		}
	};
        $num_tests_run++;
}


#---------------------------------------------------------
#	Tests of sshare_usage(...)
#
# This basically just does sshare_list of args then processes
# output, so no need to be exhaustive
#---------------------------------------------------------

#---	No arguments
$args = [  ];
@args = ( @stdargs );
$sa->sshare_usage(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage, no args ' );

@ulist=( 'payerle', 'kevin', 'george' );
$argstr=join ',', @ulist;
$args = [  'users' => $argstr ];
@args = ( "--users=$argstr", @stdargs );
$sa->sshare_usage(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage Multiple user, CSV' );

# Now for ALL users
@ulist=( 'ALL' );
@args = ( '--all', @stdargs );
$argstr = [ @ulist ];
$args = [  'users' => $argstr ];
$sa->sshare_usage(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage all users, aref' );

@alist = ( 'abc124', 'nsa', 'cia' );
$argstr=join ',', @alist;
@args = ( "--accounts=$argstr", @stdargs );
$argstr = [ @alist ];
$args = [  'accounts' => $argstr ];
$sa->sshare_usage(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage Multiple accounts, aref' );

#---------------------------------------------------------
#	Tests of sshare_usage_for_account(...)
#---------------------------------------------------------

my ($account, $cluster);

#----	Just account
$account='abc124';
@args = ( "--accounts=$account", '--all', @stdargs );
$args = [ account => $account, nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, just account' );

#----	account and no users
$account='abc124';
@args = ( "--accounts=$account", "--users='NO SUCH USER'", @stdargs );
$args = [ account => $account, users => [], nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account + no users' );

#----	account and users list
$account='abc124';
@ulist=( 'george', 'kevin' );
$argstr = join ",", @ulist;
@args = ( "--accounts=$account", "--users=$argstr", @stdargs );
$args = [ account => $account, users => [@ulist], nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account + users' );

#----	account and all users
$account='abc124';
@args = ( "--accounts=$account", '--all', @stdargs );
$args = [ account => $account, users =>'ALL', nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account + all users(1)' );

$args = [ account => $account, users =>['ALL'], nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account + all users(2)' );

#----	Just account and cluster
$account='abc124';
$cluster='yottascale';
@args = ( "--clusters=$cluster", "--accounts=$account", '--all', @stdargs );
$args = [ account => $account, cluster=>$cluster, nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account+cluster' );

#----	account+cluster and no users
$account='abc124';
@args = ( "--clusters=$cluster",  "--accounts=$account", "--users='NO SUCH USER'", @stdargs );
$args = [ account => $account, cluster=>$cluster, users => [], nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account+cluster no users' );

#----	account+cluster and users list
$account='abc124';
@ulist=( 'george', 'kevin' );
$argstr = join ",", @ulist;
@args = ( "--clusters=$cluster",  "--accounts=$account", "--users=$argstr", @stdargs );
$args = [ account => $account, cluster=>$cluster, users => [@ulist], nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account+cluster+users' );

#----	account+cluster and all users
$account='abc124';
@args = ( "--clusters=$cluster",  "--accounts=$account", '--all', @stdargs );
$args = [ account => $account, cluster=>$cluster, users =>'ALL', nowarnings=>1 ];
$sa->sshare_usage_for_account(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account, account+cluster+all users(1)' );

#---------------------------------------------------------
#	Tests of sshare_usage_for_account_user(...)
#---------------------------------------------------------
my $user;

$user = 'george';
$account='abc124';
@args = ( "--accounts=$account", "--users=$user", @stdargs );
$args = [ account => $account, user => $user , nowarnings=>1 ];
$sa->sshare_usage_for_account_user(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account_user, no cluster' );

$user = 'george';
$account='abc124';
$cluster='yottascale';
@args = ( "--clusters=$cluster", "--accounts=$account", "--users=$user", @stdargs );
$args = [ account => $account, cluster=>$cluster, user=>$user , nowarnings=>1 ];
$sa->sshare_usage_for_account_user(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_usage_for_account_user, with cluster' );






#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);

