#!/usr/local/bin/perl -w
use blib;
use strict;
use IO::File;
use IO::Dir;
use Geo::StormTracker::Parser;
use Geo::StormTracker::Data;
use Geo::StormTracker::Main;

my ($file,$advisory,$dir,$io,$result)=undef;
my ($parser,$adv_obj)=undef;
my ($main_obj,$error,$path, $data_obj, $region_code, $year, $event_num);
my @lines=();
my @files=();

my $advisory_dir='/home/newemd/emdjlc/hurricane/Storm-Tracker/advisories/';

#Get list of files
$dir=IO::Dir->new();
$dir->open($advisory_dir) or die "couldn't open directory\n";
@files=$dir->read();
print "files array is: @files\n";
$dir->close;

#Create a parser object
$parser=Geo::StormTracker::Parser->new();

#Create a new main_obj 
#For now ignore the fact that each advisory may go to a different storm
$path='/home/newemd/emdjlc/hurricane/Storm-Tracker/database/';
($main_obj,$error)=Geo::StormTracker::Main->new($path);

#Loop over each file and print result
$io=IO::File->new();
foreach $file (@files){
	next if $file =~ m!^(\.|\.\.)$!;
#	next unless $file =~ m!3[12]$!;
	$io->open("<$advisory_dir/$file");
	@lines=$io->getlines;
	$advisory=join('',@lines);

	$parser=Geo::StormTracker::Parser->new();

	$adv_obj=$parser->read_data($advisory);

	$io->close();

	($data_obj, $region_code, $year, $event_num, $error)=$main_obj->add_advisory($adv_obj,1);

}#foreach

exit;
