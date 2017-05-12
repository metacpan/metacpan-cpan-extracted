#!/usr/local/bin/perl
#The ShatterProof package is copyright (c) 2013 Ontario Institute for Cancer Research (OICR).
#
#This package and its accompanying libraries is free software; you can redistribute it and/or modify it under the terms of the GPL (either version 1, or at your option, any later version) or the Artistic License 2.0.  Refer to LICENSE for the full license text.

#OICR makes no representations whatsoever as to the SOFTWARE contained herein.  It is experimental in nature and is provided WITHOUT WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE OR ANY OTHER WARRANTY, EXPRESS OR IMPLIED.  CSHL MAKES NO REPRESENTATION OR WARRANTY THAT THE USE OF THIS SOFTWARE WILL NOT INFRINGE ANY PATENT OR OTHER PROPRIETARY RIGHT.

#By downloading this SOFTWARE, your Institution hereby indemnifies OICR against any loss, claim, damage or liability, of whatsoever kind or
#nature, which may arise from your Institution's respective use, handling or storage of the SOFTWARE.

#If publications result from research using this SOFTWARE, we ask that the Ontario Institute for Cancer Research be acknowledged and/or credit be given to OICR scientists, as scientifically appropriate.

### Shatterproof.pm ###############################################################################
# ShatterProof is a tool that can be used to analyze next generation sequencing data for signs 
# of chromothripsis. 
# See POD at end of file for more description
#

### INCLUDES ######################################################################################
use strict;
use warnings;
use Carp;

use vars qw($VERSIONS);

use feature 'switch';
#use Switch;
use File::Basename;
use List::Util qw[min max];
use Statistics::Distributions;
use POSIX;
###################################################################################################

### HISTORY #######################################################################################
# Version       Date            Coder   	Comments
# 0.001         2012/03/19      sgovind      	Versioning start point
# 0.002		2012/04/03	sgovind		moved input validation methods and run methods
#						from shatterproof.pl to here
# 0.003		2012/10/08	sgovind		Updated POD
# 0.04		2012/11/25	sgovind		Stable build before changing translocation scoring equation
# 0.05		2012/12/26	sgovind		See change log for details
# 0.06		2012/12/27	sgovind		Added additional documentation for new config variable
# 0.07		2012/12/27	sgovind		Added example guide for provided sample data
# 0.08		2013/05/22	sgovind		Added EXPORT code for test case, added minor error checking
# 0.09		2013/06/10	sgovind		Minor changes to accomodate testing
# 0.10		2013/06/19	sgovind		Minor changes to accomodate testing
# 0.11		2013/06/24	sgovind		Changed all sorts to stable sorts. Reduced number of posix
#						calculations.
# 0.12		2013/06/28	sgovind		Changed sort order of interchromosomal translocation output
# 0.13		2013/0716	sgovind		Corrected logical error in calculate_loh_score

our $VERSION = '0.14';

package Shatterproof;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(
			$bin_size
			$genome_cnv_data_hash_ref
			$chromosome_copy_number_count_hash_ref
			$chromosome_cnv_breakpoints_hash_ref
			$tp53_mutation_found
			$genome_trans_data_hash_ref
			$chromosome_translocation_count_hash_ref
			$genome_trans_breakpoints_hash_ref
			$genome_mutation_density_hash_ref
			$suspect_regions_array_ref
			$likely_regions_array_ref
			$genome_cnv_data_windows_hash_ref
			$genome_trans_data_windows_hash_ref
			$genome_mutation_data_windows_hash_ref
			$localization_window_size
		);

### Global Variables ##############################################################################
my $pos = 0;	#used to parse command line variables
my $ARGC;	#stores the number of command line arguments provided

my %chromosome_length = (			#stores the sequence length of each chromosome
			 X => 154913754,
			 Y => 57741652,
			 1 => 247199719,
			 2 => 242751149,
			 3 => 199446827,
			 4 => 191263063,
			 5 => 180837866,
			 6 => 170896993,
			 7 => 158821424,
			 8 => 146274826,
			 9 => 140442298,
			 10 => 135374737,
			 11 => 134452384,
			 12 => 132289534,
			 13 => 114127980,
			 14 => 106360585,
			 15 => 100338915,
			 16 => 88822254,
			 17 => 78654742,
			 18 => 76117153,
			 19 => 63806651,
			 20 => 62435965,
			 21 => 46944323,
			 22 => 49528953
			);

my $TP53_start 	= 1000000*7.57;	#start base pair of the TP53 gene
my $TP53_end 	= 1000000*7.59;	#end base pair of the TP53 gene

my $insertion_data_present = 0;
my $LOH_data_present = 0;


#The values for the following 13 variables are defined in the config.pl file 
our $bin_size;			#number of bases pairs that will be compressed into 1 region when analyzing the genome
						#this value defines how many base pairs are included in one array element in the data_hash_ref varaibles

our $localization_window_size;			#number of regions to sum together when performing sliding window analysis of the genome

our $expected_mutation_density;			#the expected mutation density of translocations in a highly mutated region
						#used to calculate spread factor of translocations
our $low_mutation_density_threshold;		#the mutation density that will be used to call likely regions

our $collapse_regions;				#flag variable
						#value 1:	merge overlapping CNV regions that have the same copy number
						#value 0:	do not merge overlapping CNV regions that have the same copy number. If such 
						#		regions are found an error is thrown

our $outlier_deviation;				#the number of standard deviations away from the mean a value has to be in order to be considered non-significant

our $translocation_cut_off_count;		#the max number of translocation chromosomes that will be tolerated before translocation score is set to 0

our $chromosome_localization_weight;		#the scoring formula weight given to the localization of mutations to a specific region on the chromosome
our $genome_localization_weight; 		#the scoring formula weight given to the localization of mutations to a specific chromosome
our $cnv_weight;				#the scoring formula weight given to the aberrant CNV hallmark 
our $translocation_weight; 			#the scoring formula weight given to the localization of translocations
our $insertion_breakpoint_weight; 		#the scoring formula weight given to the number of insertions found at translocation breakpoints
our $loh_weight;				#the scoring formula weight given to the amount of heterozygosity that is retained in a mutated region
our $tp53_mutated_weight; 			#the scoring formula weight given to the presents or absence of a TP53 mutation

### SUB METHODS ###################################################################################

#=head2 Sub-Method: run

### run ###########################################################################################
# Description:
#	Main method called by shatterproof.pl
#	Calls primary sub methods
#
# Input variables:
#	$argv_ref:	reference to @ARGV

#=cut
sub run {

	my $argv_ref = shift;		#parse parameters
	my @argv = @{$argv_ref};	#dereference array reference

	my $cnv_directory;		#stores the path to the directory where the CNV input files are found
	my $trans_directory;		#stores the path to the directory where the translocation input files are found
	my $insertion_directory;		#stores the path to the directory where the insertion input files are found
	my $loh_directory;		#stores the path to the directory where the loss of hetrozygosity input files are found
	my $output_directory;		#stores the path to the directory where output files will be placed

	my $config_file_path;		#stores the path to the configuration file

	my $tp53_mutated = 0;		#flag variable to indicate if the TP53 gene should be considered to be mutated
	my $tp53_mutation_found = 0;	#flag variable to indicate if a mutation was found in the TP53 region. This does not affect scoring

	my @cnv_files;			#list of CNV input files
	my @trans_files;		#list of translocation input files
	my @insertion_files;			#list of insertion input files
	my @loh_files;			#list of LOH input files

	
	my $chromosome_copy_number_count_hash_ref;	#hash
							#key1: 	chromosome eg. 1,2,X,Y
							#key2:	copy-number state eg. 0,1,3,20
							#value:	number of regions with copy number key2

	my $chromosome_cnv_breakpoints_hash_ref;	#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	an array storing the start and end points of all cnv regions on key

	my $chromosome_translocation_count_hash_ref;	#hash
							#key1: 	chromosome eg. 1,2,X,Y
							#key2: 	chromosome eg. 1,2,X,Y
							#value:	number of translocations between key1 and key2

	my $chromosome_insertion_count_hash_ref;		#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	number of insertions on key

	my $chromosome_loh_breakpoints_hash_ref;	#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	an array storing the start and end points of all loh regions on key


	my $genome_trans_breakpoints_hash_ref;		#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	an array storing all the translocation breakpoints on key
							
	my $genome_trans_insertion_breakpoints_hash_ref;	#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	an array storing only the translocation breakpoints on key that have a insertion with 10 base pairs

	my $genome_mutation_density_hash_ref;		#hash
							#key: 	chromosome eg. 1,2,X,Y
							#value:	the total number of mutation on key divided by the sequence length of key


	my $genome_cnv_data_hash_ref = initialize_genome_hash();	#hash {key1}[index]{key2}
									#key1: 	chromosome eg. 1,2,X,Y
									#value:	an array storing references to hashes which contain information about the 
									#	CNVs in each region of key1. The index of the array indicated the region
									#key2:	'BPcount' -> gives the number of CNV breakpoints in the region.
									#	a number, eg. '1' -> gives the number of subregions within the region that 
									#	have a copy number of 1
									
	my $genome_trans_data_hash_ref = initialize_genome_hash();	#hash {key1}[index]{key2}{key3}
									#key1: 	chromosome eg. 1,2,X,Y
									#value1:an array storing references to hashes which contain information about the 
									#	translocations in each region of key1. The index of the array indicated the region.
									#key2:	'BPcount' -> gives the number of translocation breakpoints in the region
									#	'in' -> gives a reference to a hash that contains information about translocations
									#	into the region
									#	'out' -> gives a reference to a hash that contains information about translocations
									#	out of the region
									#key3:	chromosome eg. 1,2,X,Y
									#value2:the number of subregions in the region that were translocated to key1 from key3 if key2 = 'in'
									#	or
									#	the number of subregions in the region that were translocated from key1 to key3 if key2 = 'out'
	
	my $genome_insertion_data_hash_ref = initialize_genome_hash();	#hash {key1}[index]
									#key1: 	chromosome eg. 1,2,X,Y
									#value:	an array storing the number of insertions in each region of key1
									#	The index of the array indicated the region


	my $genome_cnv_data_windows_hash_ref;		#hash {key1}[index]
							#key1: 	chromosome eg. 1,2,X,Y
							#value:	an array storing the number of CNV breakpoints in each window of the genome.
							#	Each window begins at the region indicated by the array index
							
	my $genome_trans_data_windows_hash_ref;		#hash {key1}[index]
							#key1: 	chromosome eg. 1,2,X,Y
							#value:	an array storing the number of translocation breakpoints in each window of the genome.
							#	Each window begins at the region indicated by the array index
							

	my $genome_mutation_data_windows_hash_ref;	#hash {key1}[index]
							#key1: 	chromosome eg. 1,2,X,Y
							#value:	an array storing the total number of mutation breakpoints in each window of the genome.
							#	Each window begins at the region indicated by the array index

	my $suspect_regions_array_ref;		#reference to array that stores regions where chromothripsis most likely occured. Format: chr start end
	my $likely_regions_array_ref;		#reference to array that stores regions where chromothripsis may have occured. Format: chr start end


	#Validate input arguements and parse them to the correct variables
	validate_input(\@argv, \$cnv_directory, \$trans_directory, \$insertion_directory, \$loh_directory, \$tp53_mutated, \$output_directory, \$config_file_path);

	#Load the values from the config file
	if(load_config_file($config_file_path)!=1){
		die("ERROR - could not load config file\n");
		}

	print "CNV dir:\t$cnv_directory\n";
	print "Trans dir:\t$trans_directory\n";

	if(defined($insertion_directory)){
		print "insertion dir:\t$insertion_directory\n";
		}

	if(defined($loh_directory)){
		print "LOH dir:\t$loh_directory\n";
		}

	print "Output dir:\t$output_directory\n";

	print "Force TP53 Mutation:\t$tp53_mutated\n\n";

	#Get a list of files for each of the provided input directories
	@cnv_files = glob ("$cnv_directory"."*.spc");
	@trans_files = glob ("$trans_directory"."*.spt");

	if(scalar(@cnv_files)==0 || scalar(@trans_files)==0){
		die "ERROR: no CNV or translocation input files found\n";
		}

	if(defined($insertion_directory)){
		@insertion_files = glob ("$insertion_directory"."*.vcf");
		}

	if(defined($loh_directory)){
		@loh_files = glob ("$loh_directory"."*.spl");
		}

	#Echo a list of all the input files
	$" = "\n\t\t";
	print "CNV files:\t@cnv_files\n\n";
	print "Trans files:\t@trans_files\n\n";
	$" = "\n\t\t";
	if(scalar(@insertion_files)==0){
		print "Indel files:\t-none\n\n";
		}
	else{
		print "Indel files:\t@insertion_files\n\n";
		}
	$" = "\n\t";
	if(scalar(@loh_files)==0){
		print "LOH files:\t-none\n\n";
		}
	else{
		print "LOH files:\t@loh_files\n\n";
		}
	$" = " ";

	#Create the output directory if it does not exist
	mkdir ("$output_directory",0770) unless (-d "$output_directory");

	#Check that the output directory exists
	if(!(-e $output_directory)){
		die "ERROR: could not create directory: $output_directory\n";
		}

	print "\n--analyzing CNV data\n";
	($genome_cnv_data_hash_ref, $chromosome_copy_number_count_hash_ref, $chromosome_cnv_breakpoints_hash_ref) = analyze_cnv_data($output_directory, \@cnv_files, $bin_size, \$tp53_mutation_found);
	print "---done analyzing CNV data\n\n";

	print "--analyzing translocation data\n";
	($genome_trans_data_hash_ref, $chromosome_translocation_count_hash_ref, $genome_trans_breakpoints_hash_ref) = analyze_trans_data($output_directory, \@trans_files, $bin_size, \$tp53_mutation_found);
	print "---done analyzing translocation data\n\n";

	#If insertion data was provided then analyze it
	if(defined($insertion_directory)){
		print "--analyzing insertion data\n";
		($genome_insertion_data_hash_ref, $chromosome_insertion_count_hash_ref, $genome_trans_insertion_breakpoints_hash_ref) = analyze_insertion_data($output_directory, \@insertion_files, $bin_size, $genome_trans_breakpoints_hash_ref, \$tp53_mutation_found);
		print "---done analyzing insertion data\n\n";
		}	

	#Delete intermediate storage
	%$genome_trans_breakpoints_hash_ref = ();
	undef $genome_trans_breakpoints_hash_ref;

	#If LOH data was provided then analyze it
	if(defined($loh_directory)){
		print "--analyzing LOH data\n";
		($chromosome_loh_breakpoints_hash_ref) = analyze_loh_data($output_directory, \@loh_files, \$tp53_mutation_found);
		print "---done analyzing LOH data\n\n";

		#Check that the correct format of the LOH hash has been preserved
		my %loh_hash = %{$chromosome_loh_breakpoints_hash_ref};
		for my $key1 (keys %loh_hash){
			my @a = @{$loh_hash{$key1}};
			my $size = @a;

			if($size % 2 != 0){
				die "ERROR: odd number of loh breakpoints recorded for chromosome $key1\n";
				}
			}

		}

	print "--calculating chromosome mutation densities\n";
	$genome_mutation_density_hash_ref = calculate_genome_localization($output_directory, $chromosome_copy_number_count_hash_ref, $chromosome_translocation_count_hash_ref);
	print "---done calculating chromosome mutation densities\n\n";

	print "--calculating chromosome region mutation densities\n";
	($suspect_regions_array_ref, $likely_regions_array_ref, $genome_cnv_data_windows_hash_ref, $genome_trans_data_windows_hash_ref, $genome_mutation_data_windows_hash_ref) = calculate_chromosome_localization($output_directory, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $bin_size, $localization_window_size);
	print "---done calculating chromosome region mutation densities\n\n";

	print "--analyzing suspect regions\n";
	analyze_suspect_regions($output_directory, $suspect_regions_array_ref, $genome_mutation_density_hash_ref, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $genome_trans_insertion_breakpoints_hash_ref, $bin_size, $localization_window_size, $tp53_mutated, $tp53_mutation_found, $chromosome_cnv_breakpoints_hash_ref, $chromosome_loh_breakpoints_hash_ref);
	print "---done analyzing suspect regions\n\n";

	print "--analyzing likely regions\n";
	analyze_likely_regions($output_directory, $likely_regions_array_ref, $genome_mutation_density_hash_ref, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $bin_size, $localization_window_size);
	print "---done analyzing likely regions\n\n";

	print "--calculating copy number count\n";
	check_copy_number_count($output_directory, $chromosome_copy_number_count_hash_ref);
	print "---done calculating copy number count\n\n";

	print "--calculating switch count\n";
	check_copy_number_switches($output_directory, $chromosome_copy_number_count_hash_ref);
	print "---done calculating switch count\n\n";

	print "--calculating interchromosomal translocation rate\n";
	calculate_interchromosomal_translocation_rate($output_directory, $chromosome_translocation_count_hash_ref);
	print "---done calculating interchromosomal translocation rate\n";

	}#sub run

#=head2 Sub-Method: validate_input

### validate_input ################################################################################
# Description:
#	Validates command line arguments. Prints error messages if some input if invalid.
#
# Input variables:
#	$argv_ref:		reference to @ARGV
#	$cnv_directory_ref:	reference to variable storing the CNV input directory
#	$trans_directory_ref:	reference to variable storing the translocation input directory
#	$insertion_directory_ref:	reference to variable storing the insertion input directory
#	$loh_directory_ref:	reference to variable storing the LOH input directory
#	$tp53_mutated_ref:	reference to variable storing the tp53 mutated flag
#	$output_directory_ref:	reference to variable storing the output directory
#	$config_file_path_ref:	reference to variable storing the path to the config file

#=cut
sub validate_input {

	#Parse parameters
	my $argv_ref = shift;
	my @argv = @{$argv_ref};

	my $cnv_directory_ref = shift;
	my $trans_directory_ref = shift;
	my $insertion_directory_ref = shift;
	my $loh_directory_ref = shift;
	my $tp53_mutated_ref = shift;
	my $output_directory_ref = shift;
	my $config_file_path_ref = shift;
	
	#Determine number of command line arguements
	$ARGC = @argv;

	#Parse the command line arguements
	given ($ARGC) {
		when (/^0$/) { usage(0); }	#Print error message if no arguements were entered

		when (/^1$/) {		#Check for help option
			if($argv[0] eq "--help"){
				man_text();
				}
			else{
				usage(1);
				}
		       }#case 1

		default   {

			if($argv[$pos] eq "--cnv"){	#Check for the cnv input directory option, this field is mandatory
				next_arg(2);
				$$cnv_directory_ref = $argv[$pos];
				if(!(substr($$cnv_directory_ref,-1,1) eq '/')){
					$$cnv_directory_ref = $$cnv_directory_ref.'/';
					}
				next_arg(3);
				}
			else {
				usage(4);
				}


			if($argv[$pos] eq "--trans"){	#Check for the translocation input directory option, this field is mandatory
				next_arg(5);
				$$trans_directory_ref = $argv[$pos];
				if(!(substr($$trans_directory_ref,-1,1) eq '/')){
					$$trans_directory_ref = $$trans_directory_ref.'/';
					}
				next_arg(6);
				}
			else {
				usage(7);
				}

			if($argv[$pos] eq "--insrt"){	#Check for the insertion input directory option
				next_arg(8);
				$$insertion_directory_ref = $argv[$pos];
				if(!(substr($$insertion_directory_ref,-1,1) eq '/')){
					$$insertion_directory_ref = $$insertion_directory_ref.'/';
					}
				$insertion_data_present = 1;
				next_arg(9);
				}

			if($argv[$pos] eq "--loh"){	#Check for the LOH input directory option
				next_arg(10);
				$$loh_directory_ref = $argv[$pos];
				if(!(substr($$loh_directory_ref,-1,1) eq '/')){
					$$loh_directory_ref = $$loh_directory_ref.'/';
					}
				$LOH_data_present = 1;
				next_arg(11);
				}

			if($argv[$pos] eq "--tp53"){	#Check for the TP53 gene mutation check option
				$$tp53_mutated_ref = 1;
				next_arg(12);
				}

			if($argv[$pos] eq "--config"){	#Check for the config file option, this field is mandatory
				next_arg(13);
				$$config_file_path_ref = $argv[$pos];
				next_arg(14);
				}
			else{
				usage(15);
				}

			if($argv[$pos] eq "--output"){	#Check for the output directory option, this field is mandatory
				next_arg(16);
				$$output_directory_ref = $argv[$pos];
				if(!(substr($$output_directory_ref,-1,1) eq '/')){
					$$output_directory_ref = $$output_directory_ref.'/';
					}
				}
			else {
				usage(17);
				}

			#Check that there are no other command line arguments
			if($pos != $ARGC-1){
				usage(18);
				}
		       }#default case
		}#given ($ARGC)

	}#sub validate_input

#=head2 Sub-Method: analyze_cnv_data

### analyze_cnv_data ##############################################################################
# Description:
#	Reads data from files located in the CNV input directory and populates:
#		$genome_cnv_data_hash_ref
#		$chromosome_copy_number_count_hash_ref
#		$chromosome_cnv_breakpoints_hash_ref
#
# Input variables:
#	$output_directory:	stores the path to the output directory
#	$cnv_files_array_ref:	reference to array containing all the CNV input files
#	$bin_size:		stores the size of the bins which the chromosome will be divided into
#	$tp53_mutation_found_ref:	reference to the tp53 mutation found flag

#=cut
sub analyze_cnv_data {

	#Parse the parameters
	my $output_directory = shift;

	my $cnv_files_array_ref = shift;
	my @cnv_files = @$cnv_files_array_ref;

	my $bin_size = shift;
	my $tp53_mutation_found_ref = shift;

	my %genome_cnv_data = ();	#hash
					#key:	chromosome eg. 1,2,X,Y
					#value:	a reference to an array where each element corresponds to a bin along the 
					#	chromosome

	my @file_data;		#an array storing all the entries from every input file

	my $CURRENT_FILE;	#file handle to the current file that is open
	my $TP53_FILE;		#file handle to the TP53 CNV mutation output file

	my $line;		#stores raw line read in from file
	my @line_data;		#stores tokenized line read in from file

	my %chromosome_copy_number_count = (); 		#hash  {chr}{copy number}{count}
							#key1: chromosome eg. 1,2,X,Y
							#key2: a copy-number state eg 0,1,3,15
							#value: the number of region on key1 that have a copy number of key2	

	my %chromsome_cnv_breakpoints = (		#hash 	{chr}[start and end pairs]
					 X => [],	#key: 	chromosome eg. 1,2,X,Y
					 Y => [],	#value: an array that stored an ordered list of CNV breakpoints on key
					 1 => [],
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);

	#Read the contents of the cnv files into memory
	if($#cnv_files==-1){
		die "ERROR: no cnv files found in analyze_cnv_data\n";
		}

	foreach my $file (@cnv_files){
		#Open the file
		open ($CURRENT_FILE, "<", $file) or die "ERROR: could not open file at path $file\n";

		#Check that the file is not empty
		if(eof($CURRENT_FILE)){
			close ($CURRENT_FILE);
			die "ERROR: $file is empty\n";
			}

		#Read header line and validate
		$line = <$CURRENT_FILE>;
		chomp($line);

		#Check that the format of the header line is correct
		if(!($line =~ m/^#chr\tstart\tend\tnumber\tquality$/)){
			close ($CURRENT_FILE);
			die "ERROR: header of cnv file $file is invalid\n";
			}

		#Read all the data lines in the file
		while( !(eof($CURRENT_FILE)) ){
			#read data line
			$line = <$CURRENT_FILE>;
			chomp($line);

			#Validate the data line
			if(!($line =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])\t[0-9]+\t[0-9]+\t[0-9]+\t([0-9]+|\.)$/)){
				die "ERROR: invalid line found ($line) in file $file\n";
				}

			#Split the data line and add it to the file_data array
			@line_data = (split (/\t/,$line));

			push(@file_data,[@line_data]);
			}

		close ($CURRENT_FILE);

		}#foreach my $file (@cnv_files)

	#Check that there are no overlapping CNV regions with different copy-numbers 
	@file_data = check_for_overlaps("cnv", \@file_data);


	#Create TP53 directory and output folder
	mkdir ("$output_directory"."TP53",0770) unless (-d "$output_directory"."TP53");
	if(!(-e "$output_directory"."TP53")){
		die "ERROR: could not create folder $output_directory"."TP53\n";
		}

	#Create the TP53 CNV mutation file
	open ($TP53_FILE, ">", "$output_directory"."TP53/TP53.spc") or die "ERROR: could not create file: $output_directory"."TP53/TP53.spc";

	#Print the header of the file (same format as a .spc file)
	print $TP53_FILE "#chr\tstart\tend\tnumber\tquality";

	#For every data line that was read in from an input file,
	#record the CNV mutation in the genome_cnv_data_hash, 
	#record the exact breakpoints of the CNV, 
	#update the chromosome_copy_number_count hash and
	#check if the CNV is in the TP53 region
	for (my $n = 0; $n < scalar(@file_data); $n++){
		my $hash = {};

		#Ensure that the chromosome value is valid
		if(!($file_data[$n][0] =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])$/)){
			die "ERROR: invalid line found in CNV input file: @{$file_data[$n]}\n";
			}

		#Parse the chromosome
		my $chr = $2;

		#Increment the copy-number count hash based on the line data
		$chromosome_copy_number_count {$chr}{$file_data[$n][3]}++;

		#Record the exact breakpoints of the CNV
		push (@{$chromsome_cnv_breakpoints{$chr}}, ($file_data[$n][1],$file_data[$n][2])); 

		#Calculate the bin for the start and end breakpoint
		my $start_index = int($file_data[$n][1]/$bin_size);
		my $end_index = int($file_data[$n][2]/$bin_size);

		my $update_bin = sub {
			my $source_chr 	= shift;
			my $index 	= shift;
			my $copy_num	= shift;

			my $genome_hash_ref	= shift;
			my %genome_hash		= %{$genome_hash_ref};
		
			my $hash = ();	

			if(!defined(@{$genome_hash{$source_chr}}[$index])){
				$hash->{'BPcount'} = 1;
				$hash->{$copy_num} = 0.5;
				@{$genome_hash{$source_chr}}[$index] = $hash;
				}
			else{	#if a bin does exist then increment the counts
				${@{$genome_hash{$source_chr}}[$index]}{'BPcount'}++;
				${@{$genome_hash{$source_chr}}[$index]}{$copy_num}+=0.5;
				}
			};

		#Check if a bin exists at the start index
		#if not, create one
		if(!defined(@{$genome_cnv_data{$chr}}[$start_index])){
			$hash->{'BPcount'} = 1;
			$hash->{$file_data[$n][3]} = 0.5;
			@{$genome_cnv_data{$chr}}[$start_index] = $hash;
			}
		else{ 	#If one does exist increment the counts
			${@{$genome_cnv_data{$chr}}[$start_index]}{'BPcount'}++;
			${@{$genome_cnv_data{$chr}}[$start_index]}{$file_data[$n][3]}+=0.5;
			}

		$hash = {};

		#Check if a bin exists at the end index
		#if not, create one
		if(!defined(@{$genome_cnv_data{$chr}}[$end_index])){
			$hash->{'BPcount'} = 1;
			$hash->{$file_data[$n][3]} = 0.5;
			@{$genome_cnv_data{$chr}}[$end_index] = $hash;
			}
		else{ 	#If one does exist increment the counts
			${@{$genome_cnv_data{$chr}}[$end_index]}{'BPcount'}++;
			${@{$genome_cnv_data{$chr}}[$end_index]}{$file_data[$n][3]}+=0.5;
			}


		#Check if the variation was in the TP53 gene
		if(
		   ( $chr ne 'X' && $chr ne 'Y' ) &&
		   ( $chr==17 )
		  ){
			if(
			   ( $file_data[$n][3] != 2 ) &&
			   ( ( $file_data[$n][1] >= $TP53_start && $file_data[$n][1] <= $TP53_end ) || ( $file_data[$n][2] >= $TP53_start && $file_data[$n][2] <= $TP53_end ) )
			  ){
				#If a CNV was found in the TP53 region
				$$tp53_mutation_found_ref = 1;

				#Record the mutation in the TP53 CNV file
				print $TP53_FILE "\n";
				for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++){
					print $TP53_FILE "$file_data[$n][$i]";
					if($i != scalar(@{$file_data[$n]})-1){
						print $TP53_FILE "\t";
						}#if
					}#for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++)
				}#if
			}#if
		}#for (my $n = 0; $n < scalar(@file_data); $n++)

	close($TP53_FILE);

	#return hash
	return(\%genome_cnv_data, \%chromosome_copy_number_count, \%chromsome_cnv_breakpoints);

	}#sub analyze_cnv_data

#=head2 Sub-Method: check_for_overlaps

### check_for_overlaps ############################################################################
# Description:
#	Checks if there were overlapping CNV regions with different copy-numbers in the input files.
#	Also checks if there are any overlapping translocation destinations or overlapping LOH
#	regions.
#
# Input variables:
#	$type:		flag variable indicating which type of overlap to check for "cnv", "trans",
#			or "loh"
#	$file_data_ref:	reference to an array storing all the data lines read in from the specific
#			type of input file

#=cut
sub check_for_overlaps {

	my $type = shift;
	my $file_data_ref = shift;
	my @file_data = @$file_data_ref;

	my $start_overlap = 0;	#Flag variable indicating if the start position of one region is overlapping with 
				#another region

	my $end_overlap = 0;	#Flag variable indicating if the end position of one region is overlapping with
				#another region

	#Check for overlapping regions
	#Compares each entry in the array to every following entry
	for (my $n = 0; $n < scalar(@file_data); $n++){
		for (my $k = $n+1; $k < scalar(@file_data); $k++){

			#Check if the 2 regions in question are on the same chromosome
			if($file_data[$n][0] eq $file_data[$k][0]) {

				#Check if the end point of region 1 is within region 2	
				if($file_data[$n][2]>=$file_data[$k][1] && $file_data[$n][2]<=$file_data[$k][2]){
					$end_overlap = 1;
					}

				#Check if the start point of region 1 is within region 2
				if($file_data[$n][1]>=$file_data[$k][1] && $file_data[$n][1]<=$file_data[$k][2]){
					$start_overlap = 1;
					}

				#If an overlap was detected
				if($start_overlap==1 || $end_overlap==1) {

					#if it was a translocation overlap then throw an error
					if($type eq "trans"){
						die "ERROR: found overlapping translocation source regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#if it was a LOH overlap then throw an error
					if($type eq "loh"){
						die "ERROR: found overlapping LOH regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#if it was a CNV overlap check if the copy numbers are the same
					#If they are different throw an error
					if(
					   ( $type eq "cnv") &&
					   ( $file_data[$n][3] != $file_data[$k][3] )
					  ){
						die "ERROR: found overlapping regions with different copy number values:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#if they are the same
				 	#and the user does not wish to collapse overlapping regions with the same copy number then throw an error
					elsif ($collapse_regions==0) {
						die "ERROR: found overlapping copy number regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#if the user wishes to collapses overlapping regions with the same copy number then do so
					elsif ($collapse_regions==1) {
						#Region 2 completely encompasses region 1
						#So replace region 1 with region 2
						if($start_overlap==1 && $end_overlap==1){
							$file_data[$n][1] = $file_data[$k][1];
							$file_data[$n][2] = $file_data[$k][2];	
							}
						#The start point of region 1 is within region 2
						#So replace the start point of region 1 with the start point of region 2
						elsif($start_overlap==1){
							$file_data[$n][1] = $file_data[$k][1];
							}
						#The end point of region 1 is within region 2
						#So replace the end point of region 1 with the end point of region 2
						elsif($end_overlap==1){
							$file_data[$n][2] = $file_data[$k][2];
							}
						#If region 1 was modified then remove region 2 and re-check for overlaps
						if($start_overlap==1 || $end_overlap==1){
							@file_data = (@file_data[0..($k-1),($k+1)..(scalar(@file_data)-1)]);
							$start_overlap = 0;
							$end_overlap = 0;
							$k = $n+1;
							redo;
							}

						}#elsif ($collapse_regions==1)
					}#if($start_overlap==1 || $end_overlap==1)

				#Check if region 1 completely encompasses region 2
				elsif($file_data[$n][1]<=$file_data[$k][1] && $file_data[$n][2]>=$file_data[$k][2]){

					if($type eq "trans"){
						die "ERROR: found overlapping translocation source regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					if($type eq "loh"){
						die "ERROR: found overlapping LOH regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#If the copy numbers are different throw an error
					if(
					   ( $type eq "cnv") &&
					   ( $file_data[$n][3] != $file_data[$k][3] )
					  ){
						die "ERROR: found overlapping regions with different copy number values:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#If the copy numbers are the same but the user does not want to collapse then throw an error
					elsif ($collapse_regions==0) {
						die "ERROR: found overlapping copy number regions:\n\t@{$file_data[$n]}\n\t@{$file_data[$k]}\n";
						}

					#If the user does wish to collapse then remove the second region
					elsif ($collapse_regions==1) {
						@file_data = (@file_data[0..($k-1),($k+1)..(scalar(@file_data)-1)]);
						}
					}#elsif($file_data[$n][1]<=$file_data[$k][1] && $file_data[$n][2]>=$file_data[$k][2])
				}#if($file_data[$n][0] eq $file_data[$k][0])
			}#for (my $n = 0; $n < scalar(@file_data); $n++)
		}#for (my $n = 0; $n < scalar(@file_data); $n++)

	#Return the updated entries
	return (@file_data);

	}#sub check_for_overlaps

#=head2 Sub-Method: analyze_trans_data

### analyze_trans_data ############################################################################
# Description:
#	Reads data from files located in the trans input directory and popultates:
#		$genome_trans_data_hash_ref
#		$chromosome_translocation_count_hash_ref
#		$genome_trans_breakpoints_hash_ref		
#
# Input variables:
#	$output_directory:	stores the path to the output directory
#	$trans_files_array_ref:	reference to array containing all the translocation 
#				input files
#	$bin_size:		stores the size of the bins which the chromosome will be divided into
#	$tp53_mutation_found_ref:      reference to the tp53 mutation found flag

#=cut
sub analyze_trans_data {

	#Parse the parameters
	my $output_directory = shift;
	my $trans_files_array_ref = shift;
	my @trans_files = @$trans_files_array_ref;

	my $bin_size = shift;

	my $tp53_mutation_found_ref = shift;

	my %genome_trans_data = ();	#hash
					#key:   chromosome eg. 1,2,X,Y
					#value: a reference to an array where each element corresponds to a bin along the
					#	chromosome

	my @file_data;		#an array storing all the entries from every input file

	my $CURRENT_FILE;	#file handle to the current file that is open
	my $TP53_FILE;		#file handle to the TP53 translocation mutation output file

	my $line;		#stores raw line read in from file
	my @line_data;		#stores tokenized line read in from file

	my $chr1;
	my $chr2;

	my %chromosome_trans_count = (); 	#hash 	{chr}{chr}{count}
						#key1:	chromosome eg. 1,2,X,Y
						#key2: 	chromosome eg. 1,2,X,Y
						#value:	the number of translocations between key1 and key2

	my %genome_trans_breakpoints = 	(		#hash {chr}[array]
					 X => [],	#key:	chromosome eg. 1,2,X,Y
					 Y => [],	#value:	an array storing all the translocation breakpoints
					 1 => [],	#	on key
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);


	#Read the contents of the cnv files into memory
	if($#trans_files==-1){
		die "ERROR: no trans files found in analyze_trans_data\n";
		}

	foreach my $file (@trans_files){
		#open the file
		open ($CURRENT_FILE, "<", $file) or die "ERROR: could not open file at path $file\n";

		#check that the file is not empty
		if(eof($CURRENT_FILE)){
			close ($CURRENT_FILE);
			die "ERROR: $file is empty\n";
			}

		#read header line and validate
		$line = <$CURRENT_FILE>;
		chomp($line);

		#validate the header line
		if(!($line =~ m/^#chr1\tstart\tend\tchr2\tstart\tend\tquality$/)){
			close ($CURRENT_FILE);
			die "ERROR: header of translocation file $file is invalid\n";
			}

		#read in every data line
		while( !(eof($CURRENT_FILE)) ){
			#read data line
			$line = <$CURRENT_FILE>;
			chomp($line);

			#validate the format of the data line
			if(!($line =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])\t[0-9]+\t[0-9]+\t(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])\t[0-9]+\t[0-9]+\t([0-9]+|\.)$/)){
				die "ERROR: invalid line found in translocation input file: ($line) in file $file\n";
				next;
				}

			#Split the data line and add it to the array
			@line_data = (split (/\t/,$line));

			#if the start position is  greater than the end position for either the source or destination throw an error
			if(
			   ( $line_data[1] >= $line_data[2] ) ||
			   ( $line_data[4] >= $line_data[5] )
			  ){
				#warn "ERROR: invalid line found ($line) in file $file. Start or end values invalid\n";
				#next;
				}

			#Add the data line to the file_data array
			push(@file_data,[@line_data]);
			}

		close ($CURRENT_FILE);

		}#foreach my $file (@trans_files)

	#ignoring overlapping translocations for now
	#@file_data = check_for_overlaps("trans", \@file_data);

	#Create TP53 directory and output folder
	mkdir ("$output_directory"."TP53",0770) unless (-d "$output_directory"."TP53");
	if(!(-e "$output_directory"."TP53")){
		die "ERROR: could not create folder $output_directory"."TP53\n";
		}

	#create TP53 translocation mutation file
	open ($TP53_FILE, ">", "$output_directory"."TP53/TP53.spt") or die "ERROR: could not create file: $output_directory"."TP53/TP53.spt";
	
	#Print the header of the file (same format as a .spt file)
	print $TP53_FILE "#chr1\tstart\tend\tchr2\tstart\tend\tquality";

	#For every data line that was read in from an input file,
	#record the translocation mutation in the genome_trans_data_hash, 
	#record the exact breakpoints of the translocation, 
	#update the chromosome_trans_count hash and
	#check if the translocation is in the TP53 region
	for (my $n = 0; $n < scalar(@file_data); $n++){
		
		my $hash = {};

		#verify that the chromosome 1 is valid
		if(!($file_data[$n][0] =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])$/)){
			die "ERROR: invalid chromosome field detected in translocation file\n";
			}

		#parse out chromosome 1
		my $chr1 = $2;

		#verify that the chromosome 2 is valid
		if(!($file_data[$n][3] =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])$/)){
			die "ERROR: invalid chromosome field detected in translocation file\n";
			}

		#parse out chromosome 2
		my $chr2 = $2;

		#calculate the bin where each breakpoint will be placed
		my $start_index1 = int($file_data[$n][1]/$bin_size);
		my $end_index1 = int($file_data[$n][2]/$bin_size);

		my $start_index2 = int($file_data[$n][4]/$bin_size);
		my $end_index2 = int($file_data[$n][5]/$bin_size);

		my $update_bin = sub {
			my $source_chr 	= shift;
			my $dest_chr	= shift;
			my $index 	= shift;
			my $data	= shift;
			my $type	= shift;

			my $genome_hash_ref	= shift;
			my %genome_hash		= %{$genome_hash_ref};
		
			my $hash = ();	

			if(!defined(@{$genome_hash{$source_chr}}[$index])){
				$hash->{'BPcount'} = 1;
				push (@{$hash->{$type}{$dest_chr}}, $data);
				@{$genome_hash{$source_chr}}[$index] = $hash;
				}
			else{	#if a bin does exist then increment the counts
				${@{$genome_hash{$source_chr}}[$index]}{'BPcount'}++;
				push (@{${@{$genome_hash{$source_chr}}[$index]}{$type}{$dest_chr}}, $data);
				}

			};

		#check if a bin exists at $start_index1
		#if not, create one
		if(!defined(@{$genome_trans_data{$chr1}}[$start_index1])){
			$hash->{'BPcount'} = 1;
			push (@{$hash->{'out'}{$chr2}}, $file_data[$n][4]);
			@{$genome_trans_data{$chr1}}[$start_index1] = $hash;
			}
		else{	#if a bin does exist then increment the counts
			${@{$genome_trans_data{$chr1}}[$start_index1]}{'BPcount'}++;
			push (@{${@{$genome_trans_data{$chr1}}[$start_index1]}{'out'}{$chr2}}, $file_data[$n][4]);
			}

		$hash = {};
		if(!defined(@{$genome_trans_data{$chr1}}[$end_index1])){
			$hash->{'BPcount'} = 1;
			push (@{$hash->{'out'}{$chr2}}, $file_data[$n][5]);
			@{$genome_trans_data{$chr1}}[$end_index1] = $hash;
			}
		else{
			${@{$genome_trans_data{$chr1}}[$end_index1]}{'BPcount'}++;
			push (@{${@{$genome_trans_data{$chr1}}[$end_index1]}{'out'}{$chr2}}, $file_data[$n][5]);
			}

		$hash = {};
		if(!defined(@{$genome_trans_data{$chr2}}[$start_index2])){
			$hash->{'BPcount'} = 1;
			push (@{$hash->{'in'}{$chr1}}, $file_data[$n][1]);
			@{$genome_trans_data{$chr2}}[$start_index2] = $hash;
			}
		else{
			${@{$genome_trans_data{$chr2}}[$start_index2]}{'BPcount'}++;
			push (@{${@{$genome_trans_data{$chr2}}[$start_index2]}{'in'}{$chr1}}, $file_data[$n][1]);
			}

		$hash = {};
		if(!defined(@{$genome_trans_data{$chr2}}[$end_index2])){
			$hash->{'BPcount'} = 1;
			push (@{$hash->{'in'}{$chr1}}, $file_data[$n][2]);
			@{$genome_trans_data{$chr2}}[$end_index2] = $hash;
			}
		else{
			${@{$genome_trans_data{$chr2}}[$end_index2]}{'BPcount'}++;
			push (@{${@{$genome_trans_data{$chr2}}[$end_index2]}{'in'}{$chr1}}, $file_data[$n][2]);
			}
	
		#Increment hash translocation counts
		$chromosome_trans_count{$chr1}{$chr2}++;
		#if the translocation is intra-chromosomal then don't count it twice
		if($chr1 ne $chr2){
			$chromosome_trans_count{$chr2}{$chr1}++;
			}

		#store the breakpoints in their bins
		push (@{$genome_trans_breakpoints{$chr1}}, $file_data[$n][1]);
		push (@{$genome_trans_breakpoints{$chr1}}, $file_data[$n][2]);

		push (@{$genome_trans_breakpoints{$chr2}}, $file_data[$n][4]);
		push (@{$genome_trans_breakpoints{$chr2}}, $file_data[$n][5]);

		#Check if the translocation origin was in the TP53 gene
		if(
		   ( $chr1 ne 'X' && $chr1 ne 'Y' ) &&
		   ( $chr1==17 )
		  ){
			if(
			   ( ( $file_data[$n][1] >= $TP53_start && $file_data[$n][1] <= $TP53_end ) || ( $file_data[$n][2] >= $TP53_start && $file_data[$n][2] <= $TP53_end ) )
			  ){
				#if a mutation was found, set the TP53 mutated flag
				$$tp53_mutation_found_ref = 1;
				print $TP53_FILE "\n";
				#print the translocation data line to the TP53 translocation mutation output file
				for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++){
					print $TP53_FILE "$file_data[$n][$i]";
					if($i != scalar(@{$file_data[$n]})-1){
						print $TP53_FILE "\t";
						}
					}#for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++)
				}#if
			}#if

		#Check if the translocation destination was in the TP53 gene
		if(
		   ( $chr2 ne 'X' && $chr2 ne 'Y' ) &&
		   ( $chr2==17 )
		  ){
			if(
			   ( ( $file_data[$n][4] >= $TP53_start && $file_data[$n][4] <= $TP53_end ) || ( $file_data[$n][5] >= $TP53_start && $file_data[$n][5] <= $TP53_end ) )
			  ){
				$$tp53_mutation_found_ref = 1;
				print $TP53_FILE "\n";
				for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++){
					print $TP53_FILE "$file_data[$n][$i]";
					if($i != scalar(@{$file_data[$n]})-1){
						print $TP53_FILE "\t";
						}
					}#for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++)
				}#if
			}#if
		}#for (my $n = 0; $n < scalar(@file_data); $n++)

	close($TP53_FILE);

	#return hash
	return(\%genome_trans_data, \%chromosome_trans_count, \%genome_trans_breakpoints);

	}#sub analyze_trans_data


#=head2 Sub-Method: analyze_insertion_data

### analyze_insertion_data ##############################################################################
# Description:
#	Reads data from files located in the insertion input directory and populates:
#		$genome_insertion_data_hash_ref
#		$chromosome_insertion_count_hash_ref
#		$genome_trans_insertion_breakpoints_hash_ref	
#
# Input variables:
#	$output_directory:			stores the path to the output directory
#	$insertion_files_array_ref:		reference to array containing all the insertion input files
#	$bin_size:				stores the size of the bins which the chromosome will be divided into
#	$genome_trans_breakpoints_hash_ref:	store reference to hash that contains the translocation breakpoints on
#						each chromosome
#	$tp53_mutation_found_ref:      		reference to the tp53 mutation found flag
#

#=cut 
sub analyze_insertion_data {

	#Parse Parameters
	my $output_directory = shift;
	my $insertion_files_array_ref = shift;
	my @insertion_files = @$insertion_files_array_ref;

	my $bin_size = shift;

	my $genome_trans_breakpoints_hash_ref = shift;
	my %genome_trans_breakpoints = %$genome_trans_breakpoints_hash_ref;

	my $tp53_mutation_found_ref = shift;

	my %genome_insertion_data = ();	#hash
					#key:   chromosome eg. 1,2,X,Y
					#value: a reference to an array where each element corresponds to a bin along the
					#	chromosome

	my $CURRENT_FILE;	#file handle to the current file that is open
	my $TP53_FILE;		#file handle to the TP53 insertion mutation output file

	my $line;		#stores raw line read in from file
	my @line_data;		#stores tokenized line read in from file

	my $chr;

	my $file_name;
	my $path;
	my $suffix;

	my $rm_insertion_file_result;

	my $insertion_found = 0;

	my %chromosome_insertion_count = (); 	#hash {chr}{count}
						#key: chromosome eg. 1,2,X,Y
						#value: the number of insertions found on key

	my %genome_trans_insertion_breakpoints = (	#hash
					 X => [],	#key:	chromosome eg. 1,2,X,Y
					 Y => [],	#value: an array storing all the insertion start positions on key
					 1 => [],
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);

	#Create TP53 directory and output folder
	mkdir ("$output_directory"."TP53",0770) unless (-d "$output_directory"."TP53");
	if(!(-e "$output_directory"."TP53")){
		die "ERROR: could not create folder $output_directory"."TP53\n";
		}

	#for each file in the insertion input file array
	foreach my $file (@insertion_files){

		#Parse the file name, path and file type
		( $file_name, $path, $suffix ) = File::Basename::fileparse( $file, "\.[^.]*");

		#open the file
		open ($CURRENT_FILE, "<", $file) or die "ERROR: could not open file at path $file\n";

		#ensure that the file is not empty
		if(eof($CURRENT_FILE)){
			die "ERROR: $file is empty\n";
			}

		#create the TP53 insertion mutation output file
		open ($TP53_FILE, ">", "$output_directory"."TP53/$file_name"."$suffix") or die "ERROR: could not create file: $output_directory"."TP53/$file_name"."$suffix";

		#read header lines
		$line = <$CURRENT_FILE>;
		chomp($line);

		#print the VCF header lines to the TP53 insertion mutation output file
		while ($line =~ m/^#(.*?)/){ 
			print $TP53_FILE "$line\n";
			$line = <$CURRENT_FILE>;
			chomp($line);
			}

		#read all the data lines in the file
		while(1){
			@line_data = (split (/\t/,$line));

			#verify that the chromosome is valid and that the mutation is an insertion type
			if(
			   ( !($line_data[1] =~ m/^[0-9]+$/) 				 ) ||
			   ( !($line_data[0] =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|x|y|[1-9])/) ) ||
			   ( length($line_data[4]) <= length($line_data[3])		 )
			  ){
				warn "ERROR: invalid chromosome or non-insertion VCF data line found and skipped:\t$line\n";
				$line = <$CURRENT_FILE>;
				unless($line){last;}
				chomp($line);
				next;
				}

			#parse the chromosome
			$chr = $2;

			#change to uppercase if 'x' or 'y' is found
			if($chr eq 'x'){
				$chr = 'X';
				}
			if($chr eq 'y'){
				$chr = 'Y';
				}

			#increment the insertion count of the chromosome	
			$chromosome_insertion_count{$chr}++;

			#check if a bin exists at the insertion start position
			#if one does not, then create one
			if(!defined(@{$genome_insertion_data{$chr}}[int($line_data[1]/$bin_size)])){
				${$genome_insertion_data{$chr}}[int($line_data[1]/$bin_size)] = 1;
				}
			else{	#if one does, then increment the count
				${$genome_insertion_data{$chr}}[int($line_data[1]/$bin_size)]++;
				}

			#Search through the list of translocation breakpoints on the same chromosome
			foreach my $bp (@{$genome_trans_breakpoints{$chr}}){
				#if the insertion is within 10bps of the breakpoints and the insertion to the list stored in
				#the genome_trans_insertion_breakpoints hash
				if( $line_data[1] < $bp+10 && $line_data[1] > $bp-10){
					push (@{$genome_trans_insertion_breakpoints{$chr}}, $bp);
					}
				}

			#Check if the insertion was in the TP53 gene
			if(
			   ( $chr ne 'X' && $chr ne 'Y' ) &&
			   ( $chr==17 )
			  ){
				if($line_data[1] >= $TP53_start && $line_data[1] <= $TP53_end){
					$$tp53_mutation_found_ref = 1; #if a mutation was found in the region set the TP53 mutated flag
					$insertion_found = 1;
					print $TP53_FILE "$line\n"; 	#print the culprit data line to the TP53 insertion 
									#mutation output file
					}
				}

			#read the next line
			$line = <$CURRENT_FILE>;
			#check that the end of file has not been reached
			unless($line){last;}
			chomp($line);
			}#while(1)

		#close file
		close($CURRENT_FILE);
		close ($TP53_FILE);

		#if an insertion was not found in the current file then delete the created TP53 insertion mutation output file
		if($insertion_found!=1){
			my $dir = "$output_directory"."TP53/$file_name"."$suffix";
			$rm_insertion_file_result = `rm $dir`;
			}

		$insertion_found = 0;
		}#foreach my $file (@insertion_files)

	#return hash
	return(\%genome_insertion_data, \%chromosome_insertion_count, \%genome_trans_insertion_breakpoints);

	}#sub analyze_insertion_data


#=head2 Sub-Method: analyze_loh_data

### analyze_loh_data ##############################################################################
# Description:
#	Reads data from files located in the LOH input directory and populates:
#		$chromosome_loh_breakpoints_hash_ref	
#
# Input variables:
#	$output_directory:	stores the path to the output directory
#	$loh_files_array_ref:	reference to array containing all the LOH input files
#	$tp53_mutation_found_ref: reference to tp53 mutation found flag
#

#=cut

sub analyze_loh_data {

	#parse the parameters
	my $output_directory = shift;
	my $loh_files_array_ref = shift;
	my @loh_files = @$loh_files_array_ref;

	my $tp53_mutation_found_ref = shift;

	my @file_data;	#an array storing all the entries from every input file

	my $CURRENT_FILE;	#file handle to the current file that is open
	my $TP53_FILE;		#file handle to the TP53 translocation mutation output file

	my $line;		#stores raw line read in from file
	my @line_data;		#stores tokenized line read in from files

	my %chromsome_loh_breakpoints = (		#hash {chr}[start and end pairs]
					 X => [],	#key: 	chromosome eg. 1,2,X,Y
					 Y => [],	#value:	an array that stores all the LOH breakpoints on key
					 1 => [],
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);

	#Read the contents of the cnv files into memory
	foreach my $file (@loh_files){
		#open the file
		open ($CURRENT_FILE, "<", $file) or die "ERROR: could not open file at path $file\n";

		#Ensure that the file is not empty
		if(eof($CURRENT_FILE)){
			close ($CURRENT_FILE);
			die "ERROR: $file is empty\n";
			}

		#read header line and validate
		$line = <$CURRENT_FILE>;
		chomp($line);

		#Validate the header line
		if(!($line =~ m/^#chr\tstart\tend\tquality$/)){
			close ($CURRENT_FILE);
			die "ERROR: header of loh file $file is invalid\n";
			}

		#Read all the data lines
		while( !(eof($CURRENT_FILE)) ){
			
			#read data line
			$line = <$CURRENT_FILE>;
			chomp($line);

			#validate the data line
			if(!($line =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])\t[0-9]+\t[0-9]+\t([0-9]+|\.)$/)){
				die "ERROR: invalid line found ($line) in file $file\n";
				}

			#Split the data line and add it to the array
			@line_data = (split (/\t/,$line));
			push(@file_data,[@line_data]);
			}

		close ($CURRENT_FILE);

		}#foreach my $file (@cnv_files)

	#Ensure that there are no overlapping LOH regions, or join them if the user indicated
	@file_data = check_for_overlaps("loh", \@file_data);

	#Create TP53 directory and output folder
	mkdir ("$output_directory"."TP53",0770) unless (-d "$output_directory"."TP53");
	if(!(-e "$output_directory"."TP53")){
		die "ERROR: could not create folder $output_directory"."TP53\n";
		}

	#Create the TP53 LOH mutation output data file
	open ($TP53_FILE, ">", "$output_directory"."TP53/TP53.spl") or die "ERROR: could not create file: $output_directory"."TP53/TP53.spl";
	#Print the header for the output file (same format as a .spl file)
	print $TP53_FILE "#chr\tstart\tend\tquality";

	#For every data line that was read in
	for (my $n = 0; $n < scalar(@file_data); $n++){

		#Validate the chromosome field
		if(!($file_data[$n][0] =~ m/^(chr)?(1[0-9]|2[0-2]|X|Y|[1-9])$/)){
			die "ERROR: invalid chromosome field detected\n";
			}

		#Parse the chromosome
		my $chr = $2;

		#Add the breakpoints to the array for the chromosome
		push (@{$chromsome_loh_breakpoints{$chr}}, ($file_data[$n][1],$file_data[$n][2])); 


		#Check if the variation was in the TP53 gene
		if(
		   ( $chr ne 'X' && $chr ne 'Y' ) &&
		   ( $chr==17 )
		  ){
			if(
			   ( ( $file_data[$n][1] >= $TP53_start && $file_data[$n][1] <= $TP53_end ) || ( $file_data[$n][2] >= $TP53_start && $file_data[$n][2] <= $TP53_end ) )
			  ){
				#If a mutation was found in the TP53 region then set the TP53 mutated flag
				$$tp53_mutation_found_ref = 1;

				#Print the LOH data line to the TP53 LOH mutation output file
				print $TP53_FILE "\n";
				for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++){
					print $TP53_FILE "$file_data[$n][$i]";
					if($i != scalar(@{$file_data[$n]})-1){
						print $TP53_FILE "\t";
						}#if
					}#for (my $i = 0; $i < scalar(@{$file_data[$n]}); $i++)
				}#if
			}#if

		}#for (my $n = 0; $n < scalar(@file_data); $n++)

	close($TP53_FILE);

	#return hash
	return(\%chromsome_loh_breakpoints);

	}#sub analyze_loh_data



#=head2 Sub-Method: calculate_genome_localization

### calculate_genome_localization #################################################################
# Description:
#	Caculates the mutation density for each chromosome	
#
# Input variables:
#	$output_directory:			  stores the path to the output directory
#	$chromosome_copy_number_count_hash_ref:	  stores a reference to the hash storing the number 
#						  of CNV events on each chromosome
#	#chromosome_translocation_count_hash_ref: stores a reference to the hash storing the number
#						  of translocation events on each chromosome
#

#=cut

sub calculate_genome_localization {

	#parse the parameters
	my $output_directory = shift;
	my $chromosome_copy_number_count_hash_ref = shift;
	my $chromosome_translocation_count_hash_ref = shift;

	my %chromosome_mutation_count;	#hash
					#key:	chromosome eg. 1,2,X,Y
					#value: the density of translocation and CNV events on key 
	
	my $density;	#store the mutation density for a chromosome

	my $OUTPUT_FILE;	#file handle to the output file

	#initialize all the counts to 0
	for (my $i=1; $i<23; $i++){
		$chromosome_mutation_count{$i} = 0;
		}
	$chromosome_mutation_count{'X'} = 0;
	$chromosome_mutation_count{'Y'} = 0;

	#add the number of CNV events on each chromosome
	for my $cnv_key1 ( keys %$chromosome_copy_number_count_hash_ref){
		for my $cnv_key2 (keys %{$chromosome_copy_number_count_hash_ref->{$cnv_key1}}){
			$chromosome_mutation_count{$cnv_key1} += $chromosome_copy_number_count_hash_ref->{$cnv_key1}->{$cnv_key2};
			}
		}	
	
	#add the number of translocation events on each chromosome
	for my $trans_key1 ( keys %$chromosome_translocation_count_hash_ref){
		for my $trans_key2 (keys %{$chromosome_translocation_count_hash_ref->{$trans_key1}}){
			$chromosome_mutation_count{$trans_key1} += $chromosome_translocation_count_hash_ref->{$trans_key1}->{$trans_key2};
			}
		}	

	#Create the output file
	open ($OUTPUT_FILE, ">", "$output_directory/genome_localization.log") or die "ERROR: could not create file $output_directory/genome_localization.log\n";
	#Print the header
	print $OUTPUT_FILE "#chr\tcount\tdensity\n";

	#for each chromosome print the count and overall density
	{use sort 'stable';
	for my $chr ( sort keys %chromosome_mutation_count){
			$density = $chromosome_mutation_count{$chr}/$chromosome_length{$chr};
			
			print $OUTPUT_FILE "$chr";
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE $chromosome_mutation_count{$chr};
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE "$density";
			print $OUTPUT_FILE "\n";

			#Replace the count with the density
			$chromosome_mutation_count{$chr} = $density;
			}	
	}#use sort 'stable'

	close ($OUTPUT_FILE);

	#return the hash containing the densities
	return(\%chromosome_mutation_count);

	}#sub calculate_genome_localization


#=head2 Sub-Method: calculate_chromosome_localization

### calculate_chromosome_localization #############################################################
# Description:
#	Performs a sliding window analysis on the CNV and translocation data. Identifies regions
#	that have a density of mutation much greater than the average rate of mutation of the
#	genome.
#
# Input variables:
#	$output_directory:		stores the directory where output files are created
#	$genome_cnv_data_hash_ref:	reference to hash that stores position of all CNV breakpoints in 
#					the genome
#	$genome_trans_data_hash_ref:	reference to hash that stores position of all the
#					translocation breakpoints in the genome	
#	$bin_size:			size of the bins that divide up the genome
#	$window_size:			number of bins to evaluate in each window
#

#=cut 
sub calculate_chromosome_localization {

	#parse parameters
	my $output_directory = shift;
	my $genome_cnv_data_hash_ref = shift;
	my $genome_trans_data_hash_ref = shift;
	my $bin_size = shift;
	my $window_size = shift;

	my @suspect_regions;	#array storing the start position, end position and chromosome
				#of very highly mutated regions
	my @likely_regions;	#array storing the start position, end position and chromosome
				#of somewhat highly mutated regions

	my $in_suspect_region = 0;	#flag variables used in identifying highly mutated regions
	my $in_likely_region = 0;

	my $suspect_chr = -1;
	my $suspect_start = -1;
	my $suspect_end = -1;
	
	my $likely_chr = -1;
	my $likely_start = -1;
	my $likely_end = -1;

	my %genome_cnv_data_windows = 	(		#hash
					 X => [],	#key: chromosome eg. 1,2,X,Y
					 Y => [],	#value: an array storing the count of CNVs
					 1 => [],	#	in each window along the chromosome
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);

	my %genome_trans_data_windows = (		#hash
					 X => [],	#key:	chromosome eg. 1,2,X,Y
					 Y => [],	#value:	an array storing a count of translocation
					 1 => [],	#	in each window along the chromosome
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);

	my %genome_mutation_data_windows = (		#hash
					 X => [],	#key:	chromosome eg. 1,2,X,Y
					 Y => [],	#value:	an array storing a count of all mutations
					 1 => [],	#	in each window along the chromosome
					 2 => [],
					 3 => [],
					 4 => [],
					 5 => [],
					 6 => [],
					 7 => [],
					 8 => [],
					 9 => [],
					 10 => [],
					 11 => [],
					 12 => [],
					 13 => [],
					 14 => [],
					 15 => [],
					 16 => [],
					 17 => [],
					 18 => [],
					 19 => [],
					 20 => [],
					 21 => [],
					 22 => []
					);


	my $current_chr;		#current chromosome being analyzed
	my @current_chr_data = ();	#array storing the bins for the current chromosome

	my $genome_mean_mutation_density = 0;	#average density of all the windows across the genome
	my $total_genome_windows = 0;		#total number of windows across the genome
	my $genome_mutation_density_standard_deviation = 0;	#standard deviation of the mutation densities for
								#all the windows

	my $OUTPUT_FILE;	#file handle to output file

	$output_directory = $output_directory."mutation_clustering";

	#create output directories
	mkdir ("$output_directory",0770) unless (-d "$output_directory");
	if(!(-e "$output_directory")){
		die "ERROR: could not create folder $output_directory\n";
		}

	mkdir ("$output_directory/cnv",0770) unless (-d "$output_directory/cnv");
	if(!(-e "$output_directory")){
		die "ERROR: could not create folder $output_directory/cnv\n";
		}
	
	mkdir ("$output_directory/translocations",0770) unless (-d "$output_directory/translocations");
	if(!(-e "$output_directory")){
		die "ERROR: could not create folder $output_directory/translocations\n";
		}

	mkdir ("$output_directory/all_types",0770) unless (-d "$output_directory/all_types");
	if(!(-e "$output_directory")){
		die "ERROR: could not create folder $output_directory/all_types\n";
		}

	#compute the density of CNV mutations in each window
	for my $cnv_key ( keys %$genome_cnv_data_hash_ref){
		#get the array storing the CNV bins for the current chromosome
		@current_chr_data = @{$genome_cnv_data_hash_ref->{$cnv_key}};

		#check that the array is not empty
		if(scalar(@current_chr_data) > 0){

			#create an output file for this chromosome
			open ($OUTPUT_FILE, ">", "$output_directory/cnv/chr$cnv_key"."_cnv_localization.log") or die "ERROR: could not create file $output_directory/cnv/chr$cnv_key"."_cnv_localization.log";
			#print the header for the output file
			print $OUTPUT_FILE "#chr\tstart\tend\tdensity";

			@{$genome_cnv_data_windows{$cnv_key}}[0] = 0;	#initialize the count in the first window

			#Calculate the mutation count in the first window
			for(my $chr_pos = 0; $chr_pos < $window_size; $chr_pos++){
				my %region_hash;
				if(!defined($current_chr_data[$chr_pos])){
					next;
					}
				%region_hash = %{$current_chr_data[$chr_pos]};

				@{$genome_cnv_data_windows{$cnv_key}}[0] += $region_hash{'BPcount'};
				}

			#print the values from the first window to the output file
			print $OUTPUT_FILE "\n";
			print $OUTPUT_FILE "$cnv_key";
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE "0";
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE ($window_size)*$bin_size;
			print $OUTPUT_FILE "\t";

			if(!defined(@{$genome_cnv_data_windows{$cnv_key}}[0])){
				print $OUTPUT_FILE "0";
				}
			else{
				my $rounded = POSIX::ceil((@{$genome_cnv_data_windows{$cnv_key}}[0])/2);
				print $OUTPUT_FILE ($rounded)/($window_size*$bin_size);
				#add the cnv count to the total mutation count for the region
				@{$genome_mutation_data_windows{$cnv_key}}[0] += $rounded;
				}

			#perform the sliding window analysis for the rest of the chromosome
			for(my $chr_pos = 1; $chr_pos < scalar(@current_chr_data); $chr_pos++){

				#check that the window will not overshoot the length of the chromosome			
				if( (($chr_pos+($window_size-1))*$bin_size) > $chromosome_length{$cnv_key}  ){
					last;
					}

				@{$genome_cnv_data_windows{$cnv_key}}[$chr_pos] = 0;	#initialize the count for the current window

				my %past_region_hash;
				my %next_region_hash;

				my $prev_value = 0;
				my $next_value = 0;

				#get the count of the from the first bin from the previous window
				if(defined($current_chr_data[$chr_pos-1])){
					%past_region_hash = %{$current_chr_data[$chr_pos-1]};
					$prev_value = $past_region_hash{'BPcount'};
					}

				#get the count from the bin following the last bin in the previous window
				if(defined($current_chr_data[$chr_pos+($window_size-1)])){
					%next_region_hash = %{$current_chr_data[$chr_pos+($window_size-1)]};
					$next_value = $next_region_hash{'BPcount'};	
					}

				#the count for the current window = the count from the previous window - the first bin of the previous window + the next bin along the chromosome
				@{$genome_cnv_data_windows{$cnv_key}}[$chr_pos] += (@{$genome_cnv_data_windows{$cnv_key}}[$chr_pos-1]) - ($prev_value) + ($next_value);

				#print the values for this window
				print $OUTPUT_FILE "\n";
				print $OUTPUT_FILE "$cnv_key";
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE $chr_pos*$bin_size;
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE ($chr_pos+$window_size)*$bin_size;
				print $OUTPUT_FILE "\t";

				if(!defined(@{$genome_cnv_data_windows{$cnv_key}}[$chr_pos])){
					print $OUTPUT_FILE "0";
					}
				else{
					my $rounded = POSIX::ceil((@{$genome_cnv_data_windows{$cnv_key}}[$chr_pos])/2);
					print $OUTPUT_FILE ($rounded)/($window_size*$bin_size);
					#add the cnv count to the total mutation count for the region
					@{$genome_mutation_data_windows{$cnv_key}}[$chr_pos] += $rounded;
					}
				}#for(my $chr_pos = 1; $chr_pos < scalar(@current_chr_data); $chr_pos++)

			close ($OUTPUT_FILE);
			}#if(scalar(@current_chr_data) > 0)

		@current_chr_data = ();
		}#for my $cnv_key ( keys %$genome_cnv_data_hash_ref)

	#perform the sliding window analysis on the translocation mutation data
	for my $trans_key ( keys %$genome_trans_data_hash_ref){

		#get the array storing the translocation bins for the current chromosome	
		@current_chr_data = @{$genome_trans_data_hash_ref->{$trans_key}};

		#check that the array is not empty
		if(scalar(@current_chr_data) > 0){

			#create the output file
			open ($OUTPUT_FILE, ">", "$output_directory/translocations/chr$trans_key"."_translocation_localization.log") or die "ERROR: could not create file $output_directory/translocations/chr$trans_key"."_translocation_localization.log";
			#print the header for the output file
			print $OUTPUT_FILE "#chr\tstart\tend\tdensity";

			#initialize the translocation count for the first window
			@{$genome_trans_data_windows{$trans_key}}[0] = 0;

			#calculate the translocation mutation count in the first window
			for(my $chr_pos = 0; $chr_pos < $window_size; $chr_pos++){
				my %region_hash;
				if(!defined($current_chr_data[$chr_pos])){
					next;
					}
				%region_hash = %{$current_chr_data[$chr_pos]};

				my %trans_hash_in;
				my %trans_hash_out;
				my $size = 0;

				#calculate the number of inbound translocation breakpoints
				if(defined($region_hash{'in'})){
					%trans_hash_in = %{$region_hash{'in'}};

					for my $key (keys %trans_hash_in){
						$size = @{$trans_hash_in{$key}};
						$size = $size/2;
						@{$genome_trans_data_windows{$trans_key}}[0] += $size;
						}
					}

				#calculate the number of outbound translocation breakpoints
				if(defined($region_hash{'out'})){
					%trans_hash_out = %{$region_hash{'out'}};

					for my $key (keys %trans_hash_out){
						if($key eq $trans_key){
							next;
							}
						$size = @{$trans_hash_out{$key}};
						$size = $size/2;
						@{$genome_trans_data_windows{$trans_key}}[0] += $size;
						}
					}

				}#for(my $chr_pos = 0; $chr_pos < $window_size; $chr_pos++)

			#print the values from the first window to the output file	
			print $OUTPUT_FILE "\n";
			print $OUTPUT_FILE "$trans_key";
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE "0";
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE ($window_size)*$bin_size;
			print $OUTPUT_FILE "\t";

			if(!defined(@{$genome_trans_data_windows{$trans_key}}[0])){
				print $OUTPUT_FILE "0";
				}
			else{
				my $rounded = POSIX::ceil(@{$genome_trans_data_windows{$trans_key}}[0]);
				print $OUTPUT_FILE ($rounded)/($window_size*$bin_size);
				#add the translocation mutation count to the total mutation count for the region
				@{$genome_mutation_data_windows{$trans_key}}[0] += $rounded;
				}

			#perform the sliding window analysis for the rest of the chromosome
			for(my $chr_pos = 1; $chr_pos < scalar(@current_chr_data); $chr_pos++){

				if( (($chr_pos+($window_size-1))*$bin_size) > $chromosome_length{$trans_key} ){
					last;
					}

				@{$genome_trans_data_windows{$trans_key}}[$chr_pos] = 0;
				my %prev_region_hash;
				my %next_region_hash;

				my $prev_value = 0;
				my $next_value = 0;

				#Caculate the number of mutations in the first bin of the previous window
				if(defined($current_chr_data[$chr_pos-1])){
					%prev_region_hash = %{$current_chr_data[$chr_pos-1]};

					my $size = 0;
					my %prev_trans_hash_in;
					my %prev_trans_hash_out;

					if(defined($prev_region_hash{'in'})){
						%prev_trans_hash_in = %{$prev_region_hash{'in'}};

						for my $key (keys %prev_trans_hash_in){
							$size = @{$prev_trans_hash_in{$key}};
							$size = $size/2;
							$prev_value += $size;
							}
					}

					if(defined($prev_region_hash{'out'})){
						%prev_trans_hash_out = %{$prev_region_hash{'out'}};

						for my $key (keys %prev_trans_hash_out){
							if($key eq $trans_key){
								next;
								}
							$size = @{$prev_trans_hash_out{$key}};
							$size = $size/2;
							$prev_value += $size;
							}
						}

					}

				#Caculate the number of mutations in the last bin of the current window
				if(defined($current_chr_data[$chr_pos+($window_size-1)])){
					%next_region_hash = %{$current_chr_data[$chr_pos+($window_size-1)]};

					my $size = 0;
					my %next_trans_hash_in;
					my %next_trans_hash_out;

					if(defined($next_region_hash{'in'})){
						%next_trans_hash_in = %{$next_region_hash{'in'}};

						for my $key (keys %next_trans_hash_in){
							$size = @{$next_trans_hash_in{$key}};
							$size = $size/2;
							$next_value += $size;
							}
					}

					if(defined($next_region_hash{'out'})){
						%next_trans_hash_out = %{$next_region_hash{'out'}};

						for my $key (keys %next_trans_hash_out){
							if($key eq $trans_key){
								next;
								}
							$size = @{$next_trans_hash_out{$key}};
							$size = $size/2;
							$next_value += $size;
							}
						}


					}

				#total number of translocation mutations in the current window = number of mutations in previous window - the first bin of the previous window + next bin along the chromosome
				@{$genome_trans_data_windows{$trans_key}}[$chr_pos] += (@{$genome_trans_data_windows{$trans_key}}[$chr_pos-1]) - ($prev_value) + ($next_value);

				#print values from this window
				print $OUTPUT_FILE "\n";
				print $OUTPUT_FILE "$trans_key";
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE $chr_pos*$bin_size;
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE ($chr_pos+$window_size)*$bin_size;
				print $OUTPUT_FILE "\t";

				if(!defined(@{$genome_trans_data_windows{$trans_key}}[$chr_pos])){
					print $OUTPUT_FILE "0";
					}
				else{
					my $rounded = POSIX::ceil(@{$genome_trans_data_windows{$trans_key}}[$chr_pos]);
					print $OUTPUT_FILE ($rounded)/($window_size*$bin_size);
					@{$genome_mutation_data_windows{$trans_key}}[$chr_pos] += $rounded;
					}
				}#for(my $chr_pos = 1; $chr_pos < scalar(@current_chr_data); $chr_pos++)


			close ($OUTPUT_FILE);
			}
		@current_chr_data = ();
		}

	#calculate the density of both types of mutations in each window in the genome
	for my $mutation_key ( keys %genome_mutation_data_windows){
	
		#check that some data exisits for the current chromosome
		if(scalar(@{$genome_mutation_data_windows{$mutation_key}}) > 0){

			#create the output file
			open ($OUTPUT_FILE, ">", "$output_directory/all_types/chr$mutation_key"."_mutation_localization.log") or die "ERROR: could not create file $output_directory/all_types/chr$current_chr"."_mutation_localization.log";
			#print the header for the output file
			print $OUTPUT_FILE "#chr\tstart\tend\tdensity";
		
			my $density;

			#for every bin along the chromosome
			for(my $chr_pos = 0; $chr_pos < scalar(@{$genome_mutation_data_windows{$mutation_key}}); $chr_pos++){
				$total_genome_windows++;	#increment the total number of windows in the genome
				
				#calculate the density of mutations in the window
				if(!defined(@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])){
					$density = 0;
					}
				else{
					$density = (@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])/($window_size*$bin_size);
					}

				#sum the density values to calculate the mean
				$genome_mean_mutation_density += $density;

				#print the values for the window
				print $OUTPUT_FILE "\n";
				print $OUTPUT_FILE "$mutation_key";
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE $chr_pos*$bin_size;
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE ($chr_pos+$window_size)*$bin_size;
				print $OUTPUT_FILE "\t";
				print $OUTPUT_FILE $density;

				}#for(my $chr_pos = 0; $chr_pos < scalar(@{$genome_mutation_data_windows{$mutation_key}}); $chr_pos++)

			close ($OUTPUT_FILE);
			}
		}#for my $mutation_key ( keys %genome_mutation_data_windows)

	#calculate the mean mutation density for the windows in the genome
	$genome_mean_mutation_density = $genome_mean_mutation_density/$total_genome_windows;	

	#find the sum of squared difference between the density of mutation of each window and the mean density of mutation
	for my $mutation_key ( keys %genome_mutation_data_windows){
		if(scalar(@{$genome_mutation_data_windows{$mutation_key}}) > 0){
			my $density;

			for(my $chr_pos = 0; $chr_pos < scalar(@{$genome_mutation_data_windows{$mutation_key}}); $chr_pos++){
				if(!defined(@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])){
					$density = 0;
					}
				else{
					$density = (@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])/($window_size*$bin_size);
					}

				#sum the squared differences
				$genome_mutation_density_standard_deviation += ($density-$genome_mean_mutation_density)**2;
				}
			}
		}#for my $mutation_key ( keys %genome_mutation_data_windows)

	#divided the sum of the squared differnces by the total number of windows and take the square root
	$genome_mutation_density_standard_deviation = ($genome_mutation_density_standard_deviation/$total_genome_windows)**0.5;

	#calculate z scores for each window and check if the window is greater than 2 SDs away from genome mean
	#use this value to identify highly mutated regions
	for my $mutation_key ( keys %genome_mutation_data_windows){
		if(scalar(@{$genome_mutation_data_windows{$mutation_key}}) > 0){
			my $density;
			my $region_z_score = 0;

			for(my $chr_pos = 0; $chr_pos < scalar(@{$genome_mutation_data_windows{$mutation_key}}); $chr_pos++){
				
				if(!defined(@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])){
					$density = 0;
					}
				else{
					$density = (@{$genome_mutation_data_windows{$mutation_key}}[$chr_pos])/($window_size*$bin_size);
					}

				#calculate z score for the window	
				$region_z_score = ($density-$genome_mean_mutation_density)/$genome_mutation_density_standard_deviation;

				#check if the z score is above the threshold
				if( $region_z_score >= $outlier_deviation ) {
					if($in_suspect_region!=1){
						$suspect_start = $chr_pos*$bin_size;
						$in_suspect_region = 1;
						}
					$suspect_chr = $mutation_key;
					$suspect_end = ($chr_pos+$window_size)*$bin_size;
					}
				elsif ($in_suspect_region==1){
					#once a region has been called push the chromosome, start and end positions into the suspect region array
					push (@suspect_regions, ($suspect_chr,$suspect_start,$suspect_end));
					$suspect_chr = -1;
					$suspect_start = -1;
					$suspect_end = -1;
					$in_suspect_region = 0;
					}

				#check if the z score is below the threshold but still suspicously high
				if(
				   ( $region_z_score < $outlier_deviation ) &&
				   ( $region_z_score >= ($outlier_deviation-1) )
				   ){
					if($in_likely_region!=1){
						$likely_start = $chr_pos*$bin_size;
						$in_likely_region = 1;
						}
					$likely_chr = $mutation_key;
					$likely_end = ($chr_pos+$window_size)*$bin_size;
					}
				elsif ($in_likely_region==1){
					push (@likely_regions, ($likely_chr,$likely_start,$likely_end));
					$likely_chr = -1;
					$likely_start = -1;
					$likely_end = -1;
					$in_likely_region = 0;
					}

				}#for(my $chr_pos = 0; $chr_pos < scalar(@{$genome_mutation_data_windows{$mutation_key}}); $chr_pos++)

				#check if the last region analyzed was suspicious and push its data into the appropriate array
				if ($in_suspect_region==1){
					push (@suspect_regions, ($suspect_chr,$suspect_start,$suspect_end));
					$suspect_chr = -1;
					$suspect_start = -1;
					$suspect_end = -1;
					$in_suspect_region = 0;
					}

				if ($in_likely_region==1){
					push (@likely_regions, ($likely_chr,$likely_start,$likely_end));
					$likely_chr = -1;
					$likely_start = -1;
					$likely_end = -1;
					$in_likely_region = 0;
					}
			}
		}#for my $mutation_key ( keys %genome_mutation_data_windows)


	return (\@suspect_regions, \@likely_regions, \%genome_cnv_data_windows, \%genome_trans_data_windows, \%genome_mutation_data_windows);

	}#sub calculate_chromosome_localization


#=head2 Sub-Method: check_copy_number_count

### check_copy_number_count #######################################################################
# Description:
#	Produces an output file that records the number of regions of copy-number variation that
#	are present in each chromosome.	
#
# Input variables:
#	$output_directory:			stores the path to the output directory	
#	$chromosome_copy_number_count_hash_ref:	reference to hash that stores the count of regions
#						of copy-number variation on each chromosome
#

#=cut

sub check_copy_number_count {

	#parse parameters
	my $output_directory = shift;
	my $chromosome_copy_number_count_hash_ref = shift;

	my $OUTPUT_FILE;	#file handle to output file

	#open the output file
	open ($OUTPUT_FILE, ">", "$output_directory/copy_number_count.log") or die "ERROR: could not create file $output_directory/copy_number_count.log\n";

	#print the header
	print $OUTPUT_FILE "#chr\tcopy_number\tnumber_of_regions";

	#for each chromosome
	#print out the number of regions with the given copy-number
	{use sort 'stable';
	for my $chr (sort keys %$chromosome_copy_number_count_hash_ref){
		my %intermediate_hash = %{$chromosome_copy_number_count_hash_ref->{$chr}};
		for my $CN (sort {$a <=> $b} keys %intermediate_hash){
			print $OUTPUT_FILE "\n";
			print $OUTPUT_FILE "$chr";	#chromosome
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE "$CN";	#copy-number
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE $chromosome_copy_number_count_hash_ref->{$chr}->{$CN};	#number of regions with copy-number $CN
			}
		}
	}#use sort 'stable'
	close ($OUTPUT_FILE);
		
	}#sub check_copy_number_count

#=head2 Sub-Method: check_copy_number_switches

### check_copy_number_switches ####################################################################
# Description:
#	Creates an output file that records the number of breakpoints between CNV regions on each
#	chromosome	
#
# Input variables:
#	$output_directory:			stores path to output directory	
#	$chromosome_copy_number_count_hash_ref:	reference to hash that stores the count of regions
#						of copy-number variation on each chromosome
#

#=cut

sub check_copy_number_switches {

	#parse parameters
	my $output_directory = shift;
	my $chromosome_copy_number_count_hash_ref = shift;

	my $switch_count = 0;

	my $OUTPUT_FILE;	#file handle to output file

	#open output file
	open ($OUTPUT_FILE, ">", "$output_directory/copy_number_switches.log") or die "ERROR: could not create file $output_directory/copy_number_switches.log\n";

	#print header
	print $OUTPUT_FILE "#chr\tswitch_count";

	#for each chromosome
	#sum the total number of CNV events
	#multiply the sum by 2 to get the number of CNV breakpoints
	{use sort 'stable';
	for my $chr (sort keys %$chromosome_copy_number_count_hash_ref){
		my %intermediate_hash = %{$chromosome_copy_number_count_hash_ref->{$chr}};
		for my $CN (sort {$intermediate_hash{$b} <=> $intermediate_hash{$a} } keys %intermediate_hash){
			#only count regions that have abberant copy numbers
			if($CN != 2){
				$switch_count += ($chromosome_copy_number_count_hash_ref->{$chr}->{$CN} * 2);
				}
			}

		#print values to output file
		print $OUTPUT_FILE "\n";
		print $OUTPUT_FILE "$chr";
		print $OUTPUT_FILE "\t";
		print $OUTPUT_FILE $switch_count;

		$switch_count = 0;
		}
	}#use sort 'stable'

	close ($OUTPUT_FILE);
		
	}#sub check_copy_number_switches

#=head2 Sub-Method: calculate_interchromosomal_translocation_rate

### calculate_interchromosomal_translocation_rate #################################################
# Description:
#	Create an output file that records the number of translocations between each and every
#	chromosome	
#
# Input variables:
#	$output_directory:				stores path to output directory	
#	$chromosome_translocation_count_hash_ref:	reference to hash that stores the count of 
#							translocations between each chromosome
#

#=cut

sub calculate_interchromosomal_translocation_rate {

	#parse parameters
	my $output_directory = shift;
	my $chromosome_translocation_count_hash_ref = shift;

	my $OUTPUT_FILE;	#file handle to output file

	#open output file
	open ($OUTPUT_FILE, ">", "$output_directory/interchromosomal_translocation_rate.log") or die "ERROR: could not create file $output_directory/interchromosomal_translocation_rate.log\n";

	#print header
	print $OUTPUT_FILE "#chr1\tchr2\tcount";

	#for each chromosome
	#print the number of translocations between every other chromosome
	{use sort 'stable';
	for my $chr1 (sort keys %$chromosome_translocation_count_hash_ref){
		my %intermediate_hash = %{$chromosome_translocation_count_hash_ref->{$chr1}};

		for my $chr2 (sort keys %intermediate_hash){
			print $OUTPUT_FILE "\n";
			print $OUTPUT_FILE $chr1;
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE $chr2;
			print $OUTPUT_FILE "\t";
			print $OUTPUT_FILE $chromosome_translocation_count_hash_ref->{$chr1}->{$chr2};
			}
		}
	}#use sort 'stable'
	close ($OUTPUT_FILE);
		
	}#sub calculate_interchromosomal_translocation_rate


#=head2 Sub-Method: analyze_suspect_regions

### analyze_suspect_regions #######################################################################
# Description:
#	Produces the final report output file, that includes the chromothriptic scores for each of
#	the highly mutated regions	
#
# Input variables:
#	$output_directory:				stores path to the output directory
#	$suspect_regions_array_ref:			reference to array storing the chromosome,
#							start, and end position of highly mutated
#							regions
#	$genome_mutation_density_hash_ref:		stores the average mutation density of each
#							chromosome	
#	$genome_cnv_data_hash_ref:			stores the position of CNV mutations on
#							each chromosome
#	$genome_trans_data_hash_ref:			stores the position of translocation events
#							on each chromosome
#	$genome_trans_insertion_breakpoints_hash_ref:	stores the position of insertions on each
#							chromosome
#	$bin_size:					stores the size of a single bin
#	$localization_window_size:			stores the number of bins to include in a
#							window
#	$tp53_mutated:					stores whether the TP53 gene is mutatated
#							or not
#	$tp53_mutation_found:				stores whether or not a mutation was found
#							in the TP53 loci
#	$chromosome_cnv_breakpoints_hash_ref:		stores the breakpoints of CNV mutations on
#							each chromosome
#	$chromosome_loh_breakpoints_hash_ref:		stores the breakpoints of LOH regions on
#							each chromosome
#

#=cut

sub analyze_suspect_regions {

	#parse parameters
	my $output_directory 				= shift;

	my $suspect_regions_array_ref 			= shift;
	my @suspect_regions 				= @$suspect_regions_array_ref;

	my $genome_mutation_density_hash_ref 		= shift;
	my %genome_mutation_density_hash		= %{$genome_mutation_density_hash_ref};
	
	my $genome_cnv_data_hash_ref 				= shift;
	my $genome_trans_data_hash_ref				= shift;
	my $genome_trans_insertion_breakpoints_hash_ref 	= shift;

	my $bin_size 					= shift;
	my $localization_window_size			= shift;

	my $tp53_mutated				= shift;
	my $tp53_mutation_found				= shift;

	my $chromosome_cnv_breakpoints_hash_ref		= shift;
	my $chromosome_loh_breakpoints_hash_ref		= shift;


	my $suspect_regions_size = @suspect_regions;	

	my $OUTPUT_FILE;

	my @suspect_region_data = ();

	my $header_string;

	#check that the suspect region data array is not malformed, should contain sets of 3 elements
	if($suspect_regions_size % 3 != 0){
		die "ERROR: suspect_regions_array has $suspect_regions_size entries. Value must be divisible by 3.\n";
		}

	#create output directory for report files	
	mkdir ("$output_directory"."suspect_regions",0770) unless (-d "$output_directory"."suspect_regions");
	if(!(-e "$output_directory"."suspect_regions")){
		die "ERROR: could not create folder $output_directory"."suspect_regions";
		}

	#open final report output file
	open ($OUTPUT_FILE, ">", "$output_directory"."suspect_regions/suspect_regions.yml") or die "ERROR: could not create file: $output_directory"."suspect_regions/suspect_regions.yml\n";

	#construct and print header
	$header_string = "file: Suspect Chromothriptic Regions\n";
	$header_string .= "bin_size:\t\t\t$bin_size\n";
	$header_string .= "localization_window_size:\t$localization_window_size\n";
	$header_string .= "\n";
	$header_string .= "genome_localization_score_weight:\t$genome_localization_weight\n";
	$header_string .= "chromosome_localization_score_weight:\t$chromosome_localization_weight\n";
	$header_string .= "cnv_score_weight:\t\t\t$cnv_weight\n";
	$header_string .= "translocation_score_weight:\t\t$translocation_weight\n";
	$header_string .= "insertion_breakpoint_score_weight:\t$insertion_breakpoint_weight\n";
	$header_string .= "loh_score_weight:\t\t\t$loh_weight\n";
	$header_string .= "tp53_mutation_score_weight:\t\t$tp53_mutated_weight\n";
	$header_string .= "\n";
	$header_string .= "min_mutation_density_z_score:\t$outlier_deviation\n";
	$header_string .= "---\n";
	$header_string .= "\n";
	print $OUTPUT_FILE $header_string;

	#calculate a chromothripsis score for each region that was present in the suspect region array
	#store the results of the score calculation in a 2d array where elements in the first dimension correspond to each suspect region
	#and the elements in the second dimension are the results of the score calculation
	for (my $i = 0; $i < $suspect_regions_size; $i+=3){
		my @region_data = ();
		$region_data[0]   = $suspect_regions[$i];	#chr
		$region_data[1] = $suspect_regions[$i+1];	#start
		$region_data[2]   = $suspect_regions[$i+2]; 	#end

		($region_data[3], $region_data[4], $region_data[5], $region_data[6], $region_data[7], $region_data[8], $region_data[9], $region_data[10], $region_data[11], $region_data[12], $region_data[13]) = calculate_score($region_data[0], $region_data[1], $region_data[2], $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $genome_mutation_density_hash_ref, $genome_trans_insertion_breakpoints_hash_ref, $tp53_mutated, $chromosome_cnv_breakpoints_hash_ref, $chromosome_loh_breakpoints_hash_ref, $bin_size);

		#add the results of the score calculation for this region to the array storing all the results
		push @suspect_region_data, [@region_data];
		}

	#sort the results so that the region with the highest chromothriptic score will be printed
	#to the final report output file first
	{use sort 'stable';
	@suspect_region_data = sort {$b->[3] <=> $a->[3] } @suspect_region_data;
	}#use sort 'stable'A

	#for each score that is generated print the score and the related statistics for that region 
	foreach my $score_data (@suspect_region_data){
		my $chr   = $score_data->[0];	#chr
		my $start = $score_data->[1];	#start
		my $end   = $score_data->[2]; 	#end
		
		my $score			= sprintf("%.5f",$score_data->[3]);
		my $chr_z_score			= $score_data->[4];
		my $region_density		= sprintf("%e",$score_data->[5]);

		my $cnv_number_hash_ref		= $score_data->[6];
		my %cnv_number_hash;
		my $num_copy_num;
		if(defined($cnv_number_hash_ref)){
			%cnv_number_hash = %{$cnv_number_hash_ref};
			$num_copy_num = keys %cnv_number_hash;
			}
		else{
			$num_copy_num = 0;
			}

		my $cnv_density			= sprintf("%e",$score_data->[7]);

		my $intertranslocation_hash_ref	= $score_data->[8];
		my $translocation_density	= $score_data->[9];
		my %intertranslocation_hash;
		my $num_trans_chr;
		if(defined($intertranslocation_hash_ref)){
			%intertranslocation_hash = %{$intertranslocation_hash_ref};
			$num_trans_chr = keys %intertranslocation_hash;
			}
		else{
			$num_trans_chr = 0;
			}

		my $breakpoint_insertions_array_ref	= $score_data->[10];
		my @breakpoint_insertions_array;
		my $breakpoint_percentage;
		if(defined($breakpoint_insertions_array_ref)){
			@breakpoint_insertions_array = @$breakpoint_insertions_array_ref;
			$breakpoint_percentage	= sprintf("%.2f",($breakpoint_insertions_array[0]/$breakpoint_insertions_array[1])*100);
			}

		my $loh_size = $score_data->[11];
		my $hz_size = $score_data->[12];
		my $percent_hz_lost;
		if(defined($loh_size) && defined($hz_size)){
			$percent_hz_lost = sprintf("%.2f",($loh_size/$hz_size)*100);
			}

		my @score_array = @{$score_data->[13]};

		my $chr_density = $genome_mutation_density_hash{$chr};

		my $print_string;

		$print_string = "chromosome:\t$chr\n";
		$print_string .= "start:\t\t$start\n";
		$print_string .= "end:\t\t$end\n";
		$print_string .= "\n";

		$print_string .= "final_score:\t\t\t$score\n";
		$print_string .= "genome_localization_score:\t".$score_array[2]*$genome_localization_weight."\t(".$score_array[2].")"."\n";
		$print_string .= "chromosome_localization_score:\t".$score_array[1]*$chromosome_localization_weight."\t(".$score_array[1].")"."\n";
		$print_string .= "cnv_score:\t\t\t".$score_array[0]*$cnv_weight."\t(".$score_array[0].")"."\n";
		$print_string .= "translocation_score:\t\t".$score_array[3]*$translocation_weight."\t(".$score_array[3].")"."\n";
		$print_string .= "insertion_breakpoint_score:\t".$score_array[4]*$insertion_breakpoint_weight."\t(".$score_array[4].")"."\n";
		$print_string .= "loh_score:\t\t\t".$score_array[5]*$loh_weight."\t(".$score_array[5].")"."\n";
		$print_string .= "tp53_score:\t\t\t".$score_array[6]*$tp53_mutated_weight."\t(".$score_array[6].")\n";
		
		$print_string .= "\n";

		$print_string .= "mutation_density_of_region:\t$region_density\n";
		$print_string .= "mutation_density_of_chromosome:\t$chr_density\n";
		$print_string .= "standard_deviations_from_mean_of_chromosome_mutation_density:\t$chr_z_score\n";
		$print_string .= "\n";

		$print_string .= "density_of_copy_number_switches: $cnv_density\n";
		$print_string .= "number_of_aberrant_copy_number_states:\t$num_copy_num\n";
		if($num_copy_num>0){
			$print_string .= "aberrant_copy_number_states:\n";
			{use sort 'stable';
			foreach my $key (sort {$cnv_number_hash{$b} <=> $cnv_number_hash{$a} } keys %cnv_number_hash){
				$print_string .= "\t$key:\t$cnv_number_hash{$key}\n";
				}
			}#use sort 'stable'
			}

		$print_string .= "\n";

		$print_string .= "density_of_translocation_breakpoints: $translocation_density\n";
		$print_string .= "number_of_translocation_chromosomes:\t$num_trans_chr\n";

		if($num_trans_chr>0){
			$print_string .= "translocation_chromosomes:\n";
			{use sort 'stable';
			foreach my $key (sort {$intertranslocation_hash{$b} <=> $intertranslocation_hash{$a} } keys %intertranslocation_hash){
				$print_string .= "\t$key:\t$intertranslocation_hash{$key}\n";
				}
			}#use sort 'stable'
			}
		$print_string .= "\n";

		if(defined($breakpoint_insertions_array_ref)){
			$print_string .= "insertion_data:\n";	
			$print_string .= "\tinsertions_found_at_translocation_breakpoints:\t$breakpoint_insertions_array[0]\n";	
			$print_string .= "\ttotal_translocation_breakpoints:\t$breakpoint_insertions_array[1]\n";	
			$print_string .= "\tpercentage:\t$breakpoint_percentage"."%\n";	
			$print_string .= "\n";
			}

		if($loh_size!=-1){
			$print_string .= "loh_data:\n";
			$print_string .= "\ttotal_size_of_loh:\t$loh_size\n";	
			$print_string .= "\ttotal_size_of_original_heterozygosity:\t$hz_size\n";
			$print_string .= "\tpercent_heterozygosity_lost:\t$percent_hz_lost"."%\n";	
			$print_string .= "\n";
			}

		if($tp53_mutated && $tp53_mutation_found){
			$print_string .= "tp53_mutation_present:\t1 (forced and mutations found)\n";
			}
		elsif($tp53_mutated){
			$print_string .= "tp53_mutation_present:\t1 (forced)\n";
			}
		elsif($tp53_mutation_found){
			$print_string .= "tp53_mutation_present:\t1 (mutations found)\n";
			}
		else{
			$print_string .= "tp53_mutation_present:\t0\n";
			}


		$print_string .= "---\n";
		$print_string .= "\n";
		print $OUTPUT_FILE $print_string;
		$print_string = "";
		}

	print $OUTPUT_FILE "...";
	close($OUTPUT_FILE);
	}#sub analyze_suspect_regions


#=head2 Sub-Method: analyze_likely_regions

### analyze_likely_regions ########################################################################
# Description:
#	Generates an output file that lists the regions that have a mutation density that is less
#	than the outlier cut off but greater than 1 - the outlier cut off
#
# Input variables:
#	$output_directory:			stores path to the output directory
#	$likely_regions_array_ref:		reference to array storing the chromosome, start,
#						and end position of highly mutated regions
#	$genome_mutation_density_hash_ref:	stores the average mutation density of each
#						chromosome
#	$genome_cnv_data_hash_ref:		stores the position of CNV mutations on each
#						chromosome
#	$genome_trans_data_hash_ref:		stores the position of translocation events on each
#						chromosome
#	$bin_size:				stores the size of a single bin
#

#=cut

sub analyze_likely_regions {

	#parse parameters
	my $output_directory 			= shift;

	my $likely_regions_array_ref 		= shift;
	my @likely_regions 			= @$likely_regions_array_ref;

	my $genome_mutation_density_hash_ref 	= shift;
	my $genome_cnv_data_hash_ref 		= shift;
	my $genome_trans_data_hash_ref		= shift;
	my $bin_size 				= shift;

	my $likely_regions_size = @likely_regions;

	my $OUTPUT_FILE;

	my @return_vals;

	my @likely_region_data = ();	#stores start, end, chromsome and mutation density for each region

	#check that the likely region array is not malformed, should contain sets of 3 elements
	if($likely_regions_size % 3 != 0){
		die "ERROR: suspect_regions_array has $likely_regions_size entries. Value must be divisible by 3.\n";
		}


	#create output directory	
	mkdir ("$output_directory"."suspect_regions",0770) unless (-d "$output_directory"."suspect_regions");
	if(!(-e "$output_directory"."suspect_regions")){
		die "ERROR: could not create folder $output_directory"."suspect_regions";
		}

	#create output file
	open ($OUTPUT_FILE, ">", "$output_directory"."suspect_regions/likely_regions.log") or die "ERROR: could not create file: $output_directory"."suspect_regions/likely_regions.log\n";

	#print file header
	print $OUTPUT_FILE "Likely Chromothriptic Regions\n";
	print $OUTPUT_FILE "High Mutation Density Z-Score:\t$outlier_deviation\n";
	print $OUTPUT_FILE "Min Mutation Density Z-Score:\t$outlier_deviation-1\n";
	print $OUTPUT_FILE "---------------------------------------\n";
	print $OUTPUT_FILE "#chr\tstart\tend\tmutation_density";

	#for each likely region calculate the mutation density for the region and store it in the likely_region_data array
	for (my $i = 0; $i < $likely_regions_size; $i+=3){
		my @region_data = ();
		$region_data[0]   = $likely_regions[$i];	#chr
		$region_data[1]   = $likely_regions[$i+1];	#start
		$region_data[2]   = $likely_regions[$i+2]; 	#end

		($region_data[3],$region_data[4]) = calculate_region_mutation_density_score($region_data[0], $region_data[1], $region_data[2], $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $genome_mutation_density_hash_ref, $bin_size);

		push @likely_region_data, [@region_data];
		}

	#sort the regions by density, largest to smallest
	{use sort 'stable';
	@likely_region_data = sort {$b->[3] <=> $a->[3] } @likely_region_data;
	}#use sort 'stable'

	#print the density for each region to the output file 
	foreach my $i (@likely_region_data){
		my $chr   = $i->[0];	#chr
		my $start = $i->[1];	#start
		my $end   = $i->[2]; 	#end
		
		my $region_density	= $i->[3];	#mutation density

		print $OUTPUT_FILE "\n";
		print $OUTPUT_FILE "$chr\t$start\t$end\t$region_density";
		push (@return_vals,$chr,$start,$end,$region_density);
		}

	close($OUTPUT_FILE);
	return(\@return_vals);
	}#sub analyze_likely_regions


#=head2 Sub-Method: calculate_score

### calculate_score ###############################################################################
# Description:
#	Calculates the chromothripic score for the given region. Calls sub methods to generate the
#	score for each hallmark	
#
# Input variables:
#	$chr:						stores the chromosome on which the region
#							is found	
#	$start:						stores the start base pair of the region
#	$end:						stores the end base pair of the region
#	$genome_cnv_data_hash_ref:			stores the position of CNV mutations on
#							each chromosome
#	$genome_trans_data_hash_ref:			stores the position of translocation events
#							on each chromosome
#	$genome_mutation_density_hash_ref:		stores the average mutation density of each
#							chromosome
#	$genome_trans_insertion_breakpoints_hash_ref:	stores the position of insertions on each
#							chromosome	
#	$tp53_mutated:					stores whether the TP53 gene is mutatated
#							or not
#	$chromosome_cnv_breakpoints_hash_ref:		stores the breakpoints of CNV mutations on
#							each chromosome
#	$chromosome_loh_breakpoints_hash_ref:		stores the breakpoints of LOH regions on
#							each chromosome
#	$bin_size:					stores the size of a single bin
#

#=cut

sub calculate_score{

	#parse parameters
	my $chr 	= shift;
	my $start 	= shift;
	my $end		= shift;

	my $genome_cnv_data_hash_ref			= shift;
	my $genome_trans_data_hash_ref			= shift;
	my $genome_mutation_density_hash_ref		= shift;
	my $genome_trans_insertion_breakpoints_hash_ref	= shift;
	my $tp53_mutated				= shift;
	my $chromosome_cnv_breakpoints_hash_ref		= shift;
	my $chromosome_loh_breakpoints_hash_ref		= shift;
	my $bin_size					= shift;

	#initialize variable to store scores for each hallmark
	my $cnv_score				= 0;
	my $mutation_density_score		= 0;
	my $genome_localization_score		= 0;
	my $translocation_score			= 0;
	my $insertion_breakpoint_score		= 0;
	my $loh_score				= 0;
	my $final_score				= 0;

	my @score_array;	#array in which hallmark scores will be returned

	my $chr_mutation_density;	#stores the average mutation density of the chromosome where the region is found
	my $chr_z_score;		#stores the z_score of the mutation density of the chromosome where the region is found vs
					#all the other chromosomes
	my $cnv_number_hash_ref;	#stores a hash that contains the number of regions of each abberant copy-number
	my $cnv_density;		#stores the density of cnv mutations in the region
	my $translocation_density;	#stores the density of translocation mutations in the region
	my $mutation_density;		#stores the density of all mutations in the region
	my $intertranslocation_hash_ref;	#stores the number of translocations between all other chromosomes and the region
	my $breakpoint_insertions_array_ref;	#stores the total number of translocation breakpoints, and the number that have insertions nearby
	my $loh_size = -1;			#stores the amount of heterozygosity that was lost in the region
	my $heterozygous_size;			#stores the original amount of heterozygosity in the region
	
	($cnv_score, $cnv_number_hash_ref, $cnv_density) = calculate_copy_number_scores($chr, $start, $end, $genome_cnv_data_hash_ref, $bin_size);
	($genome_localization_score, $chr_z_score, $chr_mutation_density) = calculate_genome_localization_score($chr, $genome_mutation_density_hash_ref);
	($translocation_score, $intertranslocation_hash_ref, $translocation_density) = calculate_translocation_score($chr, $start, $end, $genome_trans_data_hash_ref, $bin_size);

	if(defined($genome_trans_insertion_breakpoints_hash_ref)){
		($insertion_breakpoint_score, $breakpoint_insertions_array_ref)	= calculate_insertion_breakpoint_score($chr, $start, $end, $genome_trans_data_hash_ref, $genome_trans_insertion_breakpoints_hash_ref, $bin_size);
		}

	($mutation_density, $mutation_density_score) = calculate_region_mutation_density_score($chr, $start, $end, $genome_cnv_data_hash_ref, $genome_trans_data_hash_ref, $genome_mutation_density_hash_ref, $bin_size);

	if(defined($chromosome_loh_breakpoints_hash_ref)){
		($loh_score, $loh_size, $heterozygous_size) = calculate_loh_score($chr, $start, $end, $chromosome_cnv_breakpoints_hash_ref, $chromosome_loh_breakpoints_hash_ref);
		}

	#calculate overall score for region based on hallmark weights and scores
	$final_score = ($cnv_score*$cnv_weight) + ($mutation_density_score*$chromosome_localization_weight) + ($genome_localization_score*$genome_localization_weight) + ($translocation_score*$translocation_weight) + ($insertion_breakpoint_score*$insertion_breakpoint_weight) + ($tp53_mutated*$tp53_mutated_weight) + ($loh_score*$loh_weight);

	#push the hallmark scores into the score array
	push (@score_array, ($cnv_score, $mutation_density_score, $genome_localization_score, $translocation_score, $insertion_breakpoint_score, $loh_score, $tp53_mutated));

	#return the scores and other region statistics
	return ($final_score, $chr_z_score, $mutation_density, $cnv_number_hash_ref, $cnv_density, $intertranslocation_hash_ref , $translocation_density, $breakpoint_insertions_array_ref, $loh_size, $heterozygous_size, \@score_array);
	}#sub calculate_score



#=head2 Sub-Method: calculate_copy_number_score

### calculate_copy_number_score  ##################################################################
# Description:
#	Calculates the score for the copy-number variation hallmark
#
# Input variables:
#	$chr:				stores the chromsome where the region is located
#	$start:				stores the starting location of the region
#	$end:				stores the end location of the region
#	$genome_cnv_data_hash_ref:	stores the position of CNV mutations on each chromosome
#	$bin_size:			stores the size of single bin
#

#=cut

sub calculate_copy_number_scores {

	#parse parameters
	my $chr = shift;
	my $start = shift;
	my $end = shift;

	my $genome_cnv_data_hash_ref = shift;
	my %genome_cnv_data_hash = %$genome_cnv_data_hash_ref;

	my $bin_size = shift;

	#calculate array index where the data for the first and last bins of the region are located
	my $start_index = $start / ($bin_size);
	my $end_index = $end / ($bin_size);

	my $cnv_score = 0;	#stores final score to return

	my %cnv_number_hash;	#hash
				#key: copy number eg 0,1,3,4
				#value: the number of regions with the given copy number

	my $cnv_switch_count = 0;	#number of switches between different copy numbers
	my $cnv_switch_density = 0;	#density of cnv events in the region

	my @chr_data;	#stores all the bins for the chromosome where the region is located
	my %cnv_hash;	#stores the cnv hash from each bin

	my $mean = 0;	#stores the average number of regions of aberrant copy-number
	my $SD = 0;	#stores the standard deviation of the number of regions of aberrant copy-number

	my %cnv_significant;		#hash
					#key: copy number (but only significant ones are stored)
					#value: the number of regions with the given copy number

	my $significant_count = 0;	#stores the number of unique significant copy-numbers

	#check if there is cnv data for the chromosome
	if(defined($genome_cnv_data_hash{$chr})){

		#extract the bin data for the chromosome
		@chr_data = @{$genome_cnv_data_hash{$chr}};

		#collect the data from the bins that contain the region
		for (my $i = $start_index; $i < $end_index+1; $i++){
			if(!defined($chr_data[$i])){
				next;
				}
			%cnv_hash = %{$chr_data[$i]};

			for my $key (keys %cnv_hash){
				if($key eq 'BPcount'){
					$cnv_switch_count += $cnv_hash{$key};
					}
				else{
					$cnv_number_hash{$key}+= $cnv_hash{$key};
					}
				}
			}

		#calculate the breakpoint density of cnv mutations for the region 
		$cnv_switch_density = $cnv_switch_count/ ($end-$start);

		#calculate the number of cnv events in the region (half the number of breakpoints)
		for my $key (keys %cnv_number_hash){
			$cnv_number_hash{$key} = POSIX::ceil($cnv_number_hash{$key});
			$mean += $cnv_number_hash{$key};
			}

		#if no cnv mutations were found return a score of 0
		if(scalar(keys %cnv_number_hash)==0){
			$cnv_score = 0;
			return ($cnv_score, \%cnv_number_hash, $cnv_switch_density);
			}

		#calculate the mean of the number regions of each copy-number
		$mean = $mean/(scalar(keys %cnv_number_hash));

		#calculate the standard deviation of the number of regions of each copy-number
		for my $key (keys %cnv_number_hash){
			$SD += ($cnv_number_hash{$key}-$mean)**2;
			}
		$SD = $SD/(scalar(keys %cnv_number_hash));
		$SD = $SD**0.5;

		#determine which copy-numbers are significant (ie are not low out liers)
		for my $key (keys %cnv_number_hash){
			if(
			   ( $SD==0 )||
			   ( (($cnv_number_hash{$key}-$mean)/$SD) >= -1*$outlier_deviation )
			  ){
				$cnv_significant{$key} = $cnv_number_hash{$key};
				$cnv_score = $cnv_score + $cnv_significant{$key}**2;	
				}
			}

		#score calculation
		$cnv_score = $cnv_score / (scalar(keys %cnv_significant));
		$cnv_score = log($cnv_score)/log(2);
		$cnv_score += 1;
		$cnv_score = 1 - (1/$cnv_score);
		$cnv_score = $cnv_score/(scalar(keys %cnv_significant));
		#$cnv_score = (1/(scalar(keys %cnv_significant)))*(0.25) + (1-(1/(1+log($cnv_score/(scalar(keys %cnv_significant)))/log(2))))*(0.75);
		}

	return ($cnv_score, \%cnv_number_hash, $cnv_switch_density);

	}#sub calculate_copy_number_scores


#=head2 Sub-Method: calculate_genome_localization_score

### calculate_genome_localization_score  ##########################################################
# Description:
#	Calculates the genome localization hallmark score
#
# Input variables:
#	$chr:					store the chromosome where the region is located
#	$genome_mutation_density_hash_ref:	stores the average mutation density of each 
#						chromosome
#

#=cut

sub calculate_genome_localization_score {

	#parse parameters
	my $chr = shift;

	my $genome_mutation_density_hash_ref = shift;
	my %genome_mutation_density_hash = %{$genome_mutation_density_hash_ref};

	#read mutation density for the chromosome
	my $chr_mutation_density = $genome_mutation_density_hash{$chr}; 

	my $mean_density = 0;	#stores the average density of mutations for the chromosomes

	my $standard_deviation = 0;	#stores the standard deviation of the mutation densities of the chromosomes

	my $z_score = 0;	#stores the z-score for the suspect chromosome
	my $p_val = 0;		#stores the p-value calculated from the z-score for the suspect chromosome

	#sum mutation densities of all the chromosomes
	for my $key (keys %genome_mutation_density_hash){
		$mean_density += $genome_mutation_density_hash{$key}/$chromosome_length{$chr};
		}

	#calculate the mean
	$mean_density = $mean_density / 24;

	#calculate the standard deviation	
	for my $key (keys %genome_mutation_density_hash){
		$standard_deviation += ((($genome_mutation_density_hash{$key}) - ($mean_density) )**2);
		}
	$standard_deviation = $standard_deviation / 24;
	$standard_deviation = ($standard_deviation)**0.5;

	#check for case where the standard deviation or mean comes back as 0
	if($mean_density == 0 || $standard_deviation == 0){
		return (0, 0, $chr_mutation_density);
		}

	#calculate the z-score for suspect chromosome
	$z_score = ($chr_mutation_density - $mean_density) / $standard_deviation;

	#calculate the p-value from the z-score
	$p_val = Statistics::Distributions::uprob($z_score);
	#only consider top tail
	$p_val = 0.5-$p_val;
	$p_val = $p_val/0.5;

	#check for case where z-score comes back as 0	
	if($z_score < 0){
		$p_val = 0;
		}

	#p_val is the score for this hallmark
	return ($p_val, $z_score, $chr_mutation_density);

	}#sub calculate_genome_localization_score


#=head2 Sub-Method: calculate_region_mutation_density_score

### calculate_region_mutation_density_score  ######################################################
# Description:
#	Calculates the chromosome localization hallmark score	
#
# Input variables:
#	$chr:					chromosome where the region is located
#	$start:					starting location of the region
#	$end:					end location of the region
#	$genome_cnv_data_hash_ref:		stores the position of CNV mutations on each 
#						chromosome	
#	$genome_trans_data_hash_ref:		stores the position of translocation events
#						on each chromosome	
#	$genome_mutation_density_hash_ref:	stores the average mutation density of each
#						chromosome
#	$bin_size:				stores the size of single bin
#

#=cut

sub calculate_region_mutation_density_score {

	#parse parameters
	my $chr = shift;
	my $start = shift;
	my $end = shift;

	my $genome_cnv_data_hash_ref = shift;
	my %genome_cnv_data_hash = %{$genome_cnv_data_hash_ref};

	my $genome_trans_data_hash_ref = shift;
	my %genome_trans_data_hash = %{$genome_trans_data_hash_ref};

	my $genome_mutation_density_hash_ref = shift;
	my %genome_mutation_density_hash = %{$genome_mutation_density_hash_ref};

	my $bin_size = shift;

	#calculate array index where the data for the first and last bins of the region are located
	my $start_index = $start / $bin_size;
	my $end_index = $end / $bin_size;

	#get the mean mutation density for the suspect chromosome
	my $mean_chr_mutation_density = $genome_mutation_density_hash{$chr}; 

	my $chis_stat;	#stores the chi squared statistic value

	my $mutation_count = 0;		#stores the total mutation count in the region
	my $cnv_count = 0;		#stores the number of cnv breakpoints in the region
	my $trans_count = 0;		#stores the number of translocation breakpoints in the region
	my $mutation_density = 0;	#store the mutation density of the region
	my $mutation_density_score;	#stores the final score for the hallmark

	my @chr_data;	#stores the bin data for the chromosome
	my %cnv_hash;	#stores the cnv hash for each bin
	my %trans_hash;	#stores the translocation hash for each bin

	#check that there is cnv data for the chromosome
	if(defined($genome_cnv_data_hash{$chr})){
		#get the cnv data for the chromosome
		@chr_data = @{$genome_cnv_data_hash{$chr}};

		#sum the number of cnv breakpoints in the suspect region
		for (my $i = $start_index; $i < $end_index+1; $i++){
			if(!defined($chr_data[$i])){
				next;
				}

			%cnv_hash = %{$chr_data[$i]};
			$cnv_count += $cnv_hash{'BPcount'};
			}
		}

	@chr_data = ();

	#check that there is translocation data for the chromosome
	if(defined($genome_trans_data_hash{$chr})){
		#get the translocation data for the chromosome
		@chr_data = @{$genome_trans_data_hash{$chr}};

		#sum the number of translocation breakpoints in the suspect region
		for (my $i = $start_index; $i < $end_index+1; $i++){
			if(!defined($chr_data[$i])){
				next;
				}
			%trans_hash = %{$chr_data[$i]};
			$trans_count += $trans_hash{'BPcount'};
			}
		}

	#divide the count by 2 to get the number of translocation events	
	$trans_count = POSIX::ceil($trans_count/2);

	#calculate the total number events in the region
	$mutation_count = $cnv_count + $trans_count;

	#calculate the mutation density for the region
	$mutation_density = $mutation_count / ($end-$start);

	#calculate the chi squared statistic
	$chis_stat = abs(((log($mutation_density)-log($mean_chr_mutation_density))**2)/(log($mean_chr_mutation_density)));

	#generate a p-value using the chi squared test
	$mutation_density_score = 1-(Statistics::Distributions::chisqrprob(1,$chis_stat));

	return ($mutation_density, $mutation_density_score);
	}#calculate_region_mutation_density_score


#=head2 Sub-Method: calculate_translocation_score

### calculate_translocation_score #################################################################
# Description:
#	Calculates the translocation hallmark score 
#
# Input variables:
#	$chr:				chromosome where the region is located
#	$start:				starting location of the region
#	$end:				end location of the region
#	$genome_trans_data_hash_ref:	stores the position of translocation events on each
#					chromosome
#	$bin_size:			stores the size of single bin
#

#=cut

sub calculate_translocation_score {

	#parse parameters
	my $chr = shift;
	my $start = shift;
	my $end = shift;

	my $genome_trans_data_hash_ref = shift;
	my %genome_trans_data_hash = %{$genome_trans_data_hash_ref};

	my $bin_size = shift;

	#calculate array index where the data for the first and last bins of the region are located
	my $start_index = $start / ($bin_size);
	my $end_index = $end / ($bin_size);

	my $translocation_density = 0;	#stores the density of translocation events in the region

	my @chr_data;		#stores the bin data for the chromosome
	my %trans_breakpoints;	#hash
				#key: chromosome eg 1,2,X,Y
				#value: an array storing the position of the translocation breakpoints

	my %trans_breakpoint_spreads;	#stores the average distance between translocation breakpoints
	my @significant_chrs;		#stores a list of chromosomes that have a significant number of
					#translocation to or from the region
	my @diffs;			#stores the distance between adjacent translocation breakpoints on
					#one chromosome
	my $diff_sum;			#stores the sum of the distances
	my $diff_count;			#store the number regions between translocation breakpoints

	my %trans_number_hash;		#hash
					#key: chromosome eg 1,2,X,Y
					#value: the number of events between the chromosome and the region

	my $mean = 0;			#stores the average number of translocations between each chromosome
					#and the region
	my $SD = 0;			#stores the standard deviation of the above value

	my $weighted_sum = 0.00;	#component of the score calculation

	my $size = 0.00;		#intermediate variable used to collect sums
	my $count = 0;			#intermeidate variable

	my $translocation_score = 0;	#final hallmark score

	my $spread_factor = 0;

	my $translocation_count = 0;	#stores the total number of translocations from significant chromosomes

	#check that there is translocation data for the chromosome
	if(defined($genome_trans_data_hash{$chr})){
		#get the translocation data for the chromosome
		@chr_data = @{$genome_trans_data_hash{$chr}};

		#for each bin sum the number of translocation events
		#and record the position of breakpoints in the trans_breakpoints hash
		for (my $i = $start_index; $i < $end_index+1; $i++){
			if(!defined($chr_data[$i])){
				next;
				}
			my %trans_hash = %{$chr_data[$i]};
			my %trans_hash_in;
			my %trans_hash_out;

			#analyze the breakpoints from translocation into the region
			if(defined($trans_hash{'in'})){
				%trans_hash_in = %{$trans_hash{'in'}};

				for my $key (keys %trans_hash_in){
					$size = @{$trans_hash_in{$key}};

					#calculate the number of translocation events
					$size = $size/2;

					#add the count to the appropriate hash
					$trans_number_hash{$key} += $size;

					#add the breakpoints to the trans_breakpoints hash
					push(@{$trans_breakpoints{$key}},(@{$trans_hash_in{$key}}));
					}
				}

			#analyze the breakpoints from translocation out of the region
			if(defined($trans_hash{'out'})){
				%trans_hash_out = %{$trans_hash{'out'}};

				for my $key (keys %trans_hash_out){
					$size = @{$trans_hash_out{$key}};
					$count = $size;
					if($key eq $chr){
						foreach my $val (@{$trans_hash_out{$key}}){
							if($val > $start && $val < $end){
								$count--;
								}
							}
						}
					#calculate the number of translocation events
					$count = $count/2;

					#add the count to the appropriate hash
					$trans_number_hash{$key} += $count;

					#add the breakpoints to the trans_breakpoints hash
					push(@{$trans_breakpoints{$key}},(@{$trans_hash_out{$key}}));
					}
				}
			}

		$count = 0;

		#check that some translocation events were found else return a score of 0
		if (keys(%trans_number_hash) == 0){
			$translocation_score = 0;
			$translocation_density = 0;
			return ($translocation_score, \%trans_number_hash, $translocation_density);
			}

		for my $key (keys %trans_number_hash){
			#round the event count up since if only one breakpoint was present at the end
			#of the region we still count that as a whole translocation event
			$trans_number_hash{$key} = POSIX::ceil($trans_number_hash{$key});

			#sum the number of translocation events in the region
			$count += $trans_number_hash{$key};
			}

		#calculate the translocation density for the region
		$translocation_density = $count / ($end-$start);

		#calculate the mean and standard deviation of the number of translocation between the region
		#and each chromosome
		($SD, $mean) = standard_deviation_and_mean(\%trans_number_hash,0);
	
		#identify chromosomes that have a high number of translocations to or from the region and
		#add them to the significant chromosome list
		for my $key (keys %trans_number_hash){
			if(
			   ( $SD==0 )||
			   #( (($trans_number_hash{$key}-$mean)/$SD)>-2*$outlier_deviation)
			   ( (($trans_number_hash{$key}-$mean)/$SD)>-1*$outlier_deviation)
			  ){
				push (@significant_chrs, $key);
				}
			}

		#calculate the total number of translocations from significant chromosomes
		foreach my $key (@significant_chrs){
			$translocation_count += $trans_number_hash{$key};	
			}

		#for each significant chromosome calculate the spread between translocation events
		foreach my $key (@significant_chrs){
			#sort the breakpoints
			{use sort 'stable';
			@{$trans_breakpoints{$key}} = sort {$a <=> $b} @{$trans_breakpoints{$key}};
			}#use sort 'stable'

			$size = @{$trans_breakpoints{$key}};
			@diffs = ();
			$diff_sum = 0;
			$diff_count = 0;

			#calculate and store the distance between adjacent breakpoints
			for (my $i = 1; $i<$size; $i++){
				push (@diffs, @{$trans_breakpoints{$key}}[$i]-@{$trans_breakpoints{$key}}[$i-1]);
				}

			#check that more that one distance was calculated
			if($size==1){
				$trans_breakpoint_spreads{$key} = 0;
				$diff_count = 1;
				}
			else{	#calculate the standard deviation and mean for the distance between breakpoints
				($SD,$mean) = standard_deviation_and_mean(\@diffs,1);

				#sum the distances that are not high outliers, indicating distance between 2 translocation
				#events and not distance between breakpoints of the same event
				foreach my $val (@diffs){
					if(
					   ( $SD==0 )||
					   ( (($val-$mean)/$SD)<$outlier_deviation )
					  ){
						$diff_sum += $val;
						$diff_count++;
						}
					}
				}

			#calculate the average spread of translocation breakpoints
			$trans_breakpoint_spreads{$key} = $diff_sum / $diff_count;

			#calculate the spread factor for the chromosome
			#my $spread_factor = (log($trans_breakpoint_spreads{$key}+1)/log(10))/((log($expected_mutation_density)/log(10))*-1);
			$spread_factor = (log($trans_breakpoint_spreads{$key}+1)/log(10))/((log($expected_mutation_density)/log(10))*-1);
			if($spread_factor==0){
			$spread_factor = 1;
				}


			#increase the weighted sum based on the number of translocation events and their spread multiplied by the proportion of translocations
			#from this specific chromosome relative to the total number of translocation events
			$weighted_sum += ($trans_number_hash{$key}/$spread_factor)*($trans_number_hash{$key}/$translocation_count);	
			}#foreach my $key (@significant_chrs)

		my $t2 = (1-(1/(log(1+$weighted_sum)/log(2))));
		#final hallmark score calculation
		$size = @significant_chrs;

		#calculate second term of score
		$translocation_score = (1-(1/(log(1+$weighted_sum)/log(2))));

		#calculate first term of score
		if($size<$translocation_cut_off_count && $size>2){
			$translocation_score = (1-(0.10*($size-2)))*$translocation_score;
			}
		if($size>=$translocation_cut_off_count){
			$translocation_score = 0;
			}

		if($translocation_score>=1){
			print "score: ".$translocation_score."\n";
			print "ws: ".$weighted_sum."\n";
			print "sf: ".$spread_factor."\n";
			print "term 1: ";
			print (1/(1+(log($size)/log(4))));
			print "\n";
			print "term 2: ";
			print (1-(1/(log($weighted_sum)/log(2))));
			print "\n";
			}

		}#if(defined($genome_trans_data_hash{$chr}))

	return ($translocation_score, \%trans_number_hash, $translocation_density);

	}#sub calculate_translocation_score


#=head2 Sub-Method: calculate_insertion_breakpoint_score

### calculate_insertion_breakpoint_score ##########################################################
# Description:
#	Calculates the insertions at translocation breakpoints hallmark score	
#
# Input variables:
#	$chr:						chromosome where the region is located
#	$start:						starting location of the region
#	$end:						end location of the region
#	$genome_trans_data_hash_ref:			stores the position of translocation events 
#							on each chromosome
#	$genome_trans_insertion_breakpoints_hash_ref:	stores the position of breakpoints with
#							insertions nearby
#	$bin_size:					stores the size of single bin
#

#=cut

sub calculate_insertion_breakpoint_score {

	#parse parameters
	my $chr = shift;
	my $start = shift;
	my $end = shift;

	my $genome_trans_data_hash_ref = shift;
	my %genome_trans_data_hash = %{$genome_trans_data_hash_ref};

	my $genome_trans_insertion_breakpoints_hash_ref = shift;
	my %genome_trans_insertion_breakpoints_hash = %{$genome_trans_insertion_breakpoints_hash_ref};

	my $bin_size = shift;

	#calculate array index where the data for the first and last bins of the region are located
	my $start_index = $start / ($bin_size);
	my $end_index = $end / ($bin_size);

	my $total_breakpoints = 0;	#total number of breakpoints in the region
	my $inserted_breakpoints = 0;	#total number of breakpoints with nearby insertions in the region

	my $insertion_breakpoint_score = 0;

	my @chr_data;		#stores the bin data for the chromosome
	my %trans_hash;		#stores translocation hash for each bin

	my @inserted_breakpoint_list;	#stores the breakpoints that have insertions nearby
	my @breakpoint_data;		#stores $total_breakpoints and $inserted_breakpoints for return

	#check if there is translocation data for the region
	if(defined($genome_trans_data_hash{$chr})){

		#get the translocation data
		@chr_data = @{$genome_trans_data_hash{$chr}};

		#for each bin in the region sum the number of breakpoints
		for (my $i = $start_index; $i < $end_index+1; $i++){
			if(!defined($chr_data[$i])){
				next;
				}
			%trans_hash = %{$chr_data[$i]};
			$total_breakpoints += $trans_hash{'BPcount'};
			}

		#get the list of breakpoints with insertions nearby on the chromosome
		@inserted_breakpoint_list = @{$genome_trans_insertion_breakpoints_hash{$chr}};

		#sort the above list
		{use sort 'stable';
		@inserted_breakpoint_list = sort {$a <=> $b} @inserted_breakpoint_list;
		}#use sort 'stable'

		#calculate how many of the breakpoints with insertions are in the region
		foreach my $breakpoint (@inserted_breakpoint_list){
			if($breakpoint > $end){
				last;
				}
			if($breakpoint > $start){
				$inserted_breakpoints++;
				}
			}

		#calculate the hallmark score
		if ($total_breakpoints > 0) {
			$insertion_breakpoint_score = $inserted_breakpoints/$total_breakpoints;
			}

		if($insertion_breakpoint_score > 1){
			die "ERROR: found a insertion_breakpoint_score greater than 1\n";
			}

		}

	push (@breakpoint_data, $inserted_breakpoints);
	push (@breakpoint_data, $total_breakpoints);

	return ($insertion_breakpoint_score, \@breakpoint_data);
	}


#=head2 Sub-Method: calculate_loh_score

### calculate_loh_score ###########################################################################
# Description:
#	Calculates the loss of heterozgozity hallmark score	
#
# Input variables:
#	$chr:					chromosome where the region is located
#	$start:					starting location of the region
#	$end:					end location of the region
#	$chromosome_cnv_breakpoints_hash_ref:	stores the breakpoints of CNV mutations on each
#						chromosome	
#	$chromosome_loh_breakpoints_hash_ref:	stores the breakpoints of LOH regions on each
#						chromosome
#

#=cut

sub calculate_loh_score {

	#parse parameters
	my $chr		= shift;
	my $start	= shift;
	my $end		= shift;

	my $chromosome_cnv_breakpoints_hash_ref	= shift;
	my %chromosome_cnv_breakpoints_hash	= %{$chromosome_cnv_breakpoints_hash_ref};

	my $chromosome_loh_breakpoints_hash_ref	= shift;
	my %chromosome_loh_breakpoints_hash	= %{$chromosome_loh_breakpoints_hash_ref};

	my @cnv_breakpoints;		#stores cnv breakpoints in the region
	my $cnv_breakpoints_size;	#stores the number of cnv breakpoints in the region

	my @loh_breakpoints;		#stores the LOH breakpoints in the region
	my $loh_breakpoints_size;	#stores the number of LOH breakpoints in the region

	#calculate maximum potential amount of heterozygosity
	my $original_heterozygous_size = $end - $start;

	#calculate maximum pontentail amount of heterozygosity that can remain
	my $remaining_heterozygous_size 	= $end - $start;

	my $loh_size = 0;	#stores the size of all LOH regions in the region

	my $loh_score = 0;	#final hallmark score

	#check if there is any cnv data for the chromosome	
	if(
	   ( !defined($chromosome_cnv_breakpoints_hash{$chr}) ) ||
	   ( !defined($chromosome_loh_breakpoints_hash{$chr}) )
	  ){
		$loh_score = 0;
		$loh_size = -1;
		$remaining_heterozygous_size = -1;
		return($loh_score, $loh_size, $remaining_heterozygous_size);
		}

	#get the cnv breakpoints for the chromosome
	@cnv_breakpoints = @{$chromosome_cnv_breakpoints_hash{$chr}};

	#sort the list
	{use sort 'stable';
	@cnv_breakpoints = sort {$a <=> $b} @cnv_breakpoints;
	}#use sort 'stable'

	#get the number of breakpoints
	$cnv_breakpoints_size = @cnv_breakpoints;

	#find all the cnv events that occur in the region and subtract the size of these regions
	#from the $original_heterozygous_size value
	for (my $i = 0; $i< $cnv_breakpoints_size; $i+=2){
		my $cnv_start = $i;
		my $cnv_end = $i+1;

		my $end_overlap = 0;
		my $start_overlap = 0;

		if($cnv_breakpoints[$cnv_start] > $end){
			last;
			}

		#Check if the end point of the cnv region is within the suspect region
		if($cnv_breakpoints[$cnv_end] >= $start && $cnv_breakpoints[$cnv_end] <= $end){
			$end_overlap = 1;
			}

		#Check if the start point of the region cnv is within the suspect region
		if($cnv_breakpoints[$cnv_start] >= $start && $cnv_breakpoints[$cnv_start] <= $end){
			$start_overlap = 1;
			}

		#If an overlap was detected
		if($start_overlap==1 && $end_overlap==1) {
			$remaining_heterozygous_size -= ($cnv_breakpoints[$cnv_end] - $cnv_breakpoints[$cnv_start]);
			}
		elsif($start_overlap==1){
			$remaining_heterozygous_size -= ($end-$cnv_breakpoints[$cnv_start]);
			}
		elsif($end_overlap==1){
			$remaining_heterozygous_size -= ($cnv_breakpoints[$cnv_end]-$start);
			}
		elsif($cnv_breakpoints[$cnv_start] < $start && $cnv_breakpoints[$cnv_end] > $end){
			$remaining_heterozygous_size = 0;
			}
		}

	#check if there is no potential heterozygous regions in the suspect region or if there are no cnv events
	#in the suspect region, if either is the case return a score of 0
	if($remaining_heterozygous_size == 0 || $remaining_heterozygous_size == $original_heterozygous_size){
		$loh_score = 0;
		$loh_size = -1;
		$remaining_heterozygous_size = -1;
		return($loh_score, $loh_size, $remaining_heterozygous_size);
		}
	
	#get a list of the LOH breakpoints on the chromosome	
	@loh_breakpoints = @{$chromosome_loh_breakpoints_hash{$chr}};

	#sort the list
	{use sort 'stable';
	@loh_breakpoints = sort {$a <=> $b} @loh_breakpoints;
	}#use sort 'stable'

	#get the number of breakpoints
	$loh_breakpoints_size = @loh_breakpoints;

	#determine which LOH regions are in the suspect region
	for (my $i = 0; $i< $loh_breakpoints_size; $i+=2){
		my $start_overlap_region_loh = 0;
		my $end_overlap_region_loh = 0;

		my $loh_start = $i;
		my $loh_end = $i+1;

		my $loh_start_breakpoint = $loh_breakpoints[$loh_start];
		my $loh_end_breakpoint = $loh_breakpoints[$loh_end];
		my $loh_region_size;

		if($loh_breakpoints[$loh_start] > $end){
			last;
			}

		#Check if the end point of the cnv region is within the loh region
		if($loh_breakpoints[$loh_end] >= $start && $loh_breakpoints[$loh_end] <= $end){
			$end_overlap_region_loh = 1;
			}

		#Check if the start point of region 1 is within region 2
		if($loh_breakpoints[$loh_start] >= $start && $loh_breakpoints[$loh_start] <= $end){
			$start_overlap_region_loh = 1;
			}

		#If an overlap was detected
		if($start_overlap_region_loh==1 && $end_overlap_region_loh!=1){
			$loh_end_breakpoint = $end;	
			}
		elsif($end_overlap_region_loh==1 && $start_overlap_region_loh!=1){
			$loh_start_breakpoint = $start;
			}
		elsif($loh_breakpoints[$loh_start] < $start && $loh_breakpoints[$loh_end] > $end){
			$loh_start_breakpoint = $start;
			$loh_end_breakpoint = $end;
			$start_overlap_region_loh=1;
			$end_overlap_region_loh=1;
			}
		if($start_overlap_region_loh != 1 && $end_overlap_region_loh != 1){	#if the loh region is not in the suspect region go to the next loh region
			next;
			}

		#if the loh region is in the suspect region then reduce the size of the loh by subtracting the size of cnv regions that over lap with it
		#this will tell us how much original heterozygosity remains
		$loh_region_size = $loh_end_breakpoint - $loh_start_breakpoint;

		#check for overlaps between the LOH region and cnv regions
		for (my $k = 0; $k< $cnv_breakpoints_size; $k+=2){   
			my $start_overlap_loh_cnv = 0;
			my $end_overlap_loh_cnv = 0;

			my $cnv_start = $k;
			my $cnv_end   = $k+1;

			if($cnv_breakpoints[$cnv_start] > $loh_end_breakpoint){
				last;
				}

			#Check if the end point of the cnv region is within the loh region
			if($cnv_breakpoints[$cnv_end] >= $loh_start_breakpoint && $cnv_breakpoints[$cnv_end] <= $loh_end_breakpoint){
				$end_overlap_loh_cnv = 1;
				}

			#Check if the start point of region 1 is within region 2
			if($cnv_breakpoints[$cnv_start] >= $loh_start_breakpoint && $cnv_breakpoints[$cnv_start] <= $loh_end_breakpoint){
				$start_overlap_loh_cnv = 1;
				}

			#If an overlap was detected
			if($start_overlap_loh_cnv==1 && $end_overlap_loh_cnv==1) {
				$loh_region_size -= ($cnv_breakpoints[$cnv_end] - $cnv_breakpoints[$cnv_start]);
				}
			elsif($start_overlap_loh_cnv==1){
				$loh_region_size -= ($loh_end_breakpoint-$cnv_breakpoints[$cnv_start]);
				}
			elsif($end_overlap_loh_cnv==1){
				$loh_region_size -= ($cnv_breakpoints[$cnv_end]-$loh_start_breakpoint);
				}
			elsif($cnv_breakpoints[$cnv_start] < $loh_start_breakpoint && $cnv_breakpoints[$cnv_end] > $loh_end_breakpoint){
				$loh_region_size = 0;
				}
			}
		$loh_size += $loh_region_size;		
		}


	#calculate the LOH score
	$loh_score = 1 - ($loh_size/$remaining_heterozygous_size);

	if($loh_size> $remaining_heterozygous_size){
		die "ERROR: invalid LOH size value found\n";
		}

	return($loh_score, $loh_size, $remaining_heterozygous_size);

	}#sub calculate_loh_score


#=head2 Sub-Method: standard_deviation_and_mean

### standard_deviation_and_mean ###################################################################
# Description:
#	Calculates the standard deviation and mean for a given set of values	
#
# Input variables:
#	$data_ref:	reference to either a hash or an array
#	$type:		0 indicates a hash, 1 indicates an array
#	

#=cut

sub standard_deviation_and_mean{

	#parse parameters
	my $data_ref = shift;
	my $type = shift;

	my %hash;
	my @array;
	my $size;

	my $mean = 0;
	my $SD = 0;

	if($type==0){
		%hash = %{$data_ref};

		if((scalar(keys %hash))==0){
			die"Found sample size of 0 when calculating SD-hash\n";
			}

		#calculate mean
		for my $key (keys %hash){
			$mean += $hash{$key};
			}
	
		$mean = $mean/(scalar(keys %hash));

		#calculate sum of squared differences
		for my $key (keys %hash){
			$SD += ($hash{$key}-$mean)**2;
			}
		
		#calculate final standard deviation value
		$SD = $SD/(scalar(keys %hash));
		$SD = $SD**0.5;
	}
	elsif($type==1){
		@array = @{$data_ref};
		$size = @array;

		if($size==0){
			die"Found sample size of 0 when calculating SD-array\n";
			}
	
		#calculate mean
		foreach my $val (@array){
			$mean += $val;
			}

		$mean = $mean/$size;

		#calculate sum of squared differences
		foreach my $val (@array){
			$SD += ($val-$mean)**2;
			}

		#calculate final standard deviation value
		$SD = $SD/$size;
		$SD = $SD**0.5;
		
		}
	else{
		die"ERROR: invalid SD/mean type found\n";
		}
	return ($SD, $mean);

	}#sub standard_deviation_and_mean


### next_arg ######################################################################################
# Parse the next arguement from the command line 
#
sub next_arg {
	my $code = shift;
	$pos++;	
	if($pos == $ARGC){
		usage($code);
		}
	}#sub next_arg

### man_text ######################################################################################
# Print the manual help text
#
sub man_text {
	print "Main Usage:\n";
	print "\tperl -w shatterproof.pl --cnv <dir> --trans <dir> [--insrt <dir>] [--loh <dir>] [--tp53] --config <path> --output <dir>\n";
	print "\n";
	print "\tArguments:\n";
	print "\t\t--cnv\t\tDefine the path to the directory containing the CNV input files\n";
	print "\t\t--trans\t\tDefine the path to the directory containing the Translocation input files\n";
	print "\t\t--insrt\t\tDefine the path to the directory containing the insertion VCF input files\n";
	print "\t\t--loh\t\tDefine the path to the directory containing the LOH input files\n";
	print "\t\t--tp53\t\tIndicate that TP53 should be considered mutated, regardless of data\n";
	print "\t\t--config\tDefine the path to the ShatterProof config file\n";
	print "\t\t--output\tDefine the path to the directory where output should be placed\n";
	print "\t\tdir\t\tPath to a directory\n";
	print "\t\tpath\t\tPath to a file\n";
	print "\n";
	print "Help Usage:\n";
	print "\tperl -w shatterproof.pl --help\t\tThis help message.\n";
	print "\n";
	exit 0;
	}#sub man_text

### usage #########################################################################################
# Prints an error message when invalid command line arguements are found
#
sub usage {
	my $usage_msg = shift;

	print "u $usage_msg \n";
	
	given($usage_msg){
		when (/^0/) 	{ print "ERROR: missing arguments\n"; 			}
		when (/^1/) 	{ print "ERROR: 2nd argument missing\n"; 		}
		when (/^2/) 	{ print "ERROR: CNV directory missing\n"; 		}
		when (/^3/) 	{ print "ERROR: --trans option missing\n"		}
		when (/^4/) 	{ print "ERROR: --cnv option missing\n"			}
		when (/^5/) 	{ print "ERROR: Translocation directory missing\n"	}
		when (/^6/) 	{ print "ERROR: --config option missing\n"		}
		when (/^7/) 	{ print "ERROR: --trans option missing\n"		}
		when (/^8/) 	{ print "ERROR: insertion directory missing\n"		}
		when (/^9/) 	{ print "ERROR: --config option missing\n"		}
		when (/^10/) 	{ print "ERROR: LOH directory missing \n"		}
		when (/^11/) 	{ print "ERROR: --config option missing\n"		}
		when (/^12/) 	{ print "ERROR: --config option missing\n"		}
		when (/^13/) 	{ print "ERROR: Path to config file missing\n"		}
		when (/^14/) 	{ print "ERROR: --output option missing\n"		}
		when (/^15/) 	{ print "ERROR: --config option missing\n"		}
		when (/^16/) 	{ print "ERROR: Output directory missing\n"		}
		when (/^17/) 	{ print "ERROR: --output option missing\n"		}
		when (/^18/) 	{ print "ERROR: too many arguments\n"			}
		}
	print "Try perl -w shatteproof.pl --help\n";
	exit 0;
	}#sub usage

### initialize_genome_hash ########################################################################
# Description:
#	Initializes a hash to store an array for each chromosome
#
sub initialize_genome_hash {

	my %genome_region_data = (  	#{chr}[region_num]->%region_data
			 X => [],
			 Y => [],
			 1 => [],
			 2 => [],
			 3 => [],
			 4 => [],
			 5 => [],
			 6 => [],
			 7 => [],
			 8 => [],
			 9 => [],
			 10 => [],
			 11 => [],
			 12 => [],
			 13 => [],
			 14 => [],
			 15 => [],
			 16 => [],
			 17 => [],
			 18 => [],
			 19 => [],
			 20 => [],
			 21 => [],
			 22 => []
			 );

	return (\%genome_region_data);
	}#sub initialize_genome_hash

### load_config_file #########################################################################################
# Description:
#	Opens the config file and reads the parameter values from it	
#
# Input variables:
#	$path:	path to config file
#
sub load_config_file {
            
        my $path = shift;
        print "\nLoading configuration file";

        #Load the configuration file config.pl
        my $CONFIG;
        open($CONFIG, "<","$path") or die "COULD NOT OPEN CONFIG FILE at path: $path \n";
        eval (<$CONFIG>) while (!eof($CONFIG));
	close($CONFIG);

        print " - Done\n";
	1;
        }#sub load_config_file

=head1 NAME

ShatterProof - a script for analyzing next-generation sequencing data

=head1 SYNOPSIS

use Shatterproof

See "shatterproof.pl" in the scripts directory for a simple perl script which calls the ShatterProof module

Call ShatterProof via:

	ShatterProof::run(\@ARGV);

=head1 DESCRIPTION

ShatterProof is a tool that can be used to analyze next generation sequencing data for signs of chromothripsis. ShatterProof is implemented as a Perl module that processes input files and produces output files in both tab-delimited and YAML format. Perl version 5.0 or greater is required to run ShatterProof. Link to publication will be posted soon.

=head1 README

=head2 Installing ShatterProof

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

Make sure that you have admin permission rights when running the previous commands.

=head2 Input File Types

ShatterProof bases its analysis of genomic data on calls of translocations, copy number variations (CNV), loss of heterozygosity (LOH) and insertions.
ShatterProof can takes as input 4 different types of input files.  See the scripts/conversion_scripts directory for some Perl scripts which will convert some common tools' output to the required input formats.

=head3 Translocation Input Files (.spt)

Tab delimited columns
First line is header line:
#chr1   start   end     chr2    start   end     quality

Example data entry line:

	1       1000    2000    4       4000    5000    78

If no value is available for quality, use a "." eg.:

	1       1000    2000    4       4000    5000    .


=head3 Copy-Number Input Files (.spc)

Tab delimited columns
First line is header line:
#chr    start   end     number  quality


Example data entry line:
	12      2000    3000    2       63

If no value is available for quality, use a "." eg.:

	12      2000    3000    2       .

=head3 Loss of Heterozygozity Input Files (.spl)

Tab delimited columns
First line is header line:
#chr    start   end	quality


Example data entry line:

	12      2000    3000	63

If no value is available for quality, use a "." eg.:

	12      2000    3000	.

=head3 Insertion Input Files (.vcf)

Additionally, ShatterProof accepts insertion calls in VCF files as input. See http://www.1000genomes.org/node/101 for details on the VCF file format.
ShatterProof analyzes the CHROM and POS fields of these files. 
 

=head2 Configuring ShatterProof

See the config.pl file in the scripts directory for a sample ShatterProof configuration file.

$bin_size: number (integer) of base pairs to include in each bin of the sliding window analysis

$localization_window_size: number (integer) of bins to include in each window of the sliding window analysis

$expected_mutation_density: a reference value (double) used in determining if the concentration of translocation events on a particular chromosome is higher than expected.

$collapse_regions: 

	flag variable

	value 1: merge overlapping CNV regions that have the same copy number

	value 0: do not merge overlapping CNV regions that have the same copy number. 	If such regions are found an error is thrown

$outlier_deviations: the number of standard deviations away from the mean a value has to be in order to be considered non-significant. Used to identify highly mutated regions.

$translocation_cut_off_count: the maximum number of translocation chromosomes to tolerate before the translocation score for a region is set to 0.

$genome_localization_weight: weight given to the localization of mutations to one chromosome hallmark

$chromosome_localization_weight: weight given to the localization of mutations to one area of a particular chromosome hallmark

$cnv_weight: weight given to the concentrated CNV hallmark

$translocation_weight: weight give to the concentrated translocations hallmark

$insertion_breakpoint_weight: weight given the the short breakpoint insertions hallmark

$loh_weight: weight given to the loss/retention of heterozygosity hallmark

$tp53_mutated_weight: weight given to the TP53 mutation hallmark


=head2 Running ShatterProof

From the scripts directory run execute the shatterproof.pl file using Perl.

Main Usage:

perl -w shatterproof.pl --cnv <dir> --trans <dir> [--insrt <dir>] [--loh <dir>] [--tp53] --config <path> --output <dir>

 Arguments:

--cnv		Define the path to the directory containing the CNV input files

--trans		Define the path to the directory containing the Translocation input files

--insrt		Define the path to the directory containing the insertion VCF input files

--loh		Define the path to the directory containing the LOH input files

--tp53		Indicate that TP53 should be considered mutated, regardless of data

--config	Define the path to the ShatterProof config file

--output	Define the path to the directory where output should be placed

dir		Path to a directory

path		Path to a file

=head1 PREREQUISITES

strict;
warnings;
Carp;
Switch;
File::Basename;
List::Util qw[min max];
Statistics::Distributions;
POSIX

=pod OSNAMES

any

=pod SCRIPT CATEGORIES

CPAN

=cut

1;
__END__
