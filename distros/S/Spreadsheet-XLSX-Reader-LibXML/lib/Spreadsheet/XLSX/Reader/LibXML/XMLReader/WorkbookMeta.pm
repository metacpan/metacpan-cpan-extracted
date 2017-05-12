package Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorkbookMeta;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorkbookMeta-$VERSION";

use	Moose::Role;
requires qw(
	advance_element_position	parse_element			start_the_file_over
	set_exclude_match			_close_file_and_reader	location_status
);
#~ ###LogSD	requires 'get_log_space', 'get_all_space';
use Types::Standard qw( Enum ArrayRef HashRef Bool);
#~ use Carp 'confess';
#~ use Clone 'clone';
use lib	'../../../../../lib',;
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> '_good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);

has _epoch_year =>(
		isa			=> Enum[qw( 1900 1904 )],
		writer		=> '_set_epoch_year',
		reader		=> '_get_epoch_year',
		default		=> 1900,
	);

has _sheet_list =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_sheet_list',
		clearer	=> '_clear_sheet_list',
		reader	=> '_get_sheet_list',
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
		reader	=> '_get_sheet_lookup',
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
		reader	=> '_get_rel_lookup',
		handles	=>{
			_get_rel_info => 'get',
		},
		default	=> sub{ {} },
	);

has _id_lookup =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> '_set_id_lookup',
		reader	=> '_get_id_lookup',
		handles	=>{
			_get_id_info => 'get',
		},
		default	=> sub{ {} },
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the WorkbookMetaInterface unique bits" ] );
	
	# Set date epoch
	$self->start_the_file_over;
	my $result = $self->advance_element_position( 'Date1904' );
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
	$result = undef;
	for my $top_node (qw( Workbook workbook ) ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Attempting to match the workbook node to: $top_node" ] );
		$self->start_the_file_over;
		if( ($self->location_status)[1] eq $top_node ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Already at: $top_node" ] );
			$result = 1;
		}else{
			$result = $self->advance_element_position( $top_node );
		}
		last if $result;
	}
	confess "Could not find any sheets" if !$result;
	$self->set_exclude_match( '(Table|fileVersion|workbookPr|bookViews|calcPr|pivotCaches|DocumentProperties|ExcelWorkbook|Styles|PageSetup|Panes|Print|ProtectObjects|ProtectScenarios)' );
	#~ $self->set_strip_keys( 1 );
	my $sheets_node = $self->parse_element( 4 );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"parsed sheet ref is:", $sheets_node ] );
	
	# Scrub worksheet and chartsheet level
	my $x = 0;
	my ( $list, $rel_lookup, $id_lookup, $new_sheet_ref );
	for my $sheet ( @{$sheets_node->{list_keys}} ){ 
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing potential sheet position -$x- named: $sheet", ] );
		if( $sheet =~ /sheet/i ){
			if( exists $sheets_node->{list}->[$x]->{attributes} ){
				my $sub_sheet = $sheets_node->{list}->[$x]->{attributes};
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Processing attributes:", $sub_sheet] );
				$sub_sheet->{sheetId} = ($x + 1);
				my $sheet_name;
				for my $key ( keys %$sub_sheet ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Testing for name with key: $key",] );
					$sheet_name = $sub_sheet->{$key} if $key =~ /name/i;
				}
				push @$list, $sheet_name;
				my $sheet_hidden = 0;
				my $y = 0;
				FINDHIDDEN: for my $key ( @{$sheets_node->{list}->[$x]->{list_keys}} ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Looking for worksheet options in key: $key",] );
					if( $key =~ /WorksheetOptions/i ){
						my $options = $sheets_node->{list}->[$x]->{list}->[$y];
						my $z = 0;
						for my $key ( @{$options->{list_keys}} ){
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"Looking for visble in key: $key",] );
							if( $key =~ /Visible/i and $options->{list}->[$z]->{raw_text} =~ /Hidden/i ){
								$sheet_hidden = 1;
								last FINDHIDDEN;
							}
							$z++;
						}
					}
					$y++;
				}
				@{$new_sheet_ref->{$sheet_name}}{ 'sheet_id', 'sheet_position', 'is_hidden', 'sheet_name', 'file' } = (
						$sub_sheet->{sheetId}, $x, $sheet_hidden, $sheet_name, [ $sheet, $x + 1 ],
				);
				
				$new_sheet_ref->{$sheet_name}->{sheet_type} = $sheet =~ /work/i ? 'worksheet' : $sheet =~ /chart/i ? 'chartsheet' : undef;
				$id_lookup->{$sub_sheet->{sheetId}} = $sheet_name;
			}
			$x++;
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"updated sheet ref is:", $new_sheet_ref,
	###LogSD		"sheet list is:", $list,
	###LogSD		"id lookup is:", $id_lookup ] );
	
	#~ # Add pivot cache lookups
	#~ $self->start_the_file_over;
	#~ $result = $self->advance_element_position( 'pivotCaches' );;
	#~ my $pivot_ref = $self->parse_element;
	#~ ###LogSD	$phone->talk( level => 'debug', message => [
	#~ ###LogSD		"parsed pivot ref is:", $pivot_ref ] );
	
	#~ # Clean up xml ref as needed
	#~ if( exists $pivot_ref->{pivotCache} ){
		#~ push @{$pivot_ref->{list}}, clone( $pivot_ref->{pivotCache} );
		#~ delete $pivot_ref->{pivotCache};
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"updated pivot ref is:", $pivot_ref ] );
	#~ }
	#~ if( exists $pivot_ref->{list} ){
		#~ for my $pivot ( @{$pivot_ref->{list}} ){
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Processing pivot:", $pivot] );
			#~ $pivot->{cacheId} = $x if !exists $pivot->{cacheId};
			#~ $pivot->{'r:id'} = "rId$x" if !exists $pivot->{'r:id'};
			#~ $rel_lookup->{$pivot->{'r:id'}} = $pivot->{cacheId};
			#~ $id_lookup->{$pivot->{cacheId}} = $pivot->{'r:id'};
			#~ $x++;
		#~ }
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"final rel lookup is:", $rel_lookup,
		#~ ###LogSD		"final id lookup is:", $id_lookup ] );
	#~ }
	
	$self->_set_sheet_list( $list );
	$self->_set_sheet_lookup( $new_sheet_ref );
	$self->_set_id_lookup( $id_lookup );
	$self->_good_load( 1 );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorkbookMeta - XML file Workbook Meta unique reader

=head1 SYNOPSIS


    
=head1 DESCRIPTION

 NOT WRITTEN YET!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

Nothing Yet 

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