#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;
use Net::UPnP::GW::Gateway;

#------------------------------
# functions
#------------------------------

sub print_usages {
	print "usage : upnpgwtool command [args]\n";
	print " command  One of these\n";
	print "  search\n";
	print "  add <description> <tcp|udp> <external address> <external port> <internal address> <internal port>\n";
	print "  delete <tcp|udp> <external address> <external port>\n";
	print "  list <external address>\n";
}

sub check_command_line()
{
	if (@ARGV < 1) {
		return 0;
	}
	$command = $ARGV[0];
	if ($command eq "search") {
		return 1;
	} 
	elsif ($command eq "list") {
		if (2 <= @ARGV) {
			return 1;
		}
	} 
	elsif ($command eq "add") {
		if (7 <= @ARGV) {
			return 1;
		}
	}
	elsif ($command eq "delete") {
		if (4 <= @ARGV) {
			return 1;
		}
	}
	return 0;
}

#------------------------------
# main (pase command line)
#------------------------------

if (!check_command_line()) {
	print_usages();
	exit 1;
}

$ext_address = "";

if ($command eq "search") {
	$search_mode = 1;
} elsif ($command eq "list") {
	$ext_address = $ARGV[1];
} elsif ($command eq "add") {
	$ext_address = $ARGV[3];
} elsif ($command eq "delete") {
	$ext_address = $ARGV[2];
}

if (!$search_mode && length($ext_address) <= 0)  {
	print_usages();
	exit 1;
}

$obj = Net::UPnP::ControlPoint->new();

@dev_list = ();
while (@dev_list <= 0 || $retry_cnt > 5) {
	@dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
	$retry_cnt++;
} 

$gwdev_cnt = 0;
foreach $dev (@dev_list) {
	$device_type = $dev->getdevicetype();
	if  ($device_type ne 'urn:schemas-upnp-org:device:InternetGatewayDevice:1') {
		next;
	}
	unless ($dev->getservicebyname('urn:schemas-upnp-org:service:WANIPConnection:1')) {
		next;
	}
	$gwdev = Net::UPnP::GW::Gateway->new();
	$gwdev->setdevice($dev);
	$gwdev_ext_address = $gwdev->getexternalipaddress();
	if ($search_mode) {
		$gwdev_friendlyname = $dev->getfriendlyname();
		print "[$gwdev_cnt]:$gwdev_friendlyname ($gwdev_ext_address)\n";
		$gwdev_cnt++;
		next;
	}
	if ($ext_address ne $gwdev_ext_address) {
		undef $gwdev;
		next;
	}
	last;
}

if ($command eq "search") {
	exit 0;
}

unless ($gwdev) {
	print "The specified gateway device ($ext_address) is not found !!";
	exit 1;
}

$dev = $gwdev->getdevice();
print $dev->getfriendlyname() . "\n";

if ($command eq "list") {
	print " ExternalIPAddress = " . $gwdev->getexternalipaddress() . "\n";
	print " PortMappingNumberOfEntries = " . $gwdev->getportmappingnumberofentries() . "\n";
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
} elsif ($command eq "add") {
	print " $ARGV[1] $ext_address:$ARGV[4] => $ARGV[5]:$ARGV[6] ($ARGV[2])\n";
	$action_ret = $gwdev->addportmapping(
#		NewRemoteHost => $ARGV[3],
		NewExternalPort => $ARGV[4],
		NewProtocol => $ARGV[2],
		NewInternalPort => $ARGV[6],
		NewInternalClient => $ARGV[5],
		NewPortMappingDescription => $ARGV[1]);
	if ($action_ret) {
		print " New port mapping is added\n";
	}
	else {
		print " New port mapping is failed\n";
	}
} elsif ($command eq "delete") {
	print " $ARGV[2]:$ARGV[3] ($ARGV[1])\n";
	$action_ret = $gwdev->addportmapping(
#		NewRemoteHost => $ARGV[2],
		NewExternalPort => $ARGV[3],
		NewProtocol => $ARGV[1]);
	if ($action_ret) {
		print " New port mapping is deleted\n";
	}
	else {
		print " New port mapping is failed\n";
	}
}

exit 0;

