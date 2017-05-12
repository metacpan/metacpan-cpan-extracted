#########1 Test File for Spreadsheet::Reader::ExcelXML::XMLReader::XMLToPerlData #####9
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

my  ( 
		$parser, $worksheet, $value, $value_position, $test_cells
	);
use	Test::Most tests => 9;
use	Test::Moose;
use Capture::Tiny 'capture_stderr';
use	lib	'../../../../Log-Shiras/lib',
		'../../../../MooseX-ShortCut-BuildInstance/lib',
		$lib;
#~ use Log::Shiras::Switchboard v0.23 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'trace',
###LogSD				},
###LogSD				build_instance =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'warn',
###LogSD					},
###LogSD				},
###LogSD				build_class =>{
###LogSD					UNBLOCK =>{
###LogSD						log_file => 'warn',
###LogSD					},
###LogSD				},
###LogSD				Test =>{
###LogSD					Top =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					Workbook =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					WorkbookFileInterface =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					WorkbookMetaInterface =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD						XMLReader =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'warn',
###LogSD							},
###LogSD							next_sibling =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD					},
#~ ###LogSD					Workbook =>{
#~ ###LogSD						_hidden =>{
#~ ###LogSD							BUILDARGS =>{
#~ ###LogSD								UNBLOCK =>{
#~ ###LogSD									log_file => 'warn',
#~ ###LogSD								},
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					WorkbookMetaInterface =>{
#~ ###LogSD						XMLToPerlData =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					WorkbookRelsInterface =>{
#~ ###LogSD						XMLReader =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						XMLToPerlData =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					WorkbookPropsInterface =>{
#~ ###LogSD						XMLReader =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						XMLToPerlData =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					SharedStringsInterface =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					StylesInterface =>{
#~ ###LogSD						XMLReader =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						XMLToPerlData =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
###LogSD			},
###LogSD			reports =>{
###LogSD				log_file =>[ Print::Log->new ],
###LogSD			},
###LogSD		);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file = $test_file . 'MySQL.xml';#
my $answer_ref =[
		[ 'id', 'count', 'dataSize', 'date', 'organizationId', 'region', 'succeeded', 'userId', 'documentTaskType', 'pageCount' ],
		[ '136', '13', '13107380', '2013-10-21', '406', '', '1', '468', '0', '13' ],
		[ '137', '11', '21668650', '2013-10-21', '417', '', '1', '479', '0', '23' ],
		[ '138', '6', '6088028', '2013-10-21', '415', '', '1', '477', '0', '6' ],
		'EOF'
	];


###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
			###LogSD		log_space => 'Test',
							file => $test_file,
							group_return_type   => 'value',
							empty_return_type   => 'empty_string',
							empty_is_end		=> 0,
							count_from_zero		=> 0,
							values_only			=> 0,# Change this to skip blank cells
						);
			#~ $parser->set_warnings( 1 );
			#~ $parser->should_spew_longmess( 1 );
}										"Prep a test parser instance";# exit 1;
#~ like		 $parser->error(), qr/No \'Styles\' element with content found/,
										#~ "Write any error messages from the file load"; exit 1;
ok			$worksheet = $parser->worksheet( 'Table1' ),
										"Load 'Table1' ok";
			my $row_ref;
			my $row = 1;
			while( !$row_ref or $row_ref ne 'EOF' ){#for my $row ( 57760 .. $row_range[1] ){# 
#~ explain 	"Checking Row: $row";
###LogSD	my $reveal_row = 2; my $reveal_col = 1;
###LogSD	if( $row == $reveal_row ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'warn',
###LogSD			},
###LogSD			build_instance =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'warn',
###LogSD				},
###LogSD			},
###LogSD			build_class =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'warn',
###LogSD				},
###LogSD			},
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					build_cell_label =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
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
###LogSD					_hidden =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					Interface =>{
###LogSD						_hidden =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD					},
###LogSD					WorksheetToRow =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
#~ ###LogSD				StylesInterface =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				ExcelFormatInterface =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD	elsif( $row > $reveal_row ){
###LogSD		exit 1;
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
###LogSD		} );
###LogSD	}
			#~ my( $error, $cell ) = capture_stderr{ $worksheet->get_cell( $row, $col ) };
#~ explain		$cell;
is_deeply	$row_ref = $worksheet->fetchrow_arrayref, $answer_ref->[$row - 1],
										"Check for the correct row values for row: $row";
#~ explain		$row_ref;
			$row++
			}
			my @column_range = $worksheet->col_range;
is_deeply	[@column_range], [ 1, 10 ],
										"Check for the correct column range [ 1, 10 ]";
			my @row_range = $worksheet->row_range;
is_deeply	[@row_range], [ 1, 4 ],
										"Check for the correct row    range [ 1, 4 ]";
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