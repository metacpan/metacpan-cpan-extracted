package Spreadsheet::Reader::ExcelXML::Styles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::Styles-$VERSION";

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

Spreadsheet::Reader::ExcelXML::Styles - The styles interface

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Data::Dumper;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Types::Standard qw( ConsumerOf HasMethods Int );
	use Spreadsheet::Reader::ExcelXML::Error;
	use Spreadsheet::Reader::ExcelXML::Styles;
	use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::Format::FmtDefault;
	use Spreadsheet::Reader::Format::ParseExcelFormatStrings;
	use Spreadsheet::Reader::Format;
	my	$workbook_instance = build_instance(
			package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
			add_attributes =>{
				formatter_inst =>{
					isa	=> 	ConsumerOf[ 'Spreadsheet::Reader::Format' ],# Interface
					writer	=> 'set_formatter_inst',
					reader	=> 'get_formatter_inst',
					predicate => '_has_formatter_inst',
					handles => { qw(
							get_formatter_region			get_excel_region
							has_target_encoding				has_target_encoding
							get_target_encoding				get_target_encoding
							set_target_encoding				set_target_encoding
							change_output_encoding			change_output_encoding
							set_defined_excel_formats		set_defined_excel_formats
							get_defined_conversion			get_defined_conversion
							parse_excel_format_string		parse_excel_format_string
							set_date_behavior				set_date_behavior
							set_european_first				set_european_first
							set_formatter_cache_behavior	set_cache_behavior
							get_excel_region				get_excel_region
						),
					},
				},
				epoch_year =>{
					isa => Int,
					reader => 'get_epoch_year',
					default => 1904,
				},
				error_inst =>{
					isa => 	HasMethods[qw(
										error set_error clear_error set_warnings if_warn
									) ],
					clearer		=> '_clear_error_inst',
					reader		=> 'get_error_inst',
					required	=> 1,
					handles =>[ qw(
						error set_error clear_error set_warnings if_warn
					) ],
					default => sub{ Spreadsheet::Reader::ExcelXML::Error->new() },
				},
			},
			add_methods =>{
				get_empty_return_type => sub{ 1 },
			},
		);
	my	$format_instance = build_instance(
			package => 'FormatInstance',
			superclasses => [ 'Spreadsheet::Reader::Format::FmtDefault' ],
			add_roles_in_sequence =>[qw(
					Spreadsheet::Reader::Format::ParseExcelFormatStrings
					Spreadsheet::Reader::Format
			)],
			target_encoding => 'latin1',# Adjust the string output encoding here
			workbook_inst => $workbook_instance,
		);
	$workbook_instance->set_formatter_inst( $format_instance );
	my	$test_instance	=	build_instance(
			package => 'StylesInterface',
			superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			add_roles_in_sequence => [
				'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
				'Spreadsheet::Reader::ExcelXML::Styles',
			],
			file => '../../../../t/test_files/xl/styles.xml',,
			workbook_inst => $workbook_instance,
		);
	print Dumper( $test_instance->get_format( 2 ) );

	#######################################
	# SYNOPSIS Screen Output
	# 01: $VAR1 = {
	# 02: 'cell_style' => {
	# 03:     'builtinId' => '0',
	# 04:     'xfId' => '0',
	# 05:     'name' => 'Normal'
	# 06: },
	# 07: 'cell_font' => {
	# 08:     'name' => 'Calibri',
	# 09:     'family' => '2',
	# 10:     'scheme' => 'minor',
	# 11:     'sz' => '11',
	# 12:     'color' => {
	# 13:         'theme' => '1'
	# 14:     }
	# 15:  },
	# 16: 'cell_fill' => {
	# 17:     'patternFill' => {
	# 18:         'patternType' => 'none'
	# 19:      }
	# 20: },
	# 21: 'cell_border' => {
	# 22:      'diagonal' => undef,
	# 23:      'bottom' => undef,
	# 24:      'right' => undef,
	# 25:      'top' => undef,
	# 26:      'left' => undef
	# 27: },
	# 28: 'cell_coercion' => bless( {
	~~ Skipped 142 lines ~~
	#170:                             'display_name' => 'Excel_date_164',
	#171:							  'name' => 'DATESTRING',
	#172:                           }, 'Type::Tiny' ),
	#173: 'applyNumberFormat' => '1',
	#174: };
	#######################################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module.  To use the general
package for excel parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::Reader::ExcelXML>, L<Worksheets
|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This role is written as the interface for getting useful data from the sub file 'styles.xml'
that is a member of a zipped (.xlsx) archive or a stand alone XML text file containing an
equivalent subset of information in the 'Styles' node.  The styles.xml file contains the
format and display options used by Excel for showing the stored data.  The SYNOPSIS shows
the (very convoluted) way to get this interface wired up and working.  Unless you are
trying to rewrite this package don't pay attention to that.  The package will build it
for you.  This interface doesn't hold any of the functionality it just mandates certain
behaviors below it.  The documentation is the explanation of how the final class should
perform when the layers below are correctly implemented.

=head2 Method(s)

These are the methods mandated by this interface.

=head3 get_format( ($position|$name), [$header], [$exclude_header] )

=over

B<Definition:> This will return the styles information from the identified $position
(counting from zero) or $name.  The target position is usually drawn from the cell
data stored in the worksheet.  The information is returned as a perl hash ref.  Since
the styles data is in two tiers it finds all the subtier information for each indicated
piece and appends them to the hash ref as values for each type key.

B<Accepts position 0:> dependant on the role implementation; $position = an integer for
the styles $position. (from L<Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles>),
$name = a (sub) node name indicating which styles node should be returned (from
L<Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles>)

B<Accepts position 1:> $header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will cause only this header subset to be returned

B<Accepts position 2:> $exclude_header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will exclude the header from the returned data set.

B<Returns:> a hash ref of data

=back

=head3 get_default_format( [$header], [$exclude_header] )

=over

B<Definition:> For any cell that does not have a unquely identified format excel generally
stores a default format for the remainder of the sheet.  This will return the two
tiered default styles information.  The information is returned in the same format as the
get_format method.

B<Accepts position 0:> $header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will cause only this header subset to be returned

B<Accepts position 1:> $exclude_header = the target header key (optional at position 2) (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will exclude the header from the returned data set.

B<Returns:> a hash ref of data

=back

=head3 loaded_correctly

=over

B<Definition:> When building a styles reader it may be that the file is deformed.  This is
the way to know if the reader thought the file was good.

B<Accepts:> Nothing

B<Returns:> (1|0)

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

B<Range:> any unencrypted styles.xml file name and path or IO::File file
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

B<Definition:> Especially for sheets with lots of stored formats the
parser can slow way down when accessing each postion.  This is
because the are not stored sequentially and the reader is a JIT linear
parser.  To go back it must restart and index through each position till
it gets to the right place.  This is especially true for excel sheets
that have experienced any significant level of manual intervention prior
to being read.  This attribute sets caching (default on) for styles
so the parser builds and stores all the styles settings at the beginning.
If the file is cached it will close and release the file handle in order
to free up some space. (a small win in exchange for the space taken by
the cache).

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

#########1#########2 main pod documentation end   5#########6#########7#########8#########9
