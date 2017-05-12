package Spreadsheet::XLSX::Reader::LibXML::SharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::SharedStrings-$VERSION";

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

Spreadsheet::XLSX::Reader::LibXML::SharedStrings - The sharedStrings interface

=head1 SYNOPSIS

	Broken
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your 
own excel parser or extending this package.  To use the general package for excel 
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::XLSX::Reader::LibXML>, L<Worksheets
|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>.

This class is written to extend L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>.  
It addes to that functionality specifically to read the sharedStrings portion 
(if any) which is most likely a sub file zipped into an .xlsx file.  It does not 
provide connection to other file types or even the elements from other files that are 
related to this file.  This POD only describes the functionality incrementally provided 
by this module.  For an overview of sharedStrings.xml reading see L<Spreadsheet::XLSX::Reader::LibXML::SharedStrings>

=head2 Methods

These are the primary ways to use this class.  For additional SharedStrings options see the 
L<Attributes|/Attributes> section.

=head3 get_shared_string_position( $positive_int )

=over

B<Definition:> This returns the xml L<converted to a deep perl data structure
|/no_formats> from the indicated 'si' position.

B<Accepts:> $positive_int ( a positive integer )

B<Returns:> a L<deep perl data structure|/no_formats> built from the xml at 'si' 
position $positive_int

=back

=head2 Attributes

Data passed to new when creating an instance of this class. For modification of these attributes 
see the listed 'attribute methods'.  For more information on attributes see 
L<Moose::Manual::Attributes>.  The easiest way to modify these attributes are when a class
instance is created and before it is passed to the workbook or parser.

=head3 cache_positions

=over

B<Definition:> Especially for sheets with lots of stored text the parser can slow way down 
when accessing each postion.  This is because an XML::LibXML Reader cannot rewind but must 
start from the beginning and index through the file till it gets to the target position.  This 
is complicated by the fact that the shared strings are not necessarily stored in a logical or 
cell order.  This is especially true for excel sheets that have experienced any significant level 
of manual intervention prior to being read.  This attribute turns (default) on caching for shared 
strings so the parser only has to read through the shared strings once.  When the read is complete 
all the way to the end it will also release the shared strings file in order to free up some space. 
(a small win in exchange for the space taken by the cache).  The trade off here is that all 
intermediate shared strings are L<fully|/no_formats> read before reading the target string.  
This means early reads will be slower.  For sheets that only have numbers stored or at least 
have very few strings this will likely not be a large startup hit (or speed improvement).  
The risk obviously is that the cach will impact memory.  You can use this attribute to turn off 
caching but it is most likely that a cache of that size will necessitate the sheet read to 
slow way down!  The tradeoff of course is the parser shouldn't die.  In order to minimize the 
physical size of the cache if there is only a text string stored in the shared strings position 
then only the string will be stored (not the definition that only a string exists).

B<Default:> 1 = caching is on

B<Range:> 1|0

B<Attribute required:> yes

B<attribute methods> Methods provided to adjust this attribute
		
=over

none - (will be autoset by L<Spreadsheet::XLSX::Reader::LibXML/store_read_positions>)

=back

=back

=head3 no_formats

=over

B<Definition:> Quite often the goal of reading a spreadsheet is to get at the data in the 
cells and not read the visible presentation of the sheet.  If so reading the sharedStrings 
file can be sped up by skipping the stored text formatting when reading from the xml.  
This flag will manage that choice.

B<Default:> 0 = format reading is on

B<Range:> 0|1

B<Attribute required:> yes

B<attribute methods> Methods provided to adjust this attribute
		
=over

none - (will be autoset by L<Spreadsheet::XLSX::Reader::LibXML/group_return_type> ('unformatted' or 'value') => 1

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

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

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML>

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9