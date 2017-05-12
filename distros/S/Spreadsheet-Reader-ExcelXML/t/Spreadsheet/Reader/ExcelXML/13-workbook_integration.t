#########1 Test File for Spreadsheet::Reader::ExcelXML::Workbook      7#########8#########9
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
		$lib		= '../../../../' . $lib;
		$test_file	= '../../../test_files/'
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;
use	Test::Most tests => 157;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance v1.40 qw( build_instance );#
use	lib	'../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
#~ ###LogSD							main =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'info',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								Workbook =>{
#~ ###LogSD									_hidden =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD										BUILD =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									worksheet =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'debug',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									worksheets =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'debug',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookFileInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
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
#~ ###LogSD								SharedStringsInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								StylesInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_stack_perl_ref =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								ExcelFormatInterface =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								Worksheet =>{
#~ ###LogSD									_load_unique_bits =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_hidden =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD										_build_out_the_cell =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'trace',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLReader =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									FileWorksheet =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_parse_column_row =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									WorksheetToRow =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									XMLToPerlData =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									Interface =>{
#~ ###LogSD										_hidden =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
#~ ###LogSD								WorkbookMetaInterface =>{
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
#~ ###LogSD										FromFile =>{
#~ ###LogSD											start_the_file_over =>{
#~ ###LogSD												UNBLOCK =>{
#~ ###LogSD													log_file => 'warn',
#~ ###LogSD												},
#~ ###LogSD											},
#~ ###LogSD										},
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
#~ ###LogSD								},
#~ ###LogSD								Workbook =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'info',
#~ ###LogSD											},
#~ ###LogSD									worksheet =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									worksheets =>{
#~ ###LogSD										UNBLOCK =>{
#~ ###LogSD											log_file => 'warn',
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD									_hidden =>{
#~ ###LogSD										BUILDARGS =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										BUILD =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										set_formatter_inst =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'warn',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD										_build_file_interface =>{
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'trace',
#~ ###LogSD											},
#~ ###LogSD										},
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
use Spreadsheet::Reader::ExcelXML::Workbook;
use	Spreadsheet::Reader::ExcelXML::Error;
use	Spreadsheet::Reader::Format::FmtDefault;
use	Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use	Spreadsheet::Reader::Format;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'TestBook.xlsx';
my  ( 
		$error_instance, $workbook, $row_ref,
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
		[undef,undef,undef,'39118','6-Feb-11'],
	];
my 			@class_attributes = qw(
				error_inst						formatter_inst					file
				count_from_zero					file_boundary_flags				empty_is_end
				values_only						from_the_edge					group_return_type
				empty_return_type				cache_positions					show_sub_file_size
				spread_merged_values			skip_hidden						spaces_are_empty
			);
my  		@class_methods = qw(
				error							set_error						clear_error
				set_warnings					if_warn							should_spew_longmess
				spewing_longmess				get_error_inst					has_error
				has_error_inst					get_formatter_inst				set_formatter_inst
				get_formatter_region			has_target_encoding				get_target_encoding
				set_target_encoding				change_output_encoding			set_defined_excel_formats
				get_defined_conversion			parse_excel_format_string		set_date_behavior
				set_european_first				set_formatter_cache_behavior	build_workbook
				set_file						counting_from_zero				boundary_flag_setting
				is_empty_the_end				get_values_only					starts_at_the_edge
				get_group_return_type			get_empty_return_type			cache_positions
				get_cache_size					has_cache_size					spreading_merged_values
				should_skip_hidden				are_spaces_empty				worksheet
				worksheets						file_name						file_opened
				get_epoch_year					has_epoch_year					get_sheet_names
				get_sheet_name					sheet_count						get_sheet_info
				get_rel_info					get_id_info						get_worksheet_names
				worksheet_name					worksheet_count					get_chartsheet_names
				chartsheet_name					chartsheet_count				creator
				modified_by						date_created					date_modified
				has_shared_strings_interface	get_shared_string				in_the_list
				has_styles_interface			get_format						start_at_the_beginning
				demolish_the_workbook			
			);# It makes a lot of sense not to pass all of these to the top level
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			# Defaults are not set at this level so all defaults need to be manually loaded
			#  instance building doesn't happen at this level either so all defaults must be pre-built
			#	The 'simple' style all happens at the Spreadsheet::Reader::ExcelXML level
			$workbook =	Spreadsheet::Reader::ExcelXML::Workbook->new(
							count_from_zero		=> 0,
							group_return_type	=> 'value',
							empty_return_type	=> 'undef_string',
							file				=> $test_file,
							error_inst =>	Spreadsheet::Reader::ExcelXML::Error->new( 
												should_warn => 0,
								###LogSD		log_space => 'Test',
											),
							formatter_inst => build_instance(
									package => 'FormatInstance',
									superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
									add_roles_in_sequence =>[qw(
											Spreadsheet::Reader::Format::ParseExcelFormatStrings
											Spreadsheet::Reader::Format
									)],
								###LogSD		log_space => 'Test',
								),
							file_boundary_flags	=> 1,
							empty_is_end		=> 0,
							values_only			=> 0,
							from_the_edge		=> 1,
							cache_positions	=>{
								shared_strings_interface => 5242880,# 5 MB
								styles_interface => 5242880,# 5 MB
								worksheet_interface => 1024,# 1 KB
							},
							show_sub_file_size => 0,
							spread_merged_values => 0,
							skip_hidden => 0,
							spaces_are_empty => 0,
			###LogSD		log_space => 'Test',
						);
}										"Prep a Workbook instance";# exit 1;
			if ( $workbook->file_opened ) {
ok			1,							"The file unzipped and the parser set up without issues";
			}else{
is			$workbook->error(), 'Workbook failed to load',
										"Write any error messages from the file load";
			}
###LogSD	$phone->talk( level => 'info', message => [ "parser only loaded" ] );
###LogSD	$phone->talk( level => 'trace', message => [ "Workbook", $workbook ] );
map{ 
has_attribute_ok
			$workbook, $_,
										"Check that the -" . ref( $workbook ) . "- instance has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$workbook, $_,
} 			@class_methods;# exit 1;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );

			my	$offset_ref = [ 0, 9, 17 ];
			my	$y = 0;
###LogSD	my	$test_position = 40;
###LogSD	my	$test_worksheet = 'Sheet1';
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
			for my $worksheet ( $workbook->worksheets() ) {# exit 1;
			my	$worksheet_name = $worksheet->get_name;
explain		'testing worksheet: ' . $worksheet_name;# exit 1;
				$row_ref = undef;
			my	$x = 0;
is			$worksheet->is_sheet_hidden, $answer_ref->[$offset_ref->[$y] + $x],
									'Check that the sheet knows correctly if it is hidden (' . ($answer_ref->[$offset_ref->[$y] + $x++] ? 'Is' : 'Not') .')';
			SHEETDATA: while( $x < 50 and !$row_ref or $row_ref ne 'EOF' ){
explain		"X is: $x | Worksheet name is: $worksheet_name";
###LogSD	if( $worksheet_name eq $test_worksheet and $x == $test_position ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
#~ ###LogSD					XMLToPerlData =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					XMLReader =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'warn',
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
#~ ###LogSD				SharedStringsInterface =>{
#~ ###LogSD					XMLToPerlData =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'warn',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					XMLReader =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'warn',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				ExcelFmtDefault =>{
#~ ###LogSD					hidden =>{
#~ ###LogSD						_build_datestring =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
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
 
explain		"Checking answer position: " . ($offset_ref->[$y] + $x);
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
			$workbook =	Spreadsheet::Reader::ExcelXML::Workbook->new(
							empty_is_end		=> 1,
							spaces_are_empty	=> 1,
							count_from_zero		=> 0,
							group_return_type	=> 'value',
							empty_return_type	=> 'undef_string',
							file				=> $test_file,
							error_inst =>	Spreadsheet::Reader::ExcelXML::Error->new( 
												should_warn => 0,
								###LogSD		log_space => 'Test',
											),
							formatter_inst => build_instance(
									package => 'FormatInstance',
									superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
									add_roles_in_sequence =>[qw(
											Spreadsheet::Reader::Format::ParseExcelFormatStrings
											Spreadsheet::Reader::Format
									)],
								###LogSD		log_space => 'Test',
								),
							file_boundary_flags	=> 1,
							values_only			=> 0,
							from_the_edge		=> 1,
							cache_positions	=>{
								shared_strings_interface => 5242880,# 5 MB
								styles_interface => 5242880,# 5 MB
								worksheet_interface => 1024,# 1 KB
							},
							show_sub_file_size => 0,
							spread_merged_values => 0,
							skip_hidden => 0,
			###LogSD		log_space => 'Test',
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
#~ explain		$worksheet->fetchrow_arrayref( 12 );
is_deeply	$worksheet->fetchrow_arrayref( 14 ), $answer_ref->[33],
										"fetchrow_arrayref( 14 ) And check that it returns: " . Dumper( $answer_ref->[33] );
is_deeply	$worksheet->fetchrow_arrayref( 12 ), $answer_ref->[29],
										"fetchrow_arrayref( 12 ) And check that it returns: " . Dumper( $answer_ref->[29] );
is_deeply	$worksheet->fetchrow_arrayref( ), $answer_ref->[30],
										"fetchrow_arrayref() (next -> 11) And check that it returns: " . Dumper( $answer_ref->[30] );
ok			$workbook->demolish_the_workbook,
										"manually DEMOLISH the workbook to avoid errors";
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
dies_ok{ 	
			$workbook =	Spreadsheet::Reader::ExcelXML::Workbook->new(
							empty_is_end		=> 1,
							spaces_are_empty	=> 1,
							count_from_zero		=> 0,
							group_return_type	=> 'value',
							empty_return_type	=> 'undef_string',
							file				=> 'badfile.not',
							error_inst =>	Spreadsheet::Reader::ExcelXML::Error->new( 
												should_warn => 0,
								###LogSD		log_space => 'Test',
											),
							formatter_inst => build_instance(
									package => 'FormatInstance',
									superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
									add_roles_in_sequence =>[qw(
											Spreadsheet::Reader::Format::ParseExcelFormatStrings
											Spreadsheet::Reader::Format
									)],
								###LogSD		log_space => 'Test',
								),
							file_boundary_flags	=> 1,
							values_only			=> 0,
							from_the_edge		=> 1,
							cache_positions	=>{
								shared_strings_interface => 5242880,# 5 MB
								styles_interface => 5242880,# 5 MB
								worksheet_interface => 1024,# 1 KB
							},
							show_sub_file_size => 0,
							spread_merged_values => 0,
							skip_hidden => 0,
			###LogSD		log_space => 'Test',
						);
}										"Check that a bad file will not load";
like		$@, qr/Value \"badfile\.not\" did not pass type constraint \"XLSXFile\|IOFileType\"/,
										"Confirm that the correct error is passed";
lives_ok{	$workbook->demolish_the_workbook }
										"manually DEMOLISH the workbook to avoid errors";
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