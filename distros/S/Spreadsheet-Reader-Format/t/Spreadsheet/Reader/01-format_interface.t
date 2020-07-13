#########1 Test File for Spreadsheet::Reader::Format        6#########7#########8#########9
#!/usr/bin/env perl
BEGIN{ $ENV{PERL_TYPE_TINY_XS} = 0; }
$| = 1;

use	Test::Most tests => 662;
use	Test::Moose;
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );#
use Types::Standard qw( HasMethods Int );
use	lib
		'../../../../Log-Shiras/lib',
		'../../../lib',;
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
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::Format;
my  ( 
			$test_instance, $workbook_instance, $capture, $x, @answer, $coercion,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				target_encoding						excel_region
				defined_excel_translations			workbook_inst
				cache_formats						datetime_dates
				european_first
			);
my  		@class_methods = qw(
				get_target_encoding					set_target_encoding
				has_target_encoding					get_excel_region					
				set_excel_region					total_defined_excel_formats
				get_defined_excel_format			set_defined_excel_formats
				change_output_encoding				get_defined_conversion
				parse_excel_format_string			set_error
				get_epoch_year						set_workbook_inst
				get_cache_behavior					set_cache_behavior
				get_date_behavior					set_date_behavior
				set_european_first					get_european_first
			);
my			$question_list =[
				[
					['[$-409]d-mmm-yy;@',undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					['[$-409]dddd, mmmm dd, yyyy;@',undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					['#,##0E+0',undef,'1','-200','2000','-2000001','2050','-20050','0.0000002','-0.00000000004125'],
					['# ???/???',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ?/2',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ?/4',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ?/8',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ??/16',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ??/10',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ???/100',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['# ??????/??????',undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222','6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181','12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667','0.000005','-0.00001','0.9999999','0.019','-0.999'],
					['d-mmmm-yy',undef,'7/4/1776','4/7/1776','7/4/76','4/7/76', '5-30-11 0:00'],
					['d-mmmm-yy',undef,'7/4/1776','4/7/1776','7/4/76','4/7/76'],
					[ "It's a mad mad world" ],
				],				
				[
					[ 'Hello World', "It's a mad mad world" ],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.115111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','2','-0.1','0.03','0.005','0.00004','0.00005'],
					[undef,'1','2','-0.1','0.03','0.005','0.00004','0.00005'],
					[undef,'1','-200','2000','-2000001','2005','-20005','0.000002','-0.00000000004125'],
					[undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222',
						'6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181',
						'12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667',
						'0.000005','-0.00001','0.9999999','0.019','-0.999'],
					[undef,'0.3333333','-1.6666666','2.1666666','-3.8333333','4.1111111','-5.2222222',
						'6.4444444','-7.5555555','8.7777777','-9.8888888','10.09090909','-11.1818181',
						'12.0833333','-13.4166666','0.12345678','-0.125','0.75','-0.0416666666666667',
						'0.000005','-0.00001','0.9999999','0.019','-0.999'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					undef,								undef,
					undef,								undef,
					undef,								undef,
					undef,								undef,
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'1','1.11511111111111','-111111111111115','1.5','-1234.567','59','-60'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'7/4/1776 11:00.234 AM','0.112311','60.99112311','1.500112311','55.0000102311','59.112311','60.345112311'],
					[undef,'1','-200','2000','-2000001','2050','-20050','0.0000002','-0.00000000004125'],
					[ 'Hello World', "It's a mad mad world" ],
				],
			];
my			$answer_list =[
				[
					['DATESTRING_0',undef,'4-Jul-76','1-Jan-04','1-Mar-04','2-Jan-04','25-Feb-04','29-Feb-04','1-Mar-04'],
					['DATESTRING_1',undef,'Thursday, July 04, 1776','Friday, January 01, 1904','Tuesday, March 01, 1904','Saturday, January 02, 1904','Thursday, February 25, 1904','Monday, February 29, 1904','Tuesday, March 01, 1904'],
					['SCIENTIFIC_2',undef,'1E+0','-200E+0','2,000E+0','-200E+4','2,050E+0','-2E+4','20E-8','-41E-12'],
					['FRACTION_3',undef,'1/3','-1 2/3','2 1/6','-3 5/6','4 1/9','-5 2/9','6 4/9','-7 5/9','8 7/9','-9 8/9','10 1/11','-11 2/11','12 1/12','-13 5/12','10/81','-1/8','3/4','-1/24','0','0','1','11/579','-998/999'],
					['FRACTION_4',undef,'1/2','-1 1/2','2','-4','4','-5','6 1/2','-7 1/2','9','-10','10','-11','12','-13 1/2','0','0','1','0','0','0','1','0','-1'],
					['FRACTION_5',undef,'1/4','-1 3/4','2 1/4','-3 3/4','4','-5 1/4','6 2/4','-7 2/4','8 3/4','-10','10','-11 1/4','12','-13 2/4','0','-1/4','3/4','0','0','0','1','0','-1'],
					['FRACTION_6',undef,'3/8','-1 5/8','2 1/8','-3 7/8','4 1/8','-5 2/8','6 4/8','-7 4/8','8 6/8','-9 7/8','10 1/8','-11 1/8','12 1/8','-13 3/8','1/8','-1/8','6/8','0','0','0','1','0','-1'],
					['FRACTION_7',undef,'5/16','-1 11/16','2 3/16','-3 13/16','4 2/16','-5 4/16','6 7/16','-7 9/16','8 12/16','-9 14/16','10 1/16','-11 3/16','12 1/16','-13 7/16','2/16','-2/16','12/16','-1/16','0','0','1','0','-1'],
					['FRACTION_8',undef,'3/10','-1 7/10','2 2/10','-3 8/10','4 1/10','-5 2/10','6 4/10','-7 6/10','8 8/10','-9 9/10','10 1/10','-11 2/10','12 1/10','-13 4/10','1/10','-1/10','8/10','0','0','0','1','0','-1'],
					['FRACTION_9',undef,'33/100','-1 67/100','2 17/100','-3 83/100','4 11/100','-5 22/100','6 44/100','-7 56/100','8 78/100','-9 89/100','10 9/100','-11 18/100','12 8/100','-13 42/100','12/100','-13/100','75/100','-4/100','0','0','1','2/100','-1'],
					['FRACTION_10',undef,'1/3','-1 2/3','2 1/6','-3 5/6','4 1/9','-5 2/9','6 4/9','-7 5/9','8 7/9','-9 8/9','10 1/11','-11 2/11','12 1/12','-13 5/12','10/81','-1/8','3/4','-1/24','1/200000','-1/100000','1','19/1000','-999/1000'],
					['DATESTRING_11',undef,'4-July-76','7-April-76','4-July-76','7-April-76', '30-May-11'],
					['DATESTRING_11',undef,'7-April-76','4-July-76','7-April-76','4-July-76',],
					[ undef, qr/Attempts to use string \|It's a mad mad world\| as an excel custom format failed. Contact the author jandrew\@cpan \(\.org\) if you feel there is an error/ ],
				],
				[
					[ 'General', 'Hello World', "It's a mad mad world" ],
					['0',undef,'1','1','-111111111111115','2','-1235','59','-60'],
					['0.00',undef,'1.00','1.12','-111111111111115.00','1.50','-1234.57','59.00','-60.00'],
					['#,##0',undef,'1','1','-111,111,111,111,115','2','-1,235','59','-60'],
					['#,##0.00',undef,'1.00','1.12','-111,111,111,111,115.00','1.50','-1,234.57','59.00','-60.00'],
					['$#,##0_);($#,##0)',undef,'$1','$1','($111,111,111,111,115)','$2','($1,235)','$59','($60)'],
					['$#,##0_);[Red]($#,##0)',undef,'$1','$1','($111,111,111,111,115)','$2','($1,235)','$59','($60)'],
					['$#,##0.00_);($#,##0.00)',undef,'$1.00','$1.12','($111,111,111,111,115.00)','$1.50','($1,234.57)','$59.00','($60.00)'],
					['$#,##0.00_);[Red]($#,##0.00)',undef,'$1.00','$1.12','($111,111,111,111,115.00)','$1.50','($1,234.57)','$59.00','($60.00)'],
					['0%',undef,'100%','200%','-10%','3%','1%','0%','0%'],
					['0.00%',undef,'100.00%','200.00%','-10.00%','3.00%','0.50%','0.00%','0.01%'],
					['0.00E+00',undef,'1.00E+00','-2.00E+02','2.00E+03','-2.00E+06','2.01E+03','-2.00E+04','2.00E-06','-4.13E-11'],
					['# ?/?',undef,'1/3','-1 2/3','2 1/6','-3 5/6','4 1/9','-5 2/9','6 4/9','-7 5/9','8 7/9',
						'-9 8/9','10 1/9','-11 1/6','12 1/9','-13 3/7','1/8','-1/8','3/4','0','0','0','1','0','-1'],
					['# ??/??',undef,'1/3','-1 2/3','2 1/6','-3 5/6','4 1/9','-5 2/9','6 4/9','-7 5/9','8 7/9',
						'-9 8/9','10 1/11','-11 2/11','12 1/12','-13 5/12','10/81','-1/8','3/4','-1/24','0','0','1','1/53','-1'],
					['yyyy-mm-dd',undef,'1776-07-04','1904-01-01','1904-03-01','1904-01-02','1904-02-25','1904-02-29','1904-03-01'],
					['d-mmm-yy',undef,'4-Jul-76','1-Jan-04','1-Mar-04','2-Jan-04','25-Feb-04','29-Feb-04','1-Mar-04'],
					['d-mmm',undef,'4-Jul','1-Jan','1-Mar','2-Jan','25-Feb','29-Feb','1-Mar'],
					['mmm-yy',undef,'Jul-76','Jan-04','Mar-04','Jan-04','Feb-04','Feb-04','Mar-04'],
					['h:mm AM/PM',undef,'11:00 AM','2:41 AM','11:47 PM','12:00 PM','12:00 AM','2:41 AM','8:16 AM'],
					['h:mm:ss AM/PM',undef,'11:00:00 AM','2:41:44 AM','11:47:13 PM','12:00:10 PM','12:00:01 AM','2:41:44 AM','8:16:58 AM'],
					['h:mm',undef,'11:00','2:41','23:47','12:00','0:00','2:41','8:16'],
					['h:mm:ss',undef,'11:00:00','2:41:44','23:47:13','12:00:10','0:00:01','2:41:44','8:16:58'],
					['m-d-yy h:mm',undef,'7-4-76 11:00','1-1-04 2:41','3-1-04 23:47','1-2-04 12:00','2-25-04 0:00','2-29-04 2:41','3-1-04 8:16'],
					undef,								undef,
					undef,								undef,
					undef,								undef,
					undef,								undef,
					['#,##0_);(#,##0)',undef,'1','1','(111,111,111,111,115)','2','(1,235)','59','(60)'],
					['#,##0_);[Red](#,##0)',undef,'1','1','(111,111,111,111,115)','2','(1,235)','59','(60)'],
					['#,##0.00_);(#,##0.00)',undef,'1.00','1.12','(111,111,111,111,115.00)','1.50','(1,234.57)','59.00','(60.00)'],
					['#,##0.00_);[Red](#,##0.00)',undef,'1.00','1.12','(111,111,111,111,115.00)','1.50','(1,234.57)','59.00','(60.00)'],
					['_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)',undef,'1','1','(111,111,111,111,115)','2','(1,235)','59','(60)'],
					['_($*#,##0_);_($*(#,##0);_($*"-"_);_(@_)',undef,'$1','$1','$(111,111,111,111,115)','$2','$(1,235)','$59','$(60)'],
					['_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)',undef,'1.00','1.12','(111,111,111,111,115.00)','1.50','(1,234.57)','59.00','(60.00)'],
					['_($*#,##0.00_);_($*(#,##0.00);_($*"-"??_);_(@_)',undef,'$1.00','$1.12','$(111,111,111,111,115.00)','$1.50','$(1,234.57)','$59.00','$(60.00)'],
					['mm:ss',undef,'00:00','41:44','47:13','00:10','00:01','41:44','16:58'],
					['[h]:mm:ss',undef,'-1117548:59:59','2:41:44','1463:47:13','36:00:10','1320:00:01','1418:41:44','1448:16:58'],
					['mm:ss.0',undef,'00:00.2',['41:43.7','41:43.6'],'47:13.0','00:09.7',['00:00.9','00:00.8'],['41:43.7','41:43.6'],'16:57.7'],
					['##0.0E+0',undef,'1.0E+0','-200.0E+0','2.0E+3','-2.0E+6','2.1E+3','-20.1E+3','200.0E-9','-41.3E-12'],
					[ '@', 'Hello World', "It's a mad mad world" ],
				],
			];
###LogSD		$phone->talk( level => 'info', message => [ "easy questions ..." ] );
lives_ok{
			$test_instance	=	build_instance(
									package	=> 'FormatInterfaceTest',
									superclasses =>[
										'Spreadsheet::Reader::Format::FmtDefault'
									],
									add_roles_in_sequence =>[
										'Spreadsheet::Reader::Format::ParseExcelFormatStrings',
										'Spreadsheet::Reader::Format'
									],
									_alt_epoch_year => 1904
###LogSD							log_space	=> 'Test',
								);
}										"Prep a test FormatInterfaceTest instance";
map{ 
has_attribute_ok
			$test_instance, $_,
										"Check that FormatInterfaceTest has the -$_- attribute"
} 			@class_attributes;
map{
can_ok		$test_instance, $_,
} 			@class_methods;

###LogSD		$phone->talk( level => 'trace', message => [ 'Test instance:', $test_instance ] );
###LogSD		$phone->talk( level => 'info', message => [ "hardest questions ..." ] );
ok			$coercion = $test_instance->get_defined_conversion( 14, 'TheBestDate' ),
										"Get the Type::Tiny conversion for position -14- and call it |TheBestDate|";
###LogSD		$phone->talk( level => 'warn', message => [ "coercion is: " . $coercion->display_name ] );
is			$coercion->display_name, 'TheBestDate',
										'Check that the coercion is named |TheBestDate|';
			my $test_group = 0;
explain									"Testing some posible user defined format strings";
			no warnings 'uninitialized';
			for my $position ( 0 .. $#{$question_list->[$test_group]} ){
			if( $position == 12 ){
lives_ok{	$test_instance->set_european_first( 1 ) }
										"Prioritize European style (DD-MM-YY) string parsing";
			}
###LogSD	my $format_string_num = 100; my $col = 2;
###LogSD	if( $position == $format_string_num ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}
###LogSD		$phone->talk( level => 'debug', message => [ 'processing excel format string: ' . $question_list->[$test_group]->[$position]->[0]  ] );
is			eval{ $coercion = $test_instance->parse_excel_format_string( $question_list->[$test_group]->[$position]->[0] ) }, $answer_list->[$test_group]->[$position]->[0],
										"Build a coercion with excel format string: $question_list->[$test_group]->[$position]->[0]";
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'warn',
###LogSD			},
###LogSD		} );
			if( ref $answer_list->[$test_group]->[$position]->[1] eq 'Regexp' ){
like		$@, $answer_list->[$test_group]->[$position]->[1],
										"Check for the correct error code on an expected fail";
			}else{
###LogSD		$phone->talk( level => 'debug', message => [ 'Built a coercion named : ' . $coercion->display_name  ] );
			for my $row_pos ( 1 .. $#{$question_list->[$test_group]->[$position]} ){
###LogSD	if( $position == $format_string_num and $row_pos == $col ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}elsif( $position == $format_string_num and $row_pos > $col){
###LogSD		exit 1;
###LogSD	}
is			$coercion->assert_coerce( $question_list->[$test_group]->[$position]->[$row_pos] ), $answer_list->[$test_group]->[$position]->[$row_pos],
										"Testing the coercion number -$position-  string -$question_list->[$test_group]->[$position]->[0]- to see if row position -$row_pos- " .
											"|$question_list->[$test_group]->[$position]->[$row_pos]|" . 
											" coerces to: $answer_list->[$test_group]->[$position]->[$row_pos]";
			}
###LogSD	if( $position >= $format_string_num ){
###LogSD		exit 1;
###LogSD	}
			}
			}
ok			$test_instance->set_date_behavior( 1 ),
										"Set the date output to privide DateTime objects rather than strings";
			my	$date_string = 'yyyy-mm-dd';
			my	$time		= 55.0000102311;
ok				$coercion = $test_instance->parse_excel_format_string( $date_string ),
										"Build a coercion with excel format string: $date_string";
is			ref $coercion->assert_coerce( $time ), 'DateTime',
										"Checking that a DateTime object was returned";
is			$coercion->assert_coerce( $time ), '1904-02-25T00:00:01',
										"Checking that the date and time are correct: 1904-02-25T00:00:01";
explain									"Test default coercion positions provided by Spreadsheet::XLSX::Reader::LibXML::FmtDefault";
is			$test_instance->set_date_behavior( 0 ), 0,
										"Set the date output to privide strings again";
lives_ok{	$test_instance->set_european_first( 0 ) }
										"Prioritize US style (MM-DD-YY) string parsing";
			$test_group++;
#~ lives_ok{ # Only uncomment this to clear up if the previous run is polluting the second run
			#~ $test_instance	=	ParseExcelFormatStringsTest->new(
									#~ workbook_inst => $workbook_instance,
#~ ###LogSD							log_space	=> 'Test',
								#~ );
#~ }										"Prep a new test ParseExcelFormatStrings instance";
			for my $position ( 0 .. $#{$question_list->[$test_group]} ){
			if( $answer_list->[$test_group]->[$position] ){

is			$test_instance->get_defined_excel_format( $position ), $answer_list->[$test_group]->[$position]->[0],
										"Check that excel default position -$position- contains: $answer_list->[$test_group]->[$position]->[0]";
###LogSD	my $start_pos = 41;
###LogSD	if( $position == $start_pos ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}
ok			my $coercion = $test_instance->parse_excel_format_string( $test_instance->get_defined_excel_format( $position ) ),
										,"..and try to turn it into a Type::Tiny coercion";
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'warn',
###LogSD			},
###LogSD		} );
			for my $row_pos ( 1 .. $#{$answer_list->[$test_group]->[$position]} ){
###LogSD	my $start_row =  3;
###LogSD	if( $position == $start_pos and $row_pos == $start_row ){
###LogSD		$operator->add_name_space_bounds( {
###LogSD			UNBLOCK =>{
###LogSD				log_file => 'trace',
###LogSD			},
###LogSD		} );
###LogSD	}elsif( $position == $start_pos + 1 ){
###LogSD		exit 1;
###LogSD	}
			my $answer = $answer_list->[$test_group]->[$position]->[$row_pos];
			if (ref $answer eq "ARRAY") {
				use version;
				if (version->parse($DateTime::VERSION) <= version->parse('1.44')) { # Fixes issue #1 
					$answer = $answer->[0];
				}
				else {
					$answer = $answer->[1];
				}
			}
is			$coercion->assert_coerce( $question_list->[$test_group]->[$position]->[$row_pos - 1] ), $answer,
										,"Testing the excel default coercion -$position- to see if |$question_list->[$test_group]->[$position]->[$row_pos - 1]|" . 
											" coerces to: $answer";
			} } }
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