package Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface-$VERSION";

use	Moose::Role;
requires qw(
	get_creator				get_modified_by			get_date_created
	get_date_modified		loaded_correctly
);

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'WorkbookPropsInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface - Workbook docProps file interface

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Types::Standard qw( HashRef );
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
	use Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps;
	use Spreadsheet::Reader::ExcelXML::WorkbookPropsInterface;
	my	$extractor_instance = build_instance(
			superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			package => 'ExtractorInstance',
			file => '../../../../t/test_files/TestBook.xml',
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
	print $test_instance->$get_date_created . "\n";

	###########################
	# SYNOPSIS Screen Output
	# 01: 2013-11-10T08:27:01Z
	###########################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module (role) is provided as a way to standardize access to or L<interface
|http://www.cs.utah.edu/~germain/PPS/Topics/interfaces.html> with base docProps data files
containing workbook level meta data.  It doesn't provide any functionality itself it just
provides requirements for any built classes so a consumer of this interface will be able
to use a consistent interface.  The base class will generally be;

L<Spreadsheet::Reader::ExcelXML::XMLReader>

The unique functionality is generally provided by;

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookProps>

L<Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps>

=head2 Required Methods

These are the methods required by the role.  A link to the Zip implementation of these
methods is provided.  The XML versions are documented in ~::XMLReader::WorkbookRels.

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_creator>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_modified_by>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_date_created>

L<Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookMeta/get_date_modified>

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
