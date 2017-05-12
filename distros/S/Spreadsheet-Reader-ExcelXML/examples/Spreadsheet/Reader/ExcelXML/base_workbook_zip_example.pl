#!/usr/bin/env perl
use MooseX::ShortCut::BuildInstance qw( build_instance );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::ZipReader;
use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
my	$test_file = '../../../../t/test_files/TestBook.xlsx';
my	$test_instance =  build_instance(
		package	=> 'WorkbookFileInterface',
		superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
		add_roles_in_sequence =>[ 
			'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
		],
		file => $test_file,
	);
my $sub_file = $test_instance->extract_file( 'xl/workbook.xml' );
print $sub_file->getline;