#!/usr/bin/perl

use strict;
use warnings;
use NOLookup::Brreg::DataLookup;
use Encode;

use vars qw / 
    $opt_o $opt_n $opt_f $opt_t $opt_p $opt_i $opt_u 
    $opt_d $opt_x $opt_v $opt_h
    /;
use Getopt::Std;

use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

# Use this to activate LWP debug,
# ref. https://metacpan.org/pod/LWP::ConsoleLogger::Everywhere
#use LWP::ConsoleLogger::Everywhere;

&getopts('hvuo:n:f:p:t:i:d:x:');

if ($opt_h) {
    pod2usage();
}

unless ($opt_o || $opt_n || $opt_f || $opt_t || $opt_d || $opt_x) {
    pod2usage("An organization number, name, from/to dates or update date or -id must be specified!\n");
}

my $h1 = "OrgNumber\tOrgForm\tregDate  \torgName";
my $h2 = "OrgNumber\tupdateDateTime\t\t\tupdateId";

my $bo = NOLookup::Brreg::DataLookup->new;

if ($opt_o) {
    $bo->lookup_orgno($opt_o, $opt_u);

} elsif ($opt_n) {
    my $nm = decode('UTF-8', $opt_n);
    $bo->lookup_orgname($nm, $opt_p, $opt_i, $opt_u);

} elsif ($opt_f || $opt_t) {
    $bo->lookup_reg_dates($opt_f, $opt_t, $opt_p, $opt_i, $opt_u);

} elsif ($opt_d || $opt_x) {
    $bo->lookup_update_dates($opt_d, $opt_x, $opt_p, $opt_i, $opt_u);
}
 
if ($bo->error) {
    print STDERR "Error: ", $bo->status, "\n";
    exit;
}

if ($bo->warning) {
    print STDERR "Warning: ", $bo->status, "\n";
}

my $etype = "(Enhet)";

if ($opt_u) {
    $etype = "(UnderEnhet)";
}

#print STDERR "bo: ", Dumper $bo;

if ($bo->size <1) {
    print "No match on $etype search\n";
    
} elsif ($bo->size == 1) {
    print "Found ", $bo->size, " matching $etype entries:\n";
    print "$h1\n";
    foreach my $e (@{$bo->data}) {
	print $e->organisasjonsnummer, "\t",
            $e->organisasjonsform->{kode}, "\t",
            $e->registreringsdatoEnhetsregisteret || ($e->slettedato . " (slettet)"), "\t",
            encode('UTF-8', $e->navn), "\n";
    }
} elsif ($bo->size > 1 && ($opt_n || $opt_f || $opt_t)) {
    print "Found ", $bo->size, " matching $etype entries:\n";
    print "$h1\n";
    foreach my $e (@{$bo->data}) {
	print $e->organisasjonsnummer, "\t",
            $e->organisasjonsform->{kode}, "\t",
            $e->registreringsdatoEnhetsregisteret, "\t",
            encode('UTF-8', $e->navn), "\n";
    }
    
} elsif ($bo->size > 1 && ($opt_d || $opt_x)) {
    print "Found ", $bo->size, " matching updated $etype entries:\n";
    print "$h2\n";
    foreach my $e (@{$bo->data}) {
	print $e->organisasjonsnummer, "\t",
	    $e->dato, "\t",
	    $e->oppdateringsid, "\n";
    }
}

if ($opt_v) {
    print "\n--\nJSON data structure: ", 
	Dumper($bo->raw_json_decoded), "\n--\n";
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
     OrgNumber	OrgForm	regDate  	orgName
     985821585  AS      2003-06-30      UNINETT NORID AS

  perl no_brreg.pl -n uninett 

     Found 4 matching (Enhet) entries:
     OrgNumber	OrgForm	regDate  	orgName
     819549532	FLI	2017-09-12	UNINETT PENSJONISTFORENING
     968100211  AS      1995-02-20      UNINETT AS
     985821585  AS      2003-06-30      UNINETT NORID AS
     814864332  AS      2015-01-26      UNINETT SIGMA2 AS

     If name consists of several words, hits on each word is also
     found.

  perl no_brreg.pl -n uninett -u

     Found 3 matching (UnderEnhet) entries:
     OrgNumber	OrgForm	regDate  	orgName
     973897187 BEDR    1995-02-23      UNINETT AS
     986671773 BEDR    2004-03-11      UNINETT NORID AS
     987631473 BEDR    2004-12-22      UNINETT SIGMA2 AS

  perl no_brreg.pl -n "uninett as" -p3

     Found 300 matching (Enhet) entries:
     OrgNumber	OrgForm	regDate  	orgName
     968100211	AS	1995-02-20	UNINETT AS
     985821585	AS	2003-06-30	UNINETT NORID AS
     814864332	AS	2015-01-26	UNINETT SIGMA2 AS
     819549532	FLI	2017-09-12	UNINETT PENSJONISTFORENING
     918312080	AS	2017-01-24	AS TRANSPORT AS
     918591052	AS	2017-02-21	AS HOLDING AS
     :
     :
     Lists max. 3 pages, each of 100 hits. Default max. pages are 10, e.g. 1000 hits.

  perl no_brreg.pl  -f 2019-02-23 -t 2019-02-24 

     Found 10 matching (Enhet) entries:
     OrgNumber	OrgForm	regDate  	orgName
     922173222	AS	2019-02-23	AERO DRAGBAG AS
     922141266	NUF	2019-02-23	COMAEN B.V.
     922266433	AS	2019-02-23	SVÅBEKK 15 AS
     922082510	ENK	2019-02-23	SHIRAZI ISOKONTROLL MEHDI SADEGHINEJADIAN SHIRAZI
     922084823	ENK	2019-02-23	MOFRAD HMS MOHAMMAD NEKOOMANESHMOFRAD
     :


  perl ./no_brreg.pl  -d 2019-02-25 -p1

     Found 100 matching updated (Enhet) entries:
     OrgNumber	updateDateTime			updateId
     816860482	2019-02-25T05:01:06.526Z	2686439
     816860482	2019-02-25T05:01:47.969Z	2686443
     958292104	2019-02-25T05:01:47.969Z	2686445
     :
     :

  perl no_brreg.pl  -d 2019-02-25 -p1 -x 2687774

     Found 2 matching updated (Enhet) entries:
     OrgNumber	updateDateTime			updateId
     919640170	2019-02-25T18:25:34.449Z	2687776
     919640170	2019-02-25T18:26:16.002Z	2687778

     List enheter on date and with optional updateId 

Arguments:

  -o: orgnumber (9 digits)

  -n: orgname (complete name or start of name, minimum 2 chars)

  To list entries registered in period from/to date:
  -f: from registration date (2017-04-10)
  -t: to registration date   (2017-04-11)

  To list entries updated/changed since update date/id:
  -d: from update date       (2017-04-11)
  -x: from update id         (1234)

  When -n, -f, -t, -d or -i is specifed, also:
  -u: search in underenheter, else enheter.
  -p: max number of pages (1..x, default 10). 100 hits per page.
  -i: page index (0..x), which page to start on

  Other:
  -h: help
  -v: verbose dump of the complete JSON data structure

=cut

1;


