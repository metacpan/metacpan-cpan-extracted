#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::SharedStrings #####9
#!/usr/bin/env perl
my ( $lib, $test_file );
BEGIN{
	#~ $SIG{__DIE__} = sub { require Carp; Carp::confess(@_) };
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

use	Test::Most tests => 16;
use	Test::Moose;
use IO::File;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance 1.040 qw(
		build_instance		should_re_use_classes	set_args_cloning
	);
should_re_use_classes( 1 );
set_args_cloning ( 0 );
use Types::Standard qw( ConsumerOf HasMethods Int Str );
use	lib
		'../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
#~ ###LogSD							Test =>{
#~ ###LogSD								SharedStrings =>{
#~ ###LogSD									parse_element =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'trace',
###LogSD										},
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
use	Spreadsheet::Reader::ExcelXML::XMLReader;
use	Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
use	Spreadsheet::Reader::ExcelXML::SharedStrings;
use Spreadsheet::Reader::ExcelXML::Error;

$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'emptySharedStringsBug.xml';
my  ( 
			$test_instance, $workbook_instance, $capture, $x, @answer, $error_instance, $file_handle,
	);
my			$answer_ref = [
				327,
				'utf-8',
				[ 0, undef ],
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
												isa => ConsumerOf[ 'Spreadsheet::Reader::ExcelXML::SharedStrings' ],
												predicate => 'has_shared_strings_interface',
												writer => 'set_shared_strings_interface',
												handles =>{
													'get_shared_string' => 'get_shared_string',
													'start_the_ss_file_over' => 'start_the_file_over',
												},
											}
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			$test_instance	=	build_instance(
									package => 'SharedStrings',
									superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
									add_roles_in_sequence => [
										'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
										'Spreadsheet::Reader::ExcelXML::SharedStrings',
									],
			###LogSD				log_space	=> 'Test',
									file		=> $test_file,
									workbook_inst	=> $workbook_instance,
								);
}										"Prep a new SharedStrings instance";

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			my	$answer_row = 0;
is			$test_instance->_get_unique_count, $answer_ref->[$answer_row++],
										"Check for correct unique_count";
is			$test_instance->encoding, $answer_ref->[$answer_row++],
										"Check for correct encoding";
			for my $x ( 2..$#$answer_ref ){
is_deeply	$test_instance->get_shared_string( $answer_ref->[$x]->[0] ), $answer_ref->[$x]->[1],
										"Get the -$answer_ref->[$x]->[0]- sharedStrings 'si' position as:" . Dumper( $answer_ref->[$x]->[1] );# exit 1;
			}
lives_ok{	$capture = $test_instance->get_shared_string( 20 ); 
}										"Attempt an element past the end of the list";
is		$capture, undef,				'Make sure it returns undef';
lives_ok{	$capture = $test_instance->get_shared_string( 16 ); 
}										"Attempt a different element past the end of the list";
is		$capture, undef,				'Make sure it returns undef';
###LogSD		$phone->talk( level => 'info', message => [ "Turn caching off" ] );
lives_ok{
			$test_instance	=	SharedStrings->new(
									file			=> $test_file,
									cache_positions	=> 0,
									workbook_inst	=> $workbook_instance,
			###LogSD				log_space	=> 'Test',
								);
}										"Prep a new SharedStrings instance";

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			$answer_row = 0;
is			$test_instance->_get_unique_count, $answer_ref->[$answer_row++],
										"Check for correct unique_count";
is			$test_instance->encoding, $answer_ref->[$answer_row++],
										"Check for correct encoding";
			for my $x ( 2..$#$answer_ref ){
is_deeply	$test_instance->get_shared_string( $answer_ref->[$x]->[0] ), $answer_ref->[$x]->[1],
										"Get the -$answer_ref->[$x]->[0]- sharedStrings 'si' position as:" . Dumper( $answer_ref->[$x]->[1] );
			}
lives_ok{	$capture = $test_instance->get_shared_string( 20 ); 
}										"Attempt an element past the end of the list";
is		$capture, undef,				'Make sure it returns undef';
lives_ok{	$capture = $test_instance->get_shared_string( 16 ); 
}										"Attempt a different element past the end of the list";
is		$capture, undef,				'Make sure it returns undef';
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