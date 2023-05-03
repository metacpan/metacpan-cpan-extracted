#!/usr/bin/env perl

use strict;
use warnings;
use NOLookup::Whois::WhoisLookup;
use Encode;
use vars qw($opt_q $opt_v $opt_h $opt_s $opt_p);
use Getopt::Std;
use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

&getopts('hvq:s:p:');    # q:query, v=verbose dump, s:whois server, p:whois port

if ($opt_h) {
    pod2usage();
}

unless ($opt_q) {
    pod2usage("A query must be specified!\n");
}

my $q = decode('UTF-8', $opt_q);

my $SERVER = $opt_s || 'whois.norid.no';
my $PORT   = $opt_p || 43;

my ($wh, $do, $ho) = NOLookup::Whois::WhoisLookup->new($q, $SERVER, $PORT);

if ($wh->errno) {
    print STDERR "Whois error: ", $wh->errno, "\n";
    if ($wh->raw_text) {
	print STDERR "Raw text   : ", $wh->raw_text, "\n";
    }
    exit;
}

#print STDERR "wh: ", Dumper $wh;

if ($do) {
    # Present if a domain name or handle is queried,
    # and a match was found
    my $hret = "object is";

    print "Domain name      : ", encode('UTF-8', $do->domain_name), "\n";
    print "Registrar handle : ", $do->registrar_handle, "\n";
    print "Tech-c handle    : ", $do->tech_c_handle, "\n";
    foreach my $nh (sort(split("\n", $do->name_server_handle))) {
	print "Nameserver handle: $nh\n";
    }

    print "DNSSEC signed    : ";
    if ($do->dnssec) {
	print "yes\n";
    } else {
	print "no\n";
    }
    
    if ($ho) {
	print "Holder name      : ", encode('UTF-8', $ho->name), "\n";
	print "Holder address   : ", encode('UTF-8', $ho->post_address), "\n";
	print "Holder email     : ", encode('UTF-8', $ho->email_address), "\n";
	print "Id type          : ", encode('UTF-8', $ho->id_type), "\n";
	print "Id number        : ", encode('UTF-8', $ho->id_number), "\n";
	if ($ho->organization_type) {
	    print "Organization type: ", encode('UTF-8', $ho->organization_type), "\n";
	}
	$hret = "and holder objects are";

    }
    if ($opt_v) {
	print "Domain object raw text: ", Dumper($do->raw_text);
	print "Host object raw text  : ", Dumper($ho->raw_text) if ($ho);
    } else {
	print "Domain $hret returned, use -v to see the details\n";
    }

} else {
    # $wh contains the result of all other queries

    if ($opt_v) {
	print "Whois raw data: ", Dumper($wh->raw_text);
    } else {
	print "A whois object is returned, use -v to see the details\n";
	
    }
}

=pod

=head1 NAME

no_whois.pl

=head1 DESCRIPTION

Uses NOLookup::Whois::WhoisLookup to perform lookup on some query
from the Norid whois service.

=head1 USAGE

no_whois.pl [hvq:] <querystring>

Arguments:

  -q: query
  -v: verbose dump of the returned raw whois response
  -h: this help

Examples:

   Query on a domain name:
      perl no_whois.pl -q norid.no

   Query on a organization number:
      perl no_whois.pl -q 985821585

   Query on a domain name, verbose dump to see raw response:
      perl no_whois.pl -q norid.no -v

   Query on a contact handle, verbose dump to see raw response:
      perl no_whois.pl -q UNA165O-NORID -v

=cut

1;


