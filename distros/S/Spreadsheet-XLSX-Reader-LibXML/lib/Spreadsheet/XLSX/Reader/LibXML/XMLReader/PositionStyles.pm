package Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionStyles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::PositionStyles-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
		get_defined_conversion		location_status				start_the_file_over
		advance_element_position	parse_element				set_defined_excel_formats
		grep_node					_close_file_and_reader			
	);#empty_return_type						DEMOLISH			
use Types::Standard qw(
		Bool			ArrayRef			Int			is_HashRef			is_Int
    );
use Carp qw( confess );
use Clone qw( clone );

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9

my	$element_lookup ={
		numFmts			=> 'numFmt',
		fonts			=> 'font',
		borders			=> 'border',
		fills			=> 'fill',
		cellStyleXfs	=> 'xf',
		cellXfs			=> 'xf',
		cellStyles		=> 'cellStyle',
		tableStyles		=> 'tableStyle',
	};

my	$key_translations ={
		fontId		=> 'fonts',
		borderId	=> 'borders',
		fillId		=> 'fills',
		xfId		=> 'cellStyles',
		#~ pivotButton	 => 'pivotButton',
	};

my	$cell_attributes ={
		fontId			=> 'cell_font',
		borderId		=> 'cell_border',
		fillId			=> 'cell_fill',
		xfId			=> 'cell_style',
		numFmtId		=> 'cell_coercion',
		alignment		=> 'cell_alignment',
		numFmts			=> 'cell_coercion',
		fonts			=> 'cell_font',
		borders			=> 'cell_border',
		fills			=> 'cell_fill',
		cellStyleXfs	=> 'cellStyleXfs',
		cellXfs			=> 'cellXfs',
		cellStyles		=> 'cell_style',
		tableStyles		=> 'tableStyle',
		#~ pivotButton		=> 'pivotButton',
	};

my	$xml_from_cell ={
		cell_font		=> 'fontId',
		cell_border		=> 'borderId',
		cell_fill		=> 'fillId',
		cell_style		=> 'xfId',
		cell_coercion	=> 'numFmtId',
		cell_alignment	=> 'alignment',
	};

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9
	
has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_format{
	my( $self, $position, $header, $exclude_header ) = @_;
	my	$xml_target_header = $header ? $header : '';#$xml_from_cell->{$header}
	my	$xml_exclude_header = $exclude_header ? $xml_from_cell->{$exclude_header} : '';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_format', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Get defined formats at position: $position",
	###LogSD			( $header ? "Returning only the values for header: $header - $xml_target_header" : '' ),
	###LogSD			( $exclude_header ? "..excluding the values for header: $exclude_header - $xml_exclude_header" : '' ) , ] );
	
	# Check for stored value - when caching implemented
	my	$already_got_it = 0;
	if( $self->_has_styles_positions ){
		if( $position > $self->_get_styles_count - 1 ){
			$self->set_error( "Requested styles position is out of range for this workbook" );
			return undef;
		}
		my $target_ref = clone( $self->_get_s_position( $position ) );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The complete cached style is:", $target_ref, ] );
		if( $header ){
			$target_ref = $target_ref->{$header} ? { $header => $target_ref->{$header} } : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The cached style with target header -$header- only is:", $target_ref  ] );
		}elsif( $exclude_header ){
			delete $target_ref->{$exclude_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The cached style with exclude header -$exclude_header- removed is:", $target_ref  ] );
		}
		return $target_ref;
	}
	
	# pull the value the long (hard and slow) way
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Starting at node: $node_name",  "..at node depth: $node_depth", "..and node type: $node_type"  ] );
	
	# Pull the base ref
	my( $success, $base_ref ) = $self->_get_header_and_value( 'cellXfs', $position );
	if( !$success ){
		confess "Unable to pull position -$position- of the base stored formats (cellXfs)";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Building out the position -$position- for:", $base_ref,
	###LogSD		( $header ? "..with target header: $xml_target_header" : '' ), ( $exclude_header ? "..and exclude header: $xml_exclude_header" : '' ) ] );
	my $built_ref = $self->_build_perl_style_formats( $base_ref, $xml_target_header, $xml_exclude_header );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Built position -$position- is:", $built_ref ] );
	my $return_ref;
	for my $top_key ( keys %$built_ref ){
		$return_ref->{$top_key} = $self->_build_perl_node_from_xml_perl( $built_ref->{$top_key}, $built_ref->{$top_key} );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Updated return ref:", $return_ref ] );
	}
	return $return_ref;
}

sub get_default_format{
	my( $self, $header, $exclude_header ) = @_;
	my	$position = 0;
	my	$xml_target_header = $header ? $xml_from_cell->{$header} : '';
	my	$xml_exclude_header = $exclude_header ? $xml_from_cell->{$exclude_header} : '';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_default_format_position', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Get defined formats at default position: $position",
	###LogSD			( $header ? "Returning only the values for header: $header - $xml_target_header" : '' ),
	###LogSD			( $exclude_header ? "..excluding the values for header: $exclude_header - $xml_exclude_header" : '' ) , ] );
	
	# Check for stored value - when caching implemented
	my	$already_got_it = 0;
	if( $self->_has_generic_styles_positions ){
		if( $position > $self->_get_generic_styles_count - 1 ){
			$self->set_error( "Requested default styles position is out of range for this workbook" );
			return undef;
		}
		my $target_ref = $self->_get_gs_position( $position );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The complete cached style is:", $target_ref  ] );
		if( $header ){
			$target_ref = $target_ref->{$header} ? { $header => $target_ref->{$header} } : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The cached style with target header only is:", $target_ref  ] );
		}elsif( $exclude_header ){
			delete $target_ref->{$exclude_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The cached style with exclude header -$exclude_header- removed is:", $target_ref  ] );
		}
		return $target_ref;
	}
	
	# pull the value the long (hard and slow) way
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Starting at node: $node_name",  "..at node depth: $node_depth", "..and node type: $node_type"  ] );
	
	# Pull the base ref
	my( $success, $base_ref ) = $self->_get_header_and_value( 'cellStyleXfs', $position );
	if( !$success ){
		confess "Unable to pull position -$position- of the base stored generic formats (cellStylesXfs)";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Building out the position -$position- for:", $base_ref,
	###LogSD		( $header ? "..with target header: $xml_target_header" : '' ), ( $exclude_header ? "..and exclude header: $xml_exclude_header" : '' ) ] );
	my $built_ref = $self->_build_perl_style_formats( $base_ref, $xml_target_header, $xml_exclude_header );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Built position -$position- is:", $built_ref ] );
	my $return_ref;
	for my $top_key ( keys %$built_ref ){
		$return_ref->{$top_key} = $self->_build_perl_node_from_xml_perl( $built_ref->{$top_key}, $built_ref->{$top_key} );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Updated return ref:", $return_ref ] );
	}
	return $return_ref;
}



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _loaded =>(
		isa		=> Bool,
		writer	=> '_good_load',
		reader	=> 'loaded_correctly',
		default	=> 0,
	);
	
has _styles_positions =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		handles	=>{
			_get_s_position => 'get',
			_set_s_position => 'set',
			_add_s_position => 'push',
		},
		reader => '_get_all_cache',
		predicate => '_has_styles_positions'
	);
	
has _styles_count =>(
		isa		=> Int,
		default	=> 0,
		reader => '_get_styles_count',
		writer => '_set_styles_count',
	);
	
has _generic_styles_positions =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		handles	=>{
			_get_gs_position => 'get',
			_set_gs_position => 'set',
			_add_gs_position => 'push',
		},
		reader => '_get_all_generic_cache',
		predicate => '_has_generic_styles_positions'
	);
	
has _generic_styles_count =>(
		isa		=> Int,
		default	=> 0,
		reader => '_get_generic_styles_count',
		writer => '_set_generic_styles_count',
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_load_unique_bits', );
	#~ ###LogSD		$phone->talk( level => 'trace', message => [ 'self:', $self ] );
	
	# Advance to the styleSheet node
	my $good_load = 0;
	$self->start_the_file_over;
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Currently at libxml2 level: $node_depth",
	###LogSD		"Current node name: $node_name",
	###LogSD		"..for type: $node_type", ] );
	my	$result = 1;
	if( $node_name eq 'styleSheet' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the styleSheet node" ] );
	}else{
		$result = $self->advance_element_position( 'styleSheet' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"attempt to get to the Styles element result: $result" ] );
	}
	
	# Record file state
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The styleSheet node has value" ] );
		$self->_good_load( 1 );# Is there a need to check for an empty node here???
	}else{
		$self->set_error( "No 'styleSheet' elements with content found - can't parse this as a styles file" );
		return undef;
	}
	
	# Initial pull from the xml
	my ( $success, $custom_format_ref, $top_level_ref );
	if( $self->should_cache_positions ){
		$top_level_ref = $self->parse_element;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Parsing the whole thing for caching" ] );
		$self->_close_file_and_reader;# Don't need the file open any more!
		
		( $success, $custom_format_ref ) = $self->grep_node( $top_level_ref, 'numFmts' );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Initial extraction of numFmts:", $custom_format_ref ] );
	}else{
		if( $self->advance_element_position( 'numFmts' ) ){
			$custom_format_ref = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Pulling the custom number formats only:", $custom_format_ref ] );
		}
	}
	
	# Load the custom formats
	if( $custom_format_ref ){
		my	$translations;
		for my $format ( @{$custom_format_ref->{list}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Adding sheet defined translations:", $format ] );
			my	$format_code = $format->{attributes}->{formatCode};
				$format_code =~ s/\\//g;
			$translations->[$format->{attributes}->{numFmtId}] = $format_code;
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'loaded format positions:', $translations ] );
		$self->set_defined_excel_formats( $translations );
	}
	
	# Cache remaining as needed
	my( $list_to_cache, $count );
	if( $self->should_cache_positions ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Load the rest of the cache" ] );
		my $perlized_ref = $self->_build_perl_node_from_xml_perl( $top_level_ref, $top_level_ref );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Extracting elements from:", $perlized_ref ] );
		
		# Build specfic formats
		my $cell_xfs = $perlized_ref->{cellXfs};
		if( !$cell_xfs ){
			confess "No base level formats (cellXfs) stored";
		}else{
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Loading specific cell formats:", $cell_xfs ] );
			$self->_set_styles_count( scalar( @{$cell_xfs->{list}} ) );
			map{ $self->_add_s_position( $_ ) } @{$cell_xfs->{list}};
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final specific caches:", $self->_get_all_cache ] );
		}
		
		
		# Build generic formats
		my $cell_style_xfs = $perlized_ref->{cellStyleXfs};
		if( $cell_style_xfs ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Loading generic cell formats" ] );
			$self->_set_generic_styles_count( scalar( @{$cell_style_xfs->{list}} ) );
			map{ $self->_add_gs_position( $_ ) } @{$cell_style_xfs->{list}};
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final generic caches:", $self->_get_all_generic_cache ] );
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Completed caching" ] );
	}
	return 1;
}

sub _build_perl_style_formats{
	my( $self, $base_ref, $target_header, $exclude_header ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_build_perl_style_formats', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building a perl style (cell ready) ref from the base xml ref", $base_ref,
	###LogSD			( $target_header ? "..returning only header: $target_header" : undef ),
	###LogSD			( $exclude_header ? "..excluding header: $exclude_header" : undef ), ] );
	my $return_ref;
	if( $target_header ){
		if( exists $xml_from_cell->{$target_header} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Possible conversion of header -$target_header- to: $xml_from_cell->{$target_header}", ] );
			if( exists $base_ref->{attributes}->{$xml_from_cell->{$target_header}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"$xml_from_cell->{$target_header} is a key in:", $base_ref, ] );
				$target_header = $xml_from_cell->{$target_header};
			}
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing sub group: $target_header", "..with position: $base_ref->{attributes}->{$target_header}", ] );
		$return_ref = { $self->_get_header_and_value( $target_header, $base_ref->{attributes}->{$target_header} ) };
	}else{
		for my $key ( keys %{$base_ref->{attributes}} ){
			next if $key eq $exclude_header;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing sub group: $key", "..with position: ", $base_ref->{attributes}->{$key}, ] );
			my( $key, $sub_ref ) = $self->_get_header_and_value( $key, $base_ref->{attributes}->{$key} );
			$return_ref->{$key} = $sub_ref;
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Returning ref:", $return_ref ] );
	return $return_ref;
}

sub _get_header_and_value{
	my( $self, $target_header, $target_position ) = @_;
	$target_header = exists $key_translations->{$target_header} ? $key_translations->{$target_header} : $target_header;
	my $sub_header = exists $element_lookup->{$target_header} ? $element_lookup->{$target_header} : 'dealers_choice';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_get_header_and_value', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"getting the ref for target header: $target_header",
	###LogSD			"..with sub header: $sub_header",
	###LogSD			"..and position: $target_position",			] );
	
	
	my( $key, $value );
	if( $target_header =~ /^apply/ ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Found an 'apply flag'",			] );
		( $key, $value ) = ( $target_header, $target_position );
	}elsif( $target_header eq 'numFmtId' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Pulling the number conversion for position: $target_position", ] );
		( $key, $value ) = ( $cell_attributes->{$target_header}, $self->get_defined_conversion( $target_position ) );
	}elsif( !exists $cell_attributes->{$target_header} ){
		$self->set_error( "Format key -$target_header- not yet supported by this package" );
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Reaching into the xml for header -$target_header- position: $target_position", ] );
		if( is_Int( $target_position ) ){
			my ( $node_depth, $node_name, $node_type ) = $self->location_status;
			my $sub_header = $element_lookup->{$target_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"For the super header: $target_header",
			###LogSD		"Accessing the Styles file for position -$target_position- of the header: $sub_header",
			###LogSD		"..currently at a node named: $node_name", "..of node type: $node_type", "..and node depth: $node_depth"] );
			
			# Begin at the beginning
			if( $node_name eq $target_header or $self->advance_element_position( $target_header ) ){# Can't tell which sub position you are at :(
			my ( $node_depth, $node_name, $node_type ) = $self->location_status;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Arrived at: $target_header",
				###LogSD		"..currently at a node named: $node_name", "..of node type: $node_type", "..and node depth: $node_depth" ] );
			}else{
				$self->start_the_file_over;
				if( $self->advance_element_position( $target_header ) ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Rewound to: $target_header" ] );
				}else{
					return( undef, undef );
				}
			}
	
			# Index to the indicated sub position
			my $result = $self->advance_element_position( $sub_header, $target_position + 1 );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Advancing to position -$target_position- gives result: $result" ] );
			if( !$result ){
				$self->set_error( "Requested styles sub position for -$target_header- is not found in this workbook" );
				return( undef, undef );
			}
			
			# Pull the data
			my $base_ref = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Pulling data from target header -$target_header- for position -$target_position- gives ref:", $base_ref ] );
			
			( $key, $value ) = ( $cell_attributes->{$target_header}, $base_ref );
		}else{
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"just translating the key for the sub-ref:",  $target_position ] );
			( $key, $value ) = ( $cell_attributes->{$key}, $target_position );
		}
	}
	
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Returning key: $key", "..and value:", $value ] );
	return( $key, $value );
}

sub _build_perl_node_from_xml_perl{
	my( $self, $top_ref, $current_ref, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_build_perl_node_from_xml_perl', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"building out the ref:", $current_ref ] );
	###LogSD		$phone->talk( level => 'trace', message => [
	###LogSD			"..with high level ref:",  $top_ref ] );
	my $new_ref;
	
	if( is_HashRef( $current_ref ) ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"processing a hashref" ] );
		
		# Handle attributes
		if( is_HashRef( $current_ref->{attributes} ) ){
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"processing the attributes of a hashref" ] );
			for my $attribute ( keys %{$current_ref->{attributes}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Processing the attribute $attribute => $current_ref->{attributes}->{$attribute}", ] );
				if( $attribute eq 'xfId' or $attribute eq 'builtinId' ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Skipping the -$attribute- attribute", ] );
				}elsif( $attribute eq 'numFmtId' ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Setting -$cell_attributes->{$attribute}- with number conversion for position: $current_ref->{attributes}->{$attribute}", ] );
					$new_ref->{$cell_attributes->{$attribute}} = $self->get_defined_conversion( $current_ref->{attributes}->{$attribute} );
				}elsif( $attribute =~ /Id$/i ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"pulling sub ref for attribute -$attribute- from: $key_translations->{$attribute}", ] );
					my( $success, $sub_node ) = $self->grep_node( $top_ref, $key_translations->{$attribute}, );
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Pulling position -$current_ref->{attributes}->{$attribute}- from sub ref:", $sub_node ] );
					$new_ref->{$cell_attributes->{$attribute}} = $self->_build_perl_node_from_xml_perl( $top_ref, $sub_node->{list}->[$current_ref->{attributes}->{$attribute}] );
				}elsif( exists $cell_attributes->{$attribute} ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Setting -$cell_attributes->{$attribute}- to value: $current_ref->{attributes}->{$attribute}", ] );
					$new_ref->{$cell_attributes->{$attribute}} = $current_ref->{attributes}->{$attribute};
				}else{
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Setting -$attribute- to value: $current_ref->{attributes}->{$attribute}", ] );
					$new_ref->{$attribute} = $current_ref->{attributes}->{$attribute};
				}
			}
		}elsif( exists $current_ref->{attributes} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The attribute only has a base value: $current_ref->{attributes}" ] );
			$new_ref = $current_ref->{attributes};
		}
		
		# Handle sub lists
		if( exists $current_ref->{list_keys} ){
			my $x = 0;
			my $use_list = 0;
			my $list_subref;
			my @list_keys = @{$current_ref->{list_keys}};
			for my $list_node ( @list_keys ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Processing list node: $list_node", $current_ref->{list}->[$x] ] );
				if( exists $new_ref->{$list_node} ){
					$use_list = 1;
				}
				my $sub_node = $self->_build_perl_node_from_xml_perl( $top_ref, $current_ref->{list}->[$x++] );
				push @{$new_ref->{list}}, $sub_node;
				$new_ref->{$list_node} = $sub_node;
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Intermediate new list:", $new_ref ] );
			if( $use_list or exists $new_ref->{count} ){
				map{ delete $new_ref->{$_} } @list_keys;
			}else{
				delete $new_ref->{list};
			}
		}
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Probably at the bottom of the branch - returning the value: " . ($current_ref//'undef') ] );
		$new_ref = $current_ref;
	}
	
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final new ref is:", $new_ref ] );
	return $new_ref;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::PositionStyles - Support for 2007+ styles files

=head1 SYNOPSYS

Not written yet

=head1 DESCRIPTION

Not written yet

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Binary Excel 2003 and earlier

L<Spreadsheet::XLSX> - 2007+

L<Spreadsheet::ParseXLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end   5#########6#########7#########8#########9