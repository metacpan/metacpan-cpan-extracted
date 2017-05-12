#########1 Test File for Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile8#########9
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
		$lib		= '../../../../../../' . $lib;
		$test_file	= '../../../../../test_files/';
	}
}
$| = 1;

use	Test::Most tests => 50;
use	Test::Moose;
use IO::File;
use XML::LibXML::Reader;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HasMethods Int Str );
use File::Temp qw/ tempfile /;
use	lib
		'../../../../../../../Log-Shiras/lib',
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
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML::XMLReader;
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
use	Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile;
use	Spreadsheet::XLSX::Reader::LibXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'MySQL.xml';
my  ( 
			$workbook_instance, $test_instance, $file_handle, $next_line,
	);
my			$fh = tempfile();
my 			$row = 0;
my 			@class_attributes = qw(
				file
			);
my  		@instance_methods = qw(
				extract_file
			);
				#~ '<?xml version="1.0" encoding="UTF-8"?>',
my			$answer_ref = [
				[
					'<?xml version="1.0" encoding="UTF-8"?><Worksheet xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" ss:Name="Table1">',
					'	<Table>',
					'		<Column ss:Index="1" ss:AutoFitWidth="0" ss:Width="110"/>',
					'		<Column ss:Index="3" ss:AutoFitWidth="0" ss:Width="110"/>',
					'		<Column ss:Index="4" ss:AutoFitWidth="0" ss:Width="110"/>',
					'		<Column ss:Index="6" ss:AutoFitWidth="0" ss:Width="110"/>',
					'		<Column ss:Index="7" ss:AutoFitWidth="0" ss:Width="110"/>',
					'		<Row>',
					'			<Cell><Data ss:Type="String">id</Data></Cell>',
					'			<Cell><Data ss:Type="String">count</Data></Cell>',
					'			<Cell><Data ss:Type="String">dataSize</Data></Cell>',
					'			<Cell><Data ss:Type="String">date</Data></Cell>',
					'			<Cell><Data ss:Type="String">organizationId</Data></Cell>',
					'			<Cell><Data ss:Type="String">region</Data></Cell>',
					'			<Cell><Data ss:Type="String">succeeded</Data></Cell>',
					'			<Cell><Data ss:Type="String">userId</Data></Cell>',
					'			<Cell><Data ss:Type="String">documentTaskType</Data></Cell>',
					'			<Cell><Data ss:Type="String">pageCount</Data></Cell>',
					'		</Row>',
					'',
					'		<Row>',
					'			<Cell><Data ss:Type="String">136</Data></Cell>',
					'			<Cell><Data ss:Type="Number">13</Data></Cell>',
					'			<Cell><Data ss:Type="String">13107380</Data></Cell>',
					'			<Cell><Data ss:Type="String">2013-10-21</Data></Cell>',
					'			<Cell><Data ss:Type="Number">406</Data></Cell>',
					'			<Cell><Data ss:Type="String"/></Cell>',
					'			<Cell><Data ss:Type="String">1</Data></Cell>',
					'			<Cell><Data ss:Type="Number">468</Data></Cell>',
					'			<Cell><Data ss:Type="Number"/></Cell>',
					'			<Cell><Data ss:Type="Number">13</Data></Cell>',
					'		</Row>',
					'		<Row>',
					'			<Cell><Data ss:Type="String">137</Data></Cell>',
					'			<Cell><Data ss:Type="Number">11</Data></Cell>',
					'			<Cell><Data ss:Type="String">21668650</Data></Cell>',
					'			<Cell><Data ss:Type="String">2013-10-21</Data></Cell>',
					'			<Cell><Data ss:Type="Number">417</Data></Cell>',
					'			<Cell><Data ss:Type="String"/></Cell>',
					'			<Cell><Data ss:Type="String">1</Data></Cell>',
					'			<Cell><Data ss:Type="Number">479</Data></Cell>',
					'			<Cell><Data ss:Type="Number"/></Cell>',
					'			<Cell><Data ss:Type="Number">23</Data></Cell>',
					'		</Row>',
				],
				[
					'<?xml version="1.0" encoding="UTF-8"?><Chartsheet/>',
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
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			$test_instance	=	build_instance(
									package => 'XMLWorkbookFile',
									file	=> $test_file,
									workbook_inst	=> $workbook_instance,
									superclasses	=>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader' ],
									add_roles_in_sequence =>[
										'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData',
										'Spreadsheet::XLSX::Reader::LibXML::XMLReader::ExtractFile',
									],
			###LogSD				log_space	=> 'Test',
								);
}										"Prep a new ~::XMLReader::ExtractFile instance";
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;

map{
can_ok		$test_instance, $_,
} 			@instance_methods;

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			my $test = 0;
			my $x = 0;
ok			$file_handle = $test_instance->extract_file( [qw( Worksheet )] ),
										"Pull the Worksheet file with headers";
			$file_handle->seek( 0, 0 );
			for my $y (1..scalar(@{$answer_ref->[$test]}) ){
				$next_line = <$file_handle>;
				chomp $next_line;
is				$next_line, $answer_ref->[$test]->[$x++],
											"Check Worksheet file row against answer position: $x";
				#~ print "$next_line\n";
			}
			$test++;
			$x = 0;
ok			$file_handle = $test_instance->extract_file( [qw( Chartsheet )] ),
										"Attempt to build a Chartsheet file with headers";
			$file_handle->seek( 0, 0 );
			for my $y (1..scalar(@{$answer_ref->[$test]}) ){
				$next_line = <$file_handle>;
				chomp $next_line;
				#~ print "$next_line\n";
is				$next_line, $answer_ref->[$test]->[$x++],
											"Check Worksheet file row against answer position: $x";
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