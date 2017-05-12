#########1 Test File for Spreadsheet::Reader::ExcelXML  6#########7#########8#########9
#!/usr/bin/env perl
my ( $lib, $test_file, $file_name, $new_error );
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

use	Test::Most tests => 7;
use	Test::Moose;
use File::Copy;
use File::Temp;
use	lib	'../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.23 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(
###LogSD						name_space_bounds => {
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD							build_class => {
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD							build_instance => {
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'warn',
###LogSD								},
###LogSD							},
###LogSD							Test => {
###LogSD								Top => {
###LogSD									_hidden => {
###LogSD										BUILDARGS => {
###LogSD											UNBLOCK =>{
###LogSD												log_file => 'warn',
###LogSD											},
###LogSD										},
###LogSD									},
###LogSD								},
#~ ###LogSD								Worksheet => {
#~ ###LogSD									UNBLOCK =>{
#~ ###LogSD										log_file => 'warn',
#~ ###LogSD									},
#~ ###LogSD									_hidden => {
#~ ###LogSD										DEMOLISH => {
#~ ###LogSD											UNBLOCK =>{
#~ ###LogSD												log_file => 'trace',
#~ ###LogSD											},
#~ ###LogSD										},
#~ ###LogSD									},
#~ ###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML;# ':debug'
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
$file_name	= 'TestBook.xlsx';
$test_file .= $file_name;
	#~ print "Test file is: $test_file\n";
my  ( 
		$parser, $worksheet, $error,# $value, $value_position,
	);
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
			###LogSD		log_space => 'Test',
							file => $test_file,
						);
}										"Prep a test parser instance";
			$parser->set_warnings( 1 );
is			$parser->error(), undef,	"Write any error messages from the file load";
			for my $worksheet ( $parser->worksheets() ) {
#~ explain			$worksheet->get_name;
				$worksheet->get_cell( 1,1 );# Advance the worksheet reader past the beginning
				#~ last;
			}
lives_ok{	$parser = undef }			"Try to 'undef' the parser";
			my $temp_dir = File::Temp->newdir();
			move( $test_file, "$temp_dir$file_name" ) or $new_error = $!;
			if( $new_error ){
fail		"File -$test_file- could not be moved to the temp dir -$temp_dir- because: $new_error";
			}else{
pass		"File moved successfully to temp dir: $temp_dir";
			}# exit 1;
			move( "$temp_dir$file_name", $test_file ) or $new_error = $!;
			if( $new_error ){
fail		"File -$temp_dir$file_name- could not be moved back to -$test_file- because: $new_error";
			}else{
pass		"File moved successfully from temp dir: $temp_dir";
			}
lives_ok{
			$parser =	Spreadsheet::Reader::ExcelXML->new(
			###LogSD		log_space => 'Test',
							file => $test_file,
						);
}										"Prep a test parser instance (again)";
lives_ok{	$parser->DEMOLISH }			"Make sure the Temp Dir cleanup works with ->DEMOLISH";
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