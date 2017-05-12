#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet ########9
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
		$lib		= '../../../../../' . $lib;
		$test_file	= '../../../../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 31;
use	Test::Moose;
use Test::Deep;
#~ use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( Bool ConsumerOf HasMethods Int Str );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
use	Data::Dumper;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								XMLReader =>{
#~ ###LogSD									extract_file =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_get_node_all =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										squash_node =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'trace',
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
use	Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use	Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet;
use	Spreadsheet::Reader::ExcelXML::Error;

	$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
	$test_file .= 'TestBook.xml';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  (  
			$test_instance, $workbook_instance, $file_handle, $extractor_instance, $shared_strings_instance, $format_instance,
	);
my 			@class_attributes = qw( is_hidden );
my  		@instance_methods = qw(
				is_sheet_hidden					_min_col							has_min_col
				_min_row						has_min_row							_max_col
				has_max_col						_max_row							has_max_row
				load_unique_bits				advance_row_position				build_row_data
				get_merge_map					get_custom_column_data				get_custom_row_data
			);
my	$answer_ref =[
		[
			undef,
			{
				'bestFit' => 1,
				'width' => '19.140625'
			},
			{
				'width' => re(qr/16.283815298507/),
				'bestFit' => 1
			},
			{
				'bestFit' => 1,
				'width' => re(qr/9.7131529850746/),
			},
			{
				'width' => re(qr/8.7132695895522/),
				'bestFit' => 1
			},
			{
				'bestFit' => 1,
				'width' => re(qr/11.284398320895/),
			}
		], 1,
		[
			undef,
			{
				'width' => '9.5703125',
				'bestFit' => 1
			},
			undef,
			{
				'bestFit' => 1,
				'hidden' => '1'
			},
			{
				'bestFit' => 1,
				'hidden' => '1'
			},
			{
				'width' => re(qr/9.7131529850746/),
				'bestFit' => 1
			}
		], 0,
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
				},
				add_methods =>{
					get_epoch_year => sub{ 1904 },
				}
			);
			$extractor_instance	= build_instance(
				superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
				package			=> 'ReaderInstance',
				file			=> $test_file,# $file_handle
				workbook_inst	=> $workbook_instance,
			###LogSD	log_space => 'Test',
			);
			$file_handle = $extractor_instance->extract_file( [ 'Worksheet', 'Sheet5' ] ),
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'WorksheetFileReader',
								file => $file_handle,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
								is_hidden => 1,
								add_roles_in_sequence =>[ 
									'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
									'Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet',
								],
			);# exit 1;
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance" ] );
}										"Prep a new NamedWorksheet instance";
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
is			$test_instance->_max_row, 6,
										"check that it knows what the highest row number is";
is			$test_instance->_max_col, 5,
										"check that it knows what the highest column number is";
			my $x = 0;
cmp_deeply	$test_instance->_get_column_formats, $answer_ref->[$x++],
										"Check that the column formats were recorded correctly";
is			$test_instance->is_sheet_hidden, $answer_ref->[$x++],
										"Check that the sheet knows if it is hidden";
ok			$file_handle = $extractor_instance->extract_file( [ 'Worksheet', 'Sheet1' ] ),
										"Extract 'Sheet1' ok";
###LogSD		if( 1 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD							Test =>{
###LogSD								Worksheet =>{
###LogSD									_load_unique_bits =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'trace',
###LogSD										},
###LogSD									},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
ok			$test_instance = WorksheetFileReader->new(
								file => $file_handle,
			###LogSD			log_space	=> 'Test::Worksheet',
								workbook_inst => $workbook_instance,
							),			"Build the new Worksheet interface";
is			$test_instance->_min_row, 1,
										"check that it knows what the lowest row number is";# exit 1;
is			$test_instance->_min_col, 1,
										"check that it knows what the lowest column number is";
is			$test_instance->_max_row, 14,
										"check that it knows what the highest row number is";
is			$test_instance->_max_col, 6,
										"check that it knows what the highest column number is";
###LogSD		if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				get_shared_string =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
###LogSD		} );
###LogSD		}
cmp_deeply	$test_instance->_get_column_formats, $answer_ref->[$x++],
										"Check that the column formats were recorded correctly";
is			$test_instance->is_sheet_hidden, $answer_ref->[$x++],
										"Check that the sheet knows if it is hidden";
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