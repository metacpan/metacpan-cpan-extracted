package Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
		current_named_node				current_node_parsed				starts_at_the_edge
		_parse_column_row				advance_element_position		good_load
		start_the_file_over				squash_node						parse_element
		spreading_merged_values			should_skip_hidden				has_shared_strings_interface
		get_shared_string				are_spaces_empty				get_empty_return_type
		get_values_only					collecting_merge_data			collecting_column_formats
	);
use Clone 'clone';
use Carp qw( confess );
use Types::Standard qw(
		Bool 				Int 			is_HashRef				ArrayRef
		Maybe				HashRef
	);
use MooseX::ShortCut::BuildInstance qw ( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use lib	'../../../../lib';
###LogSD	use Log::Shiras::Telephone;
#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has is_hidden =>(
		isa		=> Bool,
		reader	=> 'is_sheet_hidden',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub advance_row_position{
	my( $self, $increment ) = @_;
	$increment //= 1;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::FileWorksheet::advance_row_position', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Moving row forward -$increment- times", ] );
	my( $result, $node_name, $node_level ) =  $self->advance_element_position( 'row', $increment );
	###LogSD		$phone->talk( level => 'debug ', message => [
	###LogSD			"advance result is:" . ($result//'fail') ] );
	return undef if !$result;

	# Pull data about the row
	my $row_ref = $self->current_node_parsed;
	$row_ref = $row_ref->{row};
	delete $row_ref->{raw_text};
	$self->_set_custom_row_data( $row_ref->{r} => $row_ref );# Should this be tied into cache_positions?
	###LogSD		$phone->talk( level => 'debug ', message => [
	###LogSD			"parse result is:", $row_ref, $self->_get_all_positions, ] );

	return $row_ref;
}

sub build_row_data{
	my( $self, ) = @_;# $row_ref, $row_position
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::FileWorksheet::build_row_data', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building out the current row node", ] );
	my $full_row_ref = $self->squash_node( $self->parse_element );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Full row parsed to:", $full_row_ref, ] );

	# Confirm row list
	if( exists  $full_row_ref->{c} ){
		my $alt_row->{list} = [ $full_row_ref->{c} ];
		delete $full_row_ref->{c};
		$alt_row->{attributes} = $full_row_ref;
		$full_row_ref = $alt_row;
	}
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"New full row adjusted to:", $full_row_ref, ] );
	my $new_ref;
	@$new_ref{qw( row_number row_formats )} = exists $full_row_ref->{attributes} ?
		( $full_row_ref->{attributes}->{r}, $full_row_ref->{attributes} ) :
		( $full_row_ref->{r}, $full_row_ref ) ;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"updated Full row:", $full_row_ref,
	###LogSD		"New row ref initialized as:", $new_ref ] );

	# set spans value
	if( exists $full_row_ref->{attributes}->{spans} ){
		$new_ref->{row_span} =
			[ $full_row_ref->{attributes}->{spans} =~ /(\d+):(\d+)/ ];
	}else{
		$new_ref->{row_span} = [($self->_min_col//1),($self->_max_col//1)];
	}
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Updated new ref:", $new_ref ] );

	# Parse the cells for position and range
	my $column_to_cell_translations = [];
	my $last_value_column;
	my $alt_ref;
	for my $cell ( @{$full_row_ref->{list}} ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Processing cell:", $cell] );
		@$cell{qw( cell_col cell_row )} = $self->_parse_column_row( $cell->{r} );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Cell column: $cell->{cell_col}", "Cell row: $cell->{cell_row}" ] );

		# load cell_type, cell_xml_value, and rich text
		#   can't delay this because the information is required for 'empty_is_end'
		$cell->{cell_type} = 'Text';
		my $v_node = $cell->{v};
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"v node is:",  $v_node ] );
		if( exists $cell->{t} ){
			if( $cell->{t} eq 's' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified potentially required shared string for cell:",  $cell] );
				my $position = ( $self->has_shared_strings_interface ) ?
						$self->get_shared_string( $v_node ) : $v_node;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Shared strings resolved to:",  $position] );
				if( is_HashRef( $position ) ){
					@$cell{qw( cell_xml_value rich_text )} = ( $position->{raw_text}, $position->{rich_text} );
					delete $cell->{rich_text} if !$cell->{rich_text};
				}else{
					$cell->{cell_xml_value} = $position;
				}
			}elsif( $cell->{t} =~ /^(e|inlineStr)$/ ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a stored string in the worksheet file: ", $v_node ] );
				$cell->{cell_xml_value} = $v_node;
			}elsif( $cell->{t} eq 'str' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a potential formula stored in the core data position: ", $v_node ] );
				$cell->{cell_xml_value} = $v_node;
                if( !exists $cell->{f}  and $v_node =~ /\=/ ){
                    $cell->{f} = $v_node;
                }
			}elsif( $cell->{t} eq 'b' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a stored boolean in the worksheet file: ", $v_node ] );
				$cell->{cell_xml_value} = $v_node ? 1 : 0 ;
                $cell->{cell_type} = 'Numeric';
			}elsif( $cell->{t} eq 'd' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a stored date in the worksheet file: ", $v_node ] );
				$cell->{cell_xml_value} = $v_node;
                $cell->{cell_type} = 'Date';
			}elsif( $cell->{t} eq 'n' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified a stored number in the worksheet file: ", $v_node ] );
				$cell->{cell_xml_value} = $v_node;
                $cell->{cell_type} = 'Numeric';
			}else{
				confess "Unknown 't' attribute set for the cell: $cell->{t}";
			}
			delete $cell->{t};
			if( $self->are_spaces_empty and $cell->{cell_xml_value} and $cell->{cell_xml_value} =~ /^\s+$/ ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Clearing spaces only xml value: " . ($v_node//'')] );
				delete $cell->{cell_xml_value};
			}
		}elsif( defined $v_node ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Setting cell_xml_value from: $v_node", ] );
			$cell->{cell_xml_value} = $v_node;
			$cell->{cell_type} = 'Numeric' if $cell->{cell_xml_value} and $cell->{cell_xml_value} ne '';
		}
		delete $cell->{v};
		if( $self->get_empty_return_type eq 'empty_string' ){
			$cell->{cell_xml_value} = '' if !exists $cell->{cell_xml_value} or !defined $cell->{cell_xml_value};
		}elsif( !defined $cell->{cell_xml_value} or
				($cell->{cell_xml_value} and length( $cell->{cell_xml_value} ) == 0) ){
			delete $cell->{cell_xml_value};
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:",  $cell] );

		# Handle formula, position translations, and last value
		$cell->{cell_formula} = $cell->{f} if exists $cell->{f};
		delete $cell->{f};
		$last_value_column = $cell->{cell_col};
		push @$alt_ref, $cell;
		$column_to_cell_translations->[$cell->{cell_col}] = $#$alt_ref;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'Saving cell:', $cell, $alt_ref,
		###LogSD		"..with column to cell translations:", $column_to_cell_translations,
		###LogSD		"..and last value column: $last_value_column",	] );
	}

	# Scrub merge cells, column formats, and then empty values
	my $max_column = ( $last_value_column and $new_ref->{row_span}->[1] < $last_value_column) ?
						$last_value_column : $new_ref->{row_span}->[1];
	my( $cell_stack, $position_stack );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Asking for row merge map of:", $new_ref ] );
	my $merge_range = $self->_get_row_merge_map( $new_ref->{row_number} );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Full row merge settings:", $merge_range ] );
	SCRUBINGCELLSTACK: for my $col ( 1 .. $max_column ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing column: $col", ,
		###LogSD		(defined $column_to_cell_translations->[$col] ? $alt_ref->[$column_to_cell_translations->[$col]] : undef)	] );
		my $new_cell;

		# Resolve additional merge info
		if( $merge_range and $merge_range->[$col] ){# Do it different for named worksheets
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Column -$col- is part of a merge range", $new_cell->{cell_merge} ] );

			# Handle primary position sharing
			if( $self->spreading_merged_values ){
				my $not_primary = 1;
				if( defined $column_to_cell_translations->[$col] and $alt_ref->[$column_to_cell_translations->[$col]] ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Checking column -$col- to see if it contains the primary value" ] );
					$merge_range->[$col] =~ /([^:]+)/;
					if( $alt_ref->[$column_to_cell_translations->[$col]]->{r} eq $1 ){
						$not_primary = 0;
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"Found a primary value at: " . $alt_ref->[$column_to_cell_translations->[$col]]->{r} ] );
						my $primary_ref;
						for my $key ( qw( rich_text cell_xml_value s cell_type ) ){
							if( !exists $primary_ref->{$key} and
								exists $alt_ref->[$column_to_cell_translations->[$col]]->{$key} ){
								$primary_ref->{$key} = $alt_ref->[$column_to_cell_translations->[$col]]->{$key};
							}
						}
						###LogSD	$phone->talk( level => 'debug', message =>[
						###LogSD		"primary ref is:", $primary_ref ] );
						delete $primary_ref->{rich_text} if !$primary_ref->{rich_text};
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"Built primary ref: ", $primary_ref ] );
						$self->_set_merged_value( $merge_range->[$col] => $primary_ref );
					}
				}
				if( $not_primary ){
					$new_cell = $self->_get_merged_value( $merge_range->[$col] );
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"New cell now has: ", $new_cell ] );
				}
			}
			$new_cell->{cell_merge} = $merge_range->[$col];
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"updated new cell now has: ", $new_cell ] );
		}

		# Handle formats (especially from the column) including hidden - more work needed here!
		if( $new_cell or (defined $column_to_cell_translations->[$col] and
			$alt_ref->[$column_to_cell_translations->[$col]] 		) ){
			$new_cell->{cell_hidden} =
				$self->is_sheet_hidden ? 'sheet' :
				(	$self->get_custom_column_data( $col ) and
					exists $self->get_custom_column_data( $col )->{hidden} and
					$self->get_custom_column_data( $col )->{hidden} ) ? 'column' :
				$full_row_ref->{attributes}->{hidden} ? 'row' : undef ;
			delete $new_cell->{cell_hidden} if !$new_cell->{cell_hidden};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"updated new cell now has: ", $new_cell ] );
		}

		# Load in remaining data
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Possibly loading additional cell data: ", defined $column_to_cell_translations->[$col] ? $alt_ref->[$column_to_cell_translations->[$col]] : $column_to_cell_translations->[$col] ] );
		if( defined $column_to_cell_translations->[$col] and $alt_ref->[$column_to_cell_translations->[$col]] ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Mapping file column -$col- from position: $column_to_cell_translations->[$col]", ] );
			map{ $new_cell->{$_} = $alt_ref->[$column_to_cell_translations->[$col]]->{$_} if !exists $new_cell->{$_} } keys %{$alt_ref->[$column_to_cell_translations->[$col]]};
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated new cell:",  $new_cell ] );

		# Skip hidden
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Should skip hidden: " . $self->should_skip_hidden,
		###LogSD		"With hidden value exists: " . (($new_cell and exists $new_cell->{ cell_hidden }) ? $new_cell->{ cell_hidden } : 'undef'), $new_cell ] );
		if( $self->should_skip_hidden and $new_cell and exists $new_cell->{cell_hidden} ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Skipping a known hidden cell", $new_cell ] );
			next SCRUBINGCELLSTACK;
		}

		# Skip empty
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Checking values only: " . $self->get_values_only,
		###LogSD		"With xml value exists: " . exists $new_cell->{cell_xml_value}, $new_cell ] );
		if( $self->get_values_only and $new_cell and !exists $new_cell->{cell_xml_value} ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Skipping the empty cell", $new_cell ] );
			next SCRUBINGCELLSTACK;
		}

		# Stack new data
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Checking if anything was stored in new_cell:", $new_cell ] );
		if( $new_cell and (keys %$new_cell ) > 0 ){
			push @$cell_stack, $new_cell;
			$position_stack->[$new_cell->{cell_col}] = $#$cell_stack;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		'Updated cell stack:', $cell_stack,
			###LogSD		'..with position stack:', $position_stack	] );
			$last_value_column = $new_cell->{cell_col};
		}
	}
	$new_ref->{column_to_cell_translations} = $position_stack;

	# Handle full empty rows here
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'Updated cell stack:', $cell_stack,
	###LogSD		'..with position stack:', $position_stack,
	###LogSD		'..and last value column:', $last_value_column	] );
	if( $cell_stack ){
		$new_ref->{row_value_cells} = $cell_stack;
		# Update max column as needed
		$new_ref->{row_last_value_column} = $last_value_column;
		if( !$self->has_max_col or $last_value_column > $self->_max_col ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updating max column with: $last_value_column",	] );
			$self->_set_max_col( $last_value_column );
		}
		# Update span end
		if( $new_ref->{row_span}->[1] < $last_value_column ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updating span-end with: $last_value_column",	] );
			$new_ref->{row_span}->[1] = $last_value_column;
		}
		# Update max row
		if( !$self->has_max_row or $new_ref->{row_number} > $self->_max_row ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updating max row with: $new_ref->{row_number}",	] );
			$self->_set_max_row( $new_ref->{row_number} );
		}
		# Update max column
		if( !$self->has_max_col or $new_ref->{row_span}->[1] > $self->_max_col ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updating max column with: $new_ref->{row_span}->[1]",	] );
			$self->_set_max_col( $new_ref->{row_span}->[1] );
		}
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'No data available for this row',	] );
		return undef;
	}


	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Updated new ref:", $new_ref,] );
	return $new_ref;
}

sub load_unique_bits{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::FileWorksheet::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the Worksheet unique bits", ] );

	# Read the sheet row-column dimensions
	my $good_load = 0;
	my $current_named_node = $self->current_named_node;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Currently at named node:", $current_named_node, ] );
	my	$result = 1;
	my( $node_name, $node_level, $node_ref );
	if( $current_named_node->{name} eq 'dimension' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the dimension node" ] );
	}else{
		( $result, $node_name ) = $self->advance_element_position( 'dimension' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"attempt to get to the dimension node result: $result" ] );
	}
	if( $result ){
		my $dimension = $self->current_node_parsed;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed dimension value:", $dimension ] );
		my	( $start, $end ) = split( /:/, $dimension->{dimension}->{ref} );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Start position: $start",
		###LogSD		( $end ? "End position: $end" : '' ), ] );
		my ( $start_column, $start_row ) = ( $self->starts_at_the_edge ) ?
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
		$good_load = 1;
	}else{
		$self->_set_min_col( 0 );
		$self->_set_min_row( 0 );
		$self->set_error( "No sheet dimensions provided" );
	}

	# Work without a net !!!!!
	$self->change_stack_storage_to( 0 );

	#pull column stats
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Checking if column data should be collected: " . $self->collecting_column_formats ] );
	if( $self->collecting_column_formats ){
		if( $node_name eq 'EOF' ){
			$self->start_the_file_over;
		}
		( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position( 'cols' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Arrived at node named -$node_name- with result: $result", ] );
		if( $result ){

			# Build the node and add it to the stack
			my $node_ref = $self->initial_node_build( $node_name, $node_ref );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Returned from initial node build with node:", $node_ref ] );
			$self->add_node_to_stack( $node_ref );

			# Pull the data
			my $column_data = $self->parse_element;
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"parsed column elements to:", $column_data ] );

			# Process the data
			my $column_store = [];
			for my $definition ( @{$column_data->{list}} ){
				next if !is_HashRef( $definition ) or !is_HashRef( $definition->{attributes} );
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Processing:", $definition ] );
				my $row_ref;
				map{ $row_ref->{$_} = $definition->{attributes}->{$_} if defined $definition->{attributes}->{$_} } qw( width customWidth bestFit hidden );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Updated row ref:", $row_ref ] );
				for my $col ( $definition->{attributes}->{min} .. $definition->{attributes}->{max} ){
					$column_store->[$col] = $row_ref;
					###LogSD	$phone->talk( level => 'trace', message => [
					###LogSD		"Updated column store is:", $column_store ] );
				}
			}
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final column store is:", $column_store ] );
			$good_load = 1;
			$self->_set_column_formats( $column_store );
		}
	}

	# Get sheet meta data merge information
	my	$merge_ref = [];
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Checking if merged data should be collected: " . $self->collecting_merge_data ] );
	if( $self->collecting_merge_data ){
		if( $node_name eq 'EOF' ){
			$self->start_the_file_over;
		}
		( $result, $node_name, $node_level, $node_ref ) = $self->advance_element_position( 'mergeCells' );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Arrived at node named -$node_name- with result: $result", ] );

		if( $result ){

			# Build the node and add it to the stack
			my $node_ref = $self->initial_node_build( $node_name, $node_ref );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Returned from initial node build with node:", $node_ref ] );
			$self->add_node_to_stack( $node_ref );

			my $merge_range = $self->parse_element;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Processing all merge ranges:", $merge_range ] );
			$merge_range = $self->squash_node( $merge_range );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"squashed merge range:", $merge_range ] );
			my $final_ref = [];
			for my $merge_ref ( @{$merge_range->{list}} ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"parsed merge element to:", $merge_ref ] );
				my ( $start, $end ) = split /:/, $merge_ref->{ref};
				my ( $start_col, $start_row ) = $self->_parse_column_row( $start );
				my ( $end_col, $end_row ) = $self->_parse_column_row( $end );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Start column: $start_col", "Start row: $start_row",
				###LogSD		"End column: $end_col", "End row: $end_row" ] );
				my 	$min_col = $start_col;
				while ( $start_row <= $end_row ){
					$final_ref->[$start_row]->[$start_col] = $merge_ref->{ref};
					$start_col++;
					if( $start_col > $end_col ){
						$start_col = $min_col;
						$start_row++;
					}
				}
			}
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Final merge ref:", $final_ref ] );
			$good_load = 1;
			$self->_set_merge_map( $final_ref );
		}# exit 1;
	}

	# Record file state
	if( $good_load ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The Worksheet file has metadata" ] );
		$self->good_load( 1 );
	}else{
		$self->set_error( "No 'Worksheet' definition elements found - can't parse this as a Worksheet file" );
		return undef;
	}

	$self->start_the_file_over;
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Finished the worksheet unique bits" ] );
	return 1;
}

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

has _column_formats =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_column_formats',
		reader	=> '_get_column_formats',
		default	=> sub{ [] },
		handles	=>{
			get_custom_column_data => 'get',
		},
	);

has _row_formats =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_row_formats',
		reader	=> '_get_row_formats',
		default	=> sub{ [] },
		handles	=>{
			get_custom_row_data => 'get',
			_set_custom_row_data => 'set',
		},
	);

has	_merge_map =>(
		isa		=> ArrayRef,
		traits	=> ['Array'],
		writer	=> '_set_merge_map',
		reader	=> 'get_merge_map',
		default => sub{ [] },
		handles	=>{
			_get_row_merge_map => 'get',
		},
	);

has _primary_merged_values =>(# Values for the top left corner of the merge range
		isa		=> HashRef,
		traits	=> ['Hash'],
		reader	=> '_get_all_merged_values',
		default	=> sub{ {} },
		handles =>{
			_set_merged_value => 'set',
			_get_merged_value => 'get',
		},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::FileWorksheet - Zip file worksheet interpreter

=head1 SYNOPSIS

See t\Spreadsheet\Reader\ExcelXML\XMLReader\05-file_worksheet.t

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel
parser.  To use the general package for excel parsing out of the box please review the
documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module incrementally adds functionality to the base class
L<Spreadsheet::Reader::ExcelXML::XMLReader>. The goal is to parse individual worksheet files
(not chartsheets) from the zip file format (.xlsx) into perl objects  The primary purpose
of this role is to normalize functions used by L<Spreadsheet::Reader::ExcelXML::WorksheetToRow>
where other roles could be used to normalize other formats.  It does not provide a way to read
L<chartsheets|Spreadsheet::Reader::ExcelXML::Chartsheet>.

I<All positions (row and column places and integers) at this level are stored and returned
in count from one mode!>

To replace this part in the package look in the raw code of
L<Spreadsheet::Reader::ExcelXML::Workbook> and adjust the 'worksheet_interface' key of the
$parser_modules variable.

=head2 requires

This module is a L<role|Moose::Manual::Roles> and as such only adds incremental methods and
attributes to some base class.  In order to use this role some base object methods are
required.  The requirments are listed below with links to the default provider.

=over

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_named_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/current_node_parsed>

L<Spreadsheet::Reader::ExcelXML::XMLReader/advance_element_position>

L<Spreadsheet::Reader::ExcelXML::XMLReader/good_load>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/squash_node>

L<Spreadsheet::Reader::ExcelXML::XMLReader/parse_element>

"_parse_column_row" in L<Spreadsheet::Reader::ExcelXML::CellToColumnRow
|Spreadsheet::Reader::ExcelXML::CellToColumnRow/parse_column_row( $excel_cell_id )>

L<Spreadsheet::Reader::ExcelXML/spreading_merged_values>

L<Spreadsheet::Reader::ExcelXML/should_skip_hidden>

L<Spreadsheet::Reader::ExcelXML/has_shared_strings_interface>

L<Spreadsheet::Reader::ExcelXML/are_spaces_empty>

L<Spreadsheet::Reader::ExcelXML/get_empty_return_type>

L<Spreadsheet::Reader::ExcelXML/get_values_only>

L<Spreadsheet::Reader::ExcelXML/starts_at_the_edge>

L<Spreadsheet::Reader::ExcelXML/collecting_merge_data>

L<Spreadsheet::Reader::ExcelXML/collecting_column_formats>

L<Spreadsheet::Reader::ExcelXML::SharedStrings/get_shared_string( $positive_intE<sol>$name )>

=back

=head2 Attributes

Data passed to new when creating an instance.  This list only contains public attributes
incrementally provided by this role.  For access to the values in these attributes see
the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the
L<Methods|/Methods>.

=head3 is_hidden

=over

B<Definition:> This data is collected at the workbook level for this file type.  It indicates
if the sheet is human visible.

B<Range:> (1|0)

B<attribute methods> Methods provided to adjust this attribute

=over

B<is_sheet_hidden>

=over

B<Definition:> return the attribute value

=back

=back

=back

=head3 _sheet_min_col

=over

B<Definition:> This is the minimum column in the sheet with data or formatting.  For this
module it is pulled from the xml file at worksheet/dimension:ref = "upperleft:lowerright"

B<Range:> an integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<_min_col>

=over

B<Definition:> returns the attribute value

=back

B<has_min_col>

=over

B<Definition:> attribute predicate

=back

=back

=back

=head3 _sheet_min_row

=over

B<Definition:> This is the minimum row in the sheet with data or formatting.  For this
module it is pulled from the xml file at worksheet/dimension:ref = "upperleft:lowerright"

B<Range:> an integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<_set_min_row>

=over

B<Definition:> sets the attribute value

=back

B<_min_row>

=over

B<Definition:> returns the attribute value

=back

B<has_min_row>

=over

B<Definition:> attribute predicate

=back

=back

=back

=head3 _sheet_max_col

=over

B<Definition:> This is the maximum column in the sheet with data or formatting.  For this
module it is pulled from the xml file at worksheet/dimension/ref = "upperleft:lowerright"

B<Range:> an integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<_set_max_col>

=over

B<Definition:> sets the attribute value

=back

B<_max_col>

=over

B<Definition:> returns the attribute value

=back

B<has_max_col>

=over

B<Definition:> attribute predicate

=back

=back

=back

=head3 _sheet_max_row

=over

B<Definition:> This is the maximum row in the sheet with data or formatting.  For this
module it is pulled from the xml file at worksheet/dimension:ref = "upperleft:lowerright"

B<Range:> an integer

B<attribute methods> Methods provided to adjust this attribute

=over

B<_set_max_row>

=over

B<Definition:> sets the attribute value

=back

B<_max_row>

=over

B<Definition:> returns the attribute value

=back

B<has_max_row>

=over

B<Definition:> attribute predicate

=back

=back

=back

=head2 Methods

These are the methods provided by this class for use within the package but are not intended
to be used by the end user.  Other private methods not listed here are used in the module but
not used by the package.  If a method is listed here then replacement of this module
either requires replacing the method or rewriting all the associated connecting roles and classes.

=head3 load_unique_bits

=over

B<Definition:> This is called by L<Spreadsheet::Reader::ExcelXML::XMLReader> when the file is
loaded for the first time so that file specific metadata can be collected.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 advance_row_position( $increment )

=over

B<Definition:> As an XML data structure each worksheet has three levels of information.  The
column data is stored separately in the file and just referenced.  The row data encases all
the cell data for that row.  Each cell contains modifiers to row and column settings.  The
column data is read during the 'load_unique_bits' method.  The cell specific data is not
completed here.  This method will advance to the next recorded row position in the XML file.
Not to be confused with the next row number.  If you want to advance to the 'next' position
more than one time then you can provide a value for $increment.

B<Accepts:> a positive integer $increment (defaults to 1 if no value passed)

B<Returns:> The attribute ref of the top row node

=back

=head3 build_row_data

=over

B<Definition:> Collects all the sub-information (XML node) for the row in order to build
the argument for populating a L<Spreadsheet::Reader::ExcelXML::Row> instance.

B<Accepts:> nothing

B<Returns:> a hash ref of inputs for L<Spreadsheet::Reader::ExcelXML::Row>

=back

=head3 get_custom_column_data( $column )

=over

B<Definition:> Returns any collected custom column information for the indicated
$column.

B<Accepts:> a positive integer $column in count from 1 context

B<Returns:> a hash ref of custom column settings

=back

=head3 get_custom_row_data( $row )

=over

B<Definition:> Returns any collected custom row information for the indicated $row.

B<Accepts:> a positive integer $row in count from 1 context

B<Returns:> a hash ref of custom row settings

=back

=head3 get_merge_map

=over

B<Definition:> This returns the full merge map with merge ranges stored in each
position for the range of known rows and columns.

B<Accepts:> nothing

B<Returns:> an array ref of array refs where the top level array represents
rows stored in count from 1 context and the second level array ref are the
columns stored in count from 1 context.  (The first position for each will
therefor be dead space)

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> If a the primary cell of a merge range is hidden show that value
in the top left unhidden cell even when the attribute
L<Spreadsheet::Reader::ExcelXML::Workbook/spread_merged_values> is not
set.  (This is the way excel does it(ish))

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

#########1 Documentation End  3#########4#########5#########6#########7#########8#########9
