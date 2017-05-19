#!/usr/bin/perl

use strict;
use warnings;
use NOLookup::Brreg::DataLookup;
use Encode;
use vars qw($opt_o $opt_n $opt_f $opt_t $opt_p $opt_v $opt_h);
use Getopt::Std;
use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

&getopts('hvo:n:f:p:t:');    # o=orgno, n=name, f:from_date, p:max_pages, t:to_date, v=verbose dump

if ($opt_h) {
    pod2usage();
}

unless ($opt_o || $opt_n || $opt_f || $opt_t) {
    pod2usage("An organization number, name or from/to dates must be specified!\n");
}

my $bo = NOLookup::Brreg::DataLookup->new;

if ($opt_o) {
    $bo->lookup_orgno($opt_o);
} elsif ($opt_n) {
    my $nm = decode('UTF-8', $opt_n);
    $bo->lookup_orgname($nm, $opt_p);
} elsif ($opt_f || $opt_t) {
    $bo->lookup_reg_dates($opt_f, $opt_t, $opt_p);
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
	    print $e->organisasjonsnummer, "\t",
	    $e->organisasjonsform, "\t",
	    $e->registreringsdatoEnhetsregisteret, "\t",
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

no_brreg.pl

=head1 DESCRIPTION

Uses NOLookup::Brreg::DataLookup to perform lookup on an orgnumber 
or an orgname and fetch and print the matching information.

The data found are stored as NOLookup::Brreg::Entry data objects.

=head1 USAGE

no_brreg.pl -o 985821585

no_brreg.pl -n norid 
    Note that only orgs starting with -n are listed due
    to a limitation in the Brreg API service.

no_brreg.pl -f 2017-04-29 -t 2017-04-30 -i 2 -p 1

Limitation: Up to a maximum of 500 matches (5 json pages) are listed.

Examples:

  perl no_brreg.pl -o 985821585

     Found 1 matching entries:
     985821585	AS	2003-06-30	UNINETT NORID AS

  perl no_brreg.pl -n uninett

     Found 3 matching entries:
     968100211	AS	1995-02-20	UNINETT AS
     985821585	AS	2003-06-30	UNINETT NORID AS
     814864332	AS	2015-01-26	UNINETT SIGMA2 AS

  perl no_brreg.pl  -f 2017-04-10 -t 2017-04-11

     Found 167 matching entries:
     917416699	ENK	2017-04-10	ARVID KROGSTAD
     917853711	FLI	2017-04-10	DIA- KJEMISKE AVD. 231
     818822022	ENK	2017-04-10	ANDERSEN ENTERTAINMENT
      :

Arguments:

  -o: orgnumber (9 digits)
  -n: orgname (complete name or start of name, minimum 2 chars)
  -f: from registration date (2017-04-10)
  -t: to registration date   (2017-04-11)

  When -n, -f or -t is specifed, also:
  -p: max number of pages (1..x)

  -v: verbose dump of the complete JSON data structure

=cut

1;


