use Test::More;
use RADIUS::XMLParser;
use File::Basename;
use Test::Files;

my $test_file        = 'resources/radius.log';
my $test_output_dir  = 'tmp';
my $test_output_file = 'radius.xml';
my %labels;
my %expect;
my %actual;
my $parser;

# Declare labels to write in test XML
%labels = ( "File" => "File" );

# What to expect in test
%expect = (
	'INTERIM' => 130,
	'START'   => 46,
	'STOP'    => 46,
	'LINES'   => 5659
);

# Initialize parser
$parser = RADIUS::XMLParser->new(
	{
		ORPHANDIR => $test_output_dir,
		ALLEVENTS => 1,
		OUTPUTDIR => $test_output_dir,
		MAP       => \%labels
	}
);

# Parse Radius
my ( $xml, $stop, $start, $interim, $processed ) = $parser->convert($test_file);

# Test that XML has been created
dir_contains_ok( $test_output_dir, ['radius.xml'],
	"Assert that xml file has been created" );
if ( -e "$test_output_dir/radius.xml" ) {
	unlink "$test_output_dir/radius.xml";
}

ok( $stop == $expect{STOP},       
	"Assert that stop event(s) found are correct" );
ok( $start == $expect{START},     
	"Assert that stop event(s) found are correct" );
ok( $interim == $expect{INTERIM}, 
	"Assert that stop event(s) found are correct" );
ok( $processed == $expect{LINES},
	"Assert that processed line(s) are correct" );

# End test (declare test run)
done_testing( scalar( keys %expect ) + 1 );
