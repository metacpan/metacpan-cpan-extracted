package Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
		get_defined_conversion		start_the_file_over			close_the_file
		advance_element_position	parse_element				set_defined_excel_formats
		current_named_node			set_error					squash_node
		parse_excel_format_string	good_load
	);
use Types::Standard qw( Bool HashRef );
use Carp qw( confess );
use Clone qw( clone );

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9

my	$cell_attributes ={
		Font			=> 'cell_font',
		Borders			=> 'cell_border',
		Interior		=> 'cell_fill',
		'ss:Name'		=> 'cell_style',
		NumberFormat	=> 'cell_coercion',
		Alignment		=> 'cell_alignment',
	};

my	$xml_from_cell ={
		cell_font		=> 'fontId',
		cell_border		=> 'borderId',
		cell_fill		=> 'fillId',
		cell_style		=> 'xfId',
		cell_coercion	=> 'numFmtId',
		cell_alignment	=> 'alignment',
	};

my $date_keys ={# SpreadsheetML to Excel 2007+ custom date formats
		'Short Date'	=> 'yyyy-mm-dd',
		'Fixed'			=> '0.00',
		'ShortDate'	=> 'yyyy-mm-dd',
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_format{
	my( $self, $name, $header, $exclude_header ) = @_;
	my	$xml_target_header = $header ? $header : '';#$xml_from_cell->{$header}
	my	$xml_exclude_header = $exclude_header ? $exclude_header : '';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_format', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Get defined formats named: $name",
	###LogSD			( $header ? "Returning only the values for header: $header - $xml_target_header" : '' ),
	###LogSD			( $exclude_header ? "..excluding the values for header: $exclude_header - $xml_exclude_header" : '' ) , ] );


	my $target_ref;
	my $found_it = 0;
	if( $self->_has_styles ){# Check for stored value - when caching implemented
		if( !$self->_has_s_name( $name ) ){
			$self->set_error( "Style named |$name| is not recorded!" );
			return undef;
		}
		$target_ref = clone( $self->_get_s_name( $name ) );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The complete cached style is:", $target_ref, ] );
		$found_it = 1;
	}else{# pull the value the long (hard and slow) way
		my $x = 0;
		$self->start_the_file_over;
		while( !$found_it ){
			###LogSD		$phone->talk( level => 'debug', message => [
			###LogSD			"Looking for a 'Style' node on pass: $x", ] );
			my ( $result, $node_name, $node_level, $result_ref ) =
				$self->advance_element_position( 'Style' );
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"After search for header 'Style' arrived at node -$node_name- with result: $result" ] );
			last if !$result;
			my $xml_ref = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Parsing the node to find the name", $xml_ref ] );
			my $perlized_ref = $self->squash_node( $xml_ref );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"After squashing:", $perlized_ref ] );
			( my $element_name, $target_ref ) = $self->_transform_element( $perlized_ref );
			if( $element_name eq $name ){
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Found requested node named: $element_name" ] );
				$found_it = 1;
				last;
			}
		}
	}

	# Restrict the return value based on passed parameters
	if( $found_it ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The style named -$name- is:", $target_ref  ] );
		if( $header ){
			$target_ref = $target_ref->{$header} ? { $header => $target_ref->{$header} } : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The style with target header -$header- only is:", $target_ref  ] );
		}elsif( $exclude_header ){
			delete $target_ref->{$exclude_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The style with exclude header -$exclude_header- removed is:", $target_ref  ] );
		}
	}
	return $target_ref;
}

sub get_default_format{#### Re-use the get_format method for this since we are using names
	my( $self, $header, $exclude_header ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_default_format', );
	my	$name = 'Default';
	###LogSD		$phone->talk( level => 'info', message =>[ "Get the 'Default' format" ] );
	return $self->get_format( $name, $header, $exclude_header );
}

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );

	# Check for empty node and react
	my( $result, $node_name, $node_level, $result_ref );
	my $current_node = $self->current_node_parsed;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"The current node is:", $current_node ] );
	if( (keys %$current_node)[0] eq 'Styles' ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Found the Styles node" ] );
		$result = 2;
		$node_name = 'Styles';
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'Styles' );
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"After search for header 'Style' arrived at node -$node_name- with result: $result" ] );
	}
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Found a Styles node" ] );
		$self->good_load( 1 );
	}else{
		$self->set_error( "No 'Styles' element with content found - can't parse this as a styles file" );
		return undef;
	}

	# Cache nodes as needed (No standard number formats to record)
	my ( $success, $top_level_ref );
	if( $self->should_cache_positions ){
		$top_level_ref = $self->parse_element;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Parsing the whole thing for caching", $top_level_ref ] );
		$self->close_the_file;# Don't need the file open any more!

		$top_level_ref = $self->squash_node( $top_level_ref );#, 'numFmts'
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Squashed ref:", $top_level_ref ] );

		# Handle the single style case
		if( exists $top_level_ref->{Style} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Converting a single style node" ] );
			$self->_add_style_element( $top_level_ref->{Style} );
		}else{
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Converting a list of style nodes" ] );
			for my $style ( @{$top_level_ref->{list}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Loading:", $style ] );
				$self->_add_style_element( $style );
			}
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Final style ref:",  $self->_get_all_cache ] );
	}
	return 1;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _styles =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		handles	=>{
			_get_s_name => 'get',
			_set_s_name => 'set',
			_has_s_name => 'exists',
		},
		reader => '_get_all_cache',
		predicate => '_has_styles'
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _add_style_element{
	my( $self, $sub_element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits_add_style_element', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Adding sub element:", $sub_element, "To style ref:", $self->_get_all_cache ] );
	( my $element_name, $sub_element ) = $self->_transform_element( $sub_element );
	$self->_set_s_name( $element_name => $sub_element );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Updated style named -$element_name- ref:", $sub_element ] );
}

sub _transform_element{
	my( $self, $sub_element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_transform_element', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Transforming sub element:", $sub_element, ] );
	my ( $element_name, $new_sub );
	for my $key ( keys %$sub_element ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing sub element key: $key" ] );
		if( $key =~ /\:ID/ ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Found the style name: $sub_element->{$key}" ] );
			$element_name = $sub_element->{$key};
		}elsif( exists $cell_attributes->{$key} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Key matches cell attribute: $cell_attributes->{$key}" ] );
			if( $key =~ /NumberFormat/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found a number format: ", $sub_element->{$key} ] );
				my $replaced_string =
					!defined $sub_element->{$key} ? undef :
					exists( $date_keys->{$sub_element->{$key}->{'ss:Format'}} ) ?
						$date_keys->{$sub_element->{$key}->{'ss:Format'}} :
						$sub_element->{$key}->{'ss:Format'} ;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Replace string result: $replaced_string", ] );
				if( $replaced_string ){
					$replaced_string =~ /^(\[[A-Z]{3}\])?(.*)/;######### Take this back out when localization is implemented
					$replaced_string = $2;
				}
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Processing the date format string: " . ($replaced_string//'undef') ] );
				$new_sub->{$cell_attributes->{$key}} =
					defined( $replaced_string ) ?
						$self->parse_excel_format_string( $replaced_string ) : undef;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Finished the excel format parsing" ] );
			}else{
				$new_sub->{$cell_attributes->{$key}} = $sub_element->{$key};
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated new sub:", $new_sub ] );
		}
	}
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning element name: $element_name" ] );
	###LogSD	$phone->talk( level => 'trace', message =>[ "..with ref:", $new_sub ] );
	return( $element_name, $new_sub );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles - Support for Excel 2003 XML Styles files

=head1 SYNOPSYS

	!!!! Example code - will not run standalone !!!!

	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::XMLReader::NamedStyles;
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	my	$test_instance	=	build_instance(
			package => 'StylesInterface',
			superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			add_roles_in_sequence => [
				'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
			],
			file => ! Styles file handle with extracted content !
			workbook_inst => $workbook_instance,<--- Built elswhere!!!
		);

=head1 DESCRIPTION

This role is written to provide the methods 'get_format' and 'get_default_format' for
the styles file reading where the styles file elements are called out by name.  This
generally implies that the styles section was a node in a flat xml file written to the
Microsoft (TM) Excel 2003 xml format.  The extration should be accomplished external
to this instance creation usually with L<Spreadsheet::Reader::ExcelXML::XMLReader/extract_file>.

=head2 Requires

These are the methods required by this role and their default provider.  All
methods are imported straight across with no re-naming.

=over

L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/get_defined_conversion( $position )>

l<Spreadsheet::Reader::Format::ParseExcelFormatStrings/parse_excel_format_string( $string, $name )>

L<Spreadsheet::Reader::Format::FmtDefault/set_defined_excel_formats( %args )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_named_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node( $node )>

L<Spreadsheet::Reader::ExcelXML::Error/set_error( $error_string )>

=back

=head2 Method(s)

These are the methods mandated by this interface.

=head3 get_format( $name, [$header], [$exclude_header] )

=over

B<Definition:> This will return the styles information from the identified $name in the
style node.  The target name is usually drawn from the cell data stored in the worksheet.
The information is returned as a perl hash ref.  Since the styles data is in two tiers it
finds all the subtier information for each indicated piece and appends them to the hash
ref as values for each type key.

B<Accepts position 0:> $name = a (sub) node name indicating which styles node should be
returned

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

=head3 load_unique_bits

=over

B<Definition:> When the xml file first loads this is available to pull customized data.
It mostly pulls metadata and stores it in hidden attributes for use later.  If all goes
according to plan it sets L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load> to 1.

B<Accepts:> Nothing

B<Returns:> Nothing

=back

=head2 Attributes

Data passed to new when creating an instance with this role. For
modification of this(ese) attribute(s) see the listed 'attribute
methods'.  For more information on attributes see
L<Moose::Manual::Attributes>.  The easiest way to modify this(ese)
attribute(s) is during instance creation before it is passed to the
workbook or parser.

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
