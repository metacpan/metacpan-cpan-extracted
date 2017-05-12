package Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
	set_error					where_am_i					has_position
	advance_element_position	start_the_file_over 		i_am_here
	parse_element				get_group_return_type		squash_node
	current_named_node			current_node_parsed			close_the_file
	good_load
);#grep_node
use Types::Standard qw(
		Int		Bool		HashRef			is_HashRef		ArrayRef	Enum	is_Int
    );
use Carp qw( confess );
use Data::Dumper;
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
	if( !$success and $self->has_position and $self->where_am_i > $position ){
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

		my( $result, $node_name, $node_level, $result_ref );
		my $current_node = $self->current_node_parsed;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"The current node is:", $current_node ] );
		if( (keys %$current_node)[0] eq 'ai' ){
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Found the core properties node" ] );
			$result = 2;
			$node_name = 'si';
		}else{
			( $result, $node_name, $node_level, $result_ref ) =
				$self->advance_element_position( 'si' );
		}
		if( $result ){
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
		if( !$inital_parse ){# Potential chopped off end of file here 20-empty_shared_strings_bug.t
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Handling the (empty) end of the file",  ] );
			$self->set_error( "The shared strings file ended (poorly?) before expected" );
			$self->_set_unique_count( $self->where_am_i );
			return undef;
		}elsif( $inital_parse and $inital_parse eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Handling the end of the file",  ] );
			$return = $inital_parse;
			$self->_set_unique_count( $self->where_am_i + 1 );
			last;
		}

		# Convert the perl ref to a styles ref
		$inital_parse = $self->squash_node( $inital_parse );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Squashed to:", $inital_parse  ] );
		if( is_HashRef( $inital_parse ) ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The initial parse is a hash ref"  ] );
			if( exists $inital_parse->{t} ){
				$provisional_output = $inital_parse->{t};
			}elsif( exists $inital_parse->{list} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"The initial parse is broken up into list elements", $inital_parse->{list}  ] );
				my ( $raw_text, $rich_text );
				for my $element( @{$inital_parse->{list}} ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"processing element:", $element  ] );
					push( @$rich_text, length( $raw_text ), $element->{rPr} ) if exists $element->{rPr};
					$raw_text .= $element->{t};
				}
				@$provisional_output{qw( raw_text rich_text )} = ( $raw_text, $rich_text  );
			}else{
				confess "Couldn't find 't' or 'list' keys in: " . Dumper( $inital_parse );
			}
		}else{
			confess "Found unknown parse return: " . Dumper( $inital_parse );
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Built position " . $self->where_am_i . " => ", $provisional_output  ] );

		# Cache the position as needed
		if( $self->should_cache_positions ){
			my $cache_value =
				!$provisional_output ? undef :
				!is_HashRef( $provisional_output ) ? $provisional_output :
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
				#~ my $cache_value = scalar( keys %$provisional_output ) == 1 ? $provisional_output->{raw_text} : $provisional_output;
				###LogSD	$phone->talk( level => 'debug', message =>[ "Saving the last postion"  ] );
				$self->_set_last_position( $self->where_am_i );
				$self->_set_last_position_ref( $return );
			}
		}
		$self->i_am_here( $self->where_am_i + 1 );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The next position to collect is: " . $self->where_am_i ] );
		$self->advance_element_position( 'si' )
	}

	# Manage the output
	$return  =
		!defined $return ? $return :
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
		$self->close_the_file;
	}
	return $return;
}

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the sharedStrings unique bits" ] );
	my( $result, $node_name, $node_level, $result_ref );
	my $current_node = $self->current_node_parsed;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"The current node is:", $current_node ] );
	if( (keys %$current_node)[0] eq 'sst' ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Found the core properties node" ] );
		$result = 2;
		$node_name = 'sst';
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'sst' );
		$current_node = $self->current_node_parsed;
	}
	if( $result and $node_name eq 'sst' ){
		my $unique_count = $current_node->{sst}->{uniqueCount} // 0;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Loading unique count: $unique_count" ] );
		$self->_set_unique_count( $unique_count );
		$self->good_load( 1 );
	}else{
		$self->set_error( "No 'sst' element found - can't parse this as a shared strings file" );
		$self->_clear_unique_count;
	}
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

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

Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings - Position based sharedStrings Reader

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Data::Dumper;
	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	use Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings;
	use	Spreadsheet::Reader::ExcelXML::SharedStrings;

	my $file_instance = build_instance(
	    package => 'SharedStringsInstance',
		workbook_inst => Spreadsheet::Reader::ExcelXML::Workbook->new,
		superclasses =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader'
		],
		add_roles_in_sequence =>[
			'Spreadsheet::Reader::ExcelXML::XMLReader::PositionSharedStrings',
			'Spreadsheet::Reader::ExcelXML::SharedStrings',
		],
	);

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your
own excel parser or extending this package.  To use the general package for excel
parsing out of the box please review the documentation for L<Workbooks
|Spreadsheet::Reader::ExcelXML>, L<Worksheets
|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This role is written to extend L<Spreadsheet::Reader::ExcelXML::XMLReader>.
It adds functionality to read position based sharedStrings files.  It presents this
functionality in compliance with the top level L<interface
|Spreadsheet::Reader::ExcelXML::SharedStrings>.  This POD only describes the
functionality incrementally provided by this module.  For an overview of
sharedStrings.xml reading see L<Spreadsheet::Reader::ExcelXML::SharedStrings>

=head2 Requires

These are the methods required by this role and their default provider.  All
methods are imported straight across with no re-naming.

=over

L<Spreadsheet::Reader::ExcelXML::Error/set_error>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>

L<Spreadsheet::Reader::ExcelXML::XMLReader/where_am_i>

L<Spreadsheet::Reader::ExcelXML::XMLReader/has_position>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/i_am_here>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_named_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_node_parsed>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::Workbook/get_group_return_type>

=back

=head2 Methods

These are the primary ways to use this class.  For additional SharedStrings options
see the L<Attributes|/Attributes> section.

=head3 get_shared_string( $positive_int )

=over

B<Definition:> This returns the data in the shared strings file identified
by the $positive_int position for position in position based sharedStrings
files.

B<Accepts:> $positive_int ( a positive integer )

B<Returns:> a hash ref with the key 'raw_text' and all coallated text for that
xml node as the value.  If there is associated rich text in the node and
L<Spreadsheet::Reader::ExcelXML/group_return_type> is set to 'instance'
then it will also have a 'rich_text' key with the value set as an arrayref of
pairs (not sub array refs) with the first value being the position of the
raw_text from zero that the formatting is applied and the second position as
the settings for that format.  Ex.

	{
		raw_text => 'Hello World',
		rich_text =>[
			2,# Starting with the letter 'l' apply the format
			{
				'color' => {
					'rgb' => 'FFFF0000'
				},
				'sz' => '11',
				'b' => undef,
				'scheme' => 'minor',
				'rFont' => 'Calibri',
				'family' => '2'
			},
			6,# Starting with the letter 'W' apply the format
			{
				'color' => {
					'rgb' => 'FF0070C0'
				},
				'sz' => '20',
				'b' => undef,
				'scheme' => 'minor',
				'rFont' => 'Calibri',
				'family' => '2'
			}
		]
	}

=back

=head3 load_unique_bits

=over

B<Definition:> When the xml file first loads this is available to pull customized data.
It mostly pulls metadata and stores it in hidden attributes for use later.  If all goes
according to plan it sets L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>  to 1.

B<Accepts:> Nothing

B<Returns:> Nothing

=back

=head2 Attributes

Data passed to new when creating an instance of this class. For
modification of this(ese) attribute(s) see the listed 'attribute
methods'.  For more information on attributes see
L<Moose::Manual::Attributes>.  The easiest way to modify this(ese)
attribute(s) is when a classinstance is created and before it is
passed to the workbook or parser.

=head3 cache_positions

=over

B<Definition:> Especially for sheets with lots of stored text the
parser can slow way down when accessing each postion.  This is
because the text is not always stored sequentially and the reader
is a JIT linear parser.  To go back it must restart and index
through each position till it gets to the right place.  This is
especially true for excel sheets that have experienced any
significant level of manual intervention prior to being read.
This attribute turns (default) on caching for shared strings so
the parser only has to read through the shared strings once.  When
the read is complete all the way to the end it will also release
the shared strings file in order to free up some space.
(a small win in exchange for the space taken by the cache).  The
trade off here is that all intermediate shared strings are
L<fully|/get_shared_string( $positive_intE<verbar>$name )> read
before reading the target string.  This means early reads will be
slower.  For sheets that only have numbers stored or at least have
very few strings this will likely not be a initial hit (or speed
improvement).  In order to minimize the physical size of the cache,
if there is only a text string stored in the shared strings position
then only the string will be stored (not as a value to a raw_text
hash key).  It will then reconstitue into a hashref when requested.

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
