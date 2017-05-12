package Spreadsheet::XLSX::Reader::LibXML::Styles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::Styles-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
	should_cache_positions		get_default_format			get_format
	loaded_correctly
);

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'StylesInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::Styles - The styles interface

=head1 SYNOPSIS

	Broken!!

=head1 DESCRIPTION

This documentation is written to explain ways to use this module.  To use the general 
package for excel parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::XLSX::Reader::LibXML>, L<Worksheets
|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>.

This class is written to get useful data from the sub file 'styles.xml' that is 
a member of a zipped (.xlsx) archive or a stand alone XML text file of the same format.  
The styles.xml file contains the format and display options used by Excel for showing 
the stored data.  To unzip an Excel file manually change the \.xlsx extention to \.zip 
and windows should do (most) of the rest.  For linux use an unzip utility. (
L<Archive::Zip> for instance :)

This documentation is the explanation of this specific module.  For a general explanation 
of the class and how to to add or adjust its place in the larger package see the L<Styles
|Spreadsheet::XLSX::Reader::LibXML::Styles> POD.

This module is the simplified way to extract information from the styles file needed when 
doing high level reading of an Excel spread sheet.  In order to do so it subclasses the module 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader> and leverages one hard coded role 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader::XMLToPerlData> Additionally the module will 
error if not built with roles that supply two additional methods.  The methods are 
L<get_defined_excel_format|Spreadsheet::XLSX::Reader::LibXML::FmtDefault/get_defined_excel_format( $integer )> 
and L<parse_excel_format_string
|Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings/parse_excel_format_string( $string )>.  
The links lead to the default source of these methods in the package.  I<These methods are 
intentionally not hard coded to this class so that the user can change them at run time.  See 
the attributes L<Spreadsheet::XLSX::Reader::LibXML/default_format_list> and
L<Spreadsheet::XLSX::Reader::LibXML/format_string_parser> for more explanation.>   Read about 
the function of each when replacing them.  If you want to use the roles as-is, one way to 
integrate them is with L<MooseX::ShortCut::BuildInstance>. The 'on-the-fly' roles also 
add other methods (not documented here) to this class.  Look at the documentation for those 
modules to see what else comes with them.

=head2 Warnings

This package received a substantial re-write with version v0.38.16.  Now this class will now 
cache the styles values by default.  If this causes you heartache please L<contact me|/SUPPORT> 
and I will try and mitigate the impact.  The goal was to measurably speed up the package.

=head2 Method(s)

These are the methods just provided by this class.  Look at the documentation for the the two 
modules consumed by this class for their elements. L<Spreadsheet::XLSX::Reader::LibXML::XMLReader> 
and L<Spreadsheet::XLSX::Reader::LibXML::XMLReader::XMLToPerlData> 

=head3 get_format_position( $position, [$header], [$exclude_header] )

=over

B<Definition:> This will return the styles information from the identified $position
(Counting from zero).  the target position is usually drawn from the cell data stored in 
the worksheet.  The information is returned as a perl hash ref.  Since the styles 
data is in two tiers it finds all the subtier information for each indicated piece and 
appends them to the hash ref as values for each type key.  If you only want a specific 
branch then you can add the branch $header key and the returned value will only contain 
that leg.

B<Accepts:> $position = an integer for the styles $position. (required at position 0)

B<Accepts:> $header = the target header key (optional at postion 1) (use the 
L<Spreadsheet::XLSX::Reader::LibXML::Cell/Attributes> that are cell formats as the definition 
of range for this

B<Accepts:> $exclude_header = the target header key (optional at position 2) (use the 
L<Spreadsheet::XLSX::Reader::LibXML::Cell/Attributes> that are cell formats as the definition 
of range for this)

B<Returns:> a hash ref of data

=back

=head3 get_default_format_position( [$header], [$exclude_header] )

=over

B<Definition:> For any cell that does not have a unquely identified format excel generally 
stores a default format for the remainder of the sheet.  This will return the two 
tiered default styles information.  If you only want the default from a specific header 
then add the $header string to the method call.  The information is returned as a perl 
hash ref.

B<Accepts:> $header = the target header key (optional at postion 0) (use the 
L<Spreadsheet::XLSX::Reader::LibXML::Cell/Attributes> that are cell formats as the definition 
of range for this

B<Accepts:> $exclude_header = the target header key (optional at position 1) (use the 
L<Spreadsheet::XLSX::Reader::LibXML::Cell/Attributes> that are cell formats as the definition 
of range for this)

B<Returns:> a hash ref of data

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Extend the values saved here out to the sheet and cell level better.

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

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML>

=back

=head1 SEE ALSO

=over

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9