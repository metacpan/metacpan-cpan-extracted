#! /usr/bin/perl -w
#*********************************************************************
#*** t/41TLS.t
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 41TLS.t,v 1.3 2003/09/25 17:23:52 mws Exp $
#*********************************************************************
use strict;
use Test;
use Data::Dumper;

use ResourcePool;
use Net::LDAP qw(LDAP_SUCCESS); 
use ResourcePool::Factory::Net::LDAP; 

BEGIN { plan tests => 8; }

sub ldap($$$@) {
	my ($host, $ldapok, $tls, $no) = @_;
	$no = 1 unless defined $no;
	my $i;

	if (! defined $host) {
		for ($i = 0; $i < $no; $i++) {
			skip("skip no LDAP server configured for testing", 0);
		}
		return 0;
	} elsif (! $ldapok) {
		for ($i = 0; $i < $no; $i++) {
			skip("skip the supplied LDAP configuration seems to be faulty", 0);
		}
		return 0;
	} elsif (! $tls) {
		for ($i = 0; $i < $no; $i++) {
			skip("skip the supplied LDAP configuration does not support TLS", 0);
		}
		return 0;
	}
	return 1;	
}

my ($host, $binddn, $pass, $tls, @bindparam);
$host   = $ENV{RESOURCEPOOL_NET_LDAP_HOST};
$binddn = $ENV{RESOURCEPOOL_NET_LDAP_BINDDN};
$pass   = $ENV{RESOURCEPOOL_NET_LDAP_PASS};
$tls    = $ENV{RESOURCEPOOL_NET_LDAP_TLS};
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
	my $rc = $ldaph->bind(@bindparam);
	$ldapok = $rc->code == LDAP_SUCCESS;
	ok($ldapok);
} else {
	skip("skip no LDAP server configured for testing", 0);
}

my ($f2, $r2);
if (ldap($host, $ldapok, 1)) {
	$f2 = ResourcePool::Factory::Net::LDAP->new($host, version => 2);
	$f2->start_tls();
	$r2 = $f2->create_resource();
	# should fail, version 2 doesnt support start_tls
	ok (!defined $r2);
}

if (ldap($host, $ldapok, $tls, 2)) {
	$f2 = ResourcePool::Factory::Net::LDAP->new($host, version => 3);
	$f2->start_tls();
	$r2 = $f2->create_resource();
	# should not fail, version 3 does support start_tls
	ok (defined $r2);
	my $c = $r2->get_plain_resource()->cipher();
	ok (defined $c && $c ne "");
}

if (ldap($host, $ldapok, $tls, 2)) {
	my ($f2, $r2);
	$f2 = ResourcePool::Factory::Net::LDAP->new($host, version=>3);
	$f2->bind(@bindparam);
	$f2->start_tls();
	$r2 = $f2->create_resource();
	ok (defined $r2);
	my $c = $r2->get_plain_resource()->cipher();
	ok (defined $c && $c ne "");
}

my @wrongbindparam = @bindparam;
$wrongbindparam[0] = "cn=nobody, dc=fatalmind, dc=com";

if (ldap($host, $ldapok, $tls)) {
	my ($f, $r);
	$f = ResourcePool::Factory::Net::LDAP->new($host);
	$f->start_tls();
	$f->bind(@wrongbindparam);
	$r = $f->create_resource();
	ok (!defined $r);
}
