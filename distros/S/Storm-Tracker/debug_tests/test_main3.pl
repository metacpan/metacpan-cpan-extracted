#!/usr/local/bin/perl -w
use blib;
use strict;
use Geo::StormTracker::Parser;
use Geo::StormTracker::Main;

my ($advisory,$parser,$adv_obj,$main_obj, $msg, $success)=undef;
my @lines=();

@lines=<DATA>;
$advisory=join('',@lines);

$parser=Geo::StormTracker::Parser->new();
$adv_obj=$parser->read_data($advisory);

($main_obj,$msg)=Geo::StormTracker::Main->new('/home/newemd/emdjlc/hurricane/Storm-Tracker/database/');

die $msg unless (defined $main_obj);

($success,$msg)=$main_obj->add_advisory_by_year_and_event($adv_obj,1999,15);

&_print_var("success :",$success);

&_print_var("msg :",$msg);
 
exit;
#-------------------------------------------------------
sub _print_var {
        my $des=shift;
        my $result=shift;
 
        print $des;
 
        if (defined($result)){
                print " result is: ",$result,"\n";
        }
        else {
                print " result is: undefined\n";
        }
}#_print_var
#--------------------------------------------------------

__DATA__
 
  
 
797 
WTNT32 KNHC 062050
TCPAT2
BULLETIN
TROPICAL DEPRESSION TWELVE ADVISORY NUMBER   4
NATIONAL WEATHER SERVICE MIAMI FL
5 PM AST WED OCT 06 1999
 
...TROPICAL DEPRESSION TWELVE SLOWS TEMPORARILY...
 
AT 5 PM AST...2100Z...THE CENTER OF THE TROPICAL DEPRESSION
WAS LOCATED NEAR LATITUDE 15.5 NORTH...LONGITUDE  46.1 WEST
OR ABOUT 1025 MILES...1650 KM...EAST OF THE LESSER ANTILLES.
 
THE DEPRESSION MOVED LITTLE EARLIER TODAY...BUT IS NOW MOVING WEST-
NORTHWEST MOTION NEAR  5 MPH...7 KM/HR. THIS MOTION IS EXPECTED TO
CONTINUE FOR THE NEXT 24 HOURS.
 
MAXIMUM SUSTAINED WINDS ARE NEAR  35 MPH... 55 KM/HR...WITH HIGHER
GUSTS.  UPPER LEVEL WINDS HAVE BECOME A LITTLE LESS FAVORABLE
TODAY...AND LITTLE CHANGE IN STRENGTH IS FORECAST DURING THE NEXT
24 HOURS.
 
ESTIMATED MINIMUM CENTRAL PRESSURE IS 1007 MB...29.74 INCHES.
 
#REPEATING THE 5 PM AST POSITION ...15.5 N... 46.1 W.  MOVEMENT
TOWARD...WEST-NORTHWEST 5 MPH.  MAXIMUM SUSTAINED WINDS... 35 MPH. 
MINIMUM CENTRAL PRESSURE ... 1007 MB.
 
THE NEXT ADVISORY WILL BE ISSUED BY THE NATIONAL HURRICANE CENTER AT
11 PM AST.
 
BEVEN
 
STRIKE PROBABILITIES ASSOCIATED WITH THIS ADVISORY NUMBER CAN BE
FOUND UNDER AFOS HEADER MIASPFAT2 AND WMO HEADER WTNT72 KNHC.
 
 
 

