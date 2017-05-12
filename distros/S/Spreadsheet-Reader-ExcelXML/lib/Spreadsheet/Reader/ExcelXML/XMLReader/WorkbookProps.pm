package Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps-$VERSION";

use	Moose::Role;
requires qw(
	current_node_parsed				good_load					close_the_file
	parse_element					squash_node					advance_element_position
);
use Types::Standard qw( is_HashRef StrMatch Str );
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my	$method_lookup = {
		Author				=> '_set_creator',
		LastAuthor			=> '_set_modified_by',
		Created				=> '_set_date_created',
		LastSaved			=> '_set_date_modified',
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the WorkbookPropsInterface unique bits" ] );

	# turn workbook properties into a hashref
	if( (keys %{$self->current_node_parsed})[0] eq 'DocumentProperties' or $self->advance_element_position( 'DocumentProperties' ) ){
		my $properties = $self->squash_node( $self->parse_element );
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"The parsed properties are:", $properties ] );
		for my $header ( keys %$properties ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"processing header: $header" ] );
			if( exists $method_lookup->{$header} ){
				my $method = $method_lookup->{$header};
				my $value = is_HashRef( $properties->{$header} ) ?
								$properties->{$header}->{raw_text} : $properties->{$header};
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Implementing -$method- with value: $value" ] );
				$self->$method( $value );
			}
		}
		$self->good_load( 1 );
	}else{
		###LogSD	$phone->talk( level => 'warn', message =>[ "no cp:coreProperties found" ] );
	}

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Closing out the xml file" ] );
	$self->close_the_file;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _file_creator =>(
		isa		=> Str,
		reader	=> 'get_creator',
		writer	=> '_set_creator',
		clearer	=> '_clear_creator',
	);

has _file_modified_by =>(
		isa		=> Str,
		reader	=> 'get_modified_by',
		writer	=> '_set_modified_by',
		clearer	=> '_clear_modified_by',
	);

has _file_date_created =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> 'get_date_created',
		writer	=> '_set_date_created',
		clearer	=> '_clear_date_created',
	);

has _file_date_modified =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> 'get_date_modified',
		writer	=> '_set_date_modified',
		clearer	=> '_clear_date_modified',
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookProps - Workbook docProps XML file unique reader

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
			file => $file_handle,
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

This is the XML based file adaptor for reading the workbook docProps data and then
updating the general workbook metadata.  The extracted data is accessible through
L<Methods|/Methods>.  The goal of this module is to standardize the outputs of this
metadata from non standard inputs.

=head2 Required Methods

These are the methods required by the role.  A link to the default implementation of
these methods is provided.

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load( $state )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element( [$depth] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node( $node )>

=head2 Methods

These are the methods provided by this role (only).

=head3 load_unique_bits

=over

B<Definition:> This role is meant to run on top of L<Spreadsheet::Reader::ExcelXML::XMLReader>.
When it does the reader will call this function as available when it first starts the file.
Therefore this is where the unique Metadata for this file is found and stored. (in the
attributes)

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 get_creator

=over

B<Definition:> This returns the string stored in the file by Excel for the file creator.

B<Accepts:> nothing

B<Returns:> the creator identification string

=back

=head3 get_modified_by

=over

B<Definition:> This returns the string stored in the file by Excel for the last file
modification entity.

B<Accepts:> nothing

B<Returns:> the identification string for the last entity to modify the file

=back

=head3 get_date_created

=over

B<Definition:> returns the date string for when the file was created in Excel

B<Accepts:> nothing

B<Returns:> a date string

=back

=head3 get_date_modified

=over

B<Definition:> returns the date string for when the file was last modified in Excel

B<Accepts:> nothing

B<Returns:> a date string

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
