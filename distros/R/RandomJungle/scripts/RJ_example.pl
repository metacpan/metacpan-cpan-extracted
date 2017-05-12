# This program demonstrates the basic methods of RandomJungle::Jungle and RandomJungle::Tree
# Input and output files are located in the /t directory

use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Spec;

use RandomJungle::Jungle;

our $VERSION = 0.01;

#*************************************************

my $cwd = getcwd();
my @dirs = File::Spec->splitdir( $cwd );
pop @dirs; # move up one dir
my $path = File::Spec->catdir( @dirs, 't' );

my $raw_pfile = File::Spec->catfile( $path, 'testdata_20samples_10vars.raw' );
my $oob_pfile = File::Spec->catfile( $path, 'testdata_20samples_10vars.oob' );
my $xml_pfile = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle.xml' );
my $db_pfile  = File::Spec->catfile( $path, 'RJ_modules_example.dbm' );

#*************************************************

my $rj = RandomJungle::Jungle->new( db_file => $db_pfile ) ||
	die $RandomJungle::Jungle::ERROR;

print "Loading data...\n";
$rj->store( xml_file => $xml_pfile, oob_file => $oob_pfile, raw_file => $raw_pfile ) ||
	die $rj->err_str;

my $summary = $rj->summary_data();
print "\nHere is a summary of the data that was loaded into $db_pfile:\n";
print Dumper $summary;

# These are all included in $summary so they will not be printed again
#my $href = $rj->get_filenames; # filenames specified in store()
#my $href = $rj->get_rj_input_params; # input params that were used when RJ was run
#my $aref = $rj->get_variable_labels; # (expected:  SEX PHENOTYPE var1 ...)
#my $aref = $rj->get_sample_labels; # from the IID column of the RAW file
#my $aref = $rj->get_tree_ids;

# Retrieve the first tree and run through a few samples

my $tree_ids = [ 1 ];
my $var_labels = $rj->get_variable_labels;

TREE:
foreach my $tree_id ( @$tree_ids )
{
	my $tree = $rj->get_tree_by_id( $tree_id ) ||
		do
		{
			warn $rj->err_str;
			next TREE;
		};

	my $samples_for_tree = $rj->get_oob_for_tree( $tree_id ) ||
		do
		{
			warn $rj->err_str;
			next TREE;
		};

	my $num_term_nodes = scalar @{ $tree->get_terminal_nodes };
	my $max_depth = $tree->max_node_depth->{depth};

	print "\nRetrieved tree [$tree_id] ($num_term_nodes terminal nodes, max depth = $max_depth)\n";
	print "State of samples:\n";
	print Dumper $samples_for_tree;
	print "Classifying OOB samples:\n";

	my %node_counts;
	my %accy = ( correct => 0, incorrect => 0 );

	SAMPLE:
	foreach my $s_label ( @{ $samples_for_tree->{oob_samples} } )
	{
		my $sample_data = $rj->get_sample_data_by_label( label => $s_label ) || warn $rj->err_str;

		print "\n  Retrieved data for sample [$s_label]:\n";
		print Dumper $sample_data;

		my $node = $tree->classify_data( $sample_data->{classification_data}, as_node => 1 ) ||
			do
			{
				warn $tree->err_str;
				next SAMPLE;
			};

		print "    Phenotype: $sample_data->{PHENOTYPE}, Predicted phenotype: ", $node->get_terminal_value, "\n";

		my $accy_key = $sample_data->{PHENOTYPE} == $node->get_terminal_value ? 'correct' : 'incorrect';
		$accy{$accy_key}++;

		my $path_vis = $tree->get_path_to_vector_index( $node->get_vector_index ) ||
			do
			{
				warn $tree->err_str;
				next SAMPLE;
			};

		$node_counts{ $node->get_vector_index }++;

		my $path_str =
			join( ' -> ',
					map
					{
						my $n = $tree->get_node_by_vector_index( $_ ); # skipping error check since internally derived
						my $var_i = $n->get_variable_index;
						my $label = defined $var_i ? $var_labels->[ $var_i ] : '(terminus)';
					} ( @$path_vis )
				);

		print "    Path: $path_str\n";
	}

	print "\n  Distribution of samples into terminal nodes (node vector index => count):\n";
	print Dumper \%node_counts;

	print "\n  Accuracy of classifications (OOB only): $accy{correct} correct / $accy{incorrect} incorrect\n";
}


