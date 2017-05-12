#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 100_Slurm-Sacctmgr-basic.t'
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sacctmgr;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;

require "${testDir}/helpers/echo-help.pl";

my $sa1 = Slurm::Sacctmgr->new(sacctmgr=>"${testDir}/helpers/echo_cmdline");
my $sa2 = Slurm::Sacctmgr->new(sacctmgr=>"${testDir}/helpers/echo_cmdline_to_stderr");
my $sa2prog = 'echo_cmdline_to_stderr';

my $results;
my $args;
my $err;
my $argstr;
my (@temp, @temp2);

$args = [ 'create', 'cluster', 'test-cluster' ];
$results = $sa1->run_generic_sacctmgr_cmd(@$args);
check_results($args, $results, 'run_generic_sacctmgr_cmd');

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa1->run_generic_safe_sacctmgr_cmd(@$args);
$args = [ @$args, '--readonly' ];
check_results($args, $results, 'run_generic_safe_sacctmgr_cmd');

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa1->run_generic_sacctmgr_list_command(@$args);
$results = [ map { $_->[0] } @$results ];
$args = [ @$args, '--parsable2', '--noheader', '--readonly' ];
check_results($args, $results, 'run_generic_sacctmgr_list_command');

#Now repeat in verbose mode

$sa2->verbose(1);

$args = [ 'create', 'cluster', 'test-cluster' ];
$results = $sa2->run_generic_sacctmgr_cmd(@$args);
check_results($args, $results, 'run_generic_sacctmgr_cmd (verbose)', $sa2prog);

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa2->run_generic_safe_sacctmgr_cmd(@$args);
$args = [ @$args, '--readonly' ];
check_results($args, $results, 'run_generic_safe_sacctmgr_cmd (verbose)', $sa2prog);

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa2->run_generic_sacctmgr_list_command(@$args);
$results = [ map { $_->[0] } @$results ];
$args = [ @$args, '--parsable2', '--noheader', '--readonly' ];
check_results($args, $results, 'run_generic_sacctmgr_list_command (verbose)', $sa2prog);

#Now repeat in dryrun mode

$sa2->verbose(0);
$sa2->dryrun(1);

$args = [ 'create', 'cluster', 'test-cluster' ];
$results = $sa2->run_generic_sacctmgr_cmd(@$args);
#check_results($args, $results, 'run_generic_sacctmgr_cmd (dryrun)', $sa2prog);
#This one should fail to run
is_deeply($results, [], 'run_generic_sacctmgr_cmd (dryrun)');
$num_tests_run++;

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa2->run_generic_safe_sacctmgr_cmd(@$args);
$args = [ @$args, '--readonly' ];
check_results($args, $results, 'run_generic_safe_sacctmgr_cmd (dryrun)', $sa2prog);

$args = [ 'show', 'user', "cluster='test-cluster'", ];
$argstr = join ' ', @$args;
$results = $sa2->run_generic_sacctmgr_list_command(@$args);
$results = [ map { $_->[0] } @$results ];
$args = [ @$args, '--parsable2', '--noheader', '--readonly' ];
check_results($args, $results, 'run_generic_sacctmgr_list_command (dryrun)', $sa2prog);



done_testing($num_tests_run);

