package Spreadsheet::XLSX::Reader::LibXML::XMLReader::Worksheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::XMLReader::Worksheet-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
	get_attribute_hash_ref			location_status					advance_element_position
	parse_element					set_error						start_the_file_over
	_build_cell_label
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

my	$column_translations = {
		width		=> 'ss:Width',
		customWidth	=> 'ss:CustomWidth',
		bestFit		=> 'ss:AutoFitWidth',
		hidden		=> 'ss:Hidden',
	};

my	$rich_text_translations = {
		'html:Color'	=> 'rgb',
		'html:Size'		=> 'sz',
	};

my $width_translation = 9.5703125/50.25;# Translation from 2003 xml file width to 2007+ width

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
			_set_merge_row_map => 'set',
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
	###LogSD			$self->get_all_space . '::_hidden::_load_unique_bits::XMLReader', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Setting the Worksheet unique bits", ] );
	
	# Set the sheet row column dimensions
	$self->_set_min_col( 1 );# As far as I can tell xml flat files don't acknowledge start point other than A1
	$self->_set_min_row( 1 );
	my ( $node_depth, $node_name, $node_type ) = $self->location_status;
	if( $node_name eq 'Table' or $self->advance_element_position( 'Table' ) ){
		my $dimension = $self->get_attribute_hash_ref;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"parsed dimension value:", $dimension ] );
		my $end_column = $dimension->{'ss:ExpandedColumnCount'};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The end column is: " . ($end_column//'undef') ] );
		$self->_set_max_col( $end_column ) if $end_column;
		my $end_row = $dimension->{'ss:ExpandedRowCount'};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The end row is: " . ($end_row//'undef') ] );
		$self->_set_max_col( $end_row ) if $end_row;
	}else{
		$self->_set_min_col( 0 );
		$self->_set_min_row( 0 );
		$self->set_error( "No sheet dimensions provided" );
	}
	
	#pull column stats
	my	$has_column_data = 1;
	( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Loading the column configuration: " . $node_name ] );
	if( $node_name eq 'Column' or $self->advance_element_position( 'Column') ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Already arrived at the column data" ] );
	}else{
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Restart the sheet to find the column data" ] );
		$self->start_the_file_over;
		$self->advance_element_position( 'Column' );
	}
	( $node_depth, $node_name, $node_type ) = $self->location_status;
	my $column_store = [];
	my $current_column = 1;# flat xml files don't always record column sometime they just sequence from the beginning
	while( $node_name eq 'Column' ){
		my $column_settings = $self->parse_element;
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Processing:", $column_settings ] );
		next if !is_HashRef( $column_settings ) or !is_HashRef( $column_settings->{attributes} );
		my $col_ref;
		map{ 
			if( defined $column_settings->{attributes}->{$column_translations->{$_}} ){
				$col_ref->{$_} = $column_settings->{attributes}->{$column_translations->{$_}}
			}
		} qw( width customWidth bestFit hidden );
		$col_ref->{bestFit} = !$col_ref->{bestFit};
		delete $col_ref->{bestFit} if !$col_ref->{bestFit};
		$col_ref->{width} = $col_ref->{width} * $width_translation if exists $col_ref->{width};
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Updated column ref:", $col_ref ] );
		my $start_column = $column_settings->{attributes}->{'ss:Index'} // $current_column;
		my $end_column = $start_column + (exists( $column_settings->{attributes}->{'ss:Span'} ) ? $column_settings->{attributes}->{'ss:Span'} : 0);
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"The column ref applies to columns -$start_column- through -$end_column-" ] );
		for my $col ( $start_column .. $end_column ){
			$column_store->[$col] = $col_ref;
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated column store is:", $column_store ] );
		}
		( $node_depth, $node_name, $node_type ) = $self->location_status;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
		if( $node_name ne 'Column' ){
			$self->advance_element_position( 'Column');
			( $node_depth, $node_name, $node_type ) = $self->location_status;
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
		}
		$current_column = $end_column + 1;
	}
	###LogSD	$phone->talk( level => 'debug', message => [
	###LogSD		"Final column store is:", $column_store ] );
	$self->_set_column_formats( $column_store );
	
	# No sheet level merge data stored - add when parsed at the cell level!
	$self->start_the_file_over;
	return 1;
}

sub _go_to_or_past_row{
	my( $self, $target_row ) = @_;
	my $current_row = $self->_has_new_row_inst ? $self->_get_new_row_number : 0;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_go_to_or_past_row::XMLReader', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Indexing the row forward to find row: $target_row", "From current row: $current_row" ] );
	
	# Check the current row and make sure we don't want it
	my $current_position = -1;
	if( $self->_has_new_row_inst ){
		$current_row = $self->_get_new_row_number;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Currently loaded row is row number: $current_row" ] );
		if( defined $target_row and $current_row == $target_row ){
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		'Asked for a row that has already been built and loaded' ] );
			return $target_row;
		}else{
			$current_position = $self->_get_row_position( $current_row );
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Currently at row -$current_row- in position: $current_position" ] );
		}
	}
	my( $node_depth, $node_name, $node_type ) = $self->location_status;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
	
	# See if the desired row is in known territory
	my $max_known_row = $self->_max_row_position_recorded;
	$max_known_row-- if $max_known_row > 0;
	my $max_recorded_position = -1;
	my $row_attributes;
	if( $target_row <= $max_known_row ){
		my $target_position;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The target row -$target_row- lies in known territory" ] );
		
		# Adjust the target if the request falls in a hole
		while( 1 ){
			$target_position = $self->_get_row_position( $target_row );
			if( defined $target_position ){
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		"Target row -$target_row- has a defined position: $target_position" ] );
				last;
			}else{
				$target_row++;
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		"No row data for the last target row - checking the next row: $target_row" ] );
			}
		}
		
		# Test for a needed rewind
		if( $target_position < $current_position ){
			###LogSD	$phone->talk( level => 'info', message =>[ "Rewinding the file" ] );
			$current_position = -1;
			$self->start_the_file_over;
		}
		
		# Advance to the required position
		my $fast_forward = $target_position - $current_position;
		$self->advance_element_position( 'Row', $fast_forward );########################################### Differentiator
		( $node_depth, $node_name, $node_type ) = $self->location_status;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
		$row_attributes = $self->get_attribute_hash_ref;
		$row_attributes->{attribute_hash}->{r} = $target_row;
		delete $row_attributes->{'ss:Index'};
		@$row_attributes{qw(node_depth node_name node_type )} = ( $node_depth, $node_name, $node_type );
		return $self->_build_row_instance_here( $row_attributes );
	}else{
		# Advance to the end of known
		$max_recorded_position = $self->_get_row_position( $max_known_row ) // -1;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"The target row -$target_row- lies past known territory - jump to the end: $max_recorded_position" ] );
		my $fast_forward = $max_recorded_position - $current_position;
		if( $fast_forward > 0 ){
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Fast forwarding -$fast_forward- times" ] );
			$self->advance_element_position( 'Row', $fast_forward ) ;
		}
	}
	
	# To boldy go where no one has gone before
	my $first_pass = 1;
	$self->_clear_new_row_inst;# We are not in Kansas anymore
	while( $target_row > $max_known_row ){
		( $node_depth, $node_name, $node_type ) = $self->location_status;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
		if( $first_pass or $node_name ne 'Row' ){########################################################## Differentiator
			$first_pass = 0;
			$self->advance_element_position( 'Row' );
			( $node_depth, $node_name, $node_type ) = $self->location_status;
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Currently @ depth -$node_depth- for node named -$node_name- of type: $node_type" ] );
		}
		
		# Check for EOF node
		if( $node_name eq 'EOF' ){
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Returning EOF"  ] );
			$self->_set_max_row_state;
			return $node_name;
		}elsif( $node_name ne 'Row' ){########################################### Differentiator
			confess "I looked for a row and found node: $node_name";
		}
		
		# Process the node advance
		$row_attributes = $self->get_attribute_hash_ref;
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"The attribute ref for this row is:", $row_attributes ] );
		$current_row = exists( $row_attributes->{'ss:Index'} ) ? $row_attributes->{'ss:Index'} : $max_known_row + 1;############################################## Differentiator
		if( $current_row >= $target_row ){# You have arrived
			@$row_attributes{qw(node_depth node_name node_type )} = ( $node_depth, $node_name, $node_type );
		}elsif( !scalar(keys %$row_attributes) ){# nodes without attributes don't advance during an attribute read!!!
			$self->_read_next_node;
		}
		$row_attributes->{attribute_hash}->{r} = $current_row;
		delete $row_attributes->{'ss:Index'};
		$max_recorded_position++;
		$self->_set_row_position( $current_row => $max_recorded_position );
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		"Currently at row: $current_row",
		###LogSD		"..and current position: $max_recorded_position" ] );
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		'In ref:', $self->_get_all_positions ] );
		
		# Process hidden rows
		if( exists $row_attributes->{'ss:Hidden'} ){
			my $max_hidden_row = $current_row + ($row_attributes->{'ss:Span'}//0);
			map{ $self->_set_row_hidden( $_ => 1 ) } ( $current_row .. $max_hidden_row );
		}else{
			$self->_set_row_hidden( $current_row => 0 );
		}
		delete $row_attributes->{'ss:Hidden'};
		delete $row_attributes->{'ss:Span'};
		###LogSD	$phone->talk( level => 'trace', message => [
		###LogSD		"The updated positions from row -$current_row- of the hidden row ref: ", $self->_get_all_hidden,
		###LogSD		"..with the updated position row ref: ", $self->_get_all_positions, ] );
		$max_known_row = $current_row;
		
	}
	
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		"Building row for the current position with attribute ref:", $row_attributes ] );
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		'In ref:', $self->_get_all_positions ] );
	return $self->_build_row_instance_here( $row_attributes );
}

sub _build_row_instance_here{
	my( $self, $row_attributes ) = @_;
	my $current_row = $row_attributes->{attribute_hash}->{r};
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_build_row_instance_here::XMLReader', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"For row -$current_row- Building a full row instance", $row_attributes ] );
	delete $row_attributes->{attribute_hash}->{r};
	
	# Collect the details of the final row position
	my $row_ref = $self->parse_element( undef, $row_attributes );
	###LogSD	$phone->talk( level => 'trace', message => [#ask => 1, 
	###LogSD		'Initial row read:', $row_ref ] );
	
	# Load text values for each cell where appropriate
	my ( $alt_ref, $column_to_cell_translations, $start_column, $end_column );
	my $cell_position = 0;
	my $column_number = 1;
	for my $cell ( @{$row_ref->{list}} ){
		###LogSD	$phone->talk( level => 'debug', message => [
		###LogSD		'Processing cell:', $cell	] );
		if( $row_ref->{list_keys}->[$cell_position] ne 'Cell' ){
			confess "Found a -$row_ref->{list_keys}->[$cell_position]- when I expected to find a cell";
		}
		my $new_cell;
		
		# Handle merged cells
		$new_cell->{cell_row} = $current_row;
		$new_cell->{cell_col} = ( exists $cell->{attributes}->{'ss:Index'} ) ? $cell->{attributes}->{'ss:Index'} : $column_number;
		$new_cell->{r} = $self->_build_cell_label( $new_cell->{cell_col}, $new_cell->{cell_row} );
		if( !defined $start_column ){# handle the row span
			$start_column = $new_cell->{cell_col};
		}
		$end_column = $new_cell->{cell_col};
		my $should_merge = 0;
		my( $merge_to_col, $merge_to_row ) = ( $new_cell->{cell_col}, $new_cell->{cell_row} );
		if( exists $cell->{attributes}->{'ss:MergeAcross'} ){
			$merge_to_col = $merge_to_col + $cell->{attributes}->{'ss:MergeAcross'};
			$should_merge = 1;
			delete $cell->{attributes}->{'ss:MergeAcross'};
		}
		if( exists $cell->{attributes}->{'ss:MergeDown'} ){
			$merge_to_row = $merge_to_row + $cell->{attributes}->{'ss:MergeDown'};
			$should_merge = 1;
			delete $cell->{attributes}->{'ss:MergeDown'};
		}
		if( $should_merge ){
			my $merge_string = "$new_cell->{r}:" . $self->_build_cell_label( $merge_to_col, $merge_to_row );
			for my $row ( $new_cell->{cell_row} .. $merge_to_row ){
				my $row_ref = [];
				for my $col ( $new_cell->{cell_col} .. $merge_to_col ){
					$row_ref->[$col] = $merge_string;
				}
				$self->_set_merge_row_map( $row => $row_ref );
			}
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Updated merge map to:", $self->_get_merge_map ] );
			# Merge added to cell later per the zip style format
		}
		###LogSD	$phone->talk( level => 'trace', message =>[ "Updated cell:", $new_cell ] );
			
		
		# Resolve the value of the cell
		if( exists $cell->{attributes}->{'ss:SharedStringsID'} ){# Probably an unused branch in xml flat files
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Found a possible shared strings callout: $cell->{attributes}->{'ss:SharedStringsID'}" ] );
			my $named_value = $self->get_shared_string( $cell->{attributes}->{'ss:SharedStringsID'} );
			###LogSD	$phone->talk( level => 'debug', message => [
			###LogSD		"Shared Strings returned:", $named_value ] );
			if( is_HashRef( $named_value ) ){
				@$new_cell{qw( cell_xml_value rich_text )} = ( $named_value->{raw_text}, $named_value->{rich_text} );
				delete $new_cell->{rich_text} if !$new_cell->{rich_text};
			}else{
				$new_cell->{cell_xml_value} = $named_value;
			}
			delete $cell->{attributes}->{'ss:SharedStringsID'};
		}
		
		# Handle 'Data' node
		if( exists $cell->{list} ){
			if( exists $new_cell->{cell_xml_value} ){
				confess "Attempting to process a $cell->{attributues}-{list_keys}->[0]- node but the xml value has been set by SharedStringsID";
			}elsif( scalar( @{$cell->{list_keys}} ) > 1 ){
				confess "There appears to be more than one Data node: " . join( '~|~', @{$cell->{list_keys}} );
			}elsif( $cell->{list_keys}->[0] !~ /data/i ){
				confess "Weird node -$cell->{list_keys}->[0]- where data node expected";
			}
			@$new_cell{ qw( cell_xml_value cell_type rich_text ) } = $self->_process_data_element( $cell->{list}->[0] );
			delete $new_cell->{rich_text} if !$new_cell->{rich_text};
		}
		###LogSD	$phone->talk( level => 'trace', message =>[ "Updated cell:", $new_cell ] );
		
		# handle empty values
		if( $self->get_empty_return_type eq 'empty_string' ){
			###LogSD	$phone->talk( level => 'debug', message =>[ "Setting empty cells to empty strings" ] );
			$new_cell->{cell_xml_value} = '' if !exists $new_cell->{cell_xml_value} or !defined $new_cell->{cell_xml_value};
		}elsif( !defined $new_cell->{cell_xml_value} or
				($new_cell->{cell_xml_value} and length( $new_cell->{cell_xml_value} ) == 0) ){
			###LogSD	$phone->talk( level => 'debug', message =>[ "Deleting the xml value because it is not defined" ] );
			delete $new_cell->{cell_xml_value};
		}
		###LogSD	$phone->talk( level => 'debug', message =>[ "Updated cell:",  $new_cell ] );
		
		# Clear empty cells if required
		if( $self->get_values_only and ($new_cell->{cell_type} ne 'Number') # Weird Excel 2003 xml thing where empty cells contain 0's for number types
			and ( !defined $new_cell->{cell_xml_value} or length( $new_cell->{cell_xml_value} ) == 0 ) ){
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		'Values only called - stripping this non-value cell'	] );
		}else{
			# Build out the sub values of the cell
			$new_cell->{cell_hidden} = 'row' if $self->_get_row_hidden( $new_cell->{cell_row} );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated cell:",  $new_cell] );
			if( exists $cell->{attributes}->{'ss:StyleID'} ){
				$new_cell->{s} = $cell->{attributes}->{'ss:StyleID'};
				delete $cell->{attributes}->{'ss:StyleID'};
			}
			if( exists $cell->{attributes}->{'ss:Formula'} ){
				$new_cell->{cell_formula} = $cell->{attributes}->{'ss:Formula'};
				delete $cell->{attributes}->{'ss:Formula'};
			}
			$column_to_cell_translations->[$new_cell->{cell_col}] = $cell_position++;
			delete $cell->{attributes};# Add warning for unused attributes here?
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		'Saving cell:', $new_cell	] );
			push @$alt_ref, $new_cell;
		}
		
		#Index the column for next cell
		$column_number = $new_cell->{cell_col} + 1;
	}
	###LogSD	$phone->talk( level => 'trace', message => [
	###LogSD		'Final built cell list:', $alt_ref, 'Final cell column to position ref:', $column_to_cell_translations	] );
	
	#Load the row instance
	my $new_ref;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Row ref:", $row_ref, ] );
	if( defined $current_row ){
		$new_ref->{row_number} = $current_row;
		delete $row_ref->{list};
		delete $row_ref->{list_keys};
		delete $row_ref->{attributes}->{'ss:Hidden'};
		if( $alt_ref ){
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Alt ref:", $alt_ref, "updated row ref:", $row_ref, "new ref:", $new_ref,] );
			$new_ref->{row_value_cells}	= $alt_ref;
			$new_ref->{row_span} = [ $start_column, $end_column ];
			$new_ref->{row_last_value_column} = $end_column;
			$new_ref->{column_to_cell_translations}	= $column_to_cell_translations;
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"adjusted new ref:", $new_ref,] );
			if( !$self->has_max_col or $self->_max_col < $end_column ){
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"From known cells setting the max column to: $end_column" ] );
				$self->_set_max_col( $end_column );
			}
		}else{
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		" No row list (with values?) found" ] );
			$new_ref->{row_span} = [ 0, 0 ];
			$new_ref->{row_last_value_column} = 0;
			$new_ref->{column_to_cell_translations}	= [];
		}
		$row_ref->{height} = $row_ref->{attributes}->{'ss:Height'} if exists $row_ref->{attributes}->{'ss:Height'};
		delete $row_ref->{attributes};
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
		###LogSD		"line 469 - No row number found - must be EOF", ] );
		return 'EOF';
	}
	
	if( !$alt_ref ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'Nothing to see here - move along', ] );
		###LogSD	no warnings 'uninitialized';
		if( is_Int( $current_row ) ){
			$self->_set_row_position( $current_row => undef );# Clean up phantom placeholder
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD	"Going on to the next row: " . ($current_row +1), ] );
			no warnings 'recursion';
			$current_row = $self->_go_to_or_past_row( $current_row + 1 );# Recursive call for empty rows
			use warnings 'recursion';
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD	"The position ref is:", $self->_get_all_positions ] );
		}
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

sub _process_data_element{
	my( $self, $element_ref, $cell_raw_text, $rich_text, $element_type, $wrapper_ref ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::_process_rich_text_element::XMLReader', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Adding to raw_text: " . ($cell_raw_text//'undef'), '..and rich_text:', $rich_text, 
	###LogSD			"..for express element type -" . ($element_type//'none') . "- using wrapper ref:", $wrapper_ref, '..with element:', $element_ref ] );
	
	# Handle cell type
	my $cell_type = 'Text';
	if( exists $element_ref->{'ss:Type'} ){
		$cell_type = $element_ref->{'ss:Type'};
	}elsif( exists $element_ref->{attributes}->{'ss:Type'} ){
		$cell_type = $element_ref->{attributes}->{'ss:Type'};
	}
	$cell_type =~ s/String/Text/;
	###LogSD	$phone->talk( level => 'debug', message =>[ "Cell type set to: $cell_type" ] );
	
	my $sub_ref;
	if( $element_type ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Managing node with element type: $element_type", ] );
		if( $element_type eq 'Font' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Font element found - arrived at the bottom", ] );
			my $rich_ref;
			for my $setting ( qw( html:Color html:Size ) ){
				$rich_ref->{$rich_text_translations->{$setting}} = $element_ref->{$setting} if exists $element_ref->{$setting};
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"After adding -$rich_text_translations->{$setting}- for -$setting- result:", $rich_ref, ] );
			}
			if( exists $rich_ref->{rgb} ){
				if( $rich_ref->{rgb} eq '#000000' ){
					delete $rich_ref->{rgb};
				}else{
					$rich_ref->{rgb} =~ s/#/FF/;
				}
			}
			if( keys %$rich_ref ){
				if( keys %$wrapper_ref ){
					map{ $rich_ref->{$_} = undef } keys %$wrapper_ref;
				}
				push @$rich_text, [ length( $cell_raw_text ), $rich_ref ],
			}
			$cell_raw_text .= $element_ref->{raw_text};
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated raw_text -$cell_raw_text- with rich_text:", $rich_text, ] );
		}else{
			$wrapper_ref->{lc( $element_type )} = undef;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Going deeper with updated wrapper ref:", $wrapper_ref, ] );
			$sub_ref = $element_ref;
		}
	}elsif( exists $element_ref->{raw_text} ){
		$cell_raw_text = $element_ref->{raw_text};
		###LogSD	$phone->talk( level => 'debug', message =>[ "Cell raw_text set to: $cell_raw_text" ] );
	}else{
		$sub_ref = $element_ref;
		###LogSD	$phone->talk( level => 'debug', message =>[ "Cell raw_text set to: 'undef'" ] );
	}
	my $x = 0;
	for my $sub_element ( @{$sub_ref->{list}} ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"For node type -$sub_ref->{list_keys}->[$x]- processing node:", $sub_element ] );
		my $alt_type;# Block type passing with scope since it is found on top
		( $cell_raw_text, $alt_type, $rich_text, ) = 
			$self->_process_data_element(
				$sub_element, $cell_raw_text, $rich_text, $sub_ref->{list_keys}->[$x], $wrapper_ref
			);
		$x++;
	}
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Returning raw_text: " . ($cell_raw_text//'undef'), "..of data type: $cell_type", '..with rich_text:', $rich_text ] );
	return( $cell_raw_text, $cell_type, $rich_text );
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::XMLReader::XMLReader::Worksheet - XML file unique Worksheet reader

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