#!/usr/bin/env perl

#
# This script demonstrates the Net::CDP::Manager module. It should be
# run as root.
#

use strict;
use warnings;

# This script can be run directly from the source directory
use lib 'blib/arch';
use lib 'blib/lib';

use Net::CDP::Manager;
use Net::CDP::Packet qw(:caps);

sub pretty { defined $_[0] ? @_ : '(unspecified)' }
sub duplex { defined $_[0] ? ($_[0] ? 'full' : 'half') : '(unspecified)' }
sub trust { defined $_[0] ? ($_[0] ? 'trusted' : 'untrusted') : '(unspecified)' }
sub voice_vlan { defined $_[0] ? "Appliance $_[1], VLAN $_[0]" : '(unspecified)' }
sub power_consumption { defined $_[0] ? "$_[0] mW" : '(unspecified)' }
sub hexify { join ' ', map { map { sprintf '0x%02x', ord } split // } @_ }
sub caps {
	my $caps = shift;
	my %map = (
		CDP_CAP_ROUTER()             => 'Router',
		CDP_CAP_TRANSPARENT_BRIDGE() => 'Transparent bridge',
		CDP_CAP_SOURCE_BRIDGE()      => 'Source route bridge',
		CDP_CAP_SWITCH()             => 'Switch',
		CDP_CAP_HOST()               => 'Host',
		CDP_CAP_IGMP()               => 'IGMP capable',
		CDP_CAP_REPEATER()           => 'Repeater',
	);
	join ', ', @map{sort grep { $caps & $_ } keys %map}
}

sub callback {
	my ($packet, $port) = @_;
	
	# Print out the packet
	print "Received on port $port:\n";
	print '  Version: ', pretty($packet->version), "\n";
	print '  TTL: ', pretty($packet->ttl), "\n";
	print '  Checksum: ', pretty($packet->checksum), "\n";
	print '  Device ID: ', pretty($packet->device), "\n";
	if ($packet->addresses) {
		print "  Addresses:\n";
		foreach ($packet->addresses) {
			print '    Protocol: ', pretty($_->protocol), "\n";
			print '    Address: ', pretty($_->address), "\n";
		}
	} else {
		print "  Addresses: (unspecified)\n";
	}
	print '  Port ID: ', pretty($packet->port), "\n";
	print '  Capabilities: ', caps($packet->capabilities), "\n";
	print '  IOS Version: ', pretty($packet->ios_version), "\n"; 
	print '  Platform: ', pretty($packet->platform), "\n";
	if ($packet->ip_prefixes) {
		print "  IP Prefixes:\n";
		foreach ($packet->ip_prefixes) {
			print '    Network: ', hexify($_->network), "\n";
			print '    Length: ', pretty($_->length), "\n";
		}
	} else {
		print "  IP Prefixes: (unspecified)\n";
	}
	print '  VTP Management Domain: ', pretty($packet->vtp_management_domain), "\n";
	print '  Native VLAN: ', pretty($packet->native_vlan), "\n";
	print '  Duplex: ', duplex($packet->duplex), "\n";
	print '  Voice VLAN: ', voice_vlan($packet->voice_vlan), "\n";
	print '  Voice VLAN (query): ', voice_vlan($packet->voice_vlan_query), "\n";
	print '  Power Consumption: ', power_consumption($packet->power_consumption), "\n";
	print '  MTU: ', pretty($packet->mtu), "\n";
	print '  Extended Trust: ', trust($packet->trusted), "\n";
	print '  COS for Untrusted ports: ', pretty($packet->untrusted_cos), "\n";
	if ($packet->management_addresses) {
		print "  Management Addresses:\n";
		foreach ($packet->management_addresses) {
			print '    Protocol: ', pretty($_->protocol), "\n";
			print '    Address: ', pretty($_->address), "\n";
		}
	} else {
		print "  Management Addresses: (unspecified)\n";
	}
	print "\n";
}

while (1) {
	# Update the port list
	cdp_manage_soft cdp_ports;
	
	# Send CDP packets
	cdp_send;
	
	print 'Currently managing: ', join(', ', sort &cdp_managed), "\n";
	print 'Currently active:   ', join(', ', sort &cdp_active), "\n\n";
	
	# Wait for CDP packets for 60 seconds
	cdp_loop \&callback, 60;
}
