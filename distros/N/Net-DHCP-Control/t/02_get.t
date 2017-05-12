#!/usr/bin/perl
#
# test functions required for 'dhcptool -a status'
#

use blib;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control '$STATUS';
use Net::DHCP::Control::Failover 'failover_statename';
use MIME::Base64;
use Test::More tests => 7;
ok(1, "Partial credit for showing up");

my %auth = (key_name => $dhcpCONFIG{keyname},
	    key_type => $dhcpCONFIG{keytype},
	    key => $dhcpCONFIG{key},
	   );

for my $host (@{$dhcpCONFIG{'failover-hosts'}}) {
    my $fo;
    $fo = Net::DHCP::Control::Failover::State->new(host => $host, %auth,
				      attrs => { name => $dhcpCONFIG{"failover-name"} },
				      );
    ok($fo, "create object for host $host: $STATUS");
    my $state = $fo->get("local-state");
    ok(defined($state), "get state for host $host: $STATUS");
    $state = failover_statename($state);
    is($state, "normal", "$host in state $state");
}

