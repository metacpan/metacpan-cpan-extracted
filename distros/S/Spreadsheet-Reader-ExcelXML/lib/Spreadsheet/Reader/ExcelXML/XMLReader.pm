package Spreadsheet::Reader::ExcelXML::XMLReader;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader-$VERSION";

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
#~ use Text::ParseWords 3.27;
use Types::Standard qw(
		Int					Bool					Enum					Num
		Str					ArrayRef				is_ArrayRef				is_HashRef
		is_Int				HashRef
    );
use Carp qw( confess longmess );
use Clone qw( clone );
use Data::Dumper;
use Encode qw( encode decode );
use IO::Handle;
use FileHandle;
use lib	'../../../../lib',;
###LogSD	with 'Log::Shiras::LogSpace';
###LogSD	use Log::Shiras::Telephone;
use Spreadsheet::Reader::ExcelXML::Types qw( IOFileType );

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has file =>(
		isa			=> IOFileType,
		reader		=> 'get_file',
		writer		=> 'set_file',
		predicate	=> 'has_file',
		clearer		=> 'clear_file',
		coerce		=> 1,
		trigger		=> \&_start_xml_reader,
		handles 	=> [qw( close getline seek binmode )],
	);

has workbook_inst =>(
		isa	=> 'Spreadsheet::Reader::ExcelXML::Workbook',
		writer => 'set_workbook_inst',
		predicate => '_has_workbook_inst',
		handles => [qw(
			get_group_return_type		set_error					get_defined_conversion
			set_defined_excel_formats	parse_excel_format_string	counting_from_zero
			are_spaces_empty			get_shared_string			has_shared_strings_interface
			should_skip_hidden			spreading_merged_values		starts_at_the_edge
			get_empty_return_type		get_values_only				get_epoch_year
			change_output_encoding		get_error_inst				has_styles_interface
			boundary_flag_setting		is_empty_the_end			get_format
			get_rel_info				get_sheet_info				get_sheet_names
			collecting_merge_data		collecting_column_formats
		)],# The regex import doesn't work here due to the twistiness of the overall package
	);

has	xml_version =>(
		isa			=> 	Num,
		reader		=> 'version',
		writer		=> '_set_xml_version',
		clearer		=> '_clear_xml_version',
		predicate	=> '_has_xml_version',
	);

has	xml_encoding =>(
		isa			=> 	Str,
		reader		=> 'encoding',
		predicate	=> 'has_encoding',
		writer		=> '_set_xml_encoding',
		clearer		=> '_clear_xml_encoding',
	);

has	xml_progid =>(
		isa			=> 	Str,
		reader		=> 'progid',
		predicate	=> 'has_progid',
		writer		=> '_set_xml_progid',
		clearer		=> '_clear_xml_progid',
	);

has	xml_header =>(
		isa			=> 	Str,
		reader		=> 'get_header',
		writer		=> '_set_xml_header',
		predicate	=> '_has_xml_header',
		clearer		=> '_clear_xml_header',
	);

has	xml_doctype =>(
		isa			=> 	HashRef,
		reader		=> 'doctype',
		predicate	=> 'has_doctype',
		writer		=> '_set_xml_doctype',
		clearer		=> '_clear_xml_doctype',
	);

has position_index =>(
		isa			=> Int,
		reader		=> 'where_am_i',
		writer		=> 'i_am_here',
		clearer		=> 'clear_location',
		predicate	=> 'has_position',
	);

has	file_type =>(
		isa		=> 	Enum[ 'xml' ],
		reader	=> 'get_file_type',
		default	=> 'xml',
	);

has stacking =>(
		isa		=> Bool,
		reader	=> 'should_be_stacking',
		writer	=> 'change_stack_storage_to',
		default => 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub start_the_file_over{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::start_the_file_over', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"arrived at start_the_file_over" ] );# , caller( 0 ), caller( 1 ), caller( 2 ),

	# Clear current settings
	$self->clear_location;
	$self->_set_node_stack( [] );
	$self->_set_ref_stack( [] );
	$self->_set_string_stack( [] );
	$self->_set_position_stack( [] );
	$self->change_stack_storage_to( 1 );

	# Start at the beginning
	$self->seek(0, 0);
	###LogSD	$phone->talk( level => 'debug', message =>[ "The object is reset" ] );

	#start reading
	$self->_read_file;
	###LogSD	$phone->talk( level => 'debug', message =>[ "Arrived at the first node" ] );

	return $self->not_end_of_file;
}

#~ sub is_end_of_file{
	#~ my( $self ) = @_;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD			$self->get_all_space . '::XMLReader::reached_end_of_file', );
	#~ return !$self->has_nodes;
#~ }

sub parse_element{
	my ( $self, $level, ) = @_;# $attribute_ref
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::parse_element', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Parsing current element", (defined $level ? "..to depth: $level" : undef), ] );###LogSD			(defined $attribute_ref ? "..with attribute_ref:" : undef), $attribute_ref

	# Check for end of file state
	if( !$self->not_end_of_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Reached end of file" ] );
		return 'EOF';
	}

	# Store stacking state and then ensure it is on
	my $stacking_state = $self->should_be_stacking;
	$self->change_stack_storage_to( 1 );

	# Check for self contained node
	my $current_node = clone( $self->current_named_node );
	###LogSD	$phone->talk( level => 'debug', message =>[ "Current node is:", $current_node ] );
	if( $current_node->{closed} eq 'closed' ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Found a self contained node: ", $current_node ] );
		map{ delete $current_node->{$_} } qw( name type closed initial_string );# level
		$self->_build_out_the_return( [ $current_node ] );

		# pull the compiled ref for return
		my $built_reference = $self->_remove_ref;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Final result result:", $built_reference ] );
		$self->_set_ref_stack( [] );
		$self->_set_position_stack( [] );

		return $built_reference;
	}

	# Build target name and level
	my( $target_node, $target_level ) = @$current_node{ qw( name level ) };
	$target_level = defined $level ? ($target_level + $level) : undef;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Target node is: $target_node",
	###LogSD		(defined $target_level ? "..and target level is: $target_level" : undef ) ] );

	# Cycle to the bottom and back up
	my $done;
	while( !$done ){
		my( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Node read returned: $result_type",
		###LogSD		"..up to node named: $top_node_name",
		###LogSD		"..at level: $top_node_level", $result ] );

		#Handle unexpected EOF
		if( !$result_type ){
			return 'EOF';
		}

		# Handle any rewind and dump
		if( scalar( @$result ) > 0 ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Reached the bottom of something",
			###LogSD		"..checking if: $target_node",
			###LogSD		"..equals: " . $result->[-1]->{name} ] );

			# Check if you reached the top
			if( $result->[-1]->{name} eq $target_node ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"received the very last return" ] );
				$done = 1;
				my $top_ref = pop @$result;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"getting rid of (most) of the ref:", $top_ref ] );
				map{ delete $top_ref->{$_} } qw( name type closed initial_string );# level
				if( keys %$top_ref ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Still something left in top ref:", $top_ref, "..so adding it back result:", $result ] );
					#~ if( $result->[-1] ){ # Add the keys to the top ref as elements to the next node down
						#~ map{ $result->[-1]->{$_} = $top_ref->{$_} } keys %$top_ref;
					#~ }else{
						push @$result, $top_ref;
					#~ }
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Updated result:", $result ] );
				}
			}

			# remove results below a certain level
			while( 	defined $target_level and defined $result->[0] and
					$result->[0]->{level} > $target_level 				){
				my $unused = shift @$result;
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Throwing away:", $unused ] );
			}

			# Build out the return
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Building out the result:", $result ] );
			$self->_build_out_the_return( $result, );
		}
	}

	# pull the compiled ref for return
	my $built_reference = $self->_remove_ref;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Final result result:", $built_reference ] );
	$self->_set_ref_stack( [] );
	$self->_set_position_stack( [] );

	# restore stacking state
	$self->change_stack_storage_to( $stacking_state );

	return $built_reference;
}

sub advance_element_position{
	my ( $self, $element, $position ) = @_;
	if( $position and $position < 1 ){
		confess "You can only advance element position in a positive direction, |$position| is not correct.";
	}
	$position ||= 1;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::advance_element_position', );
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Advancing to element -" . ($element//'') . "- -$position- times", ] );

	# Check for end of file and opt out
	if( !$self->not_end_of_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Already at the EOF - returning failure", ] );
		return undef;
	}

	my( $result, $destination_name, $destination_level, $level_ref);
	my $x = 0;
	for my $y ( 1 .. $position ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Advancing position iteration: $y",
		###LogSD		"Searching for element: " . ($element//'(next)'), ] );
		($result, $destination_name, $destination_level, $level_ref) = defined $element ?
			$self->_next_element( $element ) :
			$self->_next_unnamed_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"search result: " . ($result//'none'),
		###LogSD		"arrived at node named: $destination_name",
		###LogSD		( defined( $destination_level ) ? "..and node level: $destination_level" : undef), $level_ref ] );
		#~ if( $element and $result == 1 ){# Advance passed a closing node
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[ "Handle closing node", ] );
			#~ ($result, $destination_name, $destination_level, $level_ref) = $self->_next_element( $element );
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"search result: " . ($result//'none'),
			#~ ###LogSD		"arrived at node named: $destination_name",
			#~ ###LogSD		( defined( $destination_level ) ? "..and node level: $destination_level" : undef), $level_ref ] );
		#~ }
		last if !$result;
		$x++;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Successfully indexed -$x- times for position request: $position", ] );
	}

	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"returning result: " . ($x==$position), ] );
	return (($element ? ($destination_name eq $element) : $result), $destination_name, $destination_level, $level_ref);
}

sub next_sibling{ # should land on a new node (or EOF)
	my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::next_sibling', );
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Advancing to the next sibling", ] );

	# Check for end of file and opt out
	if( !$self->not_end_of_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Already at the EOF - returning failure", ] );
		return undef;
	}

	# Find target level
	my $target_level = $self->current_named_node->{level};
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Traversing to the next start node at level: $target_level" ] );

	my ( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Read file result type -$result_type- at level -$top_node_level- with node name: $top_node_name" ] );
	while( $result_type == 1 or $top_node_level > $target_level ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Still looking for the target level" ] );
		( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Read file result type -$result_type- at level -$top_node_level- with node name: $top_node_name" ] );
		#~ ###LogSD	$phone->talk( level => 'trace', message =>[
		#~ ###LogSD		"Read file result type -$result_type- at with result: ", ($result//'fail') ] );
		last if $result_type == 0;
	}

	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Target node level -$target_level- search resulted in:", $self->current_named_node ] );
	return( ($top_node_level == $target_level), $top_node_name, $top_node_level, $result);
}

sub skip_siblings{ # should land on a new node?? (or EOF)
	my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::skip_siblings', );
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Advancing past the remaining siblings", ] );

	# Check for end of file and opt out
	if( !$self->not_end_of_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Already at the EOF - returning failure", ] );
		return undef;
	}

	# Find target level
	my $target_level = $self->current_named_node->{level} - 1;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Traversing to the next start node at level: $target_level",
	###LogSD		"(Which is one level up from the current level)" ] );

	my ( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
	while( $result_type == 1 or $top_node_level > $target_level ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Still looking for the target level" ] );
		( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
	}

	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Target node level -$target_level- search resulted in: $result", ] );
	return(( $top_node_level == $target_level ), $top_node_name, $top_node_level, $result );
}

sub current_named_node{
	my( $self, $element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::current_named_node', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"searching for the current value node", $self->_get_node_stack ] );# caller( 0 ), caller( 1 ), caller( 2 )
	my $current_node = $self->_current_node;
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"The current node is:", $current_node ] );
	if( $current_node and $current_node->{name} eq 'raw_text' ){# Add the following if you want to search to the text node level -> and $current_node =~ /^\s+$/
		###LogSD		$phone->talk( level => 'debug', message => [
		###LogSD			"The last node is a text node" ] );
		$current_node = $self->_prior_node;
	}
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"The final current node is:", $current_node ] );

	return $current_node;
}

sub squash_node{
	my( $self, $ref, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::squash_node', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"reducing the xml-style node to a perl-style data structure:", $ref,] );# caller( 1 )
	my $perl_node;
	my $success = 0;
	my $is_a_list = 0;
	my ( $list_ref, $hash_ref, $attribute_ref );

	# Handle the unsquashable
	if( !$ref or !is_HashRef( $ref ) ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The ref is unsquashable: " . ($ref//'undef')] );
		return( 1, $ref);
	}

	# Build any sub lists
	if( exists $ref->{list_keys} ){
		$success = 1;
		my $x = 0;
		for my $key ( @{$ref->{list_keys}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing the node for key -$key- from:", $ref->{list}->[$x],] );
			my $sub_value =
				!defined $ref->{list}->[$x] ? undef :
				( 	is_HashRef( $ref->{list}->[$x] ) and
					(	exists $ref->{list}->[$x]->{list} or
						exists $ref->{list}->[$x]->{attributes} or
						exists $ref->{list}->[$x]->{val}			) ) ?
							$self->squash_node( $ref->{list}->[$x] ) 		:
				( 	is_HashRef( $ref->{list}->[$x] ) and
					scalar( keys %{$ref->{list}->[$x]} ) == 1 and
					exists $ref->{list}->[$x]->{raw_text} 			) ?
							$ref->{list}->[$x]->{raw_text} : $ref->{list}->[$x];
			if( $key eq 'attributes' ){
				$attribute_ref = $sub_value;
			}else{
				$is_a_list = 1 if exists $hash_ref->{$key} and length( $key ) > 0;
				$list_ref->[$x] = $sub_value;
				$x++;
			}
			$hash_ref->{$key} = $sub_value if !$is_a_list;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Perl alt nodes with key -$key- added:", $hash_ref, $list_ref, $attribute_ref ] );
		}
		delete $ref->{list_keys};
		delete $ref->{list};
	}

	# Add the attributes
	if( exists $ref->{attributes} ){
		$perl_node = $is_a_list ? { attributes => $ref->{attributes} } : $ref->{attributes};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Perl node with attributes added:", $perl_node,] );
		delete $ref->{attributes};
		$success = 1;
	}

	# Check for a 'val' key (meaning the ref really just stores one value)
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Performing the 'val' test with success => $success and ref:", $ref,] );
	if( !$success and exists $ref->{val} ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Found a node with 'val': $ref->{val}",] );
		return( 1,  $ref->{val} );
	}

	# Check for a 'raw_text' node (xml raw_text nodes)
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Performing the 'raw_text' test with success => $success and ref:", $ref,] );
	if( !$success and exists $ref->{raw_text} ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Found a node with 'raw_text': $ref->{raw_text}",] );
		return( 1,  $ref );
	}

	# Select the list or hash choice
	if( $is_a_list ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Using the list preference" ] );
		$perl_node->{list} = $list_ref;
		$perl_node->{attributes} = $attribute_ref if $attribute_ref;
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Using the hash preference:", $hash_ref ] );
		if( exists $hash_ref->{attributes} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"found a built attributes key" ] );
			my $attribute_node = $self->squash_node( $hash_ref );
			delete $hash_ref->{attributes};
			map{ $perl_node->{$_} = $attribute_node->{$_} } keys % $attribute_node;
		}
		#~ else{
			map{ $perl_node->{$_} = $hash_ref->{$_} } keys %$hash_ref;
		#~ }
		$success = 1;
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Returning: $success", $perl_node] );
	return ( $success, $perl_node );
}

sub extract_file{###### All available potential nodes will be added if none are found only the first listed node will show as an empty node
    my ( $self, @node_list ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::extract_file', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			'Arrived at extract_file for the nodes:', @node_list ] );
	###LogSD		$self->_print_current_file( $self->get_file );

	# Provide a dump-the-whole-thing out
	my $fh;
	if( $node_list[0] eq 'ALL_FILE' ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning the whole file handle" ] );
		if( $self->has_file ){
			open( $fh, "<&", $self->get_file ) or confess "Couldn't dup the file handle for 'ALL_FILE': $!";
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"First line of file is: ", $fh->getline ] );
			$fh->seek( 0, 0 );
			return $fh;
		}else{
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Looking for a file handle that doesn't exist" ] );
		}
	}

	# Get the header
	my 	$file_string = $self->get_header;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Header string: " . ($file_string//'undef') ] );

	# Build a temp file and load it with the file string
	$fh = IO::File->new_tmpfile;
	$fh->binmode();
	print $fh "$file_string";########## No newlines since there are differences between windows
	###LogSD	$self->_print_current_file( $fh );

	# Provide a nothing-file out
	if( $node_list[0] eq 'NO_FILE' ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning an empty(ish) handle" ] );
		print $fh "<NO_FILE/>";
		return $fh;
	}

	# Add nodes
	my $found_a_node = 0;
	my $first_node;
	for my $node_name ( @node_list ){
		my @parse_commands = is_ArrayRef( $node_name ) ? @$node_name : ( $node_name );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Advancing to node -$parse_commands[0]- incrementally: " . ($parse_commands[1]//1),  $self->current_named_node ] );
		###LogSD		$self->_print_current_file( $fh );
		$self->start_the_file_over;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"File reset to the beginning" ] );
		$first_node = $parse_commands[0] if !defined $first_node;
		my $name_match = ($parse_commands[1] and !is_Int( $parse_commands[1] )) ? pop @parse_commands : undef;
		my $result = 0;
		while( !$result ){
			($result, my $current_node_name, my $current_node_level) = $self->advance_element_position( @parse_commands );  ##### Split out the second element here and test for name
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Advance result: " . ($result//'fail')] );
			last if !$result;
			if( !$name_match ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"No name matching required"] );
				last;
			}else{
				my $current_node = $self->current_node_parsed;
				my @name_key_list = grep( /name/i, keys %{$current_node->{$parse_commands[0]}} );
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Looking in current node:", $current_node,
				###LogSD		 "..for a name match to -$name_match- using top key -$parse_commands[0]- and name key: $name_key_list[0]" ] );
				if( $current_node->{$parse_commands[0]}->{$name_key_list[0]} eq $name_match ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Found the node -$parse_commands[0]- named: $name_match"] );
					last;
				}else{
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"No node name match for -$name_match- with: $current_node->{$parse_commands[0]}->{$name_key_list[0]}", ] );
					$result = 0;
				}
			}
		}
		if( $result ){
			my $node_string = $self->_get_node_all;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Node string:", $node_string ] );
			print $fh $node_string;
			###LogSD	$self->_print_current_file( $fh );
			$found_a_node = 1;
		}
	}

	# Add the first node as an empty node if none found
	if( !$found_a_node ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'None of the requested nodes were found', ] );
		print $fh "<$first_node/>";# Returns a dummy file - file content should be tested by file type
		###LogSD	$self->_print_current_file( $fh );
	}

	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		'Final file handle:', $fh ] );
	###LogSD	$self->_print_current_file( $fh );
	$fh->seek( 0, 0 ); # rewind the file for processing
	return $fh;
}

sub current_node_parsed{
    my ( $self,) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::current_node_parsed', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			'Arrived at current_node_parsed', ] );
	my $node_ref;
	$node_ref->[0] = clone( $self->_current_node );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"The current node ref is:", $node_ref ] );

	# Handle empty node
	if( !$node_ref->[0] ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Reached the end of the file" ] );
		return undef;
	}

	# Walk back a raw_text node
	if( $node_ref->[0] and $node_ref->[0]->{name} eq 'raw_text' ){
		###LogSD		$phone->talk( level => 'debug', message => [
		###LogSD			"The last node is a text node" ] );
		push @$node_ref, clone( $self->_prior_node );
		###LogSD		$phone->talk( level => 'debug', message => [
		###LogSD			"...now the current node ref is:", $node_ref ] );
	}

	# Build out the return
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Building out the node:", $node_ref, ] );
	$self->_build_out_the_return( $node_ref, );

	# pull the compiled ref for return
	my $built_reference = $self->_remove_ref;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Final result:", $built_reference, ] );
	$self->_set_ref_stack( [] );
	$self->_set_position_stack( [] );
	$built_reference = $self->squash_node( $built_reference );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Squashed node:", $built_reference, ] );

	return $built_reference;
}

sub close_the_file{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			'Spreadsheet::Reader::ExcelXML::XMLReader::DEMOLISH::close_the_file', );# $self->get_all_space .
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"clearing the XMLReader reader for log space:",
	###LogSD			'Spreadsheet::Reader::ExcelXML::XMLReader::DEMOLISH::close_the_file', ] );# $self->get_all_space .

	# Close the file
	if( $self->has_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Closing the file handle", ] );
		$self->close;
		$self->clear_file;
	}
	#~ print "XMLReader file check complete\n";
}

sub initial_node_build{
	my( $self, $name, $array_list_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::initial_node_build', );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"attempting to build the node named -$name- for string list:", $array_list_ref ] );

	my	$node_ref->{name} = $name;
		$node_ref->{type} = 'regular';

	# Set node level - Potentially this could be a separate 'partial stack' that could report to 'should_be_stacking'?
	$node_ref->{level} = !$self->not_end_of_file ? 0 :
		($self->_current_node->{level} + ($self->_current_node->{closed} eq 'closed' ? 0 : 1));
	###LogSD	$phone->talk( level => 'debug', message =>[ "updated node ref:", $node_ref ] );

	# Set node to open (default fixed elswhere)
	$node_ref->{closed} = 'open';
	###LogSD	$phone->talk( level => 'debug', message =>[ "updated node ref:", $node_ref ] );

	# Store remaining elements
	$node_ref->{attribute_strings} = $array_list_ref if scalar @$array_list_ref;
	###LogSD	$phone->talk( level => 'debug', message =>[ "updated node ref:", $node_ref ] );

	return $node_ref;
}
#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa			=> Bool,
		writer		=> 'good_load',
		reader		=> 'loaded_correctly',
		default		=> 0,
	);

has _node_stack =>(
	isa		=> ArrayRef,
	traits	=> ['Array'],
	reader	=> '_get_node_stack',
	writer	=> '_set_node_stack',
	default	=> sub{ [] },
	handles	=>{
		add_node_to_stack	=> 'push',
		not_end_of_file		=> 'count',
		_remove_node	=> 'pop',
		_remove_header	=> 'shift',
		_current_node	=>[ get => -1 ],
		_prior_node		=>[ get => -2 ],
		#~ _get_node_position => 'get',
	}
);

has _ref_stack =>(
	isa		=> ArrayRef,
	traits	=> ['Array'],
	reader	=> '_get_ref_stack',
	writer	=> '_set_ref_stack',
	default	=> sub{ [] },
	handles	=>{
		_add_ref		=> 'push',
		_remove_ref		=> 'pop',
		_has_refs		=> 'count',
	}
);

has _position_stack =>(
	isa		=> ArrayRef,
	traits	=> ['Array'],
	reader	=> '_get_position_stack',
	writer	=> '_set_position_stack',
	default	=> sub{ [] },
	handles	=>{
		_add_position		=> 'push',
		_remove_position	=> 'pop',
		_has_positions		=> 'count',
		_last_position		=>[ get => -1 ],
	}
);

has _string_stack =>(
	isa		=> ArrayRef,
	traits	=> ['Array'],
	reader	=> '_get_string_stack',
	writer	=> '_set_string_stack',
	default	=> sub{ [] },
	handles	=>{
		_add_string		=> 'push',
		_remove_string	=> 'pop',
		_has_strings	=> 'count',
	}
);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _start_xml_reader{
	my( $self, $file_handle ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_start_xml_reader', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"turning a file handle into an xml reader", ] );

	# Clear any old settings
	$self->_clear_xml_version;
	$self->_clear_xml_encoding;
	$self->_clear_xml_progid;
	$self->_clear_xml_header;
	$self->clear_location;
	$self->_set_node_stack( [] );
	$self->_set_ref_stack( [] );
	$self->_set_position_stack( [] );
	$self->_set_string_stack( [] );

	# (re) set the file to 0 for insurance
	###LogSD	$phone->talk( level => 'debug', message =>[ "start at the beginning" ] );
	$file_handle->seek( 0, 0 );
	###LogSD		$phone->talk( level => 'trace', message => [
	###LogSD			"ran seek( 0, 0 ) -> (to the beginning of the file)", ] );

	# Kick start the file read
	$self->_read_file;

	# Set the file unique bits
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Check if this type of file has unique settings" ], );
	if( $self->can( 'load_unique_bits' ) ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Loading unique bits" ], );
		$self->load_unique_bits;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Finished loading unique bits" 			], );
	}

	###LogSD	$phone->talk( level => 'debug', message => [ "finished all xml reader build steps" ], );
	return 1;
}

sub _next_element{
	my( $self, $element ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_next_element', );#::_hidden
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"searching for the next element: $element", ] );
	my( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;# Implied in next since the last one may also be $element
	NODEINDEX: while( $result_type == 1 or (($result_type != 0) and ($top_node_name ne $element)) ){
		( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"result of the read file action: $result_type", $top_node_name, $top_node_level, $result, ] );
		while( defined $result_type and $result_type == 1 ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The last node was only a closing tag - index once again to get a new tag" ] );
			( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"result of the read file action: $result_type", $result, ] );
			last NODEINDEX if $result_type == 0;
		}
	}
	return ( $result_type, $top_node_name, $top_node_level, $result );
}

sub _next_unnamed_element{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_next_unnamed_element', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"searching for the next unnamed element", ] );
	my( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;# Implied in next since the last one may also be $element
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"result of the read file action: $result_type", $result, $self->_get_node_stack ] );
	NODEINDEX: while( $result_type == 1 ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The last node was only a closing tag - index once again to get a new tag" ] );
		( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"result of the read file action: $result_type", $result, $self->_get_node_stack ] );
		last NODEINDEX if $result_type == 0;
	}
	return( $result_type, $top_node_name, $top_node_level, $result );#Start with Bang Bang operator
}

sub _build_out_the_return{
	my( $self, $add_list, ) = @_;# $target_level
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_build_out_the_return', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Against stored node list:", $self->_get_ref_stack,
	###LogSD			"Building out the return:", $add_list,
	###LogSD			"...and stored position list:", $self->_get_position_stack,] );
	#~ ###LogSD			(defined $target_level ? "stopping at level: $target_level" : undef)

	if( !$add_list or scalar( @$add_list ) == 0 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No new elements passed for addition" ] );
		return 0;
	}

	# Build the reference
	my( $top_reference, $base_reference, $last_level );

	# Handle stacking new on top of old
	exit 1 if !exists $add_list->[0]->{level};
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Checking if there are positions to add: ". ($self->_has_positions//'undef'),
	###LogSD		( $self->_has_positions ? "Comparing level -$add_list->[0]->{level}- against stored level: " . $self->_last_position : undef) ] );
	if( $self->_has_positions and $add_list->[0]->{level} == $self->_last_position - 1 ){
		$top_reference = $self->_remove_ref;
		$self->_remove_position;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"New top reference:", $top_reference ] );
	}

	for my $element ( @$add_list ){

		# store the node level
		$last_level = $element->{level};

		# Parse the attributes if they exist
		if( exists $element->{attribute_strings} ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Processing raw attribute list:", $element->{attribute_strings} ] );
			my @attribute_args = $self->_reconcile_attribute_strings( $element->{attribute_strings} );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Reconciled attribute list:", @attribute_args ] );
			$element->{attribute_strings} = [ @attribute_args ];
			$element = (defined $element->{name} and $element->{name} eq 'DOCTYPE') ? $self->_build_doctype_attributes( $element ) : $self->_build_regular_attributes( $element ) ;
			delete $element->{attribute_strings};
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated element:", $element ] );
		}

		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"processing element:", $element, "..at level: " . ($last_level//'undef'), $top_reference ] );
		my $stop_level = 'debug';
		if( !exists $element->{name} ){
			###LogSD	$phone->talk( level => 'debug', message =>[ "Handling unnamed element" ] );
			delete $element->{level};
			if( exists $element->{val} ){
				$top_reference = $element->{val};
			}else{
				for my $key ( keys %$element ){
					push @{$top_reference->{list_keys}}, $key;
					push @{$top_reference->{list}}, $element->{$key};
				}
			}
		}elsif( exists $element->{name} and $element->{name} eq 'raw_text' ){
			confess "I already have a top reference but I'm trying to add a text node" if $top_reference;
			$top_reference = { raw_text => $self->_remove_escapes( $element->{raw_text} ) };
		}else{

			# Split out element values to allow for sub-reffing
			my $name = $element->{name};
			my $level = $element->{level};
			map{ delete $element->{$_} } qw( name closed type level initial_string );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"processing element named -$name- at level -$level- with content:", $element, $top_reference ] );
			if( exists $element->{attributes} and is_HashRef( $top_reference ) ){
				if( exists $top_reference->{list} ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Adding top ref:", $top_reference, "to element named -$name- at level -$level- with content:", $element, ] );
					$element->{list} = $top_reference->{list};
					$element->{list_keys} = $top_reference->{list_keys};
					$top_reference = undef;
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Updated element:", $element, ] );
				}elsif( exists $top_reference->{raw_text} ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Adding raw_text ref:", $top_reference, "to element named -$name- at level -$level- with content:", $element, ] );
					push @{$element->{list}}, $top_reference->{raw_text};
					push @{$element->{list_keys}}, 'raw_text';
					$top_reference = undef;
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Updated element:", $element, ] );
				}
			}
			$element = undef if !scalar( %$element );
			$base_reference =
				$top_reference ? $top_reference : $element;
			$top_reference = undef;# poor mans clone

			# Build in any stored information at this level
			if( $self->_has_positions and $level == $self->_last_position ){
				my $stored_ref = $self->_remove_ref;
				$self->_remove_position;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Adding stored ref:", $stored_ref, "to element named -$name- at level -$level- with content:", $element, $top_reference ] );
				#~ $stop_level = 'fatal';
				if( exists $stored_ref->{list} ){
					@{$top_reference->{list_keys}} = @{$stored_ref->{list_keys}};
					@{$top_reference->{list}} = @{$stored_ref->{list}};
				}
			}

			# Load the current element
			push @{$top_reference->{list_keys}}, $name;
			push @{$top_reference->{list}}, $base_reference;
			###LogSD	$phone->talk( level => 'debug', message =>[ "Top ref:", $top_reference ] );
		}
		###LogSD	$phone->talk( level => $stop_level, message =>[
		###LogSD		"processing result:", $top_reference, $base_reference ] );
	}
	$self->_add_ref( $top_reference );
	$self->_add_position( $last_level );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Current ref stack:", $self->_get_ref_stack, $self->_get_position_stack ] );

	return 1;
}

sub _remove_escapes{
	my( $self, $string) = @_;

	# Return 0 length
	if( !defined $string or length( $string ) == 0 ){
		return $string;
	}
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_remove_escapes', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"removing escapes from the string: $string" ] );

	# Handle xml escapes
	$string =~ s/&lt;/</g;
	$string =~ s/&gt;/>/g;
	$string =~ s/&quot;/"/g;
	$string =~ s/&amp;/&/g;
	$string =~ s/&apos;/'/g;
	$string =~ s/&#60;/</g;
	$string =~ s/&#62;/>/g;
	$string =~ s/&#34;/"/g;
	$string =~ s/&#38;/&/g;
	$string =~ s/&#39;/'/g;
	###LogSD	$phone->talk( level => 'debug', message =>[ "updated string: $string"] );

	return $string;
}

sub _read_file{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_read_file', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"reading the 'line' from the file", ] );# caller( 0 ), caller( 1 ), caller( 2 )

	# get the next file line - and scrub it
	my $node_type = 0; #( 0 = EOF, 1 = closing only tag, 2 = open tag, 3 = self contained (open and closed in one tag))
	my @sections;
	while( !@sections ){
		my $line = $self->getline;
		###LogSD	$phone->talk( level => 'debug', message =>[ "The next file line is:", $line ] );
		if( !$line ){
			###LogSD	$phone->talk( level => 'debug', message =>[ "Reached the end of the file" ] );
			return( 0, 'EOF', 0, [ { name => 'EOF', level => -1 } ] );
		}
		$line = substr( $line, 0, -1 );
		@sections = split />/, $line;
		###LogSD	$phone->talk( level => 'debug', message =>[ "Line sections are:", @sections ] );
		if( scalar( @sections ) > 2 ){
			$self->set_error( 'The next xml line broke into more than 2 sections after |' . $sections[0] . '| from line: ' . $line );
			$self->close_the_file;
			$self->good_load( 0 );
			return( 0, 'BAD' );
		}
	}

	# Pull name, type, and attributes as well as calculating depth
	my @closures = qw( open closed );
	my $is_xml_header = 0;
	my $x = 0;
	my $return = [];
	my( $top_node_name, $top_node_level );
	for my $node ( @sections ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Processing section: ", $node] );
		my( $node_ref, $node_name, @node_split );
		my $initial_string = $node;

		# Handle the first pass
		if( $x == 0 ){

			# Handle header nodes with quotes
			if( substr( $node, 0, 1 ) eq '?' or substr( $node, 0, 1 ) eq '!' ){
				$is_xml_header = 1;
				$node = (substr( $node, 0, 1 ) eq '?') ? substr( $node, 1, -1 ) : substr( $node, 1 ) ;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Removed question marks from node: " . $node,
				###LogSD		"is_xml_header set to: $is_xml_header" ] );
			}

			# Handle end nodes - always subtractive to the stack and then exits
			if( substr( $node, 0, 1 ) eq '/' ){
				###LogSD	$phone->talk( level => 'debug', message =>[ "Reached an end node" ] );

				# For stacking off, ignore end nodes
				if( !$self->should_be_stacking ){
					###LogSD	$phone->talk( level => 'debug', message =>[ "No stacking required - ignoring end node" ] );
					return( $self->_read_file );
				}

				# Handle previously closed nodes
				while( $self->_current_node->{closed} eq 'closed' ){
					push @$return, $self->_remove_node;
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"pushed the closed end node to return - looking for an open node - current type: $node_type", $return ] );
				}

				# Process the first open node
				my $current_node = $self->_remove_node;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Current node:", $current_node ] );

				# Lookup the name
				$node_name = substr( $node, 1 );
				if( $current_node->{name} ne $node_name ){
					confess "Found an end node -$node_name- that doesn't match the next open node:" . Dumper( $current_node );
				}
				$current_node->{closed} = 'closed';
				push @$return, $current_node;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Return list type -1- with current nodes:", $return ] );

				# Return and let the caller determine if it wants to proceed
				return( 1, $node_name, $return->[-1]->{level}, $return );# Always $node_type = 1
			}

			# handle self closing nodes
			my $self_closing;
			if( substr( $node, -1, 1 ) eq '/' ){
				$node = substr( $node, 0, -1 );
				$self_closing = 1;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Found a self closing node" ] );
			}
			# Pull the node name
			@node_split = split /\s/, $node;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"node split is:", @node_split ] );
			$node_name = shift @node_split;
			$top_node_name = $node_name if !$top_node_name;

			# Exit for speed return when !should_be_stacking
			if( !$self->should_be_stacking ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Stacking is off - returning found node name: $node_name" ] );
				return( 2, $node_name, undef, [ @node_split ] );# Is level worth calculating here? (no node stack popping done (yet?) either)
			}

			# Check for white space in the xml file
			if( $self->not_end_of_file and
				$self->_current_node->{name} eq 'raw_text' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"found previously stored white space", $self->_get_node_stack ] );
				$self->_remove_node;
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"White space gone", $self->_get_node_stack ] );
			}

			# Build the node
			$node_ref = $self->initial_node_build( $node_name, [@node_split] );
			if( $is_xml_header or $self_closing ){
				$node_ref->{closed} = 'closed';
			}
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Returned from initial node build with node:", $node_ref ] );
			$top_node_level = $node_ref->{level};
			$node_type = 2;

			# pop nodes at the same or lower level
			while($self->not_end_of_file and $self->_current_node->{level} >= $node_ref->{level} ){
				push @$return, $self->_remove_node;
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Return ref now", $return, ] );
			}

		}else{
			$node_name = 'raw_text';
			@$node_ref{qw( name raw_text type closed )} = ( 'raw_text', $node, '#text', 'closed' );
			$node_ref->{level} = $top_node_level + 1;
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Raw text node:", $node_ref, ] );
		}

		# Store the node
		$node_ref->{initial_string} = $initial_string;
		$self->add_node_to_stack( $node_ref );
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Updated node stack", $self->_get_node_stack, "node_type at: $node_type" ] );
		$x++;
		last if $node_ref->{closed} eq 'closed';
	}

	# Handle header nodes then move on
	if( $is_xml_header ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Found an xml header", ($return ? ("..with initial return:", $return) : undef) ] );
		( $node_type, $top_node_name, $top_node_level, my $sub_return ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Read result after header: $node_type", $sub_return ] );
		$self->_load_header( $sub_return ) if !$self->_has_xml_header and @$sub_return;
	}

	# If you made it here the process worked
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Updated node stack", $self->_get_node_stack,
	###LogSD		"returning popped nodes:", $return, "node_type at: $node_type"] );
	return( $node_type, $top_node_name, $top_node_level, $return );# Always $node_type = 2
}

sub _load_header{
	my( $self, $header_nodes) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_load_header', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Loading headers:", $header_nodes ] );

	# Check for top level header string
	if( $header_nodes->[0]->{name} eq 'xml' ){
		my $header_string = '<' . $header_nodes->[0]->{initial_string} . '>';
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Setting the primary header string: $header_string", ] );
		$self->_set_xml_header( $header_string );
	}

	# Transform the data
	$self->_build_out_the_return( $header_nodes );
	my $built_reference = $self->_remove_ref;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Final result result:", $built_reference ] );
	$self->_set_ref_stack( [] );
	$self->_set_position_stack( [] );
	my $header_node = $self->squash_node( clone( $built_reference ) );

	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"loading file level settings since the header was found", $header_node] );
	my $test_ref =
		exists $header_node->{xml} ? $header_node->{xml} :
		exists $header_node->{'mso-application'} ? $header_node->{'mso-application'} :
		exists $header_node->{'DOCTYPE'} ? $header_node : {};

	for my $attribute ( qw( version encoding progid DOCTYPE ) ){
		if( exists $test_ref->{$attribute} ){
			#~ if( $attribute eq 'encoding' ){
				#~ $test_ref->{$attribute} = $test_ref->{$attribute} eq 'UTF-8' ? 'utf8' :  $test_ref->{$attribute};
				#~ my $encoding = ":encoding($test_ref->{$attribute})";
				#~ ###LogSD	$phone->talk( level => 'debug', message => [
				#~ ###LogSD		"Setting file handle encoding to -> $encoding", ] );
				#~ print "Setting file handle encoding to -> $encoding\n";
				#~ $self->binmode( $encoding );
			#~ }
			my $setter = '_set_xml_' . lc( $attribute );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Performing the action -$setter- on the data: $test_ref->{$attribute}", ] );
			$self->$setter( $test_ref->{$attribute} );
		}
	}
}

sub _get_node_all{
	my ( $self, $level, ) = @_;# $attribute_ref
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_get_node_all', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Parsing current element", (defined $level ? "..to depth: $level" : undef), ] );###LogSD			(defined $attribute_ref ? "..with attribute_ref:" : undef), $attribute_ref

	# Check for end of file state
	if( !$self->not_end_of_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Reached end of file" ] );
		return 'EOF';
	}

	# Check for self contained node
	my $current_node = clone( $self->current_named_node );
	###LogSD	$phone->talk( level => 'debug', message =>[ "Current node is:", $current_node ] );
	if( $current_node->{closed} eq 'closed' ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Found a self contained node: ", $current_node ] );
		map{ delete $current_node->{$_} } qw( initial_string );# level
		$self->_build_out_the_string( [ $current_node ] );

		# pull the compiled ref for return
		my $built_reference = $self->_remove_string;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Final result result:", $built_reference ] );
		$self->_set_string_stack( [] );
		$self->_set_position_stack( [] );

		return $built_reference;
	}

	# Build target name and level
	my( $target_node, $target_level ) = @$current_node{ qw( name level ) };
	$target_level = defined $level ? ($target_level + $level) : undef;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Target node is: $target_node",
	###LogSD		(defined $target_level ? "..and target level is: $target_level" : undef ) ] );

	# Cycle to the bottom and back up
	my $done;
	ADDSTRINGS: while( !$done ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Looking for the next node in the file", ] );
		my( $result_type, $top_node_name, $top_node_level, $result ) = $self->_read_file;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Node read returned: $result_type", $result ] );

		# Handle any rewind and dump
		if( scalar( @$result ) > 0 ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Reached the bottom of something",
			###LogSD		"..checking if: $target_node",
			###LogSD		"..equals: " . $result->[-1]->{name} ] );

			# Check if you reached the top
			if( $result->[-1]->{name} eq $target_node ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"received the very last return" ] );
				$done = 1;
			}

			# Exit if unexpectedly reached the end
			if( $result_type == 0 ){
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Unexpected end of file:", $result ] );
				last ADDSTRINGS;
			}

			# Build out the return
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Building out the result:", $result ] );
			$self->_build_out_the_string( $result, );
		}
	}

	# pull the compiled ref for return
	my $built_reference = $self->_remove_string;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Final result:", $built_reference ] );
	$self->_set_string_stack( [] );
	$self->_set_position_stack( [] );

	return $built_reference;
}

sub _build_out_the_string{
	my( $self, $add_list, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_build_out_the_string', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			"Building out the node string:", $add_list,
	###LogSD			"Against stored string list:", $self->_get_string_stack,
	###LogSD			"...and stored position list:", $self->_get_position_stack, ] );

	if( !$add_list or scalar( @$add_list ) == 0 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No new elements passed for addition" ] );
		return 0;
	}

	# Build the reference
	my( $top_string, $last_level );# $base_string,

	# Handle stacking new on top of old
	if( $self->_has_positions and $add_list->[0]->{level} == $self->_last_position - 1 ){
		$top_string = $self->_remove_string;
		$self->_remove_position;
		#~ $should_close_nodes = 1;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"New top string:", $top_string ] );
	}

	# Turn the stack into a string
	for my $element ( @$add_list ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Processing element:", $element ] );

		# store the node level
		$last_level = $element->{level};
		my $base_string = $top_string;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated last level -$last_level- and base_string: " . ($base_string//'undef') ] );
		if( $element->{type} eq '#text' ){
			$top_string = $element->{initial_string};
		}else{
			$top_string = '<' . $element->{initial_string} . '>';
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated top_string: " . $top_string ] );
		$top_string .= $base_string if $base_string;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated top_string: " . $top_string ] );

		# Close the open node
		if( $element->{type} ne '#text' and substr( $element->{initial_string}, -1 ) ne '/' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Closing the node: $element->{name}" ] );
			$top_string .= '</' . $element->{name} . '>';
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"New top_string:", $top_string ] );

		# Build in any stored information at this level
		if( $self->_has_positions and $last_level == $self->_last_position ){
			my $stored_string = $self->_remove_string;
			$self->_remove_position;
			$top_string = $stored_string . $top_string;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated to string:", $top_string ] );
		}
	}
	$self->_add_string( $top_string);
	$self->_add_position( $last_level );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Current string stack:", $self->_get_string_stack, $self->_get_position_stack ] );

	return 1;
}

around getline => sub{
	local $/ = '<';
	my( $orig, $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::getline', );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"adding localized '<' as the newline character for \$/" ] );
	$self->$orig;
};

sub _reconcile_attribute_strings{
	my( $self, $parse_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_reconcile_attribute_strings', );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"attempting to reconcile attribute split for list:", $parse_ref ] );
	my @attributes;
	my $should_glue = 0;
	my $test_string;
	for my $string ( @$parse_ref ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "processing sting: $string" ] );
		if( $string =~ /^[^"]*"[^"]*$/ ){
			###LogSD	$phone->talk( level => 'warn', message =>[ "found unclosed quote" ] );
			if( $should_glue ){
				###LogSD	$phone->talk( level => 'warn', message =>[ "..which is a closing string" ] );
				$should_glue = 0;
				push @attributes, $test_string . ' ' . $string;
				$test_string = undef;
			}else{
				###LogSD	$phone->talk( level => 'warn', message =>[ "..which is an opening string" ] );
				$should_glue = 1;
				$test_string = $string;
			}
			###LogSD	$phone->talk( level => 'warn', message =>[ "Updated attributes:", @attributes ] );
		}elsif( $should_glue ){
			###LogSD	$phone->talk( level => 'warn', message =>[ "found a middle string in an open sequence" ] );
			$test_string .= ' ' . $string;
		}elsif( length( $string ) == 0 ){
			###LogSD	$phone->talk( level => 'warn', message =>[ "Found a zero length string out in the open - don't add it" ] );
		}else{
			###LogSD	$phone->talk( level => 'debug', message =>[ "just a string: $string" ] );
			push @attributes, $string;
		}
	}
	if( $should_glue ){
		confess "Unable to close and open string with quotes -" . join '|~|', @attributes;
	}
	###LogSD	$phone->talk( level => 'trace', message =>[ "returning split:", @attributes ] );
	return @attributes;
}

sub _build_doctype_attributes{
	my( $self, $node_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_build_doctype_attributes', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"attempting to build the DOCTYPE attributes for:", $node_ref] );

	$node_ref->{$node_ref->{attribute_strings}->[0]} = { $node_ref->{attribute_strings}->[1] => substr( $node_ref->{attribute_strings}->[2], 1, -1 ) };
	###LogSD	$phone->talk( level => 'debug', message =>[ "updated node ref:", $node_ref ] );

	return $node_ref;
}

sub _build_regular_attributes{
	my( $self, $top_ref ) = @_;
	###LogSD    my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD                $self->get_all_space . '::XMLReader::_hidden::_build_regular_attributes', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"attempting to build an attributes ref for:", $top_ref ] );

	for my $att ( @{$top_ref->{attribute_strings}} ){
		next if !$att or $att eq 'xml:space="preserve"';
		###LogSD	$phone->talk( level => 'debug', message =>[ "parsing attribute string: $att" ] );
		my( $att_name, $att_val, $form_val ) = split /\s*=\s*/, $att;
		#~ $att_val = substr( $att_val, 1, -3 ) if substr( $att_val, 0, 1 ) eq '"';# Remove bracing quotes from values
		$att_val = $self->_remove_escapes( $att_val );
		$form_val = $self->_remove_escapes( $form_val );
		###LogSD	$phone->talk( level => 'debug', message =>[ "Final result:", $att_name, $att_val, $form_val ] );
		$att_val = substr( $att_val, 1, -1 ) if $att_val and (substr( $att_val, 0, 1 ) eq '"') and (substr( $att_val, -1, 1 ) eq '"');
		if( $att_name eq 'val' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"found a value attribute" ] );
			$top_ref->{$att_name} = $att_val;
		}elsif( $form_val ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"found a formula value: $form_val" ] );
			#~ $element->{attributes}->{$att_name} = '"' if substr( $form_val, -1, 1 ) eq '"';
			$top_ref->{attributes}->{$att_name} .=
				substr( $form_val, -1, 1 ) eq '"' ?
					substr( $form_val, 0, -1 )	: $form_val ;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"final formula value: $top_ref->{attributes}->{$att_name}" ] );
		}else{
			$top_ref->{attributes}->{$att_name} = $att_val;
		}
		###LogSD	$phone->talk( level => 'debug', message =>[ "updated node ref:", $top_ref ] );
	}

	return $top_ref;
}

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			'Spreadsheet::Reader::ExcelXML::XMLReader::_hidden::DEMOLISH', );# $self->get_all_space .
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD			"XMLReader DEMOLISH called" ] );

	$self->close_the_file;

}

###LogSD	sub _print_current_file{ # Debugging method only used when the Log::Shiras debug source filter is on
	###LogSD    my ( $self, $ref ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLReader::_hidden::_print_current_file', );
	###LogSD	my $line =  ( caller(0) )[2];
	###LogSD	if( !$ref ){
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"The file handle sent from line -$line- is empty" ], );
	###LogSD    }else{
	###LogSD		$ref->seek( 0, 0 );
	###LogSD		my( $next_line, $print_string );
	###LogSD		while( $next_line = <$ref>  ){
	#~ ###LogSD			chomp( $next_line );
	###LogSD			next if $next_line =~ /^\s*$/;
	###LogSD			$print_string .= $next_line;
	###LogSD    	}
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"For code line -$line- the file is:", $print_string ]);
	###LogSD    }
###LogSD	}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader - A minimal pure-perl xml reader class

=head1 SYNOPSIS

	package MyPackage;
	use MooseX::StrictConstructor;
	use MooseX::HasDefaults::RO;
	# You have to 'use' or build a the Workbook here or the XMLReader won't load
	#  -> because the reader uses a regex to scrap imported methods
	use Spreadsheet::Reader::ExcelXML::Workbook;
	extends	'Spreadsheet::Reader::ExcelXML::XMLReader';

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel spreadsheet parser.  I suppose the class could be used more generally but that's
not why I wrote it and for now I have no intention of providing a full xml toolbox.
For Excel spreadsheet parsing generally please start at the top level documentation.
L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>.

This class is meant to be used as the base reading class for specific types of xml
files.  The reader for those specific files will include roles that are useful for
that files content.  When the file first loads it will store some available information
from the header (?) nodes and move to the first file node.  At that point it will
check if any of the consuming roles have a method '_load_unique_bits'  If so it
will call that method for additional meta data collection by that role.

This class will process the xml file in a just in time fashion holding enough
information to know the level and open nodes not yet closed but nothing else.  The
intent is to use a little RAM as possible and process the file in the most
(pure perl) computationaly efficient way possible.  I welcome all suggestions for
improvement.

=head2 Attributes

Data passed to new when creating an instance.  For modification of these attributes
see the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For ways to manage the instance after it is opened
see the L<Methods|/Methods>.

=head3 file

=over

B<Definition:> This attribute holds the file handle for the file being read.  If
the full file name and path is passed to the attribute the class will coerce that
into an L<IO::File> file handle.

B<Default:> no default - this must be provided to read a file

B<Required:> yes

B<Range:> any unencrypted xml file name and path or IO::File file handle set to
read.

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_file>

=over

B<Definition:> change the file value in the attribute (this will reboot
the file instance and lock the file)

=back

B<get_file>

=over

B<Definition:> Returns the file handle of the file even if a file name
was passed

=back

B<has_file>

=over

B<Definition:> this is used to see if the file loaded correctly.

=back

B<clear_file>

=over

B<Definition:> this clears (and unlocks) the file handle

=back

=back

B<Delegated Methods>

=over

L<close|IO::Handle/$io-E<gt>close>

=over

closes the file handle

=back

L<seek|IO::Seekable/$io-E<gt>seek ( POS, WHENCE )>

=over

allows seek commands to be passed to the file handle

=back

L<getline|IO::Handle/$io-E<gt>getline>

=over

returns the next line of the file handle with '<' set as the
L<input_record_separator ($E<sol>)|http://perldoc.perl.org/perlvar.html>

=back

=back

=back

=head3 workbook_inst

=over

B<Definition:> This attribute holds a reference to the top level workbook (parser).
The purpose is to use some of the methods provided there.

B<Default:> no default

B<Required:> not strictly for this class but the attribute is provided to give
self referential access to general workbook settings and methods for composed
classes that inherit this a base class.

B<Range:> isa => 'Spreadsheet::Reader::ExcelXML::Workbook'

B<attribute methods> Methods provided to adjust this attribute

=over

B<set_workbook_inst>

=over

set the attribute with a workbook instance

=back

=back

B<Delegated Methods (required)> Methods delegated to this module by the
attribute.  All methods are delegated with the method name unchanged.
Follow the link to review documentation of the provider for each method.
As you can see several are delegated through the Workbook level and
don't originate there.

=over

L<Spreadsheet::Reader::ExcelXML/get_group_return_type>

L<Spreadsheet::Reader::ExcelXML/counting_from_zero>

L<Spreadsheet::Reader::ExcelXML/are_spaces_empty>

L<Spreadsheet::Reader::ExcelXML/has_shared_strings_interface>

L<Spreadsheet::Reader::ExcelXML/should_skip_hidden>

L<Spreadsheet::Reader::ExcelXML/spreading_merged_values>

L<Spreadsheet::Reader::ExcelXML/starts_at_the_edge>

L<Spreadsheet::Reader::ExcelXML/get_empty_return_type>

L<Spreadsheet::Reader::ExcelXML/get_values_only>

L<Spreadsheet::Reader::ExcelXML/get_epoch_year>

L<Spreadsheet::Reader::ExcelXML/get_error_inst>

L<Spreadsheet::Reader::ExcelXML/has_styles_interface>

L<Spreadsheet::Reader::ExcelXML/boundary_flag_setting>

L<Spreadsheet::Reader::ExcelXML/is_empty_the_end>

L<Spreadsheet::Reader::ExcelXML/get_rel_info>

L<Spreadsheet::Reader::ExcelXML/get_sheet_info>

L<Spreadsheet::Reader::ExcelXML/get_sheet_names>

L<Spreadsheet::Reader::ExcelXML/collecting_merge_data>

L<Spreadsheet::Reader::ExcelXML/collecting_column_formats>

L<Spreadsheet::Reader::ExcelXML::Error/set_error( $error_string )>

L<Spreadsheet::Reader::Format/get_defined_conversion( $position )>

L<Spreadsheet::Reader::Format/set_defined_excel_formats( %args )>

L<Spreadsheet::Reader::Format/parse_excel_format_string( $string, $name )>

L<Spreadsheet::Reader::Format/change_output_encoding( $string )>

L<Spreadsheet::Reader::ExcelXML::SharedStrings/get_shared_string( $positive_intE<verbar>$name )>

L<Spreadsheet::Reader::ExcelXML::Styles/get_format( ($positionE<verbar>$name), [$header], [$exclude_header] )>

=back

=back

=head3 xml_version

=over

B<Definition:> This stores the xml version read from the xml header.  It is read
when the file handle is first set in this sheet.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> xml versions

B<attribute methods> Methods provided to adjust this attribute

=over

B<version>

=over

get the stored xml version

=back

=back

=back

=head3 xml_encoding

=over

B<Definition:> This stores the data encoding of the xml file from the xml header.
It is read when the file handle is first set in this sheet.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> valid xml file encoding

B<attribute methods> Methods provided to adjust this attribute

=over

B<encoding>

=over

get the attribute value

=back

B<has_encoding>

=over

predicate for the attribute value

=back

=back

=back

=head3 xml_progid

=over

B<Definition:> This is an attribute found in a secondary xml header that
is associated with Excel 2003 xml based files.  The value can be tested
to see if the file was intended to be compliant with that format.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> a string

B<attribute methods> Methods provided to adjust this attribute

=over

B<progid>

=over

get the attribute value

=back

B<has_progid>

=over

predicate for the attribute value

=back

=back

=back

=head3 xml_header

=over

B<Definition:> This stores the primary xml header string from the xml file.  It
is read when the file handle is first set in this sheet.  I contains both the
verion and the encoding where available and is used when building subsets of
the file as standalone xml.

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> valid xml file header

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_header>

=over

get the attribute value

=back

B<_set_xml_header>

=over

set the attribute value

=back

=back

=back

=head3 xml_doctype

=over

B<Definition:> This stores the DOCTYPE indicated in the XML header !DOCTYPE

B<Default:> no default - this is auto read from the header

B<Required:> no

B<Range:> whatever it finds

B<attribute methods> Methods provided to adjust this attribute

=over

B<doctype>

=over

get the attribute value

=back

B<has_doctype>

=over

predicate for the attribute

=back

=back

=back

=head3 position_index

=over

B<Definition:> This attribute is available to facilitate other consuming roles and
classes.  Of this attributes methods only the 'clear_location' method is used in this
class during the L<start_the_file_over|/start_the_file_over> method.  It can be used
for tracking positions with the same node name.

B<Default:> no default - this is mostly managed by the role or child class

B<Required:> no

B<Range:> Integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<where_am_i>

=over

get the attribute value

=back

B<i_am_here>

=over

set the attribute value

=back

B<clear_location>

=over

clear the attribute value

=back

B<has_position>

=over

set the attribute value

=back

=back

=back

=head3 file_type

=over

B<Definition:> This is a static attribute that shows the file type

B<Default:> xml

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_file_type>

=over

get the attribute value

=back

=back

=back

=head3 stacking

=over

B<Definition:> a pure perl xml parser will in general be slower than the C equivalent.
To provide some acceleration to arrive at a target destination you can turn of the stack
trace which will include building and storing the trace elements.  This breaks things so
don't do it without a solid understanding of what is happening.  For instance if you turn
this off and then call the method L<parse_element|/parse_element( [$depth] )>  The
parse_element method will have to turn the stack trace back on on it's own to build the
element tree.  The issue is that the most recent element at the base of the tree won't be
available to build from.  You will need to manually build it and push it to the stack.  See
the methods L<initial_node_build|/initial_node_build( $node_name, $attribute_list_ref )> and
L<add_node_to_stack|/add_node_to_stack( $node_ref )> to implement this.

B<Default:> 1 = the stack trace is on

B<attribute methods> Methods provided to adjust this attribute

=over

B<should_be_stacking>

=over

get the attribute value

=back

B<change_stack_storage_to( $Bool )>

=over

Turn the stack trace(r) state to $Bool (1 = on)

=back

=back

=back

=head2 Methods

These are the methods provided by this class.

=head3 start_the_file_over

=over

B<Definition:> Clears the L<position_index|/position_index>, the old stack trace, and kick starts
L<stack trace tracking|/stacking> again.  It then uses seek(0, 0) to reset the file handle to the
beginning.  Finally, it reads the file until it gets to the first non-xml header node.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 good_load( $state )

=over

B<Definition:> a setter method to indicated if the file loaded correctly.  This
generally should be set by consuming roles in the L<load_unique_bits
|/load_unique_bits> phase.


B<Accepts:> (1|0)

B<Returns:> nothing

=back

=head3 loaded_correctly

=over

B<Definition:> a getter method to understand if the file loaded correctly.
This is generally used by consumers of the instance to see if there was any
trouble during the initial build.

B<Accepts:> nothing

B<Returns:> 1 = good build, 0 = bad_build

=back

=head3 parse_element( [$depth] )

=over

B<Definition:> This will read and store the full node from the current position
down to an optional $depth.  When the parse is complete the parser will be
positioned at the beginning of the next node.  The node does not include the
top name but will include attributes.

B<Accepts:> $depth = optional

B<Returns:> A perl hash reference where all nodes at a level are listed using three
hashref keys; list_keys, list, and attributes.  The 'attributes' key points to a
hash reference containing that nodes attributes.  The 'list_keys' key points to an
array reference with all the node names for each node at the next level down.  The
'list' key points to an array reference of nodes or node values matching the position
of the list_keys.  There are two special case exceptions to this.  First, for text
values the node is listed as { raw_text => 'text node content' }.  Second, if the
attributes only include a 'val' key the node stores this under the 'val' key rather
than the 'attributes' key with a sub key 'val'.

=back

=head3 advance_element_position( $element, [$iterations] )

=over

B<Definition:> This will move the xml file reader forward until it finds the identified named
$element.  If the reader is already at an element of that name it will index forward until it finds
the next $element of that name.  If the optional positive $iterations integer is passed it will index
to the named $element - $iterations times.

B<Accepts:> $element = a case sensitive xml node name found forward of the
current position in the file.  [$iterations] = optional a positive integer
indicating how many times to index forward to the named $element.

B<Returns:> a list of 4 positions ( $success, $node_name, $node_level, $return_node_ref )

$success = a boolean value indicating whether the desired goal was met, $node_name = the actual node
name for the final position (should match $element if $success), $node_level = the level of the final
named node in the stack( not the sub text node ) $return_node_ref = When the L<stacking|/stacking>
attribute is on this returns the last displaced elements in the stack displaced by the traverse of
the xml tree.  When stacking is off this returns an array ref of values used as the second argument in
L<initial_node_build|/initial_node_build( $node_name, $attribute_list_ref )>.

=back

=head3 next_sibling

=over

B<Definition:> This will move the xml file reader forward until it finds next
node at the same level as the current node within the same supernode.  If this
method finds a higher node prior to finding a node at the same level it will
return failure and stop reading.

B<Accepts:> nothing

B<Returns:> a list of 4 positions ( $success, $node_name, $node_level, $return_node_ref )

$success = a boolean value indicating whether the desired goal was met, $node_name = the actual node
name for the final position (should match $element if $success), $node_level = the level of the final
named node in the stack( not the sub text node ) $return_node_ref = When the L<stacking|/stacking>
attribute is on this returns the last displaced elements in the stack displaced by the traverse of
the xml tree.  When stacking is off this returns an array ref of values used as the second argument in
L<initial_node_build|/initial_node_build( $node_name, $attribute_list_ref )>.

=back

=head3 skip_siblings

=over

B<Definition:> This will move the xml file reader forward until it finds next
node higher.  It will not stop on end nodes so it will continue to pass all
closed nodes until it comes to the first open or self contained node above
the current node.

B<Accepts:> nothing

B<Returns:> a list of 4 positions ( $success, $node_name, $node_level, $return_node_ref )

$success = a boolean value indicating whether the desired goal was met, $node_name = the actual node
name for the final position (should match $element if $success), $node_level = the level of the final
named node in the stack( not the sub text node ) $return_node_ref = When the L<stacking|/stacking>
attribute is on this returns the last displaced elements in the stack displaced by the traverse of
the xml tree.  When stacking is off this returns an array ref of values used as the second argument in
L<initial_node_build|/initial_node_build( $node_name, $attribute_list_ref )>.

=back

=head3 current_named_node

=over

B<Definition:> when processing xml files in a just in time fashion there
will be some ambiguity surrounding text nodes;

	<t>sometext</t>
	<s>
	   <r val="2"/>

In the 't' node example the content between the '>' character and the '<'
characters are intentional and valuable to the data set.  In the 's' and
'r' node example the space between those characters is only intended for
human readability.  This parser will not be able to tell the value of the
content after the 's' node '>' character until the 'r' node is read.  At
that point the 's' node will no longer be the 'current' position.  To
resolve this, all content other than '' between '>' and '<' is treated as
a node until the next node is read.  Because these nodes are ambiguous
the idea of a 'named node' is valuable and knowing what the most recent
named node is can be useful.  This method either returns the last read node
or the second to last node if the last node is a raw text node.  In the
first example it would return the 't' node and in the second example it
would return the 's' node.

B<Accepts:> nothing

B<Returns:> a hash ref of information about the node containing the
following keys;

	level => counting from 0 at the start of the file and moving up
	type => regular = xml named node|#text = node built from the contents between the > and < characters
	name => the xml node name (for #text nodes this is 'raw_text')
	closed => (closed|open) depending on the current tag state
	initial_string => The string inside the < > quotes prior to parsing
	[attributes] => all attributes and values will be stored under the attribute name
	[val] => special case storage of one attribute

=back

=head3 squash_node( $node )

=over

B<Definition:> This takes a $node from the L<parse_element|/parse_element> output
and turns it into a more perl like reference.  It checks the list_keys and if
there are any duplicates it takes the list values and uses them as elements of
an array ref assigned to a hash key called list.  If there are no duplicates
in the list_keys it turns the list_keys into hash keys with the list elements
assigned as values.  It then takes the attributes and mingles them in the hashref
with the prior results.  There are two special cases for a node reorganization.
For nodes with a 'val' in the 'list_keys' then the element in the same position of
the 'list' is returned as the whole ref.  If there is a raw_text node it is returned
as a hashref with one key 'raw_text' with the text itself as the value.  This
is all done recursivly so lower layers are assigned to upper layers using the
rules above.

B<Accepts:> the output of a L<parse_element|/parse_element> call

B<Returns:> a perl data structure with the xml organization removed

=back

=head3 extract_file( @node_list )

=over

B<Definition:> This will build an xml file and load it to a L<IO::Handle>-E<gt>new_tmpfile
object.  The xml is built on whole extracted xml strings defined by @node_list.
If none of the node list elements is found in the parsed file then the first
listed element from the node list will be used to create an empty self closing
node.

B<Accepts:> @node_list =  Node list items can either be xml node name strings or array refs
composed of two elements, first the node name and second the iterated position. Ex.

	@node_list_example = ( 'r', [ 'si', 3 ] );

In this example the extracted file would contain the first 'r' node and the 3rd
'si' node.the output of a L<parse_element|/parse_element> call.  There is the
exception case where you just want the whole file passed.  The out here is to
pass 'ALL_FILE' as the first element of the @node_list and a complete copy of
the file_handle in read mode will be passed.

B<Returns:> a File::Temp file handle loaded with an xml header and the listed
nodes.

=back

=head3 current_node_parsed

=over

B<Definition:> When nodes are read they are not completely processed to save
cycles.  If you want a fully processed result from the current node position
including any embedded text then this is the method for you.

B<Accepts:> Nothing

B<Returns:> a perl ref equivalent to the squash_node call. This only returns the
fully processed current_named_node and any sub text nodes.

=back

=head3 close_the_file

=over

B<Definition:> It may be that the file(handle) may not be needed during the whole
workbook parse.  If so you can use this method to close (and clear / release) an
open file handle as appropriate.

B<Accepts:> Nothing

B<Returns:> Nothing (the file handle is closed and cleared)

=back

=head3 not_end_of_file

=over

B<Definition:> This is a poor mans End Of File test (EOF).  The reader builds
a node stack to keep track of where it is in the xml parse and when it runs out
of nodes it means you are back at the top of the stack.

B<Accepts:> Nothing

B<Returns:> a count of the nodes in the node stack (header nodes are processed
early on and are read and removed as part of startup)

=back

=head3 initial_node_build( $node_name, $attribute_list_ref )

=over

B<Definition:> Generally this is an internal method and should not be used.  However,
in order to provide a faster forward ability the node stack trace(ing) can be
L<turned off|stacking>.  When you want to turn it back on you have to manually build
the top node using this method and store it to the node stack using L<add_node_to_stack
|/add_node_to_stack( $node_ref )>.  This method will build the essentials for adding
to the node stack.  Please not that it will not necessarily get the node level right.
I<If you need that to be correct then don't turn off the stack trace.>  It will not
build raw_text nodes correctly.

B<Accepts:>
	$node_name = a string without spaces for the name of the node,
	$attribute_list_ref = This is basically everything else in the xml tag except the name
	split on /\s+/.  Any self closing '/' should be removed prior to the split.

B<Returns:> a node ref that can be added to the node stack to kickstart stack tracing

=back

=head3 add_node_to_stack( $node_ref )

=over

B<Definition:> Generally this is an internal method and should not be used.  However,
in order to provide a faster forward ability the node stack trace(ing) can be
L<turned off|stacking>.  When you want to turn it back on you have to manually build
the top node and store it to the node stack using this method.  Adding a node after the stack
trace has been turned off will create a discontinuity where the new node is added.  Stack
trace operations above this node will generally fail and stop the script.

B<Accepts:> $node_ref = a top to push on the node stack for traceability

B<Returns:> nothing

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

#########1#########2 main pod documentation end   5#########6#########7#########8#########9
