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
foreach $file (@files){
	next if $file =~ m!^(\.|\.\.)$!;
	open FILE, "<$advisory_dir/$file" or die "couldn't open file $file\n";

	$adv_obj=$parser->read(\*FILE);

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

	close FILE;
}#foreach

exit;
