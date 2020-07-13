#!/usr/bin/env perl
use lib 
	'../../../lib',
	'../../../../p5-spreadsheet-reader-excelxml/lib',
	;
use MooseX::ShortCut::BuildInstance 'build_instance';
use Spreadsheet::Reader::Format;
use Spreadsheet::Reader::Format::FmtDefault;
use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
use Spreadsheet::Reader::ExcelXML;
my $formatter = build_instance(
	package => 'FormatInstance',
	# The base United State localization settings - Inject your customized format class here
	superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
	# ~ParseExcelFormatStrings => The Excel string parser generation engine
	# ~Format => The top level interface defining minimum compatability requirements
	add_roles_in_sequence =>[qw(
		Spreadsheet::Reader::Format::ParseExcelFormatStrings
		Spreadsheet::Reader::Format
	)],
	target_encoding => 'latin1',# Adjust the string output encoding here
	datetime_dates	=> 1,
);

# Use in a standalone manner
my	$date_string = 'yyyy-mm-dd';
my	$time		= 55.0000102311;
# Build a coercion with excel format string: $date_string
my	$coercion	= $formatter->parse_excel_format_string( $date_string );
# Checking that a DateTime object was returned
print ref( $coercion->assert_coerce( $time ) ) . "\n";
# Checking that the date and time are presented correctly: 1904-02-25T00:00:01
print $coercion->assert_coerce( $time ) . "\n";

# Set specific default custom formats here (for use in an excel parser)
$formatter->set_defined_excel_formats( 0x2C => 'MyCoolFormatHere' );

# Use the formatter like Spreadsheet::ParseExcel
my $parser	= Spreadsheet::Reader::ExcelXML->new;
my $workbook = $parser->parse( '../t/test_files/TestBook.xlsx', $formatter );
