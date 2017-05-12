#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;
use Net::UPnP::AV::MediaServer;

my $obj = Net::UPnP::ControlPoint->new();

if (0< @ARGV) {
	$target_server_name = $ARGV[0];
}
	
@dev_list = ();
while (@dev_list <= 0 || $retry_cnt > 5) {
#	@dev_list = $obj->search(st =>'urn:schemas-upnp-org:device:MediaServer:1', mx => 10);
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
	print "[$devNum] : " . $friendlyname . "\n";
	unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
		next;
	}
	my $mediaServer = Net::UPnP::AV::MediaServer->new();
	$mediaServer->setdevice($dev);
	
	print "\tSystemUpdateID = " . $mediaServer->getsystemupdateid() . "\n";
	
	my @content_list = $mediaServer->getcontentlist(ObjectID => 0);
	foreach my $content (@content_list) {
		print_content($mediaServer, $content, 1);
	}

	$devNum++;
}

sub print_content {
	my ($mediaServer, $content, $indent) = @_;
	my $id = $content->getid();
	my $title = $content->gettitle();

	for ($n=0; $n<$indent; $n++) {
		print "\t";
	}
	print "$id = $title";
	if ($content->isitem()) {
		print " (" . $content->geturl();
		if (length($content->getdate())) {
			print " - " . $content->getdate();
		}
		print " - " . $content->getcontenttype() . ")";
	}
	print "\n";

	unless ($content->iscontainer()) {
		return;
	}

	my @child_content_list = $mediaServer->getcontentlist(ObjectID => $id );
	
	if (@child_content_list <= 0) {
		return;
	}
	
	$indent++;
	foreach my $child_content (@child_content_list) {
		print_content($mediaServer, $child_content, $indent);
	}
}

exit 0;

