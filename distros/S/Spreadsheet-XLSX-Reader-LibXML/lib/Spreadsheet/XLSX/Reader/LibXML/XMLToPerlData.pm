package Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');

use	Moose::Role;
use Data::Dumper;
use 5.010;
requires qw(
	get_empty_return_type		get_text_node				get_attribute_hash_ref
	advance_element_position	location_status				skip_siblings
	next_sibling
);#text_value
use Types::Standard qw(	Int	ArrayRef is_HashRef is_Int StrMatch Bool );
use Clone qw( clone );
###LogSD	requires 'get_all_space';
###LogSD	use Log::Shiras::Telephone;

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has exclude_match =>(
		isa		=> StrMatch[qr/^\([^\)]+\)$/],
		reader	=> '_get_exclude_match',
		writer	=> 'set_exclude_match',
		clearer	=> '_clear_exclude_match',
		predicate => '_has_exclude_match',
	);

has strip_keys =>(
		isa		=> Bool,
		reader	=> '_should_strip_keys',
		writer	=> 'set_strip_keys',
		clearer	=> '_clear_strip_keys',
		default => 0,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub parse_element{ # $attribute_ref expects three keys node_name node_type node_level attribute_hash
	my ( $self, $level, $attribute_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::parse_element', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Parsing current element", (defined $level ? "..to level: $level" : undef),
	###LogSD			(defined $attribute_ref ? "..with attribute_ref:" : undef), $attribute_ref ] );
	$self->_clear_partial_ref;
	$self->_clear_bread_crumbs;
	my ( $node_depth, $node_name, $node_type ) =
		$attribute_ref ? @$attribute_ref{qw(node_depth node_name node_type )} : $self->location_status ;
	if( $node_name eq '#document' and $node_type == 9 ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Already arrived at the end of the document" ] );
		return 'EOF';
	}elsif( defined $level ){
		###LogSD	$phone->talk( level => 'debug', message =>[ "Setting max level with (+1)", $level, $node_depth] );
		$self->_set_max_level( $level + $node_depth + 1 );
	}else{
		$self->_clear_max_level;
	}
	
	# Set the seed data
	my	$base_depth	= $node_depth;
	my	$last_level = $node_depth - 1;
	my	$has_value	= 0;
	my	$time		= 'first';
	
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Start node name: $node_name",
	###LogSD		"..of type: $node_type",
	###LogSD		"..at libxml2 level: $node_depth",
	###LogSD		"..from base depth: $base_depth",
	###LogSD		"..for time: $time",
	###LogSD		(($self->_has_max_level) ? 
	###LogSD			('..with max allowed level: ' . $self->_get_max_level) : ''),] );
	
	my $sub_ref;
	PARSETHELAYERS: while( ($time eq 'first') or ($node_depth > $base_depth) ){
		$time = 'not_first';
		
		# Check for a rewind
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Checking for rewind state with current node depth: $node_depth",
		###LogSD		"..........................against last node depth: $last_level", ] );
		if( $node_depth < $last_level ){
			my $rewind = $last_level - $node_depth;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Just moved back up: $rewind", ] );
			$self->_rewind( $rewind );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Rewound to depth: $node_depth", ] );
			$last_level = $node_depth;
		}
		
		# Record progress
		if( $node_depth == $last_level ){# Stack the same level
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Found another node at level: $node_depth",
			###LogSD		"..node_named: $node_name", ] );
			$self->_stack( $node_name );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Finished stacking with :", $self->_get_partial_ref, $self->_get_bread_crumbs ] );
		}else{
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Building out: $node_name", ] );
			$self->_accrete_node( $node_name );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Finished accreting with :", $self->_get_partial_ref, ] );
		}
		$has_value = 0;# Reset value tracker for node level
		
		$last_level = $node_depth;
		if( !$self->_has_max_level or $self->_get_max_level > $node_depth ){# Check for the bottom
			# Check for a text node
			my( $result, $node_text, ) = $attribute_ref ? ( undef, undef ) : $self->get_text_node;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"result: " . ($result//'fail'), $node_text] );
			
			# If no text node check for an attribute_ref
			my $next_ref;
			if( $result ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"The next node is a text node - adding |$node_text|" ] );
				$has_value = 1;
				my $increment = $self->_accrete_node( $node_text, 'text' );
				$last_level += $increment;
				###LogSD	$phone->talk( level => 'debug', message =>[ "Loaded the text node"] );
			}else{
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Not a text node - Checking for an attribute ref: " . ref $attribute_ref, $attribute_ref ] );
				my $is_attribute = 0;
				if( ref $attribute_ref ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Using the pre-parsed attribute ref", $attribute_ref->{attribute_hash} ] );
					( $result, $next_ref ) = ( 1, $attribute_ref->{attribute_hash} );
					$attribute_ref = undef;
					$is_attribute = 1;
				}else{
					( $result, $next_ref ) = $self->get_attribute_hash_ref;
					$is_attribute = $result;
				}
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"The attribute hash_ref search result -$result- produced the ref:", $next_ref ] );
				if( $result ){
					my	$ref_type = 
							$is_attribute ? 'attribute' :
							is_HashRef( $next_ref ) ? undef : 'text';
					###LogSD	$phone->talk( level => 'trace', message => [
					###LogSD		"Adding attribute hash ref type:", $ref_type, $next_ref,	] );
					
					# Scrub out namespace tags in sub keys
					if( $self->_should_strip_keys ){
						###LogSD	$phone->talk( level => 'debug', message =>[
						###LogSD		"The strip keys flag is on" ] );
						if( $self->_has_strip_match ){
							my $exclude = $self->_get_strip_match;
							###LogSD	$phone->talk( level => 'debug', message =>[
							###LogSD		"stripping any namespace labels with: $exclude" ] );
							for my $key ( keys %$next_ref ){
								###LogSD	$phone->talk( level => 'debug', message =>[
								###LogSD		"Checking key: $key" ] );
								$key =~ /($exclude\:)?(.)(.+)/;
								if( $1 ){
									my $new_key = lc( $3 ) . $4;
									###LogSD	$phone->talk( level => 'debug', message =>[
									###LogSD		"Key updated to: $new_key" ] );
									$next_ref->{$new_key} = $next_ref->{$key};
									delete $next_ref->{$key};
								}
							}
						}else{
							###LogSD	$phone->talk( level => 'debug', message =>[
							###LogSD		"Attempting to find namespace labels" ] );
							my @key_list;
							for my $key ( keys %$next_ref ){
								###LogSD	$phone->talk( level => 'debug', message =>[
								###LogSD		"Checking key: $key" ] );
								$key =~ /xmlns\:?(.*)/;
								push @key_list, $1 if $1;
							}
							if( scalar( @key_list ) > 0 ){
								my $exclude = '(' . join( '|', @key_list ) . ')';
								###LogSD	$phone->talk( level => 'debug', message =>[
								###LogSD		"Exclude string resolved to: $exclude" ] );
								$self->_set_strip_match( $exclude );
							}
						}
					}
					
					$has_value = 1;
					my $increment = $self->_accrete_node( $next_ref, $ref_type );
					$last_level += $increment;
				}
			}
		}
		
		# Move one step forward
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Advancing to the next node",	] );
		my $result  = $self->advance_element_position;
		last PARSETHELAYERS if !$result;# End of file?
		( $node_depth, $node_name, $node_type ) = $self->location_status;
		if( $self->_has_exclude_match ){
			my $string = $self->_get_exclude_match;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Checking if node -$node_name- matches: $string" ] );
			while( $node_name =~ /$string/i ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Found a match" ] );
				$result = $self->next_sibling;
				last PARSETHELAYERS if !$result;# End of file?
				( $node_depth, $node_name, $node_type ) = $self->location_status;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Next sibling node is: $node_name", "..checking against: $string" ] );
			}
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Result of the next node process: $result", 
		###LogSD		"Next node name: $node_name",
		###LogSD		"..of type: $node_type",
		###LogSD		"..at libxml2 level: $node_depth",
		###LogSD		"..against base depth: $base_depth",
		###LogSD		(($self->_has_max_level) ? 
		###LogSD			('..and for max allowed level: ' . $self->_get_max_level) : ''),] );
		
		# Skip any additional nodes that are too low
		if( $self->_has_max_level and $self->_get_max_level < $node_depth ){
			$self->skip_siblings;
			my $result  = $self->advance_element_position;# Go from the end of the last to the begining of the new
			last PARSETHELAYERS if !$result;# End of file?
			( $node_depth, $node_name, $node_type ) = $self->location_status;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"After skip_siblings next node name is: $node_name",
			###LogSD		"..of type: $node_type",
			###LogSD		"..at libxml2 level: $node_depth",
			###LogSD		"..against base depth: $base_depth",
			###LogSD		(($self->_has_max_level) ? 
			###LogSD			('..and for max allowed level: ' . $self->_get_max_level) : ''),] );
		}
		
		# Handle a self contained node with no sub data
		if( $last_level > $node_depth and $has_value == 0 ){
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD		"Found a self contained node with no sub-data",	] );
			$last_level += $self->_empty_node( $node_name );
			$has_value = 1;
		}
	}
	
	# Handle a self contained node with no sub data one last time
	if( $has_value == 0 and $last_level > $node_depth ){
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"One final self contained node with no sub-data",	] );
		$self->_empty_node( $node_name );
	}
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Finished the loop with:", $self->_get_partial_ref, ] );
	
	# Rewind one last time
	my $rewind = $self->_ref_depth - 2;
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Rewinding finally: $rewind", ] );
	
	# Clear every time
	$self->_clear_exclude_match;
	$self->set_strip_keys( 0 );
	$self->_clear_strip_match;
	
	# Handle the empty return case
	if( $rewind < 0 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"It seems there was no data at this position", ] );
		return undef;
	}
	
	my $eof_flag = $self->_rewind( $rewind );
	if( $eof_flag ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Found -EOF-", ] );
		return $eof_flag;
	}else{
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Finished processing with:", $self->_get_partial_ref ] );
		my $final_answer =  $self->_last_ref_level;
		delete $final_answer->{list_ref} if is_HashRef( $final_answer );
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"returning:", $final_answer ] );
		return $final_answer;
	}
}

sub grep_node{
	my( $self, $ref, $node_name ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::grep_node', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Extracting the node -$node_name- from the general ref:", $ref, ]);# caller( 0 ), caller( 1 ), caller( 2 ), caller( 3 ), caller( 4 ), caller( 5 )]
	my $sub_node;
	my $x = 0;
	my $success = 0;
	for my $key ( @{$ref->{list_keys}} ){
		if( $key eq $node_name ){
			$sub_node = $ref->{list}->[$x];
			$success = 1;
			last;
		}
		$x++;
	}
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning: $success", $sub_node] );
	return ( $success, $sub_node );
}

sub squash_node{
	my( $self, $ref, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::squash_node', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"reducing the xml style node to a perl style data structure:", $ref,] );# caller( 1 )
	my $perl_node;
	my $success = 0;
	my $is_a_list = 0;
	my ( $list_ref, $hash_ref );
	
	# Build any sub lists
	if( exists $ref->{list_keys} ){
		$success = 1;
		my $x = 0;
		for my $key ( @{$ref->{list_keys}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing the node for key -$key- from:", $ref->{list}->[$x],] );
			my $sub_value =
				!defined $ref->{list}->[$x] ? undef :
				( exists $ref->{list}->[$x]->{list} or exists $ref->{list}->[$x]->{attributes} ) ?
					$self->squash_node( $ref->{list}->[$x] ) : $ref->{list}->[$x];
			$is_a_list = 1 if exists $hash_ref->{$key};
			$hash_ref->{$key} = $sub_value if !$is_a_list;
			$list_ref->[$x] = $sub_value;
			$x++;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Perl alt nodes with key -$key- added:", $hash_ref, $list_ref,] );
		}
	}
	
	# Add the attributes
	if( exists $ref->{attributes} ){
		$perl_node = $is_a_list ? { attributes => $ref->{attributes} } : $ref->{attributes};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Perl node with attributes added:", $perl_node,] );
		$success = 1;
	}
	
	# Combine the attributes and sub lists
	if( $is_a_list ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Using the list preference" ] );
		$perl_node->{list} = $list_ref;
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Using the hash preference" ] );
		map{ $perl_node->{$_} = $hash_ref->{$_} } keys %$hash_ref;
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Returning: $success", $perl_node] );
	return ( $success, $perl_node );
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _strip_match =>(
		isa		=> StrMatch[qr/^\([^\)]+\)$/],
		reader	=> '_get_strip_match',
		writer	=> '_set_strip_match',
		clearer	=> '_clear_strip_match',
		predicate => '_has_strip_match',
	);

has	_max_level =>(
		isa			=> 	Int,
		reader		=> '_get_max_level',
		writer		=> '_set_max_level',
		predicate	=> '_has_max_level',
		clearer		=> '_clear_max_level',
	);

has	_partial_ref =>(
		isa			=> 	ArrayRef,
		traits		=> ['Array'],
		reader		=> '_get_partial_ref',
		writer		=> '_set_partial_ref',
		clearer		=> '_clear_partial_ref',
		handles =>{
			_add_ref_level 	=> 'push',
			_set_ref_level 	=> 'set',
			_get_ref_level 	=> 'get',
			_ref_depth		=> 'count',
			_last_ref_level => 'pop',
		}
	);

has	_bread_crumbs =>(
		isa			=> 	ArrayRef,
		traits		=> ['Array'],
		reader		=> '_get_bread_crumbs',
		writer		=> '_set_bread_crumbs',
		clearer		=> '_clear_bread_crumbs',
		handles =>{
			_add_bread_crumb	=> 'push',
			_set_bread_crumb 	=> 'set',
			_get_bread_crumb 	=> 'get',
			_crumb_trail_length	=> 'count',
			_last_bread_crumb	=> 'pop',
		}
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _accrete_node{
	my ( $self, $node_id, $node_type ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::parse_element::_accrete_node', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Accreting the node:", $node_id, $node_type, $self->_get_ref_level( -1 ), $self->_get_bread_crumb( -1 )] );
	my ( $ref, $crumb, $add );
	if( $node_type ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"This has a node type: $node_type" ] );
		if( $node_type eq 'text' ){
			my $last_ref = $self->_last_ref_level;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Working with node id -$node_id- and text ref:", $last_ref] );
			if( exists $last_ref->{raw_text} ){
			#~ if( exists $last_ref->{list_keys} and $last_ref->{list_keys}->[-1] eq 'raw_text' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Attaching text to a raw_text node" ] );
				if( $node_id and $node_id =~ /^\s+$/ ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Deleting space nodes"] );
					$self->_last_bread_crumb;
					$add = -1;
				}else{
					$last_ref->{raw_text} = $node_id;
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Added node id (text) -$node_id- to the last ref:", $last_ref ] );
					$self->_add_ref_level( $last_ref );
					$add = 0;
				}
			}elsif( $node_id  =~ /^\s+$/ and
					(	!exists $last_ref->{attributes} or
						(!exists $last_ref->{attributes}->{'xml:space'} and !exists $last_ref->{attributes}->{'ss:Type'}) or
						(exists $last_ref->{attributes}->{'xml:space'} and $last_ref->{attributes}->{'xml:space'} ne 'preserve') or
						(exists $last_ref->{attributes}->{'ss:Type'} and $last_ref->{attributes}->{'ss:Type'} ne 'String' ) 			) ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Deleting space node from list"] );
				if( !$self->_get_bread_crumb( -1 ) ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Deleting the whole node list set", $last_ref ] );
					$self->_last_bread_crumb;
					if( exists $last_ref->{attributes} ){
						delete $last_ref->{list};
						delete $last_ref->{list_keys};
						$self->_add_bread_crumb( 'attributes' );
						$self->_add_ref_level( $last_ref );
						$add = 0;
					}else{
						$add = -1;
					}
				}else{
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Just deleting the last list element"] );
					pop @{$last_ref->{list}};
					pop @{$last_ref->{list_keys}};
					#~ delete $last_ref->{attributes};
					$self->_add_bread_crumb( ($self->_last_bread_crumb-1) );
					$self->_add_ref_level( $last_ref );
					$add = 0;
				}
			}else{
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Adding the text node element"] );
				my $new_ref;
				if( scalar( @{$last_ref->{list}} ) == 1 ){
					$new_ref->{raw_text} = $node_id;
				}
				#~ else{
					#~ $last_ref->{list}->[$self->_get_bread_crumb( -1 )] = $node_id;
					#~ delete $last_ref->{attributes};
				#~ }
				if( exists $last_ref->{attributes} ){
					map{ $new_ref->{$_} = $last_ref->{attributes}->{$_} } keys %{$last_ref->{attributes}};
				}
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Loading new last ref:", $new_ref ] );
				$self->_add_ref_level( $new_ref );
				$add = 0;
			}
		}elsif( $node_type eq 'attribute' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"building an attribute node"] );
			$ref = { attributes => $node_id };
			$crumb = 'attributes';
			$add = 1;
		}else{
			confess "Unable to accrete type -$node_type- with content: $node_id";
		}
	}elsif( $node_id and $node_id eq 'raw_text' ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"building a text node"] );
		$ref = { raw_text => undef };
		$crumb = 'raw_text';
		$add = 1;
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"building a list node"] );
		$ref = { list => [undef], list_keys =>[ $node_id ] };
		$crumb = 0;
		$add = 1;
	}
	#~ my $ref = { $
		#~ ( $node_type and $node_type eq 'text' ) ? $node_id :
		#~ ( ref $node_id ) ? $node_id : { $node_id => undef };
	if( $add > 0 ){
		$self->_add_ref_level( $ref );
		$self->_add_bread_crumb( $crumb );
	}
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Current node representations:", $self->_get_partial_ref, $self->_get_bread_crumbs,] );
	return $add;
}

sub _rewind{
	my ( $self, $rewind_count ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::parse_element::_rewind', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Rewinding: $rewind_count", '----', $self->_get_bread_crumb( -1 ), '^^^', '---',  $self->_get_ref_level( -1 ), '^^^', ] );
	if( !defined $rewind_count or $rewind_count < 0 ){
		$self->set_error( "Can't rewind |$rewind_count| times! - possible end of file" );
		return 'EOF'
	}elsif( $rewind_count == 0 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Skipping rewind since -0- rewinds called!" ] );
	}else{
		$self->_last_bread_crumb;
		my	$current_value	= $self->_last_ref_level;
		my ( $next_value, $current_ref );
		for my $count ( 1..$rewind_count ){
			$next_value		= $self->_last_bread_crumb;
			$current_ref	= $self->_last_ref_level;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Rewinding:", $current_value, "to current ref:", $current_ref, "..with placement: $next_value" ] );
			if( is_HashRef( $current_value ) ){
				if( exists $current_value->{raw_text} and !exists $current_value->{'xml:space'} and !exists $current_value->{'ss:Type'} and
						( !defined $current_value->{raw_text} or $current_value->{raw_text} =~ /^\s+$/ ) ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Skipping rewind for unwanted raw_text node" ] );
				}else{
				
					# Delete unwanted spaces between nodes
					if( exists $current_value->{list_keys} and $current_value->{list_keys}->[-1] eq 'raw_text' and
						(!$current_value->{list}->[-1] or $current_value->{list}->[-1] =~ /^\s+$/ ) ){
						###LogSD	$phone->talk( level => 'debug', message =>[
						###LogSD		"Deleting final unwanted raw_text node" ] );
						pop @{$current_value->{list}};
						pop @{$current_value->{list_keys}};
					}elsif( $next_value eq 'raw_text' and (!$current_value or $current_value =~ /^\s+$/) ){
						###LogSD	$phone->talk( level => 'debug', message =>[
						###LogSD		"Removing unwanted spaces between nodes |" . ($current_value//'undef') . '|' ] );
						$current_value = undef;
						$next_value = undef;
						delete $current_ref->{raw_text};
					}
					
					if( defined $next_value ){
						if( is_Int( $next_value ) ){
							$current_ref->{list}->[$next_value] = $current_value;
						}else{
							$current_ref->{list}->{$next_value} = $current_value;
						}
					}
				}
			}else{
				confess "I don't know how to handle: " . Dumper( $current_ref, $next_value, $current_value );
			}
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated current ref/value:", $current_ref ] );
			$current_value = $current_ref;
		}
		
		if( $current_ref ){
			#Reload last pop
			$self->_add_bread_crumb( $next_value );
			$self->_add_ref_level( $current_ref );
		}
	}
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Get final node representations:", $self->_get_partial_ref, $self->_get_bread_crumbs,] );
	return undef;
}

sub _stack{
	my ( $self, $node_id ) = @_;
	my	$replace_key	= $self->_last_bread_crumb;
	my	$current_value	= $self->_last_ref_level;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::parse_element::_stack', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Stacking node id: " . ($node_id//''),
	###LogSD			( ( (defined $replace_key and is_Int( $replace_key ))  ?  "..against position: " :  "..to key: ") . ($replace_key//'undef')) ,
	###LogSD			 "in:",$current_value ] );
	my ( $alt_key, $alt_value );
	
	# Check for bad spaces before a tag
	if( $replace_key ){
		if( $replace_key eq 'raw_text' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Found a bad text callout in a HashRef before the tag -$node_id- with value:", $current_value, $replace_key ] );
			delete $current_value->{$replace_key};
			#~ $current_value->{$node_id} = undef;
			$replace_key = $node_id;
		}elsif( is_Int( $replace_key ) and exists $current_value->{list} and $current_value->{list_keys}->[-1] eq 'raw_text' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Found a bad text callout in a list before the tag -$node_id- with value:", $current_value,
			###LogSD		"..at position: $replace_key" ] );
			pop @{$current_value->{list}};
			pop @{$current_value->{list_keys}};
		}
	}
	push @{$current_value->{list}}, undef;
	$replace_key = $#{$current_value->{list}};
	push @{$current_value->{list_keys}}, $node_id;
		
	#Reload last pop
	$self->_add_bread_crumb( $replace_key );
	$self->_add_ref_level( $current_value );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Get final node representations:", $self->_get_partial_ref, $self->_get_bread_crumbs,] );
	return ( $replace_key, $current_value );
}

sub _empty_node{
	my ( $self, $node_name ) = @_;# Need to do a '_has_class_space' to get class space transition
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::XMLToPerlData::parse_element::_empty_node', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Handling an empty node: $node_name", ] );
	my $final_value =
			( $self->get_empty_return_type and $self->get_empty_return_type eq 'empty_string' ) ? '' : undef;
	my $ref = { $node_name => $final_value };
	$self->_add_ref_level( $ref );
	$self->_add_bread_crumb( $ref );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Updated master stack:", $self->_get_partial_ref, ] );
	return 1;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData - 
Role to turn xlsx XML to perl hashes

=head1 SYNOPSIS

	#!/usr/bin/env perl
	use Data::Dumper;
	use	MooseX::ShortCut::BuildInstance qw( build_instance );
	use	Spreadsheet::XLSX::Reader::LibXML::XMLReader;
	use	Spreadsheet::XLSX::Reader::LibXML::Error;
	use	Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData;
	my  $test_file = '../../../../test_files/xl/sharedStrings.xml';
	my  $test_instance	=	build_instance(
			package => 'TestIntance',
			superclasses =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLReader', ],
			add_roles_in_sequence =>[ 'Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData', ],
			file => $test_file,
			error_inst => Spreadsheet::XLSX::Reader::LibXML::Error->new,
			add_attributes =>{
				empty_return_type =>{
					reader => 'get_empty_return_type',
				},
			},
		);
	$test_instance->advance_element_position( 'si', 16 );# Go somewhere interesting
	print Dumper( $test_instance->parse_element ) . "\n";

	###############################################
	# SYNOPSIS Screen Output
	# 01: $VAR1 = {
	# 02:           'list' => [
	# 03:                       {
	# 04:                         't' => {
	# 05:                                'raw_text' => 'He'
	# 06:                              }
	# 07:                       },
	# 08:                       {
	# 09:                         'rPr' => {
	# 10:                                  'color' => {
	# 11:                                             'rgb' => 'FFFF0000'
	# 12:                                           },
	# 13:                                  'sz' => '11',
	# 14:                                  'b' => 1,
	# 15:                                  'scheme' => 'minor',
	# 16:                                  'rFont' => 'Calibri',
	# 17:                                  'family' => '2'
	# 18:                                },
	# 19:                         't' => {
	# 20:                                'raw_text' => 'llo '
	# 21:                              }
	# 22:                       },
	# 23:                       {
	# 24:                         'rPr' => {
	# 25:                                  'color' => {
	# 26:                                             'rgb' => 'FF0070C0'
	# 27:                                           },
	# 28:                                  'sz' => '20',
	# 29:                                  'b' => 1,
	# 30:                                  'scheme' => 'minor',
	# 31:                                  'rFont' => 'Calibri',
	# 32:                                  'family' => '2'
	# 33:                                },
	# 34:                         't' => {
	# 35:                                'raw_text' => 'World'
	# 36:                              }
	# 37:                       }
	# 38:                     ]
	# 39:         };
	###############################################
    
=head1 DESCRIPTION  ############## Re-write XMLReader POD too!!!

This documentation is written to explain ways to use this module when writing your own excel 
parser.  To use the general package for excel parsing out of the box please review the 
documentation for L<Workbooks|Spreadsheet::XLSX::Reader::LibXML>,
L<Worksheets|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>

This package is used convert xml to deep perl data structures.  As a note deep perl xml and  
data structures are not one for one compatible to xml.  However, there is a subset of xml that 
reasonably translates to deep perl structures.  For this implementation node names are treated 
as hash keys unless there are multiple subnodes within a node that have the same name.  In this 
case the subnode name is stripped and each node is added as a subref in an arrary ref.  The overall 
arrayref is attached to the key list.  Attributes are also treated as hash keys at the same level 
as the sub nodes.  Text nodes (or raw text between base tags) is treated as having the key 'raw_text'.

This reader assumes that it is a role that can be added to a class built on 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader> it expects to get the methods provided by that type 
of xml reader for traversing and reading the file.  As a consequence it doesn't accept an xml object 
or file since it expects to access the method below.

=head2 Required Methods

Follow the links to see details of the current implementation.

=over
	
L<get_empty_return_type|Spreadsheet::XLSX::Reader::LibXML::XMLReader/get_empty_return_type>

L<get_text_node|Spreadsheet::XLSX::Reader::LibXML::XMLReader/get_text_node>

L<get_attribute_hash_ref|Spreadsheet::XLSX::Reader::LibXML::XMLReader/get_attribute_hash_ref>

L<advance_element_position|Spreadsheet::XLSX::Reader::LibXML::XMLReader/advance_element_position>

L<location_status|Spreadsheet::XLSX::Reader::LibXML::XMLReader/location_status>

=back

=head2 Methods

These are the methods provided by this module.

=head3 parse_element( $level )

=over

B<Definition:> This returns a deep perl data structure that represents the full xml 
down as many levels as indicated by $level (positive is deeper) or  to the bottom for 
no passed value.  When this method is done the xml reader will be left at the begining 
of the next xml node after the ending flag for the requested node.

B<Accepts:> $level ( a positive integer )

B<Returns:> ($success, $data_ref ) This method returns a list with the first element 
being success or failure and the second element being the data ref corresponding to the 
xml being parsed.

=back 

=head1 SUPPORT

=over

L<github Spreadsheet::XLSX::Reader::LibXML/issues
|https://github.com/jandrew/Spreadsheet-XLSX-Reader-LibXML/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<yet|/SUPPORT>

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

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
