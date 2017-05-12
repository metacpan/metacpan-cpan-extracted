#!/usr/bin/perl -w
####################################################
# idx_and_search.pl - SWISH::API::Common test script
# Mike Schilli, 2005 (m@perlmeister.com)
####################################################
use strict;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($ERROR);

use SWISH::API::Common;

    # Generate index
my $sw = SWISH::API::Common->new();
$sw->index("/tmp");

    # Search for "michael"
my @results = $sw->search("michael");

    # Print results
if(@results) {
    for my $hit (@results) {
        print $hit->path(), "\n";
    }
} else {
    print "No results\n";
}
