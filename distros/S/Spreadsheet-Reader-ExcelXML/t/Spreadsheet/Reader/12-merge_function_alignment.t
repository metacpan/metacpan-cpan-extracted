#########1 Test File for Spreadsheet::XLSX::Reader::XMLReader::Worksheet        8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $worksheet );
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
		$test_file	= '../../test_files/';
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 36;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( Bool HasMethods );
use	lib
		'../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds =>{
###LogSD							main =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'debug',
###LogSD								},
###LogSD							},
#~ ###LogSD							Test =>{
#~ ###LogSD								get_merged_areas =>{
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'trace',
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
use Spreadsheet::Reader::ExcelXML;

	$test_file	= ( @ARGV ) ? $ARGV[0] : $test_file;
	$test_file .= 'merged.xlsx';
	
###LogSD	my	$log_space	= 'Test';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $error_instance, $workbook_instance, $file_handle, $format_instance,
	);
my			$answer_ref = [
				[ [ 0, 1, 1, 2 ], [  1, 0,  2, 0 ] ],
				[ 'A1', '',],
				[ 'B1', 1, 'B1:C2' ],
				[ 'C1', 1, 'B1:C2' ],
				[ 'A2', 1, 'A2:A3' ],
				[ 'B2', 1, 'B1:C2' ],
				[ 'C2', 1, 'B1:C2' ],
				[ 'A3', 1, 'A2:A3' ],
				[ 'B3', '',],
				[ 'C3', '',],
			];

			my $x = 0;
use Spreadsheet::Reader::ExcelXML ':like_ParseExcel';
lives_ok{
			$test_instance	= Spreadsheet::Reader::ExcelXML->new(
				file => $test_file,
			###LogSD	log_space	=> 'Test',
			);
			###LogSD	$phone->talk( level => 'info', message =>[ "Loaded test instance" ] );
}										"Prep a workbook instance";# exit 1;
#~ ###LogSD		exit 1;
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					FileWorksheet =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
#~ ###LogSD					XMLReader =>{
#~ ###LogSD						_hidden =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						squash_node =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						parse_element =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						current_named_node =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						current_node_parsed =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD						advance_element_position =>{
#~ ###LogSD							UNBLOCK =>{
#~ ###LogSD								log_file => 'warn',
#~ ###LogSD							},
#~ ###LogSD						},
#~ ###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
lives_ok{ 	$worksheet = $test_instance->worksheet( 'Blad1' ) }
										'..and pull the worksheet in question (Blad1)';
###LogSD		exit 1;
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD					_get_next_value_cell =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
###LogSD		} );
is_deeply	$worksheet->get_merged_areas, $answer_ref->[$x++],
				'Check that get_merged_areas works';

			for my $row ( 0.. 2 ){
			for my $column ( 0..2 ){
###LogSD	my $reveal_row = 0;
###LogSD	my $reveal_col = 1;
###LogSD	my $revealed = 0;
###LogSD	if( $row == $reveal_row and $column == $reveal_col ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD					_get_next_value_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		$revealed = 1;
###LogSD	}
###LogSD	elsif( $revealed and ( $row != $reveal_row or $column != $reveal_col) ){
###LogSD		exit 1;
###LogSD		$operator->add_name_space_bounds( {
###LogSD			Test =>{
###LogSD				Worksheet =>{
###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD					_get_next_value_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'warn',
###LogSD						},
###LogSD					},
###LogSD				},
###LogSD			},
###LogSD		} );
###LogSD		$revealed = 0;
###LogSD	}
ok			my $cell = $worksheet->get_cell( $row, $column ),
										"get the cell for row -$row- and column -$column-";
is			$cell->cell_id, $answer_ref->[$x]->[0],
										"Confirm the cellId: $answer_ref->[$x]->[0]";
is			$cell->is_merged, $answer_ref->[$x]->[1],
										"..and test for the correct merge state: $answer_ref->[$x]->[1]";
			if( $cell->is_merged ){
is			$cell->merge_range, $answer_ref->[$x]->[2],
										"..and check for the participating merge range: $answer_ref->[$x]->[2]";
			}
			$x++;
			}
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