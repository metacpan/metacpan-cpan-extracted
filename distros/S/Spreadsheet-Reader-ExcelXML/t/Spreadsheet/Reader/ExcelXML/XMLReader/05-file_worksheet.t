#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $styles_file );
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	my	$start_deeper = 1;
	$lib		= 'lib';
	$test_file	= 't/test_files/xl/worksheets/';
	for my $next ( <*> ){
		if( ($next eq 't') and -d $next ){
			$start_deeper = 0;
			last;
		}
	}
	if( $start_deeper ){
		$lib		= '../../../../../' . $lib;
		$test_file	= '../../../../test_files/xl/worksheets/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 30;
use	Test::Moose;
#~ use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( Bool ConsumerOf HasMethods Int Str );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
use	Data::Dumper;
use Log::Shiras::Unhide qw( :debug );
###LogSD	use Log::Shiras::Report::Stdout;
###LogSD	use Log::Shiras::Switchboard;
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD							build_class =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD							build_instance =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										squash_node =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										_hidden =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
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
#~ ###LogSD							main =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'info',
#~ ###LogSD								},
#~ ###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Log::Shiras::Report::Stdout->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
use	Spreadsheet::Reader::ExcelXML::XMLReader;
use	Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use	Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
use	Spreadsheet::Reader::ExcelXML::Error;

	$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
my	$test_fil2 = $test_file . 'sheet3_test.xml';
	$test_file .= 'sheet3.xml';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  (  
			$test_instance, $workbook_instance, $file_handle, $shared_strings_instance, $format_instance,
	);
my 			@class_attributes = qw( is_hidden );
my  		@instance_methods = qw(
				is_sheet_hidden					_min_col							has_min_col
				_min_row						has_min_row							_max_col
				has_max_col						_max_row							has_max_row
				load_unique_bits				advance_row_position				build_row_data
				get_merge_map					get_custom_column_data				get_custom_row_data
			);#current_row_node_parsed
										
my	$answer_ref =[
		[
			undef,
			{
				'width' => '9.5703125',
				'customWidth' => '1',
				'bestFit' => '1'
			},
			undef,
			{
				'width' => '0',
				'customWidth' => '1',
				'hidden' => '1'
			},
			{
				'width' => '0',
				'customWidth' => '1',
				'hidden' => '1'
			},
			{
				'customWidth' => '1',
				'bestFit' => '1',
				'width' => '9.7109375'
			}
        ],
		[
			undef, undef, undef, undef, undef, undef,
			[
				undef, 'A6:B6', 'A6:B6'
			],
			undef, undef, undef, undef, undef,
			[
				undef, undef, undef, undef, 'D12:E12', 'D12:E12'
			]
        ],
		[
			undef,
			{
				'bestFit' => '1',
				'customWidth' => '1',
				'width' => '9.5703125'
			},
			undef, undef, undef,
			{
				'customWidth' => '1',
				'bestFit' => '1',
				'width' => '9.7109375'
			}
        ],
		[
			undef, undef, undef, undef, undef, undef,
			[
				undef, 'A6:B6', 'A6:B6'
			],
			undef, undef, undef, undef, undef,
			[
				undef, undef, undef, undef, 'D12:E12', 'D12:E12'
			]
        ],
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
					from_the_edge =>{
						isa		=> Bool,
						reader	=> 'starts_at_the_edge',
						writer	=> 'set_from_the_edge',
						default => 1,
					},
					merge_data =>{
						isa => Bool,
						reader => 'collecting_merge_data',
						default => 1,
					},
					column_formats =>{
						isa => Bool,
						reader => 'collecting_column_formats',
						default => 1,
					},
				},
			);
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetFileReader',
								file => $test_file,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet',
								],
			);# exit 1;
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance" ] );
}										"Prep a new FileWorksheet instance";# exit 1;
map{
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;
			#~ exit 1;
map{
can_ok		$test_instance, $_,
} 			@instance_methods;
is			$test_instance->_min_row, 1,
										"check that it knows what the lowest row number is";# exit 1;
is			$test_instance->_min_col, 1,
										"check that it knows what the lowest column number is";
is			$test_instance->_max_row, undef,
										"check that it knows what the highest row number is (not)";
is			$test_instance->_max_col, undef,
										"check that it knows what the highest column number is (not)";
			my $x = 0;
is_deeply	$test_instance->_get_column_formats, $answer_ref->[$x++],
										"Check that the column formats were recorded correctly";
is_deeply	$test_instance->get_merge_map, $answer_ref->[$x++],
										"Check that the merge map was recorded correctly";
lives_ok{
			
			$test_instance = WorksheetFileReader->new(
								file => $test_fil2,
								is_hidden => 0,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
			);# exit 1;
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance" ] );
}										"Prep a new FileWorksheet instance with a different file";
is			$test_instance->_min_row, 1,
										"check that it knows what the lowest row number is";# exit 1;
is			$test_instance->_min_col, 1,
										"check that it knows what the lowest column number is";
is			$test_instance->_max_row, 14,
										"check that it knows what the highest row number is";
is			$test_instance->_max_col, 6,
										"check that it knows what the highest column number is";
			#~ print Dumper( $test_instance->_get_column_formats );
is_deeply	$test_instance->_get_column_formats, $answer_ref->[$x++],
										"Check that the column formats were recorded correctly";
			#~ print Dumper( $test_instance->_get_merge_map );
is_deeply	$test_instance->get_merge_map, $answer_ref->[$x++],
										"Check that the merge map was recorded correctly";
explain 								"...Test Done";
done_testing();