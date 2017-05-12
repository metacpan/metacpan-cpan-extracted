package Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::WorkbookFileInterface-$VERSION";

use	Moose::Role;
requires qw( get_file_type extract_file loaded_correctly );

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'WorkbookFileInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::WorkbookFileInterface - XLSX and XML workbook file interface

=head1 SYNOPSIS

	use	MooseX::ShortCut::BuildInstance v1.8 qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::WorkbookFileInterface;
	use Spreadsheet::Reader::ExcelXML::ZipReader;
	my $test_file = 'TestBook.xlsx';
	my $test_instance = build_instance(
			package => 'ZipWorkbookFileInterface',
			superclasses => ['Spreadsheet::Reader::ExcelXML::ZipReader'],
			file => $test_file,
			add_roles_in_sequence =>[
				'Spreadsheet::Reader::ExcelXML::WorkbookFileInterface',
			],
		);

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module (role) is provided as a way to standardize access to or L<interface
|http://www.cs.utah.edu/~germain/PPS/Topics/interfaces.html> with base workbook files
accross zip and flat xml types.  It doesn't provide any functionality itself it just
provides requirements for any built classes so a consumer of this interface will be
able to use a consistent interface.  The two most likely base classes for this interface
are;

L<Spreadsheet::Reader::ExcelXML::ZipReader>

L<Spreadsheet::Reader::ExcelXML::XMLReader>

=head2 Required Methods

These are the methods required by the role.  A link to the Zip implementation of these
methods is provided.  The XML versions are documented in the ~::XMLReader.

L<Spreadsheet::Reader::ExcelXML::ZipReader/get_file_type>

L<Spreadsheet::Reader::ExcelXML::ZipReader/loaded_correctly>

L<Spreadsheet::Reader::ExcelXML::ZipReader/extract_file( $zip_sub_file )>

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
