#!/usr/bin/perl -w

# This is the scanning counterpart to zoomscan.pl's searching
# perl -I../../blib/lib -I../../blib/arch zoomscan.pl <target> <scanQuery>
#
# For example (using Z39.50 and SRW, Type-1 and CQL):
# perl zoomscan.pl tcp:localhost:8018/IR-Explain---1 '@attr 1=dc.title the'
# perl zoomscan.pl http://localhost:8018/IR-Explain---1 '@attr 1=dc.title the'
# perl zoomscan.pl -q http://localhost:8018/IR-Explain---1 'dc.title=the'

use strict;
use warnings;
use Getopt::Std;
use ZOOM;

my %opts;
if (!getopts('q', \%opts) || @ARGV != 2) {
    print STDERR "Usage: $0 [options] target scanQuery
	-q	Query is CQL [default: PQF]
	eg. $0 z3950.indexdata.dk/gils computer\n";
    exit 1;
}

my($host, $scanQuery) = @ARGV;

eval {
    my $conn = new ZOOM::Connection($host, 0);
    $conn->option(preferredRecordSyntax => "usmarc");
    ### Could use ZOOM::Query::CQL below, but that only works in SRU/W.
    my $q = $opts{q} ? new ZOOM::Query::CQL($scanQuery) :
		       new ZOOM::Query::PQF($scanQuery);
    my $ss = $conn->scan($q);
    my $n = $ss->size();
    for my $i (0..$n-1) {
	my($term, $occ) = $ss->term($i);
	print $i+1, ": $term";
	print " ($occ)" if defined $occ;
	print "\n";
    }
    
    $ss->destroy();
    $conn->destroy();
}; if ($@) {
    die "Non-ZOOM error: $@" if !$@->isa("ZOOM::Exception");
    print STDERR "ZOOM error $@\n";
    exit 1;
}
