use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Spec;
use Test::More;
use Test::Warn;

use RandomJungle::TestData qw( get_exp_data );

our $VERSION = 0.01;

#*************************************************

# all data files should be in the same dir as this test script
# if this test file is run directly ('perl *.t') then $cwd is complete
# if the test file is run via 'prove' from one dir up, we need to add 't' to the path
my $cwd = getcwd();
my $path = ( File::Spec->splitdir( $cwd ) )[-1] eq 't' ? $cwd : File::Spec->catdir( $cwd, 't' );

my $xml_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle.xml' );
my $bad_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle_invalid_xml.xml' );

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Load module
BEGIN { use_ok( 'RandomJungle::File::XML' ); }

# Object initialization and file parsing
{
	# new()

	my $xml = RandomJungle::File::XML->new();
	is( $xml, undef, 'new() returns undef when filename is undef' );
	like( $RandomJungle::File::XML::ERROR, qr/filename/,
		'new() sets $ERROR when filename is undef' );

	$xml = RandomJungle::File::XML->new( filename => 'invalid' );
	is( $xml, undef, 'new() returns undef when filename is invalid' );
	like( $RandomJungle::File::XML::ERROR, qr/does not exist/,
		'new() sets $ERROR when filename is invalid' );

	$xml = RandomJungle::File::XML->new( filename => $xml_file );
	is( ref( $xml ), 'RandomJungle::File::XML', 'Object creation and initialization' );

	# Parsing

	my $retval = $xml->parse;
	ok( $retval ? 1 : 0, 'Parsing XML file' );

	$xml = RandomJungle::File::XML->new( filename => $bad_file );
	$retval = $xml->parse;
	is( $retval, undef, 'parse() returns undef when given invalid XML' );
	like( $xml->err_str, qr/Error parsing/, 'parse() sets err_str when given invalid XML' );
}

# Retrieve basic data
{
	my $xml = RandomJungle::File::XML->new( filename => $xml_file );
	$xml->parse;

	# get_filename()

	is( $xml->get_filename, $xml_file, 'Retrieve filename' );

	# get_RJ_input_params()

	my $params = $xml->get_RJ_input_params;
	is( ref( $params ), 'HASH', 'Return type for get_RJ_input_params()' );
	is( scalar keys %$params, scalar keys %{ $exp->{XML}{options} }, 'Number of elements returned from get_RJ_input_params()' );

	while( my ( $k, $v ) = each %$params )
	{
		is( $params->{$k}, $exp->{XML}{options}{$k}, "Value of input param ($k)" );
	}

	# get_RJ_input_params() - without calling parse() first

	$xml = RandomJungle::File::XML->new( filename => $xml_file );
	$params = $xml->get_RJ_input_params;
	is( ref( $params ), 'HASH', 'Return type for get_RJ_input_params() without parse()' );
	is( scalar keys %$params, scalar keys %{ $exp->{XML}{options} }, 'Number of elements returned from get_RJ_input_params() without parse()' );

	$xml = RandomJungle::File::XML->new( filename => $bad_file );
	my $retval = $xml->get_RJ_input_params;
	is( $retval, undef, 'get_RJ_input_params() returns undef when given invalid XML' );
	like( $xml->err_str, qr/Error parsing/, 'get_RJ_input_params() sets err_str when given invalid XML' );

	# get_tree_ids()

	my $ids = $xml->get_tree_ids;
	is( ref( $ids ), 'ARRAY', 'Return type for get_tree_ids()' );
	is( scalar @$ids, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_ids()' );

	foreach my $i ( 0 .. scalar @$ids - 1 )
	{
		is( $ids->[$i], $exp->{XML}{tree_ids}[$i], "Order of tree IDs (index $i)" );
	}

	# get_tree_ids() - without calling parse() first

	$xml = RandomJungle::File::XML->new( filename => $xml_file );
	$ids = $xml->get_tree_ids;
	is( ref( $ids ), 'ARRAY', 'Return type for get_tree_ids() without parse()' );
	is( scalar @$ids, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_ids() without parse()' );

	$xml = RandomJungle::File::XML->new( filename => $bad_file );
	$retval = $xml->get_tree_ids;
	is( $retval, undef, 'get_tree_ids() returns undef when given invalid XML' );
	like( $xml->err_str, qr/Error parsing/, 'get_tree_ids() sets err_str when given invalid XML' );
}

# Retrieve tree records
{
	my $xml = RandomJungle::File::XML->new( filename => $xml_file );
	$xml->parse;

	# get_tree_data()

	my $trees = $xml->get_tree_data;
	is( ref( $trees ), 'HASH', 'Return type for get_tree_data()' );
	is( scalar keys %$trees, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_data()' );

	foreach my $id ( @{ $exp->{XML}{tree_ids} } )
	{
		ok( exists $trees->{$id}, "Retrieved record for tree ID $id" );
	}

	# get_tree_data( tree_id => $id )

	my $tree = $xml->get_tree_data( tree_id => undef );
	is( $tree, undef, 'Return value for get_tree_data() when tree_id is undef' );
	like( $xml->err_str, qr/not specified/, 'get_tree_data() sets err_str when tree_id is undef' );

	$tree = $xml->get_tree_data( tree_id => 'invalid' );
	is( $tree, undef, 'Return value for get_tree_data() when tree_id is invalid' );
	like( $xml->err_str, qr/invalid/, 'get_tree_data() sets err_str when tree_id is invalid' );

	my $tree_id = 1;
	$tree = $xml->get_tree_data( tree_id => $tree_id );
	is( ref( $tree ), 'HASH', 'Return type for get_tree_data()' );
	is( $tree->{$tree_id}{id}, $tree_id, 'Content of tree data (id)' );
	is( $tree->{$tree_id}{var_id_str}, $exp->{XML}{treedata}{$tree_id}{varID},
		  'Content of tree data (var_id_str)' );
	is( $tree->{$tree_id}{values_str}, $exp->{XML}{treedata}{$tree_id}{values},
		  'Content of tree data (values_str)' );
	is( $tree->{$tree_id}{branches_str}, $exp->{XML}{treedata}{$tree_id}{branches},
		  'Content of tree data (branches_str)' );

	# get_tree_data() - without calling parse() first

	$xml = RandomJungle::File::XML->new( filename => $xml_file );
	$trees = $xml->get_tree_data;
	is( ref( $trees ), 'HASH', 'Return type for get_tree_data() without parse()' );
	is( scalar keys %$trees, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_data() without parse()' );

	$xml = RandomJungle::File::XML->new( filename => $bad_file );
	my $retval = $xml->get_tree_data;
	is( $retval, undef, 'get_tree_data() returns undef when given invalid XML' );
	like( $xml->err_str, qr/Error parsing/, 'get_tree_data() sets err_str when given invalid XML' );
}

# Debugging method (deprecated)
{
	my $xml = RandomJungle::File::XML->new( filename => $xml_file );
	$xml->parse;

	# get_data() - basic testing only

	my $data = $xml->get_data;
	is( ref( $data ), 'HASH', 'Return type for get_data()' );
	is( scalar keys %$data, 3, 'Number of elements returned from get_data()' );

	$xml = RandomJungle::File::XML->new( filename => $xml_file );
	$data = $xml->get_data;
	is( ref( $data ), 'HASH', 'Return type for get_data() without parse()' );
	is( scalar keys %$data, 3, 'Number of elements returned from get_data() without parse()' );

	$xml = RandomJungle::File::XML->new( filename => $bad_file );
	my $retval = $xml->get_data;
	is( $retval, undef, 'get_data() returns undef when given invalid XML' );
	like( $xml->err_str, qr/Error parsing/, 'get_data() sets err_str when given invalid XML' );
}

# Error handling
{
	my $xml = RandomJungle::File::XML->new( filename => $xml_file );

	# set_err()

	$xml->set_err();
	is( $xml->err_str, '', 'set_err() initializes error string if undef' );

	$xml->set_err( 'boom' );
	is( $xml->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $xml->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

done_testing();
