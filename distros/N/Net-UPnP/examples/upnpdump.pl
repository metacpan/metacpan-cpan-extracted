#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;

my $obj = Net::UPnP::ControlPoint->new();

@dev_list = $obj->search();

$devNum = 1;
foreach $dev (@dev_list) {
	print "[$devNum] : " . $dev->getfriendlyname() . "\n";
	print "\tdeviceType = " . $dev->getdevicetype() . "\n";
	print "\tlocation = " . $dev->getlocation() . "\n";
	print "\tudn = " . $dev->getudn() . "\n";
	@serviceList = $dev->getservicelist();
	if (@serviceList < 0) {
		next;
	}
	print "\tserviceList = " . @serviceList . "\n";
	$serviceNum = 1;
	foreach $service (@serviceList) {
		$service_type = $service->getservicetype();
		print "\t\t[$serviceNum] = " . $service_type . "\n";
		$serviceNum++;
	}
	$devNum++;
}

exit 0;

