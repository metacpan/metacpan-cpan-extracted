#!/usr/local/bin/perl -w
use blib;
use strict;
use IO::File;
use IO::Dir;
use Geo::StormTracker::Parser;

my ($file,$advisory,$dir,$io,$result)=undef;
my ($parser,$adv_obj)=undef;
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

#Loop over each file and print result
$io=IO::File->new();
foreach $file (@files){
	next if $file =~ m!^(\.|\.\.)$!;
	$io->open("<$advisory_dir/$file");
	@lines=$io->getlines;
	$advisory=join('',@lines);

	$parser=Geo::StormTracker::Parser->new();

	$adv_obj=$parser->read_data($advisory);

	#$result=$adv_obj->advisory_number();
	$result=$adv_obj->name();
	if ((defined $result) and (ref $result)){
		$result=join('__',@{$result});
	}

	if (defined($result)){
		print "\n------------------\nresult for file $file is: \n",$result;
	}
	else {
		print "\n------------------\nresult for file $file is: undefined\n";
	}

	$io->close();
}#foreach

exit;
