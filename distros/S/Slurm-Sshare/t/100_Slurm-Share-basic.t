#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 100_Slurm-Sshare-basic.t`
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
my $helpersDir = "${testDir}/helpers";
my $ssh1prog = 'echo_cmdline';
my $ssh2prog = 'echo_cmdline_to_stderr';
my $sshare1 = "${helpersDir}/$ssh1prog";
my $sshare2 = "${helpersDir}/$ssh2prog";

$sa->sshare($sshare1);


my $results;
my $args;
my $err;
my $argstr;
my (@temp, @temp2);

#---------------------------------------------------------
#	Tests of run_generic_sshare_cmd
#---------------------------------------------------------

$args = [ 'a', 'b', 'asefdafd-eee' ];
$results = $sa->run_generic_sshare_cmd(@$args);
check_results($args, $results, 'run_generic_sshare_cmd()');

#Now repeat in verbose mode
$sa->verbose(1);
$sa->sshare($sshare2);

$args = [ 'create', 'cluster', 'test-cluster' ];
$results = $sa->run_generic_sshare_cmd(@$args);
check_results($args, $results, 'run_generic_sshare_cmd (verbose)', $ssh2prog);

#Back to non-verbose
$sa->verbose(0);
$sa->sshare($sshare1);


done_testing($num_tests_run);

