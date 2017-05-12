#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader     7#########8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $test_fil2, $test_fil3, $next_line );
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

use	Test::Most tests => 106;
use	Test::Moose;
use IO::File;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HasMethods Int Str );
use	lib
		'../../../../../Log-Shiras/lib',
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
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
#~ use	Spreadsheet::Reader::ExcelXML::Workbook;# Required because the XMLReader will scrape the public methods
#~ use	Spreadsheet::Reader::ExcelXML::XMLReader;
use	Spreadsheet::Reader::ExcelXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_fil2 = $test_file . 'MySQL.xml';
$test_fil3 = $test_file . 'TestBook.xml';
$test_file .= 'xl/sharedStrings.xml';
my  ( 
			$class_instance, $test_instance, $workbook_instance, $capture, @answer, $error_instance, $file_handle,
	);
my 			@class_attributes = qw(
				file			workbook_inst		xml_version
				xml_encoding	xml_header			position_index
				file_type
			);
my  		@class_methods = qw(
				get_file						set_file						has_file
				clear_file						close							getline
				seek							set_workbook_inst				version
				encoding						has_encoding					get_header
				where_am_i						i_am_here						clear_location
				has_position					get_file_type					start_the_file_over
				parse_element					advance_element_position		next_sibling
				skip_siblings					squash_node						current_named_node
				extract_file					current_node_parsed				not_end_of_file
				collecting_merge_data
			);############# No checking for delegated workbook methods! -> must be certified in requires for roles    is_end_of_file					
my			$answer_ref = [
				{	
					'list' =>[ { 'raw_text' => 'Hello' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'World' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'my' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => ' ' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Category' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Total' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Date' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Red' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Blue' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Omaha' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Row Labels' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Grand Total' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Superbowl Audibles' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => 'Column Labels' } ],
					'list_keys' => [ 't', ]
		        },
				{	
					'list' => [ { 'raw_text' => '2/6/2011' } ],
					'list_keys' => [ 't', ]
		        },
				{
					'list_keys' => [ qw( r r r ) ],
					'list' => [
						{
							'list_keys' => [ 't' ],
							'list' => [
								{ 'raw_text' => 'He' }
							],
						},
						{
							'list_keys' => [ qw( rPr t ) ],
		                    'list' => [
		                        {
		                            'list_keys' => [ qw( b sz color rFont family scheme ) ],
		                            'list' => [
		                                undef,
										{ 'val' => '11' },
										{ 'attributes' => { 'rgb' => 'FFFF0000' } },
										{ 'val' => 'Calibri' },
										{ 'val' => '2' },
										{ 'val' => 'minor' }
									]
								},
								{ 'raw_text' => 'llo ' }
							],
						},
						{
		                    'list_keys' => [ qw( rPr t ) ],
							'list' => [
		                        {
		                            'list_keys' => [ qw( b sz color rFont family scheme ) ],
									'list' => [
		                                undef,
		                                { 'val' => '20' },
		                                { 'attributes' => { 'rgb' => 'FF0070C0' } },
										{ 'val' => 'Calibri' },
										{ 'val' => '2' },
										{ 'val' => 'minor' }
									]
								},
								{ 'raw_text' => 'World' }
							],
						}
					]
		        },
				'EOF',
				{
					'list' => [
						{
							't' => 'He',
						},
						{
							'rPr' => {
								'b' => undef,
								'color' => { 'rgb' => 'FFFF0000' },
								'family' => '2',
								'rFont' => 'Calibri',
								'scheme' => 'minor',
								'sz' => '11'
							},
							't' => 'llo ',
						},
						{
							'rPr' => {
								'b' => undef,
								'color' => { 'rgb' => 'FF0070C0' },
								'family' => '2',
								'rFont' => 'Calibri',
								'scheme' => 'minor',
								'sz' => '20'
							},
							't' => 'World',
						},
					]
				},
				{
					'list_keys' => [ qw( r r r ) ],
					'list' => [
						{
							'list_keys' => [ 't' ],
							'list' => [ undef ],
						},
						{
							'list_keys' => [ qw( rPr t ) ],
							'list' => [ undef, undef ],
						},
						{
							'list_keys' => [ qw( rPr t ) ],
							'list' => [ undef, undef ]
						}
					],
				},
				undef,
				[ 1, 20 ],
				[ 1, { rgb => 'FF0070C0' } ],
				[ 1, 'Calibri' ],
				[ 1, 2 ],
				[ 1, 'minor' ],
				[ '' ,{ 'raw_text' => 'World' } ],
				{ 'raw_text' => 'llo ' },
				[
					'<?xml version="1.0" encoding="UTF-8"?><Worksheet ss:Name="Table1">' .
						'<Table>' .
							'<Column ss:Index="1" ss:AutoFitWidth="0" ss:Width="110"/>' .
							'<Column ss:Index="3" ss:AutoFitWidth="0" ss:Width="110"/>' .
							'<Column ss:Index="4" ss:AutoFitWidth="0" ss:Width="110"/>' .
							'<Column ss:Index="6" ss:AutoFitWidth="0" ss:Width="110"/>' .
							'<Column ss:Index="7" ss:AutoFitWidth="0" ss:Width="110"/>' .
							'<Row>' .
								'<Cell><Data ss:Type="String">id</Data></Cell>' .
								'<Cell><Data ss:Type="String">count</Data></Cell>' .
								'<Cell><Data ss:Type="String">dataSize</Data></Cell>' .
								'<Cell><Data ss:Type="String">date</Data></Cell>' .
								'<Cell><Data ss:Type="String">organizationId</Data></Cell>' .
								'<Cell><Data ss:Type="String">region</Data></Cell>' .
								'<Cell><Data ss:Type="String">succeeded</Data></Cell>' .
								'<Cell><Data ss:Type="String">userId</Data></Cell>' .
								'<Cell><Data ss:Type="String">documentTaskType</Data></Cell>' .
								'<Cell><Data ss:Type="String">pageCount</Data></Cell>' .
							'</Row>' .
					'' .
							'<Row>' .
								'<Cell><Data ss:Type="String">136</Data></Cell>' .
								'<Cell><Data ss:Type="Number">13</Data></Cell>' .
								'<Cell><Data ss:Type="String">13107380</Data></Cell>' .
								'<Cell><Data ss:Type="String">2013-10-21</Data></Cell>' .
								'<Cell><Data ss:Type="Number">406</Data></Cell>' .
								'<Cell><Data ss:Type="String"></Data></Cell>' .
								'<Cell><Data ss:Type="String">1</Data></Cell>' .
								'<Cell><Data ss:Type="Number">468</Data></Cell>' .
								'<Cell><Data ss:Type="Number"></Data></Cell>' .
								'<Cell><Data ss:Type="Number">13</Data></Cell>' .
							'</Row>' .
							'<Row>' .
								'<Cell><Data ss:Type="String">137</Data></Cell>' .
								'<Cell><Data ss:Type="Number">11</Data></Cell>' .
								'<Cell><Data ss:Type="String">21668650</Data></Cell>' .
								'<Cell><Data ss:Type="String">2013-10-21</Data></Cell>' .
								'<Cell><Data ss:Type="Number">417</Data></Cell>' .
								'<Cell><Data ss:Type="String"></Data></Cell>' .
								'<Cell><Data ss:Type="String">1</Data></Cell>' .
								'<Cell><Data ss:Type="Number">479</Data></Cell>' .
								'<Cell><Data ss:Type="Number"></Data></Cell>' .
								'<Cell><Data ss:Type="Number">23</Data></Cell>' .
							'</Row>' .
							'<Row>' .
								'<Cell><Data ss:Type="String">138</Data></Cell>' .
								'<Cell><Data ss:Type="Number">6</Data></Cell>' .
								'<Cell><Data ss:Type="String">6088028</Data></Cell>' .
								'<Cell><Data ss:Type="String">2013-10-21</Data></Cell>' .
								'<Cell><Data ss:Type="Number">415</Data></Cell>' .
								'<Cell><Data ss:Type="String"></Data></Cell>' .
								'<Cell><Data ss:Type="String">1</Data></Cell>' .
								'<Cell><Data ss:Type="Number">477</Data></Cell>' .
								'<Cell><Data ss:Type="Number"></Data></Cell>' .
								'<Cell><Data ss:Type="Number">6</Data></Cell>' .
							'</Row>' .
						'</Table>' .
					'</Worksheet>'
				],
				[
					'<?xml version="1.0" encoding="UTF-8"?><Chartsheet/>',
				],	
				[
					qr/<\?xml version=\"1.0\"\?><Worksheet ss:Name=\"Sheet5\"><Table ss:ExpandedColumnCount=\"5\"/,
					qr/x:FullRows=\"1\" ss:DefaultRowHeight=\"15\"><Column ss:Width=\"100.5\"\/><Column ss:AutoFitWidth=\"0\"/,
				],
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
###LogSD	use Log::Shiras::Unhide qw( :debug );
require	Spreadsheet::Reader::ExcelXML::XMLReader;
			$test_instance	=	build_instance(
									superclasses	=>[ 'Spreadsheet::Reader::ExcelXML::XMLReader' ],
									package			=> 'ReaderInstance',
									file			=> $test_file,# $file_handle
									workbook_inst	=> $workbook_instance,
			###LogSD				log_space => 'Test',
								);
}										"Prep a new Reader instance";
			map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that ". ref( $test_instance ) . " has the -$_- attribute"
			} @class_attributes;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
			map{
can_ok		$test_instance, $_,
			} @class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			map{
			$test_instance->advance_element_position( 'si' );
			my $test_ref = $test_instance->parse_element;
#~ explain		$test_ref;
is_deeply	$test_ref, $answer_ref->[$_], 
										"Test matching 'si' position: $_";
			}( 0..16);#10
#~ exit 1;
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
			map{
			$test_instance->advance_element_position( 'si' );
			my $test_ref = $test_instance->parse_element;
#~ explain		$test_ref;
is_deeply	$test_ref, $answer_ref->[$_], 
										"Test matching 'si' position: $_";
			}( 0..16);
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
is(			($test_instance->advance_element_position( 'si', 16 ))[0], 1,
										"Advance to the 16th 'si' position");# exit 1;
			my $test_ref = $test_instance->parse_element;
#~ explain		$test_ref;# exit 1;
is_deeply	$test_ref, $answer_ref->[15], 
										"Test matching 'si' position: 15 (from zero)";
###LogSD		if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				XMLReader =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
			$test_ref = $test_instance->squash_node( $test_ref );
#~ explain		$test_ref; exit 1;
is_deeply	$test_ref, $answer_ref->[17], 
										"Check for the correct result after 'squash_node'";
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
ok(			($test_instance->advance_element_position( 'si', 16 ))[0],
										"Advance to the 16th 'si' position");
			$test_ref = $test_instance->parse_element( 2 );
#~ explain		$test_ref; exit 1;
is_deeply	$test_ref, $answer_ref->[18], 
										"Test matching 'si' position -15- (from zero) to a depth of: 2";
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
###LogSD		if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				XMLReader =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
ok(			($test_instance->advance_element_position( 'b', 2 ))[0],
										"Advance to the 2nd 'b' position");# exit 1;
			$test_ref = $test_instance->parse_element;
explain		$test_ref;# exit 1;
is_deeply	$test_ref, $answer_ref->[19], 
										"Test matching the results of the second 'b' node";# exit 1;
			map{
is(			($test_instance->next_sibling)[0], $answer_ref->[19 + $_]->[0],
										"Advance to the next_sibling iteration -$_- with result: $answer_ref->[19 + $_]->[0]");
			$test_ref = $test_instance->parse_element;
#~ explain		$test_ref;
			$test_ref = $test_instance->squash_node( $test_ref );
#~ explain		$test_ref;
is_deeply	$test_ref, $answer_ref->[19 + $_]->[1], 
										"Test matching the results of sibling position -$_- after the second 'b' node";
			}(1..6);# exit 1;
ok			$test_instance->start_the_file_over,
										'Test re-starting the file';
ok(			($test_instance->advance_element_position( 'b' ))[0],
										"Advance to the 1st 'b' position");
ok(			($test_instance->skip_siblings)[0],
										"skip the remaining siblings");
			$test_ref = $test_instance->parse_element;
#~ explain		$test_ref; exit 1;
			$test_ref = $test_instance->squash_node( $test_ref );
#~ explain		$test_ref;
is_deeply	$test_ref, $answer_ref->[26], 
										"Test matching the first node past the 'b' node siblings";
###LogSD		if( 0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				XMLReader =>{
###LogSD					extract_file =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					advance_element_position =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					current_node_parsed =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
#~ ###LogSD					current_named_node =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					_build_out_the_return =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
ok			$test_instance->set_file( $test_fil2 ),
										"Change the file to: $test_fil2";
			my $test = 27;
			my $x = 0;
ok			$file_handle = $test_instance->extract_file( [qw( Worksheet )] ),
										"Pull the Worksheet file with headers";# exit 1;
			$file_handle->seek( 0, 0 );
			for my $y (1..scalar(@{$answer_ref->[$test]}) ){
				$next_line = <$file_handle>;
				chomp $next_line;
is				$next_line, $answer_ref->[$test]->[$x++],
											"Check Worksheet file row against answer position: $x";
			}
			$test++;
			$x = 0;
ok			$file_handle = $test_instance->extract_file( [qw( Chartsheet )] ),
										"Attempt to build a Chartsheet file with headers";
			for my $y (1..scalar(@{$answer_ref->[$test]}) ){
				$next_line = <$file_handle>;
				chomp $next_line;
				#~ print "$next_line\n";
is				$next_line, $answer_ref->[$test]->[$x++],
											"Check Worksheet file row against answer position: $x";
			}
			$x = 0;
ok			$test_instance->set_file( $test_fil3 ),
										"Change the base file for extracting";
###LogSD		if( 1 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				XMLReader =>{
###LogSD					extract_file =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					advance_element_position =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
#~ ###LogSD					_build_out_the_return =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		}
ok			$file_handle = $test_instance->extract_file( [ 'Worksheet', 'Sheet5' ], ),
										"Extract a named (Sheet5) Worksheet file with headers";
			$test++;
			for my $y (1..scalar(@{$answer_ref->[$test]}) ){
				$next_line = <$file_handle>;
				chomp $next_line;
				#~ print "$next_line\n";
like			$next_line, $answer_ref->[$test]->[$x++],
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