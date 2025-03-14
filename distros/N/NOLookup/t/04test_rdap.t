#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Encode;
use NOLookup::RDAP::RDAPLookup
    qw / $RDAP_LOOKUP_ERR_NO_MATCH $RDAP_LOOKUP_ERR_FORBIDDEN /;

# Use ipv4 only sockets for easier config
#use IO::Socket::SSL 'inet4';

use Data::Dumper;
$Data::Dumper::Indent=1;

require_ok('NOLookup::RDAP::RDAPLookup');

my $debug = 0;

my %ehandles;
my %rhandles;
my %identities;
my %ns_handles;
my %ns_names;
my %ns_ips;

my (%iptested, %idtested, %ehtested, %nsntested, %nsniptested, %dnnsntested);

# A test domain that need to be registered.
my @doms = (
    qw/
    norid.no
    /
    );

#############
#
# Test pass 1):
# - Test lowest layer access. This access is open for the world.
# - The tests are should be successful if rate limiting is not
#   trigged.
#    
# Test pass 2):
# - Test basic auth layer access for 'registrar' layer.
#   Access uses a username and a password, and requires configuration
#   granted for the calling ip-address, username and password.
# - The tests are activated and should be successful if
#   $ENV{RDAP_REGISTRAR_BASIC_AUTH_USER} is set along with
#   $ENV{RDAP_REGISTRAR_BASIC_AUTH_PASSWORD} and if the rate
#   limiting is not trigged.
#
# Test pass 3):
# - Test basic auth layer access for 'registry' layer.
#   Access uses a username and a password, and requires configuration
#   granted for the calling ip-address, username and password.
# - The tests are activated and should be successful if
#   $ENV{RDAP_REGISTRY_BASIC_AUTH_USER} is set along with
#   $ENV{RDAP_REGISTRY_BASIC_AUTH_PASSWORD} and and if the rate
#   limiting is not trigged.
#
############

my $service_url = $ENV{RDAP_SERVICE_URL} || 'https://rdap.test.norid.no';

unless ($service_url) {
    ok(1, "No service URL set, aborting tests");
}

ok(1, "Testing towards service: $service_url");

my $test_secret;
my $test_proxy;
my $referral_ip;
my $bauth_username;
my $bauth_password;
my $type;
my $fieldset = 'full';
my $nopages  = 2;

my $layer_anonymous = 'anonymous';
my $layer_registrar = 'registrar';
my $layer_registry  = 'registry';

# Pass 1: Anonymeous, no auth
ok(1 , "=== Pass 1: Testing '$layer_anonymous' layer");
&run_tests($layer_anonymous, 1);

# Pass 2:
if ($ENV{RDAP_REGISTRAR_BASIC_AUTH_USER} && $ENV{RDAP_REGISTRAR_BASIC_AUTH_PASSWORD}) {
    #### Pass 2: Basic auth: Registrar layer
    ok(1 , "=== Pass 2: Testing basic auth '$layer_registrar' layer");
    $bauth_username = $ENV{RDAP_REGISTRAR_BASIC_AUTH_USER};
    $bauth_password = $ENV{RDAP_REGISTRAR_BASIC_AUTH_PASSWORD};
    &run_tests($layer_registry, 2);
} else {
    ok(1 , "=== Pass 2: SKIP testing basic auth '$layer_registrar' layer");
}

# Pass 3:
if ($ENV{RDAP_REGISTRY_BASIC_AUTH_USER} && $ENV{RDAP_REGISTRY_BASIC_AUTH_PASSWORD}) {
    #### Pass 3: Basic auth: Registry layer
    ok(1 , "=== Pass 3: Testing basic auth '$layer_registry' layer");
    $bauth_username = $ENV{RDAP_REGISTRY_BASIC_AUTH_USER};
    $bauth_password = $ENV{RDAP_REGISTRY_BASIC_AUTH_PASSWORD};
    &run_tests($layer_registry, 3);
} else {
    ok(1 , "=== Pass 3: SKIP Testing basic auth '$layer_registry' layer");
}


=head2 run_tests

Run the tests for a given layer.

=cut

sub run_tests {
    my ($layer, $pass, $do_search) = @_;

    &init_test_data();
    
    # Domains to test:
    #print STDERR "$pass: doms      : ", Dumper \@doms, "\n";

    ok(1, " Pass $pass START - Domains: '$layer'");
    test_domain_names_lookup($layer);
    ok(1, " Pass $pass DONE - Domains: '$layer'");

    ok(1, " Pass $pass START - Nameservers: '$layer'");
    test_nameserver_handles_lookup($layer);
    ok(1, " Pass $pass DONE - Nameservers: '$layer'");
    
    ok(1, " Pass $pass START - Entity handles: '$layer'");
    test_entity_handles_lookup($layer);
    ok(1, " Pass $pass END - Entity handles: '$layer'");

    #print STDERR "$pass: ns ips: ", Dumper(\%ns_ips), "\n";
    ok(1, " Pass $pass START - Domains by nameserver ips: '$layer'");
    test_domains_by_nameserver_ips_lookup($layer);
    ok(1, " Pass $pass END - Domains by nameserver ips: '$layer'");
    
    ok(1, " Pass $pass START - Nameservers by nameserver ips: '$layer'");
    test_nameservers_by_nameserver_ips_lookup($layer);
    ok(1, " Pass $pass END - Nameservers by nameserver ips: '$layer'");

    #print STDERR "$pass: ns names: ", Dumper(\%ns_names), "\n";
    ok(1, " Pass $pass START - Domains by nameserver names: '$layer'");
    test_domains_by_nameserver_names_lookup($layer);
    ok(1, " Pass $pass DONE - Domains by nameserver names: '$layer'");

    ok(1, " Pass $pass START - Nameserver names: '$layer'");
    test_nameservers_by_nameserver_names_lookup($layer);
    ok(1, " Pass $pass DONE - Nameserver names: '$layer'");

    #print STDERR "$pass: identities: ", Dumper(\%identities), "\n";
    ok(1, " Pass $pass START - Identity lookup: '$layer'");
    test_domains_by_identities_lookup($layer);
    ok(1, " Pass $pass END - Identity lookup: '$layer'");

    #print_test_data($layer);
}

=head2 init_test_data

Init test data before a new layer test shall be performed.

=cut

sub init_test_data {
    %ehandles   = ();
    %rhandles   = ();    
    %identities = ();
    %ns_handles = ();
    %ns_names   = ();
    %ns_ips     = ();

    %iptested    = ();
    %idtested    = ();
    %ehtested    = ();
    %nsntested   = ();
    %nsniptested = ();
    %dnnsntested = ();
    
}

=head2 print_test_data

Print test data collected by the tests.

=cut

sub print_test_data {
    my ($pass) = @_;
    
    # Related handles etc. collected from the domains
    print STDERR "$pass: ehandles  : ", Dumper(\%ehandles)  , "\n";
    print STDERR "$pass: rhandles  : ", Dumper(\%rhandles)  , "\n";
    print STDERR "$pass: identities: ", Dumper(\%identities), "\n";
    print STDERR "$pass: ns_handles: ", Dumper(\%ns_handles), "\n";
    print STDERR "$pass: ns_names  : ", Dumper(\%ns_names)  , "\n";
    print STDERR "$pass: ns_ips    : ", Dumper(\%ns_ips)    , "\n";
}


=head2 test_domain_names_lookup

A 'domain' is looked up

=cut

sub test_domain_names_lookup {
    my ($layer) = @_;

    ok(1, "=== test_domain_names_lookup() for '$layer' ===");
    
    foreach my $q (sort @doms) {

	my $q = decode('ISO8859-1', $q);
	my $ro = ro_obj();

	process_head_get_lookup($layer, 'HEAD', $q, $ro, 1, 0, 0);
	process_head_get_lookup($layer, 'GET' , $q, $ro, 0, 0, 0);

	my $res = $ro->result;

	#print "domain res: ", Dumper $res;

	my $handle = $res->handle;
	my $htype  = $ro->norid_handle_type($handle);

	ok($res->class eq 'domain', "Class is : " . $res->class);
	ok($res->isa('Net::RDAP::Object::Domain'), "isa(Net::RDAP::Object::Domain)"); 
	ok($handle, "Domain handle found for q: $handle");
	
	&process_domain($layer, $q, $htype, $ro, $res);
    }

}

=head2 test_nameserver_handles_lookup

Lookup nameserver handles and test.

Test max. 2 names.

=cut

sub test_nameserver_handles_lookup {
    my ($layer) = @_;

    ok(1, "=== test_nameserver_handles_lookup() for '$layer' ===");

    my $ix = 0;
    
    foreach my $q (sort keys %ns_handles) {

	my $ro = ro_obj();

	process_head_get_lookup($layer, 'HEAD', $q, $ro, 1, 0, 0);
	process_head_get_lookup($layer, 'GET' , $q, $ro, 0, 0, 0);

	my $res = $ro->result;

	#print "Nameserver handle lookup res: ", Dumper $res;
	
	ok($res->class, "Class is : " . $res->class);
	ok($res->isa('Net::RDAP::Object::Nameserver'), "isa(Net::RDAP::Object::Nameserver)"); 

	my $handle = $res->handle;
	my $htype = $ro->norid_handle_type($handle);

	ok($htype eq 'host', "NS htype found for q: $htype");

	ok($handle, "NS handle found for q: $handle");

	ok(1, "GET Result for htype: '$htype' is set for q: " . encode('UTF-8', $q));
	
	# entity after direct lookup
	ok($res->handle, "Entity nameserver handle found for q: " . $res->handle);

	&process_nameserver($layer, $q, $htype, $ro, $res);

	++$ix;
	last if ($ix == 4);
    }
}

=head2 test_entity_handles_lookup

Lookup entity handles and test.

=cut

sub test_entity_handles_lookup {
    my ($layer) = @_;

    ok(1, "=== test_entity_handles_lookup() for '$layer' ===");

    my $ix = 0;
    foreach my $q (sort keys %ehandles) {

	last if $ehtested{$q};
	$ehtested{$q} = 1;

	my $ro = ro_obj();

	process_head_get_lookup($layer, 'HEAD', $q, $ro, 1, 0, 0);
	process_head_get_lookup($layer, 'GET' , $q, $ro, 0, 0, 1);

	my $res = $ro->result;

	#print "Entity handle lookup of $q,  res: ", Dumper $res; 

	ok($res->class, "Class is : " . $res->class);
	ok($res->isa('Net::RDAP::Object::Entity'), "isa(Net::RDAP::Object::Entity)"); 

	ok($res->handle, "Entity handle found for q: " . $res->handle);

	my $handle = $res->handle;
	my $htype = $ro->norid_handle_type($handle);

	ok(1, "GET Result for htype: '$htype' is set for q: " . encode('UTF-8', $q));
	
	# entity after direct lookup
	ok($res->handle, "Entity nameserver handle found for q: " . $res->handle);

	&process_entity($layer, $q, $htype, $ro, $res);

	++$ix;
	last if ($ix == 4);

    }
}

=head2 test_domains_by_identities_lookup

Test registrant identity number lookup searches, like search on orgnumbers
or registrant handles.

Max 2 ids.

=cut

sub test_domains_by_identities_lookup {
    my ($layer) = @_;

    ok(1, "=== test_entity_handles() for '$layer' ===");

    #print STDERR "ids: ", Dumper \%identities, "\n";

    my $ix = 0;
    
    foreach my $q (sort keys %identities, sort keys %rhandles) {

	last if $idtested{$q};
	$idtested{$q} = 1;

	my $ro = ro_obj();

	# head not supported, just do a get
	process_head_get_lookup($layer, 'GET', $q, $ro, 0, 0, 0);

	my $res = $ro->result;

	if ($ro->error) {
	    # Access layer or other reject on this
	    next;
	}

	ok($res->isa('Net::RDAP::SearchResult'), "isa(Net::RDAP::SearchResult)"); 

	#print "Identity lookup for $q, res: ", Dumper $res;
	my $pix = 0;
	foreach my $do ($res->domains) {
	    my $handle = $do->handle;
	    my $htype  = $ro->norid_handle_type($handle);
	    &process_domain($layer, $q, $htype, $ro, $do);
	    ++$pix;
	    last if ($pix == 3);
	}

	++$ix;
	last if ($ix == 2);
	
    }
}

=head2 test_domains_by_nameserver_ips_lookup

Max 2 ips.

=cut

sub test_domains_by_nameserver_ips_lookup {
    my ($layer) = @_;

    ok(1, "=== test_domains_by_nameserver_ips_lookup() for '$layer' ===");

    #print STDERR "ids: ", Dumper \%identities, "\n";

    my $ix = 0;
    
    foreach my $q (sort keys %ns_ips) {

	last if $iptested{$q};
	$iptested{$q} = 1;
	
	my $ro = ro_obj();

	# head not supported, just do a get
	process_head_get_lookup($layer, 'GET', $q, $ro, 0, 0, 0);

	my $res = $ro->result;

	if ($ro->error) {
	    # Access layer or other reject on this
	    next;
	}

	ok($res->isa('Net::RDAP::SearchResult'), "isa(Net::RDAP::SearchResult)"); 

	#print "Identity lookup for $q, res: ", Dumper $res;
	my $pix = 0;
	foreach my $do ($res->domains) {
	    my $handle = $do->handle;
	    my $htype  = $ro->norid_handle_type($handle);
	    &process_domain($layer, $q, $htype, $ro, $do);
	    ++$pix;
	    last if ($pix == 3);
	}

	++$ix;
	last if ($ix == 2);
	
    }
}


=head2 test_nameservers_by_nameserver_names_lookup

Test nameserver names.

This is a search.

Max 2 names

=cut

sub test_nameservers_by_nameserver_names_lookup {
    my ($layer) = @_;

    ok(1, "=== test_nameservers_by_nameserver_names_lookup() for '$layer' ===");

    my $ix = 0;
    
    foreach my $q (sort keys %ns_names) {

	last if $nsntested{$q};
	$nsntested{$q} = 1;
	
	my $ro = ro_obj();

	# head not supported, just do a get
	process_head_get_lookup($layer, 'GET', $q, $ro, 0, 1, 0);

	my $res = $ro->result;

	if ($ro->error) {
	    # Access layer or other reject on this
	    next;
	}

	ok($res->isa('Net::RDAP::SearchResult'), "isa(Net::RDAP::SearchResult)"); 

	#print "Identity lookup for $q, res: ", Dumper $res;
	my $pix = 0;
	foreach my $ns ($res->nameservers) {
	    my $handle = $ns->handle;
	    my $htype  = $ro->norid_handle_type($handle);
	    &process_nameserver($layer, $q, $htype, $ro, $ns);
	    ++$pix;
	    last if ($pix == 3);
	}

	++$ix;
	last if ($ix == 2);
	
    }
}

=head2 test_nameservers_by_nameserver_ips_lookup

Test nameserver names.

This is a search.

Max 2 names

=cut

sub test_nameservers_by_nameserver_ips_lookup {
    my ($layer) = @_;

    ok(1, "=== test_nameservers_by_nameserver_ips_lookup() for '$layer' ===");

    my $ix = 0;
    
    foreach my $q (sort keys %ns_ips) {

	last if $nsniptested{$q};
	$nsniptested{$q} = 1;

	my $ro = ro_obj();

	# head not supported, just do a get
	process_head_get_lookup($layer, 'GET', $q, $ro, 0, 1, 0);

	my $res = $ro->result;

	if ($ro->error) {
	    # Access layer or other reject on this
	    next;
	}

	ok($res->isa('Net::RDAP::SearchResult'), "isa(Net::RDAP::SearchResult)"); 

	#print "Identity lookup for $q, res: ", Dumper $res;

	my $pix = 0;
	foreach my $ns ($res->nameservers) {
	    my $handle = $ns->handle;
	    my $htype  = $ro->norid_handle_type($handle);
	    &process_nameserver($layer, $q, $htype, $ro, $ns);
	    ++$pix;
	    last if ($pix == 3);
	}

	++$ix;
	last if ($ix == 2);
	
    }
}


=head2 test_domains_by_nameserver_names_lookup

Test domains by nameserver names.

This is a search.

Max 2 names

=cut

sub test_domains_by_nameserver_names_lookup {
    my ($layer) = @_;

    ok(1, "=== test_domains_by_nameserver_names_looup() for '$layer' ===");

    my $ix = 0;
    
    foreach my $q (sort keys %ns_names) {

	last if $dnnsntested{$q};
	$dnnsntested{$q} = 1;

	my $ro = ro_obj();

	# head not supported, just do a get
	process_head_get_lookup($layer, 'GET', $q, $ro, 0, 2, 0);

	my $res = $ro->result;

	if ($ro->error) {
	    # Access layer or other reject on this
	    next;
	}

	ok($res->isa('Net::RDAP::SearchResult'), "isa(Net::RDAP::SearchResult)"); 

	#print "Identity lookup for $q, res: ", Dumper $res;
	my $pix = 0;
	foreach my $do ($res->domains) {
	    my $handle = $do->handle;
	    my $htype  = $ro->norid_handle_type($handle);
	    &process_domain($layer, $q, $htype, $ro, $do);
	    ++$pix;
	    last if ($pix == 3);
	}

	++$ix;
	last if ($ix == 2);
	
    }
}


=head2 process_head_get_lookup

Do an RDAP lookup with relevant parameters.

=cut

sub process_head_get_lookup {
    my ($layer, $op, $q, $ro, $check, $nameservers, $entity) = @_;
    
    # test HEAD operation for existence and object 
    $ro->lookup($q, $check, $nameservers, $entity);
    
    if ($ro->error) {
	if ($ro->error == $RDAP_LOOKUP_ERR_FORBIDDEN) {
	    ok(1, "$op: $layer: Error returned forbidden for $q, error / status: " .
	       $ro->error . "/" . $ro->status);
	} else {
	    ok(0, "$op: $layer: Error returned unexpectedly for $q, error / status: " .
	       $ro->error . "/" . $ro->status);
	}
	return;
    }
    ok(1, "$op OK for q: " . encode('UTF-8', $q));
}
    
=head2 process_domain

- domain (Net::RDAP::Object::Domain):
 - objectClassName = 'domain'
 - handle
 - ldhName
 - unicodeName,
 - nameservers[nameserver]
 - ipAddresses{}
 - entities[entity]
 - events[]
 - secureDNS{}
 - notices[]
 - links[]

=cut

sub process_domain {
    my ($layer, $q, $htype, $ro, $do) = @_;

    ok(1, "=== process_domain() $q, $htype for '$layer' ===");

    ok($do->class eq 'domain', "Class do is : " . $do->class);
    ok($do->isa('Net::RDAP::Object::Domain'), "isa(Net::RDAP::Object::Domain)"); 

    my $handle = $do->handle;
    $htype     = $ro->norid_handle_type($handle);
   
    my @ns = $do->nameservers;
    if (scalar(@ns) > 0) {
	ok(@ns, "Domain NS entries found for $handle: " . scalar(@ns));
	ok(@ns >= 2, "Domain NS at least 2 entries found for $handle: " . scalar(@ns));
	foreach my $ns (@ns) {
	    &process_nameserver($layer, $q, $htype, $ro, $ns);
	}
    } else {
	# MUST have NS!!
	ok(0, "Domain NS entries NOT found for $handle: " . scalar(@ns));
    }
    
    # SecDNS DS?
    if ($do->delegationSigned) {
	ok($do->delegationSigned, "Domain $q IS signed");
    } else{
	ok(1, "Domain $q IS NOT signed");
    }
    
    my @ds = $do->ds;
    if (scalar(@ds) > 0) {
	ok(@ds, "Domain->dnssec DS entries found for $handle: " . scalar(@ds));
	foreach my $ds (@ds) {
	    &process_dnssec_ds($layer, $q, $htype, $ro, $ds);
	}
    } else {
	ok(1, "Domain->dnssec DS entries not found for $handle");
    }
    
    # SecDNS keys?
    my @keys = $do->keys;
    if (scalar(@keys) > 0) {
	ok(@keys, "Domain->dnssec KEY entries found for $handle: " . scalar(@keys));
	foreach my $key (@keys) {
	    &process_dnssec_key($layer, $q, $htype, $ro, $key);
	}
    } else {
	ok(1, "Domain->dnssec KEY entries not found for $handle");
    }
    
    # entities: All are registrant,  registrar and tech-c's if full layer access.
    my @ent = $do->entities;
    
    my $expected_min_cnt = 2;
    
    if ($layer eq $layer_registry) {
	$expected_min_cnt = 3;
    }
    
    if (scalar @ent > 0) {
	ok(@ent, "Domain->entities found for $handle: " . scalar(@ent));
	ok(@ent >= $expected_min_cnt,
	   "Domain->entities at least $expected_min_cnt entities found for $handle: " . scalar(@ent));
	foreach my $en (@ent) {
	    &process_entity($layer, $q, $htype, $ro, $en);
	}	    
    } else {
	# MUST have 3 at least!
	ok(0, "Domain NS entries NOT found for $handle");
    }
}




=head2 process_nameserver

- nameserver:
   - objectClassName = 'nameserver'
   - rdapConformance[]
   - handle
   - ldhName
   - ipAddresses{v4[], v6[]}
   - events[{}]
   - entities[{}]
   - notices[{}]
   - links[{}]

=cut

sub process_nameserver {
    my ($layer, $q, $htype, $ro, $ns) = @_;

    ok(1, "=== process_nameserver() $q, $htype for '$layer' ===");

    ok($ns->isa('Net::RDAP::Object::Nameserver'), "isa(Net::RDAP::Object::Nameserver)"); 
    ok($ns->class, "Class ns is : " . $ns->class);

    my $handle = $ns->handle;
    
    ok($handle, "NS handle is found: $handle");
    ok($ns->name->name, "NS name is found: " . $ns->name->name);
    
    $ns_handles{$handle} = 1;
    $ns_names{$ns->name->name} = 1;

    # test for ip-addresses
    my @addrs = $ns->addresses;
    if (scalar(@addrs) > 0) {
	foreach my $ip (@addrs) {
	    &process_ip($layer, $q, $htype, $ro, $ns, $ip);
	}
    }
    
    my @ent = $ns->entities;
    if (@ent) {
	ok(@ent, "Nameserver->entities found for $handle: " . scalar(@ent));
	foreach my $en (@ent) {
	    &process_entity($layer, $q, $htype, $ro, $en);
	}	    
    }

    my @events = $ns->events;
    if (@events) {
	ok(@events, "Nameserver->events found for $handle: " . scalar(@events));
	foreach my $event (@events) {
	    &process_event($layer, $q, $htype, $ro, $event);
	}	    
    }
}

=head2 process_ip

Test entity handles and org. numbers

- ipAddresses" : {
        "v4" : [
            "1.2.3.2"
         ],
         "v6" : [
            "2001:700:0:5561::1001"
         ]
      },

=cut

sub process_ip {
    my ($layer, $q, $htype, $ro, $ns, $ip) = @_;    

    ok($ns->class, "Class ns is : " . $ns->class);
    
    # Collect and test for ip-addresses
    #print STDERR "ip: ", Dumper $ip;
    $ns_ips{$ip->ip} = 1;
    
    ok($ip->version, "Ip address version: " . $ip->version);
    ok($ip->ip     , "Ip address value  : " . $ip->ip);
}

=head2 process_dnssec_ds

https://metacpan.org/pod/Net::DNS::RR::DS

=cut

sub process_dnssec_ds {
    my ($layer, $q, $htype, $ro, $ds) = @_;

    ok($ds, "DNSSEC DS found: " .
       sprintf("  %s. IN DS %u %u %u %s", uc($ds->name),
	       $ds->keytag, $ds->algorithm, $ds->digtype, uc($ds->digest)));   
}

=head2 process_dnssec_key

  https://metacpan.org/pod/Net::DNS::RR::DNSKEY

=cut

sub process_dnssec_key {
    my ($layer, $q, $htype, $ro, $key) = @_;

    ok($key, "DNSSEC KEY found: " .
       sprintf("  %s. IN DNSKEY %u %u %u %s", uc($key->name), $key->flags, $key->protocol, $key->algorithm, uc($key->key)));
}


=head2 process_search_result

FIXME: Search tests

=cut

sub process_search_result {
    my ($layer, $q, $htype, $ro) = @_;

    ok(1, "=== process_search_result() for '$layer' ===");

    my $res = $ro->result;

    ok($res->class, "Class is : " . $res->class);
    
    my @doms = $res->domains;
    
    ok(@doms, "Domains found for $q, found: " . scalar(@doms));
	    
    foreach my $dom (@doms) {
	ok($dom->handle, "Domain handle in dom found for q: " . $dom->handle);
	
	my $name = $dom->name;
	my $xname;
	if ($name) {
	    if ('Net::DNS::Domain' eq ref($name)) {
		$xname = $name->xname;
		$name = $name->name;
	    } else {
		$xname = $name;
	    }
		}
	ok($name,  "Domain search returned domain name : " . $name); 
	ok($xname, "Domain search returned domain xname: " . encode('UTF-8', $xname)); 
    }
}


=head2 process_entity

- entity:
  - objectClassName = 'entity'
  - rdapConformance[]
  - handle
  - roles [techical, registrar, registrant] only if domain
  - events
  - vcardArray' => [vcard,]
  - publicIds[{}]  
  - notices[{}]
  - links[{}]


=cut

sub process_entity {
    my ($layer, $q, $htype, $ro, $en) = @_;

    ok(1, "=== process_entitys() $q, $htype for '$layer' ===");

    ok($en->class eq 'entity', "Class en is : " . $en->class);

    my $eh = $en->handle;
    my $ehtype = $ro->norid_handle_type($eh);
	    
    #print STDERR "EN HANDLE2: ", $en->handle, " said to be ehtype: $ehtype\n";
    my @roles = $en->roles;
    if (@roles) {
	my $role = $roles[0];
	ok(@roles, "Entity roles are found: $role");
	
	ok($en->handle, "Entity->entities->handle is found: " .
	   $en->handle . " ($role)");
    } else {
	ok(1, "Entity roles are not found for $q, $htype");
    }

    if ($ehtype eq 'organization' || $ehtype eq 'person') {
	# A registrant handle
	$rhandles{$eh} = 1;
    }
    
    &process_vcard($layer, $q, $ehtype, $ro, $en);
    
    my @ids = $en->ids;
    if (scalar(@ids)) {
	foreach my $id (@ids) {
	    &process_id($layer, $q, $ehtype, $ro, $id);
	}
    }

    my @events = $en->events;
    if (scalar(@events)) {
	ok(1, "Events found: " . scalar(@events));
	foreach my $ev (@events) {
	    &process_event($layer, $q, $ehtype, $ro, $ev);
	}
    }    

    # Save the entity handle
    $ehandles{$eh} = 1;
    
}

=head2 process_id

        "publicIds" : [
            {
               "identifier" : "985821585",
               "type" : "Norwegian organization number"
            }
         ],
 

=cut

sub process_id {
    my ($layer, $q, $htype, $ro, $id) = @_;

    ok(1, " * process_id() $q, $htype for '$layer' ===");

    ok($id->type      , "Id type found: " . $id->type);
    ok($id->identifier, "Id identifier found: " . $id->identifier);

    if ($htype eq 'organization' || $htype eq 'person') {
	$identities{$id->identifier} = 1;
    }
}

=head2 process_event

        "events" : [
            {
               "eventAction" : "registration",
               "eventDate" : "2010-02-10T10:28:20Z"
            },
 
=cut

sub process_event {
    my ($layer, $q, $htype, $ro, $event) = @_;

    ok(1, " * process_event() $q, $htype for '$layer' ===");

    ok($event->isa('Net::RDAP::Event'), "isa(Net::RDAP::Event)"); 
    
    # DateTime object is UTC, convert to localtime
    my $to = $event->date;
    $to->set_time_zone('Europe/Oslo');
    ok(1, ucfirst($event->action) . ": " . scalar($to->date));
}

=head2 process_vcard

Test a VCARD

Note that address is an array with fixed indexes.

=cut

sub process_vcard {
    my ($layer, $q, $htype, $ro, $en) = @_;

    ok(1, " * process_vcard() $q, $htype for '$layer' ===");

    my $card = $en->vcard;
    
    ok($en->class eq 'entity', "Class is: " . $en->class);

    ok($card->isa('vCard'), "isa(vCard)"); 
    
    my $eh = $en->handle;
    my $ehtype = $ro->norid_handle_type($eh);

    ok($eh, "Vcard processed for entity: $eh...");
    
    #print "vcard: layer: $layer, handle: $handle, htype: $htype\n";
    #print "card : ", Dumper $card, "\n";

    my @addresses = @{$card->addresses};
    if (scalar(@addresses) > 0) {
	foreach my $address (@addresses) {

	    #print "card address for $handle, entity: $eh: ", Dumper $address, "\n";
   
	    my @lines;
	    my $ix = 0;
	    foreach my $element (@{$address->{'address'}}) {
		my @val = ('ARRAY' eq ref($element) ? @{$element} : $element);
		
		foreach my $al (@val) {
		    
		    # empty $al is the case when it is actually empty,
		    # or if no access to it is granted
		    next unless $al;

		    my $utfal = encode('UTF-8', $al);
		    
		    if ($ix < 3) {
			if ($ehtype eq 'registrar') {
			    # 0: PoBox, 1: extended address, 2: street address 

			    # Address for registrar shall be accessible for all layers
			    ok($al , "$htype address line found: $utfal");
			    
			} else {
			    # Address for other entities shall be accessible
			    # by registry layer or if own objects
			    ok($al , "$htype address line found: $utfal") if ($layer eq $layer_registry);
			    ok(!$al, "$htype address line not found") if ($layer eq $layer_anonymous);
			}
			
		    } elsif ($ix == 3) {
			if ($ehtype eq 'registrar') {
			    ok($al, "$htype city line found: $al");
			} else {
			    # city: shall be accessible by GDPR layer only
			    ok($al, "$htype city line found: $utfal")  if ($layer eq $layer_registry);
			    ok(!$al, "$htype city line not found")  if ($layer eq $layer_anonymous);
			}
			
		    } elsif ($ix == 4) {
			unless ($al) {
			    ok (1, "$htype empty region line is OK");
			    next;
			}
			if ($ehtype eq 'registrar') {
			    ok($al, "$htype region line found: $al");
			} else {
			    # region shall be accessible
			    # by GDPR layer only
			    ok($al, "$htype region line found: $utfal")  if ($layer eq $layer_registry);
			    ok(!$al, "$htype region line not found") if ($layer eq $layer_anonymous);
			}
			
		    } elsif ($ix == 5) {
			if ($ehtype eq 'registrar') {
			    ok($al, "$htype region line found: $utfal");
			} else {
			    # pcode / zip shall be accessible
			    # by GDPR layer only
			    ok($al, "$htype pcode/zip line found: $utfal") if ($layer eq $layer_registry);
			    ok($al, "$htype pcode/zip line found") if ($layer eq $layer_anonymous);
			}

		    } elsif ($ix == 6) {
			# country shall be accessible
			# by all layers
			ok($al, "$htype country line found: $utfal");
					    
		    } else {
			die "Should not end at this index $ix";
		    }
		}
		++$ix;
	    }
	}
    }
}

=head2 ro_obj

Make an RDAP lookup object.

=cut

sub ro_obj {
    my $query = shift || undef;
        
    return NOLookup::RDAP::RDAPLookup->new(
	{
	    service_url         => $service_url,
	    debug               => $debug,
	    use_cache  	        => 1,
	    norid_header_secret => $test_secret,
	    norid_header_proxy  => $test_proxy,
	    norid_referral_ip   => $referral_ip,
	    bauth_username      => $bauth_username,
	    bauth_password      => $bauth_password,
	    type                => $type,
	    fieldset            => $fieldset,
	    nopages             => $nopages,
	    # force ipv4 usage for static ip, as ipv6 addresses may be changed
	    force_ipv           => 4,
	});
}
