package Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
		current_named_node				current_node_parsed				squash_node
		advance_element_position		good_load						start_the_file_over
		_build_cell_label				get_epoch_year					parse_element
		spreading_merged_values			should_skip_hidden				are_spaces_empty
		get_empty_return_type			get_values_only
	);
use Clone 'clone';
use Carp qw( confess );
use Types::Standard qw(
		Bool 				Int 			is_HashRef			ArrayRef
		HashRef
	);
use MooseX::ShortCut::BuildInstance qw ( build_instance should_re_use_classes );
use DateTime::Format::Flexible;
use DateTimeX::Format::Excel;
should_re_use_classes( 1 );
use lib	'../../../../lib';
###LogSD	use Log::Shiras::Telephone;
#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9

my	$format_translations = {
		width		=> 'ss:Width',
		customWidth	=> 'ss:CustomWidth',
		bestFit		=> 'ss:AutoFitWidth',
		hidden		=> 'ss:Hidden',
		mergeAcross => 'ss:MergeAcross',
		mergeDown   => 'ss:MergeDown',
		r			=> 'ss:Index',
		cell_col	=> 'ss:Index',
		ht		=> 'ss:Height',
		cell_type	=> 'ss:Type',
		s			=> 'ss:StyleID',
		cell_xml_value	=> 'raw_text',
		cell_formula	=> 'ss:Formula',
	};

my	$rich_text_translations = {
		'html:Color'	=> 'rgb',
		'html:Size'		=> 'sz',
	};

my $width_translation = 9.5703125/50.25;# Translation from 2003 xml file width to 2007+ width

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has is_hidden =>(
		isa		=> Bool,
		reader	=> 'is_sheet_hidden',
		writer	=> '_set_sheet_hidden',
		default => 0,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub advance_row_position{
	my( $self, $increment ) = @_;#, $new_file, $old_file
	$increment //= 1;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::NamedWorksheet::advance_row_position', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Moving row forward -$increment- times", ] );
	my $new_ref;
	for my $x ( 1 .. $increment ){
		my( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'Row' );
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Advanced to 'Row' increment -$x- time(s) arriving at node -" .
		###LogSD		"$node_name- with result: " . ($result//'fail'), ] );
		last if !$result;
		$new_ref = undef;
		my $row_node = $self->current_node_parsed;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"current node is:", $row_node] );
		map{
			if( defined $row_node->{Row}->{$format_translations->{$_}} ){
				$new_ref->{$_} = $row_node->{Row}->{$format_translations->{$_}}
			}
		} qw( r hidden ht );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"converted result is:", $new_ref] );
		$self->_set_current_row_number( $new_ref->{r}//($self->_get_current_row_number + 1) );
		$new_ref->{r} //= $self->_get_current_row_number;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"augmented result is:", $new_ref] );
		$self->_set_custom_row_data( $new_ref->{r} => $new_ref );# Should this be tied into cache_positions?
	}

	return $new_ref;
}

sub build_row_data{
	my( $self, ) = @_;# $row_ref, $row_position
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::NamedWorksheet::build_row_data', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Building out the current row node", ] );
	my $full_row_ref = $self->squash_node( $self->parse_element );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Full row parsed to:", $full_row_ref, ] );

	# Check EOF
	if( !ref( $full_row_ref ) ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Probably found an end of file flag: $full_row_ref", ] );
		return $full_row_ref;
	}

	# Confirm row list
	if( exists  $full_row_ref->{Cell} ){
		my $alt_row->{list} = [ $full_row_ref->{Cell} ];
		delete $full_row_ref->{Cell};
		$alt_row->{attributes} = $full_row_ref;
		$full_row_ref = $alt_row;
	}
	my $new_ref;
	map{
		if( defined $full_row_ref->{attributes}->{$format_translations->{$_}} ){
			$full_row_ref->{attributes}->{$_} = $full_row_ref->{attributes}->{$format_translations->{$_}};
			delete $full_row_ref->{attributes}->{$format_translations->{$_}};
		}
	} qw( r hidden ht );
	$new_ref->{row_number} = $self->_get_current_row_number;
	$new_ref->{row_formats} = $full_row_ref->{attributes};
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"updated Full row:", $full_row_ref,
	###LogSD		"New row ref initialized as:", $new_ref ] );

	# set spans value
	$new_ref->{row_span} = [($self->_min_col//1),($self->_max_col//1)];
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Updated new ref:", $new_ref ] );

	# Parse the cells for position and range
	my $column_to_cell_translations = [];
	my $last_value_column;
	my $alt_ref;
	my $current_column = 0;
	for my $cell ( @{$full_row_ref->{list}} ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Processing cell:", $cell] );
		map{
			if( defined $cell->{$format_translations->{$_}} ){
				$cell->{$_} = $cell->{$format_translations->{$_}};
				delete $cell->{$format_translations->{$_}};
			}
		} qw( cell_col hidden s mergeAcross mergeDown cell_formula );
		if( exists $cell->{Data} ){# Handle regular values
			map{
				if( defined $cell->{Data}->{$format_translations->{$_}} ){
					$cell->{$_} = $cell->{Data}->{$format_translations->{$_}};
				}
			} qw( cell_type cell_xml_value );
			delete $cell->{Data};
		}else{# Handle rich text
			@$cell{ qw( cell_xml_value rich_text cell_type ) } = $self->_process_data_element( $cell->{'ss:Data'} );
			delete $cell->{'ss:Data'};
		}
		if( defined $cell->{cell_col} ){
			$current_column = $cell->{cell_col};
		}else{
			$cell->{cell_col} = ++$current_column;
		}
		$cell->{cell_row} = $self->_get_current_row_number;
		$cell->{r} = $self->_build_cell_label( @$cell{qw(cell_col cell_row)} );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:", $cell ] );

		# Handle weird empty Number cells treated as 0
		if( exists $cell->{cell_type} and $cell->{cell_type} eq 'Number' and
			( !$cell->{cell_xml_value} or $cell->{cell_xml_value} eq '' )		){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Identified wierd Excel 2003 xml file format where empty number cells are represented as 0" ] );
				$cell->{cell_unformatted} = 0;
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:", $cell ] );

		# resolve cell_xml_value, and rich text
		#   can't delay this because the information is required for 'empty_is_end'
		# No v-node to collect here.  I don't think shared strings works well or at all in this format
		if( $self->are_spaces_empty and $cell->{cell_xml_value} and $cell->{cell_xml_value} =~ /^\s+$/ ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Clearing spaces only xml value: |$cell->{cell_xml_value}|" ] );
			delete $cell->{cell_xml_value};
		}
		if( $self->get_empty_return_type eq 'empty_string' ){
			$cell->{cell_xml_value} = '' if !exists $cell->{cell_xml_value} or !defined $cell->{cell_xml_value};
		}elsif( !defined $cell->{cell_xml_value} or
				($cell->{cell_xml_value} and length( $cell->{cell_xml_value} ) == 0) ){
			delete $cell->{cell_xml_value};
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:",  $cell] );

		# Handle DateTime cell_type(s)
		if( $cell->{cell_type} eq 'DateTime'){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Transforming:",  $cell->{cell_xml_value} ] );
			my $dt = DateTime::Format::Flexible->parse_datetime( $cell->{cell_xml_value} );
			$cell->{cell_unformatted} = $self->_format_datetime( $dt );
			$cell->{cell_type} = 'Date';
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:",  $cell] );

		# Store merge range if any
		if( exists $cell->{mergeAcross} or exists $cell->{mergeDown} ){
			my $final_column = $cell->{cell_col};
			$final_column += $cell->{mergeAcross} if exists $cell->{mergeAcross};
			my $final_row = $cell->{cell_row};
			$final_row += $cell->{mergeDown} if exists $cell->{mergeDown};
			my $merge_range = $cell->{r} . ':' . $self->_build_cell_label( $final_column, $final_row );
			$cell->{cell_merge} = $merge_range;
			delete $cell->{mergeAcross};
			delete $cell->{mergeDown};
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated cell merge range: $merge_range",	] );
			for my $row ( $cell->{cell_row} .. $final_row ){
				my $row_merge_ref = $self->_get_row_merge_map( $row );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Building on row merge map:", $row_merge_ref	] );
				for my $col ( $cell->{cell_col} .. $final_column ){
					$row_merge_ref->[$col] = $merge_range;
				}
				$self->_set_row_merge_map( $row => $row_merge_ref );
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated merge map:", $self->get_merge_map	] );
			$self->_set_merged_value( $merge_range => $cell );
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated cell:",  $cell] );

		# Handle formula, position translations, and last value
		$last_value_column = $cell->{cell_col};
		push @$alt_ref, $cell;
		$column_to_cell_translations->[$cell->{cell_col}] = $#$alt_ref;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'Saving cell:', $cell, $alt_ref,
		###LogSD		"..with column to cell translations:", $column_to_cell_translations,
		###LogSD		"..and last value column: $last_value_column",	] );
	}

	# Scrub merge cells, column formats, and then empty values
	my $max_column = $new_ref->{row_span}->[1] < $last_value_column ?
						$last_value_column : $new_ref->{row_span}->[1];
	my( $cell_stack, $position_stack );
	my $row_merge_range = $self->_get_row_merge_map( $new_ref->{row_number} );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Full row merge settings:", $row_merge_range ] );
	my $final_column_translations;
	SCRUBINGCELLSTACK: for my $col ( 1 .. $max_column ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing column: $col", ,
		###LogSD		(defined $column_to_cell_translations->[$col] ? $alt_ref->[$column_to_cell_translations->[$col]] : undef)	] );
		my $new_cell;

		# Resolve additional merge info
		if( $row_merge_range and $row_merge_range->[$col] ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Column -$col- is part of a merge range" ] );

			# Handle primary (merged) position sharing
			if( $self->spreading_merged_values and
				(	!defined $column_to_cell_translations->[$col] or
					!exists $alt_ref->[$column_to_cell_translations->[$col]]->{cell_merge} ) ){ # Test for the other (not primary) merged cells
				$new_cell = $self->_get_merged_value( $row_merge_range->[$col] );
				my $row_delta = $new_cell->{cell_row} - $self->_get_current_row_number;
				$new_cell->{cell_row} = $self->_get_current_row_number;
				my $column_delta = $new_cell->{cell_col} - $col;
				$new_cell->{cell_col} = $col;
				$new_cell->{r} = $self->_build_cell_label( $new_cell->{cell_col}, $new_cell->{cell_row} );
				if( exists $new_cell->{cell_formula} and $new_cell->{cell_formula} =~ /R\[?(-?\d*)\]?C\[?(-?\d*)\]?(.*)/ ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Adjusting the RC style formula: ", $new_cell->{cell_formula},
					###LogSD		"..with row_delta: $row_delta", "..and column_delta: $column_delta" ] );
					my $new_formula;
					my @match_list = split /(R)/, $new_cell->{cell_formula};
					for my $section ( @match_list ){
						if( $section =~ /\[?(-?\d*)\]?C\[?(-?\d*)\]?(.*)/g ){
							my $row_offset = ($1//0);
							my $column_offset = ($2//0);
							my $end_string = ($3//'');
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"Managing row offset -$row_offset- column offset -$column_offset- and end string: $end_string" ] );
							$new_formula .= '[' . ($row_offset + $row_delta) . ']' . 'C[' . ($column_offset + $column_delta) . ']' . $end_string;
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"Added row - column offsets with result: $new_formula" ] );
						}else{
							$new_formula .= $section;
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"Added formula string with result: $new_formula" ] );
						}
					}
					$new_cell->{cell_formula} = $new_formula;
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Updated formula: ", $new_cell->{cell_formula} ] );
				}
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"New cell now has: ", $new_cell ] );
			}
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
		###LogSD		"With xml value exists: " . exists $new_cell->{cell_xml_value}, ] );
		if( $self->get_values_only and $new_cell and !exists $new_cell->{cell_xml_value} ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Skipping the empty cell", $new_cell ] );
			next SCRUBINGCELLSTACK;
		}

		# Handle cell type
		if( $new_cell and exists $new_cell->{cell_type} ){
			$new_cell->{cell_type} =~ s/String/Text/;
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
	my( $self, ) = @_;#, $new_file, $old_file
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::NamedWorksheet::load_unique_bits', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Setting the Worksheet unique bits", ] );

	# Read the sheet row-column dimensions
	$self->_set_min_col( 1 );# As far as I can tell xml flat files don't acknowledge start point other than A1
	$self->_set_min_row( 1 );
	my $good_load = 0;
	my $current_named_node = $self->current_named_node;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Currently at named node:", $current_named_node, ] );
	my( $result, $node_name, $node_level, $result_ref );
	if( $current_named_node->{name} eq 'Table' ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"already at the Table node" ] );
		$result = 1;
	}else{
		( $result, $node_name, $node_level, $result_ref ) =
			$self->advance_element_position( 'Table' );
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Advance to 'Table' node arrived at node -" .
		###LogSD		"$node_name- with result: " . ($result//'fail'), ] );
	}
	if( $result ){
		my $Table = $self->current_node_parsed;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed Table value:", $Table ] );
		my $end_column = $Table->{Table}->{'ss:ExpandedColumnCount'};
		my $end_row = $Table->{Table}->{'ss:ExpandedRowCount'};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"End Column: $end_column", "End Row: $end_row" ] );
		my ( $start_column, $start_row ) = ( 1, 1 );
		$self->_set_max_col( $end_column ) if defined $end_column;
		$self->_set_max_row( $end_row ) if defined $end_row;
		$good_load = 1;
	}else{
		$self->_set_min_col( 0 );
		$self->_set_min_row( 0 );
		$self->set_error( "No sheet dimensions provided" );
	}

	#pull column stats
	( $result, $node_name, $node_level, $result_ref ) =
		$self->advance_element_position( 'Column' );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"attempt to get to the Column node arrived at -$node_name- with result: $result" ] );
	my $column_store = [];
	my $current_column = 1;# flat xml files don't always record column sometime they just sequence from the beginning
	while( $node_name eq 'Column' ){
		my $column_settings = $self->squash_node( $self->parse_element );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing:", $column_settings ] );
		my $col_ref;
		map{
			if( defined $column_settings->{$format_translations->{$_}} ){
				$col_ref->{$_} = $column_settings->{$format_translations->{$_}}
			}
		} qw( width customWidth bestFit hidden );
		$col_ref->{bestFit} = !$col_ref->{bestFit};
		delete $col_ref->{bestFit} if !$col_ref->{bestFit};
		$col_ref->{width} = $col_ref->{width} * $width_translation if exists $col_ref->{width};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Updated column ref:", $col_ref ] );
		my $start_column = $column_settings->{'ss:Index'} // $current_column;
		my $end_column = $start_column + (exists( $column_settings->{'ss:Span'} ) ? $column_settings->{'ss:Span'} : 0);
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The column ref applies to columns -$start_column- through -$end_column-" ] );
		for my $col ( $start_column .. $end_column ){
			$column_store->[$col] = $col_ref;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated column store is:", $column_store ] );
		}
		my $result = $self->next_sibling;
		last if !$result;
		$node_name = $self->current_named_node->{name};
		$current_column = $end_column + 1;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Currently at named node: $node_name", ".. it could be column: $current_column" ] );
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Final column store is:", $column_store ] );
	$self->_set_column_formats( $column_store );

	#~ # Get cell merge and row hidden information
	#~ if( $current_named_node->{name} eq 'Row' ){
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"already at the Table node" ] );
	#~ }else{
		#~ $result = $self->advance_element_position( 'Row' );
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"attempt to get to the Table node result: $result" ] );
		#~ $current_named_node = $self->current_named_node;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Currently at named node:", $current_named_node, ] );
	#~ }
	#~ my	$merge_ref = [];
	#~ my	$row_store = [];
	#~ my	$current_row = 1;# flat xml files don't always record row sometime they just sequence from the beginning
	#~ while( $current_named_node->{name} eq 'Row' ){
		#~ my $row_settings = $self->current_node_parsed;
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[ "Processing:", $row_settings ] );
		#~ my $row_ref;
		#~ map{
			#~ if( defined $row_settings->{Row}->{$format_translations->{$_}} ){
				#~ $row_ref->{$_} = $row_settings->{Row}->{$format_translations->{$_}}
			#~ }
		#~ } qw( width customWidth hidden );
		#~ $row_ref->{bestFit} = !$row_ref->{bestFit};
		#~ delete $row_ref->{bestFit} if !$row_ref->{bestFit};
		#~ $row_ref->{width} = $row_ref->{width} * $width_translation if exists $row_ref->{width};
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Updated row ref:", $row_ref ] );
		#~ $current_row = $row_settings->{Row}->{'ss:Index'} // $current_row;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"The row ref applies to row: $current_row" ] );
		#~ $row_store->[$current_row] = $row_ref;
		#~ $result = $self->advance_element_position( 'Cell' );
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"attempt to get to the first Cell node result: $result" ] );
		#~ $current_named_node = $self->current_named_node;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Currently at named node:", $current_named_node, ] );
		#~ my $current_column = 1;
		#~ while( $current_named_node->{name} eq 'Cell' ){
			#~ my $cell_settings = $self->current_node_parsed;
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[ "Processing:", $cell_settings ] );
			#~ my $cell_ref;
			#~ map{
				#~ if( defined $cell_settings->{Cell}->{$format_translations->{$_}} ){
					#~ $cell_ref->{$_} = $cell_settings->{Cell}->{$format_translations->{$_}}
				#~ }
			#~ } qw( hidden mergeAcross mergeDown );
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Updated cell ref:", $cell_ref ] );
			#~ $current_column = $cell_settings->{Cell}->{'ss:Index'} // $current_column;
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"The cell ref applies to column: $current_column" ] );
			#~ if( exists $cell_ref->{mergeAcross} or  exists $cell_ref->{mergeDown} ){
				#~ my $top_left = $self->_build_cell_label( $current_column, $current_row );
				#~ ###LogSD	$phone->talk( level => 'debug', message => [
				#~ ###LogSD		"Top left cell ID: $top_left" ] );
				#~ my	$right_column = $current_column + ($cell_ref->{mergeAcross}//0);
				#~ my	$bottom_row = $current_row + ($cell_ref->{mergeDown}//0);
				#~ my  $bottom_right = $self->_build_cell_label( $right_column, $bottom_row );
				#~ my	$merge_range = "$top_left:$bottom_right";
				#~ ###LogSD	$phone->talk( level => 'debug', message => [
				#~ ###LogSD		"Merge range is: $merge_range" ] );
				#~ for my $row ( $current_row .. $bottom_row ){
					#~ for my $col ( $current_column .. $right_column ){
						#~ $merge_ref->[$row]->[$col] = $merge_range;
					#~ }
				#~ }
				#~ ###LogSD	$phone->talk( level => 'debug', message => [
				#~ ###LogSD		"Updated merge range:", $merge_ref ] );
			#~ }
			#~ my $result = $self->next_sibling;
			#~ $current_named_node = $self->current_named_node;
			#~ $current_column++;
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Currently at named node:", $current_named_node, ".. it could be column: $current_column" ] );
		#~ }
		#~ $current_row++;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		".. or it could be row: $current_row" ] );
	#~ }
	#~ ###LogSD	$phone->talk( level => 'trace', message => [
	#~ ###LogSD		"Final row store is:", $row_store,
	#~ ###LogSD		"Final merge store is:", $merge_ref ] );
	#~ $self->_set_row_formats( $row_store );
	#~ $self->_set_merge_map( $merge_ref );

	#~ # Pull sheet hidden state
	#~ $result = 1;
	#~ if( $current_named_node->{name} eq 'Visible' ){
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"already at the Visible node" ] );
	#~ }else{
		#~ $result = $self->advance_element_position( 'Visible' );
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"attempt to get to the Visible node result: " . ($result//'failed') ] );
		#~ $current_named_node = $self->current_named_node;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Currently at named node:", $current_named_node, ] );
	#~ }
	#~ if( $result ){
		#~ my $visible_node = $self->current_node_parsed;
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		"handling visible node:", $visible_node, ] );
		#~ $self->_set_sheet_hidden( 1 ) if
			#~ exists $visible_node->{Visible} and
			#~ $visible_node->{Visible} eq 'SheetHidden';
	#~ }

	# Record file state
	if( $good_load ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The Worksheet file has metadata" ] );
		$self->good_load( 1 );
	}else{
		$self->set_error( "No 'Worksheet' definition elements found - can't parse this as a Worksheet file" );
		return undef;
	}

	# Set the date parser
	my $system_type = $self->get_epoch_year eq 1904 ? 'apple_excel' : 'win_excel' ;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Setting Excel date type to: $system_type" ] );
	$self->_set_date_parser( DateTimeX::Format::Excel->new( system_type => $system_type ) );

	$self->start_the_file_over;
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Finished the worksheet unique bits" ] );
	return 1;
}

after 'start_the_file_over' => sub{
		my( $self, ) = @_;
		###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
		###LogSD			$self->get_all_space . '::NamedWorksheet::start_the_file_over', );
		###LogSD		$phone->talk( level => 'debug', message => [
		###LogSD			"resetting the current row", ] );
		$self->_set_current_row_number( 0 );
	};

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

has _sheet_min_col =>(
		isa			=> Int,
		writer		=> '_set_min_col',
		reader		=> '_min_col',
		predicate	=> 'has_min_col',
	);

has _current_row_number =>(# Counting from 1
		isa			=> Int,
		writer		=> '_set_current_row_number',
		reader		=> '_get_current_row_number',
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
			_set_row_merge_map => 'set',
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

has _date_parser =>(
		isa		=> 'DateTimeX::Format::Excel',
		writer	=> '_set_date_parser',
		handles	=> { _format_datetime => 'format_datetime' },
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _process_data_element{
	my( $self, $element_ref, $cell_raw_text, $rich_text, $wrapper_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::NamedWorksheet::_process_data_element', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Adding to raw_text: " . ($cell_raw_text//'undef'), '..and rich_text:', $rich_text,
	###LogSD			"..using wrapper ref:", $wrapper_ref, '..with element:', $element_ref ] );

	# Handle cell type
	my $element_type = exists $element_ref->{'ss:Type'} ? $element_ref->{'ss:Type'} : 'Text';
	delete $element_ref->{'ss:Type'};
	###LogSD	$phone->talk( level => 'debug', message =>[ "Cell type is: $element_type" ] );

	# Handle xmlns element
	delete $element_ref->{xmlns};
	###LogSD	$phone->talk( level => 'debug', message =>[ "after xmlns actions - updated element: ", $element_ref ] );

	# Handle Font element
	if( exists $element_ref->{Font} ){
		my $rich_ref;
		for my $setting ( qw( html:Color html:Size ) ){
			$rich_ref->{$rich_text_translations->{$setting}} = $element_ref->{Font}->{$setting} if exists $element_ref->{Font}->{$setting};
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"After adding -$rich_text_translations->{$setting}- for -$setting- result:", $rich_ref, ] );
		}
		if( exists $rich_ref->{rgb} ){
			if( $rich_ref->{rgb} ne '#000000' ){
				$rich_ref->{color}->{rgb} = $rich_ref->{rgb};
				$rich_ref->{color}->{rgb} =~ s/#/FF/;
			}
			delete $rich_ref->{rgb};
		}
		if( keys %$rich_ref ){
			if( @$wrapper_ref ){
				map{ $rich_ref->{$_} = undef } @$wrapper_ref;
			}
			push @$rich_text, length( $cell_raw_text ), $rich_ref,
		}
		$cell_raw_text .= $element_ref->{Font}->{raw_text};
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Updated raw_text -$cell_raw_text- with rich_text:", $rich_text, ] );
		delete $element_ref->{Font};
	}
	###LogSD	$phone->talk( level => 'debug', message =>[ "after font actions - updated element: ", $element_ref ] );

	# Handle list element here
	for my $sub_element ( @{$element_ref->{list}} ){
		$sub_element = { 'Font' => $sub_element };
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Handling list element:", $sub_element ] );
		( $cell_raw_text, $rich_text, ) = $self->_process_data_element( $sub_element, $cell_raw_text, $rich_text, $wrapper_ref );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returned raw_text: $cell_raw_text", $rich_text ] );
	}
	delete $element_ref->{list};
	###LogSD	$phone->talk( level => 'debug', message =>[ "after list actions - updated element: ", $element_ref ] );

	# Handle remaining node(s)
	if( scalar (keys %$element_ref) == 0 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"All done with -$element_type- node raw_text |" . ($cell_raw_text//'') . "|", $rich_text ] );
	}elsif( scalar (keys %$element_ref) == 1 ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Found a wrapper node: " . (keys %$element_ref)[0] ] );
		push @$wrapper_ref, lc((keys %$element_ref)[0]);
		( $cell_raw_text, $rich_text, ) = $self->_process_data_element( $element_ref->{(keys %$element_ref)[0]}, $cell_raw_text, $rich_text, $wrapper_ref );
		pop @$wrapper_ref;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returned raw_text: $cell_raw_text", $rich_text, $wrapper_ref ] );
	}else{
		confess "I found more nodes than expected at this point: " . join( ', ', keys %$element_ref );
	}
	###LogSD	$phone->talk( level => 'debug', message =>[ "Updated element: ", $element_ref ] );

	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Returning raw_text: " . ($cell_raw_text//'undef'), "..of data type: $element_type", '..with rich_text:', $rich_text ] );
	return( $cell_raw_text, $rich_text, $element_type );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::XMLReader::NamedWorksheet - Flat XML Excel worksheet interpreter

=head1 SYNOPSIS

See t\Spreadsheet\Reader\ExcelXML\XMLReader\06-named_worksheet.t

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel
parser.  To use the general package for excel parsing out of the box please review the
documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module incrementally adds functionality to the base class
L<Spreadsheet::Reader::ExcelXML::XMLReader>. The goal is to parse individual worksheet files
(not chartsheets) from the flat XML Excel file format (.xml) into perl objects  The primary
purpose of this role is to normalize functions used by L<Spreadsheet::Reader::ExcelXML::WorksheetToRow>
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

"_build_cell_label" in L<Spreadsheet::Reader::ExcelXML::CellToColumnRow
|Spreadsheet::Reader::ExcelXML::CellToColumnRow/build_cell_label( $column, $row, )>

L<Spreadsheet::Reader::ExcelXML::Workbook/get_epoch_year>

L<Spreadsheet::Reader::ExcelXML::Workbook/spreading_merged_values>

L<Spreadsheet::Reader::ExcelXML::Workbook/should_skip_hidden>

L<Spreadsheet::Reader::ExcelXML::Workbook/are_spaces_empty>

L<Spreadsheet::Reader::ExcelXML::Workbook/get_empty_return_type>

L<Spreadsheet::Reader::ExcelXML::Workbook/get_values_only>

=back

=head2 Attributes

Data passed to new when creating an instance.  This list only contains public attributes
incrementally provided by this role.  For access to the values in these attributes see
the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the
L<Methods|/Methods>.

=head3 is_hidden

=over

B<Definition:> This data is collected at the worksheet level for this file type.  It indicates
if the sheet is human visible.  Since the data is collected during the implementation of
load_unique_bits it will always overwrite what is passed from the Workbook.

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
