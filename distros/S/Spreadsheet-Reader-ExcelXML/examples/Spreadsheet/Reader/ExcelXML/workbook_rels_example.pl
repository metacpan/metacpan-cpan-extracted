#!/usr/bin/env perl
use Data::Dumper;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use Types::Standard qw( HashRef );
use lib '../../../../lib';
use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps;
use Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface;
my	$test_file = '../../../../t/test_files/xl/_rels/workbook.xml.rels';
my	$workbook_instance = build_instance(
		package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		add_attributes =>{
			_rel_lookup =>{
				isa		=> HashRef,
				traits	=> ['Hash'],
				handles	=>{ get_rel_info => 'get', },
				default	=> sub{ {
					'rId2' => 'Sheet5',
					'rId3' => 'Sheet1',
					'rId1' => 'Sheet2'
				} },
			},
			_sheet_lookup =>{
				isa		=> HashRef,
				traits	=> ['Hash'],
				handles	=>{ get_sheet_info => 'get', },
				default	=> sub{ {
					'Sheet1' => {
						'sheet_id' => '1',
						'sheet_position' => 2,
						'sheet_name' => 'Sheet1',
						'is_hidden' => 0,
						'sheet_rel_id' => 'rId3'
					},
					'Sheet2' => {
						'sheet_position' => 0,
						'sheet_name' => 'Sheet2',
						'sheet_id' => '2',
						'sheet_rel_id' => 'rId1',
						'is_hidden' => 0
					},
					'Sheet5' => {
						'sheet_position' => 1,
						'sheet_name' => 'Sheet5',
						'sheet_id' => '3',
						'sheet_rel_id' => 'rId2',
						'is_hidden' => 1
					}
				} },
			},
		},
		add_methods =>{
			get_sheet_names => sub{ [
				'Sheet2',
				'Sheet5',
				'Sheet1'
			] },
		}
	);
my	$test_instance =  build_instance(
		package	=> 'WorkbookRelsInterface',
		superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		add_roles_in_sequence =>[ 
			'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels',
			'Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface',
		],
		file => $test_file,
		workbook_inst => $workbook_instance,
	);
for my $test_method (qw( get_chartsheet_list get_worksheet_list get_sheet_lookup )){
	print Dumper( $test_instance->$test_method )
}