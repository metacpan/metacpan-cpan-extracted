package Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedSharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedSharedStrings-$VERSION";

use 5.010;
use Moose::Role;
requires qw( 
	set_error					where_am_i					has_position
	advance_element_position	start_the_file_over 		i_am_here
	parse_element				grep_node					get_group_return_type
	squash_node
);
use Types::Standard qw(
		Int		Bool		HashRef			is_HashRef		ArrayRef	Enum	is_Int
    );
use Carp qw( confess );
use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_shared_string{
	my( $self, $name ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_shared_string', );
	if( !defined $name ){
		$self->set_error( "Requested shared string name required - none passed" );
		return undef;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Getting the sharedStrings element named: $name", ] );
	
	# Check if the name has already been seen
	my $keep_looking = 1;
	if( $self->_has_ss_key( $name ) ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"This key has already been seen" ] );
		$keep_looking = 0;
	}elsif( $self->_is_cache_complete ){
		$self->set_error( "The shared string named -$name- is unknown and the full file has been searched" );
		return undef;
	}
	
	#Return stored values as available
	if( $self->should_cache_positions ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Retreiving the cached value for shared strings named: $name" ] );
		return $self->_get_ss_position( $self->_get_ss_key( $name ) );
	}
	
	# Find data in the un-parsed remainder as needed
	my $node_attributes;
	my $curr_pos = $self->_get_current_position;
	if( $keep_looking ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"This key has not already been seen - advancing parsing" ] );
		
		# Go to the end of known quickly
		my $last_pos = $self->_get_last_recorded_position;
		if( $self->_get_current_position < $last_pos ){
			$self->advance_element_position( 'si' ) for ( 1 .. ($last_pos - $curr_pos) );
			$self->_set_current_position( $last_pos );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Finished advancing to the end of known territory" ] );
		}
		
		# Advance into the unknow until data is found
		$self->advance_element_position( 'si' ) ;
		my ( $node_depth, $node_name, $node_type ) = $self->location_status;
		$last_pos++;
		$curr_pos++;
		while( $node_name eq 'si' ){# Read the next unknown node here
			$node_attributes = $self->get_attribute_hash_ref;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"This si node has attributes:", $node_attributes ] );
			$self->_set_current_position( $curr_pos );
			$self->_set_last_position( $last_pos );
			$self->_set_ss_key( $node_attributes->{'ss:ID'} => $curr_pos );
			if( $node_attributes->{'ss:ID'} eq $name ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Found the si node named: $name" ] );
				return $self->_ss_ref_to_node( $curr_pos, $node_attributes );
			}elsif( $self->should_cache_positions ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Building position -$curr_pos- for caching" ] );
				$self->_ss_ref_to_node( $curr_pos, $node_attributes );
			}
			$self->advance_element_position( 'si' ) ;
			( $node_depth, $node_name, $node_type ) = $self->location_status;
			$last_pos++;
			$curr_pos++;
		}
		confess "Unsuccefully finished parsing shared strings without finding node named: $node_name";
	}
	
	# Checking if the reqested position is too far
	if( $self->_get_ss_key( $name ) < $curr_pos ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Rewinding the file to start over" ] );
		$self->start_the_file_over;
		$curr_pos = 0;
	}
	
	# Fast forward to the desired position
	my $desired_position = $self->_get_ss_key( $name );
	if( $desired_position > $curr_pos ){
		$self->advance_element_position( 'si' ) for ( 1 .. ($desired_position - $curr_pos) );
		$self->_set_current_position( $desired_position );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Finished advancing to the end of known territory" ] );
	}
	
	#  Collect and return the data
	$node_attributes = $self->get_attribute_hash_ref;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"This si node has attributes:", $node_attributes ] );
	return $self->_ss_ref_to_node( $desired_position, $node_attributes );
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> '_good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);

has _current_position =>(
		isa		=> Int,
		writer	=> '_set_current_position',
		reader	=> '_get_current_position',
		predicate => '_has_current_position',
		default	=> 0,
	);

has _last_recorded_position =>(
		isa		=> Int,
		writer	=> '_set_last_recorded_position',
		reader	=> '_get_last_recorded_position',
		predicate => '_has_last_recorded_position',
		default	=> 0,
	);
	
has _shared_strings_keys =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		default	=> sub{ {} },
		handles	=>{
			_get_ss_key => 'get',
			_set_ss_key => 'set',
			_has_ss_key => 'exists',
		},
		reader => '_get_all_cache_keys',
	);
	
has _shared_string_positions =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		handles	=>{
			_get_ss_position => 'get',
			_set_ss_position => 'set',
			_add_ss_position => 'push',
		},
		reader => '_get_all_cache_positions',
		predicate => '_has_sharedStrings_positions'
	);
	
has _cache_completed =>(
		isa		=> Bool,
		default	=> 0,
		reader	=> '_is_cache_complete',
		writer	=> '_set_cache_completed',
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the sharedStrings unique bits" ] );
	$self->start_the_file_over;
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Currently at libxml2 level: $node_depth",
	###LogSD		"Current node name: $node_name",
	###LogSD		"..for type: $node_type", ] );
	my	$result = 1;
	if( $node_name eq 'SharedStrings' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the SharedStrings node" ] );
	}else{
		$result = $self->advance_element_position( 'SharedStrings' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"attempt to get to the SharedStrings element result: $result" ] );
	}
	
	# Check for empty node
	$self->_read_next_node;
	if( ($self->location_status)[1] eq 'EOF' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The SharedStrings node is empty" ] );
		$result = 0;
	}else{
		$self->start_the_file_over;
	}
	
	# Record file state
	if( $result ){
		$self->_good_load( 1 );
	}else{
		$self->set_error( "No 'SharedStrings' element with content found - can't parse this as a shared strings file" );
	}
}

sub _should_block_formats{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_should_block_formats', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"determining if formats should be blocked: " . $self->get_group_return_type ] );
	return ( $self->get_group_return_type =~ /(unformatted|value|xml_value)/) ? 1 : 0 ;
}

sub _ss_ref_to_node{
	my( $self, $position, $attribute_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_ss_ref_to_node', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Received position -$position- with attribute ref:", $attribute_ref ] );
	my $ss_ref = $self->parse_element( undef, $attribute_ref );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Extracted shared string ref:", $ss_ref ] );
		
	# Convert the perl ref to an Excel style ref
	my $provisional_output;
	if( is_HashRef( $ss_ref ) ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The initial parse is a hash ref"  ] );
		my( $success, $t_node ) = $self->grep_node( $ss_ref, 't' );
		if( $success ){
			$provisional_output = $t_node;# ->{raw_text}
		}elsif( exists $ss_ref->{list} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The initial parse is broken up into list elements", $ss_ref->{list}  ] );
			my ( $raw_text, $rich_text );
			for my $element( @{$ss_ref->{list}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"processing element:", $element  ] );
				my ( $success, $perl_style ) = $self->squash_node( $element );
				push( @$rich_text, length( $raw_text ), $perl_style->{rPr} ) if exists $perl_style->{rPr};
				$raw_text .= $perl_style->{t}->{raw_text};
			}
			@$provisional_output{qw( raw_text rich_text )} = ( $raw_text, $rich_text  );
		}
	}else{
		confess "Found unknown parse return: $ss_ref";
	}
	delete $provisional_output->{'xml:space'} if is_HashRef( $provisional_output );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Built position " . $self->where_am_i . " => ", $provisional_output  ] );
	
	# Cache the position as needed
	my $cache_value =
			!$provisional_output ? undef :
			(scalar( keys %$provisional_output ) == 1 or $self->_should_block_formats) ?
				$provisional_output->{raw_text} : $provisional_output;;
	if( $self->should_cache_positions ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Caching position -$position- as:", $cache_value ] );
		$self->_set_ss_position( $position => $cache_value );
		###LogSD	$phone->talk( level => 'trace', message =>[ "Updated cache:", $self->_get_all_cache_positions  ] );
	}
	###LogSD	$phone->talk( level => 'debug', message =>[ "Returning:", $cache_value  ] );
	return $cache_value;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::NamedSharedStrings - Name based sharedStrings Reader

=head1 SYNOPSIS

	Broken!
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your 
own excel parser or extending this package.  To use the general package for excel 
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::XLSX::Reader::LibXML>, L<Worksheets
|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>.

This class is written to extend L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>.  
It addes to that functionality specifically to read the sharedStrings portion 
(if any) which is most likely a sub file zipped into an .xlsx file.  It does not 
provide connection to other file types or even the elements from other files that are 
related to this file.  This POD only describes the functionality incrementally provided 
by this module.  For an overview of sharedStrings.xml reading see L<Spreadsheet::XLSX::Reader::LibXML::SharedStrings>

=head2 Methods

These are the primary ways to use this class.  For additional SharedStrings options see the 
L<Attributes|/Attributes> section.

=head3 get_shared_string_position( $positive_int )

=over

B<Definition:> This returns the xml L<converted to a deep perl data structure
|/no_formats> from the indicated 'si' position.

B<Accepts:> $positive_int ( a positive integer )

B<Returns:> a L<deep perl data structure|/no_formats> built from the xml at 'si' 
position $positive_int

=back

=head2 Attributes

Data passed to new when creating an instance of this class. For modification of these attributes 
see the listed 'attribute methods'.  For more information on attributes see 
L<Moose::Manual::Attributes>.  The easiest way to modify these attributes are when a class
instance is created and before it is passed to the workbook or parser.

=head3 cache_positions

=over

B<Definition:> Especially for sheets with lots of stored text the parser can slow way down 
when accessing each postion.  This is because an XML::LibXML Reader cannot rewind but must 
start from the beginning and index through the file till it gets to the target position.  This 
is complicated by the fact that the shared strings are not necessarily stored in a logical or 
cell order.  This is especially true for excel sheets that have experienced any significant level 
of manual intervention prior to being read.  This attribute turns (default) on caching for shared 
strings so the parser only has to read through the shared strings once.  When the read is complete 
all the way to the end it will also release the shared strings file in order to free up some space. 
(a small win in exchange for the space taken by the cache).  The trade off here is that all 
intermediate shared strings are L<fully|/no_formats> read before reading the target string.  
This means early reads will be slower.  For sheets that only have numbers stored or at least 
have very few strings this will likely not be a large startup hit (or speed improvement).  
The risk obviously is that the cach will impact memory.  You can use this attribute to turn off 
caching but it is most likely that a cache of that size will necessitate the sheet read to 
slow way down!  The tradeoff of course is the parser shouldn't die.  In order to minimize the 
physical size of the cache if there is only a text string stored in the shared strings position 
then only the string will be stored (not the definition that only a string exists).

B<Default:> 1 = caching is on

B<Range:> 1|0

B<Attribute required:> yes

B<attribute methods> Methods provided to adjust this attribute
		
=over

none - (will be autoset by L<Spreadsheet::XLSX::Reader::LibXML/store_read_positions>)

=back

=back

=head3 no_formats

=over

B<Definition:> Quite often the goal of reading a spreadsheet is to get at the data in the 
cells and not read the visible presentation of the sheet.  If so reading the sharedStrings 
file can be sped up by skipping the stored text formatting when reading from the xml.  
This flag will manage that choice.

B<Default:> 0 = format reading is on

B<Range:> 0|1

B<Attribute required:> yes

B<attribute methods> Methods provided to adjust this attribute
		
=over

none - (will be autoset by L<Spreadsheet::XLSX::Reader::LibXML/group_return_type> ('unformatted' or 'value') => 1

=back

=back

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Nothing yet

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

This software is copyrighted (c) 2014, 2015 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML>

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

#########1#########2 main pod documentation end   5#########6#########7#########8#########9