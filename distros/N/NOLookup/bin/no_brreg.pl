#!/usr/bin/perl

use strict;
use warnings;
use NOLookup::Brreg::DataLookup;
use Encode;
use vars qw($opt_o $opt_n $opt_f $opt_t $opt_p $opt_u $opt_d $opt_i $opt_v $opt_h);
use Getopt::Std;
use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

# o=orgno, n=name, f:from_date, t:to_date, p:max_pages
# d=update_date, i:update_id
# u:underenhet, , v=verbose dump
&getopts('hvuo:n:f:p:t:i:d:');

if ($opt_h) {
    pod2usage();
}

unless ($opt_o || $opt_n || $opt_f || $opt_t || $opt_d || $opt_i) {
    pod2usage("An organization number, name, from/to dates or update date or id must be specified!\n");
}

my $h1 = "OrgNumber\tOrgForm\tregDate  \torgName";
my $h2 = "OrgNumber\tupdateDateTime\t\t\tupdateId";

my $bo = NOLookup::Brreg::DataLookup->new;

if ($opt_o) {
    $bo->lookup_orgno($opt_o, $opt_u);

} elsif ($opt_n) {
    my $nm = decode('UTF-8', $opt_n);
    $bo->lookup_orgname($nm, $opt_p, $opt_u);

} elsif ($opt_f || $opt_t) {
    $bo->lookup_reg_dates($opt_f, $opt_t, $opt_p, $opt_u);

} elsif ($opt_d || $opt_i) {
    $bo->lookup_update_dates($opt_d, $opt_i, $opt_p, $opt_u);
}
 
if ($bo->error) {
    print STDERR "Error: ", $bo->status, "\n";

} else {
    if ($bo->warning) {
        print STDERR "Warning: ", $bo->status, "\n";
    }

    my $ue = "";

    if ($opt_u) {
        $ue = "\t(UnderEnhet)";
    }
    #print STDERR "bo: ", Dumper $bo;
    
    if ($bo->size <1) {
        print "$ue: No match on search\n";
    
    } elsif ($bo->size == 1) {
        print "Found ", $bo->size, " matching entries:\n";
        print "$h1\n";
        foreach my $e (@{$bo->data}) {
            print $e->organisasjonsnummer, "\t",
            $e->organisasjonsform->{kode}, "\t",
            $e->registreringsdatoEnhetsregisteret || ($e->slettedato . " (slettet)"), "\t",
            encode('UTF-8', $e->navn), "$ue\n";
        }
    } elsif ($bo->size > 1 && ($opt_n || $opt_f || $opt_t)) {
        print "Found ", $bo->size, " matching entries:\n";
        print "$h1\n";
        foreach my $e (@{$bo->data}) {
            print $e->organisasjonsnummer, "\t",
            $e->organisasjonsform->{kode}, "\t",
            $e->registreringsdatoEnhetsregisteret, "\t",
            encode('UTF-8', $e->navn), "$ue\n";
        }

    } elsif ($bo->size > 1 && ($opt_d || $opt_i)) {
        print "Found ", $bo->size, " matching updated entries:\n";
        print "$h2\n";
        foreach my $e (@{$bo->data}) {
            print $e->organisasjonsnummer, "\t",
                $e->dato, "\t",
                $e->oppdateringsid, "$ue\n";
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

Up to a maximum of 1000 matches (10 json pages) are listed.

Examples:

  perl no_brreg.pl -o 985821585

     Found 1 matching entries:
     985821585  AS      2003-06-30      UNINETT NORID AS

  perl no_brreg.pl -n uninett 

     Found 3 matching entries:
     968100211  AS      1995-02-20      UNINETT AS
     985821585  AS      2003-06-30      UNINETT NORID AS
     814864332  AS      2015-01-26      UNINETT SIGMA2 AS

     If name consists of several words, hits on each word is also
     found.

  perl no_brreg.pl -n uninett -u
     Found 3 matching entries:
     973897187 BEDR    1995-02-23      UNINETT AS      (UnderEnhet)
     986671773 BEDR    2004-03-11      UNINETT NORID AS        (UnderEnhet)
     987631473 BEDR    2004-12-22      UNINETT SIGMA2 AS       (UnderEnhet)

  perl no_brreg.pl -n "uninett as" -p 3
     Found 3 matching entries:
     973897187 BEDR    1995-02-23      UNINETT AS      (UnderEnhet)
     986671773 BEDR    2004-03-11      UNINETT NORID AS        (UnderEnhet)
     987631473 BEDR    2004-12-22      UNINETT SIGMA2 AS       (UnderEnhet)

     Lists max. 3 pages, each 100 hits. Default max. pages are 10, e.g. 1000 hits.

  perl no_brreg.pl  -f 2017-04-10 -t 2017-04-11

     Found 167 matching entries:
     917416699  ENK     2017-04-10      ARVID KROGSTAD
     917853711  FLI     2017-04-10      DIA- KJEMISKE AVD. 231
     818822022  ENK     2017-04-10      ANDERSEN ENTERTAINMENT
      :

  perl no_brreg.pl  -d 2017-04-10
     Found 167 matching entries:
     917416699  ENK     2017-04-10      ARVID KROGSTAD


Arguments:

  -o: orgnumber (9 digits)

  -n: orgname (complete name or start of name, minimum 2 chars)

  To list entries registered in period from/to date:
  -f: from registration date (2017-04-10)
  -t: to registration date   (2017-04-11)

  To list entries updated/changed since update date/id:
  -d: from update date       (2017-04-11)
  -i: from update id         (1234)

  When -n, -f, -t, -d or -i is specifed, also:
  -u: search in underenheter, else enheter.
  -p: max number of pages (1..x, default 10). 100 hits per page.

  Other:
  -h: help
  -v: verbose dump of the complete JSON data structure

=cut

1;


