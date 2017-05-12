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
my $bad_file_iid = File::Spec->catfile( $path, 'testdata_20samples_10vars_invalid_header_IID.raw' );
my $bad_file_sex = File::Spec->catfile( $path, 'testdata_20samples_10vars_invalid_header_SEX.raw' );
my $bad_file_pheno = File::Spec->catfile( $path, 'testdata_20samples_10vars_invalid_header_PHENOTYPE.raw' );

#*************************************************

# Get expected results from RJ::TestData
my $exp = get_exp_data();

# Load module
BEGIN { use_ok( 'RandomJungle::File::RAW' ); }

# Object initialization and file parsing
{
	# new()

	my $raw = RandomJungle::File::RAW->new();
	is( $raw, undef, 'new() returns undef when filename is undef' );
	like( $RandomJungle::File::RAW::ERROR, qr/filename/,
		'new() sets $ERROR when filename is undef' );

	$raw = RandomJungle::File::RAW->new( filename => 'invalid' );
	is( $raw, undef, 'new() returns undef when filename is invalid' );
	like( $RandomJungle::File::RAW::ERROR, qr/does not exist/,
		'new() sets $ERROR when filename is invalid' );

	$raw = RandomJungle::File::RAW->new( filename => $raw_file );
	is( ref( $raw ), 'RandomJungle::File::RAW', 'Object creation and initialization' );

	# Parsing

	my $retval = $raw->parse;
	ok( $retval ? 1 : 0, 'Parsing RAW file' );

	# Break encapsulation to trigger error reading file

	$raw->{raw_file}{filename} = 'invalid';

	$retval = $raw->parse;
	is( $retval, undef, 'parse() returns undef when error opening raw file' );
	like( $raw->err_str, qr/Error opening/, 'parse() sets err_str when error opening raw file' );

	# RAW file format

	# only need to check retval of parse() on error once
	$raw = RandomJungle::File::RAW->new( filename => $bad_file_iid );
	$retval = $raw->parse;
	is( $retval, undef, 'parse() returns undef for invalid header row (IID)' );
	like( $raw->err_str, qr/unexpected name.+IID/, 'Detect invalid header row (IID)' );

	$raw = RandomJungle::File::RAW->new( filename => $bad_file_sex );
	$retval = $raw->parse;
	is( $retval, undef, 'parse() returns undef for invalid header row (SEX)' );
	like( $raw->err_str, qr/unexpected name.+SEX/, 'Detect invalid header row (SEX)' );

	$raw = RandomJungle::File::RAW->new( filename => $bad_file_pheno );
	$retval = $raw->parse;
	is( $retval, undef, 'parse() returns undef for invalid header row (PHENOTYPE)' );
	like( $raw->err_str, qr/unexpected name.+PHENOTYPE/, 'Detect invalid header row (PHENOTYPE)' );
}

# Retrieve basic data
{
	my $raw = RandomJungle::File::RAW->new( filename => $raw_file );
	$raw->parse;

	# get_filename()

	is( $raw->get_filename, $raw_file, 'Retrieve filename' );

	# get_variable_labels()

	my $var_labels = $raw->get_variable_labels;
	is( ref( $var_labels ), 'ARRAY', 'Return type for get_variable_labels()' );
	is( scalar @$var_labels, scalar @{ $exp->{RAW}{variable_labels} },
		'Number of elements returned from get_variable_labels()' );

	foreach my $i ( 0 .. scalar @$var_labels - 1 )
	{
		is( $var_labels->[$i], $exp->{RAW}{variable_labels}[$i], "Variable label at index $i" );
	}

	# get_header_labels()

	my $header_labels = $raw->get_header_labels;
	is( ref( $header_labels ), 'ARRAY', 'Return type for get_header_labels()' );
	is( scalar @$header_labels, scalar @{ $exp->{RAW}{header_labels} },
		'Number of elements returned from get_header_labels()' );

	foreach my $i ( 0 .. scalar @$header_labels - 1 )
	{
		is( $header_labels->[$i], $exp->{RAW}{header_labels}[$i], "Header label at index $i" );
	}

	# get_sample_labels()

	my $sample_labels = $raw->get_sample_labels;
	is( ref( $sample_labels ), 'ARRAY', 'Return type for get_sample_labels()' );
	is( scalar @$sample_labels, scalar @{ $exp->{RAW}{sample_labels} },
		'Number of elements returned from get_sample_labels()' );

	foreach my $i ( 0 .. scalar @$sample_labels - 1 )
	{
		is( $sample_labels->[$i], $exp->{RAW}{sample_labels}[$i], "Sample label at index $i" );
	}

	# get_sample_data() (content will be checked in get_data_for_sample)

	my $sample_data = $raw->get_sample_data;
	is( ref( $sample_data ), 'HASH', 'Return type for get_sample_data()' );
	is( scalar keys %$sample_data, scalar @{ $exp->{RAW}{sample_labels} },
		'Number of elements returned from get_sample_data()' );
}

# Retrieve information by sample
{
	my $raw = RandomJungle::File::RAW->new( filename => $raw_file );
	$raw->parse;

	# Select a sample for testing
	my $sample_i = 0;
	my $sample_label = $exp->{RAW}{data_by_sample_index}{$sample_i}{label};

	# get_phenotype_for_sample()

	my $retval = $raw->get_phenotype_for_sample();
	is( $retval, undef, 'get_phenotype_for_sample() returns undef for missing param (sample)' );
	like( $raw->err_str, qr/No sample specified/, 'get_phenotype_for_sample() sets err_str for missing param (sample)' );

	$retval = $raw->get_phenotype_for_sample( 'invalid' );
	is( $retval, undef, 'get_phenotype_for_sample() returns undef for invalid sample' );
	like( $raw->err_str, qr/Invalid sample/, 'get_phenotype_for_sample() sets err_str for invalid sample' );

	my $pheno = $raw->get_phenotype_for_sample( $sample_label );
	is( $pheno, $exp->{RAW}{data_by_sample_index}{$sample_i}{phenotype}, 'Retrieve phenotype by sample label' );

	# get_data_for_sample()

	$retval = $raw->get_data_for_sample();
	is( $retval, undef, 'get_data_for_sample() returns undef for missing param' );
	like( $raw->err_str, qr/No sample specified/, 'get_data_for_sample() sets err_str for missing param' );

	$retval = $raw->get_data_for_sample( 'invalid' );
	is( $retval, undef, 'get_data_for_sample() returns undef for invalid sample' );
	like( $raw->err_str, qr/Invalid sample/, 'get_data_for_sample() sets err_str for invalid sample' );

	my $sample_data = $raw->get_data_for_sample( $sample_label );
	is( ref( $sample_data ), 'ARRAY', 'Return type for get_data_for_sample()' );
	is( scalar @$sample_data, scalar @{ $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data} },
		'Number of elements returned from get_data_for_sample()' );

	foreach my $i ( 0 .. scalar @$sample_data - 1 )
	{
		is( $sample_data->[$i], $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data}[$i],
			"Sample data value for variable at index $i" );
	}

	$sample_data = $raw->get_data_for_sample( $sample_label, orig => 0 );
	is( ref( $sample_data ), 'ARRAY', 'Return type for get_data_for_sample() - orig is 0' );
	is( scalar @$sample_data, scalar @{ $exp->{RAW}{data_by_sample_index}{$sample_i}{spliced_data} },
		'Number of elements returned from get_data_for_sample() - orig is 0' );

	$sample_data = $raw->get_data_for_sample( $sample_label, orig => 1 );
	is( $sample_data, $exp->{RAW}{data_by_sample_index}{$sample_i}{orig_data},
		  'Original data string returned by get_data_for_sample() - orig is 1' );
}

# Debugging method (deprecated)
{
	my $raw = RandomJungle::File::RAW->new( filename => $raw_file );
	$raw->parse;

	# get_data() - basic testing only

	my $data = $raw->get_data;
	is( ref( $data ), 'HASH', 'Return type for get_data()' );
	is( scalar keys %$data, 2, 'Number of elements returned from get_data()' );
}

# Error handling
{
	my $raw = RandomJungle::File::RAW->new( filename => $raw_file );

	# set_err()

	$raw->set_err();
	is( $raw->err_str, '', 'set_err() initializes error string if undef' );

	$raw->set_err( 'boom' );
	is( $raw->err_str, 'boom', 'set_err() sets error string' );

	# err_trace()

	like( $raw->err_trace, qr/Trace begun/, 'err_trace() returns trace string' );
}

done_testing();
