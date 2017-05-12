#########1 Test File to check that styles file with table styles don't die      8#########9
#!/usr/bin/env perl
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
		$lib		= '../../../../' . $lib;
		$test_file	= '../../../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 7;
use	Test::Moose;
use IO::File;
use Data::Dumper;
use	Spreadsheet::Reader::Format;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance		should_re_use_classes	set_args_cloning
	);
should_re_use_classes( 1 );
set_args_cloning ( 0 );
use Types::Standard qw( ConsumerOf HasMethods Int );
use	lib
		'../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'info',
###LogSD								},
###LogSD							},
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'debug',
###LogSD							},
###LogSD							Test =>{
###LogSD								StylesInterface =>{
###LogSD									XMLToPerlData =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									XMLReader =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD								},
#~ ###LogSD								parse_element =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								get_format_position =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								_get_header_and_value =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								parse_element =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								_build_date =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								get_format_position =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								_get_header_and_position =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								parse_excel_format_string =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::XMLReader;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
use	Spreadsheet::Reader::ExcelXML::Styles;
use	Spreadsheet::Reader::ExcelXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'table_styles.xml';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
		$workbook_instance, $format_instance, $test_instance,
	);
my			$answer_ref =[
				{
					cell_font =>{
						name => 'Calibri',
						family => '2',
						scheme => 'minor',
						sz => '11',
						color =>{
							theme => '1'
						}
					},
				}
			];
my 			$row = 0;
my 			@class_attributes = qw(
				cache_positions
			);
my  		@class_methods = qw(
				should_cache_positions		get_format			get_default_format
				loaded_correctly
			);
				#~ get_number_format
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$workbook_instance = build_instance(
										package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
										add_attributes =>{
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
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			$format_instance = build_instance(
								package => 'FormatInstance',
								superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
								add_roles_in_sequence =>[qw(
										Spreadsheet::Reader::Format::ParseExcelFormatStrings
										Spreadsheet::Reader::Format
								)],
								target_encoding => 'latin1',# Adjust the string output encoding here
								workbook_inst => $workbook_instance,
							);
			$workbook_instance->set_formatter_inst( $format_instance );
			$test_instance	=	build_instance(
									package => 'StylesInterface',
									superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
									add_roles_in_sequence => [
										'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
										'Spreadsheet::Reader::ExcelXML::Styles',
									],
									file => $test_file,
									workbook_inst => $workbook_instance,
			###LogSD				log_space => 'Test',
								);
			#~ $workbook_instance = build_instance(
										#~ package	=> 'Spreadsheet::XLSX::Reader::LibXML::Workbook',
										#~ add_attributes =>{
											#~ error_inst =>{
												#~ isa => 	HasMethods[qw(
																	#~ error set_error clear_error set_warnings if_warn
																#~ ) ],
												#~ clearer		=> '_clear_error_inst',
												#~ reader		=> 'get_error_inst',
												#~ required	=> 1,
												#~ handles =>[ qw(
													#~ error set_error clear_error set_warnings if_warn
												#~ ) ],
												#~ default => sub{ Spreadsheet::XLSX::Reader::LibXML::Error->new() },
											#~ },
											#~ formatter_inst =>{
												#~ isa	=> 	ConsumerOf[ 'Spreadsheet::XLSX::Reader::LibXML::FormatInterface' ],# Interface
												#~ writer	=> 'set_formatter_inst',
												#~ reader	=> 'get_formatter_inst',
												#~ predicate => '_has_formatter_inst',
												#~ handles => { qw(
														#~ get_formatter_region			get_excel_region
														#~ has_target_encoding				has_target_encoding
														#~ get_target_encoding				get_target_encoding
														#~ set_target_encoding				set_target_encoding
														#~ change_output_encoding			change_output_encoding
														#~ set_defined_excel_formats		set_defined_excel_formats
														#~ get_defined_conversion			get_defined_conversion
														#~ parse_excel_format_string		parse_excel_format_string
														#~ set_date_behavior				set_date_behavior
														#~ set_european_first				set_european_first
														#~ set_formatter_cache_behavior	set_cache_behavior
														#~ get_excel_region				get_excel_region
													#~ ),
												#~ },
											#~ },
											#~ epoch_year =>{
												#~ isa => Int,
												#~ reader => 'get_epoch_year',
												#~ default => 1904,
											#~ },
											#~ group_return_type =>{
												#~ isa => Str,
												#~ reader => 'get_group_return_type',
												#~ writer => 'set_group_return_type',
												#~ default => 'instance',
											#~ },
											#~ styles_interface =>{
												#~ isa => ConsumerOf[ 'Spreadsheet::XLSX::Reader::LibXML::Styles' ],
												#~ writer		=> 'set_styles_interface',
												#~ reader		=> '_get_styles_interface',
												#~ clearer		=> '_clear_styles_interface',
												#~ predicate	=> 'has_styles_interface',
												#~ handles		=>{
													#~ get_format	=> 'get_format',
													#~ _demolish_styles => 'DEMOLISH',
												#~ },
											#~ }
										#~ },
										#~ add_methods =>{
											#~ get_empty_return_type => sub{ 1 },
										#~ },
										#~ formatter_inst => $format_instance,
								#~ );
			#~ $format_instance	=	build_instance(
									#~ package	=> 'FormatInterface',
									#~ superclasses =>[
										#~ 'Spreadsheet::XLSX::Reader::LibXML::FmtDefault'
									#~ ],
									#~ add_roles_in_sequence =>[
										#~ 'Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings',
										#~ 'Spreadsheet::XLSX::Reader::LibXML::FormatInterface'
									#~ ],
									#~ workbook_inst => $workbook_instance,
#~ ###LogSD							log_space	=> 'Test',
								#~ );
			#~ $workbook_instance->set_formatter_inst( $format_instance );
			#~ $test_instance	=	build_instance(
									#~ package => 'Styles',
									#~ superclasses => ['Spreadsheet::XLSX::Reader::LibXML::XMLReader'],
									#~ add_roles_in_sequence => [
										#~ 'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData',
										#~ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionStyles',
										#~ 'Spreadsheet::XLSX::Reader::LibXML::Styles',
									#~ ],
									#~ file => $test_file,
									#~ workbook_inst => $workbook_instance,
			#~ ###LogSD				log_space => 'Test',
								#~ );
			#~ $workbook_instance->set_styles_interface( $test_instance );
}										"Prep a new Styles instance - cache_positions => 1";# exit 1;
map{ 
has_attribute_ok
			$test_instance, $_,			"Check that Spreadsheet::XLSX::Reader::LibXML::XMLDOM::Styles has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;
explain									"Currently this test does not check specific output of a table style just that it won't kill the sheet on loading";
###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
###LogSD		$phone->talk( level => 'debug', message => [ $test_instance->get_default_format ] );
is_deeply	$answer_ref->[0], $test_instance->get_default_format( 'cell_font' ),
										"Check that the default format for font is:" . Dumper( $answer_ref->[0] );
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