package Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
	set_error					close_the_file				advance_element_position
	parse_element				get_group_return_type		squash_node
	start_the_file_over 		current_named_node			good_load

);
use Types::Standard qw(
		Int		Bool		HashRef			is_HashRef		ArrayRef	Enum	is_Int
    );
use Carp qw( confess );
use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_shared_string{
	my( $self, $name ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_shared_string', );
	confess "Please post an example of this file to: " .
		"https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues\n" .
		"I don't have a good example of this type of file for parsing yet";
}

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the sharedStrings unique bits" ] );

	# Check for empty node and react (Sub element of SharedStrings is SharedString?)
	my( $result, $node_name, $node_level, $result_ref );
	my $current_node = $self->current_node_parsed;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"The current node is:", $current_node ] );
	if( (keys %$current_node)[0] eq 'SharedString' ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Found the core properties node" ] );
		$result = 2;
		$node_name = 'cp:coreProperties';
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'SharedString' );
	}
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The SharedString node has an - Implied 'SharedStrings' node - this is totally incomplete" ] );
		$self->start_the_file_over;
		$self->good_load( 1 );
	}else{
		$self->set_error( "No 'SharedString' element with content found - can't parse this as a sharedStrings file" );
		return undef;
	}
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _should_block_formats{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_should_block_formats', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"determining if formats should be blocked: " . $self->get_group_return_type ] );
	return ( $self->get_group_return_type =~ /(unformatted|value|xml_value)/) ? 1 : 0 ;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings - Name based sharedStrings Reader

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Data::Dumper;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings;
	use	Spreadsheet::Reader::ExcelXML::SharedStrings;

	my $file_instance = build_instance(
	    package => 'SharedStringsInstance',
		workbook_inst => Spreadsheet::Reader::ExcelXML::Workbook->new,
		superclasses =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader'
		],
		add_roles_in_sequence =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader::NamedSharedStrings',
		],
	);

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your
own excel parser or extending this package.  To use the general package for excel
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::Reader::ExcelXML>, L<Worksheets
|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This role is written to extend L<Spreadsheet::Reader::ExcelXML::XMLReader>.
It adds functionality to read name based sharedStrings files.  It presents this
functionality in compliance with the top level L<interface
|Spreadsheet::Reader::ExcelXML::SharedStrings>.  This POD only describes the
functionality incrementally provided by this module.  For an overview of
sharedStrings.xml reading see L<Spreadsheet::Reader::ExcelXML::SharedStrings>

=head1 WARNING

If your Excel 2003 xml based file does not include a SharedStrings portion
then ignore this warning since it will not matter.  I don't have an example of an
Excel 2003 xml file that has SharedStrings content.  I'm not even sure that
any generators build flat SpreadsheetML files with a SharedStrings subsection.
As a consequence this role is just a placeholder to allow the rest of the
package to work on Excel 2003 xml files.  If you are actually parsing an xml
file that contains a SharedStrings portion then your parse will die with the
request to submit an issue on the L<github repo
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>.  Please
include the file that is failing.  I will need an example in order to
complete this section of the parser.

=head2 Requires

These are the methods required by this role and their default provider.  All
methods are imported straight across with no re-naming.

=over

L<Spreadsheet::Reader::ExcelXML::Error/set_error>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_named_node>

L<Spreadsheet::Reader::ExcelXML::Workbook/get_group_return_type>

=back

=head2 Methods

These are the primary ways to use this class.  For additional SharedStrings options
see the L<Attributes|/Attributes> section.

=head3 get_shared_string( $name)

=over

B<Definition:> This is the primary method that needs an example for completion.

B<Accepts:> $name = the node name of the shared string to be returned

B<Returns:> dies with a message to submit the file to my L<github repo
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head3 load_unique_bits

=over

B<Definition:> When the xml file first loads this is available to pull customized data.
It mostly pulls metadata and stores it in hidden attributes for use later.  If all goes
according to plan it sets L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load> to 1.

B<Accepts:> Nothing

B<Returns:> Nothing

=back

=head2 Attributes

Data passed to new when creating an instance of this class. For
modification of this(ese) attribute(s) see the listed 'attribute
methods'.  For more information on attributes see
L<Moose::Manual::Attributes>.  The easiest way to modify this(ese)
attribute(s) is when a classinstance is created and before it is
passed to the workbook or parser.

=head3 cache_positions

=over

B<Definition:> Especially for sheets with lots of stored text the
parser can slow way down when accessing each postion.  This is
because the text is not always stored sequentially and the reader
is a JIT linear parser.  To go back it must restart and index
through each position till it gets to the right place.  This is
especially true for excel sheets that have experienced any
significant level of manual intervention prior to being read.
This attribute turns (default) on caching for shared strings so
the parser only has to read through the shared strings once.  When
the read is complete all the way to the end it will also release
the shared strings file in order to free up some space.
(a small win in exchange for the space taken by the cache).  The
trade off here is that all intermediate shared strings are
L<fully|/get_shared_string( $positive_intE<verbar>$name )> read
before reading the target string.  This means early reads will be
slower.  For sheets that only have numbers stored or at least have
very few strings this will likely not be a initial hit (or speed
improvement).  In order to minimize the physical size of the cache,
if there is only a text string stored in the shared strings position
then only the string will be stored (not as a value to a raw_text
hash key).  It will then reconstitue into a hashref when requested.

B<Default:> 1 = caching is on

B<Range:> 1|0

B<Attribute required:> yes

B<attribute methods> Methods provided to adjust this attribute

=over

none - (will be autoset by L<Spreadsheet::Reader::ExcelXML/cache_positions>)

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Nothing yet

=back

=head1 AUTHOR

=over

Jed Lund

jandrew@cpan.org

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

#########1#########2 main pod documentation end   5#########6#########7#########8#########9
