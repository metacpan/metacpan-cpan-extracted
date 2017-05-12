#########1 Test File for Spreadsheet::Reader::ExcelXML::CellToColumnRow         8#########9
#!/usr/bin/env perl
my ( $lib, $test_file );
BEGIN{ 
	$ENV{PERL_TYPE_TINY_XS} = 0;
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; $_[0]; };
};
$| = 1;

use	Test::Most tests => 81;
use	Test::Moose;
use	MooseX::ShortCut::BuildInstance qw( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use Types::Standard qw( Bool );
use	lib
		'../../../../../Log-Shiras/lib',
		'../../../../lib',;
#~ use Log::Shiras::Switchboard qw( :debug );#
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
###LogSD	use Log::Shiras::Unhide qw( :debug );
use	Spreadsheet::Reader::ExcelXML::CellToColumnRow;
use	Spreadsheet::Reader::ExcelXML::Error;
###LogSD	use	Log::Shiras::LogSpace;
my  ( 
			$test_instance,
	);
my  		@class_attributes = qw(
			);
my  		@class_methods = qw(
				parse_column_row	build_cell_label	get_used_position
				get_excel_position	
			);
my			$question_ref =[
				'A1', 'B1','C1','D1','E1', 'F1','G1','H1',
				'I1', 'J1','K1','L1','M1', 'N1','O1','P1',
				'Q1', 'R1','S1','T1','U1', 'V1','W1','X1',
				'Y1', 'Z1','AA1','AB1','AC1', 'AD1','AE1',
				'XFD1048576', 'XFE1', 'A1048577', 'A0', '10',
				'A', 'Z1.1',
				];
my			$answer_ref = [
				[ 1, 1 ],[ 2, 1 ],[ 3, 1 ],[ 4, 1 ],[ 5, 1 ],
				[ 6, 1 ],[ 7, 1 ],[ 8, 1 ],[ 9, 1 ],[ 10, 1 ],
				[ 11, 1 ],[ 12, 1 ],[ 13, 1 ],[ 14, 1 ],[ 15, 1 ],
				[ 16, 1 ],[ 17, 1 ],[ 18, 1 ],[ 19, 1 ],[ 20, 1 ],
				[ 21, 1 ],[ 22, 1 ],[ 23, 1 ],[ 24, 1 ],[ 25, 1 ],
				[ 26, 1 ],[ 27, 1 ],[ 28, 1 ],[ 29, 1 ],[ 30, 1 ],
				[ 31, 1 ],[ 16384, 1048576 ],
				[ undef, 1 ], [ 1, undef ], [ 1, undef ],
				[ undef, 10 ], [ 1, undef ], [ undef, undef ],
				[ 0, 0 ],[ 1, 0 ],[ 2, 0 ],[ 3, 0 ],[ 4, 0 ],
				[ 5, 0 ],[ 6, 0 ],[ 7, 0 ],[ 8, 0 ],[ 9, 0 ],
				[ 10, 0 ],[ 11, 0 ],[ 12, 0 ],[ 13, 0 ],[ 14, 0 ],
				[ 15, 0 ],[ 16, 0 ],[ 17, 0 ],[ 18, 0 ],[ 19, 0 ],
				[ 20, 0 ],[ 21, 0 ],[ 22, 0 ],[ 23, 0 ],[ 24, 0 ],
				[ 25, 0 ],[ 26, 0 ],[ 27, 0 ],[ 28, 0 ],[ 29, 0 ],
				[ 30, 0 ],[ 16383, 1048575 ],
				[ undef, 0 ], [ 0, undef ], [ 0, undef ],
				[ undef, 9 ], [ 0, undef ], [ undef, undef ],
			];
my			$error_ref =[
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,
				qr/\QThe column text -XFE- points to a position at -16385- past the excel limit of: 16,384\E/,
				qr/\QThe requested row cannot be greater than 1,048,576 - you requested: 1048577\E/,
				qr/\QThe requested row cannot be less than one - you requested: 0\E/,
				qr/\QCould not parse the column component from -10-\E/,
				qr/\QCould not parse the row component from -A-\E/,
				qr/\Qcould not match -Z1.1-\E/,
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,
				undef,undef,
				qr/\QThe column text -XFE- points to a position at -16385- past the excel limit of: 16,384\E/,
				qr/\QThe requested row cannot be greater than 1,048,576 - you requested: 1048577\E/,
				qr/\QThe requested row cannot be less than one - you requested: 0\E/,
				qr/\QCould not parse the column component from -10-\E/,
				qr/\QCould not parse the row component from -A-\E/,
				qr/\Qcould not match -Z1.1-\E/,
			];
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'info', message => [ "initial questions ..." ] );
lives_ok{
			$test_instance = build_instance(
				package => 'Spreadsheet::Reader::ExcelXML::CellToColumnRow::TestClass',
				add_roles_in_sequence =>[ 
			###LogSD	'Log::Shiras::LogSpace',
					'Spreadsheet::Reader::ExcelXML::CellToColumnRow',
				],
				add_attributes =>{ 
					error_inst =>{
						handles =>[ qw( error set_error clear_error set_warnings if_warn ) ],
						default	=>	sub{ Spreadsheet::Reader::ExcelXML::Error->new(
										#~ should_warn => 1,
										should_warn => 0,# to turn off cluck when the error is set
									) },
					},
					count_from_zero =>{
						isa		=> Bool,
						reader	=> 'counting_from_zero',
						writer	=> 'set_count_from_zero',
						default => 1,
					},
					
				},
				name_space		=> 'Test',
				count_from_zero	=> 0,
			);
}										"Prep a new CellToColumnRow instance";
map{ 
has_attribute_ok
			$test_instance, $_,			"Check that Spreadsheet::Reader::ExcelXML::CellToColumnRow has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
			no warnings 'uninitialized';
map{
is_deeply	[ $test_instance->parse_column_row( $question_ref->[$_] ) ], $answer_ref->[$_],
										"Convert the Excel cell ID -" . $question_ref->[$_] . "- to column, row: (" .
										$answer_ref->[$_]->[0] . ', ' . $answer_ref->[$_]->[1] . ')';
if( $error_ref->[$_] ){
like		$test_instance->error, $error_ref->[$_],
										"... and check for the correct error message";
}
}(0 .. 37);
map{
is			$test_instance->build_cell_label( @{$answer_ref->[ $_]} ), $question_ref->[$_],#Reverse the polarity flow through the gate
										"Convert the column, row: (" . $answer_ref->[ $_]->[0] . 
										', ' . $answer_ref->[ $_]->[1] . ') - to Excel cell ID -' . $question_ref->[$_] . '-'
										;
}(0 .. 31);
			use warnings 'uninitialized';
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