#!/usr/bin/perl -w

use strict;

# include a path to the front of @INC to find the package
BEGIN {
	unshift @INC, '/Volumes/r4/t4/ug/daniel/svn/BioPerl_Scripts/SeqDiff/';
}

# include some necessary code...
use SeqDiff;
use Bio::SeqFeatureI;
use Bio::SeqIO;
use YAML;

# turn off buffering...print after every print()
$| = 1;

# makes SeqIO objects
sub make_seq_object_from_file {
	my $file_name = shift;
	my $seqio_object  = Bio::SeqIO->new(
		-file 		=> $file_name,
		-format 	=> 'genbank'
	);
	$file_name =~ s/(\S+)?\..*/$1/g;
	return $seqio_object->next_seq;
}

# make the seq objects we want to compare from files given on the commandline
print "making Seq objects...\n";
my $seq_OLD = make_seq_object_from_file( $ARGV[0] );
my $seq_NEW = make_seq_object_from_file( $ARGV[1] );

# get a new instance of the SeqDiff package
print "getting a new SeqDiff object...\n";
my $seqdiff = SeqDiff->new(
	-old 		=> $seq_OLD,
	-new 		=> $seq_NEW,
);

# match the features
print "matching features...\n";
$seqdiff->match_features();				

# loop through the pairs of matching features...
print "calculating differences...\n\n";

my $pairs_with_at_least_one_difference = 0;
while ( my $diff = $seqdiff->next() ) {			

	# skip blank comparisons (the two objects were the same)
	next unless ref $diff;	
	$pairs_with_at_least_one_difference++;

	# use YAML to print it out	
	print Dump($diff->{'comparison'});	
	
}

# get some statistics...
my @lost 	= $seqdiff->get_lost_features();
my @gained 	= $seqdiff->get_gained_features();

my $num_features_from_old 	= scalar $seqdiff->old_seq->get_SeqFeatures();
my $num_features_from_new 	= scalar $seqdiff->new_seq->get_SeqFeatures();

my $total_num_comparisons 		= $seqdiff->get_total_num_attempted_matches();
my $total_possible_comparisons 	= ($num_features_from_old * $num_features_from_new);

# ...and print them
printf(
	"Compared %d of %d features from OLD (%d lost).\n",
	($num_features_from_old - scalar(@lost)),
	$num_features_from_old,
	scalar @lost
);

printf(
	"Compared %d of %d features from NEW (%d gained).\n",
	($num_features_from_new - scalar(@gained)),
	$num_features_from_new,
	scalar @gained
);

printf(
	"Did %d of %d total comparisons possible (%0.2f%%).\n",
	$total_num_comparisons,
	$total_possible_comparisons,
	($total_num_comparisons / $total_possible_comparisons)
);