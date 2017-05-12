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

my $raw_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.raw' );
my $oob_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.oob' );
my $xml_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.jungle.xml' );
my $db_file  = File::Spec->catfile( $path, 'RJ_File_DB_test.dbm' );

my $bad_oob_file = File::Spec->catfile( $path, 'testdata_20samples_10vars_invalid.oob' );

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Since a large portion of ::Jungle is a wrapper for ::File::DB, many of these tests are
# copied from DB_01.t (as the functionality and behavior is the same)

# Load module
BEGIN { use_ok( 'RandomJungle::Jungle' ); }

# Object initialization and db connection
{
	# new()

	my $rj = RandomJungle::Jungle->new();
	is( $rj, undef, 'new() returns undef when db_file is undef' );
	like( $RandomJungle::Jungle::ERROR, qr/db_file/,
		'new() sets $ERROR when db_file is undef' );

	$rj = RandomJungle::Jungle->new( db_file => $db_file );
	is( ref( $rj ), 'RandomJungle::Jungle', 'Object creation and initialization' );
}


# Store data in db
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );
	is( ref( $rj ), 'RandomJungle::Jungle', 'Object creation and initialization' );

	# store() - failure

	foreach my $file_type qw( xml_file oob_file raw_file )
	{
		my $retval = $rj->store( $file_type => 'invalid' );
		ok( ! $retval, "store() returns false when $file_type does not exist" );
		like( $rj->err_str, qr/does not exist/, "store() sets err_str when $file_type does not exist" );
	}

	# store() - success
	# accurate loading of content is tested in DB_01.t

	my $retval = $rj->store();
	ok( $retval, "store() returns true when called without params" );

	$retval = $rj->store( xml_file => $xml_file );
	ok( $retval, "store() returns true when called with XML file" );

	$retval = $rj->store( oob_file => $oob_file );
	ok( $retval, "store() returns true when called with OOB file" );

	$retval = $rj->store( raw_file => $raw_file );
	ok( $retval, "store() returns true when called with RAW file" );

	$retval = $rj->store( xml_file => $xml_file, raw_file => $raw_file, oob_file => $oob_file );
	ok( $retval, "store() returns true when called with XML, RAW, and OOB files" );

	# store() after losing db connection object (corrupted Jungle object)

	$rj->{rjdb} = undef;
	$retval = $rj->store( xml_file => $xml_file );
	is( $retval, undef, 'store() returns undef when db connection is lost' );
	like( $rj->err_str, qr/Cannot store data/, "store() sets err_str when db connection is lost" );
}

# Retrieve filenames
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	my $href = $rj->get_filenames;

	is( ref( $href ), 'HASH', 'Return type for get_filenames()' );
	is( scalar keys %$href, 4, 'Number of elements returned from get_filenames()' );
	is( $href->{db}, $db_file, 'get_filenames() returns db filename' );
	is( $href->{xml}, $xml_file, 'get_filenames() returns xml filename' );
	is( $href->{oob}, $oob_file, 'get_filenames() returns oob filename' );
	is( $href->{raw}, $raw_file, 'get_filenames() returns raw filename' );
}

# Retrieve RJ params
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	my $params = $rj->get_rj_input_params;
	is( ref( $params ), 'HASH', 'Return type for get_rj_input_params()' );
	is( scalar keys %$params, scalar keys %{ $exp->{XML}{options} }, 'Number of elements returned from get_rj_input_params()' );
	is_deeply( $params, $exp->{XML}{options}, 'Content returned from get_rj_input_params()' );
}

# Retrieve variable and sample info
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# get_variable_labels()

	my $var_labels = $rj->get_variable_labels;
	is( ref( $var_labels ), 'ARRAY', 'Return type for get_variable_labels()' );
	is( scalar @$var_labels, scalar @{ $exp->{RAW}{variable_labels} },
		'Number of elements returned from get_variable_labels()' );
	is_deeply( $var_labels, $exp->{RAW}{variable_labels}, 'Content returned from get_variable_labels()' );

	# get_sample_labels()

	my $sample_labels = $rj->get_sample_labels;
	is( ref( $sample_labels ), 'ARRAY', 'Return type for get_sample_labels()' );
	is( scalar @$sample_labels, scalar @{ $exp->{RAW}{sample_labels} },
		'Number of elements returned from get_sample_labels()' );
	is_deeply( $sample_labels, $exp->{RAW}{sample_labels}, 'Content returned from get_sample_labels()' );
}

# Retrieve sample data
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# get_sample_data_by_label()

	my $retval = $rj->get_sample_data_by_label();
	is( $retval, undef, "get_sample_data_by_label() returns undef when sample label is not specified" );
	like( $rj->err_str, qr/sample label/,
		  "get_sample_data_by_label() sets err_str when sample label is not specified" );

	$retval = $rj->get_sample_data_by_label( label => 'invalid' );
	is( $retval, undef, "get_sample_data_by_label() returns undef when sample label is invalid" );

	# Select a sample for testing
	my $sample_i = 0;
	my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

	my $sample_data = $rj->get_sample_data_by_label( label => $sample_label );
	is( ref( $sample_data ), 'HASH', 'Return type for get_sample_data_by_label()' );
	is( scalar keys %$sample_data, 6, 'Number of elements returned from get_sample_data_by_label()' );
	is( $sample_data->{label}, $sample_label, 'Sample label returned from get_sample_data_by_label()' );
	is( $sample_data->{index}, $sample_i, 'Index of sample from get_sample_data_by_label()' );
	is( $sample_data->{orig_data}, $exp->{RAW}{data_by_sample_index}{$sample_i}{orig_data},
		  'Original data string returned by get_sample_data_by_label()' );

	my $data_ref = $sample_data->{classification_data};
	is( ref( $data_ref ), 'ARRAY', 'Datatype for classification_data from get_sample_data_by_label()' );
	is( scalar @$data_ref, scalar @{ $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data} },
		'Number of elements in classification_data' );
	is_deeply( $data_ref, $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data},
			'Content returned from get_sample_data_by_label()' );
}

# Retrieve tree data
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# get_tree_ids()

	my $trees = $rj->get_tree_ids;
	is( ref( $trees ), 'ARRAY', 'Return type for get_tree_ids()' );
	is( scalar @$trees, scalar @{ $exp->{XML}{tree_ids} }, 'Number of elements returned from get_tree_ids()' );
	is_deeply( $trees, $exp->{XML}{tree_ids}, 'Content returned from get_tree_ids()' );

	# get_tree_by_id()

	my $retval = $rj->get_tree_by_id();
	is( $retval, undef, "get_tree_by_id() returns undef when tree ID is not specified" );
	like( $rj->err_str, qr/Tree ID is required/,
		  "get_tree_by_id() sets err_str when tree ID is not specified" );

	$retval = $rj->get_tree_by_id( 'invalid' );
	is( $retval, undef, "get_tree_by_id() returns undef when tree ID is invalid" );
	like( $rj->err_str, qr/invalid ID/,
		"get_tree_by_id() sets err_str when tree ID is invalid" );

	my $tree_id = 0;

	my $tree = $rj->get_tree_by_id( $tree_id );
	is( ref( $tree ), 'RandomJungle::Tree', 'get_tree_by_id() returns a RandomJungle::Tree object on success' );

	# break encapsulation to test detection of corrupted tree data
	delete $rj->{rjdb}{db}{XML}{tree_data}{$tree_id}{var_id_str};
	$retval = $rj->get_tree_by_id( $tree_id );
	is( $retval, undef, "get_tree_by_id() returns undef when tree data is corrupted" );
	like( $rj->err_str, qr/Cannot create object/,
		"get_tree_by_id() sets err_str when tree data is corrupted" );

	$retval = $rj->store( xml_file => $xml_file ); # replace corrupted data
	ok( $retval, "store() returns true when called with XML file" );
}

# Retrieve OOB data for a sample
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# get_oob_for_sample()

	my $retval = $rj->get_oob_for_sample();
	is( $retval, undef, "get_oob_for_sample() returns undef when no params are given" );
	like( $rj->err_str, qr/Sample label is undefined/,
		  "get_oob_for_sample() sets err_str when sample label is not specified" );

	$retval = $rj->get_oob_for_sample( 'invalid' );
	is( $retval, undef, "get_oob_for_sample() returns undef when an invalid label is specified" );
	like( $rj->err_str, qr/Cannot find sample index/,
		  "get_oob_for_sample() warns when an invalid label is specified" );

	# Select a sample for testing
	my $sample_i = 0;
	my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

	my $oob_data = $rj->get_oob_for_sample( $sample_label );
	is( ref( $oob_data ), 'HASH', 'Return type for get_oob_for_sample()' );
	is( scalar keys %$oob_data, 2, 'Number of elements returned from get_oob_for_sample()' );

	foreach my $k qw( sample_used_to_construct_trees
					  sample_not_used_to_construct_trees )
	{
		is( ref( $oob_data->{$k} ), 'ARRAY', "Return type for get_oob_for_sample() -> $k" );
		is( scalar @{ $oob_data->{$k} }, scalar @{ $exp->{OOB}{data_by_sample_index}{$sample_i}{$k} },
			"Number of elements returned from get_oob_for_sample() -> $k" );
		is_deeply( $oob_data->{$k}, $exp->{OOB}{data_by_sample_index}{$sample_i}{$k},
			"Content returned from get_oob_for_sample() -> $k" );
	}

	# get_oob_state()

	$retval = $rj->get_oob_state();
	is( $retval, undef, "get_oob_state() returns undef when no params are given" );
	like( $rj->err_str, qr/required parameter/,
		  "get_oob_state() sets err_str when no params are given" );

	$retval = $rj->get_oob_state( sample => $sample_label );
	is( $retval, undef, "get_oob_state() returns undef when tree ID is undefined" );
	like( $rj->err_str, qr/required parameter/,
		  "get_oob_state() sets err_str when tree ID is undefined" );

	my $tree_id = 2;

	$retval = $rj->get_oob_state( tree_id => $tree_id );
	is( $retval, undef, "get_oob_state() returns undef when sample is undefined" );
	like( $rj->err_str, qr/required parameter/,
		  "get_oob_state() sets err_str when sample is undefined" );

	$retval = $rj->get_oob_state( sample => 'invalid', tree_id => $tree_id );
	is( $retval, undef, "get_oob_state() returns undef when sample is invalid" );
	like( $rj->err_str, qr/Cannot find sample index for sample/,
		  "get_oob_state() sets err_str when sample is invalid" );

	foreach my $sample_i ( 0, 19 )
	{
		my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

		foreach my $tree_id ( @{ $exp->{XML}{tree_ids} } )
		{
			my $state = $rj->get_oob_state( sample => $sample_label, tree_id => $tree_id );
			is( $state, $exp->{OOB}{data_by_sample_index}{$sample_i}{state_for_tree}[$tree_id],
				"OOB state for sample index $sample_i, tree ID $tree_id" );
		}
	}
}

# Retrieve OOB data for a sample - detect invalid data in OOB file
{
	# get_oob_for_sample()

	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# overwrite OOB data with corrupted data
	my $retval = $rj->store( oob_file => $bad_oob_file );
	ok( $retval, "store() returns true when called with OOB file" );

	my $sample_i = 1;
	my $sample_label = $exp->{RAW}{sample_labels}[$sample_i];

	$retval = $rj->get_oob_for_sample( $sample_label );
	is( $retval, undef, 'get_oob_for_sample() returns undef when extra state is present' );
	like( $rj->err_str, qr/OOB states does not equal the number of labels/,
		  'get_oob_for_sample() warns when extra state is present' );

	$sample_i = 2;
	$sample_label = $exp->{RAW}{sample_labels}[$sample_i];

	$retval = $rj->get_oob_for_sample( $sample_label );
	is( $retval, undef, 'get_oob_for_sample() returns undef when state is empty string' );
	like( $rj->err_str, qr/unrecognized OOB state/,
		  'get_oob_for_sample() sets err_str when state is empty string' );

	$sample_i = 3;
	$sample_label = $exp->{RAW}{sample_labels}[$sample_i];

	$retval = $rj->get_oob_for_sample( $sample_label );
	is( $retval, undef, 'get_oob_for_sample() returns undef for unrecognized OOB state' );
	like( $rj->err_str, qr/unrecognized OOB state/,
		  'get_oob_for_sample() sets err_str for unrecognized OOB state' );

	$retval = $rj->store( oob_file => $oob_file ); # restore valid data
	ok( $retval, "store() returns true when called with OOB file" );
}

# Retrieve OOB data for a tree
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# get_oob_for_tree()

	my $retval = $rj->get_oob_for_tree();
	is( $retval, undef, "get_oob_for_tree() returns undef when no params are given" );
	like( $rj->err_str, qr/undefined/,
		  "get_oob_for_tree() sets err_str when no params are given" );

	$retval = $rj->get_oob_for_tree( 'invalid' );
	is( $retval, undef, "get_oob_for_tree() returns undef when tree ID is invalid" );
	like( $rj->err_str, qr/Invalid tree ID/,
		  "get_oob_for_tree() sets err_str when tree ID is invalid" );


	my $tree_id = 2;
	my $oob_data = $rj->get_oob_for_tree( $tree_id );
	is( ref( $oob_data ), 'HASH', 'Return type for get_oob_for_tree()' );
	is( scalar keys %$oob_data, 2, 'Number of elements returned from get_oob_for_tree()' );

	foreach my $k qw( in_bag_samples
					  oob_samples )
	{
		is( ref( $oob_data->{$k} ), 'ARRAY', "Return type for get_oob_for_tree() -> $k" );
		is( scalar @{ $oob_data->{$k} }, scalar @{ $exp->{OOB}{data_by_tree_index}{$tree_id}{$k} },
			"Number of elements returned from get_oob_for_tree() -> $k" );
		is_deeply( $oob_data->{$k}, $exp->{OOB}{data_by_tree_index}{$tree_id}{$k},
			"Content returned from get_oob_for_tree() -> $k" );
	}
}

# Retrieve OOB data for a tree - detect invalid data in OOB file
{
	# get_oob_for_tree()

	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# overwrite OOB data with corrupted data (note: magic numbers follow - TestData.pm should be extended)
	my $retval = $rj->store( oob_file => $bad_oob_file );
	ok( $retval, "store() returns true when called with OOB file" );

	my $tree_id = 2;

	$retval = $rj->get_oob_for_tree( $tree_id );
	is( $retval, undef, 'get_oob_for_tree() returns undef for missing state' );
	like( $rj->err_str, qr/Cannot find data/,
		  'get_oob_for_tree() sets err_str for missing state' );

	$retval = $rj->store( oob_file => $oob_file ); # restore valid data
	ok( $retval, "store() returns true when called with OOB file" );
}

# Retrieve summary data
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# summary_data()

	my $data = $rj->summary_data;

	is( ref( $data ), 'HASH', 'Return type for summary_data()' );
}

# Error handling
{
	my $rj = RandomJungle::Jungle->new( db_file => $db_file );

	# set_err()

	$rj->set_err();
	is( $rj->err_str, '', 'set_err() initializes error string if undef' );

	$rj->set_err( 'boom' );
	is( $rj->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $rj->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

done_testing();
