package Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels-$VERSION";

use	Moose::Role;
requires qw(
	current_node_parsed			advance_element_position		parse_element
	squash_node					get_rel_info					get_sheet_info
	get_sheet_names				good_load
);
###LogSD	requires 'get_log_space', 'get_all_space';
use Types::Standard qw( Enum ArrayRef HashRef Bool );
use Data::Dumper;
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
	###LogSD			"Setting the WorkbookRelsInterface unique bits" ] );

	# Build the list
	$self->start_the_file_over;
	my ( $found_member_names, $worksheet_list, $chartsheet_list );

	# Handle a zip based file
	my( $result, $node_name, $node_level, $result_ref ) = $self->advance_element_position( 'Relationship' );
	while( $result and $node_name eq 'Relationship'  ){
		my $relationship_ref = $self->squash_node( $self->parse_element );# Cleans up end nodes without other work
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed sheet ref is:", $relationship_ref ] );
		my $rel_ref = $self->get_rel_info( $relationship_ref->{Id} ) ;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Current rel ref:", $rel_ref ] );
		if( $rel_ref ){
			my	$target = 'xl/' .  $relationship_ref->{Target};
			my	$sheet_ref = $self->get_sheet_info( $rel_ref );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Building relationship for: $relationship_ref->{Id}",
			###LogSD		"With target: $target",
			###LogSD		"For sheet -$rel_ref- with info:", $sheet_ref ] );
			$target =~ s/\\/\//g;
			if( $target =~ /worksheets(\\|\/)/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found a worksheet" ] );
				$sheet_ref->{file} = $target;
				$sheet_ref->{sheet_type} = 'worksheet';
				$self->_set_sheet_info( $rel_ref => $sheet_ref );
				$worksheet_list->[$sheet_ref->{sheet_position}] = $rel_ref;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Updating sheet member key -$rel_ref- with:", $sheet_ref,
				###LogSD		"..and updated worksheet list:", $worksheet_list ] );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"..resulting new sheet lookup for sheet: $rel_ref", $self->get_sheet_info( $rel_ref ), ] );
				$found_member_names = 1;
			}elsif( $target =~ /chartsheets(\\|\/)/ ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found a chartsheet" ] );
				$sheet_ref->{file} = $target;
				$sheet_ref->{sheet_type} = 'chartsheet';
				$self->_set_sheet_info( $rel_ref => $sheet_ref );
				$chartsheet_list->[$sheet_ref->{sheet_position}] = $rel_ref;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Updating sheet member key -$rel_ref- with:", $sheet_ref,
				###LogSD		"..and updated chartsheet list:", $chartsheet_list ] );
				$found_member_names = 1;
			}else{# Add method for pivot table lookup later
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Not a worksheet or a chartsheet - possible pivot table lookup" ] );
				#~ $pivot_lookup->{$rel_ID} = $target;
			}
		}
		( $result, $node_name, $node_level, $result_ref ) = $self->advance_element_position( 'Relationship' );# Advance to the next start
	}
	if( !$found_member_names ){# Handle and xml based file
		confess "Couldn't find any zip member (file) names for the sheets - is the workbook empty?";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the worksheet list with:", $worksheet_list ] );
	map{ $self->_add_worksheet( $_ ) if $_ } @$worksheet_list if $worksheet_list;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the chartsheet list with:", $chartsheet_list ] );
	map{ $self->_add_chartsheet( $_ ) if $_ } @$chartsheet_list if $chartsheet_list;

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Closing out the xml file" ] );
	$self->close_the_file;
	$self->good_load( 1 );
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _sheet_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		reader	=> 'get_sheet_lookup',
		handles	=>{
			_set_sheet_info => 'set',
		},
		default	=> sub{ {} },
	);

has _worksheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		reader	=> 'get_worksheet_list',
		handles	=>{
			_add_worksheet	=> 'push',
		},
		default	=> sub{ [] },
	);

has _chartsheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		reader	=> 'get_chartsheet_list',
		handles	=>{
			_add_chartsheet  => 'push',
		},
		default	=> sub{ [] },
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels - Workbook Rels Zip file unique reader

=head1 SYNOPSIS

	use Types::Standard qw( HashRef );
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Types::Standard qw( HashRef );
	use Data::Dumper;
	my	$workbook_instance = build_instance(
			package	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
			add_attributes =>{
				_rel_lookup =>{
					isa		=> HashRef,
					traits	=> ['Hash'],
					handles	=>{ get_rel_info => 'get', },
					default	=> sub{ {
						'rId2' => 'Sheet5',
						'rId3' => 'Sheet1',
						'rId1' => 'Sheet2'
					} },
				},
				_sheet_lookup =>{
					isa		=> HashRef,
					traits	=> ['Hash'],
					handles	=>{ get_sheet_info => 'get', },
					default	=> sub{ {
						'Sheet1' => {
							'sheet_id' => '1',
							'sheet_position' => 2,
							'sheet_name' => 'Sheet1',
							'is_hidden' => 0,
							'sheet_rel_id' => 'rId3'
						},
						'Sheet2' => {
							'sheet_position' => 0,
							'sheet_name' => 'Sheet2',
							'sheet_id' => '2',
							'sheet_rel_id' => 'rId1',
							'is_hidden' => 0
						},
						'Sheet5' => {
							'sheet_position' => 1,
							'sheet_name' => 'Sheet5',
							'sheet_id' => '3',
							'sheet_rel_id' => 'rId2',
							'is_hidden' => 1
						}
					} },
				},
			},
			add_methods =>{
				get_sheet_names => sub{ [
					'Sheet2',
					'Sheet5',
					'Sheet1'
				] },
			}
		);
	my	$rels_instance =  build_instance(
			superclasses	=> ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			package	=> 'WorkbookRelsInterface',
			add_roles_in_sequence =>[
				'Spreadsheet::Reader::ExcelXML::ZipReader::WorkbookRels',
				'Spreadsheet::Reader::ExcelXML::WorkbookRelsInterface',
			],
			file => 'xl/_rels/workbook.xml.rels',
			workbook_inst => $workbook_instance,
		);
	print Dumper( $rels_instance->get_worksheet_list );

	###########################
	# SYNOPSIS Screen Output
	# 01: $VAR1 = [
	# 02: 	'Sheet2',
	# 03: 	'Sheet5',
	# 04:   'Sheet1'
	# 05: ]
	###########################

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This is the Zip based file adaptor for reading the workbook rels data and then updating
the general workbook metadata. The transformed data is then accesable through L<Methods
|/Methods>.   The goal is to standardize the outputs of this transformation metadata from
non standard inputs.

=head2 Required Methods

These are the methods required by the role.  A link to the default implementation of
these methods is provided.

L<Spreadsheet::Reader::ExcelXML/get_sheet_info( $name )>

L<Spreadsheet::Reader::ExcelXML/get_rel_info( $rel_id )>

L<Spreadsheet::Reader::ExcelXML/get_sheet_names>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_node_parsed>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element( [$depth] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node( $node )>

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

=head3 get_sheet_lookup

=over

B<Definition:> The sheet lookup is a hashref with keys as sheet names and the values are a sub
hashref with $key => $value pairs of sheet meta data containing information like hiddeness and
location.  This method returns the full set.

B<Accepts:> nothing

B<Returns:> a full hashref of hashrefs

=back

=head3 get_worksheet_list

=over

B<Definition:> returns an ordered arrayref conataining only worksheet names in their visible order
from the Excel workbook.

B<Accepts:> nothing

B<Returns:> an arrayref of names

=back

=head3 get_chartsheet_list

=over

B<Definition:> returns an ordered arrayref conataining only chartsheet names in their visible order
from the Excel workbook.

B<Accepts:> nothing

B<Returns:> an arrayref of names

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
