#!/usr/local/bin/perl -w
use blib;
use strict;
use IO::File;
use IO::Dir;
use Geo::StormTracker::Parser;
use Geo::StormTracker::Data;

my ($file,$advisory,$dir,$io,$result)=undef;
my ($parser,$adv_obj)=undef;
my ($data_obj,$error,$path,$success);
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

#Create a new data_object
#For now ignore the fact that each advisory may go to a different storm
$path='/home/newemd/emdjlc/hurricane/Storm-Tracker/atlantic/1999/11/';
($data_obj,$error)=Geo::StormTracker::Data->new($path);

#Loop over each file and print result
$io=IO::File->new();
foreach $file (@files){
	next if $file =~ m!^(\.|\.\.)$!;
	next unless $file =~ m!31$!;
	$io->open("<$advisory_dir/$file");
	@lines=$io->getlines;
	$advisory=join('',@lines);

	$parser=Geo::StormTracker::Parser->new();

	$adv_obj=$parser->read_data($advisory);

	($success,$error)=$data_obj->insert_advisory($adv_obj,0);

#	$result=$adv_obj->wmo_header();
#	if ((defined $result) and (ref $result)){
#		$result=join('__',@{$result});
#	}
#
#	if (defined($result)){
#		print "\n------------------\nresult for file $file is: \n",$result;
#	}
#	else {
#		print "\n------------------\nresult for file $file is: undefined\n";
#	}

	$io->close();
}#foreach

exit;
