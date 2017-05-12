#########1 Test File for Spreadsheet::XLSX::Reader::LibXML::XMLReader::XMLToPerlData #####9
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
		$lib		= '../../../../' . $lib;
		$test_file	= '../../../test_files/'
	}
}
#~ BEGIN{
	#~ use Carp 'confess';
	#~ $SIG{__WARN__} = sub{ confess $_[0] };
#~ }
my  ( 
		$parser, $worksheet, $value, $value_position, $test_cells
	);
use	Test::Most tests => 36;
use	Test::Moose;
use Capture::Tiny 'capture_stderr';
use	lib	'../../../../../Log-Shiras/lib',
		'../../../../lib';
#~ use Log::Shiras::Switchboard v0.23 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
#~ ###LogSD				UNBLOCK =>{
#~ ###LogSD					log_file => 'trace',
#~ ###LogSD				},
#~ ###LogSD				build_instance =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				build_class =>{
#~ ###LogSD					UNBLOCK =>{
#~ ###LogSD						log_file => 'warn',
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD				Test =>{
#~ ###LogSD					WorkbookFileInterface =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
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
#~ ###LogSD				},
###LogSD			},
###LogSD			reports =>{
###LogSD				log_file =>[ Print::Log->new ],
###LogSD			},
###LogSD		);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file = $test_file . 'MySQL.xml';#
my $answer_ref =[
		[ 'id', 'count', 'dataSize', 'date', 'organizationId', 'region', 'succeeded', 'userId', 'documentTaskType', 'pageCount' ],
		[ '136', '13', '13107380', '2013-10-21', '406', '', '1', '468', '0', '13' ],
		[ '137', '11', '21668650', '2013-10-21', '417', '', '1', '479', '0', '23' ],
		[ '138', '6', '6088028', '2013-10-21', '415', '', '1', '477', '0', '6' ],
		[ '139', '1', '8523261', '2013-10-22', '415', '', '1', '477', '0', '9' ],
		[ '140', '9', '16491556', '2013-10-23', '448', '', '1', '509', '0', '37' ],
		[ '141', '5', '4385355', '2013-10-23', '406', '', '1', '468', '0', '7' ],
		[ '142', '4', '4111610', '2013-10-23', '410', '', '1', '472', '0', '4' ],
		[ '143', '3', '1757154', '2013-10-24', '420', '', '1', '482', '0', '3' ],
		[ '144', '8', '5493170', '2013-10-25', '410', '', '1', '472', '0', '8' ],
		[ '145', '1', '756623', '2013-10-25', '420', '', '1', '482', '0', '1' ],
		[ '146', '3', '19124058', '2013-10-28', '406', '', '1', '468', '0', '42' ],
		[ '147', '3', '2304357', '2013-10-30', '420', '', '1', '482', '0', '3' ],
		[ '148', '3', '1101041', '2013-10-30', '426', '', '1', '488', '0', '3' ],
		[ '149', '3', '405292', '2013-10-31', '490', '', '1', '553', '0', '3' ],
		[ '150', '3', '2455899', '2013-11-01', '493', '', '1', '556', '0', '0' ],
		[ '151', '1', '130706', '2013-11-01', '490', '', '1', '553', '0', '0' ],
		[ '152', '2', '3469532', '2013-11-03', '503', '', '1', '567', '0', '0' ],
		[ '153', '8', '4498550', '2013-11-05', '511', '', '1', '575', '0', '0' ],
		[ '154', '1', '0', '2013-11-06', '525', '', '0', '588', '0', '0' ],
		[ '155', '1', '969631', '2013-11-06', '410', '', '1', '472', '0', '0' ],
		[ '156', '1', '546003', '2013-11-06', '525', '', '1', '588', '0', '0' ],
		[ '157', '7', '17241653', '2013-11-06', '511', '', '1', '575', '0', '0' ],
		[ '158', '1', '356687', '2013-11-06', '527', '', '1', '590', '0', '0' ],
		[ '159', '13', '11465234', '2013-11-07', '410', '', '1', '472', '0', '0' ],
		[ '512', '144', '193488048', '2014-05-13', '477', '', '1', '483', '0', '576' ],
		[ '513', '6', '71282745', '2014-05-13', '1332', '', '1', '1441', '0', '34' ],
		[ '514', '1', '23957045', '2014-05-13', '1384', '', '1', '1491', '0', '18' ],
		[ '515', '12', '121655365', '2014-05-14', '1332', '', '1', '1441', '0', '60' ],
		[ '4034', '4', '307254', '2015-04-21', '2066', 'eu-west-1', '1', '2222', '0', '6' ],
		'EOF'
	];


###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::XLSX::Reader::LibXML->new(
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
}										"Prep a test parser instance";
like		 $parser->error(), qr/No \'Styles\' element with content found/,
										"Write any error messages from the file load";# exit 1;
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
is_deeply	[@row_range], [ 1, 30 ],
										"Check for the correct row    range [ 1, 30 ]";
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