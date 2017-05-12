#!/usr/local/bin/perl
### freec_to_spc.pl #########################################################################
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

my $INPUT_FILE;
my $OUTPUT_FILE;

my $path;
my $suffix;

my $line;
my @line_data;

my $chr;
my $number;
my $copy_number;
### Sub-Methods ###################################################################################



### Main ##########################################################################################
my $ARGC = @ARGV;

if($ARGC != 2){
	die "ERROR: $ARGC arguments were provided, exactly 2 are expected\n";
	}

$input_file_path = $ARGV[0];
$output_directory = $ARGV[1];

( $input_file_name, $path, $suffix ) = fileparse( $input_file_path, "\.[^.]*");


$output_file_name = $output_directory.$input_file_name.".spc";

print "$output_file_name\n";


open ($INPUT_FILE, "<", $input_file_path) or die "ERROR: could not open file at path $input_file_path\n";
open ($OUTPUT_FILE, ">", $output_file_name) or die "ERROR could not open file at path $output_file_name\n";

print $OUTPUT_FILE "#chr\tstart\tend\tnumber\tquality";

while(!(eof($INPUT_FILE))){

	$line = <$INPUT_FILE>;

	@line_data = split(' ',$line);
	
	if(!($line_data[0] =~ m/^(chr)?(.*)/)){
		warn "ERROR chr entry was invalid\n";
		}
	$chr = $2;

	if($line_data[3] == 2){
		warn "ERROR: FOUND a 2\n";
		next;
		}

	$number = $line_data[3];

	print $OUTPUT_FILE "\n";
	print $OUTPUT_FILE $chr;
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE $line_data[1];
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE $line_data[2];
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE $number;
	print $OUTPUT_FILE "\t";
	print $OUTPUT_FILE ".";

	}
