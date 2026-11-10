#!/usr/bin/env perl

use Net::UPnP::ControlPoint;
use Net::UPnP::AV::MediaServer;

Net::UPnP->SetDebug(1);

my $obj = Net::UPnP::ControlPoint->new();

if (0< @ARGV) {
	$target_server_name = $ARGV[0];
}
	
@dev_list = ();
while (@dev_list <= 0 || $retry_cnt > 5) {
	@dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
	$retry_cnt++;
} 

$devNum= 0;
foreach $dev (@dev_list) {
	my $device_type = $dev->getdevicetype();
	if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
		next;
	}
	my $friendlyname = $dev->getfriendlyname();
	if (0 < length($target_server_name)) {
		unless ($friendlyname =~ $target_server_name) {
			next;
		}
	}
	my $mediaServer = Net::UPnP::AV::MediaServer->new();
	$mediaServer->setdevice($dev);
	$mediaServer->walkcontent(callback => sub {});
	die $mediaServer->getwalkerror() if $mediaServer->getwalkerror();
}


exit 0;

