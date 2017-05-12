package Spreadsheet::Reader::ExcelXML::Cell;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::Cell-$VERSION";

$| = 1;
use 5.010;
use Moose;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use Types::Standard qw(
		Str					InstanceOf				HashRef
		Enum				HasMethods				ArrayRef
		Int					Maybe					CodeRef
		is_Object
    );
use lib	'../../../../lib';
###LogSD	use Log::Shiras::Telephone;
use	Spreadsheet::Reader::ExcelXML::Types qw( CellID );
###LogSD with 'Log::Shiras::LogSpace';

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has	error_inst =>(
		isa			=> InstanceOf[ 'Spreadsheet::Reader::ExcelXML::Error' ],
		clearer		=> '_clear_error_inst',
		reader		=> '_get_error_inst',
		required	=> 1,
		handles =>[ qw(
			error set_error clear_error set_warnings if_warn
		) ],
	);

has cell_xml_value =>(
		isa			=> Maybe[Str],
		reader		=> 'xml_value',
		predicate	=> 'has_xml_value',
	);

has cell_unformatted =>(
		isa			=> Maybe[Str],
		reader		=> 'unformatted',
		predicate	=> 'has_unformatted',
	);

has rich_text =>(
		isa		=> ArrayRef,
		reader	=> 'get_rich_text',
		predicate	=> 'has_rich_text',
	);

has cell_font =>(
		isa		=> HashRef,
		reader	=> 'get_font',
		predicate	=> 'has_font',
	);

has cell_border =>(
		isa		=> HashRef,
		reader	=> 'get_border',
		predicate	=> 'has_border',
	);

has cell_style =>(
		isa		=> Str,
		reader	=> 'get_style',
		predicate	=> 'has_style',
	);

has cell_fill =>(
		isa		=> HashRef,
		reader	=> 'get_fill',
		predicate	=> 'has_fill',
	);

has cell_alignment =>(
		isa		=> HashRef,
		reader	=> 'get_alignment',
		predicate	=> 'has_alignment',
	);

has cell_type =>(
		isa		=> Enum[qw( Text Numeric Date Custom )],
		reader	=> 'type',
		writer	=> '_set_cell_type',
		predicate	=> 'has_type',
	);

has cell_encoding =>(
		isa		=> Str,
		reader	=> 'encoding',
		predicate	=> 'has_encoding',
	);

has cell_merge =>(
		isa			=> Str,
		reader		=> 'merge_range',
		predicate 	=> 'is_merged',
	);

has cell_formula =>(
		isa			=> Str,
		reader		=> 'formula',
		predicate	=> 'has_formula',
	);

has cell_row =>(
		isa			=> Int,
		reader		=> 'row',
		predicate	=> 'has_row',
	);

has cell_col =>(
		isa			=> Int,
		reader		=> 'col',
		predicate	=> 'has_col',
	);

has r =>(
		isa			=> CellID,
		reader		=> 'cell_id',
		predicate	=> 'has_cell_id',
	);

has cell_hyperlink =>(
		isa		=> ArrayRef,
		reader	=> 'get_hyperlink',
		predicate	=> 'has_hyperlink',
	);

has cell_hidden =>(
		isa			=> Enum[qw( sheet column row 0 )],
		reader		=> 'is_hidden',
		default		=> 0,
	);

has cell_coercion =>(
		isa			=> HasMethods[ 'assert_coerce', 'display_name' ],
		reader		=> 'get_coercion',
		writer		=> 'set_coercion',
		predicate	=> 'has_coercion',
		clearer		=> 'clear_coercion',
		handles		=>{
			coercion_name => 'display_name',#
		},
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'Cell' }

sub value{
	my( $self, ) 	= @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD				$self->get_all_space . '::value', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Reached the -value- function' ] );
	###LogSD		$phone->talk( level => 'trace', message => [ "Cell:", $self ] );
	my	$unformatted =
			defined $self->has_xml_value ? $self->xml_value :
			defined $self->has_unformatted ? $self->_unformatted : undef;
	return	$self->_return_value_only(
				$unformatted,
				$self->get_coercion,
				$self->_get_error_inst,
			);
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

after 'set_coercion' => sub{
	my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD				$self->get_all_space . '::set_coercion', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Setting 'cell_type' to custom since the coercion has been set" ] );
	$self->_set_cell_type( 'Custom' );
};

sub _return_value_only{
	my ( $self, $unformatted, $coercion, $error_inst
	###LogSD	, $alt_log_space
	) = @_;# To be used by GetCell too
	###LogSD	$alt_log_space //= $self->get_all_space;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD				$alt_log_space . '::_hidden::_return_value_only', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			 "Returning the coerced value of -" . ( defined $unformatted ? $unformatted : '') . '-', ] );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			 '..using coercion:' , $coercion ] ) if $coercion;
	my	$formatted = $unformatted;
	if( !$coercion ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"No coercion passed" ] );
		return $unformatted;
	}elsif( !defined $unformatted ){
		$error_inst->set_error( "The cell does not have a value" );
	}elsif( $unformatted eq '' ){
		$error_inst->set_error( "The cell has the empty string for a value" );
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Attempting to return the value of the cell formatted to " .
		###LogSD		(($coercion) ? $coercion->display_name : 'No conversion available' ) ] );
		my	$sig_warn	= $SIG{__WARN__};
		$SIG{__WARN__}	= sub{};
		eval '$formatted = $coercion->assert_coerce( $unformatted )';
		$error_inst->set_error( $@ ) if( $@ );
		$SIG{__WARN__} = $sig_warn;
	}
	$formatted =~ s/\\//g if $formatted;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Format is:", $coercion->display_name,
	###LogSD		"Returning the formated value: " .
	###LogSD		( $formatted ? $formatted : '' ), ] );
	return $formatted;
}

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD				$self->get_all_space . '::hidden::DEMOLISH', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"clearing the cell for cell-ID:" . $self->cell_id, ] );
	#~ print "Clearing coercion\n";
	$self->clear_coercion;
	#~ print "Clearing error instance\n";
	$self->_clear_error_inst;
	#~ print "Cell closed\n";
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::Cell - ExcelXML Cell data class

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Spreadsheet::Reader::ExcelXML::Cell;
	use Spreadsheet::Reader::ExcelXML::Error;

	my	$cell_inputs = {
			'cell_hidden' => 0,
			'r' => 'A2',
			'cell_row' => 1,
			'cell_unformatted' => 'Hello',
			'cell_col' => 0,
			'cell_xml_value' => 'Hello',
			'cell_type' => 'Text',
			'error_inst' => Spreadsheet::Reader::ExcelXML::Error->new,
		};
	my	$cell_instance = Spreadsheet::Reader::ExcelXML::Cell->new( $cell_inputs );
	print "Cell value is: " . $cell_instance->value . "\n";

	###########################
	# SYNOPSIS Output
	# Cell value is: Hello
	###########################

=head1 DESCRIPTION

This is the class that contains cell data.  There are no XML parsing actions taken in the
background of this class.  All data has been pre-coalated/built from the L<Worksheet
|Spreadsheet::Reader::ExcelXML::Worksheet> class.  In general the Worksheet class
will populate the attributes of this class when it is generated.  If you want to use it
as a standalone class just fill in the L<Attributes|/Attributes> below.  It should be
noted that the Formatter class also L<pre-converts
|Spreadsheet::Reader::Format/change_output_encoding( $string )> the
unformatted value.  Not much goes on here but access or excesize of code provided from
other places.

=head2 Primary Methods

This is the method used to transform data stored in the L<Attributes|/Attributes>
(not just return it directly).  The method is an object method and should be implemented
on the instance.

B<Example:>

	my $value = $cell_intance->value;

=head3 value

=over

B<Definition:> Returns the formatted value of the cell transformed from the
L<base xml|/cell_xml_value> string if it is available. In the weird case where the
cell_xml_value is not available but the L<unformatted|/cell_unformatted> value is
then this method will use the unformatted value.  This method then applies any
conversion stored in the L<cell_coercion|/cell_coercion> attribute.  If there is
no format/conversion set then this will return the selected value. Any failures
to process this value can be retrieved with L<$self-E<gt>error|/error>.

B<Accepts:>Nothing

B<Returns:> the cell 'value' processed by the set conversion

=back

=head2 Attributes

This class is just a storage of coallated information about the requested cell stored
in the following attributes. For more information on attributes see
L<Moose::Manual::Attributes>.  Data about the cell can be retrieved from each
attribute using the 'attribute methods'.  'Delegated methods' are methods
available at the class or instance level directly delegated from that
specific attribute.

=head3 error_inst

=over

B<Definition:> This attribute holds an 'error' object instance.  In general
the package will share a reference for this instance accross the workbook with all
worksheets and all cells so any 'set' or 'get' action should be available at all
touch points for this error object.  If you wish to have a unique error instance
you can set it here.

B<Default:> a L<Spreadsheet::Reader::ExcelXML::Error> instance with the
attributes set as;

	( should_warn => 0 )

B<Range:> a 'Spreadsheet::Reader::ExcelXML::Error' instance.  To roll this on your
own, the minimum list of methods to implement for your own instance is;

	error set_error clear_error set_warnings if_warn

B<Delegated methods> Links to default implementation and method name conversions
(if any) delegated from this attribute to the package.

=over

L<Spreadsheet::Reader::ExcelXML::Error/error>

L<Spreadsheet::Reader::ExcelXML::Error/set_error>

L<Spreadsheet::Reader::ExcelXML::Error/clear_error>

L<Spreadsheet::Reader::ExcelXML::Error/set_warnings>

L<Spreadsheet::Reader::ExcelXML::Error/if_warn>

=back

=back

=head3 cell_xml_value

=over

B<Definition:> This contains the raw value stored in xml for this cell.  This
can be different than the 'cell_unformatted' value based on archane rules set
by Microsoft.

B<Range:>Any string or nothing

B<attribute methods> Methods provided to adjust this attribute

=over

B<xml_value>

=over

B<Definition:> returns the attribute value

=back

B<has_xml_value>

=over

B<Definition:> predicate for this attribute

=back

=back

=back

=head3 cell_unformatted

=over

B<Definition:> This holds the unformatted value of the cell.  The unformatted
value of the cell as defined by this package is the value displayed in the
formula bar when selecting the cell.  This can be a bit squidgy where the cell
is actually populated with a formula.  In that case this should contain the
implied value based on my (or your) visibility to the excel value that would
normally be there.

B<Range:> a string

B<attribute methods> Methods provided to adjust this attribute

=over

B<unformatted>

=over

B<Definition:> returns the attribute value

=back

B<has_unformatted>

=over

B<Definition:> a predicate method for the attribute

=back

=back

=back

=head3 rich_text

=over

B<Definition:> This attribute holds a rich text data structure like
L<Spreadsheet::ParseExcel::Cell/get_rich_text()> with the exception that it
doesn't bless each hashref into an object.  The hashref's are also organized
per the Excel xlsx information in the the sharedStrings.xml file.  In general
this is an arrayref of arrayrefs where the second level contains two positions.
The first position is the place (from zero) where the formatting is implemented.
The second position is a hashref of the formatting values.  The format is in
force until the next start place is identified.

=over

B<note:> It is important to understand that Excel can store two formats for the
same cell and often they don't agree.  For example using the attribute L<cell_font
|/cell_font> will not always contain the same value as specific fonts (or any font)
listed in the rich text array.

=back

B<Default:> undef = no rich text defined for this cell

B<Range:> an array ref of rich_text positions and definitions

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_rich_text>

=over

B<Definition:> returns the attribute value

=back

B<has_rich_text>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_font

=over

B<Definition:> This holds the font assigned to the cell

B<Range:> a hashref of definitions for the font

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_font>

=over

B<Definition:> returns the attribute contents

=back

B<has_font>

=over

B<Definition:> Predicate for the attribute contentss

=back

=back

=back

=head3 cell_border

=over

B<Definition:> This holds the border settings assigned to the cell

B<Range:> a hashref of border definitions

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_border>

=over

B<Definition:> returns the attribute contents

=back

B<has_border>

=over

B<Definition:> Indicates if the attribute has any contents

=back

=back

=back

=head3 cell_style

=over

B<Definition:> This holds the style settings assigned to the cell

B<Range:> a hashref of style definitions

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_style>

=over

B<Definition:> returns the attribute contents

=back

B<has_style>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_fill

=over

B<Definition:> This holds the fill settings assigned to the cell

B<Range:> a hashref of style definitions

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_fill>

=over

B<Definition:> returns the attribute value

=back

B<has_fill>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_alignment

=over

B<Definition:> This holds the alignment settings assigned to the cell

B<Range:> The alignment definition

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_alignment>

=over

B<Definition:> returns the attribute value

=back

B<has_alignment>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_type

=over

B<Definition:> This holds the type of data stored in the cell.  In general it
follows the convention of L<ParseExcel
|Spreadsheet::ParseExcel/ChkType($self, $is_numeric, $format_index)> (Date, Numeric,
or Text) however, since custom coercions will change data to some possible non excel
standard state this also allows a 'Custom' type representing any cell with a custom
conversion assigned to it (by you either at the worksheet level or here).

B<Range:> Text = Strings, Numeric = Real Numbers, Date = Real Numbers with an
assigned Date conversion or ISO dates, Custom = any stored value with a custom
conversion

B<attribute methods> Methods provided to adjust this attribute

=over

B<type>

=over

B<Definition:> returns the attribute value

=back

B<has_type>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_encoding

=over

B<Definition:> This holds the byte encodeing of the data stored in the cell

B<Default:> Unicode

B<Range:> Traditional encoding options

B<attribute methods> Methods provided to adjust this attribute

=over

B<encoding>

=over

B<Definition:> returns the attribute value

=back

B<has_encoding>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_merge

=over

B<Definition:> if the cell is part of a group of merged cells this will
store the upper left and lower right cell ID's in a string concatenated
with a ':'

B<Default:> undef

B<Range:> two cell ID's

B<attribute methods> Methods provided to adjust this attribute

=over

B<merge_range>

=over

B<Definition:> returns the attribute value

=back

B<is_merged>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_formula

=over

B<Definition:> if the cell value (raw xml) is calculated based on a
formula the Excel formula string is stored in this attribute.

B<Default:> undef

B<Range:> Excel formula string

B<attribute methods> Methods provided to adjust this attribute

=over

B<formula>

=over

B<Definition:> returns the attribute value

=back

B<has_formula>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_row

=over

B<Definition:> This is the sheet row that the cell was read from.
The value is stored in the user context ( either count from zero
or count from one).

B<Range:> the minimum row to the maximum row

B<attribute methods> Methods provided to adjust this attribute

=over

B<row>

=over

B<Definition:> returns the attribute value

=back

B<has_row>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_col

=over

B<Definition:> This is the sheet column that the cell was read from.
The value is stored in the user context ( either count from zero
or count from one).

B<Range:> the minimum column to the maximum column

B<attribute methods> Methods provided to adjust this attribute

=over

B<col>

=over

B<Definition:> returns the attribute value

=back

B<has_col>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 r

=over

B<Definition:> This is the cell ID of the cell

B<attribute methods> Methods provided to adjust this attribute

=over

B<cell_id>

=over

B<Definition:> returns the attribute value

=back

B<has_cell_id>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_hyperlink

=over

B<Definition:> This stores an arraryref of hyperlinks from the cell

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_hyperlink>

=over

B<Definition:> returns the attribute value

=back

B<has_hyperlink>

=over

B<Definition:> Indicates if the attribute has anything stored

=back

=back

=back

=head3 cell_hidden

=over

B<Definition:> This stores the hidden state of the cell.  The stored
value indicates which entity is controlling hiddeness.

B<Range:> (sheet|column|row|0)

B<attribute methods> Methods provided to adjust this attribute

=over

B<is_hidden>

=over

B<Definition:> returns the attribute value

=back

=back

=back

has cell_coercion =>(
		isa			=> HasMethods[ 'assert_coerce', 'display_name' ],
		reader		=> 'get_coercion',
		writer		=> 'set_coercion',
		predicate	=> 'has_coercion',
		clearer		=> 'clear_coercion',
		handles		=>{
			coercion_name => 'display_name',#
		},
	);

=head3 cell_coercion

=over

B<Definition:> This attribute holds the tranformation code to turn an
unformatted  value into a formatted value.

B<Default:> a L<Type::Tiny> instance with sub types set to assign different
inbound data types to different coercions for the target outcome of formatted
data.

B<Range:> If you wish to set this with your own code it must have two
methods.  First, 'assert_coerce' which will be applied when transforming
the unformatted value.  Second, 'display_name' which will be used to self
identify.  For an example of how to build a custom format see
L<Spreadsheet::Reader::ExcelXML::Worksheet/custom_formats>.

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_coercion>

=over

B<Definition:> returns the contents of the attribute

=back

B<clear_coercion>

=over

B<Definition:> used to clear this attribute

=back

B<set_coercion>

=over

B<Definition:> used to set a new coercion instance.  Implementation
of this method will also switch the cell type to 'Custom'.

=back

B<has_coercion>

=over

B<Definition:> Indicate if any coecion code is applied

=back

B<Delegated method:> Methods delegated from the instance for conversion
type checking.  The name delegated to is listed next to a link for the
default method delegated from.

=over

B<coercion_name> => L<Type::Tiny/display_name>

=back

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Return the merge range in array and hash formats

B<2.> Add calc chain values

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

This software is copyrighted (c) 2016 by Jed

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
