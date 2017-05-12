#########1 Test File for Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels ########9
#!/usr/bin/env perl
my ( $lib, $test_file );
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	my	$start_deeper = 1;
	$lib		= 'lib';
	$test_file	= 't/test_files/xl/_rels/';
	for my $next ( <*> ){
		if( ($next eq 't') and -d $next ){
			$start_deeper = 0;
			last;
		}
	}
	if( $start_deeper ){
		$lib		= '../../../../../' . $lib;
		$test_file	= '../../../../test_files/xl/_rels/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 9;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );#
use Types::Standard qw( HashRef );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							Test =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'trace',
###LogSD								},
###LogSD								WorkbookFileInterface =>{
###LogSD									UNBLOCK =>{
###LogSD										log_file => 'warn',
###LogSD									},
###LogSD								},
###LogSD								WorkbookRelsInterface =>{
###LogSD									XMLReader =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD								},
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
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface;
	$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
	$test_file .= 'workbook.xml.rels';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $workbook_instance, $file_handle,
	);
my 			$row = 0;
#~ my 			@class_attributes = qw(
				#~ worksheet_list			chartsheet_list			sheet_lookup
			#~ );
my  		@class_methods = qw(
				get_worksheet_list		get_chartsheet_list		get_sheet_lookup
				loaded_correctly		load_unique_bits
			);
my			$test_ref ={
				get_chartsheet_list =>[],
				get_worksheet_list =>[
					'Sheet2',
					'Sheet5',
					'Sheet1'
		        ],
				get_sheet_lookup =>{
					'Sheet1' => {
						'file' => [[ 'Worksheet', 'Sheet1' ]],
						'is_hidden' => 0,
						'sheet_rel_id' => 'rId3',
						'sheet_name' => 'Sheet1',
						'sheet_id' => '1',
						'sheet_type' => 'worksheet',
						'sheet_position' => 2
					},
					'Sheet5' => {
						'file' => [[ 'Worksheet', 'Sheet5' ]],
						'sheet_id' => '3',
						'sheet_position' => 1,
						'sheet_type' => 'worksheet',
						'is_hidden' => 1,
						'sheet_name' => 'Sheet5',
						'sheet_rel_id' => 'rId2'
					},
					'Sheet2' => {
						'file' => [[ 'Worksheet', 'Sheet2' ]],
						'sheet_position' => 0,
						'sheet_type' => 'worksheet',
						'sheet_id' => '2',
						'is_hidden' => 0,
						'sheet_rel_id' => 'rId1',
						'sheet_name' => 'Sheet2'
					},
				}
					
			};
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$workbook_instance = build_instance(
				package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
				add_attributes =>{
					_rel_lookup =>{
						isa		=> HashRef,
						traits	=> ['Hash'],
						handles	=>{ get_rel_info => 'get', },
						default	=> sub{ {
							'rId2' => 'Sheet5',
							'rId3' => 'Sheet1',
							'rId1' => 'Sheet2'
						} },
					},
					_sheet_lookup =>{
						isa		=> HashRef,
						traits	=> ['Hash'],
						handles	=>{ get_sheet_info => 'get', },
						default	=> sub{ {
							'Sheet1' => {
								'sheet_id' => '1',
								'sheet_position' => 2,
								'sheet_name' => 'Sheet1',
								'is_hidden' => 0,
								'sheet_rel_id' => 'rId3'
							},
							'Sheet2' => {
								'sheet_position' => 0,
								'sheet_name' => 'Sheet2',
								'sheet_id' => '2',
								'sheet_rel_id' => 'rId1',
								'is_hidden' => 0
							},
							'Sheet5' => {
								'sheet_position' => 1,
								'sheet_name' => 'Sheet5',
								'sheet_id' => '3',
								'sheet_rel_id' => 'rId2',
								'is_hidden' => 1
							}
						} },
					},
				},
				add_methods =>{
					get_sheet_names => sub{ [
						'Sheet2',
						'Sheet5',
						'Sheet1'
					] },
				}
			);
			$file_handle = IO::File->new_tmpfile;
			$file_handle->binmode();
			print $file_handle '<?xml version="1.0"?><NO_FILE/>';
			$test_instance =  build_instance(
				superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
				package	=> 'WorkbookRelsInterface',
				add_roles_in_sequence =>[ 
					'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels',
					'Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface',
				],
				file => $file_handle,
				workbook_inst => $workbook_instance,
			###LogSD	log_space	=> 'Test',
			);# exit 1;
}										"Prep a Zip based WorkbookMetaInterface instance";# exit 1;
#~ map{ 
#~ has_attribute_ok
			#~ $test_instance, $_,
										#~ "Check that the WorkbookMetaInterface instance has the -$_- attribute"
#~ } 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'trace', message => [ 'Test instance:', $test_instance ] );
			for my $test_method ( keys %$test_ref ){
is_deeply	$test_instance->$test_method, $test_ref->{$test_method},
										"Check that the -$test_method- is:" . Dumper( $test_ref->{$test_method} );
			}
###LogSD		if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD		} );
###LogSD		}
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