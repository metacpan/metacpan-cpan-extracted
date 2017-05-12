#########1 Test File for unhandled cell type 'b'                  6#########7#########8#########9
#!perl
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
		$lib		= '../../' . $lib;
		$test_file	= '../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 2;
use	Test::Moose;
use Clone 'clone';
use Data::Dumper;
use	Types::Standard qw(
		InstanceOf		Str			Num			ConsumerOf
		HasMethods		Bool		Enum		Int
		is_RegexpRef
	);
use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance	set_args_cloning
	);
set_args_cloning ( 0 );
use	lib
		$lib,
        '../../../p5-spreadsheet-reader-format/lib'
	;
#~ use Log::Shiras::Unhide qw( :debug );
###LogSD	use Log::Shiras::Report::Stdout;
###LogSD	use Log::Shiras::Switchboard;
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							Test =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'trace',
###LogSD								},
###LogSD								SharedStringsInterface =>{
###LogSD									UNBLOCK =>{
###LogSD										log_file => 'warn',
###LogSD									},
###LogSD								},
###LogSD								StylesInterface =>{
###LogSD									UNBLOCK =>{
###LogSD										log_file => 'warn',
###LogSD									},
###LogSD								},
###LogSD								ExcelFormatInterface =>{
###LogSD									UNBLOCK =>{
###LogSD										log_file => 'warn',
###LogSD									},
###LogSD								},
###LogSD								Worksheet =>{
###LogSD								    XMLReader =>{
###LogSD								        _hidden =>{
###LogSD										    UNBLOCK =>{
###LogSD											    log_file => 'warn',
###LogSD										    },
###LogSD									    },
###LogSD								    },
#~ ###LogSD									FileWorksheet =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_parse_column_row =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									get_excel_position =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
###LogSD								},
###LogSD							},
###LogSD                                            UNBLOCK =>{
###LogSD							            log_file => 'trace',
###LogSD								    },
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'info',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Log::Shiras::Report::Stdout->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::Format;
use	Spreadsheet::Reader::ExcelXML::Error;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
use Spreadsheet::Reader::ExcelXML::SharedStrings;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
use Spreadsheet::Reader::ExcelXML::Styles;
use Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
use Spreadsheet::Reader::ExcelXML::WorksheetToRow;
use Spreadsheet::Reader::ExcelXML::Worksheet;
use Spreadsheet::Reader::ExcelXML::Cell;
	$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
my	$shared_strings_file = $test_file;
my	$styles_file = $test_file;
my	$xml_file = $test_file;
	$shared_strings_file .= 'xl/boolean_sharedStrings.xml';
	$styles_file .= 'xl/boolean_styles.xml';
	$test_file .= 'xl/worksheets/boolean_test.xml';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $error_instance, $styles_instance, $shared_strings_instance,
			$string_type, $date_time_type, $cell, $row_ref, $offset, $workbook_instance,
			$file_handle, $styles_handle, $shared_strings_handle, $format_instance,
			$extractor_instance
	);
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
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
				values_only => 0,
				spaces_are_empty => 0,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 0,
				skip_hidden => 0,
				count_from_zero => 1,
				file_boundary_flags => 1,
				empty_is_end => 0,
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
			$shared_strings_instance = build_instance(
									package => 'SharedStrings',
									superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
									add_roles_in_sequence => [
										'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
										'Spreadsheet::Reader::ExcelXML::SharedStrings',
									],
			###LogSD				log_space	=> 'Test',
									file		=> $shared_strings_file,
									workbook_inst	=> $workbook_instance,
								);
			$workbook_instance->set_shared_strings_interface( $shared_strings_instance );
			$styles_instance	=	build_instance(
									package => 'PositionStyles',
									superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
									add_roles_in_sequence => [
										'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
										'Spreadsheet::Reader::ExcelXML::Styles',
									],
									file => $styles_file,
									workbook_inst => $workbook_instance,
			###LogSD				log_space => 'Test',
								);
			$workbook_instance->set_styles_interface( $styles_instance );
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
			);
}										"Prep a test WorksheetInterface instance";

###LogSD		$phone->talk( level => 'trace', message => [ 'Test instance:', $test_instance ] );
explain									"Test get_cell";
is			$test_instance->get_cell( 0, 0 )->value, 1,
										"Check that you can get the value from a boolean formatted cell (As a number)";
explain 								"...Test Done";
done_testing();