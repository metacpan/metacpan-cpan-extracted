#! /usr/bin/perl -w
#*********************************************************************
#*** t/40LDAP.t
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 40LDAP.t,v 1.6 2003/09/25 17:23:52 mws Exp $
#*********************************************************************
use strict;
use Test;
use Data::Dumper;

use ResourcePool;
use Net::LDAP qw(LDAP_SUCCESS); 
use ResourcePool::Factory::Net::LDAP; 

BEGIN { plan tests => 13; }

sub ldap($$) {
	my ($host, $ldapok) = @_;
	if (! defined $host) {
		skip("skip no LDAP server configured for testing", 0);
		return 0;
	} elsif (! $ldapok) {
		skip("skip the supplied LDAP configuration seems to be faulty", 0);
		return 0;
	}
	return 1;	
}

my ($host, $binddn, $pass, @bindparam);
$host   = $ENV{RESOURCEPOOL_NET_LDAP_HOST};
$binddn = $ENV{RESOURCEPOOL_NET_LDAP_BINDDN};
$pass   = $ENV{RESOURCEPOOL_NET_LDAP_PASS};
if (defined $binddn) {
	@bindparam = ($binddn, password => $pass);
}

# there shall be silence
$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory::Net::LDAP->new("hostname1");
my $pr1 = $f1->create_resource();
ok(! defined $pr1);
my $ldapok = 0;

if (defined $host) {
	my $ldaph = Net::LDAP->new($host);
	#my $rc = $ldaph->bind($binddn, password => $pass);
	my $rc = $ldaph->bind(@bindparam);
	$ldapok = $rc->code == LDAP_SUCCESS;
	ok($ldapok);
} else {
	skip("skip no LDAP server configured for testing", 0);
}

my ($f2, $r2);
if (ldap($host, $ldapok)) {
	$f2 = ResourcePool::Factory::Net::LDAP->new($host, [@bindparam]);
	$r2 = $f2->create_resource();
	ok (defined $r2);
}

if (ldap($host, $ldapok)) {
	my ($f2, $r2);
	$f2 = ResourcePool::Factory::Net::LDAP->new($host);
	$f2->bind(@bindparam);
	$r2 = $f2->create_resource();
	ok (defined $r2);
}

my @wrongbindparam = @bindparam;
$wrongbindparam[0] = "cn=nobody, dc=fatalmind, dc=com";

if (ldap($host, $ldapok)) {
	my ($f, $r);
	$f = ResourcePool::Factory::Net::LDAP->new($host, [@wrongbindparam]);
	$r = $f->create_resource();
	ok (!defined $r);
}

if (ldap($host, $ldapok)) {
	my ($f, $r);
	$f = ResourcePool::Factory::Net::LDAP->new($host);
	$f->bind(@wrongbindparam);
	$r = $f->create_resource();
	ok (!defined $r);
}

if (ldap($host, $ldapok)) {
	if (defined $r2) {
		ok($r2->postcheck);
	} else {
		skip("skip follow up",0);
	}
} 

if (ldap($host, $ldapok)) {
	if (defined $r2) {
		ok($r2->precheck);
		$r2->close();
	} else {
		skip("skip follow up",0);
	}
}

my $pool;
my $ldaph;
if (ldap($host, $ldapok)) {
	$pool = ResourcePool->new($f2);
	$ldaph = $pool->get();	
	ok($ldaph);
} 

if (ldap($host, $ldapok)) {
	ok($pool->free($ldaph));
} 

if (ldap($host, $ldapok)) {
	ok(! $pool->free($ldaph));
} 

my ($f3, $r3);
if (ldap($host, $ldapok)) {
	$f3 = ResourcePool::Factory::Net::LDAP->new($host, [@bindparam]);
	$r3 = $f3->create_resource();
	ok (defined $r3);
} 

my ($f4, $r4);
if (ldap($host, $ldapok)) {
	my $dn = shift(@bindparam);
	my @oldbindparam = (dn => $dn, @bindparam);
	$f4 = ResourcePool::Factory::Net::LDAP->new($host, [@oldbindparam]);
	$r4 = $f4->create_resource();
	ok (defined $r4);
} 
