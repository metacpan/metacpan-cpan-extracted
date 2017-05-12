#########1 Test File for Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta ########9
#!/usr/bin/env perl
my ( $lib, $test_file );
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	my	$start_deeper = 1;
	$lib		= 'lib';
	$test_file	= 't/test_files/xl/';
	for my $next ( <*> ){
		if( ($next eq 't') and -d $next ){
			$start_deeper = 0;
			last;
		}
	}
	if( $start_deeper ){
		$lib		= '../../../../../' . $lib;
		$test_file	= '../../../../test_files/xl/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 13;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );#
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
###LogSD								WorkbookMetaInterface =>{
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
#~ use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
#~ use Spreadsheet::Reader::ExcelXML::ZipReader;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface;
	$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
	$test_file .= 'workbook.xml';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $extractor_instance, $file_handle,
	);
my 			$row = 0;
#~ my 			@class_attributes = qw(
				#~ epoch_year				sheet_list				sheet_lookup
				#~ rel_lookup				id_lookup
			#~ );
my  		@class_methods = qw(
				get_epoch_year			get_sheet_list			get_sheet_lookup
				get_rel_lookup			get_id_lookup			loaded_correctly
				load_unique_bits
			);
my			$test_ref ={
				get_epoch_year => 1904,
				get_sheet_list =>[
					'Sheet2',
					'Sheet5',
					'Sheet1'
		        ],
				get_sheet_lookup =>{
					'Sheet1' => {
						'sheet_position' => 2,
						'is_hidden' => 0,
						'sheet_name' => 'Sheet1',
						'sheet_id' => '1',
						'sheet_rel_id' => 'rId3'
					},
					'Sheet5' => {
						'sheet_id' => '3',
						'sheet_name' => 'Sheet5',
						'sheet_rel_id' => 'rId2',
						'is_hidden' => 1,
						'sheet_position' => 1
					},
					'Sheet2' => {
						'sheet_rel_id' => 'rId1',
						'sheet_name' => 'Sheet2',
						'sheet_id' => '2',
						'sheet_position' => 0,
						'is_hidden' => 0
					}
		        },
				get_rel_lookup =>{
					'rId2' => 'Sheet5',
					'rId1' => 'Sheet2',
					'rId3' => 'Sheet1'
		        },
				get_id_lookup =>{
					'1' => 'Sheet1',
					'3' => 'Sheet5',
					'2' => 'Sheet2'
		        },
			};
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			#~ $extractor_instance = build_instance(
				#~ superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
				#~ package => 'ExtractorInstance',
				#~ file => $test_file,
			#~ ###LogSD	log_space	=> 'Test',
				#~ add_roles_in_sequence =>[ 
					#~ 'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
				#~ ],
			#~ );# exit 1;
			#~ $file_handle = $extractor_instance->extract_file( 'xl/workbook.xml' );
			$test_instance =  build_instance(
				superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
				package	=> 'WorkbookMetaInterface',
				add_roles_in_sequence =>[ 
					'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta',
					'Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface',
				],
				file => $test_file,
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