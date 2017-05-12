package Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface-$VERSION";

use	Moose::Role;
requires qw(
	get_sheet_lookup			get_worksheet_list			get_chartsheet_list
	loaded_correctly
);

###LogSD	requires 'get_log_space', 'get_all_space';

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'WorkbookRelsInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface - Workbook rels file interface

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Data::Dumper;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Types::Standard qw( HashRef );
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels;
	use Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface;
	my	$test_file = 't/test_files/xl/_rels/workbook.xml.rels';
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
	print Dumper( $rels_instance->get_worksheet_list );

	###########################
	# SYNOPSIS Screen Output
	# 01: $VAR1 = [
	# 01: 	'Sheet2',
	# 01: 	'Sheet5',
	# 01:   'Sheet1'
	# 01: ]
	###########################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module (role) is provided as a way to standardize access to or L<interface
|http://www.cs.utah.edu/~germain/PPS/Topics/interfaces.html> with base rels data files
containing workbook level relationships between zip sub file types.  It doesn't provide
any functionality itself it just provides requirements for any built classes so a consumer
of this interface will be able to use a consistent interface.  The base class will generally
be;

L<Spreadsheet::Reader::ExcelXML::XMLReader>

The unique functionality is generally provided by;

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels>

L<Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookRels>

=head2 Required Methods

These are the methods required by the role.  A link to the Zip implementation of these
methods is provided.  The XML versions are documented in ~::XMLReader::WorkbookRels.

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_sheet_lookup>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_worksheet_list>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_chartsheet_list>

L<Spreadsheet::Reader::ExcelXML::XMLReader/loaded_correctly>

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Nothing currently

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

This software is copyrighted (c) 2016 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::Reader::ExcelXML> - the package

=back

=head1 SEE ALSO

=over

L<Spreadsheet::Read> - generic Spreadsheet reader

L<Spreadsheet::ParseExcel> - Excel binary version 2003 and earlier (.xls files)

L<Spreadsheet::XLSX> - Excel version 2007 and later

L<Spreadsheet::ParseXLSX> - Excel version 2007 and later

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
