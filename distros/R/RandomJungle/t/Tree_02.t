use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Spec;
use Test::More;
use Test::Warn;

use RandomJungle::Jungle;
use RandomJungle::TestData qw( get_exp_data );

our $VERSION = 0.01;

# This file contains tests for the following methods in RandomJungle::Tree:

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

# Get a tree for testing

my $tree_id = 1;
my $exp_tree_data = $exp->{XML}{treedata}{$tree_id};

my %params = (  id => $tree_id,
				var_id_str => $exp_tree_data->{varID},
				values_str => $exp_tree_data->{values},
				branches_str => $exp_tree_data->{branches}, );

my @all_node_vis = sort { $a <=> $b } ( keys %{ $exp_tree_data->{nodes_at_vector_i} } );

my $tree = RandomJungle::Tree->new( %params );

# Retrieve node by vector index
{
	# get_node_by_vector_index()

	my $retval = $tree->get_node_by_vector_index();
	is( $retval, undef, 'get_node_by_vector_index() returns undef when no params are specified' );
	like( $tree->err_str, qr/undefined/,
		  'get_node_by_vector_index() sets err_str when no params are specified' );

	$retval = $tree->get_node_by_vector_index( 'invalid' );
	is( $retval, undef, 'get_node_by_vector_index() returns undef for invalid vector index (non-numeric)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_node_by_vector_index() sets err_str for invalid vector index (non-numeric)' );

	$retval = $tree->get_node_by_vector_index( 10000 );
	is( $retval, undef, 'get_node_by_vector_index() returns undef for invalid vector index (out of bounds)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_node_by_vector_index() sets err_str for invalid vector index (out of bounds)' );

	# check different node types:  non-terminal (0), terminal (5)
	foreach my $vi ( @all_node_vis )
	{
		my $node = $tree->get_node_by_vector_index( $vi );

		is( ref( $node ), 'RandomJungle::Tree::Node',
			"get_node_by_vector_index() returns a RandomJungle::Tree::Node object for vector index ($vi)" );

		check_node_content( $node, $exp_tree_data->{nodes_at_vector_i}{$vi} );
	}
}

# Retrieve pre-defined node sets
{
	# get_root_node()

	my $vi = $tree->get_root_node;
	is( $vi, 0, 'get_root_node() returns vector index 0' );

	# get_root_node( as_node => 0 )

	$vi = $tree->get_root_node( as_node => 0 );
	is( $vi, 0, 'get_root_node( as_node => 0 ) returns vector index 0' );

	# get_root_node( as_node => 1 )

	my $node = $tree->get_root_node( as_node => 1 );
	is( ref( $node ), 'RandomJungle::Tree::Node',
		'get_root_node( as_node => 1 ) returns a RandomJungle::Tree::Node object' );

	check_node_content( $node, $exp_tree_data->{nodes_at_vector_i}{0} );

	# get_all_nodes()

	my $aref = $tree->get_all_nodes;
	is( ref( $aref ), 'ARRAY', 'Return type from get_all_nodes()' );
	is_deeply( $aref, \@all_node_vis, 'Content returned from get_all_nodes()' );

	# get_all_nodes( as_node => 0 )

	$aref = $tree->get_all_nodes( as_node => 0 );
	is( ref( $aref ), 'ARRAY', 'Return type from get_all_nodes( as_node => 0 )' );
	is_deeply( $aref, \@all_node_vis, 'Content returned from get_all_nodes( as_node => 0 )' );

	# get_all_nodes( as_node => 1 )

	$aref = $tree->get_all_nodes( as_node => 1 );
	is( ref( $aref ), 'ARRAY', 'Return type from get_all_nodes( as_node => 1 )' );

	foreach my $node ( @$aref )
	{
		is( ref( $node ), 'RandomJungle::Tree::Node',
			'get_all_nodes( as_node => 1 ) returns a RandomJungle::Tree::Node object' );
		check_node_content( $node, $exp_tree_data->{nodes_at_vector_i}{ $node->get_vector_index } );
	}

	# get_terminal_nodes()

	$aref = $tree->get_terminal_nodes;
	is( ref( $aref ), 'ARRAY', 'Return type from get_terminal_nodes()' );

	# get_terminal_nodes( as_node => 0 )

	$aref = $tree->get_terminal_nodes( as_node => 0 );
	is( ref( $aref ), 'ARRAY', 'Return type from get_terminal_nodes( as_node => 0 )' );

	# get_terminal_nodes( as_node => 1 )

	$aref = $tree->get_terminal_nodes( as_node => 1 );
	is( ref( $aref ), 'ARRAY', 'Return type from get_terminal_nodes( as_node => 1 )' );

	foreach my $node ( @$aref )
	{
		is( ref( $node ), 'RandomJungle::Tree::Node',
			'get_terminal_nodes( as_node => 1 ) returns a RandomJungle::Tree::Node object' );
		check_node_content( $node, $exp_tree_data->{nodes_at_vector_i}{ $node->get_vector_index } );
	}
}

# Retrieve information about relationships between nodes
{
	# get_parent_of_vector_index( $vi )

	my $retval = $tree->get_parent_of_vector_index();
	is( $retval, undef, 'get_parent_of_vector_index() returns undef when no params are specified' );
	like( $tree->err_str, qr/undefined/,
		  'get_parent_of_vector_index() sets err_str when no params are specified' );

	$retval = $tree->get_parent_of_vector_index( 'invalid' );
	is( $retval, undef, 'get_parent_of_vector_index() returns undef for invalid vector index (non-numeric)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_parent_of_vector_index() sets err_str for invalid vector index (non-numeric)' );

	$retval = $tree->get_parent_of_vector_index( 10000 );
	is( $retval, undef, 'get_parent_of_vector_index() returns undef for invalid vector index (out of bounds)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_parent_of_vector_index() sets err_str for invalid vector index (out of bounds)' );

	$retval = $tree->get_parent_of_vector_index( 0 );
	is( $retval, undef, 'get_parent_of_vector_index() returns undef for vector index 0 (root node)' );
	like( $tree->err_str, qr/has no parent/,
		  'get_parent_of_vector_index() sets err_str for vector index 0 (root node)' );

	foreach my $vi ( @all_node_vis )
	{
		next if $vi == 0; # skip root
		my $vi_of_parent = $tree->get_parent_of_vector_index( $vi );
		is( $vi_of_parent, $exp_tree_data->{nodes_at_vector_i}{$vi}{index_of_parent_node},
			"Return value of get_parent_of_vector_index() for vector index $vi" );
	}

	# get_parent_of_vector_index( $vi, as_node => 0 )

	foreach my $vi ( @all_node_vis )
	{
		next if $vi == 0; # skip root
		my $vi_of_parent = $tree->get_parent_of_vector_index( $vi, as_node => 0  );
		is( $vi_of_parent, $exp_tree_data->{nodes_at_vector_i}{$vi}{index_of_parent_node},
			"Return value of get_parent_of_vector_index( as_node => 0 ) for vector index $vi" );
	}

	# get_parent_of_vector_index( $vi, as_node => 1 )

	$retval = $tree->get_parent_of_vector_index( 'invalid', as_node => 1 );
	is( $retval, undef, 'get_parent_of_vector_index( as_node => 1 ) returns undef for invalid vector index (non-numeric)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_parent_of_vector_index( as_node => 1 ) sets err_str for invalid vector index (non-numeric)' );

	$retval = $tree->get_parent_of_vector_index( 10000, as_node => 1 );
	is( $retval, undef, 'get_parent_of_vector_index( as_node => 1 ) returns undef for invalid vector index (out of bounds)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_parent_of_vector_index( as_node => 1 ) sets err_str for invalid vector index (out of bounds)' );

	$retval = $tree->get_parent_of_vector_index( 0, as_node => 1 );
	is( $retval, undef, 'get_parent_of_vector_index( as_node => 1 ) returns undef for vector index 0 (root node)' );
	like( $tree->err_str, qr/has no parent/,
		  'get_parent_of_vector_index( as_node => 1 ) sets err_str for vector index 0 (root node)' );

	foreach my $vi ( @all_node_vis )
	{
		next if $vi == 0; # skip root
		my $node = $tree->get_parent_of_vector_index( $vi, as_node => 1 );
		is( ref( $node ), 'RandomJungle::Tree::Node',
			'get_parent_of_vector_index( as_node => 1 ) returns a RandomJungle::Tree::Node object' );
		my $parent_vi = $exp_tree_data->{nodes_at_vector_i}{$vi}{index_of_parent_node};
		check_node_content( $node, $exp_tree_data->{nodes_at_vector_i}{$parent_vi} );
	}

	# get_path_to_vector_index( $vi )

	$retval = $tree->get_path_to_vector_index();
	is( $retval, undef, 'get_path_to_vector_index() returns undef when no params are specified' );
	like( $tree->err_str, qr/undefined/,
		  'get_path_to_vector_index() sets err_str when no params are specified' );

	$retval = $tree->get_path_to_vector_index( 'invalid' );
	is( $retval, undef, 'get_path_to_vector_index() returns undef for invalid vector index (non-numeric)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_path_to_vector_index() sets err_str for invalid vector index (non-numeric)' );

	$retval = $tree->get_path_to_vector_index( 10000 );
	is( $retval, undef, 'get_path_to_vector_index() returns undef for invalid vector index (out of bounds)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_path_to_vector_index() sets err_str for invalid vector index (out of bounds)' );

	foreach my $vi ( @all_node_vis )
	{
		my $aref = $tree->get_path_to_vector_index( $vi );
		is( ref( $aref ), 'ARRAY', "Return type of get_path_to_vector_index() for vector index $vi" );
		is_deeply( $aref, $exp_tree_data->{nodes_at_vector_i}{$vi}{path},
			"Path returned from get_path_to_vector_index() for vector index $vi" );
	}

	# get_depth_of_vector_index( $vi )

	$retval = $tree->get_depth_of_vector_index();
	is( $retval, undef, 'get_depth_of_vector_index() returns undef when no params are specified' );
	like( $tree->err_str, qr/undefined/,
		  'get_depth_of_vector_index() warns when no params are specified' );

	$retval = $tree->get_depth_of_vector_index( 'invalid' );
	is( $retval, undef, 'get_depth_of_vector_index() returns undef for invalid vector index (non-numeric)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_depth_of_vector_index() warns for invalid vector index (non-numeric)' );

	$retval = $tree->get_depth_of_vector_index( 10000 );
	is( $retval, undef, 'get_depth_of_vector_index() returns undef for invalid vector index (out of bounds)' );
	like( $tree->err_str, qr/Invalid/,
		  'get_depth_of_vector_index() warns for invalid vector index (out of bounds)' );

	foreach my $vi ( @all_node_vis )
	{
		my $depth = $tree->get_depth_of_vector_index( $vi );
		is( $depth, scalar @{ $exp_tree_data->{nodes_at_vector_i}{$vi}{path} },
			"Depth returned from get_depth_of_vector_index() for vector index $vi" );
	}
}

# Retrieve information about the max depth of the tree
{
	my $max_depth = 0;

	foreach my $vi ( @all_node_vis )
	{
		$max_depth = scalar @{ $exp_tree_data->{nodes_at_vector_i}{$vi}{path} } > $max_depth ?
					 scalar @{ $exp_tree_data->{nodes_at_vector_i}{$vi}{path} } : $max_depth;
	}

	my @max_depth_vis = grep
						{
							scalar @{ $exp_tree_data->{nodes_at_vector_i}{$_}{path} } == $max_depth
						} @all_node_vis;

	my $expected = { depth => $max_depth, vector_indices => \@max_depth_vis };

	my $href = $tree->max_node_depth;
	is( ref( $href ), 'HASH', 'Return type of max_node_depth()' );
	is_deeply( $href, $expected, 'Content returned from max_node_depth()' );
}

# Error handling
{
	# set_err()

	$tree->set_err();
	is( $tree->err_str, '', 'set_err() initializes error string if undef' );

	$tree->set_err( 'boom' );
	is( $tree->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $tree->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

#*************************************************

sub check_node_content
{
	# Takes a ::Node object and a href containing expected data
	# $exp_data must contain the following keys:  vector_index, is_terminal, index_of_parent_node
	# $exp_data must also contain terminal_value for terminal nodes, and variable_index and
	# next_vector_i for non-terminal nodes.  next_vector_i is an aref for genotypes 0, 1, 2.
	# Note:  This sub is intended to check the value of content only - see the test file(s) for
	# RJ::Tree::Node objects for complete tests of Node behavior.
	my ( $node, $exp_data ) = @_;

	# Attributes common to both terminal and non-terminal nodes

	is( $node->get_vector_index, $exp_data->{vector_index}, "Value of vector index for node ($exp_data->{vector_index})" );
	is( $node->get_vector_index_of_parent, $exp_data->{index_of_parent_node}, 'Value of parent vector index for node' );
	is( $node->is_terminal, $exp_data->{is_terminal}, 'is_terminal status for node' );

	if( $node->is_terminal )
	{
		is( $node->get_terminal_value, $exp_data->{terminal_value}, 'Terminal value for node' );
	}
	else
	{
		is( $node->get_variable_index, $exp_data->{variable_index}, 'Value of variable index for node' );

		foreach my $genotype ( 0 .. 2 )
		{
			is( $node->get_vector_index_for_genotype( $genotype ),
				$exp_data->{next_vector_i}[$genotype], "Next vector index given genotype ($genotype)" );
		}
	}
}

#*************************************************

done_testing();
