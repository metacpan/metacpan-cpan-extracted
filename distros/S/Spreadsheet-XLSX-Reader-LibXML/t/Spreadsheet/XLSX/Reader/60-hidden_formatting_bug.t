#########1 Test File for Spreadsheet::XLSX::Reader::LibXML  6#########7#########8#########9

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
}
$| = 1;

use	Test::Most tests => 88;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../../Log-Shiras/lib',
		'../../../../lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
###LogSD				UNBLOCK =>{
###LogSD					log_file => 'warn',
###LogSD				},
###LogSD			},
###LogSD			reports =>{
###LogSD				log_file =>[ Print::Log->new ],
###LogSD			},
###LogSD		);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
###LogSD	use MooseX::ShortCut::BuildInstance;
use Spreadsheet::XLSX::Reader::LibXML;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'hidden_format_test.xlsx';
	#~ print "Test file is: $test_file\n";
my  ( 
		$parser, @worksheets, $value, $workbook,
	);
my	$answer_ref = [
		'Sheet1',
		[0,1],
		[0,12],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, 'E421745', 'E421745', 'E421745'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0000000000000001E-9', '0.000000005', '0.000000005'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0000000000000003E-10', '0.0000000005', '5E-10'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.1000000000000002E-9', '0.0000000051', '5.1E-09'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '0', '0', '0'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.00001E-9', '0.00000000500001', '5.00001E-09'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '4', '4', '4'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0000009999999996E-9', '0.000000005000001', '5E-09'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '12', '12', '12'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0010000000000997E-9', '5.0010000000001E-09', '5.001E-09'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '13', '13', '13'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.00000000000001E-9', '5.00000000000001E-09', '5E-09'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '14', '14', '14'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0000000000000001E-9', '0.000000005', '0.000000005'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '15', '15', '15'],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '4.9999999999999999E-20', '5E-20', '5E-20'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '5.0000000000000004E-19', '0.0000000000000000005', '5E-19'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '121E22671', '121E22671', '121E22671'],[''],
		['Spreadsheet::XLSX::Reader::LibXML::Cell', undef, '121E22671', '121E22671', '121E22671'],[''],
	];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
#~ lives_ok{
			$parser = 	Spreadsheet::XLSX::Reader::LibXML->new(
							###LogSD log_space => 'Test'
						);
			$workbook = $parser->parse($test_file);
			$parser->set_warnings( 1 );
#~ }										"Prep a test parser instance";
###LogSD		$phone->talk( level => 'trace', message => [ "$parser:", $parser ] );
is			$parser->error(), undef,
										"Write any error messages from the file load";
			$parser->clear_error;
ok			@worksheets = $workbook->worksheets(),
										"Loaded worksheet objects ok";
			my	$x = 0;
			for my $worksheet ( @worksheets ){
is			$worksheet->get_name, $answer_ref->[$x],
										'Check that the next opened worksheet name is: ' . $answer_ref->[$x++];
			my @column_range = $worksheet->col_range;
is_deeply	[@column_range], $answer_ref->[$x++],
										"Check for the correct column range";
			my @row_range = $worksheet->row_range;
is_deeply	[@row_range], $answer_ref->[$x++],
										"Check for the correct row range";
			for my $row ( $row_range[0] .. $row_range[1] ){
			for my $col ( $column_range[0] .. $column_range[1] ){
###LogSD	my $reveal =14;
###LogSD	if( $row == $reveal and $col == 0 ){
###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					_build_out_the_cell =>{
###LogSD						UNBLOCK =>{
###LogSD							log_file => 'trace',
###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD	elsif( $row == $reveal and $col == 1 ){
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
			my $cell;
is			ref( $cell = $worksheet->get_cell( $row, $col ) ), $answer_ref->[$x]->[0],
										"Attempt to get the cell for row -$row- and column -$col-";
#~ is			ref( $cell ), 
										#~ "make sure it returns a cell - if it should";
			if( $answer_ref->[$x]->[0] ne '' ){
like		$parser->error(), $answer_ref->[$x]->[1],
										"Check for an expected error messages from the cell load" if $answer_ref->[$x]->[1];
is			$cell->xml_value, $answer_ref->[$x]->[2],
										"|$row|$col|Check the underlying xml value: " . $answer_ref->[$x]->[2];
is			$cell->unformatted, $answer_ref->[$x]->[3],
										"|$row|$col|And check the unformatted value: " . $answer_ref->[$x]->[3];
is			$cell->value, $answer_ref->[$x]->[4],
										"|$row|$col|And check the returned value: " . $answer_ref->[$x]->[4];
			$parser->clear_error;
			}
			$x++;
			}
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
