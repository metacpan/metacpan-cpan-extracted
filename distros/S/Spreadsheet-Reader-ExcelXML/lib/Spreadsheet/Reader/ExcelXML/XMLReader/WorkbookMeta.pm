package Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta-$VERSION";

use	Moose::Role;
requires qw(
	advance_element_position	parse_element			start_the_file_over
	close_the_file				squash_node				current_node_parsed
	next_sibling				skip_siblings			good_load
);
use Types::Standard qw( Enum ArrayRef HashRef Bool);
use lib	'../../../../../lib',;
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the WorkbookMetaInterface unique bits" ] );

	# Set date epoch
	$self->start_the_file_over;
	my( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position( 'Date1904' );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Apple date search result: " . ($result//'undef') ] );
	my $epoch_start = 1900;
	if( $result ){
		my $workbookPr_ref = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"This is a 1904 epoch sheet" ] );
		$epoch_start = 1904;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Setting epoch start to: $epoch_start" ] );
	$self->_set_epoch_year( $epoch_start );
	###LogSD	$phone->talk( level => 'trace', message =>[  "Epoch year set" ] );

	# Build sheet list
	my( $sheet_lookup, $id_lookup, $sheet_list );
	$self->start_the_file_over;
	( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position( 'Worksheet' );# Chartsheets don't appear to be allowed in SpreadsheetML format
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Arrived at node name -$node_name- with result: $result" ] );
	if( $result ){
		my $position = 0;
		my $top_ref = $self->current_node_parsed;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Current node parsed to:", $top_ref ] );
		COLLECTSHEETDATA: while( $node_name eq 'Worksheet' ){# Redundant on the first pass
			my $sheet_name = $top_ref->{Worksheet}->{'ss:Name'};
			my $sheet_id = $position + 1;
			push @$sheet_list, $sheet_name;
			$id_lookup->{$sheet_id} = $sheet_name;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Worksheet node named: $sheet_name",
			###LogSD		"Worksheet position: $position",
			###LogSD		"Worksheet ID: $sheet_id", $top_ref, $sheet_list, $id_lookup ] );
			( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Arrived at node name -$node_name- with result: $result" ] );
			last COLLECTSHEETDATA if !$result;
			my $lower_ref = $self->current_node_parsed;
			###LogSD	$phone->talk( level => 'debug', message =>[  "Lower node is:", $lower_ref ] );
			COLLECTWORKSHEETOPTIONS: while( $result and $node_name ne 'WorksheetOptions' ){
				( $result, $node_name, $node_level, $node_ref ) = $self->next_sibling;
				last COLLECTWORKSHEETOPTIONS if !$result;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Next sibling node may be: $node_name", ] );
			}
			# Load the sheet settings
			my $options_ref;
			if( $result ){# For specific settings in the file
				$options_ref = $self->squash_node( $self->parse_element );
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Fulls WorksheetOptions node:", $options_ref ] );
				delete $options_ref->{raw_text};
				delete $options_ref->{xmlns};
			}
			$options_ref->{is_hidden} =
				(exists $options_ref->{Visible} and $options_ref->{Visible} eq 'SheetHidden') ? 1 : 0;
			@$options_ref{qw( sheet_id sheet_name sheet_position )} =
				( $sheet_id, $sheet_name, $position );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Built sheet data:", $options_ref ] );
			$sheet_lookup->{$sheet_name} = $options_ref;
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Updated sheet lookup:", $sheet_lookup, $self->current_node_parsed ] );
			( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position( 'Worksheet' );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Advanced to node -$node_name- with the result: " . ($result//'') ] );
			last COLLECTSHEETDATA if !$result;
			$top_ref = $self->current_node_parsed;
			###LogSD	$phone->talk( level => 'debug', message =>[  "Next top node is:", $top_ref] );
			$position++;
		}
		###LogSD	$phone->talk( level => 'info', message =>[  "Made it out of COLLECTSHEETDATA" ] );
	}else{
		confess "Could not find any worksheets";
	}

	###LogSD	$phone->talk( level => 'debug', message =>[  "Setting attributes" ] );
	$self->_set_sheet_list( $sheet_list );
	$self->_set_sheet_lookup( $sheet_lookup );
	$self->_set_id_lookup( $id_lookup );
	$self->close_the_file;
	$self->good_load( 1 );
	###LogSD	$phone->talk( level => 'info', message =>[  "Returning" ] );
	return 1;
}



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _epoch_year =>(
		isa			=> Enum[qw( 1900 1904 )],
		writer		=> '_set_epoch_year',
		reader		=> 'get_epoch_year',
		default		=> 1900,
	);

has _sheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_sheet_list',
		clearer	=> '_clear_sheet_list',
		reader	=> 'get_sheet_list',
		handles	=>{
			_get_sheet_name => 'get',
			_sheet_count => 'count',
		},
		default	=> sub{ [] },
	);

has _sheet_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_sheet_lookup',
		clearer	=> '_clear_sheet_lookup',
		reader	=> 'get_sheet_lookup',
		handles	=>{
			_get_sheet_info => 'get',
			_set_sheet_info => 'set',
		},
		default	=> sub{ {} },
	);

has _rel_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_rel_lookup',
		reader	=> 'get_rel_lookup',
		handles	=>{
			_get_rel_info => 'get',
		},
		default	=> sub{ {} },
	);

has _id_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_id_lookup',
		reader	=> 'get_id_lookup',
		handles	=>{
			_get_id_info => 'get',
		},
		default	=> sub{ {} },
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta - XML file Workbook Meta unique reader

=head1 SYNOPSIS

	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta;
	use Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface; # Optional
	$meta_instance = build_instance(
		superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
		add_roles_in_sequence =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader::WorkbookMeta',
			'Spreadsheet::Reader::ExcelXML::WorkbookMetaInterface',
		],
		file => 'TestBook.xml', (for xml flat files the meta parser needs the whole file)
	);
	$meta_instance->get_epoch_year;

	###########################
	# SYNOPSIS Screen Output
	# 01: 1904
	###########################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This is the XML based file adaptor for reading the workbook meta data.  The file can contain
several default sets of information that should be gathered.  They can all be retrieved post
file initialization with L<Methods|/Methods>.  The goal is to standardize the outputs of this
metadata from non standard inputs.

=head2 Required Methods

These are the methods required by the role.  A link to the default implementation of
these methods is provided.

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element( [$depth] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node( $node )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_node_parsed>

L<Spreadsheet::Reader::ExcelXML::XMLReader/next_sibling>

L<Spreadsheet::Reader::ExcelXML::XMLReader/skip_siblings>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load( $state )>

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

=head3 get_epoch_year

=over

B<Definition:> returns the parsed epoch year that should be found in this file

B<Accepts:> nothing

B<Returns:> (1900|1904)

=back

=head3 get_sheet_list

=over

B<Definition:> returns the full array ref containg all discovered sheets in the
file.  This will include worksheets and chartsheets.

B<Accepts:> nothing

B<Returns:> an array ref of strings

=back

=head3 get_rel_lookup

=over

B<Definition:> returns the hashref with relId's as keys and the sheet name as
values

B<Accepts:> nothing

B<Returns:> a hash ref with $relId => $sheet_name combos

=back

=head3 get_id_lookup

=over

B<Definition:> returns the hashref with sheet id's as keys and the sheet
name as values.  I beleive that Sheet ID's are the id number used in vbscript
to identify the sheet.

B<Accepts:> nothing

B<Returns:> a hash ref with $sheetId => $sheet_name combos

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
