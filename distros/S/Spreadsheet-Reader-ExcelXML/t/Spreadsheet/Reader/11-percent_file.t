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

use	Test::Most tests => 120;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
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
$test_file .= 'perc.xlsx';
	#~ print "Test file is: $test_file\n";
my  ( 
		$parser, @worksheets, $value, $workbook,
	);
my	$answer_ref = [
		'Blad1',
		[0,2],
		[0,18],
		['Spreadsheet::Reader::ExcelXML::Cell', 1000],
		['Spreadsheet::Reader::ExcelXML::Cell', '1000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '1000.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 500],
		['Spreadsheet::Reader::ExcelXML::Cell', '500%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '500.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 200],
		['Spreadsheet::Reader::ExcelXML::Cell', '200%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '200.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 100],
		['Spreadsheet::Reader::ExcelXML::Cell', '100%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '100.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 50],
		['Spreadsheet::Reader::ExcelXML::Cell', '50%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '50.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 20],
		['Spreadsheet::Reader::ExcelXML::Cell', '20%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '20.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 10],
		['Spreadsheet::Reader::ExcelXML::Cell', '10%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '10.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 5],
		['Spreadsheet::Reader::ExcelXML::Cell', '5%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '5.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 2],
		['Spreadsheet::Reader::ExcelXML::Cell', '2%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '2.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 1],
		['Spreadsheet::Reader::ExcelXML::Cell', '1%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '1.000%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.5],
		['Spreadsheet::Reader::ExcelXML::Cell', '1%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.500%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.2],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.200%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.1],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.100%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.05],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.050%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.02],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.020%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.01],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.010%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.005],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.005%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.002],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.002%'],
		['Spreadsheet::Reader::ExcelXML::Cell', 0.001],
		['Spreadsheet::Reader::ExcelXML::Cell', '0%'],
		['Spreadsheet::Reader::ExcelXML::Cell', '0.001%'],
	];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser = 	Spreadsheet::Reader::ExcelXML->new(
							###LogSD log_space => 'Test'
						);
			$workbook = $parser->parse($test_file);
			$parser->set_warnings( 1 );
}										"Prep a test parser instance";
###LogSD		$phone->talk( level => 'trace', message => [ "$parser:", $parser ] );
like			$parser->error(), qr/Unable to load Spreadsheet::Reader::ExcelXML::XMLReader with the attribute: shared_strings_interface/,
										"Write any error messages from the file load";
ok			@worksheets = $workbook->worksheets(),
										"Loaded worksheet objects ok";
			my	$x = 0;
			for my $worksheet ( @worksheets ){
is			$worksheet->get_name, $answer_ref->[$x],
										'Check that the next opened worksheet name is: ' . $answer_ref->[$x++];
			my @column_range = $worksheet->col_range;
is_deeply	[@column_range], $answer_ref->[$x++],
										"Check for the correct column range";
			my @row_range = $worksheet->row_range;
is_deeply	[@row_range], $answer_ref->[$x++],
										"Check for the correct row range";
			for my $row ( $row_range[0] .. $row_range[1] ){
			for my $col ( $column_range[0] .. $column_range[1] ){
###LogSD	my $reveal = 0;
###LogSD	if( $row == $reveal and $col == 2 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD	elsif( $row == ($reveal + 1) and $col == 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			my $cell;
is			ref( $cell = $worksheet->get_cell( $row, $col ) ), $answer_ref->[$x]->[0],
										"Attempt to get the cell for row -$row- and column -$col-";
#~ is			ref( $cell ), 
										#~ "make sure it returns a cell - if it should";
			if( $answer_ref->[$x]->[0] ){
is			$cell->value, $answer_ref->[$x]->[1],
										"And check the returned value: " . $answer_ref->[$x]->[1];
			}
			$x++;
			}
			}
			}
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
