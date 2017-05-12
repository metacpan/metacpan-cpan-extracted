package Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles-$VERSION";

use 5.010;
use Moose::Role;
requires qw(
		get_defined_conversion		start_the_file_over			close_the_file
		advance_element_position	parse_element				set_defined_excel_formats
		current_named_node			set_error					squash_node
		good_load
	);
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
		dxfs			=> 'dxf',
	};

my	$key_translations ={
		fontId		=> 'fonts',
		borderId	=> 'borders',
		fillId		=> 'fills',
		xfId		=> 'cellStyles',
		dxfId		=> 'dxfs',
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
		dxfId			=> 'table_style',
		cellStyleXfs	=> 'cellStyleXfs',
		cellXfs			=> 'cellXfs',
		cellStyles		=> 'cell_style',
		tableStyles		=> 'tableStyle',
		pivotButton		=> 'pivotButton',
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

	# pull the data the long (hard and slow) way
	# Pull the base ref
	my( $success, $base_ref ) = $self->_get_header_and_value( 'cellXfs', $position );
	if( !$success ){
		confess "Unable to pull position -$position- of the base stored formats (cellXfs)";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Updated base ref:", $base_ref ] );

	my $built_ref = $self->_build_cell_style_formats( $base_ref, $xml_target_header, $xml_exclude_header );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Updated built ref:", $built_ref ] );
	return $built_ref;
}

sub get_default_format{
	my( $self, $header, $exclude_header ) = @_;
	my	$position = 0;
	my	$xml_target_header = $header ? $xml_from_cell->{$header} : '';
	my	$xml_exclude_header = $exclude_header ? $xml_from_cell->{$exclude_header} : '';
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_default_format', );
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

	# pull the data the long (hard and slow) way
	# Pull the base ref
	my( $key, $base_ref ) = $self->_get_header_and_value( 'cellStyleXfs', $position );
	if( !$key ){
		confess "Unable to pull the default position (0) for stored formats (cellStyleXfs)";
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Received key -$key- with value:", $base_ref ] );

	my $built_ref = $self->_build_cell_style_formats( $base_ref, $xml_target_header, $xml_exclude_header );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Updated built ref:", $built_ref ] );
	return $built_ref;
}

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::load_unique_bits', );
	#~ ###LogSD		$phone->talk( level => 'trace', message => [ 'self:', $self ] );

	# Advance to the styleSheet node
	my( $result, $node_name, $node_level, $result_ref );
	my $current_node = $self->current_node_parsed;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"The current node is:", $current_node ] );
	if( (keys %$current_node)[0] eq 'styleSheet' ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Found the core properties node" ] );
		$result = 2;
		$node_name = 'styleSheet';
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'styleSheet' );
	}

	# Record file state
	if( $result ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The styleSheet node has value" ] );
		$self->good_load( 1 );# Is there a need to check for an empty node here???
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
		$self->close_the_file;# Don't need the file open any more!

		$top_level_ref = $self->squash_node( $top_level_ref );#, 'numFmts'
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Squashed ref:", $top_level_ref ] );
		$custom_format_ref =
			!exists $top_level_ref->{numFmts} ? undef :
			exists $top_level_ref->{numFmts}->{list} ?
				$top_level_ref->{numFmts}->{list} :
				[ $top_level_ref->{numFmts}->{numFmt} ] ;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Initial extraction of numFmts:", $custom_format_ref ] );
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'numFmts' );
		if( $result ){
			$top_level_ref = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Pulling the custom number formats only:", $custom_format_ref ] );
			$top_level_ref = $self->squash_node( $top_level_ref );#, 'numFmts'
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Squashed ref:", $top_level_ref ] );
			$custom_format_ref = exists $top_level_ref->{list} ?
				$top_level_ref->{list} : [ $top_level_ref->{numFmt} ] ;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Initial extraction of numFmts:", $custom_format_ref ] );
		}
		$self->start_the_file_over;
	}

	# Load the custom formats
	if( $custom_format_ref ){
		my	$translations;
		for my $format ( @$custom_format_ref ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Adding sheet defined translations:", $format ] );
			my	$format_code = $format->{formatCode};
				$format_code =~ s/\\//g;
			$translations->[$format->{numFmtId}] = $format_code;
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'loading format positions:', $translations ] );
		$self->set_defined_excel_formats( $translations );
	}

	# Cache remaining as needed
	my( $list_to_cache, $count );
	if( $self->should_cache_positions ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Build and load the rest of the cache", $top_level_ref ] );

		# Build specfic formats
		if( !exists $top_level_ref->{cellXfs} or
			(!exists $top_level_ref->{cellXfs}->{list} and !exists $top_level_ref->{cellXfs}->{xf}) ){
			$self->set_error( "No base level formats (cellXfs) stored" );
		}else{
			my $cell_xfs = exists $top_level_ref->{cellXfs}->{list} ?
				$top_level_ref->{cellXfs}->{list} : [ $top_level_ref->{cellXfs}->{xf} ];
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Loading specific cell formats:", $cell_xfs ] );
			$self->_set_styles_count( scalar( @$cell_xfs ) );
			for my $position ( @$cell_xfs ){
				my $stacked_ref = $self->_stack_perl_ref( $top_level_ref, $position );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Updated position:", $stacked_ref ] );
				$self->_add_s_position( $stacked_ref );
			}
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final specific caches:", $self->_get_all_cache ] );
		}

		# Build generic formats
		if( exists $top_level_ref->{cellStyleXfs} and
			(exists $top_level_ref->{cellStyleXfs}->{list} or exists $top_level_ref->{cellStyleXfs}->{xf}) ){
			my $cell_style_xfs = exists $top_level_ref->{cellStyleXfs}->{list} ?
				$top_level_ref->{cellStyleXfs}->{list} : [ $top_level_ref->{cellStyleXfs}->{xf} ];
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Loading generic cell formats" ] );
			$self->_set_generic_styles_count( scalar( @$cell_style_xfs ) );
			for my $position ( @$cell_style_xfs ){
				my $stacked_ref = $self->_stack_perl_ref( $top_level_ref, $position );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Updated position:", $stacked_ref ] );
				$self->_add_gs_position( $stacked_ref );
			}
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final generic caches:", $self->_get_all_generic_cache ] );
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Completed caching" ] );
	}
	return 1;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

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

sub _build_cell_style_formats{
	my( $self, $base_ref, $target_header, $exclude_header ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_build_cell_style_formats', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building a perl style (cell ready) ref from the base xml ref", $base_ref,
	###LogSD			( $target_header ? "..returning only header: $target_header" : undef ),
	###LogSD			( $exclude_header ? "..excluding header: $exclude_header" : undef ), ] );
	my $return_ref;

	# Handle target header
	if( $target_header ){
		if( exists $xml_from_cell->{$target_header} and exists $base_ref->{$xml_from_cell->{$target_header}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Possible conversion of header -$target_header- to: $xml_from_cell->{$target_header}", ] );
			$return_ref->{$xml_from_cell->{$target_header}} = $base_ref->{$xml_from_cell->{$target_header}};
		}elsif( exists $base_ref->{$target_header} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Using header -$target_header- as is", ] );
			$return_ref->{$target_header} = $base_ref->{$target_header};
		}else{
			my $alt_header = exists $cell_attributes->{$target_header} ? $cell_attributes->{$target_header} : $target_header;
			$self->set_error( "Failed to isolate -$target_header- in the passed ref" );
			return { $alt_header => undef };
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Updated return ref:", $return_ref ] );
	}

	# Handle exclude header
	if( !$return_ref ){# Handle no target or exclude calls
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Adding all elements to be filled", ] );
		$return_ref = clone( $base_ref );
	}
	if( $exclude_header ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Excluding: $exclude_header", ] );
		if( exists $xml_from_cell->{$exclude_header} and exists $return_ref->{$xml_from_cell->{$exclude_header}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Possible conversion of header -$exclude_header- to: $xml_from_cell->{$exclude_header}", ] );
			delete $return_ref->{$xml_from_cell->{$exclude_header}};
		}elsif( exists $base_ref->{$target_header} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Using header -$exclude_header- as is", ] );
			delete $return_ref->{$target_header};
		}
	}

	# Load the sub values
	$return_ref = $self->_stack_perl_ref( 'dummy', $return_ref );
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
			my $current_node = $self->current_named_node;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Starting at node:", $current_node,  "..and position: " . ($self->where_am_i//'undef')  ] );
			my $sub_header = $element_lookup->{$target_header};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"For the super header: $target_header",
			###LogSD		"Accessing the Styles file for position -$target_position- of the header: $sub_header",
			###LogSD		"..currently at the node:", $current_node,] );

			# Begin at the beginning
			my( $result, $node_name, $node_level, $result_ref );
			if( $current_node->{name} eq $target_header ){
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Found the core properties node" ] );
				$result = 2;
				$node_name = $target_header;
			}else{
				( $result, $node_name, $node_level, $result_ref ) =
					$self->advance_element_position( $target_header );# Can't tell which sub position you are at :(
					###LogSD	$phone->talk( level => 'trace', message =>[
					###LogSD		"After search arrived at node -$node_name- with result: $result" ] );
				if( !$result ){# One more attempt
					###LogSD	$phone->talk( level => 'trace', message =>[
					###LogSD		"Starting the file over just in case the value is back" ] );
					$self->start_the_file_over;
					( $result, $node_name, $node_level, $result_ref ) =
						$self->advance_element_position( $target_header );
					###LogSD	$phone->talk( level => 'trace', message =>[
					###LogSD		"After search arrived at node -$node_name- with result: $result" ] );
				}
				if( !$result ){# Just not here!
					###LogSD	$phone->talk( level => 'trace', message =>[ "Fail!!!!!!!!!!" ] );
					$self->set_error( "Requested styles header -$target_header- is not found in this workbook" );
					return( undef, undef );
				}
			}

			# Index to the indicated sub position
			( $result, $node_name, $node_level, $result_ref ) =
				$self->advance_element_position( $sub_header, $target_position + 1 );
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"After search for header -$sub_header- and position -" .
			###LogSD		($target_position + 1) . "- arrived at node -$node_name- with result: $result" ] );
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
	$value = $self->squash_node( $value );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Returning key: $key", "..and value:", $value ] );
	return( $key, $value );
}

sub _stack_perl_ref{
	my( $self, $top_ref, $current_ref, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_stack_perl_ref', );
	###LogSD		$phone->talk( level => 'trace', message => [
	###LogSD			"..with high level ref:",  $top_ref ] );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"building out the ref:", $current_ref ] );
	my $new_ref;

	# Handle attributes
	if( is_HashRef( $current_ref ) ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"processing the attributes of a hashref" ] );
		for my $attribute ( keys %$current_ref ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing the attribute $attribute => $current_ref->{$attribute}", ] );
			if( $attribute eq 'xfId' or $attribute eq 'builtinId' ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Skipping the -$attribute- attribute", ] );
			}elsif( $attribute eq 'numFmtId' ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Setting -$cell_attributes->{$attribute}- with number conversion for position: $current_ref->{$attribute}", ] );
				$new_ref->{$cell_attributes->{$attribute}} = $self->get_defined_conversion( $current_ref->{$attribute} );
			}elsif( $attribute =~ /Id$/i ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"pulling sub ref for attribute -$attribute- from: $key_translations->{$attribute}", substr($attribute, 0, -2) ] );
				my( $key, $return );
				if( $self->should_cache_positions ){
					###LogSD	$phone->talk( level => 'trace', message => [
					###LogSD		"Positions should be cached (built) already - using top ref:", $top_ref ] );
					my $sub_node = $top_ref->{$key_translations->{$attribute}};
					my $count = exists $sub_node->{count} ? $sub_node->{count} : undef ;# to be used for double checking as needed
					my $list_ref = exists $sub_node->{list} ? $sub_node->{list} : [$sub_node->{substr($attribute, 0, -2)}] ;
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Pulling position -$current_ref->{$attribute}- from sub ref:", $sub_node, $list_ref ] );
					$return = $list_ref->[$current_ref->{$attribute}];
					$key = $cell_attributes->{$attribute};
				}else{
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Positions are not cached - pulling the data from subsection " .
					###LogSD		"-$key_translations->{$attribute}- and position: $current_ref->{$attribute}", ] );
					( $key, $return ) = $self->_get_header_and_value( $key_translations->{$attribute}, $current_ref->{$attribute} );
				}
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Setting the new ref attribute -$key- based on the base attribute -$attribute- as the cell value:", $return ] );
				$new_ref->{$key} = $return;
			}elsif( exists $cell_attributes->{$attribute} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Setting new ref key -$cell_attributes->{$attribute}- to value: $current_ref->{$attribute}", ] );
				$new_ref->{$cell_attributes->{$attribute}} = $current_ref->{$attribute};
			}else{
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Setting new ref key -$attribute- to value: $current_ref->{$attribute}", ] );
				$new_ref->{$attribute} = $current_ref->{$attribute};
			}
		}
	}elsif( defined $current_ref ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The attribute only has a base value: $current_ref->{attributes}" ] );
		$new_ref = $current_ref;
	}

	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Final new ref is:", $new_ref ] );
	return $new_ref;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::PositionStyles - Position based styles reader

=head1 SYNOPSYS

	!!!! Example code - will not run standalone !!!!

	use MooseX::ShortCut::BuildInstance qw( build_instance );
	use Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles;
	use Spreadsheet::Reader::ExcelXML::XMLReader;
	my	$test_instance	=	build_instance(
			package => 'StylesInterface',
			superclasses => ['Spreadsheet::Reader::ExcelXML::XMLReader'],
			add_roles_in_sequence => [
				'Spreadsheet::Reader::ExcelXML::XMLReader::PositionStyles',
			],
			file => 'styles.xml',
			workbook_inst => $workbook_instance,<--- Built elswhere!!!
		);

=head1 DESCRIPTION

This role is written to provide the methods 'get_format' and 'get_default_format' for
the styles file reading where the styles file elements are called out by position.
The usually occurs in the case where and .xlsx file (zipped format) is provided.

=head2 Requires

These are the methods required by this role and their default provider.  All
methods are imported straight across with no re-naming.

=over

L<Spreadsheet::Reader::Format::ParseExcelFormatStrings/get_defined_conversion( $position )>

L<Spreadsheet::Reader::Format::FmtDefault/set_defined_excel_formats( %args )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_named_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node( $node )>

L<Spreadsheet::Reader::ExcelXML::Error/set_error( $error_string )>

=back

=head2 Method(s)

These are the methods provided by this role.

=head3 get_format( $position, [$header], [$exclude_header] )

=over

B<Definition:> This will return the styles information from the identified $position
(counting from zero).  The target position is usually drawn from the cell data stored in
the worksheet.  The information is returned as a perl hash ref.  Since the styles data
is in two tiers it finds all the subtier information for each indicated piece and appends
them to the hash ref as values for each type key.

B<Accepts position 0:> $position = an integer for the styles $position.

B<Accepts position 1:> $header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will cause only this header subset to be returned

B<Accepts position 2:> $exclude_header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will exclude the header from the returned data set.

B<Returns:> a hash ref of data

=back

=head3 get_default_format( [$header], [$exclude_header] )

=over

B<Definition:> For any cell that does not have a unquely identified format excel generally
stores a default format for the remainder of the sheet.  This will return the two
tiered default styles information.  The information is returned in the same format as the
get_format method.

B<Accepts position 0:> $header = the target header key (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will cause only this header subset to be returned

B<Accepts position 1:> $exclude_header = the target header key (optional at position 2) (use the
L<Spreadsheet::Reader::ExcelXML::Cell/Attributes> that are cell formats as the definition
of range for this.)  It will exclude the header from the returned data set.

B<Returns:> a hash ref of data

=back

=head3 load_unique_bits

=over

B<Definition:> When the xml file first loads this is available to pull customized data.
It mostly pulls metadata and stores it in hidden attributes for use later.  If all goes
according to plan it sets L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load> to 1.

B<Accepts:> Nothing

B<Returns:> Nothing

=back

=head2 Attributes

Data passed to new when creating an instance with this role. For
modification of this(ese) attribute(s) see the listed 'attribute
methods'.  For more information on attributes see
L<Moose::Manual::Attributes>.  The easiest way to modify this(ese)
attribute(s) is during instance creation before it is passed to the
workbook or parser.

=head3 cache_positions

=over

B<Definition:> Especially for sheets with lots of stored formats the
parser can slow way down when accessing each postion.  This is
because the are not stored sequentially and the reader is a JIT linear
parser.  To go back it must restart and index through each position till
it gets to the right place.  This is especially true for excel sheets
that have experienced any significant level of manual intervention prior
to being read.  This attribute sets caching (default on) for styles
so the parser builds and stores all the styles settings at the beginning.
If the file is cached it will close and release the file handle in order
to free up some space. (a small win in exchange for the space taken by
the cache).

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
