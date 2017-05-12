package Spreadsheet::XLSX::Reader::LibXML::WorkbookPropsInterface;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::WorkbookPropsInterface-$VERSION";

use	Moose::Role;
requires qw(
	location_status			advance_element_position		parse_element
	squash_node
);
	#~ _get_rel_info			_get_sheet_info					_set_sheet_info
	#~ get_sheet_names
###LogSD	requires 'get_log_space', 'get_all_space';
use Types::Standard qw( Bool StrMatch Str );#Enum ArrayRef HashRef 
use Data::Dumper;
use lib	'../../../../../lib',;
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my 	$potential_top_headers =[qw(
		DocumentProperties		cp:coreProperties 
	)];

my	$method_lookup = {
		Author				=> '_set_creator',
		'dc:creator'		=> '_set_creator',
		LastAuthor			=> '_set_modified_by',
		'cp:lastModifiedBy'	=> '_set_modified_by',
		Created				=> '_set_date_created',
		'dcterms:created'	=> '_set_date_created',
		'dcterms:modified'	=> '_set_date_modified',
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'WorkbookPropsInterface' }

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> '_good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);
	
has _file_creator =>(
		isa		=> Str,
		reader	=> '_get_creator',
		writer	=> '_set_creator',
		clearer	=> '_clear_creator',
	);
	
has _file_modified_by =>(
		isa		=> Str,
		reader	=> '_get_modified_by',
		writer	=> '_set_modified_by',
		clearer	=> '_clear_modified_by',
	);
	
has _file_date_created =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> '_get_date_created',
		writer	=> '_set_date_created',
		clearer	=> '_clear_date_created',
	);
	
has _file_date_modified =>(
		isa		=> StrMatch[qr/^\d{4}\-\d{2}\-\d{2}/],
		reader	=> '_get_date_modified',
		writer	=> '_set_date_modified',
		clearer	=> '_clear_date_modified',
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the WorkbookPropsInterface unique bits" ] );
	
	# Find the right header
	my $result;
	$self->start_the_file_over;
	for my $potential ( @$potential_top_headers ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Looking for: $potential", $self->location_status ] );
		$self->start_the_file_over;
		if( ($self->location_status)[1] eq $potential ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Already at: $potential" ] );
			$result = 1;
		}else{
			$result = $self->advance_element_position( $potential );
		}
		last if $result;
	}
	
	# turn the sheet into a ref as available
	my $sheet_ref;
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Pulling the lookup ref" ] );
		$sheet_ref = $self->parse_element;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"parsed sheet ref is:", $sheet_ref ] );
		$sheet_ref = $self->squash_node( $sheet_ref );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"squashed sheet ref is:", $sheet_ref ] );
		
	}
		
	# Load values as available
	if( $sheet_ref ){
		my $x = 0;
		for my $header ( keys %$sheet_ref ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"processing header: $header" ] );
			if( exists $method_lookup->{$header} and $sheet_ref->{$header}->{raw_text} ){
				my $method = $method_lookup->{$header};
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Implementing -$method- with value: $sheet_ref->{$header}->{raw_text}" ] );
				$self->$method( $sheet_ref->{$header}->{raw_text} );
			}
			$x++;
		}
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Closing out the xml file" ] );
	$self->_close_file_and_reader;
	$self->_good_load( 1 );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::WorkbookPropsInterface - Workbook docProps interface

=head1 SYNOPSIS


    
=head1 DESCRIPTION

 NOT WRITTEN YET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

B<1.> Add the workbook attributute to the documentation

=back

=head1 TODO

=over

B<1.> Possibly add caching?  This would only be valuable for non-sequential reads  

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

L<version> - 0.77

L<perl 5.010|perl/5.10.0>

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<Carp> - confess

L<Type::Tiny> - 1.000

L<Clone> - clone

L<MooseX::ShortCut::BuildInstance> - build_instance should_re_use_classes

L<Spreadsheet::XLSX::Reader::LibXML> - which has it's own dependancies

L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>

L<Spreadsheet::XLSX::Reader::LibXML::WorksheetToRow>

L<Spreadsheet::XLSX::Reader::LibXML::Row>

L<Spreadsheet::XLSX::Reader::LibXML::Cell>

L<Spreadsheet::XLSX::Reader::LibXML::Types>

L<Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow>

L<Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData>

L<Moose::Role>

=over

B<requires>

any re-use of this role (Interface) requires the following methods. Links are provided 
to the existing package implementation for study.

=over

L<_min_row|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_min_row>

L<_max_row|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_max_row>

L<_min_col|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_min_col>

L<_max_col|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_max_col>

L<_get_col_row|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_get_col_row>

L<_get_next_value_cell|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_get_next_value_cell>

L<_get_row_all|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_get_row_all>

L<_get_merge_map|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_get_merge_map>

L<is_sheet_hidden|Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_get_merge_map>

=back

=back

=back

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::ParseXLSX> - 2007+

L<Spreadsheet::Read> - Generic

L<Spreadsheet::XLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9