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

my $oob_file = File::Spec->catfile( $path, 'testdata_20samples_10vars.oob' );

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Load module
BEGIN { use_ok( 'RandomJungle::File::OOB' ); }

# Object initialization and file parsing
{
	# new()

	my $oob = RandomJungle::File::OOB->new();
	is( $oob, undef, 'new() returns undef when filename is undef' );
	like( $RandomJungle::File::OOB::ERROR, qr/filename/, 'new() sets $ERROR when filename is undef' );

	$oob = RandomJungle::File::OOB->new( filename => 'invalid' );
	is( $oob, undef, 'new() returns undef when filename is invalid' );
	like( $RandomJungle::File::OOB::ERROR, qr/does not exist/,
		'new() sets $ERROR when filename is invalid' );

	$oob = RandomJungle::File::OOB->new( filename => $oob_file );
	is( ref( $oob ), 'RandomJungle::File::OOB', 'Object creation and initialization' );

	# Parsing

	my $retval = $oob->parse;
	ok( $retval ? 1 : 0, 'Parsing OOB file' );

	# Break encapsulation to trigger error reading file

	$oob->{oob_file}{filename} = 'invalid';
	$retval = $oob->parse;
	is( $retval, undef, 'parse() returns undef when error opening oob file' );
	like( $oob->err_str, qr/Error opening/, 'parse() sets err_str when error opening oob file' );
}

# Retrieve basic data
{
	my $oob = RandomJungle::File::OOB->new( filename => $oob_file );
	$oob->parse;

	# get_filename()

	is( $oob->get_filename, $oob_file, 'Retrieve filename' );

	# get_matrix()

	my $matrix = $oob->get_matrix;
	is( ref( $matrix ), 'ARRAY', 'Return type for get_matrix()' );
	is( scalar @$matrix, scalar @{ $exp->{OOB}{matrix} }, 'Number of elements returned from get_matrix()' );

	foreach my $i ( 0 .. scalar @$matrix )
	{
		is( $matrix->[$i], $exp->{OOB}{matrix}[$i], "OOB data string returned by get_matrix() (sample index $i)" );
	}
}

# Retrieve information by sample
{
	my $oob = RandomJungle::File::OOB->new( filename => $oob_file );
	$oob->parse;

	# get_data_for_sample_index()

	my $retval = $oob->get_data_for_sample_index();
	is( $retval, undef, 'get_data_for_sample_index() returns undef for missing param' );
	like( $oob->err_str, qr/No sample index specified/, 'get_data_for_sample_index() sets err_str for missing param' );

	$retval = $oob->get_data_for_sample_index( 'invalid' );
	is( $retval, undef, 'get_data_for_sample_index() returns undef for invalid sample index' );
	like( $oob->err_str, qr/Invalid sample/, 'get_data_for_sample_index() sets err_str for invalid sample index' );

	$retval = $oob->get_data_for_sample_index( 999 );
	is( $retval, undef, 'get_data_for_sample_index() returns undef for out of bounds index' );
	like( $oob->err_str, qr/Invalid sample/, 'get_data_for_sample_index() sets err_str for invalid sample index (out of bounds)' );

	my $sample_i = 1;
	my $sample_data = $oob->get_data_for_sample_index( $sample_i );
	is( $sample_data, $exp->{OOB}{matrix}[$sample_i], 
	  "OOB data string returned by get_data_for_sample_index() (sample index $sample_i)" );
}

# Debugging method (deprecated)
{
	my $oob = RandomJungle::File::OOB->new( filename => $oob_file );
	$oob->parse;

	# get_data() - basic testing only

	my $data = $oob->get_data;
	is( ref( $data ), 'HASH', 'Return type for get_data()' );
	is( scalar keys %$data, 2, 'Number of elements returned from get_data()' );
}

# Error handling
{
	my $oob = RandomJungle::File::OOB->new( filename => $oob_file );

	# set_err()

	$oob->set_err();
	is( $oob->err_str, '', 'set_err() initializes error string if undef' );

	$oob->set_err( 'boom' );
	is( $oob->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $oob->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

done_testing();
