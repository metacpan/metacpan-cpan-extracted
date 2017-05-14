#!/usr/local/bin/perl -w
use blib;
use strict;
use IO::File;
use IO::Dir;
use Geo::StormTracker::Main;

my ($main_obj,$error,$path,$result)=undef;
#Create a new main_obj 
$path='/home/newemd/emdjlc/hurricane/Storm-Tracker/database/';

($main_obj,$error)=Geo::StormTracker::Main->new($path);

die $error unless (defined $main_obj);

$result=$main_obj->_region_dir_exists('NT');

&_print_var("NT exists t/f :",$result);

$result=$main_obj->_region_dir_exists('NZ');

&_print_var("NZ exists t/f :",$result);
 
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

