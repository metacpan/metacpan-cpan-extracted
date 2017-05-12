#!/usr/bin/perl
#
# $Id: 02-addr.t 3 2008-11-25 19:56:47Z gomor $
#

use Test;
BEGIN{ plan tests => 18 };

use Net::Libdnet;

# the tests may destroy your network configuration.
# just fake them for those people who did not explicitely require them.
if( !$ENV{REAL_TESTS} ){
	print STDERR "$0: faking dangerous tests\n";
	for( $i=0 ; $i<18 ; $i++ ){ ok(1); };
	exit 0;
}

ok(addr_cmp(undef, "1.2.3.4"), undef);
ok(addr_cmp("1.2.3.4", undef), undef);
ok(addr_cmp("XXX", "1.2.3.4"), undef);
ok(addr_cmp("1.2.3.4", "XXX"), undef);
ok(addr_cmp("1.2.3.5", "1.2.3.4"), 1);
ok(addr_cmp("1.2.3.4", "1.2.3.4"), 0);
ok(addr_cmp("1.2.3.4", "1.2.3.5"), -1);
ok(addr_cmp("00:00:DE:AD:BE:B0", "00:00:DE:AD:BE:AF"), 1);
ok(addr_cmp("00:00:DE:AD:BE:AF", "00:00:DE:AD:BE:AF"), 0);
ok(addr_cmp("00:00:DE:AD:BE:AF", "00:00:DE:AD:BE:B0"), -1);

ok(addr_bcast(undef), undef);
ok(addr_bcast("XXX"), undef);
ok(addr_bcast("1.2.3.4"), "1.2.3.4");
ok(addr_bcast("1.2.3.4/16"), "1.2.255.255");

ok(addr_net(undef), undef);
ok(addr_net("XXX"), undef);
ok(addr_net("1.2.3.4"), "1.2.3.4");
ok(addr_net("1.2.3.4/16"), "1.2.0.0");
