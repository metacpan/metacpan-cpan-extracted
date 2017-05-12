#!/usr/bin/perl
#
# $Id: 10-route.t 3 2008-11-25 19:56:47Z gomor $
#

use Test;
BEGIN{ plan tests => 14 };

use Net::Libdnet;

# the tests may destroy your network configuration.
# just fake them for those people who did not explicitely require them.
if( !$ENV{REAL_TESTS} ){
	print STDERR "$0: faking dangerous tests\n";
	for( $i=0 ; $i<14 ; $i++ ){ ok(1); };
	exit 0;
}

# gateway to a.root-server.net
# configure dummy network
$gw = route_get("198.41.0.4");
$if = intf_get_dst($gw);
system("ifconfig $if->{name} add 172.16.255.1 netmask 255.255.255.0") && die "system";
arp_add("172.16.255.2", "de:ad:be:af:00:00");

ok(route_add(undef, "172.16.255.2"), undef);
ok(route_add("172.16.254.2", undef), undef);
ok(route_add("XXX", "172.16.255.2"), undef);
ok(route_add("172.16.254.2", "XXX"), undef);
ok(route_add("172.16.254.2", "172.16.255.2"), 1);

ok(route_get(undef), undef);
ok(route_get("XXX"), undef);
ok(route_get("172.16.254.2"), "172.16.255.2");
ok(route_get("172.16.253.2"), $gw);

ok(route_delete(undef), undef);
ok(route_delete("XXX"), undef);
ok(route_delete("172.16.254.3"), undef);
ok(route_delete("172.16.254.2"), 1);

ok(route_get("172.16.254.2"), $gw);

# remove dummy configuration
arp_delete("172.16.255.2");
system("ifconfig $if->{name} delete 172.16.255.1") && die "system";
