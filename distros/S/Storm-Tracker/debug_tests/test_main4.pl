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

#($success,$msg)=$main_obj->add_advisory_by_year_and_event($adv_obj,1999,1);
($success,$msg)=$main_obj->add_advisory_by_year_and_event($adv_obj,1999,1,1);

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


557 
WTNT31 KNHC 042051
TCPAT1
BULLETIN
TROPICAL DEPRESSION ELEVEN ADVISORY NUMBER   1
NATIONAL WEATHER SERVICE MIAMI FL
4 PM CDT MON OCT 04 1999
 
...TROPICAL DEPRESSION ELEVEN FORMS IN THE BAY OF CAMPECHE...HEAVY
RAINFALL THE PRIMARY THREAT...
 
AT 4 PM CDT...2100Z...THE CENTER OF THE TROPICAL DEPRESSION WAS
LOCATED NEAR LATITUDE 18.8 NORTH...LONGITUDE  93.9 WEST OR ABOUT 150
MILES...245 KM...EAST OF VERACRUZ MEXICO.
 
THE DEPRESSION IS CURRENTLY NEARLY STATIONARY...AND LITTLE MOTION IS
EXPECTED THROUGH TUESDAY.
 
MAXIMUM SUSTAINED WINDS ARE NEAR  35 MPH... 55 KM/HR...WITH HIGHER
GUSTS.  LITTLE CHANGE IN STRENGTH IS FORECAST DURING THE NEXT
24 HOURS.
 
THE LOWEST MINIMUM CENTRAL PRESSURE REPORTED BY AN AIR FORCE RESERVE
HURRICANE HUNTER AIRCRAFT IS 1003 MB...29.62 INCHES.
 
RAINFALL AMOUNTS OF 10 TO 15 INCHES...WITH LOCALLY HIGHER AMOUNTS IN
MOUNTAINOUS AREAS...ARE POSSIBLE OVER PORTIONS OF EASTERN AND
SOUTHEASTERN MEXICO. THESE RAINFALLS COULD CAUSE FLASH FLOODS AND
MUDSLIDES.
 
REPEATING THE 4 PM CDT POSITION...18.8 N... 93.9 W.  MOVEMENT...
STATIONARY.  MAXIMUM SUSTAINED WINDS...35 MPH.  MINIMUM CENTRAL
PRESSURE...1003 MB.
 
THE NEXT ADVISORY WILL BE ISSUED BY THE NATIONAL HURRICANE CENTER AT
10 PM CDT.
 
BEVEN
 
STRIKE PROBABILITIES ASSOCIATED WITH THIS ADVISORY NUMBER CAN BE
FOUND UNDER AFOS HEADER MIASPFAT1 AND WMO HEADER WTNT71 KNHC.
 
