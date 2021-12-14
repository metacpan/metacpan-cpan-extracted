#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Encode;
use NOLookup::RDAP::RDAPLookup 1.19;

# Use ipv4 only sockets for easier config
use IO::Socket::SSL 'inet4';

use Data::Dumper;
$Data::Dumper::Indent=1;

require_ok('NOLookup::RDAP::RDAPLookup');

my @handles;
my @onos;
my @ns_names;

# A couple of test domains that need to be registered.
my @doms = (
    qw/
    norid.no
    øl.no
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
# - Test GDPR access layer access. Access is open only for
#   users who have received a valid access token from Norid.
# - The tests are activated and should be successful if
#   $ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN} is set to a gdpr layer access
#   token, and if the rate limiting is not trigged.
#
# Test pass 3):
# - Test GDPR access layer access and also Norid proxy access.
#   Access needs both a GDPR layer access token and
#   proxy access configuration granted for the calling ip-address,
#   Proxy access is only given to Norid.
# - The tests are activated and should be successful if
#   $ENV{RDAP_GDPR_NORID_PROXY} is set along with a valid
#   $ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN},
#   and if the rate limiting is not trigged.
#
############

my $service_url = $ENV{RDAP_SERVICE_URL} || 'https://rdap.norid.no';

unless ($service_url) {
    ok(1, "No service URL set, aborting tests");
}

ok(1, "Testing towards service: $service_url");

my $test_secret;
my $test_proxy;

#### Pass 1)

ok(1, "=== Pass 1: Testing basic layer access");

test_doms();

if ($ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN}) {
    #### Pass 2)

    $test_secret = $ENV{RDAP_GDPR_LAYER_ACCESS_TOKEN};
    ok($test_secret, "=== Pass 2: GDPR access layer secret set - running layer tests with secret: $test_secret");

    test_doms();

    if ($ENV{RDAP_GDPR_NORID_PROXY}) {

	#### Pass 3)

	$test_proxy  = 1;
	ok(1 , "=== Pass 3: Norid specific proxy config activated - testing proxy extensions");

	test_doms();
	test_handles_onos();

    } else {
	ok(1 , "=== Pass 3: Norid specific proxy config not activated - proxy tests skipped")
    }
    
} else {
    ok(1, "=== Pass 2: GDPR access layer secret not set - skipping layer tests");
}


sub test_doms {
    
    foreach my $q (sort @doms) {

	my $q = decode('ISO8859-1', $q);
    
	my $bo1 = bo_obj();
	my $bo2 = bo_obj();
	
	# test HEAD operation for existence og object 
	$bo1->lookup($q, 1, 0, 0);
	if ($bo1->error) {
	    ok(0, "HEAD: Error returned unexpectedly, error / status: " .
	       $bo1->error . "/" . $bo1->status);
	    next;
	}
	ok(1, "HEAD OK for q: " . encode('UTF-8', $q));
	
	# test GET operations 
	$bo2->lookup($q, 0, 0, 0);
	if ($bo2->error) {
	    ok(0, "GET: Error returned unexpectedly, error / status: " .
	       $bo2->error . "/" . $bo2->status);
	    next;
	}
	
	ok(1, "GET  OK for q: " . encode('UTF-8', $q));
	
	my $res =  $bo2->result;

	ok($res->handle, "Domain handle found for q: " . $res->handle);

	my @ent = $res->entities;
	
	ok(@ent, "Entities found: " . scalar(@ent));

	foreach my $en (@ent) {
	    my @roles = $en->roles;
	    my $role = $roles[0];
	    
	    ok(@roles, "Entity roles are found: $role");
	    ok($en->handle, "Entity handle is found: " .
	       $en->handle . " ($role)");
	    
	    push @handles , $en->handle;
	    
	    my @ids = $en->ids;
	    
	    if (scalar(@ids)) {
		foreach my $id (@ids) {
		    if ($id->type &&
			$id->type eq 'Norwegian organization number') {
			if ($id->identifier =~ m/^\d{9}$/) {
			    push @onos, $id->identifier;
			}
		    }
		}
	    }
	}
	
	my @ns = $res->nameservers;
	ok(@ns, "Nameservers found: " . scalar(@ns));
	
	foreach my $ns (@ns) {
	    ok($ns->handle, "NS handle is found: " . $ns->handle);
	    ok($ns->name->name, "NS name is found: " . $ns->name->name);
	    
	    push @handles , $ns->handle;
	    push @ns_names, $ns->name->name;
	}

    }
}

sub test_handles_onos {
    
    foreach my $q (sort @handles, @onos) {

	my $bo1 = bo_obj();
	my $bo2 = bo_obj();
	
	# test HEAD operation for existence of object
	my $htype = 'orgno';
	
	unless ($q =~ m/^\d{9}$/) {
	    $htype = $bo1->norid_handle_type($q);
	    
	    $bo1->lookup($q, 1, 0, 1);
	    if ($bo1->error) {
		ok(0, "HEAD: Error returned unexpectedly for $q, error / status: " .
		   $bo1->error . "/" . $bo1->status);
		next;
	    }
	    ok(1, "HEAD OK for q: " . encode('UTF-8', $q));
	    
	}
	
	# GET the handles
	$bo2->lookup($q, 0, 0, 0);
	if ($bo2->error ) {
	    if ($htype eq 'orgno') {
		ok(1, "GET: Error returned for htype: $htype, q: $q, error / status: " .
		   $bo2->error . "/" . $bo2->status);
	    } else {
		ok(0, "GET: Error returned for htype: $htype, q: $q, error / status: " .
		   $bo2->error . "/" . $bo2->status);
	    }
	    next;
	}
	
	ok(1, "GET  OK for q: " . encode('UTF-8', $q));
	
	my $res = $bo2->result;

	unless ($test_secret) {
	    unless ($res) {
		# search on orgno is not supported by lowest access layer
		ok(1, "GET: no lowest layer result returned for q: $q");
		next;
	    }
	}

	ok(1, "GET  Result is set for q: " . encode('UTF-8', $q));
	
	if (($htype eq 'organization' || $htype eq 'orgno') &&
	    $res->isa('Net::RDAP::SearchResult')) {
	    # entities after search
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
	    
	} else {
	    # entity after direct lookup
	    ok($res->handle, "Entity handle found for q: " . $res->handle);

	    unless ($res->isa('Net::RDAP::Object::Nameserver')) {
		my @cards = $res->vcard;
		if (scalar @cards > 0) {
		    foreach my $card (@cards) {
			test_vcard($htype, $card);
		    }
		}
	    }

	    my @ent = $res->entities;
	    if (@ent) {
		ok(@ent, "Entity->entities found: " . scalar(@ent));
		
		foreach my $en (@ent) {
		    my $ehtype = $bo1->norid_handle_type($en->handle);
		    
		    my @roles = $en->roles;
		    my $role = $roles[0];
		    
		    ok(@roles, "Entity roles are found: $role");
		    ok($en->handle, "Entity->entities->handle is found: " .
		       $en->handle . " ($role)");

		    my @cards = $en->vcard;
		    if (scalar @cards > 0) {
			foreach my $card (@cards) {
			    test_vcard($ehtype, $card);
			}
		    }	 
		}
	    }
	}
    }
}

sub bo_obj {
    my $query = shift || undef;
        
    return NOLookup::RDAP::RDAPLookup->new(
	{
	    service_url         => $service_url,
	    debug               => 0,
	    use_cache  	        => 1,
	    norid_header_secret => $test_secret,
	    norid_header_proxy  => $test_proxy,
	});
}

sub test_vcard {
    my ($htype, $card) = @_;

    my @addresses = @{$card->addresses};
    if (scalar(@addresses) > 0) {

	foreach my $address (@addresses) {
	    my @lines;
	    my $ix = 0;
	    foreach my $element (@{$address->{'address'}}) {
		my @val = ('ARRAY' eq ref($element) ? @{$element} : $element);
		
		foreach my $al (@val) {
		    # empty $al is the case when it is actually empty,
		    # or if no access to it is granted
		    next unless $al;
		    
		    if ($ix < 3) {
			if ($htype eq 'registrar') {
			    # 0: PoBox, 1: extended address, 2: street address 

			    # Address for registrar shall be accessible for all layers
			    ok($al , "$htype adddress line found: $al") if ($test_secret);
			    
			} else {
			    # Address for other entities shall be accessible
			    # by GDPR layer only
			    ok($al , "$htype adddress line found: $al") if ($test_secret);
			    ok(!$al, "$htype adddress line not found: $al") unless ($test_secret);
			}
			
		    } elsif ($ix == 3) {
			if ($htype eq 'registrar') {
			    ok($al, "$htype city line found: $al");
			} else {
			    # city: shall be accessible by GDPR layer only
			    ok($al, "$htype city line not found: $al")  if ($test_secret);
			    ok(!$al, "$htype city line not found: $al")  unless ($test_secret);
			}
			
		    } elsif ($ix == 4) {
			unless ($al) {
			    ok (1, "$htype empty region line is OK");
			    next;
			}
			if ($htype eq 'registrar') {
			    ok($al, "$htype region line found: $al");
			} else {
			    # region shall be accessible
			    # by GDPR layer only
			    ok($al, "$htype region line found: $al")  if ($test_secret);
			    ok(!$al, "$htype region line not found: $al") unless ($test_secret);
			}
			
		    } elsif ($ix == 5) {
			if ($htype eq 'registrar') {
			    ok($al, "$htype region line found: $al");
			} else {
			    # pcode / zip shall be accessible
			    # by GDPR layer only
			    ok($al, "$htype pcode/zip line found: $al") if ($test_secret);
			    ok($al, "$htype pcode/zip line found: $al") unless ($test_secret);
			}

		    } elsif ($ix == 6) {
			# country shall be accessible
			# by all layers
			ok($al, "$htype country line found: $al");
					    
		    } else {
			die "Should not end at this index $ix";
		    }
		}
		++$ix;
	    }
	}
    }
}
