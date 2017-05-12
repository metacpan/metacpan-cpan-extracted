#!/usr/bin/env perl
use Data::Dumper;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta;
use Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface;
my	$test_file = '../../../../t/test_files/xl/workbook.xml';
my	$test_instance =  build_instance(
		package	=> 'WorkbookMetaInterface',
		superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		add_roles_in_sequence =>[ 
			'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta',
			'Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface',
		],
		file => $test_file,
	);
for my $test_method (qw( get_epoch_year get_sheet_lookup get_rel_lookup get_id_lookup )){
	print Dumper( $test_instance->$test_method )
}