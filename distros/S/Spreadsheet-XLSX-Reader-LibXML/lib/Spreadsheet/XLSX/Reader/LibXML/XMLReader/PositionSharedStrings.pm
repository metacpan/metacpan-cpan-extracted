package Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionSharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionSharedStrings-$VERSION";

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
	my( $self, $position ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_shared_string', );
	if( !defined $position ){
		$self->set_error( "Requested shared string position required - none passed" );
		return undef;
	}elsif( !is_Int( $position ) ){
		confess "The passed position -$position- is not an integer";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Getting the sharedStrings position: $position",
	###LogSD		"From current position: " . ($self->has_position ? $self->where_am_i : '(none yet)'), ] );
	
	#checking if the reqested position is too far
	if( $position > $self->_get_unique_count - 1 ){
		$self->set_error( "Asking for position -$position- (from 0) but the shared string " .
							"max cell position is: " . ($self->_get_unique_count - 1) );
		return undef;#  fail
	}
	
	my ( $return, $success );
	# handle cache retrieval
	if( $self->should_cache_positions and $self->_last_cache_position >= $position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Retreiving position -$position- from cache" ] );
		$return = $self->_get_ss_position( $position );
		$success = 1;
	}
	
	# checking if the reqested (last) position is stored (no caching)
	if( !$success and $self->_has_last_position and $position == $self->_get_last_position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Already built the answer for position: $position", 
		###LogSD		$self->_get_last_position_ref						] );
		$return = $self->_get_last_position_ref;
		$success = 1;
	}
		
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Success: " . ($success//'not yet'), "position state: " . $self->has_position ] );
	# reset the file if needed 
	if( !$self->has_position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"No current position stored - ensure the file is at the beginning" ] );
		$self->start_the_file_over;
		#~ my $fh = $self->get_file;
		#~ ###LogSD		$phone->talk( level => 'debug', message =>[ "got the file handle", $fh ] );
		#~ $fh->seek( 0, 0 );
		#~ ###LogSD		$phone->talk( level => 'debug', message =>[ "seek to 0 done" ] );
		$success = 0;
	}elsif( !$success and $self->where_am_i > $position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Current position: " . $self->where_am_i, "..against desired position: $position" ] );
		$self->start_the_file_over;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Finished resetting the file" ] );
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Reset tests complete" ] );
	
	# Kick start position counting for the first go-round
	if( !$success and !$self->has_position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Kickstart position counting - getting first si cell" ] );
		if( $self->advance_element_position( 'si' ) ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Successfully advanced one share string position" ] );
			$self->i_am_here( 0 );
		}else{
			$self->set_error( "No sharedStrings elements available" );
			$self->_set_unique_count( 0 );
			return undef;
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Any needed kickstarting complete" ] );
	
	# Advance to the proper position - storing along the way as needed
	while( !$success ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Reading the position: " . $self->where_am_i ] );
		
		# Build a perl ref
		my $inital_parse = $self->parse_element;
		my $provisional_output;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Collected:", $inital_parse  ] );
		
		# Handle unexpected end of file here
		if( $inital_parse and $inital_parse eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Handling the end of the file",  ] );
			$return = $inital_parse;
			$self->_set_unique_count( $self->where_am_i + 1 );
			last;
		}
		
		# Convert the perl ref to an Excel style ref
		if( is_HashRef( $inital_parse ) ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The initial parse is a hash ref"  ] );
			my( $success, $t_node ) = $self->grep_node( $inital_parse, 't' );
			if( $success ){
				$provisional_output = $t_node;# ->{raw_text}
			}elsif( exists $inital_parse->{list} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"The initial parse is broken up into list elements", $inital_parse->{list}  ] );
				my ( $raw_text, $rich_text );
				for my $element( @{$inital_parse->{list}} ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"processing element:", $element  ] );
					my ( $success, $perl_style ) = $self->squash_node( $element );
					push( @$rich_text, length( $raw_text ), $perl_style->{rPr} ) if exists $perl_style->{rPr};
					$raw_text .= $perl_style->{t}->{raw_text};
				}
				@$provisional_output{qw( raw_text rich_text )} = ( $raw_text, $rich_text  );
			}
		}else{
			confess "Found unknown parse return: $inital_parse ";
		}
		delete $provisional_output->{'xml:space'} if is_HashRef( $provisional_output );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Built position " . $self->where_am_i . " => ", $provisional_output  ] );
		
		# Cache the position as needed
		if( $self->should_cache_positions ){
			my $cache_value =
				!$provisional_output ? undef :
				(scalar( keys %$provisional_output ) == 1 or $self->_should_block_formats) ?
					$provisional_output->{raw_text} : $provisional_output;
			###LogSD	$phone->talk( level => 'debug', message =>[ "Caching position: " . $self->where_am_i, $cache_value ] );
			$self->_set_ss_position( $self->where_am_i => $cache_value );
			$self->_set_last_cache_position( $self->where_am_i );
			###LogSD	$phone->talk( level => 'trace', message =>[ "Updated cache:", $self->_get_all_cache  ] );
		}
		
		# Determine if we have arrived
		if( $self->where_am_i == $position ){
			$success = 1;
			$return = $provisional_output;
			if( !$self->should_cache_positions ){
				my $cache_value = scalar( keys %$provisional_output ) == 1 ? $provisional_output->{raw_text} : $provisional_output;
				###LogSD	$phone->talk( level => 'debug', message =>[ "Saving the last postion"  ] );
				$self->_set_last_position( $self->where_am_i );
				$self->_set_last_position_ref( $return );
			}
		}
		$self->i_am_here( $self->where_am_i + 1 );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The next position to collect is: " . $self->where_am_i ] );
	}
	
	# Manage the output
	$return  =
		( $return and $return eq 'EOF' ) ? undef :
		( $self->_should_block_formats and is_HashRef( $return ) ) ? $return->{raw_text} :
		$self->_should_block_formats ? $return :
		is_HashRef( $return ) ? $return : { raw_text => $return } ;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"After possible format stripping: " . $self->_should_block_formats, $return ] );
		
	# Close the file if caching complete
	if( $self->should_cache_positions and $self->has_file and $self->where_am_i > $self->_get_unique_count - 1 ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Closing the file - all positions have been stored in cache" ] );
		$self->close;
		$self->clear_file;
	}
	return $return;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> '_good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);

has _unique_count =>(
	isa			=> Int,
	writer		=> '_set_unique_count',
	reader		=> '_get_unique_count',
	clearer		=> '_clear_unique_count',
	predicate	=> '_has_unique_count'
);

has _last_position =>(
		isa		=> Int,
		writer	=> '_set_last_position',
		reader	=> '_get_last_position',
		predicate => '_has_last_position',
		trigger	=> sub{
			my ( $self ) = @_;
			if( $self->_has_last_position_ref ){
				$self->_clear_last_position_ref;
			}
		},
	);

has _last_position_ref =>(
		writer	=> '_set_last_position_ref',
		reader	=> '_get_last_position_ref',
		clearer => '_clear_last_position_ref',
		predicate => '_has_last_position_ref',
	);
	
has _shared_strings_positions =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		default	=> sub{ [] },
		handles	=>{
			_get_ss_position => 'get',
			_set_ss_position => 'set',
		},
		reader => '_get_all_cache',
	);
	
has _cache_completed =>(
		isa		=> Int,
		default	=> -1,
		reader	=> '_last_cache_position',
		writer	=> '_set_last_cache_position',
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
	if( $node_name eq 'sst' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the sst node" ] );
	}else{
		$result = $self->advance_element_position( 'sst' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"attempt to get to the sst element result: $result" ] );
	}
	if( $result ){
		my $sst_list= $self->get_attribute_hash_ref;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed sst list to:", $sst_list ] );
		my $unique_count = $sst_list->{uniqueCount} // 0;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Loading unique count: $unique_count" ] );
		$self->_set_unique_count( $unique_count );
		$self->_good_load( 1 );
	}else{
		$self->set_error( "No 'sst' element found - can't parse this as a shared strings file" );
		$self->_clear_unique_count;
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

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionSharedStrings - Position based sharedStrings Reader

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