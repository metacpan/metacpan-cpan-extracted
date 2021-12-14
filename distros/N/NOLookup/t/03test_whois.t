#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Encode;

use Data::Dumper;
$Data::Dumper::Indent=1;

use NOLookup::Whois::WhoisLookup qw /
    $WHOIS_LOOKUP_ERR_NO_CONN
    $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED 
    $WHOIS_LOOKUP_ERR_NO_ACCESS
    $WHOIS_LOOKUP_ERR_REFERRAL_DENIED
    $WHOIS_LOOKUP_ERR_OTHER
    $WHOIS_LOOKUP_ERR_NO_MATCH
    /;

require_ok('NOLookup::Whois::WhoisLookup');

my $SERVER = $ENV{WHOIS_SERVICE} || "registrarwhois.norid.no";

my @ho_handles;
my @do_handles;
my @reg_handles;
my @onos;
my @tc_handles;
my @ns_handles;


my @doms = (
    qw/
    norid.no
    øl.no
    /

    );

foreach my $q (sort @doms) {
    
    my ($wh, $do, $ho) = NOLookup::Whois::WhoisLookup->new($q, $SERVER);

    if ($wh->errno) {
	if ($wh->errno == $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED) {
	    ok(1, "Quota exceeded");
	}
	if ($wh->errno == $WHOIS_LOOKUP_ERR_NO_ACCESS) {
	    ok(1, "No access");
	}	
	
    } else {
    
	ok($wh, "Whois object returned  for q: " . encode('UTF-8', $q));
	ok($do, "Domain object returned");
	ok($ho, "Holder object returned");
	
	#print "do: ", Dumper $do;
	#print "ho: ", Dumper $ho;
	
	push @reg_handles, $do->registrar_handle if ($do);
	
	if ($ho) {
	    push @reg_handles, $ho->registrar_handle;
	    push @ho_handles , $ho->norid_handle;
	    push @onos       , $ho->id_number;
	}
	if ($do) {
	    push @reg_handles, $do->registrar_handle;
	    push @do_handles , $do->norid_handle;
	    
	    push @tc_handles , $do->tech_c_handle;
	    push @ns_handles , split "\n", $do->name_server_handle;
	}
    }
}

foreach my $q (sort @ho_handles, @do_handles, @reg_handles, @tc_handles, @ns_handles, @onos) {
    my ($wh, $do, $ho) = NOLookup::Whois::WhoisLookup->new($q, $SERVER);

    if ($wh->errno) {
	if ($wh->errno == $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED) {
	    ok(1, "Quota exceeded");
	}
	if ($wh->errno == $WHOIS_LOOKUP_ERR_NO_ACCESS) {
	    ok(1, "No access");
	}
	
    } else {
	ok($wh, "Whois object returned for q: $q");
    }
}


=head2 cut
ok($das->delegated, "Domain $q is already registered");
ok(!$das->available, "Domain $q is not available");
ok(!$das->prohibited, "Domain $q is not prohibited");
ok(!$das->invalid, "Domain $q is not invalid");
is($das->raw_text, "$q is delegated (0)", "Raw text was returned and correct");

# Prohibited
$q = "sex.no";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok(!$das->errno, "Error was not returned on $q");
ok(!$das->delegated, "Domain $q is not registered");
ok(!$das->available, "Domain $q is not available");
ok($das->prohibited, "Domain $q is prohibited");
ok(!$das->invalid, "Domain $q is not invalid");
is($das->raw_text, "This domain can currently not be registered (0)", "$q: Raw text was returned and correct");

# invalid zone/name
$q = "domain.mil.no";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok(!$das->errno, "Error was not returned on $q");
ok(!$das->delegated, "Domain $q is not registered");
ok(!$das->available, "Domain $q is not available");
ok(!$das->prohibited, "Domain $q is not prohibited");
ok($das->invalid, "Domain $q is invalid");
ok($das->raw_text, "Raw text was returned");

# Invalid request "ERROR - Invalid request"
$q = "norid.com";
$das = NOLookup::DAS::DASLookup->new($q, $SERVER);
ok($das, "DAS object returned");
ok($das->errno, "Error was returned on $q, errno: " . $das->errno);
ok($das->raw_text, "Raw text was returned");
is($das->raw_text, "ERROR - Invalid request (0)", "Raw text was returned and correct");
=cut

#print $das->errno, "\n";
#print $das->raw_text, "\n";
