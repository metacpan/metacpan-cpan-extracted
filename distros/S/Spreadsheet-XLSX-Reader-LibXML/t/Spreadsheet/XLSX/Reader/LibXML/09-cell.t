#########1 Test File for Spreadsheet::XLSX::Reader::LibXML::Cell      7#########8#########9
#!/usr/bin/env perl
BEGIN{ $ENV{PERL_TYPE_TINY_XS} = 0; }
$| = 1;

use	Test::Most tests => 56;
use	Test::Moose;
use	Data::Dumper;
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );
use	lib
		'../../../../../../Log-Shiras/lib',
		'../../../../../lib',;
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
###LogSD	use Log::Shiras::UnhideDebug;
use	Spreadsheet::XLSX::Reader::LibXML::Cell;
use	Spreadsheet::XLSX::Reader::LibXML::Error;
#~ use	Spreadsheet::XLSX::Reader::LibXML::Types qw( PassThroughType ZeroFromNum FourteenFromWinExcelNum );
my	$test_file = ( @ARGV ) ? $ARGV[0] : '../../../../test_files/';
	$test_file .= 'styles.xml';
###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 'main', );
###LogSD		$phone->talk( level => 'trace', message => [ "Test file is: $test_file" ] );
my  ( 
			$test_instance, $capture, $x, @answer,# $error_instance,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				error_inst
				cell_unformatted
				rich_text
				cell_font
				cell_border
				cell_style
				cell_fill
				cell_type
				cell_encoding
				cell_merge
				cell_formula
				cell_row
				cell_col
				r
				cell_hyperlink
				cell_coercion
			);
my  		@class_methods = qw(
				new
				error
				set_error
				clear_error
				set_warnings
				if_warn
				unformatted
				has_unformatted
				get_rich_text
				has_rich_text
				get_font
				has_font
				get_border
				has_border
				get_style
				has_style
				get_fill
				has_fill
				type
				has_type
				encoding
				has_encoding
				merge_range
				is_merged
				formula
				has_formula
				row
				has_row
				col
				has_col
				cell_id
				has_cell_id
				get_hyperlink
				has_hyperlink
				get_coercion
				set_coercion
				has_coercion
				clear_coercion
				coercion_name
				value
			);
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
map{ 
has_attribute_ok
			'Spreadsheet::XLSX::Reader::LibXML::Cell', $_,
										"Check that Spreadsheet::XLSX::Reader::Cell has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		'Spreadsheet::XLSX::Reader::LibXML::Cell', $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'info', message => [ "harder questions ..." ] );
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