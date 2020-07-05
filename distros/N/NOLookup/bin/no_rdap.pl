#!/usr/bin/perl 

# This client is inspired by rdapper:
# https://metacpan.org/source/GBROWN/rdapper-0.3
#

use strict;
use warnings;
use NOLookup::RDAP::RDAPLookup 1.19;
use NOLookup::RDAP::RDAPLookup::Whois 1.19;
use Encode;
use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor;
use JSON;

use Data::Dumper;
$Data::Dumper::Indent=1;

my ($service_url, $query, $check, $nameservers, $entity, $help,
    $debug, $verbose, $expand, $short, $use_cache, $header_secret,
    $header_proxy, $referral_ip, $whois_fmt, $force_ipv4);

##
# Default test values unless overrided by their parameters
my $use_test_values  = 1;
my $test_service_url = $ENV{RDAP_SERVICE_URL}             || 'https://rdap.test.norid.no';
my $test_secret      = $ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN} || '';
my $test_proxy       = $ENV{RDAP_GDPR_NORID_PROXY}        || '';
my $test_referral_ip = 0; # or and ip, like '1.2.3.4';
my $test_expand      = 0;
my $test_force_ipv4  = 1;

GetOptions(
    'service_url|s:s'   => \$service_url,
    'query|q:s'	        => \$query,
    'check|c'           => \$check,
    'nameservers|n'     => \$nameservers,
    'entity|e'          => \$entity,
    'header_proxy|p:i'  => \$header_proxy,
    'header_secret|z:s' => \$header_secret,
    'referral_ip|i:s'   => \$referral_ip,
    'expand|x'	        => \$expand,
    'short'	        => \$short,
    'use_cache|u'       => \$use_cache,
    'debug|d:i'         => \$debug,
    'help|h'	        => \$help,
    'verbose|v'         => \$verbose,
    'whois_fmt|w'       => \$whois_fmt,
    'force_ipv4|f:i'    => \$force_ipv4,
);

pod2usage('-verbose' => 99, '-sections' => [qw(NAME DESCRIPTION USAGE)]) if ($help);

unless ($query) {
    pod2usage("A query (-q) being a domainname, identity, nameserver name or a handle must be specified!\n");
}

if ($use_test_values) {
    $service_url   = $test_service_url unless $service_url;
    $header_secret = $test_secret      unless defined($header_secret);
    $header_proxy  = $test_proxy       unless defined($header_proxy);
    $referral_ip   = $test_referral_ip unless defined($referral_ip);
    $expand        = $test_expand      unless $expand;
    $force_ipv4    = $test_force_ipv4  unless defined($force_ipv4);
}

if ($force_ipv4) {
    # Use ipv4 only sockets and addresses
    use IO::Socket::SSL 'inet4';
}

sub print_warnings {
    my (@params) = @_;

    print STDERR colored([qw(yellow)], "Warnings:\n");
    foreach my $el (@params) {
	my $str = encode('UTF-8', sprintf(" %s", $el));
	print STDERR colored([qw(yellow)], $str)."\n";
    }
}

sub print_errors {
    my (@params) = @_;

    print STDERR colored([qw(red)], "Errors:\n");
    foreach my $el (@params) {
	my $str = encode('UTF-8', sprintf(" %s", $el));
	print STDERR colored([qw(red)], $str)."\n";
    }
    exit 1;
}

my $ro;

if ($whois_fmt) {

    $ro = NOLookup::RDAP::RDAPLookup::Whois->new(
    {
	service_url         => $service_url ,
	debug               => $debug || 0,
	use_cache  	    => $use_cache,
	norid_header_secret => $header_secret,
	norid_header_proxy  => $header_proxy,
	norid_referral_ip   => $referral_ip,
    });

} else {
    
    $ro = NOLookup::RDAP::RDAPLookup->new(
    {
	service_url         => $service_url ,
	debug               => $debug || 0,
	use_cache  	    => $use_cache,
	norid_header_secret => $header_secret,
	norid_header_proxy  => $header_proxy,
	norid_referral_ip   => $referral_ip,
    });

}

##
# Validation and analyzing what type of query is done by the lookup
#
$ro->lookup($query, $check, $nameservers, $entity);

if ($debug) {
    print STDERR "$0: Looked up: ", $ro->_method, "/ ", $ro->_full_url;
    print STDERR " (connecting over ipv4 since force_ipv4 option is set)" if ($force_ipv4);
    print STDERR "\n";
}

if ($ro->error) {
    print_errors($ro->error, $ro->status);

} elsif ($ro->warning) {
    print_warnings(sprintf("%s", $ro->warning, $ro->status));
}

if ($check) {
    print "\n-- HEAD (check) operation OK, query $query found --\n";
    exit 0;
}

print "\n-- GET (lookup) operation OK, query $query found --\n";
print "-- Use the -v 1 option to see the raw JSON content --\n" unless ($verbose);


my $result = $ro->result;
#print STDERR "ro result: ", Dumper $result;
print "lookup up class: ", $result->class, "\n" if ($result->class);
## Print structured output

if ($verbose) {
    unless ($check) {
	print "\n--\nJSON raw data structure pretty: '", $ro->raw_json_decoded, "'\n--\n";
    }
}

my ($rs, $errs);

if ($whois_fmt) {
    # Make a whois string of the rdap result
    ($rs, $errs) = $ro->result_as_norid_whois_string($check, $nameservers, $entity, $expand);

    if ($rs) {
	print "Whois conversion gave:\n", encode('UTF-8', $rs . "\n\n");

	#print STDERR " from result: ", Dumper $result;
	
	###
	# Make whois objects of the whois string
	my ($wh, $do, $ho) = $ro->norid_whois_parse($rs);

	#print "no_rdap.pl, wh: ", Dumper $wh if ($wh);
	#print "no_rdap.pl, do: ", Dumper $do if ($do);
	#print "no_rdap.pl, ho: ", Dumper $ho if ($ho);
	
    }

} else {
    ($rs, $errs) = $ro->result_as_rdap_string($check, $nameservers, $entity, $short, $expand);

    print encode('UTF-8', "$rs\n\n") if ($rs);
    
}

if ($errs && @$errs) {
    print_warnings(@$errs);
}

    
=pod

=head1 NAME

no_rdap.pl

=head1 DESCRIPTION

Default behaviour:
 Uses NOLookup::RDAP::RDAPLookup to perform RDAP lookup on domain
 related queries and fetch and print the matching information in a
 textual format inspired by rdapper.

With the -w option: 
 Uses NOLookup::RDAP::RDAPLookup::Whois to perform RDAP lookup on
 domain related queries and fetch and print the matching information in
 Norid old school whois format (rdap2whois behaviour).

=head1 USAGE

 perl no_rdap.pl -q <query>

Examples:

  no_rdap.pl -q norid.no
  no_rdap.pl -q nn.uninett.no -n
  no_rdap.pl -q 985821585

  no_rdap.pl -q UH9R-NORID
  no_rdap.pl -q NN14H-NORID
  no_rdap.pl -q REG2-NORID -w

Mandatory arguments:

  -q: query, one of:
      - domain name 
      - nameserver name (when -n is also set)
      - handle, if query matches a handle (P/O/R/H/REG (D not
        supported, use domain name))
      - identity: if query is a holder identity [ 985821585 | N.PRI.xxx ], a search is
        performed to find matching domains
        (other legacy identities like N.{ORG|LEG}.xxxx are not supported).
      - identity: if query is a O/P holder handle, a search is
        performed to find matching domains
        if -e is set, the handle object is looked up instead
      
 Optional arguments:

  -n: query is a nameserver name
  -s: The full http(s)-address (URL) of the RDAP service (default is
      https://rdap.test.norid.no)
  -c: Do a HEAD instead of the default GET. HEAD returns no data, and
      can be used to check existence of domain etc.
  -z: Secret to access layer with higher amount of visible data
      (default is basic layer)
  -p: Act as a Norid proxy (for Norid use only)
  -i: the ip address of the client UA for proper referral rate
      limiting (default is none)
  -e: lookup entity instead of doing a search
  -s: present short result ( only when -w not set)
  -x: expand result, do additinal lookups if data is truncated
  -f: force ipv4 connection

 Format for output of the result:

  -w: dump result in old style Norid whois format (default is a
      rudimentary output inspired by rdapper)

  Other:
  -d: debug: 1: Simple debug, 5: activate also ua debug in http lookup
      libraries
  -u: activate Net::RDAP library caching
  -v: verbose: dump JSON result received from RDAP
  -h: help

=cut

1;


