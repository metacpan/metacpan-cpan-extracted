#!/usr/bin/env perl
package MyPackage;
use Moose;
	
use lib '../../../../../lib';
with	'Spreadsheet::XLSX::Reader::LibXML::FmtDefault';
# call 'with' a second time to ensure that the prior methods are recorded
with	'Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings';

package main;

my	$parser 		= MyPackage->new( epoch_year => 1904 );
my	$conversion	= $parser->parse_excel_format_string( '[$-409]dddd, mmmm dd, yyyy;@' );
print 'For conversion named: ' . $conversion->name . "\n";
for my	$unformatted_value ( '7/4/1776 11:00.234 AM', 0.112311 ){
	print "Unformatted value: $unformatted_value\n";
	print "..coerces to: " . $conversion->assert_coerce( $unformatted_value ) . "\n";
}