#########1 Test File for Spreadsheet::Reader::ExcelXML  6#########7#########8#########9
#!/usr/bin/env perl -w
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
		$lib		= '../../../' . $lib;
		$test_file	= '../../test_files/'
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;
use	Test::Most tests => 290;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							build_instance =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD							build_class =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD							Test =>{
#~ ###LogSD								hidden =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'debug',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								ExcelFormatInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookFileInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
###LogSD								WorkbookMetaInterface =>{
#~ ###LogSD									_load_unique_bits =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'trace',
###LogSD										},
#~ ###LogSD									},
###LogSD									XMLToPerlData =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									XMLReader =>{
###LogSD										FromFile =>{
###LogSD											start_the_file_over =>{
###LogSD												UNBLOCK =>{
###LogSD													log_file => 'warn',
###LogSD												},
###LogSD											},
###LogSD										},
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookRelsInterface =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookPropsInterface =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								SharedStringsInterface =>{
#~ ###LogSD									get_shared_string_position =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'trace',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								StylesInterface =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									get_format_position =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_build_perl_node_from_xml_perl =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
###LogSD								},
###LogSD								Workbook =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'info',
###LogSD											},
###LogSD									worksheet =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									worksheets =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									_hidden =>{
###LogSD										BUILDARGS =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD										BUILD =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD										set_formatter_inst =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD										_build_file_interface =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'trace',
###LogSD											},
###LogSD										},
###LogSD										_build_workbook =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD										_load_meta_data =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD									},
###LogSD								},
###LogSD								Worksheet =>{
###LogSD									_load_unique_bits =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									_hidden =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									_parse_column_row =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									WorksheetToRow =>{
###LogSD										_load_unique_bits =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									XMLToPerlData =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									XMLReader =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'warn',
###LogSD										},
###LogSD									},
###LogSD									Interface =>{
###LogSD										_hidden =>{
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD									},
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'TestBook.xlsx';
my  (
		$error_instance, $parser, $workbook, $row_ref, $cell,
	);
my	$answer_ref = [
		'Sheet2', 0, 0, 6, 0, 2,
		[
			[
				[qw(Category Total Date) ],
				[qw( Red 5 2017-02-14 )],
				[qw( Blue 7 2017-02-14 )],
				[qw( Omaha 2 2018-02-03 )],
				[qw( Red 3 2018-02-03 )],
				[qw( Red 30 2016-02-06 )],
				[qw( Blue 10 2016-02-06 )],
			],
			[
				[qw(Category Total Date) ],
				[qw( Red 5 41318 )],
				[qw( Blue 7 41318 )],
				[qw( Omaha 2 41672 )],
				[qw( Red 3 41672 )],
				[qw( Red 30 40944 )],
				[qw( Blue 10 40944 )],
			],
		],
		'Sheet5', 1, 0, 5, 0, 4,
		[
			[
				[ 'Superbowl Audibles', 'Column Labels' ],
				[ 'Row Labels', '2016-02-06', '2017-02-14', '2018-02-03', 'Grand Total' ],
				[ 'Blue', 10, 7, '', 17 ,],
				[ 'Omaha', '', '', 2, 2, ],
				[ 'Red', 30, 5, 3, 38, ],
				[ 'Grand Total', 40, 12, 5, 57, ],
			],
			[
				[ 'Superbowl Audibles', 'Column Labels' ],
				[ 'Row Labels', 40944, 41318, 41672, 'Grand Total' ],
				[ 'Blue', 10, 7, '', 17 ,],
				[ 'Omaha', '', '', 2, 2, ],
				[ 'Red', 30, 5, 3, 38, ],
				[ 'Grand Total', 40, 12, 5, 57, ],
			],
		],
		'Sheet1', 0, 0, 13, 0, 5,
		[
			[
				[],
				['Hello',undef,undef,'my'],
				[],
				[undef,undef,'World'],
				[],
				['Hello World',''],
				[undef,'69'],
				[undef,'27',undef,undef,'12-Sep-05'],
				[undef,'42'],
				[undef,undef,undef,' ','2/6/2011','6-Feb-11',],
				['2.13'],
				[undef,'',undef,'6-Feb-11',''],
				[],
				[undef,undef,' ','39118','6-Feb-11'],
			],
			[
				[],
				['Hello',undef,undef,'my'],
				[],
				[undef,undef,'World'],
				[],
				['Hello World',''],
				[undef,'69'],
				[undef,'27',undef,undef,37145],
				[undef,'42'],
				[undef,undef,undef,' ','2/6/2011','2/6/2011',],
				['2.1345678901'],
				[undef,'',undef,39118,''],
				[],
				[undef,undef,' ','39118',39118],
			],
		],
	];

###LogSD		$phone->talk( level => 'info', message => [ "hard questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
			###LogSD		log_space			=> 'Test',
						);
}										"Prep a test parser instance";
###LogSD	$phone->talk( level => 'info', message => [ "parser only loaded" ] );
lives_ok{
			$workbook = $parser->parse( $test_file );
}										"Attempt to unzip the file and prepare to read data";
			#~ print Dumper( $workbook );
			if ( !defined $workbook ) {
				# the test version of "die $parser->error()";
is			$parser->error(), 'Workbook failed to load',
										"Write any error messages from the file load";
			}else{
ok			1,							"The file unzipped and the parser set up without issues";
			}

			my	$offset_ref = [ 0, 7, 14 ];
			my	$y = 0;
###LogSD	my	$test_position = 40;
###LogSD	my	$test_worksheet = 'Sheet2';
###LogSD	my	$show_worksheet_build = 0;
###LogSD	if( $show_worksheet_build ){
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				ExcelFmtDefault =>{
###LogSD					_build_datestring =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'debug',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD	}, );
###LogSD	}
			for my $worksheet ( $workbook->worksheets() ) {
			my	$x = 0;
			my	$worksheet_name = $worksheet->get_name;
is		$worksheet_name	, $answer_ref->[$offset_ref->[$y] + $x],
									'Confirm the worksheet is named: ' . $answer_ref->[$offset_ref->[$y] + $x++];
is			$worksheet->is_sheet_hidden, $answer_ref->[$offset_ref->[$y] + $x],
									'Check that the sheet knows correctly if it is hidden (' . ($answer_ref->[$offset_ref->[$y] + $x++] ? 'Is' : 'Not') .')';
			my ( $row_min, $row_max ) = $worksheet->row_range();
			my ( $col_min, $col_max ) = $worksheet->col_range();
is			$row_min, $answer_ref->[$offset_ref->[$y] + $x],
									'Check for the correct minimum row: ' . $answer_ref->[$offset_ref->[$y] + $x++];
is			$row_max, $answer_ref->[$offset_ref->[$y] + $x],
									'Check for the correct maximum row: ' . $answer_ref->[$offset_ref->[$y] + $x++];
is			$col_min, $answer_ref->[$offset_ref->[$y] + $x],
									'Check for the correct minimum col: ' . $answer_ref->[$offset_ref->[$y] + $x++];
is			$col_max, $answer_ref->[$offset_ref->[$y] + $x],
									'Check for the correct maximum col: ' . $answer_ref->[$offset_ref->[$y] + $x++];

			for my $row ( $row_min .. $row_max ) {
			for my $col ( $col_min .. $col_max ) {
###LogSD	if( $worksheet_name eq $test_worksheet and $x == $test_position ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					XMLToPerlData =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD				SharedStringsInterface =>{
###LogSD					XMLToPerlData =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					XMLReader =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
#~ ###LogSD				ExcelFmtDefault =>{
#~ ###LogSD					hidden =>{
#~ ###LogSD						_build_datestring =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'debug',
###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}elsif( $worksheet_name eq $test_worksheet and $x > $test_position){# + 1
###LogSD		exit 1;
###LogSD	}

lives_ok{	$cell = $worksheet->get_cell( $row, $col ); }
									"Check that getting the cell for row -$row- and column -$col- doesn't kill the sheet: $worksheet_name";
			next unless $cell;
is			$cell->value(), $answer_ref->[$offset_ref->[$y] + $x]->[0]->[$row]->[$col],
									"Check that the coerced value returned from sheet -$worksheet_name- row -$row- and column -$col- is: " . $answer_ref->[$offset_ref->[$y] + $x]->[0]->[$row]->[$col];
is			$cell->unformatted(), $answer_ref->[$offset_ref->[$y] + $x]->[1]->[$row]->[$col],
									"Check that the unformatted value returned from sheet -$worksheet_name- row -$row- and column -$col- is: " . $answer_ref->[$offset_ref->[$y] + $x]->[1]->[$row]->[$col];
###LogSD	if( $show_worksheet_build and $worksheet_name eq $test_worksheet ){
###LogSD	exit 1;
###LogSD	}
			}
			}
			$y++;
			}
explain 								"...Test Done";
done_testing();# $total_tests

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
