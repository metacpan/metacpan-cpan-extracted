#!/usr/local/bin/perl -w 
use blib;
use strict;
use Geo::StormTracker::Parser;
use Geo::StormTracker::Data;

my ($success,$error,$result,$data_obj,$advisory,$parser,$adv_obj,$path,$position_track_AR)=undef;
my ($string,$position_AR)=undef;
my $using_path=undef;

#$result=join('--',@{$adv_obj->movement_toward()});

$path='/home/newemd/emdjlc/hurricane/Storm-Tracker/atlantic/1999/11/';
($data_obj,$error)=Geo::StormTracker::Data->new($path);

&_print_var("data_obj",$data_obj);
&_print_var("error",$error);
print "\n";

$using_path=$data_obj->get_path();

&_print_var("using_path:",$using_path);

exit;
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
