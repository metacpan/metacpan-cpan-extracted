#!/usr/bin/env perl
use MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HashRef );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps;
use Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface;
my	$test_file = '../../../../t/test_files/TestBook.xml';
my	$extractor_instance = build_instance(
		superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		package => 'ExtractorInstance',
		file => $test_file,
		add_roles_in_sequence =>[ 
			'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
		],
	);
my	$file_handle = $extractor_instance->extract_file( qw( DocumentProperties ) );
my	$test_instance = build_instance(
		superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		package	=> 'WorkbookPropsInterface',
		add_roles_in_sequence =>[ 
			'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps',
			'Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface',
		],
		file => $file_handle,# No extractor needed for zip files so call 't/test_files/docProps/core.xml' directly
	);
for my $test_method (qw( get_creator get_modified_by get_date_created get_date_modified )){
	print $test_instance->$test_method . "\n";
}