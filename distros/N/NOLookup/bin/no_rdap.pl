#!/usr/bin/env perl

# This client is inspired by rdapper:
# https://metacpan.org/source/GBROWN/rdapper-0.3
#

use strict;
use warnings;
use NOLookup::RDAP::RDAPLookup qw / $sepln %RDAP_FIELDSETS %RDAP_REGISTERED_LAYERS/;
use NOLookup::RDAP::RDAPLookup::Whois;
use Encode;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use Term::ANSIColor;
use JSON;

use Data::Dumper;
$Data::Dumper::Indent=1;

my ($service_url, $query, $check, $nameservers, $rawtype, $fieldset,
    $cursor, $nopages, $entity, $help, $debug, $verbose, $expand,
    $short, $use_cache, $header_secret, $header_proxy, $referral_ip,
    $whois_fmt, $force_ipv, $bauth_username, $bauth_password, $color,
    @access_layers);


my $BG_COL_GREY   = 'on_grey23';
my $FG_COL_YELLOW = 'yellow';
my $FG_COL_RED    = 'red';

# Reset any term colors
print color('reset'), "\n";

##
# Default test values unless overrided by their parameters
my $use_test_values  = 1;
my $test_service_url = $ENV{RDAP_SERVICE_URL}             || 'https://rdap.test.norid.no';
my $test_secret      = $ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN} || '';
my $test_proxy       = $ENV{RDAP_GDPR_NORID_PROXY}        || '';
my $test_referral_ip = 0; # or an ip, like '1.2.3.4';
my $test_expand      = 0;

GetOptions(
    'service_url|s:s'    => \$service_url,
    'query|q:s'          => \$query,
    'check|c'            => \$check,
    'nameservers|n:i'    => \$nameservers,
    'entity|e'           => \$entity,
    'header_proxy|y:i'   => \$header_proxy,
    'header_secret|z:s'  => \$header_secret,
    'referral_ip|I:s'    => \$referral_ip,
    'expand|x'           => \$expand,
    'short|o'	         => \$short,
    'use_cache|a'        => \$use_cache,
    'debug|d:i'          => \$debug,
    'help|h'	         => \$help,
    'verbose|v'          => \$verbose,
    'whois_fmt|w'        => \$whois_fmt,
    'force_ipv|f:i'      => \$force_ipv,
    'bauth_username|U:s' => \$bauth_username,
    'bauth_password|P:s' => \$bauth_password,
    'color|l'            => \$color,
    'rawtype|r'          => \$rawtype,
    'fieldset|F:s'       => \$fieldset,
    'cursor|C:s'         => \$cursor,
    'nopages|p:i'        => \$nopages,
    'access_layers|a:s@' => \@access_layers,

    ) or pod2usage('-verbose' => 99, '-sections' => [qw(NAME DESCRIPTION USAGE)]);


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
}

sub print_warnings {
    my (@params) = @_;

    print STDERR color($FG_COL_YELLOW) if $color;
    print STDERR "Warnings:\n";

    foreach my $el (@params) {
	next unless $el;
	my $str = encode('UTF-8', sprintf(" %s", $el));
	print STDERR $str, "\n";
    }
    print color('reset'), "\n" if $color;
    
}

sub print_errors {
    my (@params) = @_;

    print STDERR color($FG_COL_RED) if $color;
    print STDERR "Errors:\n";

    foreach my $el (@params) {
	next unless $el;
	my $str = encode('UTF-8', sprintf(" %s", $el));
	print STDERR $str, "\n";
    }
    print color('reset'), "\n" if $color;
}

sub print_verbose {
    my $ro = shift;

    if ($verbose) {
	unless ($check) {
	    print $sepln;
	    print "\n--\nJSON raw data structure pretty: '", $ro->raw_json_decoded, "'\n--\n";
	}
    }
}

my $ro;

my %OPTIONS = (
    service_url         => $service_url ,
    debug               => $debug || 0,
    use_cache  	        => $use_cache,
    norid_header_secret => $header_secret,
    norid_header_proxy  => $header_proxy,
    norid_referral_ip   => $referral_ip,
    bauth_username      => $bauth_username,
    bauth_password      => $bauth_password,
    rawtype             => $rawtype,
    fieldset            => $fieldset,
    cursor              => $cursor,
    nopages             => $nopages,
    force_ipv           => $force_ipv,
    );

# Default access layers are those known by NOLookup lib.
# Application can override by passing other values.
if (@access_layers) {
    # Use passed access layers
    my %hal = map {$_ => 1} sort @access_layers;
    $OPTIONS{access_layers} = \%hal;
}

#print STDERR "OPTIONS: ", Dumper \%OPTIONS;

if ($force_ipv) {
    # Try to connect on the requested protocol, if possible
    unless ($force_ipv == 4 || $force_ipv == 6) {
	pod2usage("The -f option must specify 4 or 6!\n");
    }
}

if ($whois_fmt) {
    $ro = NOLookup::RDAP::RDAPLookup::Whois->new({ %OPTIONS });
} else {
    $ro = NOLookup::RDAP::RDAPLookup->new({ %OPTIONS });
}

##
# Validation and analyzing what type of query is done by the lookup
#

$ro->lookup($query, $check, $nameservers, $entity);

if ($ro->error) {
    print_verbose($ro);
    print_errors($ro->error, $ro->status, $ro->description);
    exit 1;
}

if ($ro->warning) {
    print_verbose($ro);
    print_warnings($ro->warning, $ro->status, $ro->description);
} else {
    print_verbose($ro);
}

if ($debug) {
    print STDERR $sepln;
    print STDERR "$0:\n";
    print STDERR " (connecting over ipv $force_ipv since force_ipv option is set)\n" if ($force_ipv);
    print STDERR " Looked up              : ", $ro->_method, "/ ", $ro->_full_url, "\n";
    print STDERR " Acccess layer set to   : ", $ro->access_layer, "\n";
    print STDERR " Size of returned data  : ", $ro->size || 0, "\n";

    # paging data
    if ($ro->is_a_search) {
	# Cursors to pages
        print STDERR " Is a search, page info :\n";
	print STDERR "  page_size : ", $ro->page_size  || '-', "\n";
	print STDERR "  first_page: ", $ro->first_page || '-', "\n";
	print STDERR "  cur_page  : ", $ro->cur_page   || '-', "\n";
        print STDERR "  prev_page : ", $ro->prev_page  || '-', "\n";
        print STDERR "  next_page : ", $ro->next_page  || '-', "\n";
        print STDERR "  size      : ", $ro->size       || '-', "\n";
        print STDERR "  total_size: ", $ro->total_size || '-', "\n";
	
    }
    print STDERR $sepln;
}

if ($check) {
    print "\n-- HEAD (check) operation OK, query '$query' found --\n";
    exit 0;
}

if ($debug) {
    print $sepln;
    print " GET (lookup) operation OK, query '$query' found\n";
    print " Use the -v option to see the raw JSON content\n" unless ($verbose);
}

my $result = $ro->result;
#print STDERR "ro result: ", Dumper $result;
#print "lookup up class: ", $result->class, "\n" if ($result->class);
## Print structured output

my ($rs, $errs);

print $sepln if ($debug);

if ($whois_fmt) {
    # Make a whois string of the rdap result
    $ro->{insert_page_info} = 1;

    ($rs, $errs) = $ro->result_as_norid_whois_string($check, $nameservers, $entity, $expand);
		  
    if ($rs) {
	print color($BG_COL_GREY) if $color;
	print "\n";
	print uc("Result in whois text format:\n\n");
	print encode('UTF-8', "$rs\n\n");

	#print STDERR " from result: ", Dumper $result;
	
	###
	# DEBUG: Make whois objects of the whois string
	#my ($wh, $do, $ho) = $ro->norid_whois_parse($rs);

	#print "no_rdap.pl, wh: ", Dumper $wh if ($wh);
	#print "no_rdap.pl, do: ", Dumper $do if ($do);
	#print "no_rdap.pl, ho: ", Dumper $ho if ($ho);
	
    }

} else {
    ($rs, $errs) = $ro->result_as_rdap_string($check, $nameservers, $entity, $short, $expand);

    if ($rs) {
	print color($BG_COL_GREY) if $color;
	print "\n";
	print uc("Result in RDAP text format:\n\n");
	print encode('UTF-8', "$rs\n\n") if ($rs);
    }
}

print color('reset'), "\n" if $color;

print $sepln if ($debug);

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

  The lookup arguments can be specified by the user, and passed as a
  raw argument. A raw query must be indicated with the -r option.

  Otherwise the default behavious kicks in. The query type is
  automagically guessed by analyzing the query, combined with
  -n or -e options to resole some ambiguous cases.

  perl no_rdap.pl -q <query>

Examples:

 * Lookup a single object:

   - A domain:
     no_rdap.pl -q norid.no

   - A nameserver:
     no_rdap.pl -q nn.uninett.no -n 1

   - A role/host/registrar/registrant entity object:
     no_rdap.pl -q UH9R-NORID
     no_rdap.pl -q NN14H-NORID
     no_rdap.pl -q reg2-NORID -w
     no_rdap.pl -q UNA78O-NORID -e
     no_rdap.pl -q XX18091P-NORID -e

 * Search for matching objects:

   - List of matching domains from a domain name or wildcard:
     no_rdap.pl -q winter.no (same as lookup of one domain)
     no_rdap.pl -q winter*.no
     no_rdap.pl -q *apartment.no

   - List of matching domains from a registrant identity:
     no_rdap.pl -q 985821585
     no_rdap.pl -q N.PRI.1234567
     no_rdap.pl -q N.ORG.1234567
     no_rdap.pl -q N.LEG.1234567

   - List of matching domains from a registrant handle:
     no_rdap.pl -q UNA78O-NORID
     no_rdap.pl -q XX18091P-NORID

   - List of matching domains from a nameserver name
     or wildcard:
     no_rdap.pl -q nn.uninett.no -n 2
     no_rdap.pl -q nn.u*.no -n 2
     no_rdap.pl -q *inett.no -n 2

   - List of matching domains from a nameserver ip:
     no_rdap.pl -q 158.38.0.181
     no_rdap.pl -q 2001:700:0:503::aa:5302

   - List of matching nameservers from a nameserver name
     wildcard:
     no_rdap.pl -q nn.uninett.no -n 1 (same as lookup of one
                                       nameserver)
     no_rdap.pl -q nn.u*.no -n 1
     no_rdap.pl -q *inett.no -n 1

   - List of matching nameservers from a nameserver ip:
     no_rdap.pl -q 158.38.0.181 -n 1
     no_rdap.pl -q 2001:700:0:503::aa:5302 -n 1

   - List of matching entities from a registrant identity:
     no_rdap.pl -q 985821585 -e
     no_rdap.pl -q N.PRI.1234567 -e
     no_rdap.pl -q N.ORG.1234567 -e
     no_rdap.pl -q N.LEG.1234567 -e

   - List of matching entities from a contact's full name or
     wildcard:
     no_rdap.pl -q 'trond haugen'
     no_rdap.pl -q 'haugen'
     no_rdap.pl -q 'trond hau*'
     no_rdap.pl -q '* haugen'


Mandatory arguments:

  -q: query, one of:
      - domain name or wildcard
      - nameserver name or wildcard (see use of -n)
      - handle, if query matches a handle (P/O/R/H/REG (D not
        supported, use domain name))
      - identity: if query is a holder identity [ 985821585 | N.{PRI|ORG|LEG}.xxxxx ], a search is
        performed to find matching domains.
      - identity: if query is a O/P holder handle, a search is
        performed to find matching domains
        if -e is set, the handle object is looked up instead
      - ip-address: lookup domains with nameservers using this ip,
        or lookup nameservers using this ip if -n is set.

   -r: The query is raw:
       A raw query is complete, and shall be used as is towards the
       RDAP backend. The http(s) part must not be included.

      
 Optional arguments:

  Query options:
  -n: integer, one of:
      1: The query is a nameserver name, and a nameservers
         by nameserver name search shall be performed
      2: The query is a nameserver name, and a domains 
         by nameserver name search shall be performed
  -s: The full http(s)-address (URL) of the RDAP service (default is
      https://rdap.test.norid.no)
  -c: Do a HEAD instead of the default GET. HEAD returns no data, and
      can be used to check existence of domain etc.

  Authentication options:
  Grants access to access layer with more functionality and data
  (default is basic layer)
  -U: Basic authentication username
      For a Norid registrar RDAP user where:
      - RDAP username is     : 'rdapuser',
      - Norid registrar id is: 'reg1234'
      The basic username must be set as follows: 'rdapuser@reg1234'.
  -P: Basic authentication password

  Authentication options (for Norid usage only):
  Grants access to access layer with more functionality and data
  (default is basic layer)
  -z: Secret for access layer with higher amount of visible data
  -I: The ip address of the client UA for proper referral rate
      limiting (default is none)
  -y: Act as a Norid proxy

  Page control for searches:
  -F: Fieldset value, undef or one of the valid fieldSets
  -C: Cursor to be used in first page lookup for a search, undef for
      first page

  -p: max number of pages from cursor (1..x, default
      $RDAP_ENTITY_QUOTA_PAGES in rdap lib).
      Note on page size:
      The 'pageSize' parameter in RDAP lookup result tells the number of
      hits per page and cannot be controlled by a client.

  Various:
  -e: lookup entity instead of doing a domain search
  -o: present short result ( only when -w not set)
  -x: expand result, do additional lookups if data is truncated
  -f: force ipv4 (-f 4) or ipv6 (-f 6) connection, else use what your system picks
      Note: option added to force mode if you experience DNS/connect problems
  -l: Use terminal colors

 Format for output of the result:

  -w: dump result in old style Norid whois format (default is a
      rudimentary text output inspired by rdapper)

  Other:
  -d: debug
    0  : debug off
    1  : debug output from this module
    2  : headers output from LWP UA callback
    3  : Debug output from Net::RDAP::UA (headers and contents)
    4-8: Debug output using LWP::ConsoleLogger::Easy,
         which then must be installed
  -a: activate Net::RDAP library caching
  -v: verbose: dump JSON result received from RDAP
  -h: help

=cut

1;


