#!/usr/bin/perl

##
## Run stress tests for Pangloss
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Getopt::Long qw( GetOptions );

use TestSimulator;

my $debug        = 0;
my $time         = 20;
my $users        = 10;
my $admins       = 0;
my $translators  = 1;
my $proofreaders = 0;

GetOptions( 'd|debug+'         => \$debug,
	    'u|users=i'        => \$users,
	    'a|admins=i'       => \$admins,
	    'x|translators=i'  => \$translators,
	    'p|proofreaders=i' => \$proofreaders,
	    't|time=i'         => \$time, );

local $| = 1;

if ($debug) {
    warn "debug set to $debug\n";
    $Pangloss::DEBUG{ALL} = $debug;
}

my $sim = TestSimulator->new;
$sim->{time}         = $time;
$sim->{users}        = $users;
$sim->{admins}       = $admins;
$sim->{translators}  = $translators;
$sim->{proofreaders} = $proofreaders;

$sim->simulate;

exit 0;


# try and trick Benchmark.pm into producing fractional 'real' times
package Benchmark;
use Time::HiRes qw( time );

