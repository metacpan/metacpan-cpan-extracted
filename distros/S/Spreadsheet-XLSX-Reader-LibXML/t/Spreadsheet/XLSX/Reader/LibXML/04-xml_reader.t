#########1 Test File for Spreadsheet::XLSX::Reader::LibXML::XMLReader 7#########8#########9
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
}
$| = 1;

use	Test::Most tests => 75;
use	Test::Moose;
use IO::File;
#~ use XML::LibXML::Reader;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HasMethods Int Str );
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'info',
###LogSD							},
###LogSD							Test =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'debug',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
use	Spreadsheet::XLSX::Reader::LibXML::XMLReader;
use	Spreadsheet::XLSX::Reader::LibXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'sharedStrings.xml';
my  ( 
			$class_instance, $test_instance, $workbook_instance, $capture, @answer, $error_instance, $file_handle,
	);
my 			@class_attributes = qw(
				file			workbook_inst		xml_version
				xml_encoding	xml_header			position_index
				file_type
			);
my  		@class_methods = qw(
				get_file					set_file						has_file
				clear_file					close							set_error
				get_empty_return_type		_get_workbook_file_type			_get_sheet_info
				_get_rel_info				get_sheet_names					get_defined_conversion
				set_defined_excel_formats	has_shared_strings_interface	get_shared_string
				get_values_only				is_empty_the_end				_starts_at_the_edge
				get_group_return_type		change_output_encoding			counting_from_zero
				get_error_inst				boundary_flag_setting			has_styles_interface
				get_format					set_workbook_inst				version
				encoding					has_encoding					get_header
				where_am_i					i_am_here						clear_location
				has_position				get_file_type					skip_siblings
				next_sibling				get_node_all					get_default_format
			);
				#~ where_am_i
				#~ has_position
my			$answer_ref = [
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Hello</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>World</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>my</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t xml:space="preserve"> </t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Category</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Total</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Date</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Red</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Blue</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Omaha</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Row Labels</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Grand Total</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Superbowl Audibles</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Column Labels</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>2/6/2011</t></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><r><t>He</t></r><r><rPr><b/><sz val="11"/><color rgb="FFFF0000"/><rFont val="Calibri"/><family val="2"/><scheme val="minor"/></rPr><t xml:space="preserve">llo </t></r><r><rPr><b/><sz val="20"/><color rgb="FF0070C0"/><rFont val="Calibri"/><family val="2"/><scheme val="minor"/></rPr><t>World</t></r></si>',
				],
				[
					'<si xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><t>Red</t></si>',
				],
			];

###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$workbook_instance = build_instance(
										package	=> 'Spreadsheet::XLSX::Reader::LibXML',
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
												default => sub{ Spreadsheet::XLSX::Reader::LibXML::Error->new() },
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
												isa => 'SharedStrings',
												predicate => 'has_shared_strings_interface',
												writer => 'set_shared_strings_interface',
												handles =>{
													'get_shared_string_position' => 'get_shared_string_position',
													'start_the_ss_file_over' => 'start_the_file_over',
												},
												weak_ref => 1,
											}
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			$test_instance	=	build_instance(
									superclasses =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader' ],
									package		 => 'ReaderInstance',
									file => $test_file,# $file_handle
									workbook_inst => $workbook_instance,
			###LogSD				log_space => 'Test',
								);
}										"Prep a new Reader instance";
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that ". ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
map{
			$test_instance->advance_element_position( 'si' );
			my ( $x, $row ) = ( 0, $_ );
			@answer = split "\n", $test_instance->get_node_all;
map{
is			$_, $answer_ref->[$row]->[$x],
										'Test matching line -' . (1 + $x++) . "- of 'si' position: $row";
}			@answer;
}( 0..10);
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
my 			$row = 0;
while( 	$test_instance->advance_element_position( 'si' ) ){#$capture = 
			my $x = 0;
			@answer = split "\n", $test_instance->get_node_all;
map{
is			$_, $answer_ref->[$row]->[$x],
										'Test matching line -' . (1 + $x++) . "- of 'si' position: $row";
}			@answer;
			$row++;
}
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