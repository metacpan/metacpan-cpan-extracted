#!/usr/local/bin/perl
### svdetect_to_spt.pl #########################################################################
#
 
### HISTORY #######################################################################################
# Version       Date            Coder   	Comments
# 1.0           2012/03/29      sgovind      	Versioning start point

### INCLUDES ######################################################################################
use warnings;
use strict;

use File::Basename;

### Global Variables ##############################################################################
my $input_file_path;
my $input_file_name;
my $output_directory;
my $output_file_name;

my $INPUT_FILE;
my $OUTPUT_FILE;

my $path;
my $suffix;

my $line;
my @line_data;

my $chr1;
my $chr2;
my $chr1_start;
my $chr1_end;
my $chr2_start;
my $chr2_end;
my $size;

my $i;
### Sub-Methods ###################################################################################



### Main ##########################################################################################
my $ARGC = @ARGV;

if($ARGC != 2){
	die "ERROR: $ARGC arguments were provided, exactly 2 are expected\n";
	}

$input_file_path = $ARGV[0];
$output_directory = $ARGV[1];

( $input_file_name, $path, $suffix ) = fileparse( $input_file_path, "\.[^.]*");


$output_file_name = $output_directory.$input_file_name.".spt";

print "$output_file_name\n";


open ($INPUT_FILE, "<", $input_file_path) or die "ERROR: could not open file at path $input_file_path\n";
open ($OUTPUT_FILE, ">", $output_file_name) or die "ERROR could not open file at path $output_file_name\n";

print $OUTPUT_FILE "#chr1\tstart\tend\tchr2\tstart\tend\tquality";

while(!(eof($INPUT_FILE))){

	$line = <$INPUT_FILE>;

	if($line =~ m/^#/){
		next;
		}
			
	@line_data = split(' ',$line);
	$size =  @line_data;


	if($line_data[16] eq "TRANSLOC" || $line_data[16] eq "INV_TRANSLOC"){

		if(!($line_data[0] =~ m/^(chr)?(.*)/)){
			warn "ERROR chr1 entry was invalid\n";
			}
		$chr1 = $2;

		if(!($line_data[3] =~ m/^(chr)?(.*)/)){
			warn "ERROR chr2 entry was invalid\n";
			}
		$chr2 = $2;
		
		if($size == 25){
			$i = 1;
			}
		else {
			$i=0;
			}
		
		if(!($line_data[20+$i] =~ m/^\((.*),(.*)\)/)){
			warn "ERROR chr1 start and end entry was invalid\n";
			}
		if($1 < $2){
			$chr1_start = $1;
			$chr1_end = $2;
			}
		else {
			$chr1_start = $2;
			$chr1_end = $1;
			}

		if(!($line_data[21+$i] =~ m/^\((.*),(.*)\)/)){
			warn "ERROR chr2 start and end entry was invalid\n";
			}
		if($1 < $2){
			$chr2_start = $1;
			$chr2_end = $2;
			}
		else {
			$chr2_start = $2;
			$chr2_end = $1;
			}

		if(length($chr1)>5 || length($chr2)>5 || $chr1 eq 'M' || $chr2 eq 'M'){
			next;
			}

		print $OUTPUT_FILE "\n";
		print $OUTPUT_FILE $chr1;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $chr1_start;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $chr1_end;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $chr2;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $chr2_start;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $chr2_end;
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE ".";
		}

	}

close($INPUT_FILE);
