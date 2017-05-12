#!/usr/bin/perl
# NanoB2B-NER::NER::Metaman
#
# Turns file lines into MetaMap lines
# Version 1.0
#
# Program by Milk

package NanoB2B::NER::Metaman;

use NanoB2B::UniversalRoutines;
use MetaMap::DataStructures;
use strict;
use warnings;

####          GLOBAL VARIABLES           ####

#option variables
my $debug = 1;
my $program_dir = "";
my $fileIndex = 0;

#datastructure variables
my %params = ();
my $dataStructures = MetaMap::DataStructures->new(\%params); 

#universal subroutines object
my %uniParams = ();
my $uniSub;

#hash object for later
my %metamapHash = ();



####      A BACKSTORY IS CREATED     ####

# construction method to create a new Metaman object
# input  : $directory <-- the name of the directory for the files
#		   \$index     <-- the index to start metamapping from in the set of files
#		   \$debug     <-- run the program with debug print statements
# output : $self      <-- an instance of the Metaman object
sub new {
	#create and bless this Metaman
	my $class = shift;
	my $self = {};
	bless $self, $class;

	#get the inputs
	$self->{directory} = shift;
	$program_dir = $self->{directory};
	$self->{index} = shift;
	$fileIndex = $self->{fileIndex};
	$self->{debug} = shift;
	$debug = $self->{debug};

	$uniParams{'debug'} = $self->{debug};
	$uniSub = NanoB2B::UniversalRoutines->new(\%uniParams);

	return $self;
}

####     TO THE METAMOBILE!    ####

# imports the data, cleans the lines, runs through metamap, and exports the results to a file
# input  : $file <-- name of the file to run through metamap
# output : 
sub meta_file{
	my $self = shift;
	my $file = shift;

	#define and reset temp var
	my $indexer = 0;
	%metamapHash = ();

	#get the name of the file
	my @n = split '/', $file;
	my $l = @n;
	my $filename = $n[$l - 1];
	$filename = lc($filename);

	#import the data from the file
	my $FILE;
	open ($FILE, "$program_dir/$file") || die ("what is this 'dir/file' you speak of?\n");
	my @fileLines = <$FILE>;
	foreach my $l(@fileLines){
		$l = lc($l);
	}
	$uniSub->printColorDebug("on_red", "$filename");

	#get the total num of lines
	my $totalLines = 0;
	$totalLines = @fileLines;
	$uniSub->printColorDebug("red", "Lines: $totalLines\n");

	#clean it up for two separate sets
	my @cleanLines = untagSet($filename, \@fileLines);

	#metamap all the lines --> metamaphash
	$uniSub->printColorDebug("blue", "*Metamapping the lines into a hashtable....\n");
	$indexer = 0;
	my $total = @cleanLines;
	foreach my $line (@cleanLines){
		#printColorDebug("on_blue", "LINE: $line\n");
		my $lnnum = $indexer + 1;
		$uniSub->printColorDebug("green", "$filename - MM Line $lnnum / $total...\n");
		my $mm = metaLine($line, $filename);
		$metamapHash{$indexer} = $mm;
		$indexer++;
	}

	#export the metamap data to a separate file
	exportMetaData($filename);
}

####      CLEANS THE LINE     ####

# cleans the line without getting rid of tags
# input  : $input <-- the line to clean
# output : 
sub cleanWords{
	my $input = shift;

	$input =~ s/[^a-zA-z0-9\:\.\s<>&#;\*\/]/ /g; 	#get rid of non-ascii
	$input =~ s/([0-9]+(\.[0-9]*)?)-[0-9]+(\.[0-9]*)?/RANGE/g;		#get rid of range num (#-#)
	$input =~ s/[0-9]+\.?[0-9]+/NUM/g;				#get rid of normal num (# or #.#)
	$input =~ s/\s?=\s?/eq/g;						#get rid of = 
	$input =~ s/<Node id.*?\/>//g;					#get rid of <NODE id=##/> 
	$input =~ s/[\*\/]//g;							#get rid of *
	#$input =~ s/[,\)\(\\\'\/\=\*\-]/ /g;			
	$input =~ s/\s\+/_/g;							#get rid of _+ space
	$input =~ s/\s+\.\s+/ /g;						#get rid of _._ periods
	$input =~ s/\.\s+/ /g;							#get rid of ._ space
	$input =~ s/\s+/ /g;							#get rid of excessive blank space
	return $input;
}

# returns clean line with no tags or retaggings
# input  : $line  <-- the line to remove the tags from
#		   $id    <-- the entity tag name (ex. <start:adversereaction>)
# output : $input <-- the line untagged
sub untag{
	my $line = shift;
	my $id = shift;

	my $input = lc($line);
	$id = lc($id);
	$input =~ s/ <start:$id>//g;
	$input =~ s/ <end>//g;
	$input = cleanWords($input);
	return $input;
}

# returns a clean set of lines
# input  : $filename  <-- the name of the file/tag for the entities
#		   @lines     <-- the set of lines from the file
# output : @clean_set <-- the line set untagged
sub untagSet{
	my $filename = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @clean_set = ();
	foreach my $line(@lines){
		my $cl = untag($line, $filename);
		push @clean_set, $cl;
	}
	return @clean_set;
}

######    METAMAPS THE LINE   ######

#metamaps a single line
# input  : $line     <-- the line to run through metamap
#		   $name     <-- the name of the file/tag for the entities
# output : $meta     <-- the metamap output for the line
sub metaLine{
	my $line = shift;
	my $name = shift;

	#make a makeshift file to put the line
	open IN, ">", "input" || die ("No input file...$!");
	my $clean_line = untag($line, $name);
	chomp($clean_line);		

	print IN "$clean_line\n";
	close IN;

	#analyze using nlm's program
	my $meta = `metamap -q < input`;
	return $meta;
}

#metamaps an entire set of lines
# input  : $name     <-- the name of the file/tag for the entities
#		   @lines    <-- the set of lines to run through metamap
# output : @set      <-- the set of metamapped lines
sub metaSet{
	my $name = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @set = ();
	foreach my $l (@lines){
		my $ml = metaLine($l, $name);
		push @set, $ml;
	}
	return @set;
}

#exports metamap hashtable data by printing it to a file
# input  : $name     <-- the name of the file/tag for the entities
# output : (META)    <-- a file with the metamap data stored in _META of the files' directory
sub exportMetaData{
	my $name = shift;

	my $META;
	#create a directory to save hashtable data
	if($program_dir ne ""){
		my $subdir = "_METAMAPS";
		$uniSub->make_path("$program_dir/$subdir");
		open($META, ">", ("$program_dir/$subdir/" . $name . "_meta")) || die ("Um...");
	}else{
		open($META, ">", ($name . "_meta")) || die ("Agh!");
	}

	#print metamap data to the file
	foreach my $key (sort { $a <=> $b } keys %metamapHash){
		my $mm = $metamapHash{$key};
		$uniSub->print2File($META, $mm);
	}
	close $META;
}

1;