#!/usr/bin/perl
#
# test various error returns
#

use blib;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control '$STATUS';
use Net::DHCP::Control::Failover 'failover_statename';
use MIME::Base64;
use Test::More tests => 3;
ok(1, "Partial credit for showing up");

my %auth = (key_name => $dhcpCONFIG{keyname},
	    key_type => $dhcpCONFIG{keytype},
	    key => $dhcpCONFIG{key},
	   );


my %host = (
#	    primary => 'flotsam.net.isc.upenn.edu',
	    primary => $dhcpCONFIG{'failover-hosts'}[0],
#	    secondary => 'jetsam.net.isc.upenn.edu',
	    secondary => $dhcpCONFIG{'failover-hosts'}[1],
	   );


my $h = Net::DHCP::Control::Failover::State->new(host => $host{primary}, %auth,
				    attrs => { name =>  "BLARRRRGH.isc.net.upenn.edu" },
				    );
ok(! defined $h, "failed to create object with bad name");
is($STATUS, 'not found', "check status - set name not found");
