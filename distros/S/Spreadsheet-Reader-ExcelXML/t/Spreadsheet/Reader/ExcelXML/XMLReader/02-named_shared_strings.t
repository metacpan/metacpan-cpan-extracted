#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings #9
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

use	Test::Most tests => 11;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HasMethods Int Str );
#~ use File::Temp qw/ tempfile /;
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
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
use	Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings;
use	Spreadsheet::Reader::ExcelXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'MySQL.xml';
my  ( 
			$workbook_instance, $test_instance, $file_handle, $next_line, $capture,
	);
#~ my			$fh = tempfile();
#~ my 			$row = 0;
my 			@class_attributes = qw(
				file						cache_positions
			);
my  		@instance_methods = qw(
				should_cache_positions		get_shared_string			load_unique_bits
			);
my			$answer_ref = [
				'UTF-8',
				qr/Please post an example of this file to: https:\/\/github.com\/jandrew\/p5-spreadsheet/,
			];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
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
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									package			=> 'ExtractorInstance',
									file			=> $test_file,# $file_handle
									workbook_inst	=> $workbook_instance,
			###LogSD				log_space => 'Test::Extractor',
								);
}										"Prep a new Reader instance";
ok			$file_handle = $test_instance->extract_file( [qw( SharedStrings )] ),
										"Build an (empty) SharedStrings file";
lives_ok{
			$test_instance	=	build_instance(
									package => 'NamedSharedStrings',
									file	=> $file_handle,
									workbook_inst	=> $workbook_instance,
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									add_roles_in_sequence =>[
										'Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings',
									],
			###LogSD				log_space	=> 'Test',
								);
}										"Prep a new ~::XMLReader::NamedSharedStrings instance";
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;

map{
can_ok		$test_instance, $_,
} 			@instance_methods;
###LogSD		if( 1 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				get_shared_string =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			my	$answer_row = 0;
is			$test_instance->encoding, $answer_ref->[$answer_row++],
										"Check for correct encoding";
dies_ok{		$test_instance->get_shared_string( 'some_name' ) }
										"Get the sharedStrings position named 'some_name' position - should die!";
like			$@, $answer_ref->[$answer_row++],
										".. and check for the correct message on death";
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