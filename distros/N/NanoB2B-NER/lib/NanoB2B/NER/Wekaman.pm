#!/usr/bin/perl
# NanoB2B-NER::NER::Wekaman
#
# Runs the ARFF files created by Arffman into weka accuracy files
# Version 1.5
#
# Program by Milk

package NanoB2B::NER::Wekaman;

use NanoB2B::UniversalRoutines;
use File::Path qw(make_path);			#makes sub directories	
use strict;
use warnings;

####          GLOBAL VARIABLES           ####

#option variables
my $program_dir;
my $classifier = "weka.classifiers.bayes.NaiveBayes";
my $weka_size = "Xmx4G";
my @features;
my $buckets = 10;
my $debug = 0;


#universal subroutines object
my %uniParams = ();
my $uniSub;


####      A SIDEKICK IS RECRUITED     ####

# construction method to create a new Wekaman object
# input  : $directory <-- the name of the directory for the files
#	 	   $features  <-- the set of features to run on [e.g. omtpcs]
#		   \$type      <-- the weka algorithm to run the set on [e.g. weka.classifiers.functions.SMO]
#		   \$weka_size <-- the size to for the memory allocation in the weka parameter [e.g. -Xmx6G]
#		   \$buckets   <-- the number of buckets used for the k-fold cross validation
#		   \$debug     <-- the set of features to run on [e.g. omtpcs]
# output : $self      <-- an instance of the Wekaman object
sub new {
	#grab class and parameters
    my $self = {};
    my $class = shift;
    return undef if(ref $class);
    my $params = shift;

    #bless this object
    bless $self, $class;
    $self->_init($params);

    #retrieve parameters for universal-routines
    $uniParams{'debug'} = $debug;
	$uniSub = NanoB2B::UniversalRoutines->new(\%uniParams);

	#return the object
    return $self;
}
#  method to initialize the NanoB2B::NER::Wekaman object.
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
	my $typeoption = $params->{'type'};
	my $sizeoption = $params->{'weka_size'};
    my $debugoption = $params->{'debug'};

    #set the global variables
    if(defined $debugoption){$debug = $debugoption;}
    if(defined $diroption){$program_dir = $diroption;}
    if(defined $bucketsNumoption){$buckets = $bucketsNumoption;}
    if(defined $ftsoption){@features = split(' ', $ftsoption); }
    if(defined $typeoption){$classifier = $typeoption};
    if(defined $sizeoption){$weka_size = $sizeoption};
}


###############			NOW BACK TO THE WEKAMAN 		################

#  runs the arff files through weka
#  input : $name <-- the name of the file to run through weka
#  output: (weka files)
sub weka_file{
	my $self = shift;
	my $name = shift;

	#split them up by sets
	my @sets = ();
	my $item = "_";
	foreach my $fs (@features){
		my $abbrev = substr($fs, 0, 1);		#add to abbreviations for the name
		$item .= $abbrev;
		push(@sets, $item);
	}

	#get the ending part of the classifier for the weka dir name
	my @b = split(/\./, $classifier);		
	my $weka_dir = $b[$#b];

	#run each set through metamap and save the accuracy file
	foreach my $set(@sets){
		#set up the new folder
		my $direct = "$program_dir/_WEKAS/$weka_dir/$name" . "_WEKA_DATA/$set";
		make_path($direct);

		#prep the output accuracy file and the test and train files
		my $acc = "WEKAMAN-$name/$set/";
		for(my $a = 1; $a <= $buckets; $a++){
			$| = 1;			
			$uniSub->printColorDebug("cyan", ("\r" . "$name - $set -- $a"));
			my $TRAIN = "$program_dir/_ARFF/$name" . "_ARFF/$set/_train/$name" . "_train-$a.arff";
			my $TEST = "$program_dir/_ARFF/$name" . "_ARFF/$set/_test/$name" . "_test-$a.arff";
			my $WEK = $direct . "/$name" . "_accuracy_$a";

			#run weka and output
			system "java $weka_size $classifier -T $TEST -t $TRAIN > $WEK";
		}
		$uniSub->printDebug("\n");
	}
}

1;