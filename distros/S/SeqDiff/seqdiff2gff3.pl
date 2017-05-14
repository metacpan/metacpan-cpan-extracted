#!/usr/bin/perl -w

use strict;

# include a path to the front of @INC to find the package
BEGIN {
	unshift @INC, '/Volumes/r4/t4/ug/daniel/svn/BioPerl_Scripts/SeqDiff/';
}

use SeqDiff;
use Bio::SeqFeatureI;
use Bio::SeqIO;
use URI::Escape;
use Data::Dumper;


sub make_seq_object_from_file {
	my $file_name = shift;
	my $seqio_object  = Bio::SeqIO->new(
		-file 		=> $file_name,
		-format 	=> 'genbank'
	);
	$file_name =~ s/(\S+)?\..*/$1/g;
	return $seqio_object->next_seq;
}

sub get_modified_date {
	my $seq = shift;
	my $ann = $seq->annotation;
	my ($date) = $ann->get_Annotations('date_changed');
	return $date->value;
}

sub get_score {
	my $hash_ref = shift;

	my $score = 0;
	while ( my ($key, $value) = each %{$hash_ref} ) {
		$score += scalar(@{$value}) if ($key eq 'gained' || $key eq 'lost');
		$score += get_score($value) if (ref($value) =~ /HASH/);
	}
	return $score;
}

my $seq_OLD = make_seq_object_from_file( $ARGV[0] );
my $seq_NEW = make_seq_object_from_file( $ARGV[1] );

my $seqdiff = SeqDiff->new(
	-old 			=> $seq_OLD,
	-new 			=> $seq_NEW,
);

$seqdiff->match_features();				


my $modified_date_old = get_modified_date( $seqdiff->old_seq );
my $modified_date_new = get_modified_date( $seqdiff->new_seq );

my $seqid = $seqdiff->new_seq->accession_number;

my $source 	= "SeqDiff";
my $type 	= "SeqDiff_" . $modified_date_old . "_vs_" . $modified_date_new;

print "##gff-version 3\n";

my $pairs_with_at_least_one_difference = 0;
while ( my $diff = $seqdiff->next() ) {			

	next unless ref $diff;	
	$pairs_with_at_least_one_difference++;

	my ($start, $end, $score, $strand, $phase, %attributes);
	
	my $reference_feature = $diff->{'new'};
	$start = $reference_feature->start;
	$end   = $reference_feature->end;
	
	$score = get_score($diff->{'comparison'});

	$strand = defined($reference_feature->strand)
		? $reference_feature->strand
		: ".";
	
	$phase = "."; 	# not implemented yet
	
	$attributes{'ID'} = $pairs_with_at_least_one_difference;
	$attributes{'Name'} = $reference_feature->display_name . "." $attributes{'ID'} . ".seqdiff";

	my $attributes_str;
	while ( my($key, $value) = each %attributes ) {
		$value = join(',', @{$value}) if ( ref($value) =~ /ARRAY/ );
		$attributes_str .= $key . '=' . uri_escape($value) . ';' if ($value);
	}

	my $gff_line = join("\t", ($seqid, $source, $type, $start, $end, $score, $strand, $phase, $attributes_str));
	
	print $gff_line . "\n";
}




__END__

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
