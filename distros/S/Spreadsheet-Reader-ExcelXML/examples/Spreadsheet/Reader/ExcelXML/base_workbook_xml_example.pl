#!/usr/bin/env perl
use MooseX::ShortCut::BuildInstance qw( build_instance );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::XMLReader;
use	Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML;
use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
my	$test_file = '../../../../t/test_files/TestBook.xml';
my	$test_instance =  build_instance(
		package	=> 'WorkbookFileInterface',
		superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		add_roles_in_sequence =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML',
			'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
		],
		file => $test_file,
	);
my $sub_file = $test_instance->extract_file( 'Styles' );
print $sub_file->getline;