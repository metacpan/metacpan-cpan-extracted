#########1 Test File for Spreadsheet::Reader::Format::FmtDefault      7#########8#########9
#!/usr/bin/env perl
BEGIN{ $ENV{PERL_TYPE_TINY_XS} = 0; }
$| = 1;

use	Test::Most tests => 64;
use	Test::Moose;
use Data::Dumper;
use Capture::Tiny qw( capture_stderr );
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );#
use	lib
		'../../../../../Log-Shiras/lib',
		'../../../../lib',;
#~ use Log::Shiras::Switchboard qw( :debug );
###LogSD	my	$operator = Log::Shiras::Switchboard->get_operator(#
###LogSD						reports =>{
###LogSD							log_file =>[ Print::Log->new ],
###LogSD						},
###LogSD					);
###LogSD	use Log::Shiras::Telephone;
###LogSD	my $phone = Log::Shiras::Telephone->new;
###LogSD	use Log::Shiras::UnhideDebug;
use	Spreadsheet::Reader::Format::FmtDefault;
my  ( 
			$test_instance, $capture, $x, @answer,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				target_encoding						excel_region
				defined_excel_translations
			);
my  		@class_methods = qw(
				get_target_encoding					set_target_encoding
				has_target_encoding					get_excel_region					
				set_excel_region					total_defined_excel_formats
				get_defined_excel_format			set_defined_excel_formats
				change_output_encoding
			);
my			$question_list =[
				undef, 'gr',
				"\xc4\x80",
				'utf8',
				"\xc4\x80",
				undef,
				[ 0x00, 0x01, 0x02, '0x03', 0x04, 0x05, 0x06, 0x07, 8, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, '0x14', 0x15, 0x16, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x31, ]
			];
my			$answer_list =[
				'en', 'gr',
				"\xc4\x80",
				'utf8',
				"\x{100}",
				37,
				[ 'General', '0', '0.00', '#,##0', '#,##0.00', '$#,##0_);($#,##0)', '$#,##0_);[Red]($#,##0)', '$#,##0.00_);($#,##0.00)', '$#,##0.00_);[Red]($#,##0.00)', '0%', '0.00%', '0.00E+00', '# ?/?', '# ??/??', 'yyyy-mm-dd', 'd-mmm-yy', 'd-mmm', 'mmm-yy', 'h:mm AM/PM', 'h:mm:ss AM/PM', 'h:mm', 'h:mm:ss', 'm-d-yy h:mm', '#,##0_);(#,##0)', '#,##0_);[Red](#,##0)', '#,##0.00_);(#,##0.00)', '#,##0.00_);[Red](#,##0.00)', '_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)', '_($*#,##0_);_($*(#,##0);_($*"-"_);_(@_)', '_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)', '_($*#,##0.00_);_($*(#,##0.00);_($*"-"??_);_(@_)', 'mm:ss', '[h]:mm:ss', 'mm:ss.0', '##0.0E+0', '@', '@', ]
			];
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$test_instance	=	build_instance(
									package	=> 'FmtDefaultTest',
			###LogSD				roles	=>[ 
			###LogSD					'Log::Shiras::LogSpace'
			###LogSD				],
									superclasses =>[
										'Spreadsheet::Reader::Format::FmtDefault',
									],
			###LogSD				log_space	=> 'Test',
									#~ epoch_year	=> 1904,
								);
}										"Prep a test FmtDefault instance";
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that Spreadsheet::Reader::Format::FmtDefault has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;
###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
			my $position = 0;
is			$test_instance->get_excel_region, $answer_list->[$position],
										,"|position - $position| Check that the region is set to: $answer_list->[$position]";
			$position++;
is			$test_instance->set_excel_region( $question_list->[$position] ), $answer_list->[$position],
										,"|position - $position| Change the region and see what happens";
is			$test_instance->has_target_encoding, '',
										,"................Check that no target encoding is set";
			$position++;
is			$test_instance->change_output_encoding(  $question_list->[$position] ), $answer_list->[$position],
										,"|position - $position| ..and check that no encoding changes occur";
			$position++;
is			$test_instance->set_target_encoding(  $question_list->[$position] ), $question_list->[$position] ,
										,"|position - $position| Set the target encoding to: $question_list->[$position]";
is			$test_instance->get_target_encoding, $question_list->[$position] ,
										,"..................and check that it is known as: $question_list->[$position]";
			$position++;
is			$test_instance->change_output_encoding(  $question_list->[$position] ), $answer_list->[$position],
										,"|position - $position| ..and check that output is now encoded differently";
			$position++;
is			$test_instance->total_defined_excel_formats, $answer_list->[$position],
										,"|position - $position| Check the total number of stored excel formats";
			$position++;
			$x = 0;
			for my $question ( @{$question_list->[$position]} ){
is			$test_instance->get_defined_excel_format( $question ), $answer_list->[$position]->[$x],
										,"|position - $position| Check that format place -$question- has format: $answer_list->[$position]->[$x]";
			$x++;
			}
is			$test_instance->get_defined_excel_format( '0x17' ), undef,
										,"...............Check that format place -0x17- (empty) does not have a format";
			my	$format_ref;
				$format_ref->[23] = 'foo';
ok			$test_instance->set_defined_excel_formats( $format_ref ),
										,"...............set the format ref position -23- to: foo";
is			$test_instance->get_defined_excel_format( '0x17' ), 'foo',
										,"...............and check that format place -0x17- (now) does have the format: foo";
is			$test_instance->get_defined_excel_format( 24 ), undef,
										,"...............Check that format place -24- (empty) does not have a format";
				$format_ref = undef;
				$format_ref->{'0x18'} = 'bar';
ok			$test_instance->set_defined_excel_formats( $format_ref ),
										,"...............set the format ref position -0x18- to: bar";
is			$test_instance->get_defined_excel_format( '0x17' ), 'foo',
										,"...............and check that format place -24- (now) does have the format: bar";

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