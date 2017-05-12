#!/usr/bin/perl

use strict;
use warnings;
use NOLookup::BrregDifi::DataLookup;
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

unless ($opt_o or $opt_n) {
    pod2usage("An organization number or name must be specified!\n");
}

my $bo = NOLookup::BrregDifi::DataLookup->new;

if ($opt_o) {
    $bo->lookup_orgno($opt_o);
} elsif ($opt_n) {
    my $nm = decode('UTF-8', $opt_n);
    $bo->lookup_orgname($nm, $opt_p, $opt_i);
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
    
    } elsif ($bo->size >= 1) {
	print "Found ", $bo->size, " matching entries:\n";
	foreach my $e (@{$bo->data}) {
	    print $e->orgnr, "\t",
	    $e->organisasjonsform, "\t", 
	    encode('UTF-8', $e->navn), "\n";
	}
    }
    if ($opt_v) {
       print "\n--\nJSON data structure: ", 
       Dumper($bo->raw_json_decoded), "\n--\n";
    }

}


=pod

=head1 NAME

no_brreg_difi.pl

=head1 DESCRIPTION

Uses NOLookup::BrregDifi::DataLookup to perform lookup on an orgnumber 
or an orgname and fetch and print the matching information.

The data found are stored as NOLookup::BrregDifi::Entry data objects.

=head1 USAGE

no_brreg_difi.pl -o 985821585

no_brreg_difi.pl -n norid 

For -o: successful output is the orgno and orgname of the organization.

    perl no_brreg_difi.pl  -o 985821585
    Found 1 matching entries:
    985821585	UNINETT NORID AS

For -n: successful output is a list of orgno and orgname of 
    the matching organizations.
    Note that only orgs starting with -n are listed due
    to a limitation in the Brreg API service.

    perl no_brreg_difi.pl -n uninett
    Found 4 matching entries:
    968100211	UNINETT AS
    985821585	UNINETT NORID AS
    887625352	UNINETT SIGMA AS
    814864332	UNINETT SIGMA2 AS

    Up to a maximum of 100 matches are listed.

Arguments:

  -o: orgnumber

  -n: orgname (complete name or start of name, minimum 2 chars)

  When -n is specifed, also:
  -p: page number (1..x), max. number of pages
  -i: page index (1..x), which page to start on

  -v: verbose dump of the complete JSON data structure

=cut

1;


