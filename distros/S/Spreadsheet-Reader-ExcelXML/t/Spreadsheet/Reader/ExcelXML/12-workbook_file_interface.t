#########1 Test File for Spreadsheet::Reader::ExcelXML::WorkbookFileInterface 8#########9
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

use	Test::Most tests => 32;
use	Test::Moose;
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );#
use	lib
		'../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
#~ ###LogSD							Test =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD								SharedStringsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								StylesInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								ExcelFormatInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
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
use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::ZipReader;
	$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
my	$xml_file = $test_file;
	$xml_file .= 'TestBook.xml';
	$test_file .= 'TestBook.xlsx';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  (
			$test_instance, $error_instance, $styles_instance, $shared_strings_instance,
			$string_type, $date_time_type, $cell, $row_ref, $offset, $workbook_instance,
			$file_handle, $styles_handle, $shared_strings_handle, $format_instance,
			$extractor_instance
	);
my 			$row = 0;
my 			@class_attributes = qw(
				file					file_type				workbook_inst
			);
my  		@class_methods = qw(
				get_file				set_file				has_file
				clear_file				get_file_type			set_workbook_inst
				extract_file			loaded_correctly
			);
my			$answer_list =[
			];
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
								package => 'ZipWorkbookFileInterface',
								file => $test_file,
			###LogSD			log_space	=> 'Test',
								add_roles_in_sequence =>[
									'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
								],
			);# exit 1;
}										"Prep a Zip based WorkbookFileInterface instance";# exit 1;
map{
has_attribute_ok
			$test_instance, $_,
										"Check that the WorkbookFileInterface instance has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'trace', message => [ 'Test instance:', $test_instance ] );
is			$test_instance->get_file_type, 'zip',
										"Check that the type is: zip";# exit 1;
ok			$file_handle = $test_instance->extract_file( 'xl/workbook.xml' ),
										"Extract the Meta file from the workbook zip package";
like		$file_handle->getline, qr/encoding="UTF-8"/,
										"Pull the first line to make sure you have the right file";
like		$file_handle->getline, qr/xmlns:r="http:\/\/schemas.openxmlformats.org\/officeDocument\/2006\/relationships"/,
										"Pull the second line to make sure you have the right file";
lives_ok{
			$test_instance = build_instance(
								superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
								package => 'XMLWorkbookFileInterface',
								file => $xml_file,
			###LogSD			log_space	=> 'Test',
								add_roles_in_sequence =>[
									'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
								],
			);# exit 1;
}										"Prep an XML based WorkbookFileInterface instance";# exit 1;
ok			$test_instance,				"Ensure there is a test instance ready";
map{
has_attribute_ok
			$test_instance, $_,
										"Check that the WorkbookFileInterface instance has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'trace', message => [ 'Test instance:', $test_instance ] );
is			$test_instance->get_file_type, 'xml',
										"Check that the type is: xml";# exit 1;
ok			$file_handle = $test_instance->extract_file( [qw( Workbook )] ),
										"Extract the Meta file from the workbook xml file";
like		$file_handle->getline, qr/<\?xml version="1.0"\?><Workbook\/>/,
										"Pull the first line to make sure you have the right file";
###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
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
