#!/usr/bin/env perl
# Includes bug #97 test
$|=1;
use Data::Dumper;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( ConsumerOf HasMethods Int );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::Error;
use Spreadsheet::Reader::ExcelXML::Styles;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::Format;
my	$workbook_instance = build_instance(
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
my	$format_instance = build_instance(
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
my	$test_instance	=	build_instance(
		package => 'StylesInterface',
		superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		add_roles_in_sequence => [
			'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
			'Spreadsheet::Reader::ExcelXML::Styles',
		],
		file => '../../../../t/test_files/xl/styles.xml',,
		workbook_inst => $workbook_instance,
	);
print Dumper( $test_instance->get_format( 2 ) );