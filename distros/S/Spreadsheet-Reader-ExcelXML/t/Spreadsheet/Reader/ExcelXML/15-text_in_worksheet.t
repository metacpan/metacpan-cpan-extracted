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
		$lib		= '../../../../' . $lib;
		$test_file	= '../../../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use Test::Most tests => 131;
use Test::Moose;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use	Types::Standard qw(
		InstanceOf		Str			Num			ConsumerOf
		HasMethods		Bool		Enum		Int
		is_RegexpRef	is_HashRef
	);
use	lib
		'../../../../../Log-Shiras/lib',
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
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::Format;
use	Spreadsheet::Reader::ExcelXML::Error;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
use Spreadsheet::Reader::ExcelXML::SharedStrings;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
use Spreadsheet::Reader::ExcelXML::Styles;
use Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::WorksheetToRow;
use Spreadsheet::Reader::ExcelXML::Worksheet;

$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'string_in_worksheet.xml';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $error_instance, $workbook_instance, $file_handle, $format_instance, $shared_strings_instance
	);
my			$answer_ref = [
				{ cell_id => 'A828', col => 828, col => 1,	type => 'Text',		xml_value => 2947,	},# s => '5', 
				{ cell_id => 'B828', col => 828, col => 2,	type => 'Text',		xml_value => 0,		},# s => '5', 
				{ cell_id => 'C828', col => 828, col => 3,	type => 'Numeric',	xml_value => 827	},
				{ cell_id => 'D828', col => 828, col => 4,	type => 'Numeric',	xml_value => 40		},
				{ cell_id => 'E828', col => 828, col => 5,	type => 'Text',		xml_value => 2493	},
				{ cell_id => 'F828', col => 828, col => 6,	type => 'Text',		xml_value => 2428	},
				{ cell_id => 'G828', col => 828, col => 7,	type => 'Text',		xml_value => 308	},
				{ cell_id => 'H828', col => 828, col => 8,	type => 'Text',		xml_value => 311	},
				{ cell_id => 'I828', col => 828, col => 9,	type => 'Text',		xml_value => '092-318', formula => 'A828' },
				{ cell_id => 'J828', col => 828, col => 10,	type => 'Text',		xml_value => 311	},
				{ cell_id => 'K828', col => 828, col => 11,	type => 'Text',		xml_value => 308	},
				{ cell_id => 'L828', col => 828, col => 12,	type => 'Numeric',	xml_value => 42104	},
				'EOF',
			];
###LogSD	$phone->talk( level => 'info', message => [ "easy questions ..." ] );

lives_ok{
			$workbook_instance = build_instance(
				package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
				add_attributes =>{
					error_inst =>{
						isa => 	HasMethods[qw(
											error set_error clear_error set_warnings if_warn
										) ],
						clearer		=> '_clear_error_inst',
						reader		=> 'get_error_inst',
						required	=> 1,
						handles =>[ qw(
							error set_error clear_error set_warnings if_warn
						) ],
						default => sub{ Spreadsheet::Reader::ExcelXML::Error->new() },
					},
					formatter_inst =>{
						isa	=> 	ConsumerOf[ 'Spreadsheet::Reader::Format' ],# Interface
						writer	=> 'set_formatter_inst',
						reader	=> 'get_formatter_inst',
						predicate => '_has_formatter_inst',
						handles => { qw(
								get_formatter_region			get_excel_region
								has_target_encoding				has_target_encoding
								get_target_encoding				get_target_encoding
								set_target_encoding				set_target_encoding
								change_output_encoding			change_output_encoding
								set_defined_excel_formats		set_defined_excel_formats
								get_defined_conversion			get_defined_conversion
								parse_excel_format_string		parse_excel_format_string
								set_date_behavior				set_date_behavior
								set_european_first				set_european_first
								set_formatter_cache_behavior	set_cache_behavior
								get_excel_region				get_excel_region
							),
						},
					},
					epoch_year =>{
						isa => Int,
						reader => 'get_epoch_year',
						default => 1904,
					},
					group_return_type =>{
						isa => Str,
						reader => 'get_group_return_type',
						writer => 'set_group_return_type',
						default => 'instance',
					},
					shared_strings_interface =>{
						isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::SharedStrings' ],
						predicate => 'has_shared_strings_interface',
						writer => 'set_shared_strings_interface',
						handles =>{
							'get_shared_string' => 'get_shared_string',
							'start_the_ss_file_over' => 'start_the_file_over',
						},
					},
					styles_insterface =>{
						isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::Styles' ],
						writer		=> 'set_styles_interface',
						reader		=> '_get_styles_interface',
						clearer		=> '_clear_styles_interface',
						predicate	=> 'has_styles_interface',
						handles		=>{
							get_format	=> 'get_format',
						},
					},
					empty_return_type =>{
						isa		=> Enum[qw( empty_string undef_string )],
						reader	=> 'get_empty_return_type',
						writer	=> 'set_empty_return_type',
					},
					from_the_edge =>{
						isa		=> Bool,
						reader	=> 'starts_at_the_edge',
						writer	=> 'set_from_the_edge',
					},
					spread_merged_values =>{
						isa => Bool,
						reader => 'spreading_merged_values',
					},
					skip_hidden =>{
						isa => Bool,
						reader => 'should_skip_hidden',
					},
					spaces_are_empty =>{
						isa => Bool,
						reader => 'are_spaces_empty',
					},
					values_only =>{
						isa		=> Bool,
						writer	=> 'set_values_only',
						reader	=> 'get_values_only',
					},
					count_from_zero =>{
						isa		=> Bool,
						reader	=> 'counting_from_zero',
						writer	=> 'set_count_from_zero',
					},
					file_boundary_flags =>{
						isa			=> Bool,
						reader		=> 'boundary_flag_setting',
						writer		=> 'change_boundary_flag',
					},
					empty_is_end =>{
						isa		=> Bool,
						writer	=> 'set_empty_is_end',
						reader	=> 'is_empty_the_end',
					},
					merge_data =>{
						isa => Bool,
						reader => 'collecting_merge_data',
					},
					column_formats =>{
						isa => Bool,
						reader => 'collecting_column_formats',
					},
				},
				column_formats => 1,
				merge_data => 1,
				values_only => 1,
				spaces_are_empty => 0,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 0,
				skip_hidden => 0,
				count_from_zero => 0,
				file_boundary_flags => 1,
				empty_is_end => 1,
			);
			$format_instance = build_instance(
								package => 'FormatInstance',
								superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
								add_roles_in_sequence =>[qw(
										Spreadsheet::Reader::Format::ParseExcelFormatStrings
										Spreadsheet::Reader::Format
								)],
			###LogSD				log_space	=> 'Test',
								target_encoding => 'latin1',# Adjust the string output encoding here
								workbook_inst => $workbook_instance,
							);
			$workbook_instance->set_formatter_inst( $format_instance );
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetInterface',
								file => $test_file,
								cache_positions => 1,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet',
									'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
									'Spreadsheet::Reader::ExcelXML::Worksheet',
								],
			);# exit 1;
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

lives_ok{	$result = $test_instance->get_next_value }
										"get_next_value iteration -$y- from sheet position: $x";
			#~ print Dumper( $result );
###LogSD	$phone->talk( level => 'debug', message => [ "result at position -$x- is:", $result,
###LogSD		'Against answer:', $answer_ref->[$x], ] );
			if( is_HashRef( $answer_ref->[$x] ) ){
			for my $method ( keys %{$answer_ref->[$x]} ){
is			$result->$method, $answer_ref->[$x]->{$method},
										"check if iteration -$y- from sheet position -$x- has the correct info for: $method";
			}
			}else{
is			$result, $answer_ref->[$x], "check if iteration -$y- from sheet position -$x- has the correct boundary flag";
			}
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