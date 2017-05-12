package Spreadsheet::Reader::ExcelXML::SharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::SharedStrings-$VERSION";

use 5.010;
use Moose::Role;
requires qw( should_cache_positions get_shared_string loaded_correctly );

use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'SharedStringsInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::SharedStrings - The sharedStrings interface

=head1 SYNOPSIS

	#!/usr/bin/env perl
	$|=1;
	use Data::Dumper;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::Workbook;
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::SharedStrings;
	use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;

	# This whole thing is performed under the hood of
	#  Spreadsheet::Reader::ExcelXML
	my $file_instance = build_instance(
			package      => 'SharedStringsInstance',
			file         => 'sharedStrings.xml',
			workbook_inst => Spreadsheet::Reader::ExcelXML::Workbook->new,
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

	#######################################
	# SYNOPSIS Screen Output
	# 01: $VAR1 = {
	# 02:     'raw_text' => ' '
	# 03: };
	# 04: $VAR1 = {
	# 05:     'raw_text' => 'Superbowl Audibles'
	# 06: };
	#######################################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your
own excel parser or extending this package.  To use the general package for excel
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::Reader::ExcelXML>, L<Worksheets
|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This class is the interface for reading the sharedStrings file in a standard
xml based Excel file.  The SYNOPSIS provides an example with a role added to
implement that type of reading ~PositionSharedStrings.  The other role written
for this interface is L<Spreadsheet::Reader::ExcelXML::NamedSharedStrings>.  It
does not provide connection to other file types or even the elements from other
files that are related to this file.  This POD documents all functionaliy required
by this interface independant of where it is provided.

=head2 Methods

These are the primary ways to use this class.  For additional SharedStrings
options see the L<Attributes|/Attributes> section.

=head3 get_shared_string( $positive_int|$name )

=over

B<Definition:> This returns the data in the shared strings file identified
by either the $positive_int position for position based sharedStrings files
or $name in name based sharedStrings files.  The position implementation is
L<Spreadsheet::Reader::ExcelXML::PositionSharedStrings>.  The named
retrieval is implemented in L<Spreadsheet::Reader::ExcelXML::NamedSharedStrings>.

B<Accepts:> $positive_int ( a positive integer ) or $name depending on the
associated role

B<Returns:> a hash ref with the key 'raw_text' and all coallated text for that
xml node as the value.  If there is associated rich text in the node and
L<Spreadsheet::Reader::ExcelXML/group_return_type> is set to 'instance'
then it will also have a 'rich_text' key with the value set as an arrayref of
pairs (not sub array refs) with the first value being the position of the
raw_text from zero that the formatting is applied and the second position as
the settings for that format.  Ex.

	{
		raw_text => 'Hello World',
		rich_text =>[
			2,# Starting with the letter 'l' apply the format
			{
				'color' => {
					'rgb' => 'FFFF0000'
				},
				'sz' => '11',
				'b' => undef,
				'scheme' => 'minor',
				'rFont' => 'Calibri',
				'family' => '2'
			},
			6,# Starting with the letter 'W' apply the format
			{
				'color' => {
					'rgb' => 'FF0070C0'
				},
				'sz' => '20',
				'b' => undef,
				'scheme' => 'minor',
				'rFont' => 'Calibri',
				'family' => '2'
			}
		]
	}

=back

=head3 loaded_correctly

=over

B<Definition:> This interface will check the sharedStrings file for a
global scope of the number of shared strings and store it when the file
is opened.  If the process was succesful then this will return 1.

B<Accepts:> nothing

B<Returns:> (1|0) depending on if file opened as a shared strings file

=back

=head2 Attributes

Data passed to new when creating an instance with this interface. For
modification of this(ese) attribute(s) see the listed 'attribute
methods'.  For more information on attributes see
L<Moose::Manual::Attributes>.  The easiest way to modify this(ese)
attribute(s) is during instance creation before it is passed to the
workbook or parser.

=head3 file

=over

B<Definition:> This attribute holds the file handle for the file being read.  If
the full file name and path is passed to the attribute the class will coerce that
into an L<IO::File> file handle.

B<Default:> no default - this must be provided to read a file

B<Required:> yes

B<Range:> any unencrypted sharedStrings.xml file name and path or IO::File file
handle with that content.

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_file>

=over

B<Definition:> change the file value in the attribute (this will reboot
the file instance and lock the file)

=back

B<get_file>

=over

B<Definition:> Returns the file handle of the file even if a file name
was passed

=back

B<has_file>

=over

B<Definition:> this is used to see if the file loaded correctly.

=back

B<clear_file>

=over

B<Definition:> this clears (and unlocks) the file handle

=back

=back

=back

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
