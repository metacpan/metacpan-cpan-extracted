#!/usr/local/bin/perl -w
use blib;
use strict;
use Geo::StormTracker::Main;

my ($advisory,$parser,$adv_obj,$main_obj, $data_obj, $msg, $success)=undef;
my ($region, $region_HR)=undef;


($main_obj,$msg)=Geo::StormTracker::Main->new('/home/newemd/emdjlc/hurricane/Storm-Tracker/database/');

die $msg unless (defined $main_obj);

($region_HR,$msg)=$main_obj->all_active_storms_by_region('NT');
#($region_HR,$msg)=$main_obj->all_active_storms_by_region();

foreach $region (keys %{$region_HR}){
	print "\nregion is $region\n";
	foreach $data_obj (@{$region_HR->{$region}}){
		&_print_var("path is  :",$data_obj->get_path());
	}#foreach
}#foreach

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
