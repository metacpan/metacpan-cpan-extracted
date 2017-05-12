#!/usr/bin/perl
#
# test functions required for 'dhcptool -a change_state'
#

use blib;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control '$STATUS';
use Net::DHCP::Control::Failover 'failover_statename';
use MIME::Base64;
use Test::More;
if (-e ".risky_tests") {
    plan tests => 6;
} else {
    plan skip_all => "By request";
    exit;
}
ok(1, "Partial credit for showing up");

my %auth = (key_name => $dhcpCONFIG{keyname},
	    key_type => $dhcpCONFIG{keytype},
	    key => $dhcpCONFIG{key},
	   );


my %host = (
#	    primary => 'flotsam.net.isc.upenn.edu',
	    primary => $dhcpCONFIG{'failover-host'}[0],
#	    secondary => 'jetsam.net.isc.upenn.edu',
	    secondary => $dhcpCONFIG{'failover-host'}[1],
	   );


my $h = Net::DHCP::Control::Failover::State->new(host => $host{primary}, %auth,
				   attrs => { name => $dhcpCONFIG{'failover-name'} },
				   );
ok($h, "handle created ($STATUS)");
ok($h->set("local-state", failover_statename("shutdown")), 
	"set state ($STATUS)");
is($h->get("local-state"), failover_statename("shutdown"), 
	"get state ($STATUS)");
ok($h->set("local-state", failover_statename("recover")), 
	"set state ($STATUS)");
is($h->get("local-state"), failover_statename("recover"), 
	"get state ($STATUS)");

			      
