#!/usr/bin/perl
#
# $Id: 07-intf.t 3 2008-11-25 19:56:47Z gomor $
#

use Test;
BEGIN{ plan tests => 9 };

use Net::Libdnet;

# the tests may destroy your network configuration.
# just fake them for those people who did not explicitely require them.
if( !$ENV{REAL_TESTS} ){
	print STDERR "$0: faking dangerous tests\n";
	for( $i=0 ; $i<9 ; $i++ ){ ok(1); };
	exit 0;
}

# gateway to a.root-server.net
$gw = route_get("198.41.0.4");

ok(intf_get_dst(undef)->{name}, undef);
ok(intf_get_dst("XXX")->{name}, undef);
$if = intf_get_dst($gw);
$name = $if->{name};
$ip = $if->{addr}; $ip =~ s,/.*$,,;
ok(defined($name), 1);

ok(intf_get(undef)->{name}, undef);
ok(intf_get("XXX")->{name}, undef);
ok(intf_get($name)->{name}, $name);

ok(intf_get_src(undef)->{name}, undef);
ok(intf_get_src("XXX")->{name}, undef);
ok(intf_get_src($ip)->{name}, $name);

