package Spreadsheet::Reader::ExcelXML::Chartsheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::Chartsheet-$VERSION";

use	5.010;
use	Moose;
use	MooseX::StrictConstructor;
use	MooseX::HasDefaults::RO;
use Carp qw( confess );
use Types::Standard qw( Enum Int Str );
use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;

use Spreadsheet::Reader::ExcelXML::Types qw( IOFileType );

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has sheet_type =>(
		isa		=> Enum[ 'chartsheet' ],
		default	=> 'chartsheet',
		reader	=> 'get_sheet_type',
	);

has sheet_rel_id =>(
		isa		=> Str,
		reader	=> 'rel_id',
	);

has sheet_id =>(
		isa		=> Int,
		reader	=> 'sheet_id',
	);

has sheet_position =>(# XML position
		isa		=> Int,
		reader	=> 'position',
	);

has sheet_name =>(
		isa		=> Str,
		reader	=> 'get_name',
	);

has drawing_rel_id =>(
		isa		=> Str,
		writer	=> '_set_drawing_rel_id',
		reader	=> 'get_drawing_rel_id',
	);

has file =>(
		isa			=> IOFileType,
		reader		=> 'get_file',
		writer		=> 'set_file',
		predicate	=> 'has_file',
		clearer		=> 'clear_file',
		coerce		=> 1,
		trigger		=> \&_start_xml_reader,
		handles 	=> [qw( close getline seek )],
	);

has workbook_inst =>(
		isa	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		writer => 'set_workbook_inst',
		predicate => '_has_workbook_inst',
		handles => [qw(
			get_group_return_type		set_error					get_defined_conversion
			set_defined_excel_formats	parse_excel_format_string	counting_from_zero
			are_spaces_empty			get_shared_string			has_shared_strings_interface
			should_skip_hidden			spreading_merged_values		starts_at_the_edge
			get_empty_return_type		get_values_only				get_epoch_year
			change_output_encoding		get_error_inst				has_styles_interface
			boundary_flag_setting		is_empty_the_end			get_format
		)],# The regex import doesn't work here due to the twistiness of the overall package
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'Chartsheet' }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::Chartsheet - An ExcelXML chartsheet placeholder

=head1 SYNOPSIS

See the SYNOPSIS in L<Spreadsheet::Reader::ExcelXML>

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your
own excel parser or extending this package.  To use the general package for excel
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::Reader::ExcelXML>, L<Worksheets
|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This class is a placeholder for chartsheet parsing.  Where there is a 'chartsheet' style
tab in the workbook this class is used to receive that data so the workbook won't fail
automatically.  Chartsheet files are not chart sub elements they are just tabs in a
workbook similar to 'worksheets' that only hold one chart. The ability to parse
'chartsheet's is still pending.  There are attributes and some methods in the class
but none will be documented untill there is a clear path for them to provide
functionality.

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Provide access to chartsheet content

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

#########1 Documentation End  3#########4#########5#########6#########7#########8#########9
