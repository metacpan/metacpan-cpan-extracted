#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 200_sshare_list-echo.t`
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
#	No arguments
#---------------------------------------------------------

$args = [  ];
@args = ( @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list, no args ' );

#---------------------------------------------------------
#	Tests of user lists
#---------------------------------------------------------

@ulist=( 'payerle' );
$argstr=join ',', @ulist;
$args = [  'users' => $argstr ];
@args = ( "--users=$argstr", @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Single user, CSV' );

$argstr = [ @ulist ];
$args = [  'users' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Single user, aref' );

@ulist=( 'payerle', 'kevin', 'george' );
$argstr=join ',', @ulist;
$args = [  'users' => $argstr ];
@args = ( "--users=$argstr", @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Multiple user, CSV' );

$argstr = [ @ulist ];
$args = [  'users' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Multiple user, aref' );

# Now for ALL users
@ulist=( 'ALL' );
$argstr=join ',', @ulist;
$args = [  'users' => $argstr ];
@args = ( '--all', @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list all users, CSV' );

$argstr = [ @ulist ];
$args = [  'users' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list all users, aref' );

#---------------------------------------------------------
#	Tests of account lists
#---------------------------------------------------------

@alist = ( 'abc124' );
$argstr=join ',', @alist;
$args = [  'accounts' => $argstr ];
@args = ( "--accounts=$argstr", @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Single account, CSV' );

$argstr = [ @alist ];
$args = [  'accounts' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Single account, aref' );

@alist = ( 'abc124', 'nsa', 'cia' );
$argstr=join ',', @alist;
$args = [  'accounts' => $argstr ];
@args = ( "--accounts=$argstr", @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Multiple account, CSV' );

$argstr = [ @alist ];
$args = [  'accounts' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list Multiple account, aref' );

#---------------------------------------------------------
#	Tests of user + account lists
# ('accounts' comes before 'users' in arglist)
#---------------------------------------------------------

$args=[];
@args=();
@ulist=( 'payerle' );
@alist = ( 'abc124' );
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 1 user + 1 acct, CSV' );

$args = [ 'users' => [ @ulist ], 'accounts' => [ @alist ] ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 1 user + 1 acct, aref' );

$args=[];
@args=();
@ulist=( 'payerle', 'kevin', 'george' );
@alist = ( 'abc124' );
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users + 1 acct, CSV' );

$args = [ 'users' => [ @ulist ], 'accounts' => [ @alist ] ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users + 1 acct, aref' );

$args=[];
@args=();
@ulist=( 'payerle' );
@alist = ( 'abc124', 'fbi', 'nsa' );
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 1 user + 3 accts, CSV' );

$args = [ 'users' => [ @ulist ], 'accounts' => [ @alist ] ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 1 user + 3 accts, aref' );

$args=[];
@args=();
@ulist=( 'payerle', 'kevin', 'george' );
@alist = ( 'abc124', 'fbi', 'nsa' );
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users + 3 accts, CSV' );

$args = [ 'users' => [ @ulist ], 'accounts' => [ @alist ] ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users + 3 accts, aref' );

$argstr=join ',', @ulist;
$args = [ 'users' => $argstr, 'accounts' => [ @alist ] ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users(CSV) + 3 accts(aref)' );

$argstr=join ',', @alist;
$args = [ 'users' => [ @ulist ], 'accounts' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_last_raw_output;
check_results(\@args, $results, 'sshare_list 3 users(aref) + 3 accts(CSV)' );

#---------------------------------------------------------
#	Tests of cluster lists
#---------------------------------------------------------

@clist = ( 'yottascale' );
$argstr=join ',', @clist;
$args = [  'clusters' => $argstr ];
@args = ( @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list single cluster, CSV', 
	$results, \@clist, \@args );

$argstr = [ @clist ];
$args = [  'clusters' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list single cluster, aref', 
	$results, \@clist, \@args );

@clist = ( 'yottascale', 'special', 'test' );
$argstr=join ',', @clist;
$args = [  'clusters' => $argstr ];
@args = ( @stdargs );
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list  3 clusters, CSV', 
	$results, \@clist, \@args );

$argstr = [ @clist ];
$args = [  'clusters' => $argstr ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list  3 clusters, aref', 
	$results, \@clist, \@args );

@args=();
@clist = ( 'yottascale' );
@ulist = ( 'payerle' );
@alist = ( 'abc124' );
$argstr=join ',', @clist;
$args = [  'clusters' => $argstr ];
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list single cluster/user/acct, CSV', 
	$results, \@clist, \@args );

$argstr = [ @clist ];
$args = [  'clusters' => $argstr ];
push @$args, accounts => [ @alist ];
push @$args, users => [ @ulist ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list single cluster/user/acct, aref', 
	$results, \@clist, \@args );

@args=();
@clist = ( 'yottascale', 'test', 'special' );
@ulist = ( 'payerle', 'kevin', 'george' );
@alist = ( 'abc124', 'fbi', 'nsa' );
$argstr=join ',', @clist;
$args = [  'clusters' => $argstr ];
$argstr=join ',', @alist;
push @$args,   'accounts' => $argstr;
push @args, "--accounts=$argstr";
$argstr=join ',', @ulist;
push @$args,  'users' => $argstr;
push @args, "--users=$argstr";
push @args, @stdargs;
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list multiple cluster/user/acct, CSV', 
	$results, \@clist, \@args );

$argstr = [ @clist ];
$args = [  'clusters' => $argstr ];
push @$args, accounts => [ @alist ];
push @$args, users => [ @ulist ];
$sa->sshare_list(@$args);
$results = $sa->_sshare_list_last_raw_output;
check_cluster_results('sshare_list multiple cluster/user/acct, aref', 
	$results, \@clist, \@args );

#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);

