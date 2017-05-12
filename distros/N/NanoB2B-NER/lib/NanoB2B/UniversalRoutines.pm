#!/usr/bin/perl
# NanoB2B::UniversalRoutines
#
# Just universally used subroutines (i.e. printColor, inArray, wordIndex)
# Version 1.0
#
# Program by Milk


package NanoB2B::UniversalRoutines;

#######################                IMPORTS                       ####################

use Term::ANSIColor;					#color coding the output
use List::MoreUtils qw(first_index);	#check for first occurrence of a word
use List::MoreUtils qw(indexes);		#get all of the indexes of a word

use strict;
use warnings;

##### GLOBAL VARIABLES #####

my $debug = 0;

#----------------------------------------
#               constructor
#----------------------------------------
#  constructor method to create a new UR object
#  input : $params <- reference to hash containing the parameters
#  output: $self <- a UR object

sub new {
    #grab class and parameters
    my $self = {};
    my $class = shift;
    return undef if(ref $class);
    my $params = shift;

    #bless this object
    bless $self, $class;

     #  get some of the parameters
    my $debugoption = $params->{'debug'};
    if(defined $debugoption){$debug = $debugoption;}

    return $self;
}

#################              HERE BE SUB-ROUTINES            ######################
#################    (alphabatized for your convenience :D)    ######################


#excludes a value from a number array
# input  : $e 	  <-- the number of elements in the array (5 = 1,2,3,4,5)
#		   $bully <-- the number to exclude from the set (3 => 1,2,4,5)
# output : @kids  <-- the number set
sub bully{
	my $self = shift;
	my $num = shift;
	my $bully = shift; 

	my @kids = (1..$num);
	@kids = grep { $_ != $bully } @kids;
	return @kids;
}

# cleans the line without getting rid of tags
# input  : $input <-- the line to clean up
# output : $input <-- cleaned up input line
sub cleanWords{
	my $self = shift;
	my $input = shift;

	$input = lc($input);
	$input =~ s/[^a-zA-z0-9\:\.\s<>&#;\*\/]/ /g; 	#get rid of non-ascii
	#$input =~ s/([0-9]+(\.[0-9]*)?)-[0-9]+(\.[0-9]*)?/RANGE/g;		#get rid of range num (#-#)
	$input =~ s/\b[0-9]+\.?[0-9]+\b/NUM/g;			#get rid of normal num (#.#)
	$input =~ s/\b[0-9]+\b/NUM/g;					#get rid of normal num (#.#)
	$input =~ s/\s?=\s?/eq/g;						#get rid of = 
	$input =~ s/<Node id.*?\/>//g;					#get rid of <NODE id=##/> 
	$input =~ s/[\*\/]//g;							#get rid of * and /
	#$input =~ s/[,\)\(\\\'\/\=\*\-]/ /g;			
	$input =~ s/\s\+/_/g;							#get rid of _+ space
	$input =~ s/\s+\.\s+/ /g;						#get rid of _._ periods
	$input =~ s/\.\s+/ /g;							#get rid of ._ space
	$input =~ s/\s+/ /g;							#get rid of excessive blank space
	return $input;
}


#finds the index of a special phrase from an array
# input  : $phrase 	 <-- the regex to look for within the set
#		   @arr      <-- the array to look through
# output : $x        <-- return the index of the regex; returns -1 if not found
sub findPhraseIndex{
	my $self = shift;
	my $phrase = shift;
	my $arr_ref = shift;
	my @arr = @$arr_ref;

	my $arrTot = @arr;
	for(my $x = 0; $x < $arrTot; $x++){
		my $line = $arr[$x];
		if($line =~/$phrase/g){
			return $x;
		}
	}
	return -1;
}

#helper function that retrieves all of the indexes of a word in a given set
# input  : $word <-- an element or object
#		   @set  <-- the array to look through
# output : array <-- returns a set of all indexes of the word; returns {-1} if none found
sub getAllIdxs{
	my $self = shift;
	my $word = shift;
	my $set_ref = shift;
	my @set = @$set_ref;

	my @idxs = indexes{$_ eq $word} @set;
	return @idxs;
}

#gets the line's index
# input  : $keyword <-- the regex to use to search for the specific line
#		   @lines   <-- the set of lines to look through
# output : $a  		<-- return the index of the line based on the regex; returns -1 if not found
sub getIndexofLine{
	my $self = shift;
	my $keyword = shift;
	my $lines_ref = shift;
	my @lines = @$lines_ref;

	my $len = @lines;
	for(my $a = 0; $a < $len; $a++){
		my $line = $lines[$a];
		if ($line =~ /($keyword)/){
			return $a;
		}
	}	
	return -1;
}

#retrieves the stop words
# input  : --
# output : @words <-- returns the set of stop words as retrieved from stop_words.txt
sub getStopWords{
	open (my $SW, "stop_words.txt") || die ("no stopping for you!");
	my @words = <SW>;
	foreach my $word (@words){chomp($word)};
	return @words;
}

#helper function to check if an element is in an array
# input  : $e 	   <-- an element or object
#		   @array  <-- the array to look through
# output : boolean <-- 1 if it is in the array, 0 if it isn't
sub inArr{
	my $self = shift;
	my $e = shift;
	my $arr_ref = shift;
	my @arr = @$arr_ref;

	my $ans = first_index {$_ eq $e} @arr;
	if($ans > -1){
		return 1;
	}else{
		return 0;
	}
}

#checks if stop word
# input  : $word 	 <-- a word to check for
# output : boolean <-- 1 if it is a stopword, 0 if it isn't
sub isStopWord{
	my $self = shift;
	my $word = shift;

	return inArr($word, getStopWords());
}

#prints to a file called debug
# input  : $output 	 <-- the text to output to the debug file
# output : --
sub print2DebugFile{
	my $self = shift;
	my $output = shift;

	open(DEBUG, ">>", "debug") || die "NOOOOOO DEBUG NOOOOOO!!! >w<";
	print2File(<DEBUG>, $output);
}

#prints to a file w/ line skip
# input  : $file 	 <-- the file to print to (must already be opened!)
#		   @array    <-- the text to print to the file (includes next line)
# output : --
sub print2File{
	my $self = shift;
	my $file = shift;
	my $txt = shift;

	print $file "$txt\n";
}

#prints to a file as is
# input  : $file 	 <-- the file to print to (must already be opened!)
#		   @array    <-- the text to print to the file
# output : --
sub print2FileNoLine{
	my $self = shift;
	my $file = shift;
	my $txt = shift;

	print $file "$txt";
}

#shows an array
# input  : $delim 	 <-- string to separate the elememts by
#		   @array    <-- the array to print
# output : string    <-- returns the array elements in a string format separated by the delimiter
sub printArr{
	my $self = shift;
	my $delim = shift;
	my $parr_ref = shift;
	my @parr = @$parr_ref;

	my $combo = join ($delim, @parr);
	print "$combo\n";
}


#prints input with color
# input  : $color 	<-- color to print the text in
#		   $text    <-- the text to print
# output : --
sub printColor{
	my $self = shift;
	my $color = shift;
	my $text = shift;

	if($color =~ /on_\w+/){print color($color), "$text", color("reset"), "\n";}
	else{print color($color), "$text", color("reset");}
}

#prints input with color for debug mode only
# input  : $color 	<-- color to print the text in
#		   $text    <-- the text to print
# output : --
sub printColorDebug{
	my $self = shift;
	my $color = shift;
	my $text = shift;

	if($debug){
		if($color =~ /on_\w+/){print color($color), "$text", color("reset"), "\n";}
		else{print color($color), "$text", color("reset");}
		
	}
}

#prints only if debug mode is on
# input  : $text    <-- the text to print
# output : --
sub printDebug{
	my $self = shift;
	my $text = shift;

	if($debug){
		print ($text);
	}
}

#helper function that checks if an array set is in another array
# input  : @arr1 	 <-- the subject array element
#		   @arr2 	 <-- the array to look through
# output : boolean 	 <-- 1 if it is in the array, 0 if it isn't
sub setInArr{
	my $self = shift;
	my $arr1_ref = shift;
	my $arr2_ref = shift;
	
	my @arr1 = @$arr1_ref;
	my @arr2 = @$arr2_ref;

	my $str1 = join " ", @arr1;
	my $str2 = join " ", @arr2;

	if(index($str2, $str1) != -1){
		return 1;
	}else{
		return 0;
	}
}

#counts how many times a word appears in a set
# input  : $word 	 <-- the word to look for in the array
#		   @arr      <-- the array to look through
# output : $num 	 <-- the total number of times the element occurs in the array
sub wordCount{
	my $self = shift;
	my $word = shift;
	my $arr_ref = shift;
	my @arr = @$arr_ref;

	my @idx = getAllIdxs($word, @arr);
	my $num = @idx;
	return $num;
}

#makes a counter for each word in a line
# input  : @words <-- the set of words to count
# output : @index_set <-- the set of counter numbers correlating to each word
sub wordIndex{
	my $self = shift;
	my $words_ref = shift;
	my @words = @$words_ref;

	my @curWords = ();
	my @index_set = ();
	foreach my $word (@words){
		my $index = wordCount($word, @curWords) + 1;
		push(@curWords, $word);
		push (@index_set, $index);
	}

	return @index_set;
}

1;