#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 300_usage_xxx-echo.t`
#
# Various tests of usage_* methods using 'echo' version of sshare
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
my (@ulist, $user, $account, $cluster);
my @args;
my @expargs;


#---------------------------------------------------------
#	Test of usage_for_account_in_cluster
#---------------------------------------------------------

$cluster='yottascale';
$account='abc124';

@args = ( cluster=>$cluster, account=>$account, nowarnings=>1);
@expargs = ( "--clusters=$cluster", "--accounts=$account", '--all', @stdargs);
$sa->usage_for_account_in_cluster(@args);
$results = $sa->_sshare_list_last_raw_output;
check_results(\@expargs, $results, 'usage_for_account_in_cluster, all users' );

@ulist=( 'payerle', 'kevin');
$argstr = join ',', @ulist;
@args = ( cluster=>$cluster, account=>$account, users=>[ @ulist ], nowarnings=>1);
@expargs = ( "--clusters=$cluster", "--accounts=$account", "--users=$argstr", @stdargs);
$sa->usage_for_account_in_cluster(@args);
$results = $sa->_sshare_list_last_raw_output;
check_results(\@expargs, $results, 'usage_for_account_in_cluster, 2 users' );

@args = ( cluster=>$cluster, account=>$account, users=>[], nowarnings=>1);
@expargs = ( "--clusters=$cluster", "--accounts=$account", "--users='NO SUCH USER'", @stdargs);
$sa->usage_for_account_in_cluster(@args);
$results = $sa->_sshare_list_last_raw_output;
check_results(\@expargs, $results, 'usage_for_account_in_cluster, 0 users' );

#---------------------------------------------------------
#	Test of usage_for_user_account_in_cluster
#---------------------------------------------------------

$cluster='yottascale';
$account='abc124';
$user='payerle';

@args = ( cluster=>$cluster, account=>$account, user=>$user, nowarnings=>1 );
@expargs = ( "--clusters=$cluster", "--accounts=$account", "--users=$user", @stdargs);
$sa->usage_for_user_account_in_cluster(@args);
$results = $sa->_sshare_list_last_raw_output;
check_results(\@expargs, $results, 'usage_for_user_account_in_cluster' );

#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);

