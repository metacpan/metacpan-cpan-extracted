#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles  8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $test_fil2 );
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

use	Test::Most tests => 23;
use	Test::Moose;
use IO::File;
use Data::Dumper;
use Types::Standard qw( ConsumerOf HasMethods Int );
use	Spreadsheet::Reader::Format;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance		should_re_use_classes	set_args_cloning
	);
should_re_use_classes( 1 );
set_args_cloning ( 0 );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'trace',
###LogSD								},
###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								XMLReader =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								StylesInterface =>{
#~ ###LogSD									_build_perl_node_from_xml_perl =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
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
#~ ###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::XMLReader;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles;
use	Spreadsheet::Reader::ExcelXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_fil2 = $test_file . 'table_styles.xml';
$test_file .= 'TestBook.xml';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$format_instance, $workbook_instance, $test_instance, $capture, $x, @answer, $file_handle, $coercion,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				cache_positions
			);
my  		@class_methods = qw(
				should_cache_positions		get_format			get_default_format
				load_unique_bits
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
}										"Prep a new Workbook dummy instance";
lives_ok{
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
}										"Prep a new Format instance";
lives_ok{
			$test_instance	=	build_instance(
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									package			=> 'ReaderInstance',
									file			=> $test_file,# $file_handle
									workbook_inst	=> $workbook_instance,
			###LogSD				log_space => 'Test',
								);
}										"Prep a new Extractor instance";
ok			$file_handle = $test_instance->extract_file( [qw( Styles )] ),
										"Pull the Styles file with headers";# exit 1;
			$file_handle->seek( 0, 0 );
###LogSD		if( 1 ){
###LogSD			$operator->add_name_space_bounds( {
#~ ###LogSD				Test =>{
#~ ###LogSD					load_unique_bits =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			} );
###LogSD		}
lives_ok{
			$test_instance	=	build_instance(
									package => 'NamedStyles',
									superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
									add_roles_in_sequence => [
										'Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles',
									],
									file => $file_handle,
									workbook_inst => $workbook_instance,
									cache_positions => 1,
			###LogSD				log_space => 'Test',
								);
			#~ $workbook_instance->set_styles_interface( $test_instance );
}										"Prep a new Styles instance - cache_positions => 1";
map{ 
has_attribute_ok
			$test_instance, $_,			"Check that NamedStyles has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
ok			$coercion = $format_instance->parse_excel_format_string( '[$-409]d-mmm-yy;@' ),#'(#,##0_);[Red](#,##0)'
										"Create a number conversion from an excel format string";
#~ explain									Dumper( $format_instance );
			my $answer = '12-Sep-05';
is			$coercion->assert_coerce( 37145 ), $answer, #coercecoerce
										"... and see if it returns: $answer";
###LogSD		if( 0 ){
###LogSD			$operator->add_name_space_bounds( {
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD			} );
###LogSD		}
is			$test_instance->get_format( 's17', 'cell_coercion' )->{cell_coercion}->display_name, 'DATESTRING_0',
										"Check that the excel number coercion at format named 's17' is named: DATESTRING_0";# exit 1;
is			$test_instance->get_default_format->{cell_fill}->{patternFill}->{patternType}, undef,
										"Check that the 'Default' format sub-value for fill is: undef";
###LogSD		if( 0 ){
###LogSD			$operator->add_name_space_bounds( {
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD			} );
###LogSD		}
is			$test_instance->get_format( 's22', 'cell_font' )->{cell_font}->{'ss:Size'}, 14,
										"Check that number format named 's22' has a font size set to: 14";# exit 1;
is			$test_instance->get_format( 's22', 'cell_font' )->{cell_font}->{'ss:FontName'}, 'Calibri',
										"Check that number format named 's22' has a font type set to: Calibri";
###LogSD		if( 1 ){
###LogSD			$operator->add_name_space_bounds( {
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD			} );
###LogSD		}
lives_ok{
			$test_instance	=	build_instance(
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									package			=> 'ReaderInstance',
									file			=> $test_file,# $file_handle
									workbook_inst	=> $workbook_instance,
			###LogSD				log_space => 'Test',
								);
}										"Prep a new Extractor instance";
ok			$file_handle = $test_instance->extract_file( [qw( Styles )] ),
										"Pull the Styles file with headers";# exit 1;
lives_ok{
			$test_instance		=	build_instance(
										package => 'NamedStyles',
										file => $file_handle,
										workbook_inst => $workbook_instance,
										cache_positions => 0,
				###LogSD				log_space	=> 'Test',
									);
}										"Prep a new Styles instance - without caching";
###LogSD		if( 1 ){
###LogSD			$operator->add_name_space_bounds( {
###LogSD				Test =>{
###LogSD					get_format =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					_transform_element =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					_build_cell_style_formats =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			} );
###LogSD		}
is			$test_instance->get_format( 's17', 'cell_coercion' )->{cell_coercion}->display_name, 'DATESTRING_0',
										"Check that the excel number coercion at format named 's17' is named: DATESTRING_0";# exit 1;
is			$test_instance->get_default_format->{cell_fill}->{patternFill}->{patternType}, undef,
										"Check that the 'Default' format sub-value for fill is: undef";
###LogSD		if( 0 ){
###LogSD			$operator->add_name_space_bounds( {
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD			} );
###LogSD		}
is			$test_instance->get_format( 's22', 'cell_font' )->{cell_font}->{'ss:Size'}, 14,
										"Check that number format named 's22' has a font size set to: 14";# exit 1;
is			$test_instance->get_format( 's22', 'cell_font' )->{cell_font}->{'ss:FontName'}, 'Calibri',
										"Check that number format named 's22' has a font type set to: Calibri";
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