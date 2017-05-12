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
	use Carp 'confess';
	$SIG{__WARN__} = sub{ confess $_[0] };
}
$| = 1;

use	Test::Most tests => 34;
use	Test::Moose;
use Data::Dumper;
use	lib	$lib,
	;
$test_file = ( @ARGV ) ? $ARGV[0] : $test_file;
my	$test_ref = {
		alt_default =>{
			get_values_only			=> 1,
			counting_from_zero		=> 0,
			is_empty_the_end		=> 1,
		},
		just_the_data =>{
			counting_from_zero   	=> 0,
			get_values_only       	=> 1,
			is_empty_the_end      	=> 1,
			get_group_return_type 	=> 'value',
			_starts_at_the_edge		=> 0,
		},
		like_ParseExcel =>{
			counting_from_zero		=> 1,
			get_group_return_type	=> 'instance',
		},
		'just_the_data~|~like_ParseExcel~|~lots_of_ram' =>{
			get_values_only       	=> 1,
			is_empty_the_end      	=> 1,
			_starts_at_the_edge		=> 0,
			counting_from_zero		=> 1,
			get_group_return_type	=> 'instance',
			cache_positions	=>{
				shared_strings_interface => 209715200,# 200 MB
				styles_interface => 209715200,# 200 MB
				#~ worksheet_interface => 209715200,# 200 MB #Not yet available
				#~ chartsheet_interface => 209715200,# 200 MB
			},
		},
	};
		
is 			eval 'use Spreadsheet::XLSX::Reader::LibXML "like_ParseExcel"', undef,
						'Attempt to load a bad import flag';
like 		$@, qr/Passed attribute default flag -like_ParseExcel- does not comply with the correct format/,		
						'.. and test for the correct error message';
			for my $good_flag ( keys %$test_ref ){
lives_ok{		delete $INC{'Spreadsheet::XLSX::Reader::LibXML'}; }
						'Remove the last load of Spreadsheet::XLSX::Reader::LibXML';
				my $eval_string = 'use Spreadsheet::XLSX::Reader::LibXML qw( :' . join( ' :', split( /~\|~/, $good_flag ) ) . ");\n";
				
is 				eval $eval_string, undef,
						"Attempt to load the package with the flag(s): $good_flag";
is 				$@, '',		
						'.. and check that it succeded';
				my $instance;
lives_ok{		$instance = Spreadsheet::XLSX::Reader::LibXML->new }
						"Build an instance of Spreadsheet::XLSX::Reader::LibXML for testing with flag(s): :$good_flag";
				for my $method ( keys %{$test_ref->{$good_flag}} ){
is_deeply				$instance->$method, $test_ref->{$good_flag}->{$method},
						"check that setting the flag -$good_flag- returns the method -$method- value: $test_ref->{$good_flag}->{$method}";
				}
			}
explain 								"...Test Done";
done_testing();