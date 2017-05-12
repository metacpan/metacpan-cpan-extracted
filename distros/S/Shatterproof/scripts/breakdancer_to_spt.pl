#!/usr/local/bin/perl
### breakdancer_to_spt.pl #########################################################################
#
 
### HISTORY #######################################################################################
# Version       Date            Coder   	Comments
# 1.0           2012/03/28      sgovind      	Versioning start point

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

my $start1;
my $end1;

my $start2;
my $end2;
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

	#Test for confidence [8] and size of translocation [7]
	if( $line_data[8] < 60 || abs($line_data[7]) < 100 ){
		next;
		}
	if($line_data[6] eq "ITX" || $line_data[6] eq "CTX"){

		print $OUTPUT_FILE "\n";
		print $OUTPUT_FILE $line_data[0];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $line_data[1];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $line_data[1]-$line_data[7];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $line_data[3];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $line_data[4];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $line_data[4]-$line_data[7];
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE ".";
		}

	}

close($INPUT_FILE);
close($OUTPUT_FILE);
