#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;
use Net::UPnP::GW::Gateway;

my $obj = Net::UPnP::ControlPoint->new();

@dev_list = ();
while (@dev_list <= 0 || $retry_cnt > 5) {
#	@dev_list = $obj->search(st =>'urn:schemas-upnp-org:device:InternetGatewayDevice:1', mx => 10);
	@dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
	$retry_cnt++;
} 

$devNum= 0;
foreach $dev (@dev_list) {
	my $device_type = $dev->getdevicetype();
	if  ($device_type ne 'urn:schemas-upnp-org:device:InternetGatewayDevice:1') {
		next;
	}
	print "[$devNum] : " . $dev->getfriendlyname() . "\n";
	unless ($dev->getservicebyname('urn:schemas-upnp-org:service:WANIPConnection:1')) {
		next;
	}
	my $gwdev = Net::UPnP::GW::Gateway->new();
	$gwdev->setdevice($dev);
	print "\tExternalIPAddress = " . $gwdev->getexternalipaddress() . "\n";
	print "\tPortMappingNumberOfEntries = " . $gwdev->getportmappingnumberofentries() . "\n";
	print "\tTotalBytesRecived = " . $gwdev->gettotalbytesrecieved() . "\n";
	@port_mapping = $gwdev->getportmappingentry();
	$port_num = 0;
	foreach $port_entry (@port_mapping) {
		if ($port_entry) {
			$port_map_name = $port_entry->{'NewPortMappingDescription'};
			if (length($port_map_name) <= 0) {
				$port_map_name = "(No name)";
			}
			print "  [$port_num] : $port_map_name\n";
			foreach $name ( keys %{$port_entry} ) {
				print "    $name = $port_entry->{$name}\n";
			}
		}
		else {
			print "  [$port_num] : Unknown\n";
		}
		$port_num++;
	}
}


exit 0;

