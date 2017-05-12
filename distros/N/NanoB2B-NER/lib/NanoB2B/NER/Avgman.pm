#!/usr/bin/perl
# NanoB2B-NER::NER::Avgman
#
# Averages Weka files and makes a nice output file
# Version 1.0
#
# Program by Milk

package NanoB2B::NER::Avgman;

use NanoB2B::UniversalRoutines;
use File::Path qw(make_path);			#makes sub directories	
use strict;
use warnings;

####          GLOBAL VARIABLES           ####

#option variables
my $program_dir;
my $bucketsNum = 10;
my $weka_dir;
my $debug = 0;

#universal subroutines object
my %uniParams;
my $uniSub;

#module variables
my @features;
my @wekaAttr = ("TP Rate", "FP Rate", "Precision", "Recall", "F-Measure", "MCC", "ROC Area", "PRC Area");
my @allBuckets;
my @sets;
my $entId = "_e";

####      A SUPER PET IS ADOPTED     ####

# construction method to create a new Avgman object
# input  : $directory <-- the name of the directory for the files
#		   $weka_dir  <-- the weka directory name
#		   $features  <-- the set of features [e.g. "ortho morph text pos cui sem"]
#		   $buckets   <-- the number of buckets used for the k-fold cross validation
#		   $debug     <-- the set of features to run on [e.g. omtpcs]
# output : $self      <-- an instance of the Avgman object
sub new {
	#grab class and parameters
    my $self = {};
    my $class = shift;
    return undef if(ref $class);
    my $params = shift;

    #reset all the arrays
    %uniParams = ();
    @features = ();
    @allBuckets = ();
    @sets = ();

    #bless this object
    bless $self, $class;
    $self->_init($params);
    @allBuckets = (1..$bucketsNum);

    #retrieve parameters for universal-routines
    $uniParams{'debug'} = $debug;
	$uniSub = NanoB2B::UniversalRoutines->new(\%uniParams);

	#make the features
	my $item = "_";
	foreach my $fs (@features){
		$item .= substr($fs, 0, 1);		#add to abbreviations for the name
		push(@sets, $item);
	}

	return $self;
}

#  method to initialize the NanoB2B::NER::Avgman object.
#  input : $parameters <- reference to a hash
#  output: 
sub _init {
    my $self = shift;
    my $params = shift;

    $params = {} if(!defined $params);

    #  get some of the parameters
    my $diroption = $params->{'directory'};
	my $ftsoption = $params->{'features'};
	my $bucketsNumoption = $params->{'buckets'};
	my $wekadiroption = $params->{'weka_dir'};
    my $debugoption = $params->{'debug'};

    #set the global variables
    if(defined $debugoption){$debug = $debugoption;}
    if(defined $diroption){$program_dir = $diroption;}
    if(defined $bucketsNumoption){$bucketsNum = $bucketsNumoption;}
    if(defined $ftsoption){@features = split(' ', $ftsoption);}
    if(defined $wekadiroption){$weka_dir = $wekadiroption};
}


###############			NOT YOUR AVGMAN! 		################

#prints weka results to an output file
# input  : $name 	  <-- name of the file with the weka data
# output : (weka average results file)
sub avg_file{
	my $self = shift;
	my $name = shift;
	my %avg = averageWekaData($name);
	my %ind = individualWekaData($name);
	my $msb = getMSB($name);

	#open new file
	my $direct = ("$program_dir/_WEKAS/$weka_dir");		
	make_path($direct);		
	my $file = "$direct/$name" . "_weka-results";		
	my $WEKA_SAVE;
	open ($WEKA_SAVE, ">", "$file") || die ("Aw man! $!");

	#print the name
	$uniSub->print2File($WEKA_SAVE, "ENTITY NAME\t\t: $name"); 

	#print the list of features
	$uniSub->print2FileNoLine($WEKA_SAVE, "FEATURES\t\t: ");
	foreach my $d(@features){$uniSub->print2FileNoLine($WEKA_SAVE, "$d, ");}
	$uniSub->print2File($WEKA_SAVE, "");

	#print the msb
	$msb = int($msb * 10**4) / 10**4;
	$uniSub->print2File($WEKA_SAVE, "Majority Label Baseline : $msb");

	$uniSub->print2File($WEKA_SAVE, "\n");

	#print the averages
	foreach my $key (sort keys %avg){
		$uniSub->print2File($WEKA_SAVE, "$key - AVERAGES");
		$uniSub->print2File($WEKA_SAVE, "-------------------------");

		my @arr = @{$avg{$key}};
		my $arrLen = @arr;
		for(my $a = 0; $a < $arrLen; $a++){
			my $wekaThing = $wekaAttr[$a];
			my $entry = $arr[$a];
			my $tab = "";
			if(length($wekaThing) > 7){
				$tab = "\t";
			}elsif(length($wekaThing) < 4){
				$tab = "\t\t\t";
			}else{
				$tab = "\t\t";
			}

			my $in = "$wekaThing" . $tab . "-\t$entry";
			$uniSub->print2File($WEKA_SAVE, $in);
		}
		$uniSub->print2File($WEKA_SAVE, "");
	}
	$uniSub->print2File($WEKA_SAVE, "\n");
	#print the individual
	foreach my $key (sort keys %ind){
		#header
		$uniSub->print2File($WEKA_SAVE, "$key - INDIVIDUAL");
		$uniSub->print2File($WEKA_SAVE, "==================\n");
		$uniSub->print2FileNoLine($WEKA_SAVE, "\t\t\t");
		foreach my $r(@wekaAttr){
			my $sr = "";
			if(length($r) >= 6){$sr = (substr($r, 0, 6) . ".");}
			elsif(length($r) < 4){$sr = "$r\t";}
			else{$sr = $r;}
			$uniSub->print2FileNoLine($WEKA_SAVE, "$sr\t");
		}
		$uniSub->print2File($WEKA_SAVE, "\n-------------------------------------------------------------------------------");

		#print the lines
		my @arr = @{$ind{$key}};
		my $arrLen = @arr;

		for(my $a = 0; $a < $arrLen;$a++){
			my $b = $a + 1;
			my $entry = $arr[$a];
			#printColorDebug("on_red", "$name - $entry");

			my $in = "BUCKET $b\t$entry";
			$uniSub->print2File($WEKA_SAVE, $in);
		}
		
		$uniSub->print2File($WEKA_SAVE, "");
	}

	close $WEKA_SAVE;

}


#average the weka accuracy datas
# input  : $name 	  <-- name of the file with the weka data
# output : %featAvg   <-- hash of each feature set's averages (in array form aligned to the wekaAttr)
sub averageWekaData{
	my $name = shift;
	my %featAvg = ();

	foreach my $item (@sets){
		my %data = ();

		foreach my $bucket(@allBuckets){

			#import the wekaman
			my $file = "$program_dir/_WEKAS/$weka_dir/$name" . "_WEKA_DATA/_$item/$name" . "_accuracy_$bucket";
			open (WEKA, "$file") || die ("WHY NO FILE - $file?!");

			#get lines
			my @lines = <WEKA>;
			foreach my $line(@lines){chomp($line)};
			my $len = @lines;

			#get the rest of the array
			my $keyword = "=== Error on test data ===";
			my $index = $uniSub->getIndexofLine($keyword, \@lines);
			my @result = @lines[$index..$len];

			#grab the only stuff you need
			my $weightWord = "Weighted Avg";
			my $weightIndex = $uniSub->getIndexofLine($weightWord, \@result);
			my $weightLine = $result[$weightIndex];

			#split it uuuuuup
			my @values = split /\s+/, $weightLine;
			my $valLen = @values;
			my $valLen2 = $valLen - 1;
			@values = @values[2..$valLen2];
			#printArr(", ", @values);

			#add to overall
			push(@{$data{$bucket}}, @values);
		}
		
		my @averages = ();
		#add all the stuffs
		foreach my $bucket (@allBuckets){
			my @wekaSet = @{$data{$bucket}};
			my $wekaLen = @wekaSet;
			for(my $e = 0; $e < $wekaLen; $e++){
				my $entry = $wekaSet[$e];
				if($entry ne "NaN"){
					$averages[$e] += $entry;
				}
			}
		}

		#printArr(", ", @avgLens);

		#divide them
		foreach my $tea (@averages){
			$tea /= $bucketsNum;
		}

		#ta-da averages
		push(@{$featAvg{$item}}, @averages);

		#hello I am here(>'_')> hug me~
		#ok then <(^_^<) ~
	}
	#exit;
	return %featAvg;
}

#retrieve the weighted average lines from the individual buckets
# input  : $name 	  <-- name of the file with the weka data
# output : %featData   <-- hash of arrays for each line of individual data for the buckets
sub individualWekaData{
	my $name = shift;
	my %featData = ();

	foreach my $item (@sets){
		my @data = ();
		foreach my $bucket(@allBuckets){

			#import the wekaman
			my $file = "$program_dir/_WEKAS/$weka_dir/$name" . "_WEKA_DATA/_$item/$name" . "_accuracy_$bucket";
			open (WEKA, "$file") || die ("WHY NO FILE - $file?!");

			#get lines
			my @lines = <WEKA>;
			foreach my $line(@lines){chomp($line)};
			my $len = @lines;

			#get the rest of the array
			my $keyword = "=== Error on test data ===";
			my $index = $uniSub->getIndexofLine($keyword, \@lines);
			my @result = @lines[$index..$len];

			#grab the only stuff you need
			my $weightWord = "Weighted Avg";
			my $weightIndex = $uniSub->getIndexofLine($weightWord, \@result);
			my $weightLine = $result[$weightIndex];

			#split it uuup
			my @values = split /\s+/, $weightLine;
			my $valLen = @values;
			$valLen -= 1;
			my @values2 = @values[2..$valLen];

			#rejoin it
			my $valLine = join("\t", @values2);

			#add it
			push (@data, $valLine);
		}
		push (@{$featData{$item}}, @data);
	}
	return %featData;
}

# grabs the majority sense-label baseline for the file
# input  : $name      <-- name of the file to get the entities from
# output : $msb       <-- # of no instances / # of yes instances
sub getMSB{
	my $file = shift;
	#get the name of the file
	my @n = split '/', $file;
	my $l = @n;
	my $filename = $n[$l - 1];
	$filename = lc($filename);

	#import the data from the file
	if($program_dir ne ""){open (FILE, "$program_dir/$file") || die ("what is this 'dir/file' you speak of?\n");}
	else{open (FILE, "$file") || die ("what is this 'file' you speak of?\n");}
	my @fileLines = <FILE>;
	foreach my $l(@fileLines){
		$l = lc($l);
	}

	#clean it up for two separate sets
	my @tagSet = retagSet($filename, \@fileLines);

	#count and get results
	return countInst(\@tagSet);
}

# counts the # of no instances / # of all instances
# input  : @set   <-- set of lines to read and count
# output : $msb   <-- # of no instances / # of all instances

sub countInst{
	my $set_ref = shift;
	my @set = @$set_ref;

	my $no_inst = 0;
	my $all_inst = 0;

	foreach my $line(@set){
		my @words = split(" ", $line);
		foreach my $word(@words){
			#print($word . "\n");
			if(!($word =~ /([\s\S]*($entId)$)/)){
				$no_inst++;
			}

			$all_inst++;
		}
	}

	return ($no_inst / $all_inst);
}



######    RETAGS THE LINE    ######

# turns the tagged entity words into special words with <> for the context words
# input  : $input <-- the line to retag
#		   $id    <-- the id within the tag to look for
# output : (.arff files)
sub retag{
	my $input = shift;
	my $id = shift;

	$id = lc($id);
	my $line = lc($input);

	#get rid of any tags
	my @words = split (" ", $line);
	my @newSet = ();
	my $charact = 0;
	foreach my $word (@words){
		if($charact){
			if($word eq "<end>"){
				$charact = 0;
			}else{
				my $charWord = "$word"."$entId"; 
				push @newSet, $charWord;
			}
		}else{
			if($word eq "<start:$id>"){
				$charact = 1;
			}else{
				push @newSet, $word;
			}
		}
	}

	#clean up the new line
	my $new_line = join " ", @newSet;
	$new_line =~s/\b$entId\b//g;
	$new_line = $uniSub->cleanWords($new_line);
	return $new_line;
}

# turns the tagged entity words in the entire file into special words with <> for the context words
# input  : $name  <-- the name of the file to use as the id tag
#		   @lines   <-- the set of lines to retag
# output : @tagSet <-- set of retagged lines
sub retagSet{
	my $name = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my @tagSet = ();
	foreach my $line (@lines){
		#retag the line
		chomp($line);
		my $tag_line = retag($line, $name);

		#add it to the set
		push @tagSet, $tag_line;
	}
	return @tagSet;
}

1;