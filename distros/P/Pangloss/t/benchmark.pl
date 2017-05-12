#!/usr/bin/perl

##
## Run search benchmarks for Pangloss
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use File::Spec;
use File::Basename;
use Getopt::Long qw( GetOptions );
use TestSimulator::User;

my $debug    = 0;
my $time     = 20;
my $log_file = File::Spec->catfile(qw( t tmp benchmark.csv ));

GetOptions( 'd|debug+' => \$debug,
	    't|time=i' => \$time,
	    'l|log=s'  => \$log_file, );

local $| = 1;

if ($debug) {
    warn "debug set to $debug\n";
    $Pangloss::DEBUG{ALL} = $debug;
}

my $log_dir = dirname( $log_file );
unless (-d $log_dir) {
    require File::Path;
    import File::Path;
    warn "making path: $log_dir" if $debug;
    mkpath( $log_dir );
}

my $sim = TestSimulator::User->new
  ->log_file( $log_file )
  ->simulate( $time );

print "Benchmark details are in $log_file.\n";

exit 0;
