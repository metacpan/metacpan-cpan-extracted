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
BEGIN { use_ok( 'RandomJungle::Tree::Node' ); }

# Object creation and initialization
{
	# new()

	my $retval = RandomJungle::Tree::Node->new();
	is( $retval, undef, 'new() returns undef when no params are specified' );
	like( $RandomJungle::Tree::Node::ERROR, qr/not defined/,
		  'new() sets $ERROR when no params are specified' );

	# construct a ::Node manually for this test (usually done via ::Tree only)

	my $tree_id = 1;
	my $vector_i = 0;
	my $node_data = get_node_data( $tree_id, $vector_i );

	$retval = RandomJungle::Tree::Node->new( vector_index => $vector_i );
	is( $retval, undef, 'new() returns undef when node_data is not specified' );
	like( $RandomJungle::Tree::Node::ERROR, qr/not defined/,
		  'new() sets $ERROR when node_data is not specified' );

	$retval = RandomJungle::Tree::Node->new( node_data => $node_data );
	is( $retval, undef, 'new() returns undef when vector_index is not specified' );
	like( $RandomJungle::Tree::Node::ERROR, qr/not defined/,
		  'new() sets $ERROR when vector_index is not specified' );

	$retval = RandomJungle::Tree::Node->new( vector_index => $vector_i, node_data => {} );
	is( $retval, undef, 'new() returns undef when node_data is invalid' );
	like( $RandomJungle::Tree::Node::ERROR, qr/Missing node data/,
		  'new() sets $ERROR when node_data is invalid' );

	my $node = RandomJungle::Tree::Node->new( vector_index => $vector_i, node_data => $node_data );

	is( ref( $node ), 'RandomJungle::Tree::Node', 'Object creation and initialization' );
}

# Retrieve basic node data for a non-terminal node
{
	my $tree_id = 1;
	my $vector_i = 0;

	# Get a node from a tree in the RJ DB (storing/retrieving a ::Tree is tested elsewhere)
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	my $tree = $rj->get_tree_by_id( $tree_id );
	my $node = $tree->get_node_by_vector_index( $vector_i );

	my $exp_href = $exp->{XML}{treedata}{$tree_id}{nodes_at_vector_i}{$vector_i};

	# is_terminal()
	# Note:  the result is hard-coded to ensure a non-terminal node is tested

	my $retval = $node->is_terminal;
	#is( $retval, $exp_href->{is_terminal}, 'is_terminal() returns 0 for a non-terminal node' );
	is( $retval, '0', 'is_terminal() returns 0 for a non-terminal node' );

	# get_terminal_value()

	$retval = $node->get_terminal_value;
	is( $retval, undef, 'get_terminal_value() returns undef for a non-terminal node' );

	# get_variable_index()

	$retval = $node->get_variable_index;
	is( $retval, $exp_href->{variable_index}, 'get_variable_index() for a non-terminal node' );
	
	# get_vector_index()

	$retval = $node->get_vector_index;
	is( $retval, $exp_href->{vector_index}, 'get_vector_index() for a non-terminal node' );

	# get_vector_index_of_parent()
	# Note:  the result is hard-coded to ensure the root node is tested

	$retval = $node->get_vector_index_of_parent;
	is( $retval, undef, "get_vector_index_of_parent() returns undef for the root node (index $vector_i)" );

	# get_vector_index_for_genotype()

	$retval = $node->get_vector_index_for_genotype();
	is( $retval, undef, 'get_vector_index_for_genotype() returns undef when genotype is not specified' );
	like( $node->err_str, qr/Genotype is not defined/,
		  'get_vector_index_for_genotype() sets err_str when genotype is not specified' );

	$retval = $node->get_vector_index_for_genotype( 'invalid' );
	is( $retval, undef, 'get_vector_index_for_genotype() returns undef when genotype is not valid' );
	like( $node->err_str, qr/Invalid genotype/,
		  'get_vector_index_for_genotype() sets err_str when genotype is not valid' );

	foreach my $genotype ( 0 .. 2 )
	{
		$retval = $node->get_vector_index_for_genotype( $genotype );
		is( $retval, $exp_href->{next_vector_i}[$genotype],
			'get_vector_index_for_genotype() for a non-terminal node' );
	}
}

# Retrieve basic node data for a terminal node
{
	my $tree_id = 1;
	my $vector_i = 5;

	# Get a node from a tree in the RJ DB (storing/retrieving a ::Tree is tested elsewhere)
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	my $tree = $rj->get_tree_by_id( $tree_id );
	my $node = $tree->get_node_by_vector_index( $vector_i );

	my $exp_href = $exp->{XML}{treedata}{$tree_id}{nodes_at_vector_i}{$vector_i};

	# is_terminal()
	# Note:  the result is hard-coded to ensure a terminal node is tested

	my $retval = $node->is_terminal;
	is( $retval, '1', 'is_terminal() returns 0 for a terminal node' );

	# get_terminal_value()

	$retval = $node->get_terminal_value;
	is( $retval, $exp_href->{terminal_value}, 'Return value of get_terminal_value() for a terminal node' );

	# get_variable_index()

	$retval = $node->get_variable_index;
	is( $retval, undef, 'get_variable_index() returns undef for a terminal node' );
	
	# get_vector_index()

	$retval = $node->get_vector_index;
	is( $retval, $exp_href->{vector_index}, 'get_vector_index() for a terminal node' );

	# get_vector_index_of_parent()

	$retval = $node->get_vector_index_of_parent;
	is( $retval, $exp_href->{index_of_parent_node}, "get_vector_index_of_parent() for a non-root node (index $vector_i)" );

	# get_vector_index_for_genotype()

	$retval = $node->get_vector_index_for_genotype();
	is( $retval, undef, 'get_vector_index_for_genotype() returns undef for a terminal node' );
	like( $node->err_str, qr/terminal node/,
		  'get_vector_index_for_genotype() sets err_str for a terminal node' );
}

# Error handling
{
	my $tree_id = 1;
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	my $tree = $rj->get_tree_by_id( $tree_id );
	my $node = $tree->get_root_node( as_node => 1 );

	# set_err()

	$node->set_err();
	is( $node->err_str, '', 'set_err() initializes error string if undef' );

	$node->set_err( 'boom' );
	is( $node->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $node->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

done_testing();

#*************************************************

sub get_node_data
{
	my ( $tree_id, $vector_i ) = @_;

	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	my $tree = $rj->get_tree_by_id( $tree_id );

	# break encapsulation b/c ::Node is supposed to only be called by ::Tree, so
	# pull the ::Tree's structure out of the object to pass to ::Node->new()
	my $node_data = $tree->{rj_tree}[$vector_i];

	return $node_data;
}
