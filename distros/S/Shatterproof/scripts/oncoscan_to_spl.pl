#!/usr/local/bin/perl
### oncoscan_to_spl.pl #########################################################################
#
 
### HISTORY #######################################################################################
# Version       Date            Coder   	Comments
# 1.0           2012/04/11      sgovind      	Versioning start point

### INCLUDES ######################################################################################
use warnings;
use strict;

use File::Basename;

### Global Variables ##############################################################################
my $input_file_path;
my $input_file_name;
my $output_directory;
my $output_file_name;

my $sample_code;
my $read_sample_code;

my $INPUT_FILE;
my $OUTPUT_FILE;

my $path;
my $suffix;

my $line;
my @line_data;

my @region_data;

my $chr;
my $start;
my $end;
### Sub-Methods ###################################################################################



### Main ##########################################################################################
my $ARGC = @ARGV;

if($ARGC != 3){
	die "ERROR: $ARGC arguments were provided, exactly 3 are expected\nInput File, Output Directory, OncoScan Sample Code\n";
	}

$input_file_path = $ARGV[0];
$output_directory = $ARGV[1];
$sample_code = $ARGV[2];

( $input_file_name, $path, $suffix ) = fileparse( $input_file_path, "\.[^.]*");


$output_file_name = $output_directory.$input_file_name.".spl";

print "$output_file_name\n";


open ($INPUT_FILE, "<", $input_file_path) or die "ERROR: could not open file at path $input_file_path\n";
open ($OUTPUT_FILE, ">", $output_file_name) or die "ERROR could not open file at path $output_file_name\n";

print $OUTPUT_FILE "#chr\tstart\tend\tquality";

$line = <$INPUT_FILE>;	#Read header line

while(!(eof($INPUT_FILE))){

	$line = <$INPUT_FILE>;

	@line_data = split(' ',$line);

	if(!($line_data[0] =~ m/^(.*)_(.*)/)){
		warn "ERROR sample code was invalid\n";
		}

	$read_sample_code = $2;

	if($read_sample_code ne $sample_code){
		next;
		}

	if($line_data[2] ne 'LOH'){
		next;
		}

	@region_data = split(/:|-/,$line_data[1]);

	if(!($region_data[0] =~ m/^(chr)?(.*)/)){
		die "ERROR chr entry was invalid\n";
		}
	$chr = $2;

	$start = $region_data[1];
	$start =~ tr/,//d;

	$end = $region_data[2];
	$end =~ tr/,//d; 

	print $OUTPUT_FILE "\n";
	print $OUTPUT_FILE $chr;
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE $start;
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE $end;
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE ".";
	}
