#########1 Test File for Spreadsheet::XLSX::Reader::LibXML  6#########7#########8#########9
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
		$test_file	= '../../../test_files/'
	}
}
$| = 1;
my $total_tests = 156;
use Test::Most;
#~ use	Test::Most tests => $total_tests;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../../Log-Shiras/lib',
		'../../../../../MooseX-ShortCut-BuildInstance/lib',
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
###LogSD											log_file => 'trace',
###LogSD										},
###LogSD									},
###LogSD									worksheets =>{
###LogSD										UNBLOCK =>{
###LogSD											log_file => 'trace',
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
###LogSD											log_file => 'trace',
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
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'TestBook.xlsx';
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
		['Hello World',undef],
		[undef,'69'],
		[undef,'27',undef,undef,'12-Sep-05'],
		[undef,'42'],
		[undef,undef,undef,' ','2/6/2011','6-Feb-11',],
		['2.13'],
		[undef,undef,undef,'6-Feb-11',undef],
		[],
		[undef,undef,' ','39118','6-Feb-11'],
		'EOF',
	];

my 			@class_attributes = qw(
				error_inst					file_name					file_handle
				sheet_parser				count_from_zero				file_boundary_flags
				empty_is_end				from_the_edge				values_only
				group_return_type			formatter_inst				empty_return_type
				cache_positions
			);
my  		@class_methods = qw(
				new							import						parse
				worksheet					worksheets					get_excel_region
				has_error_inst				error						set_error
				clear_error					set_warnings				if_warn
				should_spew_longmess		spewing_longmess			set_formatter_inst
				get_formatter_inst			get_formatter_region		has_target_encoding
				get_target_encoding			set_target_encoding			change_output_encoding
				set_defined_excel_formats	get_defined_conversion		parse_excel_format_string
				set_date_behavior			set_european_first			set_formatter_cache_behavior
				set_file_name				has_file_name				file_name
				set_file_handle				has_file_handle				file_handle
				set_parser_type				get_parser_type				counting_from_zero
				set_count_from_zero			boundary_flag_setting		change_boundary_flag
				set_empty_is_end			is_empty_the_end			set_values_only
				get_values_only				set_from_the_edge			get_group_return_type
				set_group_return_type		get_empty_return_type		set_empty_return_type
				cache_positions				creator						modified_by		
				date_created				date_modified				get_shared_string
				get_format					get_worksheet_names			worksheet_name
				worksheet_count				get_chartsheet_names		chartsheet_name
				chartsheet_count			get_sheet_names				get_sheet_name
				sheet_count					start_at_the_beginning		in_the_list
				get_epoch_year				has_epoch_year				get_error_inst
			);
			
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
map{ 
has_attribute_ok
			'Spreadsheet::XLSX::Reader::LibXML', $_,
										"Check that Spreadsheet::XLSX::Reader::LibXML has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		'Spreadsheet::XLSX::Reader::LibXML', $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::XLSX::Reader::LibXML->new(
							count_from_zero		=> 0,
							group_return_type	=> 'value',
							empty_return_type	=> 'undef_string',
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

			my	$offset_ref = [ 0, 9, 17 ];
			my	$y = 0;
###LogSD	my	$test_position = 2;
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
			my	$worksheet_name = $worksheet->get_name;
explain		'testing worksheet: ' . $worksheet_name;# exit 1;
				$row_ref = undef;
			my	$x = 0;
is			$worksheet->is_sheet_hidden, $answer_ref->[$offset_ref->[$y] + $x],
									'Check that the sheet knows correctly if it is hidden (' . ($answer_ref->[$offset_ref->[$y] + $x++] ? 'Is' : 'Not') .')';
			SHEETDATA: while( $x < 50 and !$row_ref or $row_ref ne 'EOF' ){
#~ explain		"X is: $x | Worksheet name is: $worksheet_name";
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
			$workbook = Spreadsheet::XLSX::Reader::LibXML->new(
							file_name 			=> $test_file,
							empty_is_end 		=> 1,
							empty_return_type 	=> 'undef_string',
							group_return_type	=> 'value',
			###LogSD		log_space			=> 'Test',
						);
}										"Attempt to unzip the file with different attributes";
			#~ print Dumper( $workbook );
			if ( !$workbook->has_file_name ) {
				# the test version of "die $parser->error()";
is			$workbook->error(), 'Workbook failed to load',
										"Write any error messages from the file load";
			}else{
pass									"The file unzipped and the parser set up without issues";
			}
ok			my $worksheet = $workbook->worksheet( 'Sheet1' ),
										"Open 'Sheet1' again";
is_deeply	$worksheet->fetchrow_arrayref( 13 ), $answer_ref->[31],
										"fetchrow_arrayref( 13 ) And check that it returns: " . Dumper( $answer_ref->[31] );
is_deeply	$worksheet->fetchrow_arrayref( 11 ), $answer_ref->[29],
										"fetchrow_arrayref( 11 ) And check that it returns: " . Dumper( $answer_ref->[29] );
is_deeply	$worksheet->fetchrow_arrayref( ), $answer_ref->[30],
										"fetchrow_arrayref() (next -> 12) And check that it returns: " . Dumper( $answer_ref->[30] );
###LogSD	$operator->add_name_space_bounds( {
###LogSD			Test =>{
#~ ###LogSD				ExcelFmtDefault =>{
#~ ###LogSD					_build_datestring =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD	}, );
is			$workbook->parse( 'badfile.not' ), undef,
										"Check that a bad file will not load";
like		$workbook->error, qr/Value \"badfile\.not\" did not pass type constraint \"IOFileType\"/,
										"Confirm that the correct error is passed";
#~ ###LogSD	exit 1;
explain 								"...Test Done";
done_testing($total_tests);

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