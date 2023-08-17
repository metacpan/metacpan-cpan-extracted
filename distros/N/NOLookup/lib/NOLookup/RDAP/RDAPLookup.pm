package NOLookup::RDAP::RDAPLookup;

use warnings;
use strict;
use POSIX qw(locale_h);
use URI::Encode qw(uri_encode);
use URI;
use JSON;
use base qw(Class::Accessor::Chained); ## Provides a new() method
use Net::DNS::Domain;
use Net::IP;
use List::MoreUtils qw(any);
use Text::Wrap;
use base qw(Net::RDAP);
use Net::RDAP::EPPStatusMap;
use Net::RDAP::Error;
use IO::Socket qw / AF_INET AF_INET6 /;
use Sys::HostIP;
use Data::Validate::IP qw(is_ip);
use Regexp::Common qw /net/;
use Net::LibIDN  ':all';
use Data::Validate::Domain qw(is_hostname is_domain);
use NOLookup;

use Data::Dumper;
$Data::Dumper::Indent=1;

our $VERSION = $NOLookup::VERSION;

use vars qw(@ISA @EXPORT_OK);

@ISA    = qw( Exporter Class::Accessor::Chained Net::RDAP);
@EXPORT_OK = qw / $RDAP_LOOKUP_ERR_NO_CONN

                  $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED 
                  $RDAP_LOOKUP_ERR_NO_ACCESS
                  $RDAP_LOOKUP_ERR_REFERRAL_DENIED
                  $RDAP_LOOKUP_ERR_OTHER
                  $RDAP_LOOKUP_ERR_NO_MATCH
                  $RDAP_LOOKUP_ERR_NO_CONFORMANCE
                  $RDAP_LOOKUP_ERR_FORBIDDEN
                  $RDAP_LOOKUP_ERR_INVALID
                  $RDAP_LOOKUP_NOT_AUTHORIZED

		  %rdap_head_get_method_args
		  %rdap_get_method_args
		  $sepln

		  %RDAP_FIELDSETS

		  $RDAP_PAGE_SIZE
		  $RDAP_ENTITY_QUOTA_PAGES

/;

# Some accessor methods.
# Those starting with '_' are meant for internal use.
my @methods = qw /

    warning
    error
    status
    description
    is_a_search

    size
    total_size

    total_no_pages

    page_size
    page_number
    first_page
    cur_page
    next_page
    prev_page

    get_href_page_cursor
    result
    raw_json_decoded

    _method
    _uri
    _full_url

   /;

__PACKAGE__->mk_accessors(
    @methods
);

# Connection problems
our $RDAP_LOOKUP_ERR_NO_CONN         = 100;

# Controlled refuses
our $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED  = 101;
our $RDAP_LOOKUP_ERR_NO_ACCESS       = 102;
our $RDAP_LOOKUP_ERR_REFERRAL_DENIED = 103;
our $RDAP_LOOKUP_ERR_OTHER           = 104;
our $RDAP_LOOKUP_ERR_NO_MATCH        = 105;
our $RDAP_LOOKUP_ERR_NO_CONFORMANCE  = 106;
our $RDAP_LOOKUP_ERR_FORBIDDEN       = 107;
our $RDAP_LOOKUP_NOT_AUTHORIZED      = 108;
our $RDAP_LOOKUP_ERR_INVALID         = 109;

# known fieldsets, default is empty, which does the same as 'id'
our %RDAP_FIELDSETS = (
    'id'    => 1,
    'full'  => 1, 
    );

##
# Page control defaults.
# * $RDAP_PAGE_SIZE should be set to the page size used by the rdap
#   server.
# * $RDAP_ENTITY_QUOTA_PAGES should be set to a value big enough to fetch all
#   domains on a single subscriber handle. For .no the quota is 100,
#   but special entities can have up to nearly 800 domains.
#   Thus RDAP_PAGE_SIZE*RDAP_RDAP_ENTITY_QUOTA_PAGES should be at
#   least 800.
our $RDAP_PAGE_SIZE          =  50;
our $RDAP_ENTITY_QUOTA_PAGES =  16;

# We turn the search count on always, for convenience. The user cannot
# control this parameter.
my $URI_ARG_COUNT    = '1';    # 'true' or empty

# 'brief' => 0,  # Not yet implemented 

my $RDAP_TIMEOUT = 60; # secs (default is 180 secs but we want shorter time).

# Default API service URL
my $SERVICE_URL = "https://rdap.norid.no";

our $sepln = '='x60 . "\n";

############
#
# RDAP API. See section 'About the Norid RDAP API' below for more info.
#

# Both HEAD and GET methods, HEAD used if 'check'.
our %rdap_head_get_method_args = (
    DBDN => 'domain/',
    EBEH => 'entity/',
    NBNH => 'nameserver_handle/'
    );

# Not used RBRH => 'registrar/', same as EBEH => 'entity/' 

# GET only methods
our %rdap_get_method_args = (
    DBDN => 'domains?name=',
    DBRH => 'domains?registrant=',    
    DBID => 'domains?identity=',
    DBNI => 'domains?nsIp=',
    DBNL => 'domains?nsLdhName=',
    
    NBNN => 'nameservers?name=',
    NBNI => 'nameservers?ip=',

    EBFN => 'entities?fn=',
    EBID => 'entities?identity=',
    );


# Sort keys (not yet in use)
my %sort_keys = (
    domains => {
	registrationDate => 1,
	lastChangedDate  => 1,
	expirationDate   => 1,
	name             => 1,
    },
    nameservers => {
	registrationDate => 1,
	lastChangedDate  => 1,
	name             => 1,
    },
    entities => {
	registrationDate => 1,
	lastChangedDate  => 1,
	handle           => 1,
	fn               => 1,
	org              => 1,
	country          => 1,
	cc               => 1,
	city             => 1,
    },
    );

# No info info in output
my $NO_FURTHER_INFO = "    (no further information available)\n\n";

#my $ht;

##
# RDAP API conformance values.
# This library supports and expects the following conformance values.
# if other values are returned, the library _may_ need an upgrade, so the 
# lookup will simply fail if any conformance mismatch is detected.
#

my %rdapConformance_vals_supported = (
    'rdap_level_0'           => 1,
    'rdap_objectTag_level_0' => 1,
    'norid_level_0'          => 1,
    'subsetting_level_0'     => 1,
    'sorting_level_0'        => 1,
    'paging_level_0'         => 1,   
    );


# Set an env var to suppress warnings from Net::RDAP
unless ($ENV{'NET_RDAP_UA_DEBUG'}) {
    $ENV{'NET_RDAP_UA_DEBUG'} = 0;
}

=head1 Methods

Module methods.

Those starting with '_' are meant for internal use.

=cut


=head2 new

new handles the following parameters:

  { 
    use_cache           => <0|1>,
    debug               => <0..8>,
    service_url         => <0|service_url,
    norid_referral_ip   => <0|1|ip-address>,
    bauth_username      => <0|bauth_username>,
    bauth_password      => <0|bauth_password>,
    fieldset            => <0|fieldset>
    page_size           => <0|page size>, default $RDAP_PAGE_SIZE
    cursor              => <0|cursor>
    nopages             => <0|nopages>, default $RDAP_ENTITY_QUOTA_PAGES
    insert_page_info    => <0|1>
    force_ipv           => <0|4|6>
  }

 All parameters are optional:

 * use_cache:
   - 1: activate Net::RDAP lookup cache, see Net::RDAP for use,
        Note: usage not needed or tested for this lib.

 * debug:
   - 0  : debug off
   - 1  : debug output from this module
   - 2  : headers output from LWP UA callback
   - 3  : Debug output from Net::RDAP::UA (headers and contents)
   - 4-8: Debug output using LWP::ConsoleLogger::Easy,
          which then must be installed

 * service_url: 
   - the full http(s)-address of the Norid RDAP-servie to
     be accessed. 
   - default is $SERVICE_URL above.

 * norid_referral_ip : 
   - Norid internal use only.
   - set if the calling client ip address argument shall be sent. When set:
     - if the argument passed is a pure integer, use the local ip-address as value.
     - if the argument passed is a valid ip address, use that address
       as value. This is the normal variant to be used to pass a proper client 
       ip address.
     - the ip-address is passed to the server in the '?client_ip=<ip-address>'
       argument.

 * bauth_username:
   - Basic authentication username
     For a Norid registrar RDAP user where
     - RDAP username is     : 'rdapuser',
     - Norid registrar id is: 'reg1234'
     the basic username must be set as follows: 'rdapuser@reg1234'.

 * bauth_password:
   - Basic authentication password

 * fieldset:
   - Undef or one of the valid fieldSets to determine how much data
     should be returned for search hits
     If rate limiting becomes a problem, fieldset='full' could be
     considered.

 Paging parameters:

 * page_size:
   Page size for the the RDAP service.
   Recommended set by the caller, as the lib may have wrong default
   values.

 * cursor:
   - Undef or a cursor string to be used in succeeding page lookups,
     undef for first page.

 * nopages:
   - max number of pages from cursor (1..x, default 10).
     The pageSize in the RDAP service decides the number of hits per
     page.


 * insert_page_info:
    - Text formatting option, insert page info in the text if set.

 Paging parameters set by lib, read them only:

 * total_no_pages:
   Total number of pages that can be fetched with a search combo.
   Calculated as total_size / page_size and set by lib as soon as
   we know the value.

 * page_number:
   The page number signalled by the rdap service.

 * first_page|cur_page|prev_page|next_page:
    - Page hrefs set by lib when a search is performed.

Various:

 * force_ipv:
   - force use of ip protocl version, 0/undef is default, else set to
     4 or 6

=cut

sub new {
    my ($self, $args)=@_;
    
    # defaults
    $args->{service_url} = $SERVICE_URL unless ($args->{service_url});
    
    if ($args->{norid_referral_ip} && $args->{norid_referral_ip} =~ m/^\d+$/) {
	# Set to true (a pure number) - then select a local ip-address
	delete($args->{norid_referral_ip});
	my $ip = get_my_ip_address();
	$args->{norid_referral_ip} = $ip if ($ip);
    }

    # This debug dumps everything using $Net::RDAP::UA::DEBUG
    if ($args->{'debug'} && $args->{debug} == 3) {
	$Net::RDAP::UA::DEBUG = $args->{'debug'};
    }

    my $ro = $self->SUPER::new($args);

    # Activate requested protocol, if set
    # https://metacpan.org/pod/IO::Socket::IP
    if ($args->{force_ipv}) {
	my $ua = $ro->ua;

	if ($args->{force_ipv} == 4) {
	    # Use ipv4 only sockets and addresses
	    print STDERR "RDAPLookup: Connecting forcibly over ipv4\n" if ($args->{debug});
	    $ua->ssl_opts(Domain => AF_INET);
	} elsif ($args->{force_ipv} == 6) {
	    print STDERR "RDAPLookup: Connecting forcibly over ipv6\n" if ($args->{debug});
	    $ua->ssl_opts(Domain => AF_INET6);
	}
	# Also, on force_ipv, disable ssl verify
	use IO::Socket::SSL;
	$ua->ssl_opts( verify_hostname => 0, SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);
	print STDERR "RDAPLookup: Connecting forcibly, also turn of SSL verify mode\n" if ($args->{debug});
    }

    return $ro;
    
}

=head2 lookup

Do an RDAP lookup.

  - $query      : Specifies the query string.
  - $check      : Specifies if http 'head' shall be done, default is 'get'.
  - $nameservers: Must be set to 1 for nameserver_name search
                  and 2 for a domains by nameserver name search
  - $entity     : Must be set to true for entity lookup, in which case the query should 
                  identify an entity, like:
                   - a domain name or a handle
                  For a search, this is more complex:
                  - For identities (orgno, N.XXX.YYY or registrant handles),
                    a search domains by identity/registrant is done as default.
                    To force the search to search for entities by
                    identity/registrant instead, this option must be
                    set.

=cut

sub lookup {
    my ($self, $query, $check, $nameservers, $entity ) = @_;

    #print STDERR "RDAPLookup: lookup on query: $query, check: ", $check || 0, ", nameservers: ", $nameservers || 0, ", entity: ", $entity || 0, "\n";

    unless ($self->validate_and_analyze($query, $check, $nameservers, $entity)) {
	# errno has already been set
        return $self;
    }
    # _method (head or get) and args are set in $self
    $self->_lookup_rdap($query, $self->_method, $self->_uri);
    
}

=head2 _lookup_rdap

Do an RDAP HEAD or GET lookup.

  - $http_type: 'head' or 'get'
  - $uri      : full arguments to base URI, identifying the actual lookup
                method and args
  - other args as passed in $self.

=cut

sub _lookup_rdap {
    my ($self, $query, $http_type, $uri ) = @_;

    my $ua = $self->ua;

    my $debug = $self->{debug} || 0;

    # Debug >= 4: Use LWP::ConsoleLogger::Easy debug
    if ($debug >= 4) {
	# debug only for dev env.
	print STDERR "LWP::ConsoleLogger::Easy usage is commented out in code. If you need it, uncomment in the code!\n";
	#use LWP::ConsoleLogger::Easy qw /debug_ua /;
	#debug_ua ( $ua, $self->{debug});
    }

    # Debug == 2: Show headers via callback methods
    if ($debug == 2) {
	$ua->add_handler(
	    "request_send",
	    sub {
		print STDERR $sepln;
		print STDERR "-- UA Debug: HTTP request headers:\n";
		my $msg = shift;              # HTTP::Message
		print STDERR $msg->headers_as_string(), "\n";
		return;
	    }
	    );
	
	$ua->add_handler(
	    "response_done",
	    sub {
		print STDERR "-- UA Debug: HTTP response headers: ---- \n";
		my $msg = shift;                # HTTP::Message	
		print STDERR $msg->headers_as_string(), "\n";
		print STDERR $sepln;
		return;	       
	    }
	    );
    }

    $ua->default_header( Charset           => "UTF-8");
    $ua->default_header( 'Content-Type'    => "application/rdap+json");

    my $URL = $self->{service_url} . "/$uri";

    if ($self->{norid_referral_ip}) {
	my $a = '?';
	if ($URL =~ m/\?/) {
	    # args already exists, use '&' for extra arg
	    $a = '&';
	}
	$URL .= $a ."client_ip=" . $self->{norid_referral_ip};
    }
	
    $self->_full_url($URL);

    if ($debug == 1) {
	print STDERR $sepln;
	print STDERR "RDAPLookup: _lookup_rdap (v$VERSION) called with:\n";
 	print STDERR "  URL           : '$URL'\n"; 
	print STDERR "  bauth_username: ", $self->{bauth_username}, "\n" if ($self->{bauth_username});
	print STDERR "  referral_ip   : ", $self->{norid_referral_ip}  , "\n" if ($self->{norid_referral_ip});
	print STDERR "  is_a_search   : ", $self->is_a_search || 0, "\n";
    }

    my $resp;

    # RDAP CHECK = HEAD?
    if ($http_type eq 'head') {
	# An RDAP HEAD operation. Head is not supported by Net::RDAP,
	# so call it via the already created UA
	$resp = $ua->head($URL);

	unless ($resp->is_success) {
	    $self->error(_map_rdap_error($query, $resp->code));
	    $self->status($resp->status_line);
	}

	if ($self->{debug} == 100) {
	    print STDERR "Net::RDAP self for HEAD: ", Dumper $self, "\n";
	    #print STDERR "Net::RDAP resp for HEAD: ", Dumper $resp, "\n";
	}
	
	return $self;
    }


    ####
    # A GET lookup, search or simple GET?
    # Now the lookup itself
    ###
    $resp = $self->_fetch_get_pages($query, $URL);
    
    return $self;
}

=head2 _fetch_get_pages

Handle RDAP GET operations.

If search, loop and fetch the requested number of pages from the
offset set by the cursor parameter.

=cut

sub _fetch_get_pages {
    my ($self, $query, $URL) = @_;

    my $ua    = $self->ua;
    my $debug = $self->{debug} || 0;

    my $max_pg_to_fetch = 1;
    my $fpcursor        = '';
    my $cursor          = '';

    #print STDERR "RDAPLookup _fetch_get_pages on URL: '$URL'\n";
    #print STDERR "  is_a_search: '", $self->is_a_search || 0, "'\n"; 
    
    if ($self->is_a_search) {
	$max_pg_to_fetch = $self->{nopages} || $RDAP_ENTITY_QUOTA_PAGES;

	# first page cursor
	$fpcursor = $self->{cursor} || '';	
	$cursor   = $fpcursor;
    }

    my $pcnt     = 1;

    # A place to collect the total result
    my $result;
    my $count = 0;

    # Basic auth params must be passed to the fetch() operation
    my %BA_OPTIONS;
    if ($self->{bauth_username} && $self->{bauth_password} ) {
	# Add basic authentication header via options hash
	$BA_OPTIONS{user} = $self->{bauth_username};
	$BA_OPTIONS{pass} = $self->{bauth_password};
    }

    # Add cursor, initially the $cursor passed in $self, succeding
    # values from next href in each loop
    my $FURL = $URL;
    if ($cursor) {
	$FURL .= "&cursor=$cursor";
    }

    while ($FURL && $pcnt <= $max_pg_to_fetch) {
	
	# Remember size before next lookup. If size has not increased, stop the loop.
	
	my $resp = $self->fetch(URI->new($FURL), %BA_OPTIONS );

	if ($debug == 1) {
	    print STDERR " RDAPLookup search, pcnt: '$pcnt', lookup on FURL: $FURL\n";
	    print STDERR "  pcnt: '$pcnt', max_pg_to_fetch: '$max_pg_to_fetch'\n";
	}

	if ($self->{debug} == 100) {
	    #print STDERR "Net::RDAP self for GET: ", Dumper $self, "\n";
	    print STDERR "Net::RDAP resp for GET: ", Dumper $resp, "\n";
	}

	if ($debug == 3) {
	    print STDERR "UA Debug: UA: ", Dumper $ua, "\n";	
	}
	
	unless ($resp) {
	    #print STDERR "Empty GET resp1 for query: '", $self->{query}, "\n";
	    $self->error( _map_rdap_error($query, 404) );
	    $self->status("Lookup returned nothing!");
	    return $self;
	}

	#print STDERR "resp pcnt: '$pcnt': ", Dumper $resp, "\n";
	#print STDERR "ua: ", Dumper $ua, "\n";
	#print STDERR "ua: ", Dumper $ua->{handlers}->{response_header}, "\n";
	#print STDERR "response_headers: ", Dumper $self->ua->{response_headers}, "\n";
	#print STDERR "self: ", Dumper $self, "\n";
	#print STDERR "self: ", Dumper $self->resp->{def_headers}, "\n";
	
	if ($resp->isa('Net::RDAP::Error')) {
	    #print STDERR "Net::RDAP::Error on GET on query '$query', resp: " , Dumper $resp, "\n";
	    #print STDERR "Empty GET resp2 for query: '", $self->{query}, "\n";
	    #print STDERR "Empty GET resp2 for uri: '", $self->_uri, "\n";
	    $self->error(_map_rdap_error($query,$resp->errorCode));
	    $self->status($resp->title);
	    $self->description($resp->description);
	    $self->raw_json_decoded(to_json({%{$resp}}, {utf8 => 1, pretty => 1}));
	    return $self;
	}
	
	if ($resp->isa('NOLookup::RDAP::RDAPLookup')) {
	    # a $resp is returned, but when fetch() finds nothing, it
	    # just returs the $self-object, possible with an error[] filled in,
	    # so handle it as nothing found
	    # This may also happen if QUOTA / too many requests, in
	    # which case we want to return the hits found so far.
	    
	    my $err = $resp->error;
	    if (ref($err) eq 'ARRAY') {
		#print STDERR "pcnt: '$pcnt', Error ARRAY 'NOLookup::RDAP::RDAPLookup': ", Dumper $err, "\n";
		my $ix = 0;
		foreach my $el (@$err) {
		    if ($el eq 'errorCode') {
			#print STDERR " Each Error ARRAY 'NOLookup::RDAP::RDAPLookup', ix: $ix+1: ", Dumper($err->[$ix+1]), "\n";
			$self->error( _map_rdap_error($query, $err->[$ix+1]) );
			#print STDERR " ARRAY error:", $self->error, "\n";
			
		    } elsif ($el eq 'title') {
			#print STDERR " Each Error status title NOLookup::RDAP::RDAPLookup', ix: $ix+1: , el: $el", Dumper($err->[$ix+1]), "\n";
			$self->status($err->[$ix+1]);
		    }
		    ++$ix;	
		}
	    } else {
		#print STDERR "Error SCALAR 'NOLookup::RDAP::RDAPLookup': ", Dumper $err, "\n";
		$self->error(_map_rdap_error($query, $err));
		$self->status("Lookup rejected or returned no match!");
	    }
	    #print STDERR " pcnt:'$pcnt', RDAPLookup.pm: lookup_error on URL: $URL, error: ", $self->error, "\n";

	    if ($self->error == $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED && $result) {
		# Hit by rate limiting, but we have collected some
		# result data so far, return what we have, but warn
		# about the truncated data.
		$self->warning($self->error);
		$self->status("Query stopped by RDAP rate limiting, the result may be truncated!");
		# not fatal, so clear error
		$self->error(0);
		#print STDERR " QUOTA EXCEEDED, status: ", $self->status, "\n";
		last;
	    }
	    return $self;
	}

	#### A lookup GET response with data
	
	# Check conformance values before we accept the answer
	my @cf = @{$resp->{rdapConformance}};
	
	#print STDERR "NOLookup resp: ", Dumper $resp, "\n";

	#print STDERR "cf: ", Dumper \@cf, "\n";

	foreach my $cfe (@cf) {
	    unless ($rdapConformance_vals_supported{$cfe}) {
		$self->status("Conformance mismatch on key $cfe, this library does not support this RDAP version!");
		$self->error($RDAP_LOOKUP_ERR_NO_CONFORMANCE);
		return $self;
	    }
	}

	#print "LOOP $pcnt, result is: ", Dumper $resp;
	#exit;

	if (!$self->is_a_search) {
	    # Single lookup and no search: A domain, an entity etc. found
	    $FURL = undef;
	    $result = $resp;
	    $count = 1;

	} elsif ($resp->isa('Net::RDAP::SearchResult')) {

	    my $ndom = scalar(@{$resp->{domainSearchResults}}) if ($resp->{domainSearchResults});
	    my $nns  = scalar(@{$resp->{nameserverSearchResults}}) if ($resp->{nameserverSearchResults});
	    my $nent = scalar(@{$resp->{entitySearchResults}}) if ($resp->{entitySearchResults});

	    $count += $ndom if $ndom;
	    $count += $nns  if $nns;
	    $count += $nent if $nent;
	    
	    if ($pcnt == 1) {
		$result = $resp;
		#print STDERR "pcnt: $pcnt, count: $count, result count: ", scalar(@{$result->{domainSearchResults}}), "\n" if ($ndom);
		#print STDERR "pcnt: $pcnt, count: $count, result count: ", scalar(@{$result->{nameserverSearchResults}}), "\n" if ($nns);
		#print STDERR "pcnt: $pcnt, count: $count, result count: ", scalar(@{$result->{entitySearchResults}}), "\n" if ($nent);
		
	    } else {
		# $result already has the hits from $pcnt==1, add extra
		# hits found by the loop to the $result

		push @{$result->{domainSearchResults}}, @{$resp->{domainSearchResults}} if $ndom;
		push @{$result->{nameserverSearchResults}}, @{$resp->{nameserverSearchResults}} if $nns;
		push @{$result->{entitySearchResults}}, @{$resp->{entitySearchResults}} if $nent;
		#print STDERR "LOOP and search and page '$pcnt', result is: ", Dumper $result;
	    }

	    if (my @links = $resp->links) {
		my $link = $links[0];

		if ($link && $link->{rel} eq 'self') {
		    #print STDERR "NOlookup self link: ", Dumper $link, "\n";

		    # set prev/cur/next page refs
		    # cur_page points to the last page read.
		    $self->prev_page($self->cur_page) if ($self->cur_page);
		    $self->cur_page($link->href->as_string || $FURL);
		}
	    }

	    # Paging data should be found, handle it.
	    # ? If so, loop from the cursor and dump
	    if (my $pm = $resp->{paging_metadata}) {

		#print STDERR "NOLookup: Paging metadata found: ", Dumper $pm, "\n";

		#print STDERR "Paging self: ", Dumper $self, "\n";
		#print STDERR "Paging self _uri: ", $self->_uri, "\n";
		#print STDERR "Paging self _full_url: ", $self->_full_url, "\n";
		#print STDERR "Paging self cursor   : ", $self->{cursor} || "-", "\n";

		my $pagenumber = $pm->{pageNumber} || 1;
		my $pagesize   = $pm->{pageSize}   || $RDAP_PAGE_SIZE;
		my $totalsize  = $pm->{totalCount} || 0;

		$self->page_number($pagenumber);

		my $link       = @{$pm->{links}}[0];
		#print STDERR "PM data link: ", Dumper $link, "\n";;

		my $nextref;

		$self->total_size($totalsize);

		#print STDERR "1 page_number: ", $self->page_number() || "-", "\n";
		#print STDERR "1 first_page : ", $self->first_page()  || "-", "\n";
		#print STDERR "1 cur_page   : ", $self->cur_page()    || "-", "\n";
		#print STDERR "1 prev_page  : ", $self->prev_page()   || "-", "\n";
		#print STDERR "1 next_page  : ", $self->next_page()   || "-", "\n";

		if ($pcnt == 1) {

		    #print STDERR "NOLookup pcnt: $pcnt, first_page: ", $self->first_page, "\n";

		    # Remember first page also, since multiple can be fetched
		    # If first_page is passed by the caller, keep that value.
		    $self->first_page($self->cur_page) unless ($self->first_page);

		    # Can be useful to know to page size, remember it
		    # now, since that is the max. number returned by
		    # the rdap service.
		    # If page_size is passed by the caller, he knows
		    # it already, so keep that value.
		    $self->page_size($pagesize) unless ($self->page_size);

		    # Calculate number of pages in total
		    my $nopages_int = int($self->total_size/$self->page_size);
		    my $nopages_mod = $self->total_size % $self->page_size;
		    ++$nopages_int if ($nopages_mod > 0);
		    $self->total_no_pages($nopages_int);

		}
		
		if ($link && $link->{rel} && $link->{rel} eq 'next') {
		    # At least one next is found. If we do not get
		    # here, only a single page is found, and
		    # next link is not applicable

		    #print STDERR "PM data link for next: ", Dumper $link, "\n";;

		    # nextref in 'href'
		    $nextref  = $link->{href};
		    #print STDERR "Nextref href: $nextref\n\n";
		    
		    # For testing on lab, an URL/cursor trick to
		    # get a working next link when we have two
		    # rdap.lab.norid.no instances, because the cursor only
		    # works per instance
		    my $cursor = get_href_page_cursor($nextref);

		    #print STDERR "FURL  : $FURL\n";
		    #print STDERR "URL   : $URL\n";
		    #print STDERR "cursor from nextref: $cursor\n";

		    if ($cursor) {
			$nextref = $URL;
			$nextref .= "&cursor=$cursor";
		    }
		    $self->next_page($nextref);

		    #print STDERR "Pagenumber: $pagenumber\n";
		    #print STDERR "Pagesize  : $pagesize\n";
		    #print STDERR "Nextref   : $nextref\n\n";

		} else {
		    #print STDERR "No next page\n";
		    $self->next_page(undef);
		}

		#print STDERR "2 first_page: ", $self->first_page() || "-", "\n";		
		#print STDERR "2 cur_page  : ", $self->cur_page()   || "-", "\n";
		#print STDERR "2 prev_page : ", $self->prev_page()  || "-", "\n";
		#print STDERR "2 next_page : ", $self->next_page()  || "-", "\n";

		# $FURL is set to undef if no more pages
		$FURL = $nextref;

		#print STDERR "LOOP and page 2, result is: ", Dumper $result;
		#print STDERR "LOOP and page $pcnt, result count: $count above\n--\n";
	    }
	    ++$pcnt;
	}
    }

    
    
    #
    $self->raw_json_decoded(to_json({%{$result}}, {utf8 => 1, pretty => 1}));

    # Set size of returned data
    $self->size($count);

    # Initialize some page data unless set by a search
    $self->total_no_pages(1) unless ($self->total_no_pages);
    $self->total_size(1)     unless ($self->total_size);

    #print STDERR "NOLookup returns:\n";
    #print STDERR "  size          : ", $self->size, "\n";
    #print STDERR "  total_size    : ", $self->total_size, "\n";
    #print STDERR "  total_no_pages: ", $self->total_no_pages,  "\n";
    
    #print STDERR "3 page_size    : ", $self->page_size || "-", "\n";
    #print STDERR "3 first_page   : ", $self->first_page    || "-", "\n";
    #print STDERR "3 cur_page     : ", $self->cur_page      || "-", "\n";
    #print STDERR "3 prev_page    : ", $self->prev_page     || "-", "\n";
    #print STDERR "3 next_page    : ", $self->next_page     || "-", "\n";
    
    print STDERR "  Actual found search hits returned, size is: '$count'\n" if ($debug);
    
    $self->result($result);

}

=head2 get_href_page_cursor

Find and return cursor value from a href page link

=cut

sub get_href_page_cursor {
    my ($href) = @_;

    return unless $href;
    
    my $cursor = "";

    if ($href =~ m/.+(cursor=(.+))&/ ||
	$href =~ m/.+(cursor=(.+))$/) {	
	$cursor = $2;
    }
    return $cursor;
}

=head2 _map_rdap_error

Some RDAP error is returned from Net::RDAP, ref. Net::RDAP::Error.

Those are normally HTTP response errors in the 400 and 500 range,
which are mapped to one of the $RDAP_LOOKUP_ERR_XXX local errors.

https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
 - All 1xx, 2xx, 3xx are not errors, but OK, need not be handled.
 - All 4xx, 5xx indicate some problem, so map relevant ones.
 - Some are not mapped. A warning is given, which may indicate that
   some error case has occured, and that the situation may need to be
   handled and added to this lib.

=cut

sub _map_rdap_error {
    my ($query, $rdap_error) = @_;

    my $rcode;
    if ($rdap_error =~ m/^4\d+$/) {
	# Some client side problem
	if ($rdap_error == 404) {
	    $rcode = $RDAP_LOOKUP_ERR_NO_MATCH;
	} elsif ($rdap_error == 403) {
	    $rcode = $RDAP_LOOKUP_ERR_FORBIDDEN;
	} elsif ($rdap_error == 429) {
	    $rcode = $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED;
	} elsif ($rdap_error == 401) {
	    $rcode = $RDAP_LOOKUP_NOT_AUTHORIZED;
	} else {
	    $rcode = $RDAP_LOOKUP_ERR_INVALID;
	}

    } elsif ($rdap_error =~ m/^5\d+$/) {
	# Some some server side problems
	if ($rdap_error == 501) {
	    $rcode = $RDAP_LOOKUP_ERR_INVALID;
	} else {
	    $rcode = $RDAP_LOOKUP_ERR_NO_CONN;
	}

    } else {
	$rcode = $RDAP_LOOKUP_ERR_OTHER;
	# report other case in case the code can be mapped to a better value
	print STDERR "_map_rdap_error - some other error code: '$rdap_error' was returned for query: $query\n";    
    }

    #print STDERR "_map_rdap_error returned rdap_error: $rdap_error, mapped to rcode: $rcode for query: $query\n";
    
    return $rcode;

}

=head2 get_my_ip_address

Find local ip-address.

(Note: Sys::HostAddr were also tried for this purpose, but could die at
random, so Sys::HostIP is selected. Only ipv4 seems to be processed by
Sys::HostIP, so the selection is limited to ipv4. 
TODO: Consider using another module, which also supports v6).

Best guess IP seems to be the one on the en0-interface, but when a VPN
is in use, you might want that address to be selected.  So, try to do
the best ip selection by ourselves by a reverse sort instead of a
sort, thus selecting the 'highest' numbered and public ip-address).

Return localhost if no other ip is found.

Return empty if localhost iface not found.

=cut

sub get_my_ip_address {

    my $hostip = Sys::HostIP->new;
    
    my $if_info = $hostip->if_info;
    my $lo_found;
    foreach my $key ( reverse sort keys %{$if_info} ) {
	# we don't want the loopback
	if ( $if_info->{$key} eq '127.0.0.1' ) {
	    $lo_found++;
	    next;
	}
	# now we return the first one that comes up
	return ( $if_info->{$key} );
    }
 
    # we get here if loopback is the only active device
    $lo_found and return '127.0.0.1';
    
    return '';

}

=head2 _is_a_valid_parameter

Check whether a parameter contains something fishy

Ref. CSS:
https://www.owasp.org/index.php/Testing_for_Cross_site_scripting#Description_of_Cross-site_scripting_Vulnerabilities

Returns 0 if not ok, 1 if OK.

The below code can be used if special chars should also be generally
blocked, but not in use for now:

  my $ILLCHARS = q/`';_|<>${}[]^]/;
  my $ILLCHARSqr = qr/[\|<>\$\{\}\[\]\^';_\|]/mx;
  if ($v =~ $ILLCHARSqr) {
     print STDERR "Parameter value contains illegal character(s), one or more of: '$ILLCHARS': '$v'";
     return;
  }

=cut

sub _is_a_valid_parameter {
    my $q = shift; 

    # The ZAP tool testing recommends to block the following general CSS:
    return if ($q =~ m|onMouseOver|gi);
    return if ($q =~ m|<.*script|gi);

    return 1;
}

=head2 validate_and_analyze

 1) Validate ip address, if set
 
 2) Validate query, return if query not among the expexted ones.
    - domain name or name server name
    - some object handle (D, P, R, H)
    - some registrar handle (regXXX-NORID)
    - some identity (9 digits orgno, N.XXX.yyyyyyyy)

 2) Analyze query and args and find what http method and uri arguments
    to use for the lookup and set them in '_method' and '_uri'

=cut

sub validate_and_analyze {
    my ($self, $q, $check, $ns, $entity) = @_;

    unless (&_is_a_valid_parameter($q)) {
	$self->status("Invalid character in parameter: $q");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }
    
    if (my $ip = $self->{norid_referral_ip}) {
	unless (is_ip($ip)) {
	    $self->status("Invalid referral ip address: $ip");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
    }

    my $debug    = $self->{debug}    || 0;
    my $rawtype  = $self->{rawtype};

    my $fieldset = $self->{fieldset} || '';
    $fieldset    = lc($fieldset);

    my $cursor   = $self->{cursor}   || '';

    # Fieldset among the supported values?
    if ($fieldset && !$RDAP_FIELDSETS{$fieldset}) {
	$self->status("Invalid fieldset: '$fieldset', must be one of [" .  join(", ", keys %RDAP_FIELDSETS) . "].");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }
    
    # Supported rawtype arg syntax?
    if ($rawtype) {
	my $rawvalid = 0;
	foreach my $a (keys(%rdap_head_get_method_args), keys(%rdap_get_method_args)) {
	
	    my $mhg = $rdap_head_get_method_args{$a};
	    my $mg  = $rdap_get_method_args{$a};

	    #print STDERR "Raw q: '$q', a: '$a', mhg: '$mhg'\n" if ($mhg);
	    #print STDERR "Raw q: '$q', a: '$a',  mg: '$mg'\n" if ($mg);

	    # We use \Q and \E to tell regexp to interpret with no
	    # special chars, needed because of the '?' character which
	    # can be present
	    if ($mhg && $q =~ m/^\Q$mhg\E/i) {
		#print STDERR "Raw mhg match q: '$q' arg match on a: '$a' / mhg: '$mhg' in head_get methods\n";
		++$rawvalid;
		last;
	    }
	    if ($mg && $q =~ m/^\Q$mg\E/i) {
		#print STDERR "Raw mg match q: '$q' arg match on a: '$a' / mg: '$mg' in get methods\n";
		++$rawvalid;
		last;
	    }
	}
	unless ($rawvalid) {   
	    #print STDERR "Rawtpe is set, but invalid: $rawtype\n"; 
	    $self->status("Raw lookup arguments '$q' is not valid or supported");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}

	# Validate URL arguments special because new gTLDs need to
	# be accepted.  Found an regexp on the web which seems to
	# do the trick, at http://www.regexpal.com/94502:
	#
	# 1) this one makes the 'http(s)://' part optional:
	#     ($av =~ m|^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$|i)
	#
	# 2) this one is the same as above, except makes the 'http(s)://' part mandatory
	#     ($av =~ m|^(?:http(s)?:\/\/)[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$|i)
	#
	# We use parts of the above
	
	if ($q =~ m|^(http(s)?)|i) {
	    # We do not accept any http(s) parts
	    $self->status("Invalid URL, remove http(s) part: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
	# The rest of the URL args must be valid as url arguments
	unless ($q =~ m|^[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$|i) {
	    $self->status("Invalid URL arguments: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
    }

    my $arg;
    my $search;

    # Remove unwanted spaces before, after and collapse inside to one
    if ($q) {
	$q =~ s/\s+/ /g;
	$q =~ s/^\s+//;
	$q =~ s/\s+$//;
    }

    unless ($q) {
        $self->status("mandatory query parameter not specified");
        $self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }
    if ($ns && $ns != 1 && $ns != 2) {
	#print STDERR "VALIDATE ns: $ns\n"; 
        $self->status("nameservers parameter must be set to 1 or 2");
        $self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }

    # A search must be performed with a GET only if '*' is found in
    # the $q, this parameter us used below where HEAD or GET are
    # possible, but then GET shall be selected if $search
    if ($q =~ /\*/i) {
	#print STDERR "Asterix found, so a search is to be performed, which one is decided below\n";
	++$search;
    }
    
    if ($rawtype) {
	# User has specified type and also all complete arguments already.
	$arg = $self->{rawtype};
    
    } elsif ($q =~ m/^\d{9}$/) {
	#print STDERR "Orgno found so a search is to be performed, which one is decided below\n";
	
	# org number OK
	if ($q eq "000000000") {
	    $self->status("Invalid ID: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;

	} elsif ($q !~ m/^[8|9]\d{8}/) {
	    $self->status("Invalid ID, org.number must start on 8 or 9: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}

	# Lookup an id is a search
	++$search;
	
	# Search domains by identity to get list of domain names for that identity
	$arg = 'DBID';
	if ($entity) {
	    # search entities by identity to get list of handles with that identity
	    $arg = 'EBID';
	}

    } elsif ($q =~ /^N\.(PRI|LEG|ORG|REG)\.\d+$/i) {

	$q = uc($q);

	# Lookup an id is a search
	++$search;

	# search domains by identity is default
	$arg = 'DBID';
	if ($entity) {
	    # search entities by identity
	    $arg = 'EBID';
	}

    } elsif ($q =~ /REG(\d+)(-NORID)*$/i) {
	# registrar handle lookup
	# is case sensitive, syntax: 'reg2-NORID'
	$q = "reg$1-NORID";

	# registrar by reg handle RBRH, same as EBEH, so use that
	$arg = 'EBEH';
	
    } elsif ($q =~ /^[a-z]{1,}[0-9]{1,}([D])(-NORID)*$/i) {
	# Domain (D) handle lookup is not supported by the rdap, use the domain name instead
	$self->status("Invalid query, domain handle not supported, use the domain name instead: $q");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
	
    } elsif ($q =~ /^[a-z]{1,}[0-9]{1,}([PORH])(-NORID)*$/i) {
	# P, O, R or H handle
	$q = uc($q);
	
	my $ot = uc($1);
	
	if ($ot eq 'P' || $ot eq 'O') {
	    # is a registrant handle

	    # domains by registrant handle is default
	    $arg = 'DBRH';
	    # Lookup an id is a search
	    ++$search;
	    
	    if ($entity || $check) {
		# entities by entity handle
		$arg = 'EBEH';
		$search = 0;
	    }

	} elsif ($ot eq 'H') {
	    # is a H, only option is by nameserver handle
	    $arg = 'NBNH';

	} else {
	    # is an R, only option is lookup entity by entity handle
	    $arg = 'EBEH';
	}

    } elsif (
	# IP addresses?
	# (ip blocks/ranges not supported yet, but can be added if needed:
	#  $q =~ /^\d{1,3}\.\d{1,3}\.{0,1}\d{0,3}\.{0,1}\d{0,3}\/\d{1,2}$/ || # ipv4 range
	#  $q =~ /^[0-9a-f:]+\/\d{1,3}$/i) {                                  # ipv6 range 
	#
	$q =~ m/^$RE{net}{IPv4}$/i       || # ipv4 decimal
	#$q =~ m/^$RE{net}{IPv4}{hex}$/i  || # ipv4 hex not expected nor supported
	$q =~ m/^$RE{net}{IPv6}$/i)      {  # ipv6 hex
	
	#print STDERR "Is IP-address or block in $q, search on nameservers by IP\n";
	$q = lc($q);

	# Domains by name server IP (DBNI) is default
	$arg = 'DBNI';
	++$search;
	
	if ($ns && $ns == 1) {
	    # nameservers by IP (NBNI) is a search
	    $arg = 'NBNI';
	    #print STDERR "Nameservers by IP search for $q: $arg\n";
	    
	} else {
	    #print STDERR "Domains by nameserver IP search for $q: $arg\n";
	}

    } elsif (
	# domain or nameserver name
	$q =~ /^(no)$/i       ||    # 'no'
	$q =~ /^\.(no)$/i     ||    # '.no'
	$q =~ /^(no)\.$/i     ||    # 'no.'
	$q =~ /^(.+\.no)$/i   ||    # 'xxx.no'      : domain name(s) or nameserver(s) under .no
	$q =~ /^(.+\..+)$/i) {      # 'ns1.hyp.net' : possible nameserver(s) not under no

	$q = lc($1);

        unless (is_a_valid_domainname($q, $ns)) {
	    #print STDERR "q is INVALID\n";
	    $self->status("Invalid domain name or nameserver name: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}

	#print "STDERR: a single no domain or nameserver search requested, q: $q\n";
	
	# domain by domain name is default
	$arg = 'DBDN';
	if ($ns) {
	    if ($check) {
		# nameservers by name server name (NBNN) is a search
		#print STDERR "nameserver name and check not supported for $q: $arg\n";

		$self->status("Invalid query, check on nameserver name not supported, use the nameserver handle instead: $q");
		$self->error($RDAP_LOOKUP_ERR_INVALID);
		return 0;

	    } elsif ($ns == 2) {
		# domains by name server (ldh)name (DBNL) is a search
		++$search;
		$arg = 'DBNL';
		#print STDERR "domains by nameserver name search for $q: $arg\n";

	    } else {
		# $ns == 1:
		++$search;
		$arg = 'NBNN';
		#print STDERR "nameserver search for $q: $arg\n";
	    }
	}
	#print STDERR "domain search for $q: '$arg'\n";

    } elsif ($q =~ /.+/i) {
	# Some other string has one or more character inside is
	# assumed to be an ns, if $ns, or name of a person, role or org
	$q = lc($q);

	if ($ns) {
	    $arg = 'NBNN';
	} else {
	    # entity by full name
	    $arg = 'EBFN';
	}
	++$search;
	
    } else {
	$self->status("Invalid query, not supported by the RDAP service: $q");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }

    unless ($arg) {
	$self->status("No success in finding a lookup method, try a valid query combination: $q");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }

    unless ($arg) {
	$self->status("No success in finding a lookup method, try a valid query combination: $q");
	$self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }

    #print STDERR "validate(): q: '$q' gave arg: '$arg'\n";

    if ($entity) {
	#print STDERR "validate and entity as search was selected\n";
	unless ($arg eq 'EBID' || $arg eq 'EBEH' || $arg eq 'DBRH') {
	    #print STDERR "ERROR: validate and entity search combo for '$q' and '$arg' not supported because of potential many hits\n";
	    # We must have selected one of the entity searches, else reject
	    # domain or ns search must not also have the entity set
	    $self->status("Invalid query, this search cannot be done as an entity search: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
    }

    if ($ns) {
	#print STDERR "validate and ns search was selected, ns: '$ns', arg: '$arg'\n";
	# One of the ns searches are selected.
	# Make sure found search is consistent with an ns lookup.
	unless ($arg eq 'NBNN' || $arg eq 'NBNI' || $arg eq 'DBNL' || $arg eq 'DBNI') {
	    #print STDERR "ERROR: validate and nameserver searc for '$q' and '$arg' not supported\n";
	    $self->status("Invalid query, this search cannot be done as a nameserver search: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
    }

    if ($check) {
	# HEAD
	unless ($rdap_head_get_method_args{$arg}) {
	    $self->status("No success in finding a HEAD lookup method for $arg, try a valid query combination: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
	$self->_method('head');
	$self->_uri($rdap_head_get_method_args{$arg} . $q);

    } else {
	# GET
	unless ($self->{rawtype} || $rdap_head_get_method_args{$arg} || $rdap_get_method_args{$arg}) {
	    $self->status("No success in finding a GET lookup method for $arg, try a valid query combination: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}

	$self->_method('get');

	my $uri_arg = "";

	if ($self->{rawtype}) {
	    $uri_arg = $q;
	} else {
	    if (!$search && $rdap_head_get_method_args{$arg}) {
		$uri_arg = $rdap_head_get_method_args{$arg} . $q;
	    } else {
		$uri_arg = $rdap_get_method_args{$arg} . $q;
	    }
	    
	    # RDAP args only allowed for searches:
	    if ($search && !$rawtype) {

		my $a = '?';
		if ($uri_arg =~ m/\?/) {
		    # args already set, use '&' for extra arg
		    $a = '&';
		}

		# alrays add count argument
		$uri_arg .= $a . "count=$URI_ARG_COUNT";

		# Add fieldset arg. if user wants it
		if ($fieldset) {
		    $uri_arg .= "&fieldSet=$fieldset";
		}
	    }
	}

	$self->_uri($uri_arg);
	
    }
    
    # remember the query 
    $self->{query} = $q;
    $self->is_a_search($search);

    if ($debug == 1) {
	print STDERR $sepln;
	print STDERR "RDAPLookup: Search URI for arg '$arg': ", $self->_uri, "\n";
    }
    return 1;
}

=head2 is_a_valid_domainname

Check whether a domainname or nameserver is valid.

Returns undef if not ok.
Returns 1 if OK.

=cut

sub is_a_valid_domainname {
    my ($q, $ns) = @_;

    my $ace;
    $q = lc($q);

    # A domain name or a nameserver name can contain an '*' in case of
    # wildchar search.  We just strip all '*' before validating.
    if ($q =~ m/\*/) {
	$q =~ s/\*//g;
	# remove leftover '.' at the start, if we have the *.labnic.no case
	$q =~ s/^\.//;
    }

    # Special case: Accept '.no' or 'no' as valid zone name
    if (!$ns && $q =~ m/^\.no$|^no$/) {
	return 1;
    }

    # Both domain names and host names should be possible to convert to ace
    unless ($ace = idn_to_ascii($q, 'utf-8', IDNA_USE_STD3_ASCII_RULES)) {
        return;
    }

    if ($ns) {
	# $ace and $q must be identical
	unless ($q eq $ace) {
	    return;
	}
	unless(is_hostname($ace)) {
	    return;
	}
    } else {
	unless(is_domain($ace)) {
	    return;
	}
	# Domain name must end on '.no'
	unless ($ace =~ m/^.+\.no$/) {
	    #print STDERR "Domain name does not end with '.no'\n";
	    return;
	}
    }

    # A domain or host must be two letters minimum, so length must be
    # at least 5 ('xx.no')
    unless (length($ace) > 4) {
        return;
    }

    return 1;
}

=head2 rdap_get_obj_name

Fetch the name from an object.

If we have a Net::DNS::Domain object (domain/ns), also get the xname.

=cut

sub rdap_get_obj_name {
    my ($self, $o) = @_;

    my $xname;
    my $name = $o->name;
    return unless $name;
    
    if ('Net::DNS::Domain' eq ref($name)) {
	$xname = $name->xname;
	$name = $name->name;
    } else {
	$xname = $name;
    }
    return $name, $xname;
}

=head2 norid_handle_type

Determine type of Norid handle.

=cut

sub norid_handle_type {
    my ($self, $handle) = @_;

    $handle = uc($handle);
    
    if ($handle =~ m/REG\d+-NORID$/) {
	return 'registrar';

    } elsif ($handle =~ m/.+([O|P|R|H|D])-NORID$/) {
	return 'organization' if ($1 eq 'O');
	return 'role' if ($1 eq 'R');
	return 'person' if ($1 eq 'P');
	return 'host' if ($1 eq 'H');
	return 'domain' if ($1 eq 'D');
    }
    #die "unknown handle type for: $handle";
    print STDERR "norid_handle_type: unknown handle type - please check\n";
    return;
}

=head2 result_as_rdap_string

Return sensible rdap formatted text string.
Uses internal helper formatting functions.

Shows how to access data returned by Net::RDAP.

=cut

sub result_as_rdap_string {
    my ($self, $check, $nameservers, $entity, $short, $expand) = @_;

    my (@ra, @errors);

    my $response = $self->result;

    # A check has no data, let the caller handle it.
    return if ($check);

    if ($response->isa('Net::RDAP::Error')) {
	push(@errors, sprintf("%03u (%s)", $response->errorCode, $response->title));
    }

    my ($nrs, $nerrs) = $self->rdap_notice_or_remark_as_string($response, 'notices');
    my ($rrs, $rerrs) = $self->rdap_notice_or_remark_as_string($response, 'remarks');

    if ($response->isa('Net::RDAP::SearchResult')) {
	# Put page info on top of page
	$self->rdap_page_info_as_string(\@ra);
	push @ra, "";

	my $cnt = 1;
	foreach my $o ($response->nameservers, $response->domains, $response->entities) {
	    my ($rst, $errs) = $self->rdap_obj_as_string($o, $check, $nameservers, $entity, $short, $expand);
	    push @ra, "[$cnt]";
	    push @ra, $rst if ($rst);
	    push @errors, @$errs if ($errs && @$errs);
	    ++$cnt;
	}

    } else {
	push @ra, "";

	my ($rst, $errs) = $self->rdap_obj_as_string($response, $check, $nameservers, $entity, $short, $expand);
	push @ra, $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);
    }

    return ( $nrs . $rrs . (join("\n", @ra)) ), \@errors;

}

=head2 rdap_obj_as_string

Return sensible rdap formatted text string for an rdap object.

Code stolen from rdapper and adapted.

=cut

sub rdap_obj_as_string {
    my ($self, $response, $check, $nameservers, $entity, $short, $expand) = @_;

    my (@ra, @errors, @doms);

    #print STDERR "rdap_obj_as_string CLASS: ", $response->class, "\n";
    #print STDERR "check: '$check', nameservers: '$nameservers', entity: '$entity', short: '$short', expand: '$expand'\n";

    if ('entity' ne $response->class) {
	my ($name, $xname) = $self->rdap_get_obj_name($response);

	my $handle = $response->handle;
	my $htype  = $self->norid_handle_type($handle);

	push @ra, sprintf("Handle: %s\n", $response->handle);

	if ($xname ne $name) {
	    push @ra, sprintf("Domain Name: %s\n", $xname);
	    push @ra, sprintf("Domain ACE Name: %s\n", $name);
	} else {
	    if ($htype eq 'host') {
		push @ra, sprintf("Nameserver Name: %s\n", $name);
	    } else {
		push @ra, sprintf("Domain Name: %s\n", $name);
	    }
	}
    }

    unless ('domain' eq $response->class || 'nameserver' eq $response->class) {
	if ('entity' eq $response->class) {    
	    push @ra, sprintf("Entity:");
	}
	push @ra, sprintf("  Handle: %s", $response->handle);
	push @ra, "" if ($self->is_a_search);
    }

    if ('ip network' eq $response->class) {
	push @ra, sprintf("Range: %s", $response->range->prefix);
	push @ra, sprintf("Domain: %s", $response->domain->as_string);
	
    } elsif ('autnum' eq $response->class) {
	push @ra, sprintf("Range: %u - %u", $response->start, $response->end) if ($response->start > 0 && $response->end > 0);
	push @ra, sprintf("Type: %s", $response->type) if ($response->type);
	
    } elsif ('domain' eq $response->class) {
	my @ns = $response->nameservers;
	if (scalar(@ns) > 0) {
	    push @ra, "Nameservers:";
	    foreach my $ns (sort { lc($a->name->name) cmp lc($b->name->name) } @ns) {
		push @ra, sprintf("  %s: %s", "Handle", $ns->handle);
		push @ra, sprintf("  %s: %s", "Nameserver Name", $ns->name->name);
		push @ra, "";
	    }
	}
	
	my @ds = $response->ds;
	if (scalar(@ds) > 0) {
	    push @ra, "DNSSEC:";
	    foreach my $ds ($response->ds) {
		
		push @ra, sprintf("  %s. IN DS %u %u %u %s", uc($ds->name),
				  $ds->keytag, $ds->algorithm, $ds->digtype, uc($ds->digest));
	    }
	    push @ra, "";
	}
	
	my @keys = $response->keys;
	if (scalar(@keys) > 0) {
	    push @ra, "DNSSEC Keys:";
	    foreach my $key (@keys) {
		push @ra, sprintf("  %s. IN DNSKEY %u %u %u %s", uc($key->name), $key->flags, $key->protocol, $key->algorithm, uc($key->key));
	    }
	    push @ra, "";
	}
	
    } elsif ('entity' eq $response->class) {

	my @ids = $response->ids();
	my $indent = ' ' x 2;

	foreach my $id (@ids) {
	    push @ra, sprintf("%sType: %s", $indent, $id->type);
	    push @ra, sprintf("%sIdentity: %s", $indent, $id->identifier);
	}
	
	my $card = $response->vcard;
	if (!$card) {
	    #push @ra, $NO_FURTHER_INFO;
	} else {
	    push @ra, $self->rdap_vcard_as_string($response->vcard, ' ' x 2, $response);
	}

	my $handle = $response->handle;
	my $htype  = $self->norid_handle_type($handle);

	# Also get domain list if we have a subscriber entity handle
	if (($expand || $entity) &&
	    ($htype eq 'organization' || $htype eq 'person')) {

	    $self->rdap_get_domains_by_entity_handle($handle, $check,
						     $nameservers, \@doms, \@errors);
	}

    } elsif ('nameserver' eq $response->class) {

	my @addrs = $response->addresses;
	if (scalar(@addrs) > 0) {
	    push @ra, "IP Addresses:";
	    foreach my $ip (@addrs) {
		push @ra, sprintf("  IP Address: %s", $ip->ip);
	    }
	    push @ra, "";
	} else {
	    #push @ra, "  * (no IP addresses returned)";
	}
	
    }

    my @events = $response->events;
    if (scalar(@events)) {
	push @ra, "Events:";
	foreach my $event (@events) {
	    # DateTime object is UTC, convert to localtime
	    my $to = $event->date;
	    $to->set_time_zone('Europe/Oslo');
	    
	    push @ra, sprintf("  %s: %s", ucfirst($event->action), scalar($to->date));
	}
	push @ra, "";
    }
    
    my @status = $response->status;
    if (scalar(@status) > 0) {
	push @ra, "Status:";
	foreach my $status (@status) {
	    my $epp = rdap2epp($status);
	    if ($epp) {
		push @ra, sprintf("  * %s (EPP: %s)", $status, $epp);
		
	    } else {
		push @ra, sprintf("  * %s", $status);
	    }
	}
	push @ra, "";
    }
    
    my @entities = $response->entities;
    my %entities;
    foreach my $ent (@entities) {

	if (!$ent->vcard && $expand) {
	    #print STDERR "rdap_obj_as_string(): Expand set\n" if ($self->{debug});

	    my $ro = NOLookup::RDAP::RDAPLookup->new(
		{
		    service_url         => $self->{service_url},
		    debug               => $self->{debug},
		    use_cache           => $self->{use_cache},
		    bauth_username      => $self->{bauth_username},
		    bauth_password      => $self->{bauth_password},
		    force_ipv           => $self->{force_ipv},
		    nopages             => $self->{nopages}
		});
	    
	    my $new = $ro->lookup($ent->handle, $check, $nameservers, 1);

	    if ($new->error) {
		#print STDERR "RDAPLookup: New gave error on handle lookup ", $ent->handle, " error: ", Dumper $new->error, "\n";

		# better error handling
		$self->error($new->error);
		$self->status($new->status);
		@ra = ();
		
		return $self;
	    }
	    
	    if ($new->isa('Net::RDAP::Error')) {
		push(@errors, sprintf('Unable to expand %s: %d (%s)',
				      $ent->handle, $new->errorCode, $new->title));
	    } else {
		$ent = $new->result;
	    }
	}
	
	map { $entities{$_} = $ent } $ent->roles;
    }
    
    if (scalar(@entities) > 0) {
	push @ra, "Entities:";
	
	foreach my $entity (@entities) {
	    
	    my @roles  = $entity->roles;
	    my $handle = $entity->handle;

	    if (scalar(@roles) > 0) {
		if ($handle) {
		    push @ra, sprintf("  Handle: %s", $handle);
		    push @ra, sprintf("  Role: %s", join(', ', sort(@roles)));
		    
		} else {
		    push @ra, sprintf("  %s:", join(', ', map { sprintf('%s Contact', ucfirst($_)) } sort(@roles)));
		}
		
	    } else {
		push @ra, sprintf("  Handle: %s", $handle);
	    }

	    # Show Ids
	    my @ids = $entity->ids();
	    my $indent = ' ' x 2;
	    
	    foreach my $id (@ids) {
		push @ra, sprintf("%sType: %s", $indent, $id->type);
		push @ra, sprintf("%sIdentity: %s", $indent, $id->identifier);
	    }

	    my $card = $entity->vcard;
	    if (!$card) {
		push @ra, "";
		#push @ra, $NO_FURTHER_INFO;
	    } else {
		push @ra, $self->rdap_vcard_as_string($card, ' ' x 2, $entity);
	    }
	}
    }

    # List the domains when relevant
    if (scalar(@doms)) {
	my $ds = "";
	my @dns;

	foreach my $dom (@doms) {

	    my ($name, $xname) = $self->rdap_get_obj_name($dom);

	    if ($xname) {
		push @dns, $xname;
	    } else {
		push @dns, $name;
	    }
	}

	# extend domain list with both total number and domain list
	if (@dns) {
	    push @ra, "Total Number Of Domains: " . scalar(@doms);
	    push @ra, "";
	    push @ra, "Domains:";
	    foreach my $dn (@dns) {
		push @ra, "  Domain Name: $dn";
	    }
	    push @ra, "";
	}
    }

    if (!$short) {
	my @links = $response->links;
	if (scalar(@links) > 0) {
	    push @ra, "";
	    push @ra, "Links:";
	    foreach my $link (@links) {
		push @ra, sprintf("  * %s (%s)", $link->href->as_string, $link->title || $link->rel || '-');
	    }
	    push @ra, "";
	    
	}
    }

    return join("\n", @ra), \@errors;

}

=head2 rdap_notice_or_remark_as_string

Format RDAP notice or remark as text string.

=cut

sub rdap_notice_or_remark_as_string {
    my ($self, $response, $what) = @_;

    unless ($what eq 'notices' || $what eq 'remarks') {
	die "Illegal argument $what, must be 'notices' or 'remarks'";
    }

    my (@errors, @ra);

    my @whats = $response->$what;
    if (scalar(@whats) > 0) {
	my $indent = ' ' x 2;
	
	foreach my $we (@whats) {
	    push @ra, $we->title;

	    foreach my $link ($we->links) {
		push @ra, sprintf("%s%s", $indent, $link->href->as_string);
	    }

	    push @ra, "";
	    push @ra, fill($indent, $indent, join("\n", $we->description));
	    push @ra, "";
	}
    }

    return join("\n", @ra), \@errors;
}


=head2 rdap_vcard_as_string

Format vcard object(s) as a text string.

=cut

sub rdap_vcard_as_string {
    my ($self, $card, $indent, $eo) = @_;

    #print STDERR "rdap_vcard_as_string Name for card: ", Dumper $card, "\n";
    
    my @vca;
    my $vc = "";
    
    push @vca, sprintf("%sName: %s", $indent, $card->full_name) if ($card->full_name);
    push @vca, sprintf("%sOrganization: %s", $indent, $card->organization) if ($card->organization);
    
    my @addresses = @{$card->addresses};
    if (scalar(@addresses) > 0) {
	foreach my $address (@addresses) {
	    push @vca, sprintf("%sAddress:", $indent);
	    $vc .= sprintf("%sAddress:\n\n", $indent);
	    
	    my @lines;
	    foreach my $element (@{$address->{'address'}}) {
		push(@lines, ('ARRAY' eq ref($element) ? @{$element} : $element));
	    }
	    
	    push @vca, sprintf $indent."  ".join(sprintf("\n%s  ", $indent), grep { length > 0 } map { s/^[ \t\r\n]+//g ; s/[ \t\r\n]+$//g ; $_ } @lines);
	}
    }
    
    foreach my $email (@{$card->email_addresses}) {
	if ($email->{'type'}) {
	    push @vca, sprintf("%sEmail: %s (%s)", $indent, $email->{'address'}, $email->{'type'});
	    
	} else {
	    push @vca, sprintf("%sEmail: %s", $indent, $email->{'address'});
	}
    }

    # Hack: Web address (url) for an entity is not supported via the card
    # object, ref. code for vcard() in
    # https://metacpan.org/source/GBROWN/Net-RDAP-0.14/lib/Net/RDAP/Object/Entity.pm
    # which does not process the url info.
    #
    # Therefore just fetch the url from inside the $eo instead.
    #
    # TODO: This should be fixed in Net::RDAP::Object::Entity, a bug
    #       report has been filed with a request for support.
    #       (Could also be fixed by local subclassing here, but we
    #        prefer a central fix)
    #
    my $vca = $eo->{vcardArray};

    if ($vca && $vca->[0] && $vca->[0] eq 'vcard' && $vca->[1]) {
	foreach my $vc (@{$vca->[1]}) {
	    if ($vc->[0] && $vc->[0] eq 'url') {
		if ($vc->[0] && $vc->[0] eq 'url' &&
		    $vc->[2] && $vc->[2] eq 'uri' &&
		    $vc->[3]) {
		    push @vca,  sprintf("%sWeb Address: %s", $indent, $vc->[3]);
		}
	    }
	}
    }

    foreach my $number (@{$card->phones}) {

	my @types = ('ARRAY' eq ref($number->{'type'}) ? @{$number->{'type'}} : ($number->{'type'}));
	
	# Separate between fax, voice and cell phone
	my $type = 'voice'; 
	foreach my $t (@types) {
	    $t = lc($t);
	    if ($t eq 'fax' || $t eq 'cell') {
		$type = $t;
		last;
	    }	    
	}

	# strip the 'tel:' prefix
	my $no = $number->{'number'};
	$no =~ s/^tel://;

	push @vca, sprintf("%s%s: %s", $indent, ucfirst($type), $no);

    }
    push @vca, "";
    return join("\n", @vca);
    
}

=head2 rdap_page_info_as_string

Format and insert page info, if requested.


=cut

sub rdap_page_info_as_string {
    my ($self, $wa) = @_;

    #For now, just use the same format as we use for whois page info.
    &NOLookup::RDAP::RDAPLookup::Whois::rdap_page_info_as_norid_whois_string($self, $wa);

    #$self->rdap_page_info_as_norid_whois_string($wa);

}

=head2 rdap_get_entities_by_entity_handle

Based on a subscriber handle (O or P), fetch domain list for it.

=cut

sub rdap_get_entities_by_entity_handle {
    my ($self, $handle, $check, $nameservers, $ent, $errors) = @_;

    #print STDERR "rdap_get_entities_by_entity_handle() on handle: '$handle'\n";

    my (%entities, $entity);

    my $ro = NOLookup::RDAP::RDAPLookup->new(
	{
	    service_url         => $self->{service_url},
	    debug               => $self->{debug},
	    use_cache  	        => $self->{use_cache},
	    bauth_username      => $self->{bauth_username},
	    bauth_password      => $self->{bauth_password},
	    force_ipv           => $self->{force_ipv},
	    nopages             => $self->{nopages}
	});

    my $new = $ro->lookup($handle, $check, $nameservers, 1);

    if ($new->error) {
	#print STDERR "New gave error: ", Dumper $new->error, "\n";
	$self->error($new->error);
	$self->status($new->status);
	push @$errors, "Entity handle '$handle' lookup error";

    } elsif ($new->isa('Net::RDAP::Error')) {
	#print STDERR "New gave error Net::RDAP::Error: ", Dumper $new, "\n";
	push @$errors, "Unable to lookup $handle: $handle, errorcode:" .
	    $new->errorCode . "desc: " . $new->title;

    } elsif ($new->result) {
	#print STDERR "New gave result: ", Dumper $new->result, "\n";
	$entity = $new->result;
	if ($entity->isa('Net::RDAP::Object::Entity')) {
	    #print STDERR "New gave Net::RDAP::Object::Entity result: ", Dumper $new->result, "\n";
	    my @nent = $entity->entities;
	    push @$ent, @nent if (@nent);
	}
    }
}

=head2 rdap_get_domains_by_entity_handle

Based on a subscriber handle (O or P), fetch domain list for it.

For domain list on entity, we will try fetch all domains possible on a
single quota as default via $RDAP_ENTITY_QUOTA_PAGES since it is set to a high
enough value. User may try fewer or more pages bt specifying nopages.

=cut

sub rdap_get_domains_by_entity_handle {
    my ($self, $handle, $check, $nameservers, $doms, $errors) = @_;

    #print STDERR "rdap_get_domains_by_entity_handle() on handle: '$handle'\n";

    # Do a domain search on registrant handle to get the
    # associated domains. If the lookup fails, it may be
    # that the access layer does not allow for it,
    # so on errors we do not return.

    my (%entities, $entity);

    my $ro = NOLookup::RDAP::RDAPLookup->new(
	{
	    service_url         => $self->{service_url},
	    debug               => $self->{debug},
	    use_cache  	        => $self->{use_cache},
	    bauth_username      => $self->{bauth_username},
	    bauth_password      => $self->{bauth_password},
	    force_ipv           => $self->{force_ipv},
	    nopages             => $self->{nopages} || $RDAP_ENTITY_QUOTA_PAGES
	});

    my $new = $ro->lookup($handle, $check, $nameservers, 0);

    if ($new->error) {
	if ($new->error == $RDAP_LOOKUP_ERR_NO_MATCH) {
	    # Fallthru, skip silently as this may occur if
	    # a registrant handle has no domains.
	    #print STDERR "New 2 gave not found: ", $new->error, "\n";
	} else {
	    $self->error($new->error);
	    $self->status($new->status);
	    push @$errors, "Domain search for registrant entity handle '$handle' could not be done!";
	}

    } elsif ($new->isa('Net::RDAP::Error')) {
	push @$errors, "Unable to lookup $handle: $handle, errorcode:" .
	    $new->errorCode . "desc: " . $new->title;
    } else {
	$entity = $new->result;
	if ($entity && $entity->isa('Net::RDAP::SearchResult')) {
	    my @ndoms = $entity->domains;
	    push @$doms, @ndoms;
	}
    }

}

=head2 rdap_get_entities_by_domain_name

Domain lookup entities for a domain name.

=cut

sub rdap_get_entities_by_domain_name {
    my ($self, $name, $check, $nameservers, $ent, $errors) = @_;

    #print STDERR "rdap_get_entities_by_domain_name() on name: '$name'\n";

    my (%entities, $entity);

    my $ro = NOLookup::RDAP::RDAPLookup->new(
	{
	    service_url         => $self->{service_url},
	    debug               => $self->{debug},
	    use_cache           => $self->{use_cache},
	    bauth_username      => $self->{bauth_username},
	    bauth_password      => $self->{bauth_password},
	    force_ipv           => $self->{force_ipv},
	    nopages             => $self->{nopages}
	});

    my $new = $ro->lookup($name, $check, $nameservers, 1);

    if ($new->error) {
	$self->error($new->error);
	$self->status($new->status);
	push @$errors, "Domain name '$name' lookup error";

    } elsif ($new->isa('Net::RDAP::Error')) {
	push @$errors, "Unable to lookup domain name: '$name', errorcode:" .
	    $new->errorCode . "desc: " . $new->title;

    } elsif ($new->result) {
	$entity = $new->result;
	my @nent = $entity->entities if ($entity->entities);
	push @$ent, @nent if (@nent);

    } elsif ($new->isa('NOLookup::RDAP::RDAPLookup')) {
	# No result, error set by lookup function
    }
}


=pod

=encoding ISO-8859-1

=head1 NAME

NOLookup::RDAP::RDAPLookup - Lookup RDAP data from the Norid (.no)
RDAP service.

=head1 SYNOPSIS

    use Encode;
    use NOLookup::RDAP::RDAPLookup;
 
    # Default API service URL
    my $SERVICE_URL = "https://rdap.norid.no";

    # Example 1: Domain name lookup
    # Decode the query when needed, like for IDNs
    # or names with national characters.

    my $q = 'norid.no';
    #$q = decode('ISO8859-1', 'øl.no');

    # Authenticate with basic authentication 
    my $bo = NOLookup::RDAP::RDAPLookup->new(
     {
	service_url         => 'https://rdap.norid.no',
	debug               => 0,
	use_cache  	    => 0,
	bauth_username      => 'rdapuser@reg1234',
	bauth_password      => '<password>',
     });

    # test HEAD operation for existence
    $bo->lookup($q, 1, 0, 0);
    if ($bo->error) {
       print "HEAD: Error, error / status: ",
          $bo->error . "/" . $bo->status) . "\n";
    }

    # test GET operations
    $bo->lookup($q, 0, 0, 0);
    if ($bo->error) {
       print "GET: Error, error / status: ",
          $bo->error . "/" . $bo->status) . "\n";
    }
	
    # result of lookup is in $bo->result
    # This result contains response objects built by Net::RDAP

    # if a lookup has arguments which results in a search type, the
    # is_a_search method returns true. This is a hint to the caller to
    # process paging information in the result, and maybe perform several
    # next-lookups to get more data.

    my $res = $bo->result;
    print "handle: ", $bo->handle, "\n";

 * See bin/no_rdap.pl for more information on usage.

 * See various formatting/helper functions in this file for how to
   access the various objects returned by Net::RDAP.

=head1 DESCRIPTION

This module provides an object oriented API for use with the
Norid RDAP service. It uses the Net::RDAP module from Cpan
internally to fetch information from the Norid RDAP.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>(nospam)info(at)norid.noE<gt>

=head1 SEE ALSO

L<https://www.norid.no/en>
L<https://teknisk.norid.no/en/integrere-mot-norid/rdap-tjenesten>

=head1 CAVEATS

=head1 AUTHOR

Trond Haugen, E<lt>(nospam)info(at)norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2020- Trond Haugen <(nospam)info(at)norid.no>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 About the Norid RDAP API

See
L<https://teknisk.norid.no/en/integrere-mot-norid/rdap-tjenesten>

=cut

1;
