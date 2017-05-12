package Spreadsheet::XLSX::Reader::LibXML::WorksheetToRow;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::WorksheetToRow-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
	is_empty_the_end				start_the_file_over				advance_element_position
	location_status					get_attribute_hash_ref			parse_element
	has_shared_strings_interface	get_shared_string				get_empty_return_type
	get_values_only					_starts_at_the_edge				grep_node
	set_error						_min_col						_max_col
	_min_row						_max_row						_get_column_formats
	_get_merge_map					_load_unique_bits				_go_to_or_past_row
	_get_custom_column_data
);# 
use Clone 'clone';
use Carp qw( confess );
use Types::Standard qw(
		HasMethods		InstanceOf		ArrayRef		Maybe
		Bool			Int				is_HashRef		is_Int
		is_ArrayRef
    );
use MooseX::ShortCut::BuildInstance qw ( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use lib	'../../../../../../lib';
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
use Spreadsheet::XLSX::Reader::LibXML::Row;
use Data::Dumper;
#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has is_hidden =>(
		isa		=> Bool,
		reader	=> 'is_sheet_hidden',
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9



#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _get_col_row{
	my( $self, $target_col, $target_row ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_get_col_row', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Reached _get_col_row",
	###LogSD			( $target_row ? "Requesting target row and column: [ $target_row, $target_col ]" : '' ),
	###LogSD			( $self->_has_new_row_inst ? ("..and stored current row: " . $self->_get_new_row_number) : '') ] );
	
	# Get the raw elements (as available)
	my $cell_ref = $self->_get_specific_position( $target_row, $target_col );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"The cell ref after pulling column -$target_col-", $cell_ref, ] );
	if( $cell_ref ){
		if( !$cell_ref or $cell_ref eq 'EOR' ){
			###LogSD	no warnings 'uninitialized';
			###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Cell ref is EOR or undef - checking that is is also not EOF with the last 10 known row positions: " . 
			###LogSD		join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
			###LogSD	no warnings 'uninitialized';
			# Check if EOR equals EOF
			my $valid_test = 0;
			if( $self->has_max_row and $self->_max_row == $target_row ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"This is the last row - and therefore EOF" ] );
					$cell_ref = 'EOF';
					$valid_test = 1;
			}elsif( $self->_max_row_position_recorded - 1 >= $target_row + 1 ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"At least one more row has been previewed - checking to see if it has values" ] );
				my $row_positions = $self->_get_all_positions;
				my $test_position = $target_row + 1;
				for my $position ( @$row_positions[ $test_position .. $#$row_positions ] ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"Checking if the position -$test_position- has a row defined: " . ($position//'undef') ] );
					if( defined $position ){
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"Positing -$test_position- is defined - this is not an EOF" ] );
						$valid_test = 1;
						last;
					}
					$test_position++;
				}
			}
			if( !$valid_test ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Unable to know the EOF state from stored data - processing additional rows" ] );
				my $index_result = $self->_go_to_or_past_row( $target_row + 1 );
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Returned from advancing rows with: $index_result" ] );
				if( $index_result ){
					if( $self->is_empty_the_end ){
						###LogSD	$phone->talk( level => 'debug', message => [
						###LogSD		"Empty is the end - Just check for EOF" ] );
						if( $index_result eq 'EOF' ){
							$cell_ref = 'EOF';
						}
					}else{
						if( $self->_max_col >= $target_col ){
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"There may be nothing else of value but we are not at the end of the emptys" ] );
							$cell_ref = undef;
						}else{
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"This really is the end of the row - check for EOF" ] );
							if( $index_result eq 'EOF' ){
								$cell_ref = 'EOF';
							}
						}
					}
				}
			}
		}
		if( $cell_ref and $cell_ref eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The cell ref is EOF!" ] );
			$self->_clear_new_row_inst;
			$self->start_the_file_over;
		}
	}
	my $updated_cell = 
		!$cell_ref ? undef :
		is_HashRef( $cell_ref ) ?  $self->_complete_cell( $cell_ref ) : $cell_ref;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'returning ref:', $updated_cell,] );
	return $updated_cell;
}
	
sub _get_next_value_cell{
	my( $self, ) = @_; # to fast forward use _get_col_row
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_get_next_value_cell', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Reached _get_next_value_cell",
	###LogSD			( $self->_has_new_row_inst ? ("With current stored new row: " . $self->_get_new_row_number) : '') ] );

	# Attempt to pull the data from stored values or index the row forward
	my	$index_result = 'NoParse';
	my	$cell_ref;
	my	$first_pass = 1;
	while( !$cell_ref ){
		if( !$self->_has_new_row_inst ){
			if( $first_pass ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Probably the first time through at the beginning of the sheet" ] );
				$self->start_the_file_over;
				my $first_data_row = 1;
				if( ($self->_max_row_position_recorded - 1) > 0 ){
					###LogSD	$phone->talk( level => 'debug', message => [
					###LogSD		"The sheet has been processed before - find the first data row" ] );
					my $found_it = 0;
					while( !$found_it ){
						if( defined $self->_get_row_position( $first_data_row ) ){
							###LogSD	$phone->talk( level => 'debug', message => [
							###LogSD		"Row number -$first_data_row- has data" ] );
							$found_it = 1;
						}else{
							$first_data_row++;
						}
					}
				}
				$index_result = $self->_go_to_or_past_row( $first_data_row );
			}else{
				###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Likely some bad row bound / EOF / empty last row condition found with last 10 positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				$self->start_the_file_over;
				return 'EOF';
			}
		}else{
			$cell_ref = $self->_get_new_next_value;
			my $current_row = $self->_get_new_row_number;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"For row -$current_row- the next cell is:", $cell_ref ] );
			if( $cell_ref eq 'EOR' ){
				$current_row++;
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Reached the end of the row - starting over at row: $current_row" ] );
				if( !$self->has_max_row or $current_row <= $self->_max_row ){
					$index_result = $self->_go_to_or_past_row( $current_row );
					$cell_ref = undef;
				}else{
					$self->_clear_new_row_inst;
					$self->start_the_file_over;
					return 'EOF';
				}
			}
		}
		$first_pass = 0;
		if( !$cell_ref and $index_result eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Returning: $index_result" ] );
			return $index_result;
		}
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'The cell ref after parsing through the rows:', $cell_ref, ] );
	
	my $updated_cell = $self->_complete_cell( $cell_ref );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'returning ref:', $updated_cell,] );
	return $updated_cell;
}

sub _get_row_all{
	my( $self, $target_row ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_get_row_all', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Reached _get_row_all",
	###LogSD			( $target_row ? "Requesting target row: $target_row" : '' ),
	###LogSD			( $self->_has_new_row_inst ? ("..and stored current row: " . $self->_get_new_row_number) : '') ] );
	
	# Get the raw elements (as available)
	my $row_ref = $self->_get_specific_position( $target_row, );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"The row ref is:", $row_ref, ] );
	my $updated_row = [];
	if( is_ArrayRef( $row_ref ) ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"There are cells to process:", $row_ref ] );
		for my $cell_ref ( @$row_ref ){
				###LogSD	$phone->talk( level => 'trace', message => [
				###LogSD		"Processing cell:", $cell_ref ] );
			push @$updated_row, $cell_ref ? $self->_complete_cell( $cell_ref ) : $cell_ref ;
		}
	}else{
		$updated_row = $row_ref;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		'returning row ref:', $updated_row,] );
	return $updated_row;
}

sub _complete_cell{
	my( $self, $cell_ref ) = @_;#, $new_file, $old_file
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_complete_cell', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"adding worksheet data to the cell:", $cell_ref ] );
		
	#Add merge value
	my $merge_row = $self->_get_row_merge_map( $cell_ref->{cell_row} );
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Row merge map:", $merge_row,	] );
	if( ref( $merge_row ) and $merge_row->[$cell_ref->{cell_col}] ){
		$cell_ref->{cell_merge} = $merge_row->[$cell_ref->{cell_col}];
	}
	
	# Check for hiddenness (This logic needs a deep rewrite when adding the skip_hidden attribute to the workbook)
	if( $self->is_sheet_hidden ){
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'This cell is from a hidden sheet',] );
		$cell_ref->{cell_hidden} = 'sheet';
	}else{
		my $column_attributes = $self->_get_custom_column_data( $cell_ref->{cell_col} );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"Column -$cell_ref->{cell_col}- has attributes:", $column_attributes, ] );
		if( $column_attributes and $column_attributes->{hidden} ){
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		'This cell is from a hidden column',] );
			$cell_ref->{cell_hidden} = 'column';
		}
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		'Ref to this point:', $cell_ref,] );
	return $cell_ref;
}

sub _get_specific_position{
	my( $self, $target_row, $target_col ) = @_;
	my $current_row = $self->_has_new_row_inst ? $self->_get_new_row_number : 0;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_get_specific_position', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Seeking elements of row: $target_row",
	###LogSD			( defined $target_col ? "..with the intent to extract column: $target_col" : undef) ] );
	
	# Look for the row and then the cell
	my ( $row_found, $advance_result );
	while( !$row_found ){
		
		# Check for the 'EOF' conditions
		if( $advance_result and $advance_result eq 'EOF'){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Returning EOF after arriving at the end of the file" ] );
			return 'EOF';
		}elsif( $self->has_max_row ){
			if( $target_row > $self->_max_row ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Returning EOF because max row less than target row" ] );
				return 'EOF';
			}elsif( defined $target_col and $self->has_max_col and $target_row == $self->_max_row and $target_col > $self->_max_col ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Returning EOF because max row equal to target row and max col less than requested column" ] );
				return 'EOF';
			}
		}
		
		# See if the currently stored row is the desired row (or if we know the row is empty)
		if( $self->_has_new_row_inst ){
			my $stored_row = $self->_has_new_row_inst ? $self->_get_new_row_number : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Checking if the requested row -$target_row- matches the stored row: " . ($stored_row//'undef'), ] );
			if( defined $stored_row and $stored_row == $target_row ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		'The value might be in the latest row pulled' ] );
				$row_found = 1;# Currently stored row is the one we want
			}
		}
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The current row found state: " . ($row_found//'undef'),
		###LogSD		"The current max positions recorded: " . ($self->_max_row_position_recorded - 1),
		###LogSD		"..against target_row: $target_row" ] );
		if( !$row_found and ($self->_max_row_position_recorded - 1) >= $target_row ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The desired row has already been read - check if it is empty: " ] );
			my $row_position = $self->_get_row_position( $target_row );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The desired row is at position: " . ($row_position//'undef') ] );
			if( !defined $row_position ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"I already know this is an empty row" ] );
				$row_found = 2;# Empty Row
			}else{
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Need to index to and then read row -$target_row- at position: $row_position" ] );
			}
		}
		
		# Look deeper as needed
		if( !$row_found ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Need index the currently read row forward to read the target row: $target_row" ] );
			$advance_result = $self->_go_to_or_past_row( $target_row );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Result of the index is: $advance_result" ] );
			if( $advance_result and $advance_result eq 'EOF' ){
				###LogSD	$phone->talk( level => 'debug', message => [
				###LogSD		"Setting the return ref to: EOF" ] );
				$row_found = 3;# EOF condition
			}
		}
		
	}
	
	# Handle unknown $row_found
	if( $row_found > 3 or $row_found < 1 ){
		confess "Unknown row_found value: $row_found";
	}
	
	# Return EOF as known
	if( $row_found == 3 ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Returning EOF" ] );
		return 'EOF';
	}
	
	# If the whole row is needed return that
	if( !defined $target_col ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Prepping to return the row type: " . ( $row_found == 1 ? 'ArrayRef' : $row_found == 2 ? 'Empty ArrayRef' : 'EOF' ) ] );
		my $row_list = $row_found == 1 ? $self->_get_new_row_list : [];
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Returning the row list:", $row_list ] );
		return $row_list;
	}
	
	# Return the correct cell value
	my $cell_ref;
	if( $row_found == 1 ){# Handle current row return
		if( $target_col > $self->_get_new_last_value_col ){
			$cell_ref = ($self->is_empty_the_end or $self->_get_new_row_end < $target_col) ? 'EOR' : undef;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"The requested cell is past the end of the data in this row: " . ($cell_ref//'undef') ] );
		}else{
			$cell_ref = $self->_get_new_column( $target_col );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Pulling cell data from the stored row:", $cell_ref ] );
		}
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Determining how to represent a value from an empty row:", $cell_ref, $self->has_max_col, $self->_max_col, $target_col] );
		$cell_ref = $self->is_empty_the_end ? 'EOR' : ($self->_max_col < $target_col) ? 'EOR' : undef;
	}
	
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		'Returning:', $cell_ref ] );
	return $cell_ref;
}

sub _is_column_hidden{
	my( $self, @column_requests ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::is_column_hidden::subsub', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Pulling the hidden state for the columns:', @column_requests ] );
	
	my @tru_dat;
	for my $column ( @column_requests ){
		my $column_format = $self->_get_custom_column_data( $column );
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Column formats for column -$column- are:", $column_format ] );
		push @tru_dat, (( $column_format and $column_format->{hidden} ) ? 1 : 0);
	}
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Final column hidden state is list:", @tru_dat] );
	return @tru_dat;
}

#~ sub _go_to_or_past_row{
	#~ my( $self, $target_row ) = @_;
	#~ my $current_row = $self->_has_new_row_inst ? $self->_get_new_row_number : 0;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD			$self->get_all_space . '::WorksheetToRow::_go_to_or_past_row', );
	#~ ###LogSD		$phone->talk( level => 'info', message => [
	#~ ###LogSD			"Indexing the row forward to find row: $target_row", "From current row: $current_row" ] );
	
	#~ # Handle a call where we are already at the required location
	#~ if( $self->_has_new_row_inst and defined $target_row and $self->_get_new_row_number == $target_row ){
		#~ ###LogSD	$phone->talk( level => 'info', message => [
		#~ ###LogSD		'Asked for a row that has already been built and loaded' ] );
		#~ return $target_row;
	#~ }
	
	#~ # processes through the unwanted known positions quickly
	#~ my $current_position;
	#~ my $row_attributes;
	#~ my $attribute_ref;
	#~ if( $self->_max_row_position_recorded ){
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		'The sheet has recorded some rows' ] );
		#~ my ( $fast_forward, $test_position );
		#~ my $test_target = $target_row;
		
		#~ # Look forward for fast forward goal
		#~ ###LogSD	no warnings 'uninitialized';
		#~ while( !defined $test_position and $test_target < ($self->_max_row_position_recorded - 1) ){
			#~ $test_position = $self->_get_row_position( $test_target );
			#~ ###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
			#~ ###LogSD	$phone->talk( level => 'trace', message => [
			#~ ###LogSD		"Checking for a defined row position for row: $test_target",
			#~ ###LogSD		".. with position result: " . ($test_position//'undef'),
			#~ ###LogSD		".. with max known column -$max_positions- and the last 10 detailed positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
			#~ $test_target++;
		#~ }
		#~ ###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		'After looking at and forward of the target row the test position is: ' . $test_position,
		#~ ###LogSD		"..and last 10 known columns: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] ) if defined $test_position;
		
		#~ # Look backward for fast forward goal
		#~ $test_target = $target_row < ($self->_max_row_position_recorded - 1) ? $target_row : -1;
		#~ while( !defined $test_position and $test_target < ($self->_max_row_position_recorded - 1) ){
			#~ ###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
			#~ ###LogSD	$phone->talk( level => 'trace', message => [
			#~ ###LogSD		"Checking for a defined row position for row: $test_target",
			#~ ###LogSD		".. with position result: " . ($test_position//'undef'),
			#~ ###LogSD		".. against the last 10 positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] )  ] );
			#~ $test_position = $self->_get_row_position( $test_target );
			#~ $test_target--;
		#~ }
		#~ ###LogSD	$max_positions = $self->_max_row_position_recorded - 1;
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		'After looking backward from the the target row the test position is: ' . ($test_position//'undef'),
		#~ ###LogSD		".. against the last 10 positions: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
		#~ ###LogSD	use warnings 'uninitialized';
		
		#~ # Pull the current position
		#~ $current_position	= $current_row ? $self->_get_row_position( $current_row ) : 0;
		#~ $fast_forward		= $current_position ? $test_position - $current_position : $test_position;
		#~ @$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Checking if a speed index can be done between position: " . ($current_position//'undef'),
		#~ ###LogSD		"..for last recorded row: " . ($current_row),
		#~ ###LogSD		"..to target position: $test_position",
		#~ ###LogSD		"..with proposed increment: $fast_forward",
		#~ ###LogSD		"..node name: $attribute_ref->{node_name}", "..node type: $attribute_ref->{node_type}",
		#~ ###LogSD		"..node depth: $attribute_ref->{node_depth}", ] );
		#~ if( $fast_forward < 0 or ($attribute_ref->{node_depth} == 0 and $attribute_ref->{node_name} eq 'EOF') ){
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Looking for a row that is earlier than the current position" ] );
			#~ $self->start_the_file_over;
			#~ $fast_forward	= $test_position - 1;
			#~ $current_row	= 0;
			#~ $self->advance_element_position( 'row', ) ;
		#~ }
		
		#~ if( $fast_forward > 1 ){# Since you quit at the beginning of the next node
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Fast forwarding -$fast_forward- times", ] );
			#~ $self->advance_element_position( 'row', $fast_forward - 1 ) ;
			#~ @$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
			#~ $row_attributes		= $self->get_attribute_hash_ref;
			#~ $current_row		= $row_attributes->{r};
			#~ $attribute_ref->{attribute_hash} = $row_attributes;
			#~ $current_position	= $test_position;
		#~ }
	#~ }
	#~ $self->_clear_new_row_inst;# We are not in Kansas anymore
	
	#~ # move forward into the unknown (slower, in order to record steps)
	#~ my $count = 0;
	#~ while( defined $current_row and $target_row > $current_row ){
		#~ @$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		#~ ###LogSD	$phone->talk( level => 'info', message => [
		#~ ###LogSD		"Reading the next row",
		#~ ###LogSD		"..from XML file position:", $attribute_ref, "..at current position: " . ($current_position//'undef')  ] );
		
		#~ # find a row node if you don't have one
		#~ my $result = 1;
		#~ if( $attribute_ref->{node_name} ne 'row' ){
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Attempting to advanced to a row node from a non row node"  ] );
			#~ $result = $self->advance_element_position( 'row' );
			#~ @$attribute_ref{qw( node_depth node_name node_type )} = $self->location_status;
		#~ }
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Current location result: $result", $attribute_ref  ] );
		#~ # Check for EOF node
		#~ if( $attribute_ref->{node_name} eq 'EOF' ){
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Returning EOF"  ] );
			#~ $self->_set_max_row_state;
			#~ return 'EOF';
		#~ }
		
		#~ # Process the node advance
		#~ if( $result ){
			#~ # Get the location from the current row attributes
			#~ $row_attributes = $self->get_attribute_hash_ref;
			#~ $current_row	= $row_attributes->{r};
			#~ if( !defined $row_attributes->{r} ){
				#~ confess "arrived at a row node with no row number: " . Dumper( $row_attributes );
			#~ }
			#~ $current_position = defined $current_position ? $current_position + 1 : 0;
			#~ ###LogSD	$phone->talk( level => 'trace', message => [
			#~ ###LogSD		"Currently at row: $current_row",
			#~ ###LogSD		"..and current position: $current_position", ] );
			#~ if( $current_row > ($self->_max_row_position_recorded - 1) ){
				#~ ###LogSD	no warnings 'uninitialized';
				#~ ###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
				#~ ###LogSD	$phone->talk( level => 'trace', message => [
				#~ ###LogSD		"The current last 10 positions from row -$current_row- of the hidden row ref: " . join( ', ', @{$self->_get_all_hidden}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				#~ $self->_set_row_hidden( $current_row => (exists $row_attributes->{hidden} ? 1 : 0) );
				#~ ###LogSD	$phone->talk( level => 'trace', message => [
				#~ ###LogSD		"The updated last 10 positions from row -$current_row- of the hidden row ref: " . join( ', ', @{$self->_get_all_hidden}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ),
				#~ ###LogSD		"..with the current last 10 positions of the updated position row ref: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				#~ $self->_set_row_position( $current_row => $current_position );
				#~ ###LogSD	$max_positions = $self->_max_row_position_recorded - 1;
				#~ ###LogSD	$phone->talk( level => 'trace', message => [
				#~ ###LogSD		"The position row ref max row is: $max_positions",
				#~ ###LogSD		"..with the updated last 10 positions of the updated position row ref: " . join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
				#~ ###LogSD	use warnings 'uninitialized';
			#~ }
			#~ $attribute_ref->{attribute_hash} = $row_attributes;
		#~ }else{
			#~ ###LogSD	$phone->talk( level => 'trace', message => [
			#~ ###LogSD		"Couldn't find another value row -> this is an unexpected end of file" ] );
			#~ $self->_set_max_row_state;
			#~ return 'EOF';
		#~ }
		#~ $count++;
	#~ }
	
	#~ # Collect the details of the final row position
	#~ my $row_ref = $self->parse_element( undef, $attribute_ref );
	#~ $row_ref->{list} = exists $row_ref->{list} ? $row_ref->{list} : [];
	#~ ###LogSD	$phone->talk( level => 'trace', message => [#ask => 1, 
	#~ ###LogSD		'Result of row read:', $row_ref ] );
	
	#~ # Load text values for each cell where appropriate
	#~ my ( $alt_ref, $column_to_cell_translations, $reported_column, $reported_position, $last_value_column );
	#~ my $x = 0;
	#~ for my $cell ( @{$row_ref->{list}} ){
		#~ ###LogSD	$phone->talk( level => 'info', message => [
		#~ ###LogSD		'Processing cell:', $cell	] );
		
		#~ $cell->{cell_type} = 'Text';
		#~ my $v_node = $self->grep_node( $cell, 'v' );##########################################  Start figuring how this affects styles collection next
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		"v node is:",  $v_node] );
		#~ if( exists $cell->{attributes}->{t} ){
			#~ if( $cell->{attributes}->{t} eq 's' ){
				#~ ###LogSD	$phone->talk( level => 'debug', message =>[
				#~ ###LogSD		"Identified potentially required shared string for cell:",  $cell] );
				#~ my $position = ( $self->has_shared_strings_interface ) ?
						#~ $self->get_shared_string( $v_node->{raw_text} ) : $v_node->{raw_text};
				#~ ###LogSD	$phone->talk( level => 'debug', message =>[
				#~ ###LogSD		"Shared strings resolved to:",  $position] );
				#~ if( is_HashRef( $position ) ){
					#~ @$cell{qw( cell_xml_value rich_text )} = ( $position->{raw_text}, $position->{rich_text} );
					#~ delete $cell->{rich_text} if !$cell->{rich_text};
				#~ }else{
					#~ $cell->{cell_xml_value} = $position;
				#~ }
			#~ }elsif( $cell->{attributes}->{t} =~ /^(str|e)$/ ){
				#~ ###LogSD	$phone->talk( level => 'debug', message =>[
				#~ ###LogSD		"Identified a stored string in the worksheet file: " . ($v_node//'')] );
				#~ $cell->{cell_xml_value} = $v_node->{raw_text};
			#~ }else{
				#~ confess "Unknown 't' attribute set for the cell: $cell->{attributes}->{t}";
			#~ }
			#~ delete $cell->{attributes}->{t};
		#~ }elsif( $v_node ){
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[
			#~ ###LogSD		"Setting cell_xml_value from: $v_node->{raw_text}", ] );
			#~ $cell->{cell_xml_value} = $v_node->{raw_text};
			#~ $cell->{cell_type} = 'Numeric' if $cell->{cell_xml_value} and $cell->{cell_xml_value} ne '';
		#~ }
		#~ if( $self->get_empty_return_type eq 'empty_string' ){
			#~ $cell->{cell_xml_value} = '' if !exists $cell->{cell_xml_value} or !defined $cell->{cell_xml_value};
		#~ }elsif( !defined $cell->{cell_xml_value} or
				#~ ($cell->{cell_xml_value} and length( $cell->{cell_xml_value} ) == 0) ){
			#~ delete $cell->{cell_xml_value};
		#~ }
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		"Updated cell:",  $cell] );
		
		#~ # Clear empty cells if required
		#~ if( $self->get_values_only and ( !defined $cell->{cell_xml_value} or length( $cell->{cell_xml_value} ) == 0 ) ){
				#~ ###LogSD	$phone->talk( level => 'info', message => [
				#~ ###LogSD		'Values only called - stripping this non-value cell'	] );
		#~ }else{
			#~ $cell->{cell_type} = 'Text' if !exists $cell->{cell_type};
			#~ $cell->{cell_hidden} = 'row' if $row_ref->{attributes}->{hidden};
			#~ @$cell{qw( cell_col cell_row )} = $self->_parse_column_row( $cell->{attributes}->{r} );
			#~ $cell->{r} = $cell->{attributes}->{r};
			#~ $cell->{s} = $cell->{attributes}->{s} if exists $cell->{attributes}->{s};
			#~ delete $cell->{attributes}->{r};
			#~ $last_value_column = $cell->{cell_col};
			#~ my $formula_node = $self->grep_node( $cell, 'f' );
			#~ $cell->{cell_formula} = $formula_node->{raw_text} if $formula_node;
			#~ $column_to_cell_translations->[$cell->{cell_col}] = $x++;
			#~ $reported_column = $cell->{cell_col} if !defined $reported_column;
			#~ $reported_position = 0;
			#~ delete $cell->{attributes};
			#~ delete $cell->{list};
			#~ delete $cell->{list_keys};
			#~ ###LogSD	$phone->talk( level => 'info', message => [
			#~ ###LogSD		'Saving cell:', $cell	] );
			#~ push @$alt_ref, $cell;
		#~ }
	#~ }
	
	#~ #Load the row instance
	#~ my $new_ref;
	#~ ###LogSD	$phone->talk( level => 'trace', message =>[
	#~ ###LogSD		"Row ref:", $row_ref, ] );
	#~ if( defined $row_ref->{attributes}->{r} ){
		#~ $new_ref->{row_number} = $row_ref->{attributes}->{r};
		#~ delete $row_ref->{attributes}->{r};
		#~ delete $row_ref->{list};
		#~ delete $row_ref->{list_keys};
		#~ delete $row_ref->{attributes}->{hidden};
		#~ if( $alt_ref ){
			#~ ###LogSD	$phone->talk( level => 'trace', message =>[
			#~ ###LogSD		"Alt ref:", $alt_ref, "updated row ref:", $row_ref, "new ref:", $new_ref,] );
			#~ $new_ref->{row_value_cells}	= $alt_ref;
			#~ $new_ref->{row_span} = $row_ref->{attributes}->{spans} ? [split /:/, $row_ref->{attributes}->{spans}] : [ undef, undef ];
			#~ $new_ref->{row_last_value_column} = $last_value_column;
			#~ $new_ref->{column_to_cell_translations}	= $column_to_cell_translations;
			#~ $new_ref->{row_span}->[0] //= $new_ref->{row_value_cells}->[0]->{cell_col};
			#~ ###LogSD	$phone->talk( level => 'trace', message =>[
			#~ ###LogSD		"adjusted new ref:", $new_ref,] );
			#~ if( !$self->has_max_col or $self->_max_col < $new_ref->{row_value_cells}->[-1]->{cell_col} ){
				#~ ###LogSD	$phone->talk( level => 'trace', message =>[
				#~ ###LogSD		"From known cells setting the max column to: $new_ref->{row_value_cells}->[-1]->{cell_col}" ] );
				#~ $self->_set_max_col( $new_ref->{row_value_cells}->[-1]->{cell_col} );
			#~ }
			#~ if( defined $new_ref->{row_span}->[1] and $self->_max_col < $new_ref->{row_span}->[1] ){
				#~ ###LogSD	$phone->talk( level => 'trace', message =>[
				#~ ###LogSD		"From the row span setting the max column to:  $new_ref->{row_span}->[1]" ] );
				#~ $self->_set_max_col(  $new_ref->{row_span}->[1] );
			#~ }else{
				#~ $new_ref->{row_span}->[1] //= $self->_max_col;
			#~ }
		#~ }else{
			#~ ###LogSD	$phone->talk( level => 'trace', message =>[
			#~ ###LogSD		" No row list (with values?) found" ] );
			#~ $new_ref->{row_span} = [ 0, 0 ];
			#~ $new_ref->{row_last_value_column} = 0;
			#~ $new_ref->{column_to_cell_translations}	= [];
		#~ }
		#~ delete $row_ref->{attributes}->{spans};# Delete just attributes here?
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		"Row formats:", $row_ref,
		#~ ###LogSD		"Row attributes:", $new_ref, ] );
		#~ my 	$row_node_ref =	build_instance( 
				#~ package 		=> 'RowInstance',
				#~ superclasses	=> [ 'Spreadsheet::XLSX::Reader::LibXML::Row' ],
				#~ row_formats		=> $row_ref,
				#~ %$new_ref,
		#~ ###LogSD	log_space 	=> $self->get_log_space
			#~ );
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		"New row instance:", $row_node_ref, ] );
		#~ $self->_set_new_row_inst( $row_node_ref );
	#~ }else{
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		"line 706 - No row number found - must be EOF", ] );
		#~ return 'EOF';
	#~ }
	
	#~ if( !$alt_ref ){
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		'Nothing to see here - move along', ] );
		#~ ###LogSD	no warnings 'uninitialized';
		#~ my $result = $current_row + 1;
		#~ if( is_Int( $current_row ) ){
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[
			#~ ###LogSD	"Going on to the next row: " . ($current_row +1), ] );
			#~ no warnings 'recursion';
			#~ $result = $self->_go_to_or_past_row( $current_row + 1 );# Recursive call for empty rows
			#~ use warnings 'recursion';
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[
			#~ ###LogSD	"Returned from the next row with: " . ($result//'undef'),
			#~ ###LogSD	"..target current row is: " . ($current_row +1), ] );
			#~ $self->_set_row_position( $current_row => undef );# Clean up phantom placeholder
			#~ my $max_positions = $self->_max_row_position_recorded - 1;
			#~ ###LogSD	$phone->talk( level => 'debug', message =>[
			#~ ###LogSD	"The last 10 position ref values are: " .
			#~ ###LogSD	join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ), ] );
		#~ }
		#~ $current_row = $result;
		#~ ###LogSD	my $max_positions = $self->_max_row_position_recorded - 1;
		#~ ###LogSD	$phone->talk( level => 'debug', message =>[
		#~ ###LogSD		'Updated current row -$current_row- pdated last 10 row positions are: ' . 
		#~ ###LogSD		join( ', ', @{$self->_get_all_positions}[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
		#~ ###LogSD	use warnings 'uninitialized';
	#~ }
	#~ $self->_set_max_row_state if $current_row and $current_row eq 'EOF';
	#~ ###LogSD	$phone->talk( level => 'debug', message =>[
	#~ ###LogSD		"Returning: ", $current_row ] );
	#~ return $current_row;
#~ }

#~ sub _set_max_row_state{
	#~ my( $self, ) = @_;
	#~ my $row_position_ref = $self->_get_all_positions;
	#~ my $max_positions = $#$row_position_ref;
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD			$self->get_all_space . '::WorksheetToRow::_go_to_or_past_row::_set_max_row_state', );
	#~ ###LogSD	no warnings 'uninitialized';
	#~ ###LogSD		$phone->talk( level => 'debug', message => [
	#~ ###LogSD			"The current max row is: " . ($self->has_max_row ? $self->_max_row : 'undef'),
	#~ ###LogSD			"Setting the max row from the last 10 positions of the row position ref:" . join( ', ', @$row_position_ref[( $max_positions > 10 ? $max_positions - 10 : 0 ) .. $max_positions] ) ] );
	#~ ###LogSD	use warnings 'uninitialized';
	#~ if( $self->is_empty_the_end ){
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Clearing empty rows from the end" ] );
		#~ my $last_position;
		#~ while( !defined $last_position ){
			#~ $last_position = $self->_remove_last_row_position;
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Removed the last row position value: " . ($last_position//'undef'),
			#~ ###LogSD		"..from position: " . $self->_max_row_position_recorded ] );
		#~ }
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Reload the final poped value: " . $self->_max_row_position_recorded . ' => ' . $last_position ] );
		#~ $self->_set_row_position( $self->_max_row_position_recorded => $last_position );
	#~ }
	#~ my $last_row = $self->_max_row_position_recorded - 1;
	#~ ###LogSD	$phone->talk( level => 'debug', message => [
	#~ ###LogSD		"Setting the max row to: $last_row" ] );
	#~ $self->_clear_new_row_inst;
	#~ $self->start_the_file_over;
	#~ $self->_set_max_row( $last_row );
	#~ return $last_row;
#~ }

#~ sub _load_unique_bits{################################################################# Maybe this works better as two roles? (XML vs Zip style)
	#~ my( $self, ) = @_;#, $new_file, $old_file
	#~ ###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	#~ ###LogSD			$self->get_all_space . '::WorksheetToRow::_load_unique_bits', );
	#~ ###LogSD		$phone->talk( level => 'debug', message => [
	#~ ###LogSD			"Setting the Worksheet unique bits", ] );
	
	#~ # Read the sheet dimensions
	#~ my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	#~ if( $node_name eq 'dimension' or $self->advance_element_position( 'dimension' ) ){
		#~ my $dimension = $self->parse_element;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"parsed dimension value:", $dimension ] );
		#~ my	( $start, $end ) = split( /:/, $dimension->{attributes}->{ref} );
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Start position: $start", 
		#~ ###LogSD		( $end ? "End position: $end" : '' ), ] );
		#~ my ( $start_column, $start_row ) = ( $self->_starts_at_the_edge ) ?
												#~ ( 1, 1 ) : $self->_parse_column_row( $start );
		#~ my ( $end_column, $end_row	) = $end ? 
				#~ $self->_parse_column_row( $end ) : 
				#~ ( undef, undef ) ;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		'Start column: ' . ($start_column//'undef'), 'Start row: ' . ($start_row//'undef'),
		#~ ###LogSD		'End column: ' . ($end_column//'undef'), 'End row: ' . ($end_row//'undef') ] );
		#~ $self->_set_min_col( $start_column );
		#~ $self->_set_min_row( $start_row );
		#~ $self->_set_max_col( $end_column ) if defined $end_column;
		#~ $self->_set_max_row( $end_row ) if defined $end_row;
	#~ }else{
		#~ $self->_set_min_col( 0 );
		#~ $self->_set_min_row( 0 );
		#~ $self->set_error( "No sheet dimensions provided" );
	#~ }
	
	#~ #pull column stats
	#~ my	$has_column_data = 1;
	#~ ( $node_depth, $node_name, $node_type ) = $self->location_status;
	#~ ###LogSD	$phone->talk( level => 'debug', message => [
	#~ ###LogSD		"Loading the column configuration" ] );
	#~ if( $node_name eq 'cols' or $self->advance_element_position( 'cols') ){
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Already arrived at the column data" ] );
	#~ }else{
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Restart the sheet to find the column data" ] );
		#~ $self->start_the_file_over;
		#~ $has_column_data = $self->advance_element_position( 'cols' );
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Column data search result: $has_column_data" ] );
	#~ }
	#~ if( $has_column_data ){
		#~ my $column_data = $self->parse_element;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"parsed column elements to:", $column_data ] );
		#~ my $column_store = [];
		#~ for my $definition ( @{$column_data->{list}} ){
			#~ next if !is_HashRef( $definition ) or !is_HashRef( $definition->{attributes} );
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Processing:", $definition ] );
			#~ my $row_ref;
			#~ map{ $row_ref->{$_} = $definition->{attributes}->{$_} if defined $definition->{attributes}->{$_} } qw( width customWidth bestFit hidden );
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Updated row ref:", $row_ref ] );
			#~ for my $col ( $definition->{attributes}->{min} .. $definition->{attributes}->{max} ){
				#~ $column_store->[$col] = $row_ref;
				#~ ###LogSD	$phone->talk( level => 'debug', message => [
				#~ ###LogSD		"Updated column store is:", $column_store ] );
			#~ }
		#~ }
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		"Final column store is:", $column_store ] );
		#~ $self->_set_column_formats( $column_store );
	#~ }
	
	#~ #build a merge map
	#~ my	$merge_ref = [];
	#~ ###LogSD	$phone->talk( level => 'debug', message => [
	#~ ###LogSD		"Loading the mergeCell" ] );
	#~ ( $node_depth, $node_name, $node_type ) = $self->location_status;
	#~ my $found_merges = 0;
	#~ if( ($node_name and $node_name eq 'mergeCells') or $self->advance_element_position( 'mergeCells') ){
		#~ $found_merges = 1;
	#~ }else{
		#~ $self->start_the_file_over;
		#~ $found_merges = $self->advance_element_position( 'mergeCells');
	#~ }
	#~ if( $found_merges ){
		#~ my $merge_range = $self->parse_element;
		#~ ###LogSD	$phone->talk( level => 'debug', message => [
		#~ ###LogSD		"Processing all merge ranges:", $merge_range ] );
		#~ my $final_ref;
		#~ for my $merge_ref ( @{$merge_range->{list}} ){
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"parsed merge element to:", $merge_ref ] );
			#~ my ( $start, $end ) = split /:/, $merge_ref->{attributes}->{ref};
			#~ my ( $start_col, $start_row ) = $self->_parse_column_row( $start );
			#~ my ( $end_col, $end_row ) = $self->_parse_column_row( $end );
			#~ ###LogSD	$phone->talk( level => 'debug', message => [
			#~ ###LogSD		"Start column: $start_col", "Start row: $start_row",
			#~ ###LogSD		"End column: $end_col", "End row: $end_row" ] );
			#~ my 	$min_col = $start_col;
			#~ while ( $start_row <= $end_row ){
				#~ $final_ref->[$start_row]->[$start_col] = $merge_ref->{attributes}->{ref};
				#~ $start_col++;
				#~ if( $start_col > $end_col ){
					#~ $start_col = $min_col;
					#~ $start_row++;
				#~ }
			#~ }
		#~ }
		#~ ###LogSD	$phone->talk( level => 'trace', message => [
		#~ ###LogSD		"Final merge ref:", $final_ref ] );
		#~ $self->_set_merge_map( $final_ref );
	#~ }
	#~ $self->start_the_file_over;
	#~ return 1;
#~ }

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow - Pull rows out of worksheet xml files

=head1 SYNOPSIS

See t\Spreadsheet\XLSX\Reader\LibXML02-worksheet_to_row.t
    
=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel 
parser.  To use the general package for excel parsing out of the box please review the 
documentation for L<Workbooks|Spreadsheet::XLSX::Reader::LibXML>,
L<Worksheets|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>

This module provides the basic connection to individual worksheet files (not chartsheets) for 
parsing xlsx workbooks and coalating shared strings data to cell data.  It does not provide 
a way to connect to L<chartsheets|Spreadsheet::XLSX::Reader::LibXML::Chartsheet>.  It does 
not provide the final view of a given cell.  The final view of the cell is collated with 
the role (Interface) L<Spreadsheet::XLSX::Reader::LibXML::Worksheet>.  This reader extends 
the base reader class L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>.  The functionality 
provided by those modules is not explained here.

For now this module reads each full row (with values) into a L<Spreadsheet::XLSX::Reader::LibXML::Row> 
instance.  It stores only the currently read row and the previously read row.  Exceptions to 
this are the start of read and end of read.  For start of read only the current row is available 
with the assumption that all prior implied rows are empty.  When a position past the end of the sheet 
is called both current and prior rows are cleared and an 'EOF' or undef value is returned.  See
L<Spreadsheet::XLSX::Reader::LibXML/file_boundary_flags> for more details.  This allows for storage 
of row general formats by row and where a requested cell falls in a row without values that the empty 
state can be determined without rescanning the file.

I<All positions (row and column places and integers) at this level are stored and returned in count 
from one mode!>

Modification of this module probably means extending a different reader or using other roles 
for implementation of the class.  Search for

	extends	'Spreadsheet::XLSX::Reader::LibXML::XMLReader';
	
To replace the base reader. Search for the method 'worksheet' in L<Spreadsheet::XLSX::Reader::LibXML> 
and the variable '$parser_modules' to replace this whole thing.

=head2 Attributes

Data passed to new when creating an instance.  For access to the values in these 
attributes see the listed 'attribute methods'. For general information on attributes see 
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the 
L<Public Methods|/Public Methods>.
	
=head3 is_hidden

=over

B<Definition:> This is set when the sheet is read from the sheet metadata level indicating 
if the sheet is hidden

B<Default:> none

B<Range:> (1|0)

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<is_sheet_hidden>

=over

B<Definition:> return the attribute value

=back

=back

=back

=head3 workbook_instance

=over

B<Definition:> This attribute holds a reference back to the workbook instance so that 
the worksheet has access to the global settings managed there.  As a consequence many 
of the workbook methods are be exposed here.  This includes some setter methods for 
workbook attributes. I<Beware that setting or adjusting the workbook level attributes 
with methods here will be universal and affect other worksheets.  So don't forget to 
return the old value if you want the old behavour after you are done.>  If that 
doesn't make sense then don't use these methods.  (Nothing to see here! Move along.)

B<Default:> a Spreadsheet::XLSX::Reader::LibXML instance

B<attribute methods> Methods of the workbook exposed here by the L<delegation
|Moose::Manual::Attributes/Delegation> of the instance to this class through this 
attribute

=over

B<counting_from_zero>

=over

B<Definition:> returns the L<Spreadsheet::XLSX::Reader::LibXML/count_from_zero> 
instance state

=back

B<boundary_flag_setting>

=over

B<Definition:> returns the L<Spreadsheet::XLSX::Reader::LibXML/file_boundary_flags> 
instance state

=back

B<change_boundary_flag( $Bool )>

=over

B<Definition:> sets the L<Spreadsheet::XLSX::Reader::LibXML/file_boundary_flags> 
instance state (B<For the whole workbook!>)

=back

B<get_shared_string( $int )>

=over

B<Definition:> returns the shared string data stored in the sharedStrings 
file at position $int.  For more information review 
L<Spreadsheet::XLSX::Reader::LibXML::SharedStrings>.  I<This is a delegation 
of a delegation!>

=back

B<get_format_position( $int, [$header] )>

=over

B<Definition:> returns the format data stored in the styles 
file at position $int.  If the optional $header is passed only the data for that 
header is returned.  Otherwise all styles for that position are returned.  
For more information review 
L<Spreadsheet::XLSX::Reader::LibXML::Styles>.  I<This is a delegation 
of a delegation!>

=back

B<set_empty_is_end( $Bool )>

=over

B<Definition:> sets the L<Spreadsheet::XLSX::Reader::LibXML/empty_is_end> 
instance state (B<For the whole workbook!>)

=back

B<is_empty_the_end>

=over

B<Definition:> returns the L<Spreadsheet::XLSX::Reader::LibXML/empty_is_end> 
instance state.

=back

B<get_group_return_type>

=over

B<Definition:> returns the L<Spreadsheet::XLSX::Reader::LibXML/group_return_type> 
instance state.

=back

B<set_group_return_type( (instance|unformatted|value) )>

=over

B<Definition:> sets the L<Spreadsheet::XLSX::Reader::LibXML/group_return_type> 
instance state (B<For the whole workbook!>)

=back

B<get_epoch_year>

=over

B<Definition:> uses the L<Spreadsheet::XLSX::Reader::LibXML/get_epoch_year> method.

=back

B<get_date_behavior>

=over

B<Definition:> This is a L<delegated|Moose::Manual::Delegation> method from the 
L<styles|Spreadsheet::XLSX::Reader::LibXML::Styles> class (stored as a private 
instance in the workbook).  It is held (and documented) in the 
L<Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings> role.  It will 
indicate how far unformatted L<transformation
|Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings/datetime_dates> 
is carried for date coercions when returning formatted values. 

=back

B<set_date_behavior>

=over

B<Definition:> This is a L<delegated|Moose::Manual::Delegation> method from 
the L<styles|Spreadsheet::XLSX::Reader::LibXML::Styles> class (stored as a private 
instance in the workbook).  It is held (and documented) in the 
L<Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings> role.  It will set how 
far unformatted L<transformation
|Spreadsheet::XLSX::Reader::LibXML::ParseExcelFormatStrings/datetime_dates> 
is carried for date coercions when returning formatted values. 

=back

B<get_values_only>

=over

B<Definition:> gets the L<Spreadsheet::XLSX::Reader::LibXML/values_only> 
instance state.

=back

B<set_values_only>

=over

B<Definition:> sets the L<Spreadsheet::XLSX::Reader::LibXML/values_only> 
instance state (B<For the whole workbook!>)

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

B<_set_min_col>

=over

B<Definition:> sets the attribute value

=back

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
module it is pulled from the xml file at worksheet/dimension:ref = "upperleft:lowerright"

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
	
=head3 _merge_map

=over

B<Definition:> This is an array ref of array refs where the first level represents rows 
and the second level of array represents cells.  If a cell is merged then the merge span 
is stored in the row sub array position.  This means the same span is stored in multiple 
positions.  The data is stored in the Excel convention of count from 1 so the first position 
in both levels of the array are essentially placeholders.  The data is extracted from the 
merge section of the worksheet at worksheet/mergeCells.  That array is read and converted 
into this format for reading by this module when it first opens the worksheet.

B<Range:> an array ref

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<_set_merge_map>

=over

B<Definition:> sets the attribute value

=back

=back

B<_get_merge_map>

=over

B<Definition:> returns the attribute array of arrays

=back

=back

B<delegated methods> This attribute uses the native trait 'Array'
		
=over

B<_get_row_merge_map( $int )> delgated from 'Array' 'get'

=over

B<Definition:> returns the sub array ref representing any merges for that 
row.  If no merges are available for that row it returns undef.

=back

=back
	
=head3 _column_formats

=over

B<Definition:> In order to (eventually) show all column formats that also affect individual 
cells the column based formats are read from the metada when the worksheet is opened.  They
are stored here for use although for now they are mostly used to determine the hidden state of 
the column.  The formats are stored in the array by count from 1 column position.

B<Range:> an array ref

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<_set_set_column_formats>

=over

B<Definition:> sets the attribute value

=back

=back

B<_get_get_column_formats>

=over

B<Definition:> returns the attribute array

=back

=back

B<delegated methods> This attribute uses the native trait 'Array'
		
=over

B<_get_custom_column_data( $int )> delgated from 'Array' 'get'

=over

B<Definition:> returns the sub hash ref representing any formatting 
for that column.  If no custom formatting is available it returns undef.

=back

=back
	
=head3 _new_row_inst

=over

B<Definition:> This is the current read row instance or undef for the end of the sheet 
read.

B<Range:> isa => InstanceOf[ L<Spreadsheet::XLSX::Reader::LibXML::Row> ]

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<_set_new_row_inst>

=over

B<Definition:> sets the attribute value

=back

B<_get_new_row_inst>

=over

B<Definition:> returns the attribute

=back

B<_clear_new_row_inst>

=over

B<Definition:> clears the attribute

=back

B<_has_new_row_inst>

=over

B<Definition:> predicate for the attribute

=back

B<delegated methods> from L<Spreadsheet::XLSX::Reader::LibXML::Row>
		
=over

B<_get_new_row_number> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_row_number>

B<_is_new_row_hidden> = L<Spreadsheet::XLSX::Reader::LibXML::Row/is_row_hidden>

B<_get_new_row_formats> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_row_format>

=over

pass the desired format key

=back

B<_get_new_column> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_the_column( $column )>

=over

pass a column number (no next default) returns (cell|undef|EOR)

=back

B<_get_new_next_value> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_the_next_value_position>

=over

pass nothing returns next (cell|EOR)

=back

B<_get_new_last_value_col> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_last_value_column>

B<_get_new_row_list> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_row_all>

B<_get_new_row_end> = L<Spreadsheet::XLSX::Reader::LibXML::Row/get_row_endl>

=back

=back

=back
	
=head3 _row_hidden_states

=over

B<Definition:> As the worksheet is parsed it will store the hidden state for 
the row in this attribute when each row is read.  This is the only worksheet 
level caching done.  B<It will not test whether the requested row hidden state 
has been read when accessing this data.>  If a method call a row past the 
current max parsed row it will return 0 (unhidden).

B<Range:> an array ref of Boolean values

B<delegated methods> This attribute uses the native trait 'Array'
		
=over

B<_set_row_hidden( $int )> delgated from 'Array' 'set'

=over

B<Definition:> sets the hidden state for that $int (row) counting from 1.

=back

B<_get_row_hidden( $int )> delgated from 'Array' 'get'

=over

B<Definition:> returns the known hidden state of the row.

=back

=back

=back

=head2 Methods

These are the methods provided by this class for use within the package but are not intended 
to be used by the end user.  Other private methods not listed here are used in the module but 
not used by the package.  If the private method is listed here then replacement of this module 
either requires replacing them or rewriting all the associated connecting roles and classes.

=head3 _load_unique_bits

=over

B<Definition:> This is called by L<Spreadsheet::XLSX::Reader::LibXML::XMLReader> when the file is 
loaded for the first time so that file specific metadata can be collected.

B<Accepts:> nothing

B<Returns:> nothing

=back

=head3 _get_next_value_cell

=over

B<Definition:> This returns the worksheet file hash ref representation of the xml stored for the 
'next' value cell.  A cell is determined to have value based on the attribute 
L<Spreadsheet::XLSX::Reader::LibXML/values_only>.  Next is affected by the attribute 
L<Spreadsheet::XLSX::Reader::LibXML/empty_is_end>.  This method never returns an 'EOR' flag.  
It just wraps automatically.  This does return values from the shared strings file integrated but 
not values from the Styles file integrated.

B<Accepts:> nothing

B<Returns:> a hashref of key value pairs

=back

=head3 _get_col_row( $col, $row )

=over

B<Definition:> This is the way to return the information about a specific position in the worksheet.  
Since this is a private method it requires its inputs to be in the 'count from one' index.

B<Accepts:> ( $column, $row ) - both required in that order

B<Returns:> whatever is in that worksheet position as a hashref

=back

=head3 _get_row_all( $row )

=over

B<Definition:> This is returns an array ref of each of the values in the row placed in their 'count 
from one' position.  If the row is empty but it is not the end of the sheet then this will return an 
empty array ref.

B<Accepts:> ( $row ) - required

B<Returns:> an array ref

=back

=head3 _is_column_hidden( @query_list )

=over

B<Definition:> This is returns a list of hidden states for each column integer in the @query_list 
it will generally return n array ref of each of the values in the row placed in their 'count 
from one' position.  If the row is empty but it is not the end of the sheet then this will return an 
empty array ref.

B<Accepts:> ( @query_list ) - integers in count from 1 representing requested columns

B<Returns (when wantarray):> a list of hidden states as follows; 1 => hidden, 0 => known to be unhidden, 
undef => unknown state (usually this represents columns before min_col or after max_col or at least past 
the last stored value in the column)

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

L<version>

L<perl 5.010|perl/5.10.0>

L<Moose>

L<MooseX::StrictConstructor>

L<MooseX::HasDefaults::RO>

L<Clone> - clone

L<Carp> - confess

L<Type::Tiny> - 1.000

L<MooseX::ShortCut::BuildInstance> - build_instance should_re_use_classes

L<Spreadsheet::XLSX::Reader::LibXML>

L<Spreadsheet::XLSX::Reader::LibXML::XMLReader>

L<Spreadsheet::XLSX::Reader::LibXML::Row>

L<Spreadsheet::XLSX::Reader::LibXML::CellToColumnRow>

L<Spreadsheet::XLSX::Reader::LibXML::XMLToPerlData>

=back

=head1 SEE ALSO

=over

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1 Documentation End  3#########4#########5#########6#########7#########8#########9
