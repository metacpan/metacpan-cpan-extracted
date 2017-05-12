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

use	Test::Most tests => 4;
use	Test::Moose;
use Data::Dumper;
use	lib	'../../../../../Log-Shiras/lib',
		'../../../../lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD			name_space_bounds =>{
#~ ###LogSD				Test =>{
#~ ###LogSD					StylesInstance =>{
#~ ###LogSD						_coalate_perl_style_formats =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
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
###LogSD	use MooseX::ShortCut::BuildInstance;
use Spreadsheet::XLSX::Reader::LibXML ':like_ParseExcel';
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$test_file .= 'attr.xlsx';
	#~ print "Test file is: $test_file\n";
my  ( 
		$parser, $ws, $cell, $workbook,
	);
my	$answer_ref = [
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
ok			$ws = $workbook->worksheet( 'Format' ),
										"Loaded the worksheet 'Format' OK";
#~ ###LogSD	my $reveal = 7;
#~ ###LogSD	if( $row == $reveal and $col == 0 ){
#~ ###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					_build_out_the_cell =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'trace',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
#~ ###LogSD		} );
#~ ###LogSD	}
#~ ###LogSD	elsif( $row == $reveal and $col == 1 ){
#~ ###LogSD		$operator->add_name_space_bounds( {
#~ ###LogSD			Test =>{
#~ ###LogSD				Worksheet =>{
#~ ###LogSD					_build_out_the_cell =>{
#~ ###LogSD						UNBLOCK =>{
#~ ###LogSD							log_file => 'warn',
#~ ###LogSD						},
#~ ###LogSD					},
#~ ###LogSD				},
#~ ###LogSD			},
#~ ###LogSD		} );
#~ ###LogSD	}
ok			$cell = $ws->get_cell( 3, 0 ),
										"Check that row -3- column -0- loaded OK";
is			$cell->is_hidden, 'row',	"Check that the cell knows it's the row that's hidden";
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
