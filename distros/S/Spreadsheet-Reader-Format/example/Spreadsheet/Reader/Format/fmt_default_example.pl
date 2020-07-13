#!/usr/bin/env perl
use	lib
		'../../../../lib',
		'../../../../../Log-Shiras/lib',
	;
use Spreadsheet::Reader::Format::FmtDefault;
my		$formatter = Spreadsheet::Reader::Format::FmtDefault->new(
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
