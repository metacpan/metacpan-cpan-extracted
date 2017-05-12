#########1 Test File for Spreadsheet::Reader::ExcelXML  6#########7#########8#########9

my ( $lib, $test_file );
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	my	$start_deeper = 1;
	$lib		= 'lib';
	$test_file	= 't/test_files/';
	for my $next ( <*> ){
		if( ($next eq 't') and -d $next ){
			$start_deeper = 0;
			last;
		}
	}
	if( $start_deeper ){
		$lib		= '../../../' . $lib;
		$test_file	= '../../test_files/'
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 30;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'warn',
###LogSD				},
###LogSD				build_instance =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'warn',
###LogSD					},
###LogSD				},
###LogSD				build_class =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'warn',
###LogSD					},
###LogSD				},
###LogSD				Test =>{
###LogSD					SharedStringsInstance =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					StylesInstance =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					Workbook =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'debug',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD			reports =>{
###LogSD				log_file =>[ Print::Log->new ],
###LogSD			},
###LogSD		);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
###LogSD	use MooseX::ShortCut::BuildInstance;
use Spreadsheet::Reader::ExcelXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'ChartSheet.xlsx';
	#~ print "Test file is: $test_file\n";
my  ( 
		$parser, @worksheets, $value,
	);
my	$answer_ref = [
		'Sheet1',
		'A',	'B',
		1,		2,
		2,		4,
		3,		5,
		4,		7,
		'EOF',
		[ 'Sheet1',],
		qr/You have requested -Chart1- which is a 'chartsheet' using a worksheet focused method/,
	];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
			###LogSD		log_space => 'Test',
							file => $test_file,
							group_return_type => 'unformatted',
							empty_return_type => 'empty_string',
						);
			#~ $parser->set_warnings( 1 );
}										"Prep a test parser instance";
###LogSD		$phone->talk( level => 'trace', message => [ "$parser:", $parser ] );
is			$parser->error(), undef,
										"Write any error messages from the file load";
ok			@worksheets = $parser->worksheets(),
										"Loaded worksheet objects ok";
			my	$x = 0;
			for my $worksheet ( @worksheets ){
is			$worksheet->get_name, $answer_ref->[$x],
										'Check that the next opened worksheet name is: ' . $answer_ref->[$x++];
is			$worksheet->get_sheet_type, 'worksheet',
										"..and that it is a 'worksheet' type";
			while( !$value or $value ne 'EOF' ){
#~ ###LogSD	if( $value_position == 0 ){
#~ ###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				UNBLOCK =>{
#~ ###LogSD					log_file => 'debug',
#~ ###LogSD				},
#~ ###LogSD			},
#~ ###LogSD		} );
#~ ###LogSD	}
#~ ###LogSD	elsif( $value_position == 1 ){
#~ ###LogSD		exit 1;
#~ ###LogSD	}
ok			$value = ($worksheet->get_next_value//'undef'),
										"Get the next value position:$x";
my			$return = ref( $value ) ? $value->value : $value;
is			$return, $answer_ref->[$x],
										"With value: " . $answer_ref->[$x];
#~ explain		$value_position;
			$x++;
			}
			}
is_deeply	$parser->get_worksheet_names, $answer_ref->[$x++],
										"Check that the overall worksheet list does not contains the chartsheet element";
is			$parser->worksheet( 'Chart1' ), undef,
										"Try to return the chartsheet: Chart1";
like		$parser->error, $answer_ref->[$x],
										"..and check for the correct error: " . $answer_ref->[$x++];
explain 								"...Test Done";
done_testing();

###LogSD	package Print::Log;
###LogSD	use Data::Dumper;
###LogSD	sub new{
###LogSD		bless {}, shift;
###LogSD	}
###LogSD	sub add_line{
###LogSD		shift;
###LogSD		my @input = ( ref $_[0]->{message} eq 'ARRAY' ) ? 
###LogSD						@{$_[0]->{message}} : $_[0]->{message};
###LogSD		my ( @print_list, @initial_list );
###LogSD		no warnings 'uninitialized';
###LogSD		for my $value ( @input ){
###LogSD			push @initial_list, (( ref $value ) ? Dumper( $value ) : $value );
###LogSD		}
###LogSD		for my $line ( @initial_list ){
###LogSD			$line =~ s/\n$//;
###LogSD			$line =~ s/\n/\n\t\t/g;
###LogSD			push @print_list, $line;
###LogSD		}
###LogSD		printf( "| level - %-6s | name_space - %-s\n| line  - %04d   | file_name  - %-s\n\t:(\t%s ):\n", 
###LogSD					$_[0]->{level}, $_[0]->{name_space},
###LogSD					$_[0]->{line}, $_[0]->{filename},
###LogSD					join( "\n\t\t", @print_list ) 	);
###LogSD		use warnings 'uninitialized';
###LogSD	}

###LogSD	1;
