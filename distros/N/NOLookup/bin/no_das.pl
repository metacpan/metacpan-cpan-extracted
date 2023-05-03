#!/usr/bin/env perl

use strict;
use warnings;
use NOLookup::DAS::DASLookup;
use Encode;
use vars qw($opt_q $opt_v $opt_h $opt_s $opt_p);
use Getopt::Std;
use Pod::Usage;

use Data::Dumper;
$Data::Dumper::Indent=1;

&getopts('hvq:s:p:');    # q:query, v=verbose dump

if ($opt_h) {
    pod2usage();
}

unless ($opt_q) {
    pod2usage("A query must be specified!\n");
}

my $q = decode('UTF-8', $opt_q);

my $SERVER = $opt_s || 'finger.norid.no';
my $PORT   = $opt_p || 79;

my $das = NOLookup::DAS::DASLookup->new($q, $SERVER, $PORT);

if ($das->errno) {
    print STDERR "Error   : ", $das->errno, "\n";
    if ($das->raw_text) {
	print STDERR "Raw text: ",  encode('UTF-8', $das->raw_text), "\n";
    }
    
} elsif ($das->available) {
    print "Domain is available and can be registered\n";

} elsif ($das->delegated) {
    print "Domain is not available because it is already registered\n";

} elsif ($das->prohibited) {
    print "Domain cannot be registered due to local registry policy\n";

} elsif ($das->invalid) {
    print "Domain or zone is invalid\n";
}

if ($opt_v) {
    print "DAS raw data: ", encode('UTF-8', $das->raw_text), "\n";
}

=pod

=head1 NAME

no_das.pl

=head1 DESCRIPTION

Uses NOLookup::DAS::DASLookup to perform lookup on a domain name
to check the domain availabilty status.

=head1 USAGE

no_das.pl [hvq:] <querystring>

Arguments:

  -q: query string, must be a .no domain name
  -v: verbose dump of the returned raw DAS response
  -h: this help

Examples:

   Check if 'norid.no' is available:
      no_das.pl -q norid.no

   Check if 'norid.no' is available, -v set to see raw response:
      no_das.pl -q norid.no -v

=cut

1;


