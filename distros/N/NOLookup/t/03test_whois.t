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

	print "whois test $q: ", $wh->errno, "\n";
	
	if ($wh->errno == $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED) {
	    ok(1, "Quota exceeded");

	} elsif ($wh->errno == $WHOIS_LOOKUP_ERR_NO_ACCESS) {
	    ok(1, "No access");
	    
	} else {
	    BAIL_OUT("Some error, should not happen, errcode is: " . $wh->errno);	    
	}
	
    } else {
    
	ok($wh, "Whois1 object returned  for q: " . encode('UTF-8', $q));
	ok($do, "Domain1 object returned");
	ok($ho, "Holder1 object returned");
	
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
	    push @tc_handles , split("\n", $do->tech_c_handle);
	    push @ns_handles , split("\n", $do->name_server_handle);
	}
    }
}

foreach my $q (sort @ho_handles, @do_handles, @reg_handles, @tc_handles, @ns_handles, @onos) {
    my ($wh, $do, $ho) = NOLookup::Whois::WhoisLookup->new($q, $SERVER);

    if ($wh->errno) {
	if ($wh->errno == $WHOIS_LOOKUP_ERR_QUOTA_EXCEEDED) {
	    ok(1, "Quota exceeded");

	} elsif ($wh->errno == $WHOIS_LOOKUP_ERR_NO_ACCESS) {
	    ok(1, "No access");

	} else {
	    BAIL_OUT("Some error, should not happen, errcode is: " . $wh->errno);	    
	}
		
    } else {
	ok($wh, "Whois2 object returned for q: $q");
    }
}


