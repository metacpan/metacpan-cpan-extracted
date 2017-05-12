#!/usr/bin/perl

use strict;
use warnings;
use NOLookup::Patent::DataLookup;
use Encode;
use vars qw($opt_o $opt_n $opt_p $opt_i $opt_v $opt_h);
use Getopt::Std;
use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

&getopts('hvo:n:p:i:');   

if ($opt_h) {
    pod2usage();
}

unless ($opt_o || $opt_n ) {
    pod2usage("A trademark text or an application id must be specified!\n");
}

my $bo = NOLookup::Patent::DataLookup->new;

if ($opt_o) {
    $bo->lookup_tm_applid($opt_o);
} elsif ($opt_n) {
    my $nm = decode('UTF-8', $opt_n);
    $bo->lookup_tm_text($nm, $opt_p, $opt_i);
}
 
if ($bo->error) {
    print STDERR "Error: ", $bo->status, "\n";

} else {
    if ($bo->warning) {
	print STDERR "Warning: ", $bo->status, "\n";
    }
    
    #print "bo: ", Dumper $bo;
    
    if ($bo->size <1) {
	print "No match on search\n";
    
    } elsif ($bo->size >= 1 && $opt_n) {
	# Search, multiple entries on the data array
	print "Total count ", $bo->total_size, " matching entries, listing ", $bo->size, ":\n";
	foreach my $e (@{$bo->data}) {
	    print 
		encode('UTF-8', $e->status        ), "\t", 
		encode('UTF-8', $e->applicant     ), "\t",
		$e->application_number, "\t",
		encode('UTF-8', $e->trademark_text), "\n";
	}

    } elsif ($bo->size == 1 && $opt_o) {
	# One entry on the data array
	print "Single matching entry:\n";
	foreach my $e (@{$bo->data}) {
	    print 
		encode('UTF-8', $e->status        ), "\t", 
		encode('UTF-8', $e->applicant     ), "\t",
		$e->application_number, "\t",
		$e->filed_date, "\t",
		$e->last_updated, "\t",
		encode('UTF-8', $e->trademark_text), "\n";
	}

    }
    if ($opt_v) {
       print "\n--\nJSON data structure: ", 
       Dumper($bo->raw_json_decoded), "\n--\n";
    }

}


=pod

=head1 NAME

no_patent.pl

=head1 DESCRIPTION

Uses NOLookup::Patent::DataLookup to perform lookup on an
a brand name and fetch and print the matching information.

The data found are stored as NOLookup::Patent::Entry data objects.

=head1 USAGE

no_patent.pl -n solo 

no_patent.pl -o 199901548

For -o: successful output is a one single entry.

For -n: successful output is a list name of the matching trademarks.

Arguments:

  -n: trademark text (complete or part of registered tm text)

  When -n is specifed, also:
  -p: page number (1..x), max. number of pages
  -i: page index (1..x), which page to start on

  -o: application id (found from a -n operation)

  -v: verbose dump of the complete JSON data structure

=cut

1;


