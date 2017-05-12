#########1 Test File for Spreadsheet::Reader::ExcelXML::Error         7#########8#########9
#!/usr/bin/env perl
BEGIN{ 
	$ENV{PERL_TYPE_TINY_XS} = 0;
	#~ use Carp 'longmess';
	#~ $SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
}
$| = 1;

use	Test::Most tests => 12;
use	Test::Moose;
use Capture::Tiny qw( capture_stderr capture_stdout );
use	lib 
		'../../../../../Log-Shiras/lib',
		'../../../../lib',;
#~ use Log::Shiras::Switchboard v0.21 qw( :debug );#
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						name_space_bounds =>{
###LogSD							UNBLOCK =>{
###LogSD								log_file => 'trace',
###LogSD							},
###LogSD							Test =>{
###LogSD								UNBLOCK =>{
###LogSD									log_file => 'trace',
###LogSD								},
###LogSD							},
###LogSD						},
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD		$operator->add_skip_up_caller( qw( Carp __ANON__ ) );
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::Unhide qw( :debug );
use Spreadsheet::Reader::ExcelXML::Error;
my  ( 
			$test_instance, $capture, $capture_II,
	);
my 			@class_attributes = qw(
				error_string
				should_warn
			);
my  		@class_methods = qw(
				new
				clear_error
				error
				set_error
				set_warnings
				if_warn
			);
my			$answer_ref = [
			];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
map{ 
has_attribute_ok
			'Spreadsheet::Reader::ExcelXML::Error', $_,
										"Check that Spreadsheet::Reader::ExcelXML::Error has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		'Spreadsheet::Reader::ExcelXML::Error', $_,
} 			@class_methods;

###LogSD	$phone->talk( level => 'info', message => [ "harder questions ..." ] );
lives_ok{
			$test_instance =	Spreadsheet::Reader::ExcelXML::Error->new(
									should_warn	=> 1,# to turn on cluck
								);
}										"Prep a new Error instance";

###LogSD	$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
###LogSD	$capture_II = capture_stdout{
			$capture = capture_stderr{
is			$test_instance->set_error( "Watch out World" ), 1,
										"Send an error message";
			};
###LogSD	};
###LogSD	if( 1 ){
###LogSD	like	$capture_II, qr/Watch out World/,
###LogSD								"...and check for the correct clucked warning message";
###LogSD	}else{
like		$capture, qr/Watch out World/,
										"...and check for the correct clucked warning message";
###LogSD	}
is			$test_instance->error, "Watch out World",
										"Make sure that the warning as stated is still available";
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
###LogSD			$line =~ s/\n/\n\t\t/g;
###LogSD			push @print_list, $line;
###LogSD		}
###LogSD		printf( "name_space - %-50s | level - %-6s |\nfile_name  - %-50s | line  - %04d   |\n\t:(\t%s ):\n", 
###LogSD					$_[0]->{name_space}, $_[0]->{level},
###LogSD					$_[0]->{filename}, $_[0]->{line},
###LogSD					join( "\n\t\t", @print_list ) 	);
###LogSD		use warnings 'uninitialized';
###LogSD	}

###LogSD	1;