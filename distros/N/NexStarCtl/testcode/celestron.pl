#!/usr/bin/perl
use strict;
use lib '../lib';
use NexStarCtl;


# print "(0,".TC_AXIS_RA_AZM.",".TC_DIR_POSITIVE.",3)\n";

#enforce_vendor_protocol(VNDR_CELESTRON);

#print get_mcdel_name(1)."\n";
#print get_model_name(2)."\n";
#print get_model_name(22)."\n"; 

my $port = open_telescope_port("/dev/ttyUSB0"); 
#my $port = open_telescope_port("/tmp/cam");

if (!defined $port) {
	print "Can not open communication port.\n";
	exit;
}

enforce_vendor_protocol(VNDR_CELESTRON);
enforce_protocol_version($port,0x040001);

print "tc_get_orientation = ".tc_get_orientation($port)."    err:".$NexStarCtl::error."\n";
print "tc_slew_fixed = ".tc_slew_fixed($port,1,1)."    err:".$NexStarCtl::error."\n";

exit(0); 


print "MOUNT = ".tc_get_model($port)."\n";

print "VERSION = ".tc_get_version($port)."\n";

#enforce_protocol_version($port,VER_1_2);
#enforce_vendor_protocol(VNDR_CELESTRON);

print "Align = ".tc_check_align($port)."\n";

print "orientation = ".tc_get_orientation($port)."\n";
print "Error=".$NexStarCtl::error."\n";

#my $response = tc_pass_through_cmd($port, 1, 178, 4, 0, 0, 0, 2);
#print "GPS is present:". ord($response). "\n";

#print "SET LOC= ".tc_set_location($port,  dms2d("22:58:09"), dms2d("44:05:31"))."\n";

#my ($lon,$lat) = tc_get_location($port);
#print "LON=$lon LAT=$lat\n";

#my ($lon,$lat) = tc_get_location_str($port);
#print "LONs=$lon LATs=$lat\n";

#my $tm=time();
#print "$tm\n";
#print "SETTIME= ".tc_set_time($port,$tm,2,0)."\n";

#my ($date,$time,$tz,$dst) = tc_get_time_str($port);

#print "$date, $time, $tz, $dst\n";


my $echo;
for (my $i=1; $i<256; $i++) {
	$echo = ord(tc_echo($port, chr($i)));

	#sleep 1;
	if ($echo != $i) {
		print "ERROR: Sent $i received $echo\n";
	} else {
		print "OK: Sent $i received $echo\n";
	}
	
}

#print "GOTO = ".tc_goto_rade_p($port,11*15,21)."\n";

#sleep(2);
#print "GOTO Cancel = ".tc_goto_cancel($port)."\n";

#print "TRACKING SET= ".tc_set_tracking_mode($port,0)."\n";
#print "TRACKING = ".tc_get_tracking_mode($port)."\n";

#tc_slew_variable($port,TC_AXIS_RA_AZM,TC_DIR_POSITIVE,15.25); 
#sleep(2);
#tc_slew_variable($port,TC_AXIS_DE_ALT,TC_DIR_POSITIVE,1);
#sleep(2);
#tc_slew_fixed($port,TC_AXIS_RA_AZM,TC_DIR_NEGATIVE,0);
#sleep(2);
#tc_slew_fixed($port,TC_AXIS_DE_ALT,TC_DIR_POSITIVE,0);

#print "TRACKING = ".tc_get_tracking_mode($port)."\n";

#print "TRACKING SET= ".tc_set_tracking_mode($port,2)."\n";
#print "TRACKING = ".tc_get_tracking_mode($port)."\n";


#while (tc_goto_in_progress($port)) {
#	sleep(1);
#	print ".";
#}
#print "OK\n";

#print "SYNC = ".tc_sync_rade_p($port,0,0)."\n";

#my ($rap,$decp) = tc_get_rade_p($port);
#my ($ra,$dec) = tc_get_rade($port);


#my ($azp,$altp) = tc_get_azalt_p($port);
#my ($az,$alt) = tc_get_azalt($port);

#print "Set RA(+) Backlash: " . tc_set_backlash($port,TC_AXIS_RA_AZM,TC_DIR_POSITIVE,0) . "\n";
#print "Set RA(-) Backlash: " . tc_set_backlash($port,TC_AXIS_RA_AZM,TC_DIR_NEGATIVE,0) . "\n";
#print "Set DE(+) Backlash: " . tc_set_backlash($port,TC_AXIS_DE_ALT,TC_DIR_POSITIVE,0) . "\n";
#print "Set DE(-) Backlash: " . tc_set_backlash($port,TC_AXIS_DE_ALT,TC_DIR_NEGATIVE,0) . "\n";
#print "Get RA(+) Backlash: " . tc_get_backlash($port,TC_AXIS_RA_AZM,TC_DIR_POSITIVE) . "\n";
#print "Get RA(-) Backlash: " . tc_get_backlash($port,TC_AXIS_RA_AZM,TC_DIR_NEGATIVE) . "\n";
#print "Get DE(+) Backlash: " . tc_get_backlash($port,TC_AXIS_DE_ALT,TC_DIR_POSITIVE) . "\n";
#print "Get DE(-) Backlash: " . tc_get_backlash($port,TC_AXIS_DE_ALT,TC_DIR_NEGATIVE) . "\n";

print "Get RA autoguide rate: " . tc_get_autoguide_rate($port,TC_AXIS_RA_AZM) . "\n";
print "Get DE autoguide rate: " . tc_get_autoguide_rate($port,TC_AXIS_DE_ALT) . "\n";

for (my $rate = -1; $rate < 102; $rate++) {
	my $res = tc_set_autoguide_rate($port,TC_AXIS_RA_AZM,$rate);
	if ($res != 1) {print "set faied\n";}
	print "Get RA autoguide rate: $rate => " . tc_get_autoguide_rate($port,TC_AXIS_RA_AZM) . "\n";
	#print "\n";
	#print "Set DE autoguide rate: $rate => " . tc_set_autoguide_rate($port,TC_AXIS_DE_ALT,22) . "\n";
	#print "Get DE autoguide rate: " . tc_get_autoguide_rate($port,TC_AXIS_DE_ALT) . "\n";
}

close_telescope_port($port);


#my $ra1=hms2d("22:33:32");
#my $dec1=dms2d("-44:22:11");

#my $ra1=222.333;
#my $dec1=-88.9999;

#my $nex="1000,1000";
#my ($ra1,$dec1)=nex2dd($nex);

#my ($ra2,$dec2)=precess($ra1,$dec1,2013.6,2013);

#my $nex=dd2nex($ra1,$dec1);
#print "NEX1=$nex\n";

#my $nex2=dd2nex($ra2,$dec2);
#print "NEX2=$nex2\n";

#my ($ra,$dec)=nex2dd($nex);
#print "RA=$ra\nDE=$dec\n";

#my $ras=d2hms($ra);
#my $decs=d2dms($dec);

#my $rasp=d2hms($rap);
#my $decsp=d2dms($decp);


#print "RA=$ras\nDEC=$decs\n";
#print "RAp=$rasp\nDECp=$decsp\n";

#print "AZ=$az\nALT=$alt\n";
#print "AZp=$azp\nALTp=$altp\n";
