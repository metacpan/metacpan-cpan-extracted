#!/usr/bin/perl
use strict; use warnings;

# create our test directory
mkdir( 'poe-benchmarker' ) or die "unable to mkdir: $!";

# enter it!
chdir( 'poe-benchmarker' ) or die "unable to chdir: $!";

# create the child directories
foreach my $dir ( qw( poedists results images ) ) {
	mkdir( $dir ) or die "unable to mkdir: $!";
}

# now, we actually get the POE dists
require POE::Devel::Benchmarker::GetPOEdists;
POE::Devel::Benchmarker::GetPOEdists::getPOEdists( 1 );


# run the benchmarks!
require POE::Devel::Benchmarker;
POE::Devel::Benchmarker::benchmark();

# all done!
