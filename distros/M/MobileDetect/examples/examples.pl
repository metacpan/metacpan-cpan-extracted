#!/usr/bin/perl

use MobileDetect;

my $obj 	= MobileDetect->new(); 
my $check 	= "Mozilla/5.0 (Linux; U; Android 4.1.2; nl-nl; SAMSUNG GT-I8190/I8190XXAME1 Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"; # Samsung Galaxy S3 Mini

print "is_phone: 			".$obj->is_phone($check); print "\n";
print "detect_phone: 		".$obj->detect_phone($check); print "\n";
print "is_tablet: 			".$obj->is_tablet($check);print "\n";
print "detect_tablet: 		".$obj->detect_tablet($check);print "\n";

print "is_mobile_os: 		".$obj->is_mobile_os($check);print "\n";
print "detect_mobile_os:	".$obj->detect_mobile_os($check);print "\n";
print "is_mobile_ua: 		".$obj->is_mobile_ua($check);print "\n";
print "detect_mobile_ua:	".$obj->detect_mobile_ua($check)."\n";

exit;