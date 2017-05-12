#########1 Test File for Spreadsheet::XLSX::Reader::XMLReader::WorksheetToRow   8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $styles_file );
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
		$lib		= '../../../../../' . $lib;
		$test_file	= '../../../../test_files/';
	}
}
$| = 1;

use Test::Most tests => 57;
use Test::Moose;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( Bool HasMethods );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
use	Data::Dumper;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'info',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
use	Spreadsheet::XLSX::Reader::LibXML ':just_the_data';
#~ use	Spreadsheet::XLSX::Reader::LibXML::Error;
#~ ###LogSD	use Log::Shiras::UnhideDebug;
#~ use	Spreadsheet::XLSX::Reader::LibXML::XMLReader;
#~ use Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow;
#~ use Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
#~ use Spreadsheet::XLSX::Reader::LibXML::WorksheetToRow;
#~ use Spreadsheet::XLSX::Reader::LibXML::Worksheet;

$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'string_in_worksheet.xml';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $error_instance, $workbook_instance, $file_handle, $format_instance, $shared_strings_instance
	);
my			$answer_ref = [
				[
					{ r => 'A828', cell_row => 828, cell_col => 1,	cell_type => 'Text',		s => '5', cell_xml_value => 2947		},
					{ r => 'B828', cell_row => 828, cell_col => 2,	cell_type => 'Text',		s => '5', cell_xml_value => 0			},
					{ r => 'C828', cell_row => 828, cell_col => 3,	cell_type => 'Numeric',		s => '7', cell_xml_value => 827			},
					{ r => 'D828', cell_row => 828, cell_col => 4,	cell_type => 'Numeric',		s => '5', cell_xml_value => 40			},
					{ r => 'E828', cell_row => 828, cell_col => 5,	cell_type => 'Text',		s => '5', cell_xml_value => 2493		},
					{ r => 'F828', cell_row => 828, cell_col => 6,	cell_type => 'Text',		s => '5', cell_xml_value => 2428		},
					{ r => 'G828', cell_row => 828, cell_col => 7,	cell_type => 'Text',		s => '5', cell_xml_value => 308			},
					{ r => 'H828', cell_row => 828, cell_col => 8,	cell_type => 'Text',		s => '5', cell_xml_value => 311			},
					{ r => 'I828', cell_row => 828, cell_col => 9,	cell_type => 'Text',		s => '5', cell_xml_value => '092-318', cell_formula => 'A828'	},
					{ r => 'J828', cell_row => 828, cell_col => 10,	cell_type => 'Text',		s => '7', cell_xml_value => 311			},
					{ r => 'K828', cell_row => 828, cell_col => 11,	cell_type => 'Text',		s => '5', cell_xml_value => 308			},
					{ r => 'L828', cell_row => 828, cell_col => 12,	cell_type => 'Numeric',		s => '6', cell_xml_value => 42104		},
					'EOF',
				],
			];
###LogSD	$phone->talk( level => 'info', message => [ "easy questions ..." ] );

lives_ok{
			$workbook_instance = Spreadsheet::XLSX::Reader::LibXML->new(
									###LogSD log_space => 'Test'
								);
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::XLSX::Reader::LibXML::XMLReader'],
								package => 'WorksheetReader',
								file => $test_file,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow',
									'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData',
									'Spreadsheet::XLSX::Reader::LibXML::ZipReader::Worksheet',
									'Spreadsheet::XLSX::Reader::LibXML::WorksheetToRow',
									'Spreadsheet::XLSX::Reader::LibXML::Worksheet'
								],
			);
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance" ] );
}										"Prep a new WorksheetToRow instance";

###LogSD		$phone->talk( level => 'debug', message => [ "Max row is:" . $test_instance->_max_row ] );
is			$test_instance->_min_row, 1,
										"check that it knows what the lowest row number is";
is			$test_instance->_min_col, 1,
										"check that it knows what the lowest column number is";
is			$test_instance->_max_row, 1208,
										"check that it knows what the highest row number is";
is			$test_instance->_max_col, 50,
										"check that it knows what the highest column number is";

explain									"read through value cells ...";
			my $test = 0;
			for my $y (1..2){
			my $result;
explain									"Running cycle: $y";
			my $x = 0;
			while( !$result or $result ne 'EOF' ){
				
###LogSD	my $expose = 12;
###LogSD	if( $x == $expose and $y == 1 ){
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				_get_next_value_cell =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
###LogSD		} );
###LogSD	}

###LogSD	elsif( $x > ($expose + 0) and $y > 0 ){
###LogSD		exit 1;
###LogSD	}

lives_ok{	$result = $test_instance->_get_next_value_cell }
										"_get_next_value_cell test -$test- iteration -$y- from sheet position: $x";
			#~ print Dumper( $result );
###LogSD	$phone->talk( level => 'debug', message => [ "result at position -$x- is:", $result,
###LogSD		'Against answer:', $answer_ref->[$x], ] );
is_deeply	$result, $answer_ref->[$test]->[$x],"..........and see if test -$test- iteration -$y- from sheet position -$x- has good info";
			$x++;
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
###LogSD		printf( "| level - %-8s | name_space - %-s\n| line  - %07d | file_name  - %-s\n\t:(\t%s ):\n", 
###LogSD					$_[0]->{level}, $_[0]->{name_space},
###LogSD					$_[0]->{line}, $_[0]->{filename},
###LogSD					join( "\n\t\t", @print_list ) 	);
###LogSD		use warnings 'uninitialized';
###LogSD	}

###LogSD	1;