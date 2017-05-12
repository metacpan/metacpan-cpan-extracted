#########1 Test File for Spreadsheet::XLSX::Reader::LibXML::XMLReader::XMLToPerlData #####9
#!/usr/bin/env perl
my ( $lib, $test_file, $test_fil2, $test_fil3 );
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
}
$| = 1;

use	Test::Most tests => 23;
use	Test::Moose;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HasMethods Int );
use	Data::Dumper;
use	lib
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	use Data::Dumper;
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
use	Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
use	Spreadsheet::XLSX::Reader::LibXML::XMLReader;
use	Spreadsheet::XLSX::Reader::LibXML::Error;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_fil2 = $test_file . 'xl/worksheets/sheet3_test.xml';
$test_fil3 = $test_file . 'MySQL.xml';
$test_file .= 'xl/sharedStrings.xml';
#~ print "$lib\n$test_file\n$test_fil2\n";
my  ( 
			$test_instance, $capture, @answer, $workbook_instance,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				file						workbook_inst			exclude_match
				strip_keys
			);
my  		@instance_methods = qw(
				set_exclude_match			set_strip_keys			parse_element
				grep_node					squash_node
			);
my			$answer_ref = [
				{
					'list_keys' => [ 'r', 'r', 'r' ],
					'list' => [
						{
		                    'list_keys' => [ 't' ],
							'list' => [
								{
									'raw_text' => 'He'
								}
							]
						},
						{
							'list_keys' => [ 'rPr', 't' ],
							'list' => [
								{
									'list_keys' => [ 'b', 'sz', 'color', 'rFont', 'family', 'scheme' ],
									'list' => [
										undef,
		                                {
		                                    'attributes' => '11'
		                                },
		                                {
		                                    'attributes' => {
		                                        'rgb' => 'FFFF0000'
		                                    }
		                                },
		                                {
		                                    'attributes' => 'Calibri'
		                                },
		                                {
		                                    'attributes' => '2'
		                                },
										{
		                                    'attributes' => 'minor'
		                                }
									],
								},
								{	
									'xml:space' => 'preserve',
									'raw_text' => 'llo '
								}
							],
						},
						{
							'list_keys' => [ 'rPr', 't' ],
							'list' => [
								{
									'list_keys' => [ 'b', 'sz', 'color', 'rFont', 'family', 'scheme' ],
									'list' => [
										undef,
		                                {
		                                    'attributes' => '20'
		                                },
		                                {
		                                    'attributes' => {
		                                        'rgb' => 'FF0070C0'
		                                    }
		                                },
		                                {
		                                    'attributes' => 'Calibri'
		                                },
		                                {
		                                    'attributes' => '2'
		                                },
										{
		                                    'attributes' => 'minor'
		                                }
									],
								},
								{
									'raw_text' => 'World'
								}
							],
						}
					]
		        },
				{
					'attributes' => {
						's' => '8',
						'r' => 'A11'
					},
					'list_keys' => [ 'v' ],
					'list' => [
						{
							'raw_text' => '1'
						}
					]
		        },
				{
					'attributes' => {
						'r' => 'B12'
					},
					'list_keys' =>[ 'v' ],
					'list' =>[ undef ],
		        },
				{
					'attributes' => {
						'xmlns:x' => 'urn:schemas-microsoft-com:office:excel',
						'xmlns:ss' => 'urn:schemas-microsoft-com:office:spreadsheet',
						'xmlns:o' => 'urn:schemas-microsoft-com:office:office',
						'xmlns' => 'urn:schemas-microsoft-com:office:spreadsheet',
						'xmlns:html' => 'http://www.w3.org/TR/REC-html40',
					},
					'list_keys' =>[ 'Worksheet' ],
					'list' =>[
						{
							'attributes' =>{ 'ss:Name' => 'Table1', },
						}
					],
				}
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
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
			$test_instance	=	build_instance(
									package => 'TestIntance',
									superclasses =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader', ],
									add_roles_in_sequence =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData', ],
									file	=> $test_file,
									workbook_inst => $workbook_instance,
			###LogSD				log_space	=> 'Test',
								);
}										"Prep a new TestIntance to test XMLToPerlData";
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that the " . ref( $test_instance ) . " has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@instance_methods;

###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			my $x = 0;
explain		"index to position 15";
ok			$test_instance->start_the_file_over,
										"reset the file";
			my $target = 16;
ok			$test_instance->advance_element_position( 'si', $target ),
										"index to position: " . ($target - 1);
is_deeply	$test_instance->parse_element, $answer_ref->[$x],
										"Check that the output matches expectations";
ok			$test_instance->start_the_file_over,
										"Start the file over";
explain		"index to position 15 - again";
			map{ $test_instance->advance_element_position( 'si' ) }( 0..15 );
is_deeply	$test_instance->parse_element, $answer_ref->[$x++],
										"..and check the output..again";
lives_ok{
			$test_instance	=	TestIntance->new(
									file => $test_fil2,
									workbook_inst => $workbook_instance,,
			###LogSD				log_space	=> 'Test',
								);
}										"Prep another TestIntance to test: $test_fil2";
explain		"Index to position 12";
			map{ $test_instance->advance_element_position( 'c' ) }( 0..12 );
is_deeply	$test_instance->parse_element, $answer_ref->[$x++],
										"Check that the next output matches expectations.";
ok			$test_instance->advance_element_position( 'c' ),
										"Advance to the next cell";
is_deeply	$test_instance->parse_element, $answer_ref->[$x++],
										"Check that the next output matches expectations.";
lives_ok{
			$test_instance	=	TestIntance->new(
									file => $test_fil3,
									workbook_inst => $workbook_instance,
			###LogSD				log_space	=> 'Test',
								);
}										"Prep another TestIntance to test: $test_fil3";
ok			$test_instance->advance_element_position( 'Workbook' ),
										"Correctly find the Workbook node";
ok			$test_instance->set_exclude_match( '(Table)' ),
										"Exclude 'Table' nodes from collection";
###LogSD	$operator->add_name_space_bounds( {# Move this whole block around as needed
###LogSD			Test =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD			},
###LogSD	}, );
###LogSD	explain		$test_instance->parse_element( 2 ); exit 1;#
#~ explain		$test_instance->parse_element( 2 ), $answer_ref->[$x++]; exit 1;
is_deeply	$test_instance->parse_element( 2 ), $answer_ref->[$x++],
										"And pull two levels to see what is returned";
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