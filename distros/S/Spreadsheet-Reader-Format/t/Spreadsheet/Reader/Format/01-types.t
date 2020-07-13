#########1 Test File for Spreadsheet::Reader::ExcelXML::Types         7#########8#########9
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
		$test_file	= '../../../test_files/';
	}
}
$| = 1;

use	Test::Most tests => 18;
use	Test::TypeTiny;
#~ use	Test::Moose;
use Data::Dumper;
use IO::File;
use Clone 'clone';
#~ use Capture::Tiny qw( capture_stderr );
use	lib 
		'../../../../../../Log-Shiras/lib',
		$lib,
	;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
use Spreadsheet::Reader::Format::Types v0.1 qw(
		NegativeNum					ZeroOrUndef					NotNegativeNum
		PositiveNum					Excel_number_0
	);#PassThroughType FileName EpochYear 
my	@types_list = (
		PositiveNum,				NegativeNum,				ZeroOrUndef,
		NotNegativeNum,
	);#PassThroughType,			FileName,					EpochYear,
my	$test_dir	= ( @ARGV ) ? $ARGV[0] : $test_file;
my	$xlsx_file	= $test_dir . 'TestBook.xlsx';
my	$xml_file	= $test_dir . '[Content_Types].xml';
my	$real_file	= $test_dir . 'badfile.is';
my  ( 
			$position, $counter, $exception, $fh,
	);
my			$file_handle = IO::File->new( $xlsx_file );
			open( $fh, '<', $xlsx_file );
my 			$row = 0;
my			$question_ref =[
				[ 1, 2, 0.1234, -3 ], #~ PositiveNum
				[ -1, -2, -0.1234, 0 ],#~ NegativeNum
				[ 0, undef, 's', 2 ],#~ ZeroOrUndef
				[ 1, 2, 0.1234, 0, -1],#~ NotNegativeNum
				#~ Excel_number_0?
			];
my			$answer_ref = [
				[undef, undef, undef, qr/Value "-3" did not pass type constraint "PositiveNum"/, ],
				[undef, undef, undef, qr/Value "0" did not pass type constraint "NegativeNum"/, ],
				[	undef, undef,
					qr/Value "s" did not pass type constraint "ZeroOrUndef"/,
					qr/Value "2" did not pass type constraint "ZeroOrUndef"/, ],
				[undef, undef, undef, undef, qr/Value "-1" did not pass type constraint "NotNegativeNum"/, ],
			];
###LogSD my $phone = Log::Shiras::Telephone->new;
###LogSD	$phone->talk( level => 'debug', message =>[ 'Start your engines ...' ] );
			#~ no strict 'refs';
			my $x = 0;
			for my $x ( 0..$#types_list ){
			my $type = $types_list[$x];
###LogSD	$phone->talk( level => 'debug', message =>[ "Testing type: $type" ] );
			for my $y ( 0..$#{$question_ref->[$x]} ){
###LogSD	if( $x == 0 and $y==0 ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD	$phone->talk( level => 'debug', message =>[
###LogSD		'Testing value: ' . (($question_ref->[$x]->[$y]) ? $question_ref->[$x]->[$y] : '') ] );
			my $type_error = undef;
			my $test_value = clone( $question_ref->[$x]->[$y] );
			$type_error = $type->validate( $test_value );
			if( $type_error and $type->has_coercion ){
				eval '$type->assert_coerce( $test_value )';
				$type_error = $@;
				$type_error = undef if $type_error eq '';
			}
###LogSD	$phone->talk( level => 'debug', message =>[ 'Current error string:', $type_error ] );
			if( $answer_ref->[$x]->[$y] ){
like		$type_error, $answer_ref->[$x]->[$y],
							"Check that |$question_ref->[$x]->[$y]| gives the error |" .
							"$answer_ref->[$x]->[$y]| for type: " . $type->display_name;
			}else{
is			$type_error, undef,
							'Check that |' . ($question_ref->[$x]->[$y]//'') . 
							'| passes (or coerces to) type: ' . 
							$type->display_name;
			}
			}
			}
ok			Excel_number_0->assert_coerce( 'jabberwoky' ),
							"A run on the Excel_number_0 coercion";
explain 								"...Test Done";
done_testing();

package WithErrorString;
sub new{ bless {}, shift; }
sub as_string{ "The is an error string!" }

package WithErrorMessage;
sub new{ bless {}, shift; }
sub message{ "The is an error message!" }


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

1;