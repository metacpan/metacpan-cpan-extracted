#########1 Test File for Spreadsheet::Reader::ExcelXML  6#########7#########8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $bad_file );
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
		$lib		= '../../../' . $lib;
		$test_file	= '../../test_files/'
	}
	#~ use Carp 'longmess';
	#~ $SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 76;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../Log-Shiras/lib',
		$lib,
	;
use MooseX::ShortCut::BuildInstance;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#5
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
#~ ###LogSD						name_space_bounds =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'trace',
#~ ###LogSD							},
#~ ###LogSD							build_instance =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'warn',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							build_class =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'warn',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD									_hidden =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									WorksheetToRow =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										advance_element_position =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										location_status =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										get_attribute_hash_ref =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								Workbook =>{
#~ ###LogSD									worksheet =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_hidden =>{
#~ ###LogSD										_build_file_interface =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookFileInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookMetaInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookRelsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookPropsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								StylesInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								SharedStringsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								ExcelFormatInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$bad_file = $test_file . 'xls_test.xml';
#~ $test_file .= 'TestBook.xml';
$test_file .= 'TestBook.xml';
my  ( 
		$error_instance, $parser, $workbook, $row_ref,
	);
my	$answer_ref = [
		0,
		[qw( Category Total Date )],
		[qw( Red 5 2017-02-14 )],
		[qw( Blue 7 2017-02-14 )],
		[qw( Omaha 2 2018-02-03 )],
		[qw( Red 3 2018-02-03 )],
		[qw( Red 30 2016-02-06 )],
		[qw( Blue 10 2016-02-06 )],
		'EOF',
		1,
		[ 'Superbowl Audibles', 'Column Labels' ],
		[ 'Row Labels', '2016-02-06', '2017-02-14', '2018-02-03', 'Grand Total' ],
		[ 'Blue', 10, 7, undef, 17 ,],
		[ 'Omaha', undef, undef, 2, 2, ],
		[ 'Red', 30, 5, 3, 38, ],
		[ 'Grand Total', 40, 12, 5, 57, ],
		'EOF',
		0,
		[],
		['Hello',undef,undef,'my'],
		[],
		[undef,undef,'World'],
		[],
		['Hello World'],
		[undef,'69'],
		[undef,'27',undef,undef,'12-Sep-05'],
		[undef,'42'],
		[undef,undef,undef,' ','2/6/2011','6-Feb-11',],
		['2.13'],
		[undef,undef,undef,'6-Feb-11'],
		[],
		[undef,undef,' ','39118','6-Feb-11'],
		'EOF',
	];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "start testing ..." ] );
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
							count_from_zero		=> 0,
							group_return_type	=> 'value',
							empty_return_type	=> 'undef_string',
			###LogSD		log_space			=> 'Test',
						);
}										"Prep a test parser instance";
###LogSD	$phone->talk( level => 'info', message => [ "parser only loaded" ] );
lives_ok{ 	
			$workbook = $parser->parse( $bad_file );
}										"Attempt to unzip a bad file and prepare to read data";
			#~ print Dumper( $workbook );
			if ( !defined $workbook ) {
				# the test version of "die $parser->error()";
like		$parser->error(), qr/xls_test.xml| didn't pass either the zip or xml file initial tests/,
										"Check the error message from the failed file load";
			}else{
is			$workbook,	undef,			"Test that there is no workbook";
			}# exit 1;
###LogSD	if( 0 ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD		UNBLOCK =>{
###LogSD			log_file => 'trace',
###LogSD		},
###LogSD		Test =>{
###LogSD			WorkbookFileInterface =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'debug',
###LogSD				},
###LogSD				ZipReader =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'trace',
###LogSD					},
###LogSD				},
###LogSD				XMLReader =>{
###LogSD					extract_file =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					close_the_file =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					squash_node =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					_hidden =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD			WorkbookMetaInterface =>{
###LogSD				XMLReader =>{
###LogSD					_hidden =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					squash_node =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					current_named_node =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					advance_element_position =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					start_the_file_over =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					current_node_parsed =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					parse_element =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		},
###LogSD	}, );
###LogSD	}
lives_ok{ 	
			$workbook = $parser->parse( $test_file );
}										"Attempt to unzip a good file and prepare to read data";
			#~ print Dumper( $workbook );
			if ( !defined $workbook or !$workbook->file_opened ) {
				# the test version of "die $parser->error()";
is			$parser->error(), 'Workbook failed to load',
										"Write any error messages from the file load";
			}else{
ok			1,							"The file unzipped and the parser set up without issues";
			}# exit 1;

			my	$offset_ref = [ 0, 9, 17 ];
			my	$y = 0;
###LogSD	my	$test_position = 40;
###LogSD	my	$test_worksheet = 'Sheet5';
###LogSD	my	$show_worksheet_build = 0;
###LogSD	if( $show_worksheet_build ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Workbook =>{
###LogSD					worksheet =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
#~ ###LogSD				WorkbookFileInterface =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'trace',
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD	}, );
###LogSD	}
			for my $worksheet ( $workbook->worksheets() ) {
			#~ my	$worksheet = $workbook->worksheet( 'Sheet1' );
			my	$worksheet_name = $worksheet->get_name;
explain		'testing worksheet: ' . $worksheet_name;
				$row_ref = undef;
			my	$x = 0;
is			$worksheet->is_sheet_hidden, $answer_ref->[$offset_ref->[$y] + $x],
									'Check that the sheet knows correctly if it is hidden (' . ($answer_ref->[$offset_ref->[$y] + $x++] ? 'Is' : 'Not') .')';
			SHEETDATA: while( $x < 50 and !$row_ref or $row_ref ne 'EOF' ){
#~ explain		"X is: $x | Worksheet name is: $worksheet_name";
###LogSD	if( $worksheet_name eq $test_worksheet and $x == $test_position ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD				Worksheet =>{
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					XMLToPerlData =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}elsif( $worksheet_name eq $test_worksheet and $x > $test_position){# + 1
###LogSD		exit 1;
###LogSD	}
###LogSD	$phone->talk( level => 'debug', message => [ "getting position: $x" ] );
 
#~ explain		"Checking answer position: " . ($offset_ref->[$y] + $x);
lives_ok{	$row_ref = $worksheet->fetchrow_arrayref }
										'Get the cell values for row: ' . ($x);
			if( !ref $row_ref ){
#~ explain		"Checking answer position: " . ($offset_ref->[$y] + $x);
			if( $row_ref ){
is			$row_ref, $answer_ref->[$offset_ref->[$y] + $x],
										"Received EOF - checking for correctness";
			last SHEETDATA;
			}else{
is			$row_ref, $answer_ref->[$offset_ref->[$y] + $x++],
										"Received an empty row - checking for correctness";
			}
			}else{
is_deeply	$row_ref, $answer_ref->[$offset_ref->[$y] + $x],
										"..and check that the correct values were returned";
			}
			$x++;
###LogSD	if( $show_worksheet_build and $worksheet_name eq $test_worksheet ){
###LogSD	exit 1;
###LogSD	}
			}
			$y++;
			}
lives_ok{ 	
			$workbook = Spreadsheet::Reader::ExcelXML->new(
							file 			=> $test_file,
							empty_is_end 		=> 1,
							empty_return_type 	=> 'undef_string',
							group_return_type	=> 'value',
							count_from_zero		=> 1,
			###LogSD		log_space			=> 'Test',
						);
}										"Attempt to unzip the file with different attributes";
			#~ print Dumper( $workbook );
			if ( $workbook->file_opened ) {
pass									"The file unzipped and the parser set up without issues";
			}else{
				# the test version of "die $parser->error()";
is			$workbook->error(), 'Workbook failed to load',
										"Write any error messages from the file load";
			}
ok			my $worksheet = $workbook->worksheet( 'Sheet1' ),
										"Open 'Sheet1' again";
###LogSD	if( 0 ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
#~ ###LogSD				ExcelFmtDefault =>{
#~ ###LogSD					_build_datestring =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					XMLReader =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'warn',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					XMLToPerlData =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD	}, );
###LogSD	}
is_deeply	$worksheet->fetchrow_arrayref( 13 ), $answer_ref->[31],
										"fetchrow_arrayref( 13 ) And check that it returns: " . Dumper( $answer_ref->[31] );
###LogSD	if( 1 ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD				Worksheet =>{
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'debug',
###LogSD						},
###LogSD						_hidden =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD						},
###LogSD						advance_element_position =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'debug',
###LogSD							},
###LogSD						},
###LogSD						squash_node =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD						},
###LogSD						current_node_parsed =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD						},
###LogSD						current_named_node =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD					NamedWorksheet =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'info',
###LogSD						},
###LogSD					},
###LogSD					build_cell_label =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					_hidden =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD	}, );
###LogSD	}
is_deeply	$worksheet->fetchrow_arrayref( 11 ), $answer_ref->[29],
										"fetchrow_arrayref( 11 ) And check that it returns: " . Dumper( $answer_ref->[29] );
###LogSD	if( 0 ){
###LogSD		exit 1;
###LogSD	}
###LogSD	if( 1 ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD			},
###LogSD	}, );
###LogSD	}
is_deeply	$worksheet->fetchrow_arrayref( ), $answer_ref->[30],
										"fetchrow_arrayref() (next -> 12) And check that it returns: " . Dumper( $answer_ref->[30] );
###LogSD	exit 1;
is			$workbook->parse( 'badfile.not' ), undef,
										"Check that a bad file will not load";
like		$workbook->error, qr/Value "badfile\.not" did not pass type constraint "IOFileType"/,
										"Confirm that the correct error is passed";
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