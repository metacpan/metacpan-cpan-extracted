#!/usr/bin/env perl -T
#
#Test that Slurm::Sacctmgr will barf if given any tainted data
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl -T 150_Slurm-Sshare-taint.t'

use strict;
use warnings;

use Test::More;

BEGIN {
eval "use Test::Exception";
plan skip_all => "Skipping tests because Test:Exception not found" if $@;
}
BEGIN {
eval "use Test::Taint";
plan skip_all => "Skipping tests because Test:Taint not found" if $@;
}

use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

our $num_tests_run = 0;

#Check that we _are_ in taint mode
taint_checking_ok('we _are_ in taint checking mode, right?');
$num_tests_run++;

#We need to find our testing directory, and detaint it so we can require helper routines
my $testDir = dirname(abs_path($0));
my $testDir_tainted = $testDir;
my $testDir_untainted;
if ( $testDir =~ /^(.*)$/ )
{	$testDir_untainted = $1; #Forcible untaint it
}

require "${testDir_untainted}/helpers/echo-help.pl";


my $results;
my $args;
my $err;
my $argstr;
my (@temp, @temp2);
my $eval_success;

my $sa = "Slurm::Sshare";

#Set up with untainted path to 'sshare'

my $cmdpath_untainted="${testDir_untainted}/helpers/echo_cmdline";
untainted_ok($cmdpath_untainted,'untainted cmd path is not tainted');
$num_tests_run++;

my $cmdpath_tainted="${testDir_tainted}/helpers/echo_cmdline";
tainted_ok($cmdpath_tainted,'tainted cmd path is tainted');
$num_tests_run++;

#And we need to detaint $ENV{PATH}
my $origpath = $ENV{PATH};
if ( $origpath =~ /^(.*)$/ )
{	#Forcibly detaint PATH
	$ENV{PATH} = $1;
}

$sa->sshare("$cmdpath_untainted");

#Verify things work with everything (including path to 'sshare' and PATH) untainted

$args = [ 'a', 'b', 'asdfdadfge' ];
$results = $sa->run_generic_sshare_cmd(@$args);
check_results($args, $results, 'run_generic_sshare_cmd works with all untainted');


#Verify barfs if any explicit argument is tainted
$args = [ 'a', 'b', ';rm  /very/important/file'  ];
taint($args->[2]);
throws_ok( sub { $sa->run_generic_sshare_cmd(@$args) },  '/Insecure/', 
	'run_generic_sshare_cmd fails with tainted input');
$num_tests_run++;


#Verify barfs if path to 'sshare' is tainted
$sa->sshare("$cmdpath_tainted");
$args = [ 'a', 'b', 'asdfdadfge' ]; #Not tainted
throws_ok( sub { $sa->run_generic_sshare_cmd(@$args) },  '/Insecure/', 
	'run_generic_sshare_cmd fails with tainted path to sshare');
$num_tests_run++;

#Verify barfs if PATH env var is tainted
$sa->sshare("$cmdpath_untainted");
$args = [ 'a', 'b', 'asdfdadfge' ]; #Not tainted
taint($ENV{PATH});
throws_ok( sub { $sa->run_generic_sshare_cmd(@$args) },  '/Insecure/', 
	'run_generic_sshare_cmd fails with tainted PATH');
$num_tests_run++;

done_testing($num_tests_run);

