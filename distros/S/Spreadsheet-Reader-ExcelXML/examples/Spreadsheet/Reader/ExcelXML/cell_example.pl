#!/usr/bin/env perl
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::Cell;
use Spreadsheet::Reader::ExcelXML::Error;

my	$cell_inputs = {
		'cell_hidden' => 0,
		'r' => 'A2',
		'cell_row' => 1,
		'cell_unformatted' => 'Hello',
		'cell_col' => 0,
		'cell_xml_value' => 'Hello',
		'cell_type' => 'Text',
		'error_inst' => Spreadsheet::Reader::ExcelXML::Error->new,
	};
my	$cell_instance = Spreadsheet::Reader::ExcelXML::Cell->new( $cell_inputs );
print "Cell value is: " . $cell_instance->value . "\n";