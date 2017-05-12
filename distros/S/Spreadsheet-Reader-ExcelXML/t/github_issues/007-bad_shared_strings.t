#########1 Test File for github issue #7 #########5#########6#########7#########8#########9
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
		$lib		= '../../' . $lib;
		$test_file	= '../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 16;
use	Test::Moose;
use Data::Dumper;
use Types::Standard qw( HasMethods Int Str Enum );
use File::Temp qw/ tempfile /;
use	lib
		'../../../Log-Shiras/lib',
		'../../../MooseX-ShortCut-BuildInstance/lib',
		$lib,
	;
use	MooseX::ShortCut::BuildInstance v1.36.8 qw( build_instance should_re_use_classes );
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
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
use	Spreadsheet::Reader::ExcelXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'bad_sharedStrings.xml';
my  ( 
			$workbook_instance, $test_instance, $file_handle, $next_line, $capture,
	);
my			$fh = tempfile();
my 			$row = 0;
my 			@class_attributes = qw(
				file						cache_positions
			);
my  		@instance_methods = qw(
				should_cache_positions		get_shared_string			loaded_correctly
			);
my			$answer_ref = [
				388811,
				'UTF-8',
				{ report => { SYSTEM => 'http://sales.acme.corp/dtds/salesrep.dtd' }},
				[ 0, { 	
					raw_text => 'Americas',
				} ],
				[ 1, { 	
					raw_text => '????? Some Nonsense ?????',
				} ],
				[ 2, { 	
					raw_text => 'Direct',
				} ],
			];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			#~ $workbook_instance = Spreadsheet::Reader::ExcelXML::Workbook->new;
			$workbook_instance = build_instance(
										package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
										add_attributes =>{
											error_inst =>{
												isa => 	HasMethods[qw(
																	error set_error clear_error set_warnings if_warn
																) ],
												clearer		=> '_clear_error_inst',
												reader		=> 'get_error_inst',
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
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			#~ print $workbook_instance->get_group_return_type; exit 1;
			$test_instance	=	build_instance(
									package => 'PositionSharedStrings',
									file	=> $test_file,
									workbook_inst	=> $workbook_instance,
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									add_roles_in_sequence =>[
										'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
									],
			###LogSD				log_space	=> 'Test',
								);
}										"Prep a new ~::XMLReader::PositionSharedStrings instance";
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;

map{
can_ok		$test_instance, $_,
} 			@instance_methods;
###LogSD		if( 0 ){
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
is			$test_instance->_get_unique_count, $answer_ref->[$answer_row++],
										"Check for correct unique_count";
is			$test_instance->encoding, $answer_ref->[$answer_row++],
										"Check for correct encoding";
is_deeply	$test_instance->doctype, $answer_ref->[$answer_row],
										"Check for the doctype: " . Dumper( $answer_ref->[$answer_row++] ) ;
###LogSD	my $trigger = 4;
			for my $x ( 3..5 ){
###LogSD	print "-----------$x---------\n";
###LogSD	if( $x == $trigger ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD	elsif( $x > $trigger + 1 ){
###LogSD		exit 1;
###LogSD	}
			#~ print "position -$answer_ref->[$x]->[0]- " .Dumper( $test_instance->get_shared_string( $answer_ref->[$x]->[0] ) );
is_deeply	$test_instance->get_shared_string( $answer_ref->[$x]->[0] ), $answer_ref->[$x]->[1],
										"Get the sharedStrings 'si' position -$answer_ref->[$x]->[0]- as:" . Dumper( $answer_ref->[$x]->[1] );
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