#!/usr/bin/perl
#
# $Id: 03-arp.t 3 2008-11-25 19:56:47Z gomor $
#

use Test;
BEGIN{ plan tests => 12 };

use Net::Libdnet;

# the tests may destroy your network configuration.
# just fake them for those people who did not explicitely require them.
if( !$ENV{REAL_TESTS} ){
	print STDERR "$0: faking dangerous tests\n";
	for( $i=0 ; $i<12 ; $i++ ){ ok(1); };
	exit 0;
}

# gateway to a.root-server.net
# configure dummy network
$gw = route_get("198.41.0.4");
$if = intf_get_dst($gw);
system("ifconfig $if->{name} add 172.16.255.1 netmask 255.255.255.0") && die "system";

ok(arp_get("172.16.255.2"), undef);

ok(arp_add(undef, "de:ad:be:af:00:00"), undef);
ok(arp_add("172.16.255.2", undef), undef);
ok(arp_add(undef, "XXX"), undef);
ok(arp_add("XXX", undef), undef);
ok(arp_add("172.16.255.2", "de:ad:be:af:00:00"), 1);

ok(arp_get(undef), undef);
ok(arp_get("XXX"), undef);
ok(arp_get("172.16.255.2"), "de:ad:be:af:00:00");


ok(arp_delete(undef), undef);
ok(arp_delete("XXX"), undef);
ok(arp_delete("172.16.255.2"), 1);

# remove dummy configuration
system("ifconfig $if->{name} delete 172.16.255.1") && die "system";
