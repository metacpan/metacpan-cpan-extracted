package Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML-$VERSION";

use	Moose::Role;
requires qw( has_progid progid good_load );
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Testing if the flat XML workbook opened correctly", $self->has_progid ] );

	# Check progid setting
	if( !$self->has_progid ){
		###LogSD	$phone->talk( level => 'warn', message => [
		###LogSD		'No progid recorded - bad xml base file' ] );
		$self->good_load( 0 );
	}elsif( $self->progid eq 'Excel.Sheet' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'Found the correct progid: Excel.Sheet' ] );
		$self->good_load( 1 );
	}else{
		###LogSD	$phone->talk( level => 'warn', message => [
		###LogSD		'Bad progid: ' . $self->progid ] );
		$self->good_load( 0 );
	}
	return 1;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookXML -  Workbook flat XML file test

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use MooseX::ShortCut::BuildInstance qw( build_instance );
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

	###########################
	# SYNOPSIS Screen Output
	# 01: <?xml version="1.0"?><Styles><Style ss:ID="Default"/ ~~ / ss:ID="s22"><Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="14" ss:Color="#000000"
	###########################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This is the XML based file adaptor for reading the base xml flat file and determining
if it has the expected attribute in the mso-application header indicating it is a
L<SpreadsheetML|https://en.wikipedia.org/wiki/SpreadsheetML> format file.  (
progid="Excel.Sheet" ) When combined with the generic XML reader and the
WorkbookFileInterface interface it makes a complete base xml flat file reader.

=head2 Required Methods

These are the methods required by the role.  A link to the default implementation of
these methods is provided.

L<Spreadsheet::Reader::ExcelXML::XMLReader/progid>

L<Spreadsheet::Reader::ExcelXML::XMLReader/has_progid>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load( $state )>

=head2 Methods

These are the methods provided by this role (only).

=head3 load_unique_bits

=over

B<Definition:> This role is meant to run on top of L<Spreadsheet::Reader::ExcelXML::XMLReader>.
When it does the reader will call this function as available when it first starts the file.
This particular version only tests for the correct attribute (progid="Excel.Sheet") in the
'mso-application' header.

B<Accepts:> nothing

B<Returns:> nothing

=back

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
