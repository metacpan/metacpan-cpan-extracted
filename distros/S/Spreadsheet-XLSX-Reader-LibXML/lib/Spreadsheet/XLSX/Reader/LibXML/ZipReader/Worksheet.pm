package Spreadsheet::XLSX::Reader::LibXML::ZipReader::Worksheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::ZipReader::Worksheet-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
	location_status					advance_element_position		parse_element
	start_the_file_over				_starts_at_the_edge				_parse_column_row
);
use Types::Standard qw(
		is_HashRef 		Int			ArrayRef		Maybe		InstanceOf		Bool
		is_Int
);
use Data::Dumper;
use MooseX::ShortCut::BuildInstance qw ( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use lib	'../../../../../../lib';
use Spreadsheet::XLSX::Reader::LibXML::Row;
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;

#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _sheet_min_col =>(
		isa			=> Int,
		writer		=> '_set_min_col',
		reader		=> '_min_col',
		predicate	=> 'has_min_col',
	);

has _sheet_min_row =>(
		isa			=> Int,
		writer		=> '_set_min_row',
		reader		=> '_min_row',
		predicate	=> 'has_min_row',
	);

has _sheet_max_col =>(
		isa			=> Int,
		writer		=> '_set_max_col',
		reader		=> '_max_col',
		predicate	=> 'has_max_col',
	);

has _sheet_max_row =>(
		isa			=> Int,
		writer		=> '_set_max_row',
		reader		=> '_max_row',
		predicate	=> 'has_max_row',
	);

has	_merge_map =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_merge_map',
		reader	=> '_get_merge_map',
		default => sub{ [] },
		handles	=>{
			_get_row_merge_map => 'get',
		},
	);

has _column_formats =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_column_formats',
		reader	=> '_get_column_formats',
		default	=> sub{ [] },
		handles	=>{
			_get_custom_column_data => 'get',
		},
	);

has _new_row_inst =>(
		isa			=> InstanceOf[ 'Spreadsheet::XLSX::Reader::LibXML::Row' ],
		reader		=> '_get_new_row_inst',
		writer		=> '_set_new_row_inst',
		clearer		=> '_clear_new_row_inst',
		predicate	=> '_has_new_row_inst',
		handles	=>{
			_get_new_row_number 	=> 'get_row_number',
			_is_new_row_hidden		=> 'is_row_hidden',
			_get_new_row_formats	=> 'get_row_format', # pass the desired format key
			_get_new_column			=> 'get_the_column', # pass a column number (no next default) returns (cell|undef|EOR)
			_get_new_next_value		=> 'get_the_next_value_position', # pass nothing returns next (cell|EOR)
			_get_new_last_value_col	=> 'get_last_value_column',
			_get_new_row_list		=> 'get_row_all',
			_get_new_row_end		=> 'get_row_end'
		},
	);
	
has _row_position_lookup =>(
		isa		=> ArrayRef[ Maybe[Int] ],
		traits	=>['Array'],
		default => sub{ [] },
		reader	=> '_get_all_positions',
		handles =>{
			_set_row_position => 'set',
			_get_row_position => 'get',
			_max_row_position_recorded => 'count',
			_remove_last_row_position => 'pop',
		},
	);
	
has _row_hidden_states =>(
		isa		=> ArrayRef[ Bool ],
		traits	=>['Array'],
		default => sub{ [] },
		reader	=> '_get_all_hidden',
		handles =>{
			_set_row_hidden => 'set',
			_get_row_hidden => 'get',
		},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _load_unique_bits{
	my( $self, ) = @_;#, $new_file, $old_file
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::_load_unique_bits::ZipReader', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the Worksheet unique bits", ] );
	
	# Read the sheet row column dimensions
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	if( $node_name eq 'dimension' or $self->advance_element_position( 'dimension' ) ){
		my $dimension = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed dimension value:", $dimension ] );
		my	( $start, $end ) = split( /:/, $dimension->{attributes}->{ref} );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Start position: $start", 
		###LogSD		( $end ? "End position: $end" : '' ), ] );
		my ( $start_column, $start_row ) = ( $self->_starts_at_the_edge ) ?
												( 1, 1 ) : $self->_parse_column_row( $start );
		my ( $end_column, $end_row	) = $end ? 
				$self->_parse_column_row( $end ) : 
				( undef, undef ) ;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'Start column: ' . ($start_column//'undef'), 'Start row: ' . ($start_row//'undef'),
		###LogSD		'End column: ' . ($end_column//'undef'), 'End row: ' . ($end_row//'undef') ] );
		$self->_set_min_col( $start_column );
		$self->_set_min_row( $start_row );
		$self->_set_max_col( $end_column ) if defined $end_column;
		$self->_set_max_row( $end_row ) if defined $end_row;
	}else{
		$self->_set_min_col( 0 );
		$self->_set_min_row( 0 );
		$self->set_error( "No sheet dimensions provided" );
	}
	
	#pull column stats
	my	$has_column_data = 1;
	( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the column configuration" ] );
	if( $node_name eq 'cols' or $self->advance_element_position( 'cols') ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Already arrived at the column data" ] );
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Restart the sheet to find the column data" ] );
		$self->start_the_file_over;
		$has_column_data = $self->advance_element_position( 'cols' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Column data search result: $has_column_data" ] );
	}
	if( $has_column_data ){
		my $column_data = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed column elements to:", $column_data ] );
		my $column_store = [];
		for my $definition ( @{$column_data->{list}} ){
			next if !is_HashRef( $definition ) or !is_HashRef( $definition->{attributes} );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing:", $definition ] );
			my $row_ref;
			map{ $row_ref->{$_} = $definition->{attributes}->{$_} if defined $definition->{attributes}->{$_} } qw( width customWidth bestFit hidden );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated row ref:", $row_ref ] );
			for my $col ( $definition->{attributes}->{min} .. $definition->{attributes}->{max} ){
				$column_store->[$col] = $row_ref;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Updated column store is:", $column_store ] );
			}
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Final column store is:", $column_store ] );
		$self->_set_column_formats( $column_store );
	}
	
	#No sheet meta data merge information available
	my	$merge_ref = [];
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the mergeCell" ] );
	( $node_depth, $node_name, $node_type ) = $self->location_status;
	my $found_merges = 0;
	if( ($node_name and $node_name eq 'mergeCells') or $self->advance_element_position( 'mergeCells') ){
		$found_merges = 1;
	}else{
		$self->start_the_file_over;
		$found_merges = $self->advance_element_position( 'mergeCells');
	}
	if( $found_merges ){
		my $merge_range = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing all merge ranges:", $merge_range ] );
		my $final_ref;
		for my $merge_ref ( @{$merge_range->{list}} ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"parsed merge element to:", $merge_ref ] );
			my ( $start, $end ) = split /:/, $merge_ref->{attributes}->{ref};
			my ( $start_col, $start_row ) = $self->_parse_column_row( $start );
			my ( $end_col, $end_row ) = $self->_parse_column_row( $end );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Start column: $start_col", "Start row: $start_row",
			###LogSD		"End column: $end_col", "End row: $end_row" ] );
			my 	$min_col = $start_col;
			while ( $start_row <= $end_row ){
				$final_ref->[$start_row]->[$start_col] = $merge_ref->{attributes}->{ref};
				$start_col++;
				if( $start_col > $end_col ){
					$start_col = $min_col;
					$start_row++;
				}
			}
		}
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Final merge ref:", $final_ref ] );
		$self->_set_merge_map( $final_ref );
	}
	$self->start_the_file_over;
	return 1;
}

sub _go_to_or_past_row{
	my( $self, $target_row ) = @_;
	my $current_row = $self->_has_new_row_inst ? $self->_get_new_row_number : 0;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_go_to_or_past_row::ZipReader', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Indexing the row forward to find row: $target_row", "From current row: $current_row" ] );
	
	# Handle a call where we are already at the required location
	if( $self->_has_new_row_inst and defined $target_row and $self->_get_new_row_number == $target_row ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		'Asked for a row that has already been built and loaded' ] );
		return $target_row;
	}
	
	# processes through the unwanted known positions quickly
	my $current_position;
	my $row_attributes;
	my $attribute_ref;
	if( $self->_max_row_position_recorded ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'The sheet has recorded some rows' ] );
		my ( $fast_forward, $test_position );
		my $test_target = $target_row;
		
		# Look forward for fast forward goal
		###LogSD	no warnings 'uninitialized';
		while( !defined $test_position and $test_target < ($self->_max_row_position_recorded - 1) ){
			$test_position = $self->_get_row_position( $test_target );
			###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Checking for a defined row position for row: $test_target",
			###LogSD		".. with position result: " . ($test_position//'undef'),
			###LogSD		".. with max known column -$max_positions- and the last 10 detailed positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
			$test_target++;
		}
		###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'After looking at and forward of the target row the test position is: ' . $test_position,
		###LogSD		"..and last 10 known columns: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] ) if defined $test_position;
		
		# Look backward for fast forward goal
		$test_target = $target_row < ($self->_max_row_position_recorded - 1) ? $target_row : -1;
		while( !defined $test_position and $test_target < ($self->_max_row_position_recorded - 1) ){
			###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Checking for a defined row position for row: $test_target",
			###LogSD		".. with position result: " . ($test_position//'undef'),
			###LogSD		".. against the last 10 positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] )  ] );
			$test_position = $self->_get_row_position( $test_target );
			$test_target--;
		}
		###LogSD	$max_positions = $self->_max_row_position_recorded - 1;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'After looking backward from the the target row the test position is: ' . ($test_position//'undef'),
		###LogSD		".. against the last 10 positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
		###LogSD	use warnings 'uninitialized';
		
		# Pull the current position
		$current_position	= $current_row ? $self->_get_row_position( $current_row ) : 0;
		$fast_forward		= $current_position ? $test_position - $current_position : $test_position;
		@$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Checking if a speed index can be done between position: " . ($current_position//'undef'),
		###LogSD		"..for last recorded row: " . ($current_row),
		###LogSD		"..to target position: $test_position",
		###LogSD		"..with proposed increment: $fast_forward",
		###LogSD		"..node name: $attribute_ref->{node_name}", "..node type: $attribute_ref->{node_type}",
		###LogSD		"..node depth: $attribute_ref->{node_depth}", ] );
		if( $fast_forward < 0 or ($attribute_ref->{node_depth} == 0 and $attribute_ref->{node_name} eq 'EOF') ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Looking for a row that is earlier than the current position" ] );
			$self->start_the_file_over;
			$fast_forward	= $test_position - 1;
			$current_row	= 0;
			$self->advance_element_position( 'row', ) ;
		}
		
		if( $fast_forward > 1 ){# Since you quit at the beginning of the next node
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Fast forwarding -$fast_forward- times", ] );
			$self->advance_element_position( 'row', $fast_forward - 1 ) ;
			@$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
			$row_attributes		= $self->get_attribute_hash_ref;
			$current_row		= $row_attributes->{r};
			$attribute_ref->{attribute_hash} = $row_attributes;
			$current_position	= $test_position;
		}
	}
	$self->_clear_new_row_inst;# We are not in Kansas anymore
	
	# move forward into the unknown (slower, in order to record steps)
	my $count = 0;
	while( defined $current_row and $target_row > $current_row ){
		@$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Reading the next row",
		###LogSD		"..from XML file position:", $attribute_ref, "..at current position: " . ($current_position//'undef')  ] );
		
		# find a row node if you don't have one
		my $result = 1;
		if( $attribute_ref->{node_name} ne 'row' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Attempting to advanced to a row node from a non row node"  ] );
			$result = $self->advance_element_position( 'row' );
			@$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Current location result: $result", $attribute_ref  ] );
		# Check for EOF node
		if( $attribute_ref->{node_name} eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Returning EOF"  ] );
			$self->_set_max_row_state;
			return 'EOF';
		}
		
		# Process the node advance
		if( $result ){
			# Get the location from the current row attributes
			$row_attributes = $self->get_attribute_hash_ref;
			$current_row	= $row_attributes->{r};
			if( !defined $row_attributes->{r} ){
				confess "arrived at a row node with no row number: " . Dumper( $row_attributes );
			}
			$current_position = defined $current_position ? $current_position + 1 : 0;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Currently at row: $current_row",
			###LogSD		"..and current position: $current_position", ] );
			if( $current_row > ($self->_max_row_position_recorded - 1) ){
				###LogSD	no warnings 'uninitialized';
				###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"The current last 10 positions from row -$current_row- of the hidden row ref: " . join( ', ', @{$self->_get_all_hidden}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				$self->_set_row_hidden( $current_row => (exists $row_attributes->{hidden} ? 1 : 0) );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"The updated last 10 positions from row -$current_row- of the hidden row ref: " . join( ', ', @{$self->_get_all_hidden}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ),
				###LogSD		"..with the current last 10 positions of the updated position row ref: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				$self->_set_row_position( $current_row => $current_position );
				###LogSD	$max_positions = $self->_max_row_position_recorded - 1;
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"The position row ref max row is: $max_positions",
				###LogSD		"..with the updated last 10 positions of the updated position row ref: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				###LogSD	use warnings 'uninitialized';
			}
			$attribute_ref->{attribute_hash} = $row_attributes;
		}else{
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Couldn't find another value row -> this is an unexpected end of file" ] );
			$self->_set_max_row_state;
			return 'EOF';
		}
		$count++;
	}
	
	# Collect the details of the final row position
	my $row_ref = $self->parse_element( undef, $attribute_ref );
	$row_ref->{list} = exists $row_ref->{list} ? $row_ref->{list} : [];
	###LogSD	$phone->talk( level => 'trace', message => [#ask => 1, 
	###LogSD		'Result of row read:', $row_ref ] );
	
	# Load text values for each cell where appropriate
	my ( $alt_ref, $column_to_cell_translations, $reported_column, $reported_position, $last_value_column );
	my $x = 0;
	for my $cell ( @{$row_ref->{list}} ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		'Processing cell:', $cell	] );
		
		$cell->{cell_type} = 'Text';
		my $v_node = $self->grep_node( $cell, 'v' );##########################################  Start figuring how this affects styles collection next
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"v node is:",  $v_node] );
		if( exists $cell->{attributes}->{t} ){
			if( $cell->{attributes}->{t} eq 's' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified potentially required shared string for cell:",  $cell] );
				my $position = ( $self->has_shared_strings_interface ) ?
						$self->get_shared_string( $v_node->{raw_text} ) : $v_node->{raw_text};
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Shared strings resolved to:",  $position] );
				if( is_HashRef( $position ) ){
					@$cell{qw( cell_xml_value rich_text )} = ( $position->{raw_text}, $position->{rich_text} );
					delete $cell->{rich_text} if !$cell->{rich_text};
				}else{
					$cell->{cell_xml_value} = $position;
				}
			}elsif( $cell->{attributes}->{t} =~ /^(str|e)$/ ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a stored string in the worksheet file: " . ($v_node//'')] );
				$cell->{cell_xml_value} = $v_node->{raw_text};
			}else{
				confess "Unknown 't' attribute set for the cell: $cell->{attributes}->{t}";
			}
			delete $cell->{attributes}->{t};
		}elsif( $v_node ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Setting cell_xml_value from: $v_node->{raw_text}", ] );
			$cell->{cell_xml_value} = $v_node->{raw_text};
			$cell->{cell_type} = 'Numeric' if $cell->{cell_xml_value} and $cell->{cell_xml_value} ne '';
		}
		if( $self->get_empty_return_type eq 'empty_string' ){
			$cell->{cell_xml_value} = '' if !exists $cell->{cell_xml_value} or !defined $cell->{cell_xml_value};
		}elsif( !defined $cell->{cell_xml_value} or
				($cell->{cell_xml_value} and length( $cell->{cell_xml_value} ) == 0) ){
			delete $cell->{cell_xml_value};
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:",  $cell] );
		
		# Clear empty cells if required
		if( $self->get_values_only and ( !defined $cell->{cell_xml_value} or length( $cell->{cell_xml_value} ) == 0 ) ){
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		'Values only called - stripping this non-value cell'	] );
		}else{
			$cell->{cell_type} = 'Text' if !exists $cell->{cell_type};
			$cell->{cell_hidden} = 'row' if $row_ref->{attributes}->{hidden};
			@$cell{qw( cell_col cell_row )} = $self->_parse_column_row( $cell->{attributes}->{r} );
			$cell->{r} = $cell->{attributes}->{r};
			$cell->{s} = $cell->{attributes}->{s} if exists $cell->{attributes}->{s};
			delete $cell->{attributes}->{r};
			$last_value_column = $cell->{cell_col};
			my $formula_node = $self->grep_node( $cell, 'f' );
			$cell->{cell_formula} = $formula_node->{raw_text} if $formula_node;
			$column_to_cell_translations->[$cell->{cell_col}] = $x++;
			$reported_column = $cell->{cell_col} if !defined $reported_column;
			$reported_position = 0;
			delete $cell->{attributes};
			delete $cell->{list};
			delete $cell->{list_keys};
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		'Saving cell:', $cell	] );
			push @$alt_ref, $cell;
		}
	}
	
	#Load the row instance
	my $new_ref;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Row ref:", $row_ref, ] );
	if( defined $row_ref->{attributes}->{r} ){
		$new_ref->{row_number} = $row_ref->{attributes}->{r};
		delete $row_ref->{attributes}->{r};
		delete $row_ref->{list};
		delete $row_ref->{list_keys};
		delete $row_ref->{attributes}->{hidden};
		if( $alt_ref ){
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Alt ref:", $alt_ref, "updated row ref:", $row_ref, "new ref:", $new_ref,] );
			$new_ref->{row_value_cells}	= $alt_ref;
			$new_ref->{row_span} = $row_ref->{attributes}->{spans} ? [split /:/, $row_ref->{attributes}->{spans}] : [ undef, undef ];
			$new_ref->{row_last_value_column} = $last_value_column;
			$new_ref->{column_to_cell_translations}	= $column_to_cell_translations;
			$new_ref->{row_span}->[0] //= $new_ref->{row_value_cells}->[0]->{cell_col};
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"adjusted new ref:", $new_ref,] );
			if( !$self->has_max_col or $self->_max_col < $new_ref->{row_value_cells}->[-1]->{cell_col} ){
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"From known cells setting the max column to: $new_ref->{row_value_cells}->[-1]->{cell_col}" ] );
				$self->_set_max_col( $new_ref->{row_value_cells}->[-1]->{cell_col} );
			}
			if( defined $new_ref->{row_span}->[1] and $self->_max_col < $new_ref->{row_span}->[1] ){
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"From the row span setting the max column to:  $new_ref->{row_span}->[1]" ] );
				$self->_set_max_col(  $new_ref->{row_span}->[1] );
			}else{
				$new_ref->{row_span}->[1] //= $self->_max_col;
			}
		}else{
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		" No row list (with values?) found" ] );
			$new_ref->{row_span} = [ 0, 0 ];
			$new_ref->{row_last_value_column} = 0;
			$new_ref->{column_to_cell_translations}	= [];
		}
		delete $row_ref->{attributes}->{spans};# Delete just attributes here?
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Row formats:", $row_ref,
		###LogSD		"Row attributes:", $new_ref, ] );
		my 	$row_node_ref =	build_instance( 
				package 		=> 'RowInstance',
				superclasses	=> [ 'Spreadsheet::XLSX::Reader::LibXML::Row' ],
				row_formats		=> $row_ref,
				%$new_ref,
		###LogSD	log_space 	=> $self->get_log_space
			);
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"New row instance:", $row_node_ref, ] );
		$self->_set_new_row_inst( $row_node_ref );
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"line 706 - No row number found - must be EOF", ] );
		return 'EOF';
	}
	
	if( !$alt_ref ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'Nothing to see here - move along', ] );
		###LogSD	no warnings 'uninitialized';
		my $result = $current_row + 1;
		if( is_Int( $current_row ) ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD	"Going on to the next row: " . ($current_row +1), ] );
			no warnings 'recursion';
			$result = $self->_go_to_or_past_row( $current_row + 1 );# Recursive call for empty rows
			use warnings 'recursion';
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD	"Returned from the next row with: " . ($result//'undef'),
			###LogSD	"..target current row is: " . ($current_row +1), ] );
			$self->_set_row_position( $current_row => undef );# Clean up phantom placeholder
			my $max_positions = $self->_max_row_position_recorded - 1;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD	"The last 10 position ref values are: " .
			###LogSD	join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ), ] );
		}
		$current_row = $result;
		###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'Updated current row -$current_row- pdated last 10 row positions are: ' . 
		###LogSD		join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
		###LogSD	use warnings 'uninitialized';
	}
	$self->_set_max_row_state if $current_row and $current_row eq 'EOF';
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning: ", $current_row ] );
	return $current_row;
}

sub _set_max_row_state{
	my( $self, ) = @_;
	my $row_position_ref = $self->_get_all_positions;
	my $max_positions = $#$row_position_ref;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_go_to_or_past_row::_set_max_row_state', );
	###LogSD	no warnings 'uninitialized';
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"The current max row is: " . ($self->has_max_row ? $self->_max_row : 'undef'),
	###LogSD			"Setting the max row from the last 10 positions of the row position ref:" . join( ', ', @$row_position_ref[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
	###LogSD	use warnings 'uninitialized';
	if( $self->is_empty_the_end ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Clearing empty rows from the end" ] );
		my $last_position;
		while( !defined $last_position ){
			$last_position = $self->_remove_last_row_position;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Removed the last row position value: " . ($last_position//'undef'),
			###LogSD		"..from position: " . $self->_max_row_position_recorded ] );
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Reload the final poped value: " . $self->_max_row_position_recorded . ' => ' . $last_position ] );
		$self->_set_row_position( $self->_max_row_position_recorded => $last_position );
	}
	my $last_row = $self->_max_row_position_recorded - 1;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Setting the max row to: $last_row" ] );
	$self->_clear_new_row_inst;
	$self->start_the_file_over;
	$self->_set_max_row( $last_row );
	return $last_row;
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::ZipReader::Worksheet - Zip file unique Worksheet reader

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

This software is copyrighted (c) 2014 - 2016 by Jed Lund

=head1 DEPENDENCIES

=over

L<Spreadsheet::XLSX::Reader::LibXML> - which has it's own dependancies

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