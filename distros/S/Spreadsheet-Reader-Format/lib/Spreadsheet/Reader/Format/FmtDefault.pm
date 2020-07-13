package Spreadsheet::Reader::Format::FmtDefault;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.6.4');
#~ use Log::Shiras::Unhide qw( :debug );
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::Format::FmtDefault-$VERSION";

use	5.010;
use	Moose;
use	Carp 'confess';
use	Encode qw(decode);
use Types::Standard qw( HashRef	Str is_ArrayRef is_HashRef is_StrictNum );#
###LogSD	use Log::Shiras::Telephone;
###LogSD	with 'Log::Shiras::LogSpace';

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has excel_region =>(
		isa		=> Str,
		default	=> 'en',
		reader	=> 'get_excel_region',
		writer	=> 'set_excel_region',
	);

has	target_encoding =>(
		isa			=> Str,
		reader		=> 'get_target_encoding',
		writer		=> 'set_target_encoding',
		predicate	=> 'has_target_encoding',
	);

has defined_excel_translations =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		default	=> sub{ {
			0x00 => 'General',
			0x01 => '0',
			0x02 => '0.00',
			0x03 => '#,##0',
			0x04 => '#,##0.00',
			0x05 => '$#,##0_);($#,##0)',
			0x06 => '$#,##0_);[Red]($#,##0)',
			0x07 => '$#,##0.00_);($#,##0.00)',
			0x08 => '$#,##0.00_);[Red]($#,##0.00)',
			0x09 => '0%',
			0x0A => '0.00%',
			0x0B => '0.00E+00',
			0x0C => '# ?/?',
			0x0D => '# ??/??',
			0x0E => 'yyyy-mm-dd',      # Was 'm-d-yy', which is bad as system default
			0x0F => 'd-mmm-yy',
			0x10 => 'd-mmm',
			0x11 => 'mmm-yy',
			0x12 => 'h:mm AM/PM',
			0x13 => 'h:mm:ss AM/PM',
			0x14 => 'h:mm',
			0x15 => 'h:mm:ss',
			0x16 => 'm-d-yy h:mm',
			0x1F => '#,##0_);(#,##0)',
			0x20 => '#,##0_);[Red](#,##0)',
			0x21 => '#,##0.00_);(#,##0.00)',
			0x22 => '#,##0.00_);[Red](#,##0.00)',
			0x23 => '_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)',
			0x24 => '_($*#,##0_);_($*(#,##0);_($*"-"_);_(@_)',
			0x25 => '_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)',
			0x26 => '_($*#,##0.00_);_($*(#,##0.00);_($*"-"??_);_(@_)',
			0x27 => 'mm:ss',
			0x28 => '[h]:mm:ss',
			0x29 => 'mm:ss.0',
			0x2A => '##0.0E+0',
			0x2B => '@',
			0x31 => '@',
		} },
		handles =>{
			_get_defined_excel_format => 'get',
			_set_defined_excel_format => 'set',
			total_defined_excel_formats	=> 'count',
		},
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub	get_defined_excel_format{
	my ( $self, $position, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_defined_excel_format', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD				"Getting the defined excel format for position: $position", ] );
	my	$int_value = ( $position =~ /0x/ ) ? hex( $position ) : $position;
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD				"..after int conversion: $int_value", ] );
	return $self->_get_defined_excel_format( $int_value );
}

sub	set_defined_excel_formats{
	my ( $self, @args, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::set_defined_excel_format', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Setting defined excel formats" ] );
	###LogSD		$phone->talk( level => 'trace', message => [
	###LogSD			"..from the list: ", @args, ] );
	my $position_ref;
	if( @args > 1 and @args % 2 == 0 ){
		$position_ref = { @args };
	}else{
		$position_ref = $args[0];
	}
	if( is_ArrayRef( $position_ref ) ){
		my $x = -1;
		for my $format_string ( @$position_ref ){
			$x++;
			next if !defined $format_string;
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Setting position -$x- to format string: $format_string", ] );
			$self->_set_defined_excel_format( $x => $format_string );
		}
	}elsif( is_HashRef( $position_ref ) ){
		for my $key ( keys %$position_ref ){
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD			"Setting the defined excel format for position -$key- to : ", $position_ref->{$key}, ] );
			my	$int_value = ( $key =~ /0x/ ) ? hex( $key ) : $key;
			confess "The key -$key- must translate to a number!" if !is_StrictNum( $int_value );
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Initial -$key- translated to position: " . $int_value, ] );
			$self->_set_defined_excel_format( $int_value => $position_ref->{$key} );
		}
	}else{
		confess "Unrecognized format passed: " . join( '~|~', @$position_ref );
	}
	return 1;
}

sub	change_output_encoding{
	my ( $self, $string, ) = @_;
	return undef if !defined $string;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::change_output_encoding', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Changing the encoding of: $string",
	###LogSD			($self->has_target_encoding ? ('..to encoding type: ' . $self->get_target_encoding) : ''), ] );
	my $output = $self->has_target_encoding ? decode( $self->get_target_encoding, $string ) : $string;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Final output: $output", ] );
	return $output;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::Format::FmtDefault - Default number and string formats

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Spreadsheet::Reader::Format::FmtDefault;
	my		$formatter = Spreadsheet::Reader::Format::FmtDefault->new(
						target_encoding => 'latin1',
						epoch_year		=> 1904,
					);
	my 		$excel_format_string = $formatter->get_defined_excel_format( 0x0E );
	print 	$excel_format_string . "\n";
			$excel_format_string = $formatter->get_defined_excel_format( '0x0E' );
	print 	$excel_format_string . "\n";
			$excel_format_string = $formatter->get_defined_excel_format( 14 );
	print	$excel_format_string . "\n";
			$formatter->set_defined_excel_formats( '0x17' => 'MySpecialFormat' );#Won't really translate!
			$excel_format_string = $formatter->get_defined_excel_format( 23 );
	print 	$excel_format_string . "\n";

	###########################
	# SYNOPSIS Screen Output
	# 01: yyyy-mm-dd
	# 02: yyyy-mm-dd
	# 03: yyyy-mm-dd
	# 04: MySpecialFormat
	###########################

=head1 DESCRIPTION

This is the default localization class used by L<Spreadsheet::Reader::Format>.  It is
separate from the other parts of the formatter class to isolate the basic elements of
localization to allow for the least work swapping it out.  This class can be configured
or adjused without replacing it or you can use it as a template for a new localization.
To use the class as it stands just adjust the attributes to change the outcome of the
methods.  If you re-write this class it is used as a base class and must provide the
same methods.

This class provides two basic functionalities.  First, it stores and can retreive defined
excel format strings.  Excel uses these (common) formats to assign conversions to various
cells in the sheet rather than storing a conversion string.  Specifically these are the
conversions provided to Excel end users in the pull down menu if they do not want to
write their own custom conversion strings.  This specific class represents the standard
set of parsing strings localized for the United States found in Excel.  There is one
exception where position 14 (0x0E) is different than the Excel implementation since the
Excel setting for that position breaks so many database data types.  Where excel users
have written their own custom conversion definition strings they are stored in the
L<Styles|Spreadsheet::Reader::ExcelXML::Styles> file of the zipped archive.  These strings
are implemented by a parsing engine to convert raw values to formatted values.  The rules
for these conversions are layed out in L<the Excel documentation
|https://support.office.com/en-us/article/Create-or-delete-a-custom-number-format-78f2a361-936b-4c03-8772-09fab54be7f4>.
The default implementation of these rules is done in
L<Spreadsheet::Reader::Format::ParseExcelFormatStrings>.  The second
functionality is string decoding.  It is assumed that any file encoding is handled by
the Excel file reader. However, once the file has been read into memory you may wish
to decode it to some specific output format.  The attribute L<target_encoding
|/target_encoding> and the method L<change_output_encoding|/change_output_encoding( $string )>
use L<Encode> to do this.

For an explanation of functionality for a fully built Formatter class see the
documentation for L<Spreadsheet::Reader::Format>.

=head2 Attributes

Data passed to new when creating an instance containing this class. For modification
of these attributes see the listed 'attribute methods' and L<Methods|/Methods>.  For
more information on attributes see L<Moose::Manual::Attributes>.

=head3 excel_region

=over

B<Definition:> This records the target region of this localization role (Not the region of the
Excel workbook being parsed).  It's mostly a reference value.

B<Default:> en = english

B<Attribute required:> no

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_excel_region>

=over

B<Definition:> returns the value of the attribute (en)

=back

B<set_excel_region( $region )>

=over

B<Definition:> sets the value of the attribute.

=back

=back

=back

=head3 target_encoding

=over

B<Definition:> This is the target output encoding.  If it is not defined the string
transformation step L<change_output_encoding|/change_output_encoding( $string )> becomes a
passthrough.  When the value is loaded it is used as a 'decode' target by L<Encode>
to transform the internally (unicode) stored perl string to some target 'output'
formatting.

B<Attribute required:> no

B<Default:> none

B<Range:> Any encoding recognized by L<Encode|Encode/Listing available encodings>
(No type certification is done)

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_target_encoding( $encoding )>

=over

B<Definition:> This should be recognized by L<Encode/Listing available encodings>
I<no testing of this compatability is done>

=back

B<get_target_encoding>

=over

B<Definition:> Returns the currently set attribute value

=back

B<has_target_encoding>

=over

B<Definition:> Returns positive if the target_encoding has been set

=back

=back

=back

=head3 defined_excel_translations

=over

B<Definition:> In Excel part of localization is the way numbers are displayed.
Excel manages that with a default list of format strings that make the numbers appear
in a familiar way.  These are the choices provided in the pull down menu for formats
if you did not want to write your own custom format string.  This is where you store
that list for this package.  In this case the numbers are stored as hash key => value
pairs where the keys are array positions (written in hex) and the values are the Excel
readable format strings (definitions).  Beware that if you change the list your
parser may break if you don't supply replacements for all the values in the default
list.  If you just want to replace some of the values use the method
L<set_defined_excel_formats|/set_defined_excel_formats( %args )>.

B<Attribute required:> yes

B<Default:>

	{
		0x00 => 'General',
		0x01 => '0',
		0x02 => '0.00',
		0x03 => '#,##0',
		0x04 => '#,##0.00',
		0x05 => '$#,##0_);($#,##0)',
		0x06 => '$#,##0_);[Red]($#,##0)',
		0x07 => '$#,##0.00_);($#,##0.00)',
		0x08 => '$#,##0.00_);[Red]($#,##0.00)',
		0x09 => '0%',
		0x0A => '0.00%',
		0x0B => '0.00E+00',
		0x0C => '# ?/?',
		0x0D => '# ??/??',
		0x0E => 'yyyy-mm-dd',      # Was 'm-d-yy', which is bad as system default
		0x0F => 'd-mmm-yy',
		0x10 => 'd-mmm',
		0x11 => 'mmm-yy',
		0x12 => 'h:mm AM/PM',
		0x13 => 'h:mm:ss AM/PM',
		0x14 => 'h:mm',
		0x15 => 'h:mm:ss',
		0x16 => 'm-d-yy h:mm',
		0x1F => '#,##0_);(#,##0)',
		0x20 => '#,##0_);[Red](#,##0)',
		0x21 => '#,##0.00_);(#,##0.00)',
		0x22 => '#,##0.00_);[Red](#,##0.00)',
		0x23 => '_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)',
		0x24 => '_($*#,##0_);_($*(#,##0);_($*"-"_);_(@_)',
		0x25 => '_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)',
		0x26 => '_($*#,##0.00_);_($*(#,##0.00);_($*"-"??_);_(@_)',
		0x27 => 'mm:ss',
		0x28 => '[h]:mm:ss',
		0x29 => 'mm:ss.0',
		0x2A => '##0.0E+0',
		0x2B => '@',
		0x31 => '@',
	}

B<Range:> Any hashref of formats recognized by
L<Spreadsheet::Reader::Format::ParseExcelFormatStrings>

B<attribute methods> Methods provided to by the attribute to adjust it.

=over

B<total_defined_excel_formats>

=over

B<Definition:> get the count of the current key => value pairs

=back

See L<get_defined_excel_format|/get_defined_excel_format( $position )> and
L<set_defined_excel_formats|/set_defined_excel_formats( %args )>

=back

=back

=head2 Methods

These are methods to use this class.  For additional FmtDefault options see the
L<Attributes|/Attributes> section.

=head3 get_defined_excel_format( $position )

=over

B<Definition:> This will return the preset excel format string for the stored position
from the attribute L<defined_excel_translations|/defined_excel_translations>.
The positions are actually stored in a hash where the keys are integers representing a
position in an order list.

B<Accepts:> an integer or an octal number or octal string for the format string
$position

B<Returns:> an excel format string (not a built coercion)

=back

=head3 set_defined_excel_formats( %args )

=over

B<Definition:> This will set the excel format strings for the indicated positions
in the attribute L<defined_excel_translations|/defined_excel_translations>.

B<Accepts:> a Hash list, a hash ref (both with keys representing positions), or an arrayref
of strings with the update strings in the target position.  All passed argument B<lists> greater
than one will be assumed to be hash arguments and must come in pairs.  If a single argument is
passed then that value is checked to see if it is a hashref or an arrayref.  For passed
arrayrefs all empty positions are ignored meaning that any preexisting value in that positions
is left in force.  To erase the default value send '@' (passthrough) as the format string for
that position.  This function does not do any string validation.  The validation is done when
the coercion is generated.

B<Returns:> 1 for success

=back

=head3 change_output_encoding( $string )

=over

B<Definition:> This should be called on the output string prior to performing any
coercion.

B<Accepts:> a perl unicode coded string

B<Returns:> the converted $string decoded to the L<defined format|/target_encoding>

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::Format/issues
|https://github.com/jandrew/p5-spreadsheet-reader-format/issues>

=back

=head1 TODO

=over

Nothing L<yet|/SUPPORT>.

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

L<Spreadsheet::Reader::Format>

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

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
