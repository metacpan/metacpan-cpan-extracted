#!/usr/bin/perl

=head1 NAME

NanoB2BNER.pl - This program provides an example of using the 
    ner methods in NanoB2B::NER

=head1 SYNOPSIS

This program provides an example of using the ner methods in 
NanoB2B::NER

=head1 USAGE

Usage: NanoB2BNER.pl [OPTIONS]

=head1 OPTIONS

Optional command line arguements

=head2 Options (* = required):

=head3 --help

Displays a brief summary of program options.

=head3 *--dir

The name of the directory that contain the files

=head3 *--fts STR

Get the list of features you want to use for the set
Ex. "ortho morph text pos cui sem"

=head3 --debug

Sets the debug flag on for testing

=head3 --process STR

Decide how to run NNER (by method or by file)
Ex/ "file" = each method processes the file before going to the next
Ex/ "method" = each file is run the the method before going to the next method

=head3 --index NUM

Starts the program at a certain index number in a directory

=head3 --file STR

Defines the file source of a single article

=head3 --sortBySize

Option to sort the directory files by size

=head3 --import_meta

Runs the program with the pre-made meta data

=head3 --stopwords

Eliminates stop words from vectors in the ARFF files

=head3 --buckets NUM

The number of buckets for the k-fold cross validation

=head3 --prefix NUM

Sets the prefix character amount for morph features

=head3 --suffix NUM

Sets the suffix character amount for morph features

=head3 --weka_type STR

Sets the type of weka algorithm to use on the data

=head3 --weka_size STR

Sets the maximum memory value to run weka with

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 CONTACT US
   
  If you have any trouble installing and using NanoB2B-NER, 
  please contact us: 

      Megan Charity : charityml at vcu.edu

=head1 AUTHOR

 Megan Charity, Virginia Commonwealth University 
 Bridget T. McInnes, Virginia Commonwealth University 

=head1 COPYRIGHT

Copyright (c) 2017

 Megan Charity, Virginia Commonwealth University
 charityml at vcu.edu

 Bridget T. McInnes, Virginia Commonwealth University
 btmcinnes at vcu.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

####################		IMPORTS  		###################

use Getopt::Long;						#options 
use Getopt::Long qw(GetOptions);		#shorten option length

use NanoB2B::NER;


################# 			OPTIONS        	 #####################


eval(GetOptions("help", "dir=s", "features=s", "debug", "process=s", "file=s", "sort", "import_meta", "stopwords", "prefix=i", "suffix=i", "index=i", "weka_type=s", "weka_size=s", "buckets=i")) or die ("Check your options!\n");

my %params = ();
my $process = "";

#   if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp;
    exit;
}

#required parameters
if(defined $opt_dir){										#get the name of the directory to look in
	$params{'dir'} = $opt_dir;
	print "---Opening directory: \"$opt_dir\"---\n";
}
if(defined $opt_features){										#grab the features you want to use
	$params{'features'} = $opt_features;
}

#optional parameters
if(defined $opt_debug){										#have the debug print statements
	$params{'debug'} = 1;
	print("---DEBUG MODE---\n")							
}

if(defined $opt_process){
	$process = $opt_process;
}else{
	$process = "file";
}

if(defined $opt_file){										#if using one file
	$params{'file'} = $opt_file;
	if(! (-e $opt_file)){
		print "$opt_file DNE";
	}else{
		print "---Opening file: \"$opt_file\"---\n";
	}
}

if(defined $opt_sort){								#sort the directory to access the files by smallest first
	$params{'sortBySize'} = $opt_sort;
	print("---SORTING DIRECTORY FILES BY SIZE---\n");
}

if(defined $opt_buckets){									#set the number of buckets to run
	$params{'buckets'} = $opt_buckets;
}			

if(defined $opt_index){										#start at a certain file given an index
	$params{'index'} = $opt_index;
}

if(defined $opt_stopwords){
	$params{'exclude_stopwords'} = 1;
	print("---ELIMINATING STOP WORDS---\n")				#have the debug print statements
}

if(defined $opt_import_meta){
	$params{'import_meta'} = 1;
	print("---Importing MetaMap Data---\n");				#grab metamap file instead of make them
}else{
	$params{'import_meta'} = 0;
	print("---Creating MetaMap Data---\n");
}

if(defined $opt_prefix){									#get the word prefix character count
	$params{'prefix'} = $opt_prefix;
}
if(defined $opt_suffix){									#get the word suffix character count
	$params{'suffix'} = $opt_suffix;
}

if(defined $opt_weka_type){
	$params{'weka_type'} = $opt_weka_type;
	print("---RUNNING $weka_type WEKA---\n");				#average the weka accuracies
}

if(defined $opt_weka_size){
	$params{'weka_size'} = $opt_weka_size;
	print("---MAXIMUM WEKA MEMORY = $weka_size---\n");		#average the weka accuracies
}	

#help screen
sub showHelp{
	print("######          THIS PROGRAM TURNS NANOPARTICLE TEXTS         ######\n");
	print("######         INTO ARFF FILES AND WEKA ACCURACY FILES        ######\n");
	print("######        BASED ON THE NANOPARTICLE CHARACTERISTICS       ######\n");
	print("######          FOUND FROM THE PRE-ANNOTATED ARTICLES         ######\n");
	print("\n");
	print("\n");
	print("--help             Opens this help screen\n");
	print("\n");
	print("*** REQUIRED PARAMETERS ***\n");
	print("--dir STR          Defines the directory of a set of articles\n");
	print("--features STR[s]  Get the list of features you want to use for the set\n");
	print("                        -->   \"ortho morph text pos cui sem\"\n");
	print("\n");
	print("*** OPTIONAL PARAMETERS ***\n");
	print("--debug            Runs the program with debugging print statements\n");
	print("--process STR      Decide how to run NNER (by method or by file)\n");
	print("                      --> \"file\"=each method processes the file before going to the next\n");
	print("                      --> \"method\"=each file is run in the method before going to the next\n");
	print("--index NUM        Starts the program at a certain index number in a directory\n");
	print("--file STR         Defines the file source of a single article\n");
	print("--sort             Option to sort the directory files by size\n");
	print("--import_meta      Runs the program with the pre-made meta data\n");
	print("--stopwords        Eliminates stop words from vectors in the ARFF files\n");
	print("--buckets NUM      The number of buckets for the k-fold cross validation\n");
	print("--prefix NUM       Sets the prefix character amount for morph features\n");
	print("--suffix NUM       Sets the suffix character amount for morph features\n");
	print("--weka_type STR    Sets the type of weka algorithm to use on the data\n");
	print("--weka_size STR    Sets the maximum memory value to run weka with\n");
	print("                         --> (ex. -Xmx2G, -Xmx6G, -Xmx64G)\n");
	print("\n");
	print("*** Example command: ***\n");
	print("perl NER12.pl --dir eon2 --debug --fts=\"ortho morph text pos cui sem\" --buckets=5 --import --index=18 --weka --average --weka_type weka.classifiers.functions.SMO --weka_dir SMO --weka_size=\"-Xmx6G\"\n");
}


#  function to output minimal usage notes
sub minimalUsageNotes {
    
    print "Usage: NanoB2BNER.pl --dir DIRECTORYNAME --fts FEATURESET [OPTIONS]\n";
    &askHelp();
    exit;
}

#  function to output the version number
sub showVersion {
    print '$Id: NanoB2BNER.pl,v 1.00 2017/02/22 13:47:05 btmcinnes Exp $';
    print "\nCopyright (c) 2017, Megan Charity & Bridget McInnes\n";
}

#  function to output "ask for help" message when user's goofed
sub askHelp {
    print STDERR "Type MetaMapDataStructures.pl --help for help.\n";
}
    

#########################		test code 		######################

my $nner = NanoB2B::NER->new(\%params);
if($process eq "file"){
	$nner->nerByFile();
}elsif($process eq "method"){
	$nner->nerByMethod();
}else{
	print("***ERROR: INVALID PROCESS METHOD FOR NNER!***\n");
	exit;
}
