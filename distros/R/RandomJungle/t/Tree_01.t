use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Spec;
use Test::More;
use Test::Warn;

use RandomJungle::Jungle;
use RandomJungle::TestData qw( get_exp_data );

our $VERSION = 0.02;

# This file contains tests for the following methods in RandomJungle::Tree:
#   new( %params )
#   new( %params ) [where %params contains the 'variable_labels' key]
#	id()
#   get_variables()
#   get_variables( variable_labels => 1 )
#   classify_data( $data ) [including validation of $data]
#   classify_data( $data, as_node => 1 )
#   classify_data( $data, skip_validation => 1 )

#*************************************************

# all data files should be in the same dir as this test script
# if this test file is run directly ('perl *.t') then $cwd is complete
# if the test file is run via 'prove' from one dir up, we need to add 't' to the path
my $cwd = getcwd();
my $path = ( File::Spec->splitdir( $cwd ) )[-1] eq 't' ? $cwd : File::Spec->catdir( $cwd, 't' );

my $db_file  = File::Spec->catfile( $path, 'RJ_File_DB_test.dbm' );

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Load module
BEGIN { use_ok( 'RandomJungle::Tree' ); }

# Object creation and initialization
{
	# new()

	my $retval = RandomJungle::Tree->new();
	is( $retval, undef, 'new() returns undef when no params are specified' );
	like( $RandomJungle::Tree::ERROR, qr/not defined/,
		  'new() sets $ERROR when no params are specified' );

	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	foreach my $k ( keys %params )
	{
		my %p = %params;
		delete $p{$k};

		my $retval = RandomJungle::Tree->new( %p );
		is( $retval, undef, "new() returns undef when $k is not defined" );
		like( $RandomJungle::Tree::ERROR, qr/not defined/,
			  "new() sets \$ERROR when $k is not defined" );
	}

	my $tree = RandomJungle::Tree->new( %params );
	is( ref( $tree ), 'RandomJungle::Tree', 'Object creation and initialization - required params only' );

	$tree = RandomJungle::Tree->new( %params, variable_labels => $exp->{RAW}{variable_labels} );
	is( ref( $tree ), 'RandomJungle::Tree', 'Object creation and initialization with optional variable_labels param' );
}

# Mutate tree structures for misc tests
{
	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	# new() - detect invalid or unexpected tree structures

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	$params{values_str} =~ s/1/X/; # non-digit

	my $retval = RandomJungle::Tree->new( %params );
	is( $retval, undef, 'new() returns undef when non-digits are detected in the values string' );
	like( $RandomJungle::Tree::ERROR, qr/Unexpected value/,
		  'new() sets $ERROR when non-digits are detected in the values string' );

	# get_variables() - pretend _is_variable_index_0_used() returns true

	%params = ( id => $tree_id,
				var_id_str => $exp_tree_data->{varID},
				values_str => $exp_tree_data->{values},
				branches_str => $exp_tree_data->{branches}, );

	$params{branches_str} =~ s/0,0/0,1/;
	my $tree = RandomJungle::Tree->new( %params );
	my @var_indices_used = @{ $exp->{XML}{treedata}{$tree_id}{var_indices_used_in_tree} }; # copy
	unshift( @var_indices_used, 0 ); # add 0 to the front

	my $aref = $tree->get_variables; # variable indices
	is( ref( $aref ), 'ARRAY', 'Return type from get_variables (no params), 0 used' );
	is_deeply( $aref, \@var_indices_used, 'Content returned from get_variables (no params), 0 used' );
}

# Get basic data
{
	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	my $tree = RandomJungle::Tree->new( %params );

	# id()

	is( $tree->id, $tree_id, 'Retrieve tree ID' );
}

# Get variable info
{
	# get_variables() - no variable_labels

	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	my $tree = RandomJungle::Tree->new( %params );
	my $var_indices_used = $exp->{XML}{treedata}{$tree_id}{var_indices_used_in_tree};

	my $aref = $tree->get_variables; # variable indices
	is( ref( $aref ), 'ARRAY', 'Return type from get_variables (no params)' );
	is_deeply( $aref, $var_indices_used, 'Content returned from get_variables (no params)' );

	my $href = $tree->get_variables( variable_labels => 1 );
	is( $href, undef, 'get_variables() returns undef when called with variable_labels but not in new()' );
	like( $tree->err_str, qr/labels were not provided/, 'get_variables() sets err_str when called with variable_labels but not in new()' );

	# get_variables() - variable_labels

	$tree = RandomJungle::Tree->new( %params, variable_labels => $exp->{RAW}{variable_labels} );

	$aref = $tree->get_variables( variable_labels => 0 ); # variable indices
	is( ref( $aref ), 'ARRAY', 'Return type from get_variables ( variable_labels => 0 )' );
	is_deeply( $aref, $var_indices_used, 'Content returned from get_variables ( variable_labels => 0 )' );

	$href = $tree->get_variables( variable_labels => 1 ); # $href->{$label} = $index
	is( ref( $href ), 'HASH', 'Return type from get_variables ( variable_labels => 1 )' );

	my %var_lbl2i = map { $exp->{RAW}{variable_labels}[$_] => $_ } @$var_indices_used;
	is_deeply( $href, \%var_lbl2i, 'Content returned from get_variables ( variable_labels => 1 )' );
}

# Classify data
{
	# classify_data() - detect invalid $data

	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	my $tree = RandomJungle::Tree->new( %params );

	my $retval = $tree->classify_data();
	is( $retval, undef, 'classify_data() returns undef when $data is not defined' );
	like( $tree->err_str, qr/No data provided/,
		  'classify_data() warns when $data is not defined' );

	$retval = $tree->classify_data( { href => 1 } );
	is( $retval, undef, 'classify_data() returns undef when $data is not an aref' );
	like( $tree->err_str, qr/reference to an array/,
		  'classify_data() warns when $data is not an aref' );

	$retval = $tree->classify_data( [ 0, 1, 2, 3, 2, 1, 0 ] );
	is( $retval, undef, 'classify_data() returns undef when $data contains invalid element (3)' );
	like( $tree->err_str, qr/Invalid genotype/,
		  'classify_data() warns when $data contains invalid element (3)' );

	$retval = $tree->classify_data( [ 0, 1, 2, 'a', 2, 1, 0 ] );
	is( $retval, undef, 'classify_data() returns undef when $data contains invalid element (a)' );
	like( $tree->err_str, qr/Invalid genotype/,
		  'classify_data() warns when $data contains invalid element (a)' );

	$retval = $tree->classify_data( [ 0, 1, 2, undef, 2, 1, 0 ] );
	is( $retval, undef, 'classify_data() returns undef when $data contains an undefined element' );
	like( $tree->err_str, qr/not defined/,
		  'classify_data() warns when $data contains an undefined element' );
}

# Classify data
{
	# classify_data() - check classification results

	my $tree_id = 1;
	my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

	my %params = (  id => $tree_id,
					var_id_str => $exp_tree_data->{varID},
					values_str => $exp_tree_data->{values},
					branches_str => $exp_tree_data->{branches}, );

	my $tree = RandomJungle::Tree->new( %params );

	# Get sample data from the RJ DB (ability to accurately store/retrieve sample data is
	# tested in the test files for RAW, DB, and Jungle).

	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	my $sample_labels = $rj->get_sample_labels;

	foreach my $sample_label ( @$sample_labels )
	{
		my $exp_term_node_vi = $exp->{classification}{$tree_id}{$sample_label};
		my $exp_term_node_value = $exp_tree_data->{nodes_at_vector_i}{$exp_term_node_vi}{terminal_value};

		my $href = $rj->get_sample_data_by_label( label => $sample_label );

		my $pred_pheno = $tree->classify_data( $href->{classification_data} );

		is( $pred_pheno, $exp_term_node_value,
			"Predicted phenotype from classify_data() (sample $sample_label)" );

		$pred_pheno = $tree->classify_data( $href->{classification_data}, as_node => 0 );

		is( $pred_pheno, $exp_term_node_value,
			"Predicted phenotype from classify_data( as_node => 0 ) (sample $sample_label)" );

		my $node_obj = $tree->classify_data( $href->{classification_data}, as_node => 1 );

		is( ref( $node_obj ), 'RandomJungle::Tree::Node',
			"classify_data() returns a RandomJungle::Tree::Node object when called with as_node (sample $sample_label)" );
		is( $node_obj->get_vector_index, $exp_term_node_vi,
			"Vector index of returned Node object from classify_data() (sample $sample_label)" );
		is( $node_obj->get_terminal_value, $exp_term_node_value,
			"Terminal value (predicted phenotype) of returned Node object from classify_data() (sample $sample_label)" );
	}

	# Detect errors in the classification data

	foreach my $sample_label ( $sample_labels->[0] )
	{
		my $exp_term_node_vi = $exp->{classification}{$tree_id}{$sample_label};
		my $exp_term_node_value = $exp_tree_data->{nodes_at_vector_i}{$exp_term_node_vi}{terminal_value};

		my $href = $rj->get_sample_data_by_label( label => $sample_label );
		splice( @{ $href->{classification_data} }, 0, scalar int @{ $href->{classification_data} } / 2 ); # cut in half

		my $pred_pheno = $tree->classify_data( $href->{classification_data} );
		is( $pred_pheno, undef, 'classify_data() returns undef when given truncated data' );
		like( $tree->err_str, qr/undef value obtained from data array/, 'classify_data() sets err_str when given truncated data' );
	}

	# Test with skip_validation => 1

	{
		my $retval = $tree->classify_data( [ 0, 1, 2, 'a', 2, 1, 0 ], skip_validation => 1 );
		is( $retval, undef, 'classify_data( skip_validation => 1 ) returns undef with invalid data' );
	}
}

#*************************************************

done_testing();
