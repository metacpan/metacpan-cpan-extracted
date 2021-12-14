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
use NOLookup;

# debug only for dev env.
#use LWP::ConsoleLogger::Easy qw /debug_ua /;
use Sys::HostIP;
use Data::Validate::IP qw(is_ip);

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
                  $RDAP_LOOKUP_ERR_INVALID
/;

# Connection problems
our $RDAP_LOOKUP_ERR_NO_CONN         = 100;

# Controlled refuses
our $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED  = 101;
our $RDAP_LOOKUP_ERR_NO_ACCESS       = 102;
our $RDAP_LOOKUP_ERR_REFERRAL_DENIED = 103;
our $RDAP_LOOKUP_ERR_OTHER           = 104;
our $RDAP_LOOKUP_ERR_NO_MATCH        = 105;
our $RDAP_LOOKUP_ERR_NO_CONFORMANCE  = 106;
our $RDAP_LOOKUP_ERR_INVALID         = 107;

my $RDAP_TIMEOUT = 60; # secs (default is 180 secs but we want shorter time).

# Default API service URL
my $SERVICE_URL = "https://rdap.norid.no";

############
#
# RDAP API. See section 'About the Norid RDAP API' below for more info.
#

my %rdap_head_get_method_args = (
    DBDN => 'domain/',
    EBEH => 'entity/',
    NBNH => 'nameserver_handle/'
    );

# Not used RBRH => 'registrar/', same as EBEH => 'entity/' 

my %rdap_get_method_args = (
    NBNN => 'nameservers?name=',
    DBID => 'domains?identity=',
    DBRH => 'domains?registrant=',
    EBID => 'entities?identity='
    );

my $ht;

##
# RDAP API conformance values.
# This library supports and expects the following conformance values.
# if other values are returned, the library _may_ need an upgrade, so the 
# lookup will simply fail if any conformance mismatch is detected.
#

my %rdapConformance_vals_supported = (
    'rdap_level_0'           => 1,
    'rdap_objectTag_level_0' => 1,
    'norid_level_0'          => 1
    );

# Some accessor methods.
# Those starting with '_' are meant for internal use.
my @methods = qw /

    warning
    error
    status

    result
    raw_json_decoded

    _method
    _uri
    _full_url

   /;

__PACKAGE__->mk_accessors( 
    @methods 
);

# Set an env var to suppress warnings from Net::RDAP
unless ($ENV{'NET_RDAP_UA_DEBUG'}) {
    $ENV{'NET_RDAP_UA_DEBUG'} = 0;
}

=head2 new

new handles the following parameters:

  { 
    debug               => <0|1|5>,
    use_cache  	        => <0|1>,
    service_url         => <0|service_url,
    norid_header_secret => <0|test_secret>,
    norid_header_proxy  => <0|1>,
    norid_referral_ip   => <0|1|ip-address>,
  }

 All parameters are optional:

 * use_cache:
   - 1: activate lookup cache, see Net::RDAP for use

 * debug:
   - 0: debug off
   - 1: debug from this module on
   - 5: full debug from Net::RDAP on, see Net::RDAP for use

 * service_url: 
   - the full http(s)-address of the Norid RDAP-servie to
     be accessed. 
   - default is $SERVICE_URL above.

 * norid_header_secret: 
   - access token for layered access, and
     the token is sent in the 'X-RDAP-Secret' header.

 * norid_header_proxy : 
   - Norid internal use only. 
   - true if the calling client can act as a proxy,
     and the header 'X-RDAP-Web-Proxy' is then set to 1.

 * norid_referral_ip : 
   - Norid internal use only.
   - set if the calling client ip address argument shall be sent. When set:
     - if the argument passed is a pure integer, use the local ip-address as value.
     - if the argument passed is a valid ip address, use that address
       as value. This is the normal variant to be used to pass a proper client 
       ip address.
     - the ip-address is passed to the server in the '?client_ip=<ip-address>'
       argument.

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

  $self->SUPER::new($args);

}

=head2 lookup

Do an RDAP lookup.

  - $query      : specifies the query string
  - $check      : specifies if http 'head' shall be done, default is 'get'.
  - $nameservers: must be set to true for nameserver_name search
  - $entity     : must be set to true for entity lookup, in which case the query should 
                  identify an entity, like:
                   - a domain name
                   - a handle, like registrar handle, registrant handle, ns handle or contact handle
                  must be set to false to trig a search if the query
                  contains something that allows a search, like:
                   - identity (organization number, N.PRI.xxx etc)
                   - a registrant handle (P- or O- handle)
                   - a nameserver name (must then be combined with
                     $nameservers=1 to distinguish from a domain name)

=cut

sub lookup {
    my ($self, $query, $check, $nameservers, $entity ) = @_;

    #print STDERR "RDAPLookup: lookup on query: $query, check: ", $check || 0, ", nameservers: ", $nameservers || 0, ", entity: ", $entity || 0, "\n";

    unless ($self->_validate_and_analyze($query, $check, $nameservers, $entity)) {
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

# debug only for dev env.
#    if ($self->{debug} && $self->{debug} > 1) {
#	debug_ua ( $ua, 5 );
#    }

    $ua->default_header( Charset           => "UTF-8");
    $ua->default_header( 'Content-Type'    => "application/rdap+json");

    if ($self->{norid_header_secret}) {
	# Use Norid RDAP layer secret headers
	$ua->default_header( 'X-RDAP-Secret' => $self->{norid_header_secret});
    }

    if ($self->{norid_header_proxy}) {
	# Use Norid RDAP proxy headers
	$ua->default_header( 'X-RDAP-Web-Proxy' => 1);
    }

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

    if ($self->{debug}) {
	print STDERR "_lookup-rdap called with URL: '$URL', and:\n"; 
	print STDERR "  proxy is   : ", $self->{norid_header_proxy} , "\n" if ($self->{norid_header_proxy});
	print STDERR "  secret is  : ", $self->{norid_header_secret}, "\n" if ($self->{norid_header_secret});
	print STDERR "  referral_ip: ", $self->{norid_referral_ip}  , "\n" if ($self->{norid_referral_ip});
    }

    my $resp;
    
    if ($http_type eq 'head') {
	# An RDAP HEAD operation. Head is not supported by Net::RDAP,
	# so call it via the already created UA
	$resp = $ua->head($URL);
	unless ($resp->is_success) {
	    $self->error(_map_rdap_error($query, $resp->code));
	    $self->status($resp->status_line);
	}
	return $self;
    }

    # An RDAP GET operation.
    $resp = $self->fetch(URI->new($URL));

    unless ($resp) {
	#print STDERR "Empty GET resp\n";
	$self->error( _map_rdap_error($query, 404) );
	$self->status("Lookup returned nothing!");
	return $self;
    }
    if ($resp->isa('NOLookup::RDAP::RDAPLookup')) {
	# a $resp is returned, but when fetch() finds nothing, it
	# just returs the $self-object, possible with an error[] filled in,
	# so handle it as nothing found

	#print STDERR "Nothing found returned 'NOLookup::RDAP::RDAPLookup' self resp\n";
	
	my $err = $resp->error;
	if (ref($err) eq 'ARRAY') {
	    my $ix = 0;
	    foreach my $el (@$err) {
		if ($el eq 'errorCode') {
		    $self->error( _map_rdap_error($query, $err->[$ix+1]) );
		    #print STDERR " ARRAY error:", $self->error, "\n";

		} elsif ($el eq 'title') {
		    $self->status($err->[$ix+1]);
		}
		++$ix;		
	    }
	} else {
	    $self->error(_map_rdap_error($query, $err));
	    #print STDERR " scalar error:", $self->error, "\n";
	    $self->status("Lookup rejected or returned no match!");
	}
	#print STDERR " RDAPLookup.pm: lookup_error on URL: $URL, error: ", $self->error, "\n";
	return $self;
    }

    if ($resp->isa('Net::RDAP::Error')) {
	#print STDERR "Error GET resp\n";
	$self->error(_map_rdap_error($query,$resp->errorCode));
	$self->status($resp->title);
	return $self;
    }

    # Check conformance values before we accept the answer
    my @cf = @{$resp->{rdapConformance}};
    foreach my $cfe (@cf) {
	unless ($rdapConformance_vals_supported{$cfe}) {
	    $self->status("Conformance mismatch on key $cfe, this library does not support this RDAP version!");
	    $self->error($RDAP_LOOKUP_ERR_NO_CONFORMANCE);
	    return $self;
	}
    }

    # resp contains the json data
    $self->raw_json_decoded(to_json({%{$resp}}, {utf8 => 1, pretty => 1}));

    $self->result($resp);
    
    return $self;
}

=head2 _map_rdap_error

Some RDAP error is returned from Net::RDAP, ref. Net::RDAP::Error.

Those are normally HTTP response errors in the 400 and 500 range,
which are mapped to one of the $RDAP_LOOKUP_ERR_XXX local errors.

https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
 - All 1xx are not errors, but Ok, need not be handled.
 - All 2xx are not errors, but Ok, need not be handled.
 - All 3xx are redirection errors, which are not expected, 
   map to other if we get it.
 - All 3xx are redirection errors, which are not expected, 
   map to other if we get it.
 
 All 5xx errors are considered connection problems at some level

=cut

sub _map_rdap_error {
    my ($query, $rdap_error) = @_;

    my $rcode;
    if ($rdap_error =~ m/^4\d+$/) {
	# Some client side problem
	if ($rdap_error == 404) {
	    $rcode = $RDAP_LOOKUP_ERR_NO_MATCH;
	} elsif ($rdap_error == 429) {
	    $rcode = $RDAP_LOOKUP_ERR_QUOTA_EXCEEDED;
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

=head2 _validate_and_analyze

 1) Validate ip address, if set
 
 2) Validate query, return if query not among the expexted ones.
    - domain name or name server name
    - some object handle (D, P, R, H)
    - some registrar handle (regXXX-NORID)
    - some identity (9 digits orgno, N.XXX.yyyyyyyy)

 2) Analyze query and args and find what http method and uri arguments
    to use for the lookup and set them in '_method' and '_uri'

=cut

sub _validate_and_analyze {
    my ($self, $q, $check, $ns, $entity) = @_;

    if (my $ip = $self->{norid_referral_ip}) {
	unless (is_ip($ip)) {
	    $self->status("Invalid referral ip address: $ip");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
    }
    
    my $arg;
    
    $q =~ s/\s+//g if ($q);

    unless ($q) {
        $self->status("mandatory query parameter not specified");
        $self->error($RDAP_LOOKUP_ERR_INVALID);
	return 0;
    }

    if ($q =~ m/^\d{9}$/) {
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
	# Search domains by identity to get list of domain names for that orgno
	$arg = 'DBID';
	if ($entity) {
	    # search entities by identity to get list of handles with that orgno
	    $arg = 'EBID';
	}

    } elsif ($q =~ /^N\.(PRI|LEG|ORG|REG)\.\d+$/i) {
	$q = uc($q);

	# Some other identity
	# domains by identity is default
	$arg = 'DBID';
	if ($entity) {
	    # entities by identity
	    $arg = 'EBID';
	}

    } elsif ($q =~ /REG(\d+)-NORID$/i) {
	# registrar handle lookup
	# is case sensitive, syntax: 'reg2-NORID'
	$q = "reg$1-NORID";

	# registrar by reg handle RBRH, same as EBEH, so use that
	$arg = 'EBEH';
	
    } elsif ($q =~ /.+([PORH])-NORID$/i) {
	# P, O, R or H handle
	# Note D-handle lookup is not supported by the rdap, use the domain name instead
	$q = uc($q);

	my $ot = uc($1);
	
	if ($ot eq 'P' || $ot eq 'O') {
	    # is a registrant handle

	    # domains by registrant handle is default
	    $arg = 'DBRH';
	    if ($entity) {
		# entities by entity handle
		$arg = 'EBEH';
	    }

	} elsif ($ot eq 'H') {
	    # is a name server handle

	    # nameserver_handle by nameserver handle is default
	    $arg = 'NBNH';
	    if ($entity) {
		# entity by entity handle not possible here
		#$arg = 'EBEH';
	    }

	} else {
	    # is a D or R, only option is lookup entity by entity handle
	    $arg = 'EBEH';
	}
	
    } elsif ($q =~ /.+\..+$|^\.(no.*)$/i) {

	# Some string with a dot in it is assumed to be a domain name or name server
	# name, or just 'no' itself
	$q = lc($q);

	# TODO: if $1, we have no alone to be looked up, maybe RDAP
	# will need only one syntax, like 'no.' for the name,
	# adjust $q to comply to the rule if it comes.
	if ($1) {
	    #print "STDERR: a single no domain lookup requested, q: $q\n";
	    # adjust $q here:
	}
	
	# domain by domain name is default
	$arg = 'DBDN';
	if ($ns) {
	    # nameservers by name server name (NBNN)
	    $arg = 'NBNN';
	}
	
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

    if ($check) {
	unless ($rdap_head_get_method_args{$arg}) {
	    $self->status("No success in finding a HEAD lookup method for $arg, try a valid query combination: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}
	$self->_method('head');
	$self->_uri($rdap_head_get_method_args{$arg} . $q);

    } else {
	unless ($rdap_head_get_method_args{$arg} || $rdap_get_method_args{$arg}) {
	    $self->status("No success in finding a GET lookup method for $arg, try a valid query combination: $q");
	    $self->error($RDAP_LOOKUP_ERR_INVALID);
	    return 0;
	}

	$self->_method('get');

	if ($rdap_head_get_method_args{$arg}) {
	    $self->_uri($rdap_head_get_method_args{$arg} . $q);
	} else {
	    $self->_uri($rdap_get_method_args{$arg} . $q);
	}
    }
    # remember the query 
    $self->{query} = $q;

    return 1;
}

=head2 result_as_rdap_string

Return sensible rdap formatted string.
Uses internal helper formatting functions.

Shows how to access data returned by Net::RDAP.

=cut

sub result_as_rdap_string {
    my ($self, $check, $nameservers, $entity, $short, $expand) = @_;

    my @errors;

    my $response = $self->result;

    my $rs = "";
    
    if ($response->isa('Net::RDAP::Error')) {
	push(@errors, sprintf("%03u (%s)", $response->errorCode, $response->title));
	
    } elsif ($response->isa('Net::RDAP::SearchResult')) {

	foreach my $o ($response->nameservers, $response->domains, $response->entities) {
	    my ($rst, $errs) = $self->rdap_obj_as_string($o, $check, $nameservers, $entity, $short, $expand);
	    $rs .= $rst if ($rst);
	    push @errors, @$errs if ($errs && @$errs);

	}

    } else {

	my ($rst, $errs) = $self->rdap_obj_as_string($response, $check, $nameservers, $entity, $short, $expand);
	$rs .= $rst if ($rst);
	push @errors, @$errs if ($errs && @$errs);
    }

    return $rs, \@errors;

}

=head2 rdap_obj_as_string

Return sensible rdap formatted string.

Code stolen from rdapper and adapted.

=cut

sub rdap_obj_as_string {
    my ($self, $response, $check, $nameservers, $entity, $short, $expand) = @_;

    my @errors;
    my $rs = "";
    
    if ('entity' ne $response->class) {

	my ($name, $xname) = $self->rdap_get_obj_name($response);

	if ($xname ne $name) {
	    $rs .= sprintf("\nName: %s (%s)\n\n", $xname, $name);
	} else {
	    $rs .= sprintf("\nName: %s\n\n", $name);
	}
    }

    $rs .= sprintf("Handle: %s\n\n", $response->handle);

    if ('ip network' eq $response->class) {
	$rs .= sprintf("Range: %s\n\n", $response->range->prefix);
	$rs .= sprintf("Domain: %s\n\n", $response->domain->as_string);
	
    } elsif ('autnum' eq $response->class) {
	$rs .= sprintf("Range: %u - %u\n\n", $response->start, $response->end) if ($response->start > 0 && $response->end > 0);
	$rs .= sprintf("Type: %s\n\n", $response->type) if ($response->type);
	
    } elsif ('domain' eq $response->class) {
	my @ns = $response->nameservers;
	if (scalar(@ns) > 0) {
	    $rs .= "Nameservers:\n\n";
	    foreach my $ns (sort { lc($a->name->name) cmp lc($b->name->name) } @ns) {
		$rs .= sprintf("  %s\n", $ns->name->name);
	    }
	    $rs .= "\n";
	}
	
	my @ds = $response->ds;
	if (scalar(@ds) > 0) {
	    $rs .= "DNSSEC:\n\n";
	    foreach my $ds ($response->ds) {
		$rs .=  sprintf("  %s. IN DS %u %u %u %s\n", uc($ds->name),
				$ds->keytag, $ds->algorithm, $ds->digtype, uc($ds->digest));
	    }
	    $rs .= "\n";
	}
	
	my @keys = $response->keys;
	if (scalar(@keys) > 0) {
	    $rs .= "DNSSEC Keys:\n\n";
	    foreach my $key (@keys) {
		$rs .= sprintf("  %s. IN DNSKEY %u %u %u %s\n", uc($key->name), $key->flags, $key->protocol, $key->algorithm, uc($key->key));
	    }
	    $rs .= "\n";
	}
	
    } elsif ('entity' eq $response->class) {
	$rs .= $self->rdap_vcard_as_string($response->vcard, ' ' x 2);
	
    } elsif ('nameserver' eq $response->class) {
	$rs .= "IP Addresses:\n\n";

	my @addrs = $response->addresses;
	if (scalar(@addrs) > 0) {
	    foreach my $ip (@addrs) {
		$rs .= sprintf("  * %s\n", $ip->ip);
	    }
	} else {
	    $rs .= "  * (no IP addresses returned)\n";
	}
	$rs .= "\n";
    }

    my @events = $response->events;
    if (scalar(@events)) {
	$rs .= "Events:\n\n";
	foreach my $event (@events) {
	    # DateTime object is UTC, convert to localtime
	    my $to = $event->date;
	    $to->set_time_zone('Europe/Oslo');
	    $rs .= sprintf("  %s: %s\n", ucfirst($event->action), scalar($to->date));
	}
	$rs .= "\n";
    }
    
    my @status = $response->status;
    if (scalar(@status) > 0) {
	$rs .= "Status:\n\n";
	foreach my $status (@status) {
	    my $epp = rdap2epp($status);
	    if ($epp) {
		$rs .= sprintf("  * %s (EPP: %s)\n", $status, $epp);
		
	    } else {
		$rs .= sprintf("  * %s\n", $status);
	    }
	}
	$rs .= "\n";
    }
    
    my @entities = $response->entities;
    my %entities;
    foreach my $ent (@entities) {
	
	if (!$ent->vcard && $expand) {

	    my $ro = NOLookup::RDAP::RDAPLookup->new(
		{
		    service_url         => $self->{service_url},
		    debug               => $self->{debug},
		    use_cache           => $self->{use_cache},
		    norid_header_secret => $self->{norid_header_secret},
		    norid_header_proxy  => $self->{norid_header_proxy},
		});
	    
	    my $new = $ro->lookup($ent->handle, $check, $nameservers, 1);
	    
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
	$rs .= "Entities:\n\n";
	
	foreach my $entity (@entities) {
	    
	    my @roles = $entity->roles;
	    if (scalar(@roles) > 0) {
		if ($entity->handle) {
		    $rs .= sprintf("  Entity %s (%s):\n\n", $entity->handle, join(', ', sort(@roles)));
		    
		} else {
		    $rs .= sprintf("  %s:\n\n", join(', ', map { sprintf('%s Contact', ucfirst($_)) } sort(@roles)));
		    
		}
		
	    } else {
		$rs .= sprintf("  Entity %s:\n\n", $entity->handle);
		
	    }
	    
	    my $card = $entity->vcard;
	    if (!$card) {
		$rs .= "    (no further information available)\n\n";
		
	    } else {
		$rs .= $self->rdap_vcard_as_string($card, ' ' x 4);
		
	    }
	}
    }
    
    if (!$short) {
	my @links = $response->links;
	if (scalar(@links) > 0) {
	    $rs .= "Links:\n";
	    foreach my $link (@links) {
		$rs .= sprintf("\n  * %s (%s)\n", $link->href->as_string, $link->title || $link->rel || '-');
	    }
	    $rs .= "\n";
	}
	
	my @remarks = $response->remarks;
	if (scalar(@remarks) > 0) {
	    $rs .= "Remarks:\n\n";
	    foreach my $remark (@remarks) {
		my $indent = ' ' x 2;
		
		$rs .= sprintf("  %s:\n  %s\n\n", $remark->title, ('=' x (1 + length($remark->title)))) if ($remark->title);
		
		$rs .= fill($indent, $indent, join("\n", $remark->description))."\n";
		
		foreach my $link ($remark->links) {
		    $rs .= sprintf("\n%s* %s (%s)\n", ($indent x 2), $link->href->as_string, ($link->title || $link->rel || '-'));
		}
		
		$rs .= "\n";
	    }
	}
	
	my @notices = $response->notices;
	if (scalar(@notices) > 0) {
	    $rs .= "Notices:\n\n";
	    foreach my $notice (@notices) {
		my $indent = ' ' x 2;
		
		$rs .= sprintf("  %s:\n  %s\n\n", $notice->title, ('=' x (1 + length($notice->title)))) if ($notice->title);
		
		$rs .= fill($indent, $indent, join("\n", $notice->description))."\n";
		
		foreach my $link ($notice->links) {
		    $rs .= sprintf("\n%s* %s (%s)\n", ($indent x 2), $link->href->as_string, ($link->title || $link->rel || '-'));
		}
		
		$rs .= "\n";
	    }
	}
    }

    return $rs, \@errors;
}

=head2 rdap_vcard_as_string

Format vcard object(s) as string.

=cut

sub rdap_vcard_as_string {
    my ($self, $card, $indent) = @_;

    my $vc = "";
    
    $vc .= sprintf("%sName: %s\n\n", $indent, $card->full_name) if ($card->full_name);
    $vc .= sprintf("%sOrganization: %s\n\n", $indent, $card->organization) if ($card->organization);
    
    my @addresses = @{$card->addresses};
    if (scalar(@addresses) > 0) {
	foreach my $address (@addresses) {
	    $vc .= sprintf("%sAddress:\n\n", $indent);
	    
	    my @lines;
	    foreach my $element (@{$address->{'address'}}) {
		push(@lines, ('ARRAY' eq ref($element) ? @{$element} : $element));
	    }
	    
	    $vc .= sprintf $indent."  ".join(sprintf("\n%s  ", $indent), grep { length > 0 } map { s/^[ \t\r\n]+//g ; s/[ \t\r\n]+$//g ; $_ } @lines)."\n\n";
	}
    }
    
    foreach my $email (@{$card->email_addresses}) {
	if ($email->{'type'}) {
	    $vc .= sprintf("%sEmail: %s (%s)\n\n", $indent, $email->{'address'}, $email->{'type'});
	    
	} else {
	    $vc .= sprintf("%sEmail: %s\n\n", $indent, $email->{'address'});
	    
	}
    }

    foreach my $number (@{$card->phones}) {
	my @types = ('ARRAY' eq ref($number->{'type'}) ? @{$number->{'type'}} : ($number->{'type'}));
	my $type = ((any { lc($_) eq 'fax' } @types) ? 'Fax' : 'Phone');
	$vc .= sprintf("%s%s: %s\n\n", $indent, $type, $number->{'number'});
    }
    
    return $vc;
    
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
    die "unknown handle type for: $handle";
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

    my $bo = NOLookup::RDAP::RDAPLookup->new(
     {
	service_url         => 'https://rdap.norid.no',
	debug               => 0,
	use_cache  	    => 0,
	norid_header_secret => 'secret1234',
	norid_header_proxy  => 1,
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

L<http://www.norid.no/en>
L<https://www.norid.no/en/registrar/system/tjenester/whois-das-service>
L<https://teknisk.norid.no/en/registrar/system/tjenester/rdap>
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

From Norid doc:

RDAP is based on a subset of the HTTP protocol. The server accepts
requests of type GET and HEAD. GET lookup is answered with data about
the object in question. HEAD responds if the object exists or
not. Both request types are answered with return code 200 / OK if the object
exists, and return code 404 / NOT FOUND if the object does not exist, and other
return code for other error types.

The server supports the following types of lookups:

    GET/HEAD https://rdap.norid.no/domain/<domenenavn>
    GET/HEAD https://rdap.norid.no/entity/<handle>
    GET/HEAD https://rdap.norid.no/registrar/<reg_handle>     (Norid extension)
      Note: Returns same result as /entity/<reg_handle>
    GET/HEAD https://rdap.norid.no/nameserver_handle/<handle> (Norid extension)

And the following searches:

    GET https://rdap.norid.no/nameservers?name=<hostname>
    GET https://rdap.norid.no/domains?identity=<identity>  (Norid extension for proxy)
    GET https://rdap.norid.no/domains?registrant=<handle>  (Norid extension for proxy)
    GET https://rdap.norid.no/entities?identity=<identity> (Norid extension for proxy)

=cut

1;
