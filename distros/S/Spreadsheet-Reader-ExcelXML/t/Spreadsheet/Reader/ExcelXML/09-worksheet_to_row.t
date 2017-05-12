#########1 Test File for Spreadsheet::Reader::ExcelXML::WorksheetToRow          8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, );
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

use	Test::Most tests => 52;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( Bool ConsumerOf HasMethods Int Str Enum );
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
#~ ###LogSD							build_class =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'warn',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							build_instance =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'warn',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_parse_column_row =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								SharedStringsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD							},
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
use	Spreadsheet::Reader::ExcelXML::XMLReader;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::SharedStrings;
use	Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use	Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::WorksheetToRow;
use	Spreadsheet::Reader::ExcelXML::Error;

my(  
	$test_fil2, $test_instance, $workbook_instance, $file_handle, $shared_strings_instance,
	$format_instance, $extractor_instance, $shared_strings_file
);
	$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
	$shared_strings_file = $test_file . 'xl/sharedStrings.xml';
	$test_fil2 = $test_file . 'TestBook.xml';
	$test_file .= 'xl/worksheets/sheet3.xml';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my 			@class_attributes = qw(
				cache_positions
			);
my  		@instance_methods = qw(
				go_to_or_past_row				should_cache_positions 					get_new_column
				has_new_row_inst				get_new_next_value
			);

my			$answer_ref = [
				[ 	1, 2, # Round one files - caching
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 4,
						'row_number' => '2',
						'row_span' => [ 1, 4 ],
						'row_formats' =>{ 'r' => '2' },
						'column_to_cell_translations' =>[ undef, 0, undef, undef, 1 ],
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
							{
								'cell_hidden' => 'column',
								'cell_col' => 4,
								'cell_row' => 2,
								'cell_type' => 'Text',
								'r' => 'D2',
								'cell_xml_value' => 'my'
							}
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
					0, {
						'row_number' => '2',
						'row_last_value_column' => 4,
						'row_span' =>[ 1, 4 ],
						'row_formats' =>{ 'r' => '2' },
						'column_to_cell_translations' =>[ undef, 0, undef, undef, 1 ],
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
							{
								'cell_hidden' => 'column',
								'cell_col' => 4,
								'cell_row' => 2,
								'cell_type' => 'Text',
								'r' => 'D2',
								'cell_xml_value' => 'my'
							}
						],
					}
				],
				[ 	6,6,
					2, {
						'row_last_value_column' => 2,
						'row_number' => 6,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, 0, 1 ],
						'row_formats' =>{
							'ht' => '26.25',
                            'spans' => '1:6',
                            'r' => '6'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello World',
								'cell_col' => 1,
								'cell_row' => 6,
								'r' => 'A6',
								'cell_type' => 'Text',
								's' => '11',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'family' => '2',
										'color' => { 'rgb' => 'FFFF0000' },
										'sz' => '11',
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'b' => undef
									},
									6, {
										'b' => undef,
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
										'family' => '2'
									}
								]
							},
							{
								'cell_xml_value' => 'Hello World',
								'r' => 'B6',
								'cell_row' => 6,
								'cell_col' => 2,
								'cell_type' => 'Text',
								's' => '11',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'family' => '2',
										'color' => { 'rgb' => 'FFFF0000' },
										'sz' => '11',
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'b' => undef
									},
									6, {
										'b' => undef,
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
										'family' => '2'
									}
								]
							}
						],
					}
				],
				[ 	15,'EOF',
					8, {
						'row_last_value_column' => 5,
						'row_number' => 12,
						'row_span' => [ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, 0, undef, 1, 2 ],
						'row_formats' => {
							'r' => '12',
							'spans' => '1:6'
						},
						'row_value_cells' => [
							{
								'cell_formula' => 'IF(B11>0,"Hello","")',
								'cell_type' => 'Text',
								'r' => 'B12',
								'cell_col' => 2,
								'cell_row' => 12
							},
							{
								'cell_col' => 4,
								'cell_merge' => 'D12:E12',
								'cell_formula' => 'DATEVALUE(E10)',
								'cell_type' => 'Numeric',
								'cell_hidden' => 'column',
								'r' => 'D12',
								's' => '10',
								'cell_row' => 12,
								'cell_xml_value' => '39118'
							},
							{
								'cell_col' => 5,
								'cell_merge' => 'D12:E12',
								'cell_type' => 'Numeric',
								'cell_xml_value' => '39118',
								's' => '10',
								'r' => 'E12',
								'cell_row' => 12
							}
						],
					}
				],
				[ 	10, 10,
					8, {
						'row_number' => 12,
						'row_last_value_column' => 5,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, 0, undef, 1, 2 ],
						'row_formats' => {
							'spans' => '1:6',
							'r' => '12'
						},
						'row_value_cells' => [
							{
								'cell_col' => 2,
								'cell_formula' => 'IF(B11>0,"Hello","")',
								'r' => 'B12',
								'cell_type' => 'Text',
								'cell_row' => 12
							},
							{
								'cell_col' => 4,
								'cell_xml_value' => '39118',
								'cell_formula' => 'DATEVALUE(E10)',
								'r' => 'D12',
								'cell_row' => 12,
								'cell_type' => 'Numeric',
								'cell_merge' => 'D12:E12',
								'cell_hidden' => 'column',
								's' => '10'
							},
							{
								'cell_col' => 5,
								's' => '10',
								'r' => 'E12',
								'cell_xml_value' => '39118',
								'cell_type' => 'Numeric',
								'cell_row' => 12,
								'cell_merge' => 'D12:E12'
							}
						]
					}
				],
				[ 	1, 2, # Round 2 files - no caching - no empties
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 1,
						'row_number' => '2',
						'row_span' => [ 1, 1 ],
						'column_to_cell_translations' =>[ undef, 0, ],
						'row_formats' =>{ 'r' => '2' },
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
				],
				[ 	6,6,
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 1,
						'row_number' => 6,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, 0, ],
						'row_formats' =>{
							'ht' => '26.25',
                            'spans' => '1:6',
                            'r' => '6'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello World',
								'cell_col' => 1,
								'cell_row' => 6,
								'r' => 'A6',
								'cell_type' => 'Text',
								's' => '11',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'family' => '2',
										'color' => { 'rgb' => 'FFFF0000' },
										'sz' => '11',
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'b' => undef
									},
									6, {
										'b' => undef,
										'rFont' => 'Calibri',
										'scheme' => 'minor',
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
										'family' => '2'
									}
								]
							},
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
				],
				[ 	15,'EOF', undef ],
				[ 	10, 14,
					bless( {
						###LogSD	'log_space' => 'Test::Worksheet',
						'row_number' => 14,
						'row_last_value_column' => 5,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, undef, undef, undef, 0, ],
						'row_formats' => {
							'spans' => '1:6',
							'r' => '14'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => '39118',
								's' => '2',
								'cell_row' => 14,
								'cell_col' => 5,
								'r' => 'E14',
								'cell_formula' => 'D14',
								'cell_type' => 'Numeric'
							}
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' )
				],
				[ 	1, 2, # Round 3 - named sheets - caching
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 4,
						'row_number' => '2',
						'row_span' => [ 1, 6 ],
						'column_to_cell_translations' =>[ undef, 0, undef, undef, 1 ],
						'row_formats' =>{ 'r' => '2' },
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
							{
								'cell_hidden' => 'column',
								'cell_col' => 4,
								'cell_row' => 2,
								'cell_type' => 'Text',
								'r' => 'D2',
								'cell_xml_value' => 'my'
							}
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
					0, {
						'row_number' => '2',
						'row_last_value_column' => 4,
						'row_span' =>[ 1, 6 ],
						'row_formats' =>{ 'r' => '2' },
						'column_to_cell_translations' =>[ undef, 0, undef, undef, 1 ],
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
							{
								'cell_hidden' => 'column',
								'cell_col' => 4,
								'cell_row' => 2,
								'cell_type' => 'Text',
								'r' => 'D2',
								'cell_xml_value' => 'my'
							}
						],
					}
				],
				[ 	6,6,
					2, {
						'row_last_value_column' => 2,
						'row_number' => 6,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, 0, 1 ],
						'row_formats' =>{
							'ht' => '26.25',
                            'r' => '6'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello World',
								'cell_col' => 1,
								'cell_row' => 6,
								'r' => 'A6',
								'cell_type' => 'Text',
								's' => 's20',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'color' => { 'rgb' => 'FFFF0000' },
										'b' => undef
									},
									6, {
										'b' => undef,
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
									}
								]
							},
							{
								'cell_xml_value' => 'Hello World',
								'r' => 'B6',
								'cell_row' => 6,
								'cell_col' => 2,
								'cell_type' => 'Text',
								's' => 's20',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'color' => { 'rgb' => 'FFFF0000' },
										'b' => undef
									},
									6, {
										'b' => undef,
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
									}
								]
							}
						],
					}
				],
				[ 	15,'EOF',
					8, {
						'row_last_value_column' => 5,
						'row_number' => 12,
						'row_span' => [ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, 0, undef, 1, 2 ],
						'row_formats' => {},
						'row_value_cells' => [
							{
								'cell_formula' => 'IF(R[-1]C>0,"Hello","")',
								'cell_type' => 'Text',
								'r' => 'B12',
								'cell_col' => 2,
								'cell_row' => 12
							},
							{
								'cell_col' => 4,
								'cell_merge' => 'D12:E12',
								'cell_formula' => 'DATEVALUE(R[-2]C[1])',
								'cell_type' => 'Date',
								'cell_hidden' => 'column',
								'r' => 'D12',
								's' => 's27',
								'cell_row' => 12,
								'cell_xml_value' => '2011-02-06T00:00:00.000',
								'cell_unformatted' => 39118,
							},
							{
								'cell_col' => 5,
								'cell_merge' => 'D12:E12',
								'cell_formula' => 'DATEVALUE(R[-2]C[0])',
								'cell_type' => 'Date',
								'cell_xml_value' => '2011-02-06T00:00:00.000',
								'cell_unformatted' => 39118,
								's' => 's27',
								'r' => 'E12',
								'cell_row' => 12
							}
						],
					}
				],
				[ 	10, 10,
					8, {
						'row_last_value_column' => 5,
						'row_number' => 12,
						'row_span' => [ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, 0, undef, 1, 2 ],
						'row_formats' => {},
						'row_value_cells' => [
							{
								'cell_formula' => 'IF(R[-1]C>0,"Hello","")',
								'cell_type' => 'Text',
								'r' => 'B12',
								'cell_col' => 2,
								'cell_row' => 12
							},
							{
								'cell_col' => 4,
								'cell_merge' => 'D12:E12',
								'cell_formula' => 'DATEVALUE(R[-2]C[1])',
								'cell_type' => 'Date',
								'cell_hidden' => 'column',
								'r' => 'D12',
								's' => 's27',
								'cell_row' => 12,
								'cell_xml_value' => '2011-02-06T00:00:00.000',
								'cell_unformatted' => 39118,
							},
							{
								'cell_col' => 5,
								'cell_merge' => 'D12:E12',
								'cell_formula' => 'DATEVALUE(R[-2]C[0])',
								'cell_type' => 'Date',
								'cell_xml_value' => '2011-02-06T00:00:00.000',
								'cell_unformatted' => 39118,
								's' => 's27',
								'r' => 'E12',
								'cell_row' => 12
							}
						],
					}
				],
				[ 	1, 2, # Round 4 answers - named sheets - no caching - no empties
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 1,
						'row_number' => '2',
						'row_span' => [ 1, 6 ],
						'column_to_cell_translations' =>[ undef, 0 ],
						'row_formats' =>{ 'r' => '2' },
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello',
								'cell_type' => 'Text',
								'cell_row' => 2,
								'cell_col' => 1,
								'r' => 'A2'
							},
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
				],
				[ 	6,6,
					bless( {
					###LogSD	'log_space' => 'Test::Worksheet',
						'row_last_value_column' => 1,
						'column_to_cell_translations' =>[ undef, 0, ],
						'row_number' => 6,
						'row_span' =>[ 1, 6 ],
						'row_formats' =>{
							'ht' => '26.25',
                            'r' => '6'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => 'Hello World',
								'cell_col' => 1,
								'cell_row' => 6,
								'r' => 'A6',
								'cell_type' => 'Text',
								's' => 's20',
								'cell_merge' => 'A6:B6',
								'rich_text' => [
									2, {
										'color' => { 'rgb' => 'FFFF0000' },
										'b' => undef
									},
									6, {
										'b' => undef,
										'sz' => '20',
										'color' => { rgb => 'FF0070C0' },
									}
								]
							},
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' ),
				],
				[ 	15,'EOF', undef ],
				[ 	10, 14,
					bless( {
						###LogSD	'log_space' => 'Test::Worksheet',
						'row_number' => 14,
						'row_last_value_column' => 5,
						'row_span' =>[ 1, 6 ],
						'column_to_cell_translations' =>[ undef, undef, undef, undef, undef, 0, ],
						'row_formats' => {
							'r' => '14'
						},
						'row_value_cells' => [
							{
								'cell_xml_value' => '2011-02-06T00:00:00.000',
								'cell_unformatted' => 39118,
								's' => 's17',
								'cell_row' => 14,
								'cell_col' => 5,
								'r' => 'E14',
								'cell_formula' => 'RC[-1]',
								'cell_type' => 'Date'
							}
						],
					}, 'Spreadsheet::Reader::ExcelXML::Row' )
				],
			];

###LogSD	$phone->talk( level => 'info', message => [ "easy questions ..." ] );
explain		"Building test class #1";
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
				spaces_are_empty => 1,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 1,
				skip_hidden => 0,
			);
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
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetToRowFileReader',
								file => $test_file,
								cache_positions => 1,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet',
									'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
								],
			);# exit 1;
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance 1" ] );
}										"Prep a new WorksheetToRow instance with FileWorksheet methods";
map{
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;
			#~ exit 1;
map{
can_ok		$test_instance, $_,
} 			@instance_methods;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			UNBLOCK =>{
#~ ###LogSD				log_file => 'trace',
#~ ###LogSD			},
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
#~ ###LogSD				XMLReader =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				SharedStringsInterface =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			my $test = 0;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";# exit 1;
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct instance";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[3] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[3], ),   $answer_ref->[$test]->[4],
										"Check for a cached set for that position";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					build_row_data =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";# exit 1;
explain		"Building test class #2";
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
				spaces_are_empty => 1,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 0,
				skip_hidden => 1,
			);
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
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetToRowFileReader',
								file => $test_file,
								cache_positions => 0,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet',
									'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
								],
			);
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance 2" ] );
}										"Re-write the workbook instance with FileWorksheet methods and spread_merged_values = 0";
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct instance";# exit 1;
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[3] ) );
is			$test_instance->_get_row_inst( 0 ),   undef,
										"Check that no cached position is available - or at least the first one is missing";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
###LogSD	$phone->talk( level => 'info', message => [ "Start over with the easy questions for NamedWorksheets ..." ] );
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
#~ ###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					build_row_data =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
explain		"Building test class #3";
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
				spaces_are_empty => 1,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 1,
				skip_hidden => 0,
			);
			$extractor_instance	= build_instance(
				superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
				package			=> 'ReaderInstance',
				file			=> $test_fil2,# $file_handle
				workbook_inst	=> $workbook_instance,
			###LogSD	log_space => 'Test',
			);
			$file_handle = $extractor_instance->extract_file( [ 'Worksheet', 'Sheet1' ] ),
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetToRowNamedReader',
								file => $file_handle,
								cache_positions => 1,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet',
									'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
								],
			);# exit 1;
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance 3" ] );
}										"Prep a new WorksheetToRow instance with NamedWorksheets";# exit 1;
map{
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;
			#~ exit 1;
map{
can_ok		$test_instance, $_,
} 			@instance_methods;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			UNBLOCK =>{
#~ ###LogSD				log_file => 'trace',
#~ ###LogSD			},
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					advance_row_position =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
#~ ###LogSD				XMLReader =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				SharedStringsInterface =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test ++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";# exit 1;
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct instance";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[3] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[3], ),   $answer_ref->[$test]->[4],
										"Check for a cached set for that position";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					NamedWorksheet =>{
###LogSD						build_row_data =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD						_process_data_element =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";# exit 1;
###LogSD	if( 1 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					NamedWorksheet =>{
###LogSD						build_row_data =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD						_process_data_element =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD						parse_element =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					NamedWorksheet =>{
###LogSD						build_row_data =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD						_process_data_element =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[2] ) );
is_deeply	$test_instance->_get_row_inst( $answer_ref->[$test]->[2], ),   $answer_ref->[$test]->[3],
										"Check for a cached set for position: $answer_ref->[$test]->[2]";
explain		"Building test class #4";
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
				spaces_are_empty => 1,
				empty_return_type => 'undef_string',
				from_the_edge => 1,
				spread_merged_values => 0,
				skip_hidden => 1,
			);
			$extractor_instance	= build_instance(
				superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
				package			=> 'ReaderInstance',
				file			=> $test_fil2,# $file_handle
				workbook_inst	=> $workbook_instance,
			###LogSD	log_space => 'Test',
			);
			$file_handle = $extractor_instance->extract_file( [ 'Worksheet', 'Sheet1' ] ),
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetToRowNamedReader',
								file => $file_handle,
								cache_positions => 0,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet',
									'Spreadsheet::Reader::ExcelXML::WorksheetToRow',
								],
			);
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance 4" ] );
}										"Re-write the workbook instance with spread_merged_values = 0";
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct instance";# exit 1;
			#~ print Dumper( $test_instance->_get_row_inst( $answer_ref->[$test]->[3] ) );
is			$test_instance->_get_row_inst( 0 ),   undef,
										"Check that no cached position is available - or at least the first one is missing";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
###LogSD	if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
###LogSD	if( 1 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					build_row_data =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
			$test++;
is			$test_instance->go_to_or_past_row( $answer_ref->[$test]->[0] ), $answer_ref->[$test]->[1],
										"Try to arrive at row $answer_ref->[$test]->[0] (but get to row $answer_ref->[$test]->[1])";
			#~ print Dumper( $test_instance->_get_new_row_inst );
is_deeply	$test_instance->_get_new_row_inst,  $answer_ref->[$test]->[2],
										"Check for the correct stored instance";# exit 1;
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