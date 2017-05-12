#!/usr/bin/env perl
use	lib
		'../../../../../lib',
		'../../../../../../Log-Shiras/lib',
	;
use Spreadsheet::XLSX::Reader::LibXML::FmtDefault;
my		$formatter = Spreadsheet::XLSX::Reader::LibXML::FmtDefault->new(
					target_encoding => 'latin1',
					epoch_year		=> 1904,
				);
my 		$excel_format_string = $formatter->get_defined_excel_format( 0x0E );
print 	$excel_format_string . "\n";
		$excel_format_string = $formatter->get_defined_excel_format( '0x0E' );
print 	$excel_format_string . "\n";
		$excel_format_string = $formatter->get_defined_excel_format( 14 );
print	$excel_format_string . "\n";
		$formatter->set_defined_excel_formats( '0x17' => 'MySpecialFormat' );#Won't really translate!
		$excel_format_string = $formatter->get_defined_excel_format( 23 );
print 	$excel_format_string . "\n";
my		$conversion	= $formatter->parse_excel_format_string( '[$-409]dddd, mmmm dd, yyyy;@' );
print 	'For conversion named: ' . $conversion->name . "\n";
for my	$unformatted_value ( '7/4/1776 11:00.234 AM', 0.112311 ){
	print "Unformatted value: $unformatted_value\n";
	print "..coerces to: " . $conversion->assert_coerce( $unformatted_value ) . "\n";
}
