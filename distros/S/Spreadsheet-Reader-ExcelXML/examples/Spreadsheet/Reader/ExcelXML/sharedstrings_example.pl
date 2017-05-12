#!/usr/bin/env perl
$|=1;
use Data::Dumper;
use MooseX::ShortCut::BuildInstance qw( build_instance );
use lib '../../../../lib';
#~ use Spreadsheet::Reader::ExcelXML::Workbook;
use Spreadsheet::Reader::ExcelXML::XMLReader;
use Spreadsheet::Reader::ExcelXML::SharedStrings;
use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
use Types::Standard qw( HasMethods Int Str );
use Spreadsheet::Reader::ExcelXML::Error;
my $workbook_instance = build_instance(
										package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
										add_attributes =>{
											error_inst =>{
												isa => 	HasMethods[qw(
																	error set_error clear_error set_warnings if_warn
																) ],
												clearer		=> '_clear_error_inst',
												reader		=> 'get_error_inst',
												required	=> 1,
												handles =>[ qw(
													error set_error clear_error set_warnings if_warn
												) ],
												default => sub{ Spreadsheet::Reader::ExcelXML::Error->new() },
											},
											epoch_year =>{
												isa => Int,
												reader => 'get_epoch_year',
												default => 1904,
											},
											group_return_type =>{
												isa => Str,
												reader => 'get_group_return_type',
												writer => 'set_group_return_type',
												default => 'instance',
											},
										},
										add_methods =>{
											get_empty_return_type => sub{ 1 },
										},
								);
# This whole thing is performed under the hood of
#  Spreadsheet::Reader::ExcelXML
my $file_instance = build_instance(
		package      => 'SharedStringsInstance',
		file         => '../../../../t/test_files/xl/sharedStrings.xml',
		#~ workbook_inst => Spreadsheet::Reader::ExcelXML::Workbook->new,
		workbook_inst => $workbook_instance,
		superclasses =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader'
		],
		add_roles_in_sequence =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
			'Spreadsheet::Reader::ExcelXML::SharedStrings',
		],
	);
	
# Demonstrate output
print Dumper( $file_instance->get_shared_string( 3 ) );
print Dumper( $file_instance->get_shared_string( 12 ) );