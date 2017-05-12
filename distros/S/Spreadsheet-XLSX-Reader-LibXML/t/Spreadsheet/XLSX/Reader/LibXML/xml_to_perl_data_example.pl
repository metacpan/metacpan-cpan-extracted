#!/usr/bin/env perl
$|=1;
use lib '../../../../../lib';
use Data::Dumper;
use	MooseX::ShortCut::BuildInstance qw( build_instance );
use	Spreadsheet::XLSX::Reader::LibXML::XMLReader;
use	Spreadsheet::XLSX::Reader::LibXML::Error;
use	Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
my  $test_file = '../../../../test_files/xl/sharedStrings.xml';
my  $test_instance	=	build_instance(
		package => 'TestIntance',
		superclasses =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader', ],
		add_roles_in_sequence =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData', ],
		file => $test_file,
		error_inst => Spreadsheet::XLSX::Reader::LibXML::Error->new,
		add_attributes =>{
			empty_return_type =>{
				reader => 'get_empty_return_type',
			},
		},
	);
$test_instance->advance_element_position( 'si', 16 );# Go somewhere interesting
print Dumper( $test_instance->parse_element ) . "\n";