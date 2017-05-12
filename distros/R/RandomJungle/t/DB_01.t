use strict;
use warnings;

use Cwd;
use Data::Dumper;
use File::Spec;
use Test::More;
use Test::Warn;

use RandomJungle::TestData qw( get_exp_data );

our $VERSION = 0.02;

#*************************************************

# all data files should be in the same dir as this test script
# if this test file is run directly ('perl *.t') then $cwd is complete
# if the test file is run via 'prove' from one dir up, we need to add 't' to the path
my $cwd = getcwd();
my $path = ( File::Spec->splitdir( $cwd ) )[-1] eq 't' ? $cwd : File::Spec->catdir( $cwd, 't' );

my $raw_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.raw' );
my $oob_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.oob' );
my $xml_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle.xml' );
my $db_file  = File::Spec->catfile( $path, 'RJ_File_DB_test.dbm' );

my $bad_raw_file = File::Spec->catfile( $path, 'testdata_20samples_10vars_invalid_header_IID.raw' );
my $bad_xml_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle_invalid_xml.xml' );
my $bad_oob_file = File::Spec->catfile( $path, '../t' ); # exists but cannot be opened as a file

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Load module
BEGIN { use_ok( 'RandomJungle::File::DB' ); }

# Object initialization and db connection
{
	# new()

	my $rjdb = RandomJungle::File::DB->new();
	is( $rjdb, undef, 'new() returns undef when db_file is undef' );
	like( $RandomJungle::File::DB::ERROR, qr/db_file/,
		'new() sets $ERROR when db_file is undef' );

	$rjdb = RandomJungle::File::DB->new( db_file => $db_file );
	is( ref( $rjdb ), 'RandomJungle::File::DB', 'Object creation and initialization' );
}

# Store data in db
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# store_data() - failure

	foreach my $file_type qw( xml_file oob_file raw_file )
	{
		my $retval = $rjdb->store_data( $file_type => 'invalid' );
		ok( ! $retval, "store_data() returns false when $file_type does not exist" );
		like( $rjdb->err_str, qr/does not exist/, "store_data() sets err_str when $file_type does not exist" );
	}

	my $retval = $rjdb->store_data( xml_file => $bad_xml_file );
	ok( ! $retval, "store_data() returns false when error parsing xml file" );
	like( $rjdb->err_str, qr/Error parsing/, "store_data() sets err_str when error parsing xml file" );

	$retval = $rjdb->store_data( raw_file => $bad_raw_file );
	ok( ! $retval, "store_data() returns false when given invalid raw file" );
	like( $rjdb->err_str, qr/unexpected name/, "store_data() sets err_str when given invalid raw file" );

	# this test succeeds on *nix (because the directory can be opened) - need a different method for testing
	#$retval = $rjdb->store_data( oob_file => $bad_oob_file );
	#ok( ! $retval, "store_data() returns false when the OOB file cannot be opened" );
	#like( $rjdb->err_str, qr/Error opening/, "store_data() sets err_str when the OOB file cannot be opened" );

	# store_data() - success
	# will verify content was loaded properly when retrieve data via ::DB methods

	$retval = $rjdb->store_data();
	ok( $retval, "store_data() returns true when called without params" );

	$retval = $rjdb->store_data( xml_file => $xml_file );
	ok( $retval, "store_data() returns true when called with XML file" );

	$retval = $rjdb->store_data( oob_file => $oob_file );
	ok( $retval, "store_data() returns true when called with OOB file" );

	$retval = $rjdb->store_data( raw_file => $raw_file );
	ok( $retval, "store_data() returns true when called with RAW file" );

	$retval = $rjdb->store_data( xml_file => $xml_file, raw_file => $raw_file, oob_file => $oob_file );
	ok( $retval, "store_data() returns true when called with XML, RAW, and OOB files" );
}

# Retrieve filenames
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	my $file = $rjdb->get_db_filename;
	is( $file, $db_file, 'get_db_filename() returns db filename' );

	$file = $rjdb->get_xml_filename;
	is( $file, $xml_file, 'get_xml_filename() returns xml filename' );

	$file = $rjdb->get_oob_filename;
	is( $file, $oob_file, 'get_oob_filename() returns oob filename' );

	$file = $rjdb->get_raw_filename;
	is( $file, $raw_file, 'get_raw_filename() returns raw filename' );
}

# Retrieve RJ params
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# get_rj_params()
	# Note:  These tests were copied from tests in XML_01.t for ::XML->get_RJ_input_params().
	# The tests for both modules use the same input files; copying these tests ensures they stay in sync.

	my $params = $rjdb->get_rj_params;
	is( ref( $params ), 'HASH', 'Return type for get_rj_params()' );
	is( scalar keys %$params, scalar keys %{ $exp->{XML}{options} }, 'Number of elements returned from get_RJ_input_params()' );

	while( my ( $k, $v ) = each %$params )
	{
		is( $params->{$k}, $exp->{XML}{options}{$k}, "Value of input param ($k)" );
	}
}

# Retrieve variable and sample info
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# Note:  These tests were copied from tests in RAW_01.t.  The tests for both modules use
	# the same input files; copying these tests ensures they stay in sync.

	# get_variable_labels()

	my $var_labels = $rjdb->get_variable_labels;
	is( ref( $var_labels ), 'ARRAY', 'Return type for get_variable_labels()' );
	is( scalar @$var_labels, scalar @{ $exp->{RAW}{variable_labels} },
		'Number of elements returned from get_variable_labels()' );

	foreach my $i ( 0 .. scalar @$var_labels - 1 )
	{
		is( $var_labels->[$i], $exp->{RAW}{variable_labels}[$i], "Variable label at index $i" );
	}

	# get_header_labels()

	my $header_labels = $rjdb->get_header_labels;
	is( ref( $header_labels ), 'ARRAY', 'Return type for get_header_labels()' );
	is( scalar @$header_labels, scalar @{ $exp->{RAW}{header_labels} },
		'Number of elements returned from get_header_labels()' );

	foreach my $i ( 0 .. scalar @$header_labels - 1 )
	{
		is( $header_labels->[$i], $exp->{RAW}{header_labels}[$i], "Header label at index $i" );
	}

	# get_sample_labels()

	my $sample_labels = $rjdb->get_sample_labels;
	is( ref( $sample_labels ), 'ARRAY', 'Return type for get_sample_labels()' );
	is( scalar @$sample_labels, scalar @{ $exp->{RAW}{sample_labels} },
		'Number of elements returned from get_sample_labels()' );

	foreach my $i ( 0 .. scalar @$sample_labels - 1 )
	{
		is( $sample_labels->[$i], $exp->{RAW}{sample_labels}[$i], "Sample label at index $i" );
	}
}

# Retrieve sample data
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# get_sample_data()

	my $retval = $rjdb->get_sample_data();
	is( $retval, undef, "get_sample_data() returns undef when sample label is not specified" );
	like( $rjdb->err_str, qr/sample label/, "get_sample_data() warns when sample label is not specified" );

	$retval = $rjdb->get_sample_data( label => 'invalid' );
	is( $retval, undef, "get_sample_data() returns undef when sample label is invalid" );

	# Note:  Some of these tests were based on tests in RAW_01.t.  The tests for both modules use
	# the same input files; copying these tests ensures they stay in sync.

	# Select a sample for testing
	my $sample_i = 0;
	my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

	my $sample_data = $rjdb->get_sample_data( label => $sample_label );
	is( ref( $sample_data ), 'HASH', 'Return type for get_sample_data()' );
	is( scalar keys %$sample_data, 6, 'Number of elements returned from get_sample_data()' );
	is( $sample_data->{label}, $sample_label, 'Sample label returned from get_sample_data()' );
	is( $sample_data->{index}, $sample_i, 'Index of sample from get_sample_data()' );
	is( $sample_data->{orig_data}, $exp->{RAW}{data_by_sample_index}{$sample_i}{orig_data},
		  'Original data string returned by get_data_for_sample()' );

	my $data_ref = $sample_data->{classification_data};
	is( ref( $data_ref ), 'ARRAY', 'Datatype for classification_data from get_sample_data()' );
	is( scalar @$data_ref, scalar @{ $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data} },
		'Number of elements in classification_data' );

	foreach my $i ( 0 .. scalar @$data_ref - 1 )
	{
		is( $data_ref->[$i], $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data}[$i],
			"Sample data value for variable at index $i" );
	}
}

# Retrieve OOB data for a sample
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# get_oob_by_sample()

	my $retval = $rjdb->get_oob_by_sample();
	is( $retval, undef, "get_oob_by_sample() returns undef when no params are given" );
	like( $rjdb->err_str, qr/requires either sample label or index/,
		"get_oob_by_sample() sets err_str when sample label is not specified" );

	$retval = $rjdb->get_oob_by_sample( label => 'invalid' );
	is( $retval, undef, "get_oob_by_sample() returns undef when an invalid label is specified" );
	like( $rjdb->err_str, qr/Cannot find sample index/,
		"get_oob_by_sample() sets err_str when an invalid label is specified" );

	# Note:  Some of these tests were based on tests in OOB_01.t.  The tests for both modules use
	# the same input files; copying these tests ensures they stay in sync.

	# Select a sample for testing
	my $sample_i = 0;
	my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

	my $line = $rjdb->get_oob_by_sample( label => $sample_label );
	is( $line, $exp->{OOB}{matrix}[$sample_i],
		"OOB data string returned by get_oob_by_sample() (sample label $sample_label)" );

	$line = $rjdb->get_oob_by_sample( index => $sample_i );
	is( $line, $exp->{OOB}{matrix}[$sample_i],
		"OOB data string returned by get_oob_by_sample() (sample index $sample_i)" );

	$line = $rjdb->get_oob_by_sample( id => $sample_label );
	is( $line, $exp->{OOB}{matrix}[$sample_i],
		"OOB data string returned by get_oob_by_sample() (sample id $sample_label)" );
}

# Retrieve tree data
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# get_tree_ids()

	my $trees = $rjdb->get_tree_ids;
	is( ref( $trees ), 'ARRAY', 'Return type for get_tree_ids()' );
	is( scalar @$trees, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_ids()' );

	foreach my $i ( 0 .. scalar @$trees - 1 )
	{
		is( $trees->[$i], $exp->{XML}{tree_ids}[$i], "Order of tree IDs (index $i)" );
	}

	# get_tree_data()

	$trees = $rjdb->get_tree_data();
	is( ref( $trees ), 'HASH', 'Return type for get_tree_data() without params' );
	is( scalar %$trees, 0, 'Number of records returned from get_tree_data() without params' );

	my $invalid_tree_id = scalar @{ $exp->{XML}{tree_ids} }; # last index + 1
	$trees = $rjdb->get_tree_data( 0, 1, $invalid_tree_id );
	is( ref( $trees ), 'HASH', 'Return type for get_tree_data() with params' );
	is( scalar keys %$trees, 2, 'Number of records returned from get_tree_data() with params' );
	ok( exists $trees->{0}, "Retrieved record for tree ID 0" );
	ok( exists $trees->{1}, "Retrieved record for tree ID 1" );
	ok( ! exists $trees->{$invalid_tree_id}, "Skipped invalid tree ID ($invalid_tree_id)" );

	my $tree_id = 1;
	is( $trees->{$tree_id}{id}, $tree_id, 'Content of tree data (id)' );
	is( $trees->{$tree_id}{var_id_str}, $exp->{XML}{treedata}{$tree_id}{varID},
		  'Content of tree data (var_id_str)' );
	is( $trees->{$tree_id}{values_str}, $exp->{XML}{treedata}{$tree_id}{values},
		  'Content of tree data (values_str)' );
	is( $trees->{$tree_id}{branches_str}, $exp->{XML}{treedata}{$tree_id}{branches},
		  'Content of tree data (branches_str)' );
}

# Error handling
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# set_err()

	$rjdb->set_err();
	is( $rjdb->err_str, '', 'set_err() initializes error string if undef' );

	$rjdb->set_err( 'boom' );
	is( $rjdb->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $rjdb->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

# Misc internal methods
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );

	# _sample_label_to_index()

	my $retval = $rjdb->_sample_label_to_index( undef );
	is( $retval, undef, '_sample_label_to_index() returns undef when label is undefined' );
}

=pod
# Clean up
{
	my $rjdb = RandomJungle::File::DB->new( db_file => $db_file );
	$rjdb->{db}->unlock; # workaround for DBM::Deep (see http://www.perlmonks.org/?node_id=974578)
	$rjdb->{db}->clear;
	unlink( $db_file ) || warn $!;
}
=cut

done_testing();
