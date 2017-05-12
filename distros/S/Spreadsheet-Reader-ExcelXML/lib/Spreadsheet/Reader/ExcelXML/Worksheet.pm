package Spreadsheet::Reader::ExcelXML::Worksheet;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::Worksheet-$VERSION";

use Modern::Perl;
use Carp 'confess';
use	Moose::Role;
requires qw(
		set_error					parse_excel_format_string	get_used_position
		get_excel_position			_min_row					_max_row
		_max_col					_min_col					get_merge_map
		get_custom_column_data		parse_column_row			_parse_column_row
		get_custom_row_data			get_group_return_type		change_output_encoding
		get_error_inst				has_styles_interface		has_max_row
		get_new_column				is_empty_the_end			go_to_or_past_row
		boundary_flag_setting		has_max_col					get_format
		get_new_next_value			has_new_row_inst			get_values_only
		get_new_row_all				get_new_row_number
	);
###LogSD	requires 'get_log_space', 'get_all_space';
use Types::Standard qw(
	Bool 						HasMethods					Enum
	Int							is_Int						ArrayRef
	is_ArrayRef					HashRef						is_HashRef
	is_Object					Str							is_Str
);# Int
use lib	'../../../../lib',;
###LogSD	use Log::Shiras::Telephone;

use Spreadsheet::Reader::ExcelXML::Cell;
use	Spreadsheet::Reader::ExcelXML::Types qw(
		SpecialDecimal					SpecialZeroScientific
		SpecialOneScientific			SpecialTwoScientific
		SpecialThreeScientific			SpecialFourScientific
		SpecialFiveScientific
	);

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9

my $format_headers =[ qw(
		cell_font		cell_border			cell_style
		cell_fill		cell_coercion		cell_alignment
	) ];

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has sheet_type =>(
		isa		=> Enum[ 'worksheet' ],
		default	=> 'worksheet',
		reader	=> 'get_sheet_type',
	);

has sheet_rel_id =>(
		isa		=> Str,
		reader	=> 'rel_id',
	);

has sheet_id =>(
		isa		=> Int,
		reader	=> 'sheet_id',
	);

has sheet_position =>(# XML position
		isa		=> Int,
		reader	=> 'position',
	);

has sheet_name =>(
		isa		=> Str,
		reader	=> 'get_name',
		predicate	=> '_has_name',
	);

has min_header_col =>(
		isa			=> Int,
		reader		=> 'get_min_header_col',
		writer		=> 'set_min_header_col',
		clearer		=> 'clear_min_header_col',
		predicate	=> 'has_min_header_col'
	);

has max_header_col =>(
		isa			=> Int,
		reader		=> 'get_max_header_col',
		writer		=> 'set_max_header_col',
		clearer		=> 'clear_max_header_col',
		predicate	=> 'has_max_header_col'
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

###LogSD	sub get_class_space{ 'Worksheet' }

sub min_row{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::min_row', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning the minimum row" ] );
	my $code_min = $self->_min_row;
	# Convert to user numbers
	my $user_min = $self->get_used_position( $code_min );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning -$user_min- for row: $code_min" ] );
	return $user_min;
}

sub max_row{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::max_row', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning the maximum row" ] );
	my $code_max = $self->_max_row;
	if( defined $code_max ){
		# Convert to user numbers
		my $user_max = $self->get_used_position( $code_max );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning -$user_max- for row: $code_max" ] );
		return $user_max;
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No stored value for max row" ] );
		return undef;
	}
}

sub min_col{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::min_col', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning the minimum column" ] );
	my $code_min = $self->_min_col;
	# Convert to user numbers
	my $user_min = $self->get_used_position( $code_min );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning -$user_min- for column: $code_min" ] );
	return $user_min;
}

sub max_col{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::max_col', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning the maximum column" ] );
	my $code_max = $self->_max_col;
	if( defined $code_max ){
		# Convert to user numbers
		my $user_max = $self->get_used_position( $code_max );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning -$user_max- for column: $code_max" ] );
		return $user_max;
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No stored value for max column" ] );
		return undef;
	}
}

sub row_range{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::row_range', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning row range" ] );
	my $code_min = $self->_min_row;
	# Convert to user numbers
	my $user_min = $self->get_used_position( $code_min );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning -$user_min- for row: $code_min" ] );
	my $code_max = $self->_max_row;
	my $user_max;
	if( defined $code_max ){
		# Convert to user numbers
		$user_max = $self->get_used_position( $code_max );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning -$user_max- for row: $code_max" ] );
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No stored value for max row" ] );
	}
	return( $user_min, $user_max );
}

sub col_range{
	my( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::row_bound::col_range', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			"Returning col range" ] );
	my $code_min = $self->_min_col;
	# Convert to user numbers
	my $user_min = $self->get_used_position( $code_min );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Returning -$user_min- for column: $code_min" ] );
	my $code_max = $self->_max_col;
	my $user_max;
	if( defined $code_max ){
		# Convert to user numbers
		$user_max = $self->get_used_position( $code_max );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returning -$user_max- for column: $code_max" ] );
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"No stored value for max row" ] );
	}
	return( $user_min, $user_max );
}

sub get_merged_areas{
	my( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_merged_areas', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Pulling the merge map ParseExcel style' ] );

	# Get the raw merge map
	my $raw_map = $self->get_merge_map;
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Raw merge row map;", $raw_map] );
	my ( $new_map, $dup_ref );
	#parse out the empty rows
	for my $row ( @$raw_map ){
		next if !$row;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Processing the merge row data:", $row] );
		for my $merge_cell ( @$row ){
			next if !$merge_cell;
			next if exists $dup_ref->{$merge_cell};
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Processing the merge row data: $merge_cell"] );
			my $merge_ref;
			for my $cell ( split /:/, $merge_cell ){
				my ( $column, $row ) = $self->parse_column_row( $cell );
				push @$merge_ref, $row, $column;
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Updated merge ref:", $merge_ref] );
			}
			$dup_ref->{$merge_cell} = 1;
			push @$new_map, $merge_ref;
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Updated merge areas:", $new_map] );
		}
	}
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Final merge areas:", $new_map] );
	return $new_map;
}

sub is_column_hidden{
	my( $self, @column_requests ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::is_column_hidden', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Pulling the hidden state for the columns:', @column_requests ] );

	my @result_list;
	for my $item ( @column_requests ){
		my $column;
		if( is_Int( $item ) ){
			$column = $self->get_excel_position( $item );
		}else{
			( $column, my $dummy_row ) =  $self->_parse_column_row( $item );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Parsed -$item- to column number: $column" ] );
		}
		my $column_formats = $self->get_custom_column_data( $column );
		push @result_list,
			( $column < $self->_min_col or $self->_max_col < $column ) ? undef :
			( $column_formats and exists $column_formats->{hidden}) ? $column_formats->{hidden} : 0;
	}
	my $true = 0;
	map{ $true = 1 if $_ } @result_list;
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Final column hidden state is -$true- with list:", @result_list ] );
	return wantarray ? @result_list : $true;
}

sub is_row_hidden{
	my( $self, @row_requests ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::is_row_hidden', );
	###LogSD		$phone->talk( level => 'debug', message => [
	###LogSD			'Pulling the hidden state for the rows:', [@row_requests] ] );

	my @result_list;
	for my $row ( @row_requests ){
		my $code_row = $self->get_excel_position( $row );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Sending excel row -$code_row- for used row: $row" ] );
		my $row_formats = $self->get_custom_row_data( $code_row );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Returned row formats:", $row_formats ] );
		push @result_list,
			( $code_row < $self->_min_row or $self->_max_row < $code_row ) ? undef :
			($row_formats and exists $row_formats->{hidden}) ? $row_formats->{hidden} : 0;
	}
	my $true = 0;
	map{ $true = 1 if $_ } @result_list;
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Final row hidden state is -$true- with list:", @result_list] );
	return wantarray ? @result_list : $true;
}

sub get_cell{
    my ( $self, $requested_row, $requested_column ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_cell', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at get_cell with: ",
	###LogSD			"Requested row: " . (defined( $requested_row ) ? $requested_row : ''),
	###LogSD			"Requested column: " . (defined( $requested_column ) ? $requested_column : '' ),] );

	# Ensure we have a good column and row to work from
	my( $excel_requested_column, $excel_requested_row );
	if( !defined $requested_row ){
		$self->set_error( "No row provided" );
		return undef;
	}else{
		$excel_requested_row = $self->get_excel_position( $requested_row );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Updated row to (count from 1): $excel_requested_row", ] );
	}
	if( !defined $requested_column ){
		$self->set_error( "No column provided" );
		return undef;
	}else{
		$excel_requested_column = $self->get_excel_position( $requested_column );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Updated column to (count from 1): $excel_requested_column", ] );
	}

	# Get information
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		'Requesting [ $column, $row ]: [ ' . $excel_requested_column . ', ' . $excel_requested_row . ' ]' ] );
	my $current_row = $self->go_to_or_past_row( $excel_requested_row );
	my $current_column;
	if( is_Int( $current_row ) ){
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Arrived at row: $current_row", "..searching for column: $excel_requested_column" ] );
		$current_column =
			( $current_row == $excel_requested_row ) ? $self->get_new_column( $excel_requested_column ) :
			( $self->has_max_col and $requested_column > $self->max_col) ? 'EOR' : undef ;
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Column search result: ", ($current_column//'undef') ] );
	}else{
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Requested a row past the end of the file" ] );
	}

	# Handle returns including EOF EOD and EOR flags
	my $return = undef;
	if( $current_column and is_HashRef( $current_column ) ){
		###LogSD	$phone->talk( level => 'trace', message =>[ 'Got a cell to build and return' ] );
		$return = $self->_build_out_the_cell( $current_column );
	}else{
		$return =
			$current_column ? $current_column :
			is_Int( $current_row ) ? undef : $current_row;
		###LogSD	$phone->talk( level => 'trace', message =>[ "Initial boundary flag: " . ($return//'undef') ] );
		if( $return ){# Handle some exceptions
			if( $return eq 'EOD' ){# End of data equals end of row exception
				if( $self->is_empty_the_end ){
					###LogSD	$phone->talk( level => 'trace', message =>[ "Changing End Of Data to EOR" ] );
					$return = 'EOR';
				}else{
					###LogSD	$phone->talk( level => 'trace', message =>[ "Clearing EOD" ] );
					$return = undef;
				}
			}
			#~ if( $return eq 'EOR' and $self->has_max_row and $self->max_row == $requested_row ){# EOR is EOF exception
				#~ ###LogSD	$phone->talk( level => 'trace', message =>[ "Changing EOR to EOF" ] );
				#~ $return = 'EOF';
			#~ } # Should return EOF from the file reader here?
			# Adjust reported row column
			( $excel_requested_column, $excel_requested_row ) =
				!$return ? ( $excel_requested_column, $excel_requested_row ) :
				$return eq 'EOF' ? ( 0, 0 ) :
				( 0, $excel_requested_row + 1 ) ;
		}
		# Clear boundary flags per request
		if( $return and !$self->boundary_flag_setting ){
			###LogSD	$phone->talk( level => 'trace', message =>[ "No boundary flag settings desired" ] );
			$return = undef;
		}
	}
	###LogSD	$phone->talk( level => 'trace', message =>[ "Cell search returning:", $return ] );

	$self->_set_reported_row_col( [ $excel_requested_row, $excel_requested_column ] );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Set the reported [ row, col ] to: [ $excel_requested_row, $excel_requested_column ]", ] );
	###LogSD	$phone->talk( level => 'trace', message =>[ 'Final return:', $return ] );
	return $return;
}

sub get_next_value{
    my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::get_next_value', );
	###LogSD		$phone->talk( level => 'info', message =>[ 'Arrived at get_next_value', ] );

	# Get next position
	my $next_cell;
	if( $self->has_new_row_inst ){
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Current row number: " . $self->get_new_row_number, ] );
		while( !$next_cell ){# To handle values only in a pre-cached environment
			$next_cell = $self->get_new_next_value;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		'Returned from next search with cell:', $next_cell ] );
			if( $self->get_values_only and is_HashRef( $next_cell ) and
				(	(!exists $next_cell->{cell_xml_value} and !exists $next_cell->{cell_unformatted}) or
					(exists $next_cell->{cell_xml_value} and length( $next_cell->{cell_xml_value} ) == 0 ) ) ){
				$next_cell = undef;
				###LogSD	$phone->talk( level => 'debug', message =>[ 'Deleting this cell since it is empty' ] );
			}
		}
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'No row instance currently loaded' ] );
	}
	if( !$next_cell or $next_cell eq 'EOR' ){ # Handle no current row or no cell left case
		$next_cell = undef;# Clear 'EOR'
		my $current_row = $self->go_to_or_past_row;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'Updated Row: ' . $current_row] );
		while( !$next_cell ){# To handle values only in a pre-cached environment
			$next_cell = $current_row eq 'EOF' ? 'EOF' : $self->get_new_next_value;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		'Returned from next search with cell:', $next_cell ] );

			# Handle EOF here
			if( $next_cell eq 'EOF' ){
				###LogSD	$phone->talk( level => 'debug', message =>[ 'Reached the EOF' ] );
				$self->_set_reported_row_col( [ 0, 0 ] );
				return $self->boundary_flag_setting ? $next_cell : undef;
			}

			# Skip empty cells based on get_values_only
			if( $self->get_values_only and is_HashRef( $next_cell ) and
				(	(!exists $next_cell->{cell_xml_value} and !exists $next_cell->{cell_unformatted}) or
					(exists $next_cell->{cell_xml_value} and length( $next_cell->{cell_xml_value} ) == 0 ) ) ){
				$next_cell = undef;
				###LogSD	$phone->talk( level => 'debug', message =>[ 'Deleting this cell since it is empty' ] );
			}
		}
	}

	# Build out the cell
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		'Reporting the current row col for cell:', $next_cell ] );
	$self->_set_reported_row_col( [ $next_cell->{cell_row}, $next_cell->{cell_col} ] );
	my $cell_instance = $self->_build_out_the_cell( $next_cell );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		'Built cell instance:', $cell_instance ] );

	return $cell_instance;
}

sub fetchrow_arrayref{
    my ( $self, $row ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::fetchrow_arrayref', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at fetchrow_arrayref for row: " . ((defined $row) ? $row : ''), ] );

	# Handle an implied next
	if( !defined $row ){
		my $last_row = $self->_get_reported_row;
		$row = $last_row + 1;# Even if a cell is not at the end was last reported
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD			"Resolved an implied 'next' row request to row: $row", ] );
	}else{
		$row = $self->get_excel_position( $row );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Updated row to (count from 1): $row", ] );
	}

	# Advance to the proper row
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Requesting row: $row" ] );
	my $current_row = $self->go_to_or_past_row( $row );
	###LogSD	$phone->talk( level => 'trace', message =>[
	###LogSD		"Arrived at row: $current_row" ] );

	# Pull the data
	my $result =
		(is_Int( $current_row) and $current_row == $row) ? $self->get_new_row_all :
		$current_row eq 'EOF' ? 'EOF' : undef;
	###LogSD	$phone->talk( level => 'debug', message =>[ 'Returned row ref;', $result ] );

	# Build the return
	my $return = [];
	my ( $reported_row, $reported_col ) = ( $row, undef );
	if( $result ){
		if( is_ArrayRef( $result ) ){
			for my $cell ( @$result ){
				if( is_HashRef( $cell ) ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		'Building out the cell:', $cell ] );
					$reported_col = $cell->{cell_col};

					# Skip empty cells based on get_values_only
					if( $self->get_values_only and is_HashRef( $cell ) and
						(	(!exists $cell->{cell_xml_value} and !exists $cell->{cell_unformatted}) or
							(exists $cell->{cell_xml_value} and length( $cell->{cell_xml_value} ) == 0 ) ) ){
						###LogSD	$phone->talk( level => 'debug', message =>[ 'Deleting this cell since it is empty' ] );
					}else{
						push @$return, $self->_build_out_the_cell( $cell, );
					}
				}else{
					push @$return, $cell;
				}
			}
		}else{# Handle EOF flag
			$return = $self->boundary_flag_setting ? $result : undef;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Based on boundary flag setting EOF state returning: $return" ] );
			( $reported_row, $reported_col ) = ( 0, 0 );
		}
	}else{
		$reported_col = $self->_max_col;
	}

	# Handle full rows with empty_is_end = 0
	$self->_set_reported_row_col( [ $reported_row, $reported_col ] );
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Set the reported [ row, col ] to: [ $reported_row, $reported_col ]", ] );
	###LogSD	$phone->talk( level => 'trace', message =>[ 'Final return:', $return ] );

	return $return;
}

sub fetchrow_array{
    my ( $self, $row ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::fetchrow_array', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at fetchrow_array for row: " . ((defined $row) ? $row : ''), ] );
	my $array_ref = $self->fetchrow_arrayref( $row );
	###LogSD	$phone->talk( level => 'trace', message =>[ 'Initial return:', $array_ref ] );
	my @return =
		is_ArrayRef( $array_ref ) ? @$array_ref :
		is_Str( $array_ref ) ? $array_ref : ();
	###LogSD	$phone->talk( level => 'trace', message =>[ 'Final return:', @return ] );
	return @return;
}

sub set_headers{
    my ( $self, @header_row_list ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::set_headers', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at set_headers for row: ", @header_row_list, ] );
	my $header_ref;
	$self->_clear_last_header_row;
	$self->_clear_header_ref;
	my $old_output = $self->get_group_return_type;
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Old output type: $old_output", ] );
	my $new_output = $old_output;
	if( $old_output eq 'instance' ){
		$self->set_group_return_type( 'value' );
		$new_output = 'value';
	}else{
		$old_output = undef;
	}
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"New output type: $new_output", ] );
	if( scalar( @header_row_list ) == 0 ){
		$self->set_error( "No row numbers passed to use as headers" );
		return undef;
	}
	my $last_header_row = 0;
	my $code_ref;
	for my $row ( @header_row_list ){
		if( ref( $row ) ){
			$code_ref = $row;
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD		"Found header manipulation code: ", $code_ref, ] );
			next;
		}
		$last_header_row = $row if $row > $last_header_row;
		my $array_ref = $self->fetchrow_arrayref( $row );
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Retreived header row -$row- with values: ", $array_ref, ] );
		for my $x ( 0..$#$array_ref ){
			$header_ref->[$x] = $array_ref->[$x] if !defined $header_ref->[$x];
		}
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Updated header ref: ", $header_ref, ] );
	}
	if( $code_ref ){
		my $scrubbed_headers;
		for my $header ( @$header_ref ){
			push @$scrubbed_headers, $code_ref->( $header );
		}
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"scrubbed header ref: ", $scrubbed_headers, ] );
		$header_ref = $scrubbed_headers;
	}
	$self->_set_last_header_row( $last_header_row );
	$self->_set_header_ref( $header_ref );
	$self->set_group_return_type( $old_output ) if $old_output;
	return $header_ref;
}

sub fetchrow_hashref{
    my ( $self, $row ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::fetchrow_hashref', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at fetchrow_hashref for row: " . ((defined $row) ? $row : ''), ] );
	# Check that the headers are set
	if( !$self->_has_header_ref ){
		$self->set_error( "Headers must be set prior to calling fetchrow_hashref" );
		return undef;
	}elsif( defined $row and $row <= $self->get_last_header_row ){
		$self->set_error(
			"The requested row -$row- is at or above the bottom of the header rows ( " .
			$self->get_last_header_row . ' )'
		);
		return undef;
	}
	my $array_ref = $self->fetchrow_arrayref( $row );
	return $array_ref if !$array_ref or $array_ref eq 'EOF';
	my $header_ref = $self->_get_header_ref;
	my ( $start, $end ) = ( $self->min_col, $self->max_col );
	my ( $min_col, $max_col ) = ( $self->get_min_header_col, $self->get_max_header_col );
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		((defined $min_col) ? "Minimum header column: $min_col" : undef),
	###LogSD		((defined $max_col) ? "Maximum header column: $max_col" : undef), ] );
	$min_col = ($min_col and $min_col>$start) ? $min_col - $start : 0;
	$max_col = ($max_col and $max_col<$end) ? $end - $max_col : 0;
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		((defined $min_col) ? "Minimum header column offset: $min_col" : undef),
	###LogSD		((defined $max_col) ? "Maximum header column offset: $max_col" : undef), ] );

	# Build the ref
	my $return;
	my $blank_count = 0;
	for my $x ( (0+$min_col)..($self->max_col-$max_col) ){
		my $header = defined( $header_ref->[$x] ) ? $header_ref->[$x] : 'blank_header_' . $blank_count++;
		###LogSD	$phone->talk( level => 'info', message =>[
		###LogSD		"Possibly adding value for header: $header" ] );
		if( defined $array_ref->[$x] ){
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD		"Adding value: $array_ref->[$x]" ] );
			$return->{$header} = $array_ref->[$x];
		}
	}

	return $return;
}

sub set_custom_formats{
    my ( $self, @input_args ) = @_;
	my $args;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::set_custom_formats', );
	###LogSD		$phone->talk( level => 'info', message =>[
	###LogSD			"Arrived at set_custom_formats with: ", @input_args, ] );
	my $worksheet_custom = 0;
	if( !@input_args ){
		$self->( "The input args to 'set_custom_formts' are empty - no op" );
		return undef;
	}elsif( is_HashRef( $input_args[0] ) and @input_args == 1 ){
		$args = $input_args[0];
	}elsif( @input_args % 2 == 0 ){
		$args = { @input_args };
	}else{
		$self->set_error( "Unable to coerce input args to a hashref: " . join( '~|~', @input_args ) );
		return undef;
	}
	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD			"Now acting on: ", $args ] );
	my $final_load;
	for my $key ( keys %$args ){
		my $new_coercion;
		if( $key eq '' or $key !~ /[A-Z]{0,3}(\d*)/ ){
			$self->set_error( "-$key- is not an allowed custom format key" );
			next;
		}elsif( is_Object( $args->{$key} ) ){
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD			"Key -$key- already has an object" ] );
			$new_coercion = $args->{$key};
		}else{
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD			"Trying to build a new coercion for -$key- with: $args->{$key}" ] );
			$new_coercion = $self->parse_excel_format_string( $args->{$key}, "Worksheet_Custom_" . $worksheet_custom++ );
			if( !$new_coercion ){
				$self->set_error( "No custom coercion could be built for -$key- with: $args->{$key}" );
				next;
			}
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD			"Built possible new coercion for -$key-" ] );
		}
		if( !$new_coercion->can( 'assert_coerce' ) ){
			$self->set_error( "The identified coercion for -$key- cannot 'assert_coerce'" );
		}elsif( !$new_coercion->can( 'display_name' ) ){
			$self->set_error( "The custom coercion for -$key- cannot 'display_name'" );
		}else{
			###LogSD	$phone->talk( level => 'info', message =>[
			###LogSD			"Loading -$key- with coercion: " . $new_coercion->display_name ] );
			$final_load->{$key} = $new_coercion;
		}
	}
	$self->_set_custom_format( %$final_load );
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _last_header_row =>(
		isa			=> Int,
		reader		=> 'get_last_header_row',
		writer		=> '_set_last_header_row',
		clearer		=> '_clear_last_header_row',
		predicate	=> 'header_row_set'
	);

has _custom_formats =>(
		isa		=> HashRef[ HasMethods[ 'assert_coerce', 'display_name' ] ],
		traits	=> ['Hash'],
		reader	=> 'get_custom_formats',
		default => sub{ {} },
		clearer	=> '_clear_custom_formats',
		handles	=>{
			has_custom_format => 'exists',
			get_custom_format => 'get',
			_set_custom_format => 'set',
		},
	);

has _header_ref =>(
		isa			=> ArrayRef,
		writer		=> '_set_header_ref',
		reader		=> '_get_header_ref',
		clearer		=> '_clear_header_ref',
		predicate	=> '_has_header_ref',
	);

has _reported_row_col =>(# Manage (store and retreive) in count from 1 mode
		isa		=> ArrayRef[Int],
		traits	=> ['Array'],
		writer	=> '_set_reported_row_col',
		reader	=> '_get_reported_row_col',
		default	=> sub{ [ 0, 0 ] },# Pre-row and pre-col
		handles =>{
			_get_reported_row => [ get => 0 ],
			_get_reported_col => [ get => 1 ],
		},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9

sub _build_out_the_cell{
	my ( $self, $result, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::_build_out_the_cell', );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			 "Building out the cell ref:", $result, "..with results as: ". $self->get_group_return_type, ] );
	my ( $return, $hidden_format );
	if( is_HashRef( $result ) ){
		$return->{cell_xml_value} = $result->{cell_xml_value} if exists $result->{cell_xml_value} and defined $result->{cell_xml_value};
		$return->{cell_unformatted} = $result->{cell_unformatted} if exists $result->{cell_unformatted} and defined $result->{cell_unformatted};
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"processing cell object from cell ref:", $result ] );
		my $scientific_format;
		if( !exists $return->{cell_unformatted} and exists $return->{cell_xml_value} and  #Implement implied output formatting intrensic to Excel for scientific notiation
			$return->{cell_xml_value} =~ /^(\-)?((\d{1,3})?(\.\d+)?)[Ee](\-)?(\d+)$/ and $2 and $6 and $6 < 309){# Maximum Excel value 1.79769313486232E+308 -> https://support.microsoft.com/en-us/kb/78113
			#~ warn $return->{cell_xml_value};
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Found special scientific notation case were stored values and visible values possibly differ" ] );
			my	$dec_sign = $1 ? $1 : '';
			my	$decimal = $2;
			my	$exp_sign = $5 ? $5 : '';
			my	$exponent = $6;
				$decimal = sprintf '%.14f', $decimal;
			$decimal =~ /([1-9])?\.(.*[1-9])?(0*)$/;
			my	$last_sig_digit =
					!$2         ? 0 :
					defined $3 ? 14 - length( $3 ) : 14 ;
			my $initial_significant_digits = length( $exp_sign ) > 0 ? ($last_sig_digit + $exponent) : ($last_sig_digit - $exponent);
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Processing decimal                          : $decimal",
			###LogSD		"Final significant digit of the decimal is at: $last_sig_digit",
			###LogSD		"Total significant digits                    : $initial_significant_digits", ] );
			if( $initial_significant_digits > 19 ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Attempting to use sprintf: %.${last_sig_digit}f", ] );
				$return->{cell_unformatted}  = $dec_sign . sprintf "%.${last_sig_digit}f", $decimal;
				$return->{cell_unformatted} .= 'E' . $exp_sign . sprintf '%02d', $exponent;
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Found the unformatted scientific notation case with result: $return->{cell_unformatted}"] );
			}else{
				#~ warn $initial_significant_digits if $initial_significant_digits < 0;# Uncomment here and26 lines up to validate the test 05-bad_xml_example_bug.t
				$initial_significant_digits = $initial_significant_digits > -1 ? $initial_significant_digits : 0 ;# Fix 05-bad_xml_example_bug.t bug
				###LogSD	$phone->talk( level => 'info', message =>[
				###LogSD		"Attempting to use sprintf: %.${initial_significant_digits}f", ] );
				$return->{cell_unformatted} = sprintf "%.${initial_significant_digits}f", $return->{cell_xml_value};
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Found the unformatted decimal case with output: $return->{cell_unformatted}"] );
			}
			my	$short_decimal = sprintf '%.5f', $decimal;
				$short_decimal =~ /([1-9])?\.(.*[1-9])?(0*)$/;
			my	$short_sig_digit =
					!$2         ? 0 :
					defined $3 ? 5 - length( $3 ) : 5 ;

			$scientific_format =
				( $initial_significant_digits < 10  ) ? SpecialDecimal :
				( $short_sig_digit == 0 ) ? SpecialZeroScientific :
				( $short_sig_digit == 1 ) ? SpecialOneScientific :
				( $short_sig_digit == 2 ) ? SpecialTwoScientific :
				( $short_sig_digit == 3 ) ? SpecialThreeScientific :
				( $short_sig_digit == 4 ) ? SpecialFourScientific :
				( $short_sig_digit == 5 ) ? SpecialFiveScientific :
					SpecialZeroScientific ;
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Resolved the final formatted output to formatter: " . $scientific_format->display_name ] );
		}

		$return->{cell_type} = $result->{cell_type};
		$return->{r} = $result->{r};
		$return->{cell_merge} = $result->{cell_merge} if exists $result->{cell_merge};
		$return->{cell_hidden} = $result->{cell_hidden} if exists $result->{cell_hidden};
		if( !exists $return->{cell_unformatted} and exists $result->{cell_xml_value} ){
			@$return{qw( cell_unformatted rich_text )} = @$result{qw( cell_xml_value rich_text )};
			delete $return->{rich_text} if !$return->{rich_text};
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"No crazy number stuff the unformatted value is: $return->{cell_unformatted}"] );
		}

		#Implement user defined changes in encoding
		###LogSD	$phone->talk( level => 'debug', message =>[ "Current cell: ", $return ] );
		if( $return->{cell_unformatted} and length( $return->{cell_unformatted} ) > 0 ){
			$return->{cell_unformatted} = $self->change_output_encoding( $return->{cell_unformatted} );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Unformatted with output encoding changed: " . $return->{cell_unformatted} ] );# if defined $return->{cell_unformatted};
		}
		if( $self->get_group_return_type eq 'unformatted' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Sending back just the unformatted value: " . ($return->{cell_unformatted}//'') ] ) ;
			return $return->{cell_unformatted};
		}
		if( $return->{cell_xml_value} and length( $return->{cell_xml_value} ) > 0 ){#Implement user defined changes in encoding
			$return->{cell_xml_value} = $self->change_output_encoding( $return->{cell_xml_value} );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"XML with output encoding changed: " . $return->{cell_xml_value} ] );# if defined $return->{cell_unformatted};
		}
		if( $self->get_group_return_type eq 'xml_value' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Sending back just the unformatted value: " . ($return->{cell_xml_value}//'') ] ) ;
			return $return->{cell_xml_value};
		}

		# Get any relevant custom format
		my	$custom_format;
		if( $self->has_custom_format( $result->{r} ) ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Custom format exists for: $result->{r}",] );
			$custom_format = $self->get_custom_format( $result->{r} );
		}else{
			$result->{r} =~ /([A-Z]+)(\d+)/;
			my ( $col_letter, $excel_row ) = ( $1, $2 );
			if( $self->has_custom_format( $col_letter ) ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Custom format exists for column: $col_letter",] );
				$custom_format = $self->get_custom_format( $col_letter );
			}elsif( $self->has_custom_format( $excel_row ) ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Custom format exists for row: $excel_row",] );
				$custom_format = $self->get_custom_format( $excel_row );
			}
		}

		# Initial check for return of value only (custom format case)
		if( $custom_format ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		'Cell custom_format is:', $custom_format ] );
			if( $self->get_group_return_type eq 'value' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		'Applying custom format to: ' .  $return->{cell_unformatted} ] );
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		'Returning value coerced by custom format:', $custom_format ] );
				return	Spreadsheet::Reader::ExcelXML::Cell->_return_value_only(
							$return->{cell_unformatted},
							$custom_format,
							$self->get_error_inst,
				###LogSD	$self->get_log_space . '::Cell::_hidden::_return_value_only',
						);
			}
			$return->{cell_coercion} = $custom_format;
			$return->{cell_type} = 'Custom';
		}

		# handle the formula
		if( exists $result->{cell_formula} and defined $result->{cell_formula} and length( $result->{cell_formula} ) > 0 ){
			$return->{cell_formula} = $result->{cell_formula};
		}

		# convert the row column to user defined
		$return->{cell_row} = $self->get_used_position( $result->{cell_row} );
		$return->{cell_col} = $self->get_used_position( $result->{cell_col} );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Cell args to this point:", $return] );

		if( exists $result->{s} ){
			my $header = ($self->get_group_return_type eq 'value') ? 'cell_coercion' : undef;
			my $exclude_header = ($custom_format) ? 'cell_coercion' : undef;
			my $format;
			if( $header and $exclude_header and $header eq $exclude_header ){
				###LogSD	$phone->talk( level => 'info', message =>[
				###LogSD		"It looks like you just want to just return the formatted value but there is already a custom format" ] );
			}elsif( $self->has_styles_interface ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Pulling formats with:", $result->{s}, $header, $exclude_header,	] );
				$format = $self->get_format( $result->{s}, $header, $exclude_header );
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"format is:", $format ] );
			}else{
				$self->set_error( "'s' element called out but the style file is not available!" );
			}
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Checking if the defined number format needs replacing with:", $custom_format, $scientific_format] );
			if( $custom_format ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Custom formats override this cell", $custom_format->display_name] );
				delete $format->{cell_coercion};
			}elsif( $scientific_format and
						(	!exists $format->{cell_coercion} or
							$format->{cell_coercion}->display_name eq 'Excel_number_0' or
							$format->{cell_coercion}->display_name eq 'Excel_text_0'		) ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"The generic number case will implement a hidden scientific format", $scientific_format] );
				$return->{cell_coercion} = $scientific_format;
				delete $format->{cell_coercion};
			}
			# Second check for value only - for the general number case not just custom formats
			if( $self->get_group_return_type eq 'value' ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		'Applying (a possible) regular format to: ' .  ($return->{cell_unformatted}//''), $return, $format ] );
				return	Spreadsheet::Reader::ExcelXML::Cell->_return_value_only(
							$return->{cell_unformatted},
							$return->{cell_coercion} // $format->{cell_coercion},
							$self->get_error_inst,
				###LogSD	$self->get_log_space . '::Cell::_hidden::_return_value_only',
						);
			}
			if( $self->has_styles_interface ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Format headers are:", $format_headers ] );
				for my $header ( @$format_headers ){
					if( exists $format->{$header} ){
						###LogSD	$phone->talk( level => 'trace', message =>[
						###LogSD		"Transferring styles header -$header- to the cell", ] );
						$return->{$header} = $format->{$header};
						if( $header eq 'cell_coercion' ){
							if(	$return->{cell_type} eq 'Numeric' and
								$format->{$header}->name =~ /date/i){
								###LogSD	$phone->talk( level => 'trace', message =>[
								###LogSD		"Found a -Date- cell", ] );
								$return->{cell_type} = 'Date';
							}
						}
					}
				}
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		"Practice special old spreadsheet magic here as needed - for now only single quote in the formula bar",  ] );
				if( exists $format->{quotePrefix} ){
					###LogSD	$phone->talk( level => 'debug', message =>[
					###LogSD		"Found the single quote in the formula bar case",  ] );# Other similar cases include carat and double quote in the formula bar (middle and right justified)
					$return->{cell_alignment}->{horizontal} = 'left';
					$return->{cell_formula} = $return->{cell_formula} ? ("'" . $return->{cell_formula}) : "'";
				}

			}
		}
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Checking if a scientific format should be used", $scientific_format] );
		if( $scientific_format and !exists $return->{cell_coercion} ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"The generic number case will implement a hidden scientific format", $scientific_format] );
			$return->{cell_coercion} = $scientific_format;
		}

		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"Checking return type: " . $self->get_group_return_type,  ] );
		# Final check for value only - for the text case
		if( $self->get_group_return_type eq 'value' ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		'Applying (a possible) regular format to: |' .  ($return->{cell_unformatted}//'') . '|' ] );
			return	Spreadsheet::Reader::ExcelXML::Cell->_return_value_only(
						$return->{cell_unformatted},
						$return->{cell_coercion},
						$self->get_error_inst,
			###LogSD	$self->get_log_space . '::Cell::_hidden::_return_value_only',
					);
		}
		$return->{error_inst} = $self->get_error_inst;
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Current args ref is:", $return] );
	}elsif( $result ){
		confess "I don't know how I got here: $result";
	}

	# build a cell
	delete $return->{cell_coercion} if !$return->{cell_coercion};#
	###LogSD	$return->{log_space} = $self->get_log_space;
	###LogSD	$phone->talk( level => 'debug', message =>[
	###LogSD		"Building cell with:", $return] );
	my $cell = Spreadsheet::Reader::ExcelXML::Cell->new( %$return );
	###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Cell is:", $cell ] );
	return $cell;
}

sub DEMOLISH{
	my ( $self ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::_hidden::DEMOLISH', );
    ###LogSD	if( $self->_has_name ){
    ###LogSD		$phone->talk( level => 'debug', message =>[
	###LogSD			"Cleaning up worksheet: " . $self->get_name ] );
    ###LogSD	}
	if( $self->has_file ){
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Need to clear the file" ] );
		$self->clear_file;
		###LogSD	$phone->talk( level => 'debug', message =>[ "File cleared" ] );
	}
}

#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::Worksheet - Top level Worksheet interface

=head1 SYNOPSIS

	use strict;
	use warnings;
	use Data::Dumper;

	use Spreadsheet::Reader::ExcelXML;
	my $workbook =	Spreadsheet::Reader::ExcelXML->new( #similar style to Spreadsheet::XLSX
						file => 't/test_files/TestBook.xlsx',# in the test folder of this package
						group_return_type => 'value',
					);

	if ( !$workbook->file_opened ) {
		die $workbook->error(), ".\n";
	}

	my	$worksheet = $workbook->worksheet( 'Sheet5' );
		$worksheet->set_custom_formats( {
			2 =>'yyyy-mm-dd',
		} );
	my $value;
	while( !$value or $value ne 'EOF' ){
		$value = $worksheet->fetchrow_arrayref;
		print Dumper( $value );
	}

	###########################
	# SYNOPSIS Output
	# $VAR1 = [ 'Superbowl Audibles', 'Column Labels' ];
	# $VAR1 = [         'Row Labels',     2016-02-06', '2017-02-14', '2018-02-03', 'Grand Total' ];
	# $VAR1 = [               'Blue',            '10',          '7',           '',          '17' ];
	# $VAR1 = [              'Omaha',              '',           '',          '2',           '2' ];
	# $VAR1 = [                'Red',            '30',          '5',          '3',          '38' ];
	# $VAR1 = [        'Grand Total',            '40',         '12',          '5',          '57' ];
	# $VAR1 = 'EOF';
	###########################


The best example for use of this module alone is the test file in this package
t/Spreadsheet/Reader/ExcelXML/10-worksheet.t

=head1 DESCRIPTION

This module is the worksheet interface.  Even thought it will not provide all worksheet
access itself it's role is to manage a consistent way of parsing Excel worksheets.  If
the sheet/tab is a 'chartsheet' then please review the documentation for L<Chartsheets
|Spreadsheet::Reader::ExcelXML::Chartsheet>. The documentation in this file will include
all publicly accesable elements.  This include elements provided through other roles and
the base class.  The purpose of this instance is to extract worksheet level formats and
cell level content for parsing. The workbook also has several L<Settings
|Spreadsheet::Reader::ExcelXML/Attributes> that affect the outcome of methods from this
interface.  For example the workbook level attribute setting
L<Spreadsheet::Reader::ExcelXML/count_from_zero> will directly affect how this data is
returned when retreiving cell data.  Please review all workbook level attribute
documentation for information covering those possibilities.  It is best to generate a
worksheet instance from the workbook class using one of the various L<worksheet
|Spreadsheet::Reader::ExcelXML/worksheet( $name )> methods.

=head2 Modification of this Interface

The final worksheet instance provided by this package is an amalgam of a base class and a
few roles aggregated at run time based on attribute settings from the workbook level
class.  The easiest way to modify behaviour in this instance is to build an additional
or replacement element and have it built into the interface by the workbook.   The
settings for this type of injection/adjustement are stored in the raw code of
L<Spreadsheet::Reader::ExcelXML::Workbook> within the 'worksheet_interface' key of the
$parser_modules variable.  The file t/Spreadsheet/Reader/ExcelXML/10-worksheet.t
in the distribution represents a good 'under the hood' example of the way all the elements
are integrated into the larger worksheet class as a whole.

=head2 Methods

These are the various functions that are available to extract cell (values) to read or
to extract worksheet level formats. There are several different methods provided to
extract the same content in different ways.  All the methods are object methods performed
on the worksheet.

B<Example:>

	my $cell_data = $worksheet->get_cell( $row, $column );

=head3 min_row

=over

B<Definition:> This is the minimum row determined when the sheet is opened.  This
value is affected by the workbook attributes
L<from_the_edge|Spreadsheet::Reader::ExcelXML/from_the_edge>, and
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero>

B<Accepts:> nothing

B<Returns:> an integer $row

=back

=head3 has_min_row

=over

B<Definition:> The L<predicate|Moose::Manual::Attributes/Predicate and clearer methods>
of min_row

=back

=head3 max_row

=over

B<Definition:> This is the maximum row with data listed in the sheet.  This value
is affected by the workbook attribute
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero>. B<Warning:
This value is extracted from the sheet metadata, however if your sheet has been
damaged or 'adjusted' by non-microsoft code (This is more common than you would think
in the data processing world) then this value may be wrong or missing when the sheet
is first opened.  The goal of this package is to minimize memory consumption so it
will learn what the correct value is over the first pass through the sheet as you
collect data but it does not attempt to validate this value in detail initially. If
you have an idea of the range for a damaged sheet before you open it you can use
L<EOF|change_boundary_flag( $Bool )> flags.  Otherwise the methods
L<get_next_value|/get_next_value> or L<fetchrow_arrayref|/fetchrow_arrayref> are
recomended.>

B<Accepts:> nothing

B<Returns:> an integer

=back

=head3 has_max_row

=over

B<Definition:> The L<predicate|Moose::Manual::Attributes/Predicate and clearer methods>
of max_row

=back

=head3 row_range

=over

B<Definition:> This returns a list containing the minimum row number followed
by the maximum row number.  This list is affected by the workbook attributes
L<from_the_edge|Spreadsheet::Reader::ExcelXML/from_the_edge>, and
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero> B<Warning:
This result is extracted from the sheet metadata, however if your sheet has been
damaged or 'adjusted' by non-microsoft code (This is more common than you would think
in the data processing world) then the return list may be wrong or missing when the
sheet is first opened.  The goal of this package is to minimize memory consumption so it
will learn what the correct list is over the first pass through the sheet as you
collect data but it does not attempt to validate this list in detail initially. If
you have an idea of the range for a damaged sheet before you open it you can use
L<EOR-EOF|change_boundary_flag( $Bool )> flags.  Otherwise the methods
L<get_next_value|/get_next_value> or L<fetchrow_arrayref|/fetchrow_arrayref> are
recomended.>  For missing values the minimum is set to the first row and the maximum
is set to undef.

B<Accepts:> nothing

B<Returns:> ( $minimum_row, $maximum_row )

=back

=head3 min_col

=over

B<Definition:> This is the minimum column with data listed in the sheet.  This value
is affected by the workbook attributes
L<from_the_edge|Spreadsheet::Reader::ExcelXML/from_the_edge>, and
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero>

B<Accepts:> nothing

B<Returns:> an integer

=back

=head3 has_min_col

=over

B<Definition:> The L<predicate|Moose::Manual::Attributes/Predicate and clearer methods>
of min_col

=back

=head3 max_col

=over

B<Definition:> This is the maximum row with data listed in the sheet.  This value
is affected by the workbook attribute
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero> B<Warning:
This value is extracted from the sheet metadata, however if your sheet has been
damaged or 'adjusted' by non-microsoft code (This is more common than you would think
in the data processing world) then this value may be wrong or missing when the sheet
is first opened.  The goal of this package is to minimize memory consumption so it
will learn what the correct value is over the first pass through the sheet as you
collect data but it does not attempt to validate this value in detail initially. If
you have an idea of the range for a damaged sheet before you open it you can use
L<EOR|change_boundary_flag( $Bool )> flags.  Otherwise the methods
L<get_next_value|/get_next_value> or L<fetchrow_arrayref|/fetchrow_arrayref> are
recomended.>

B<Accepts:> nothing

B<Returns:> an integer

=back

=head3 has_max_col

=over

B<Definition:> The L<predicate|Moose::Manual::Attributes/Predicate and clearer methods>
of max_col

=back

=head3 col_range

=over

B<Definition:> This returns a list containing the minimum column number followed
by the maximum column number.  This list is affected by the workbook attributes
L<from_the_edge|Spreadsheet::Reader::ExcelXML/from_the_edge>, and
L<count_from_zero|Spreadsheet::Reader::ExcelXML/count_from_zero>

B<Accepts:> nothing

B<Returns:> ( $minimum_column, $maximum_column )

=back

=head3 get_merged_areas

=over

B<Definition:> This method returns an array ref of cells that are merged.  This method does
respond to the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero> B<Warning:
This result is extracted from the sheet metadata for 2007+ Excel files, however if you
are parsing an Excel 2003 xml file this data is stored at the cell level.  Since this
parser reads the data 'Just In Time' it will not know about a set of merged cells until the
upper left cell of the group has been read.>

B<Accepts:> nothing

B<Returns:> An arrayref of arrayrefs of merged areas or undef if no merged areas

	[ [ $start_row_1, $start_col_1, $end_row_1, $end_col_1], etc.. ]

=back

=head3 is_column_hidden

=over

B<Definition:> Method indicates if the excel program would hide the identified column(s) or show
it|them if the file were opened in the Microsoft Excel application.  If more than one column is
passed then it returns true if any of the columns are hidden in scalar context and a list of
1 and 0 values for each of the requested positions in array (list) context.  This method (input)
does respond to the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero>.  For 2003
xml files this data is stored at the cell level so the parser will not 'know' until you have
read (past) the cell.

B<Accepts:> integer values or column letter values selecting the columns in question

B<Returns:> in scalar context it returns a boolean value indicating if any of the requested
columns would be hidden by Excel.  In array/list context it returns a list of boolean values
for each requested column indicating it's hidden state for Excel. (1 = hidden)

B<Examples:> (Indicating the 3rd and 4th of 6 columns are hidden)


	$worksheet_instance->is_column_hidden( 0 .. 5 ),
	###########################
	# Example Output
	# [ 0, 0, 1, 1, 0, 0 ]
	###########################

	$worksheet_instance->is_column_hidden( 'A', 'B', 'C', 'D', 'E', 'F' )
	###########################
	# Example Output
	# [ 0, 0, 1, 1, 0, 0 ]
	###########################

=back

=head3 is_row_hidden

=over

B<Definition:> Method indicates if the excel program would hide the identified row(s) or show
it|them if the file were opened in the Microsoft Excel application.  If more than one row is
passed then it returns true if any of the rows are hidden in scalar context and a list of
1 and 0 values for each of the requested positions in array (list) context.  This method (input)
does respond to the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero>.  B<Warning:
This method will only be accurate after the user has read at least one cell from or past the row
inspected for it's hidden state.  This allows the sheet to avoid reading all the way through once
before starting the cell parsing.>

B<Accepts:> integer values selecting the rows in question

B<Returns:> in scalar context it returns a boolean value indicating if any of the requested
rows would be hidden by Excel.  In array/list context it returns a list of boolean values
for each requested row indicating it's hidden state for Excel. (1 = hidden)

=back

=head3 get_cell( $row, $column )

=over

B<Definition:> Indicate both the requested row and requested column and the information for
that position will be returned.  Both $row and $column are required

B<Accepts:> the list ( $row, $column ) both required  See the attribute
L<Spreadsheet::Reader::ExcelXML/count_from_zero> to understand which row and column
are returned for $row and $colum.

B<Returns:> see the attribute L<Spreadsheet::Reader::ExcelXML/group_return_type> for
details on what is returned

=back

=head3 get_next_value

=over

B<Definition:> Reading left to right and top to bottom this will return the next cell with
a value.  This can includes cells with no value but some unique formatting such as
cells that have been merged with other cells.  See the attributes
L<Spreadsheet::Reader::ExcelXML/values_only> and
L<Spreadsheet::Reader::ExcelXML/spaces_are_empty> for more information.

B<Accepts:> nothing

B<Returns:> see the attribute L<Spreadsheet::Reader::ExcelXML/group_return_type> for
details on what is returned

=back

=head3 fetchrow_arrayref( $row )

=over

B<Definition:> In an homage to L<DBI> I included this function to return an array ref of
the cells or values in the requested $row.  If no row is requested this returns the 'next'
row.  In the array ref any empty cell will show as 'undef'.

B<Accepts:> undef = next|$row = a row integer indicating the desired row  See the attribute
L<Spreadsheet::Reader::ExcelXML/count_from_zero> to understand which row is returned for $row.

B<Returns:> an array ref of all possible column positions in that row with data filled in
per the attribute L<Spreadsheet::Reader::ExcelXML/group_return_type>.

=back

=head3 fetchrow_array( $row )

=over

B<Definition:> This function is just like L<fetchrow_arrayref|/fetchrow_arrayref( $row )>
except it returns an array instead of an array ref

B<Accepts:> undef = next|$row = a row integer indicating the desired row.  See the attribute
L<Spreadsheet::Reader::ExcelXML/count_from_zero> to understand which row is returned for $row.

B<Returns:> an array ref of all possible column positions in that row with data filled in
per the attribute L<Spreadsheet::Reader::ExcelXML/group_return_type>.

=back

=head3 set_headers( @header_row_list, [ \&header_scrubber ] )

=over

B<Definition:> This function is used to set headers used in the function
L<fetchrow_hashref|/fetchrow_hashref( $row )>.  It accepts a list of row numbers that
will be collated into a set of headers used to build the hashref for each row.
The header rows are coallated in sequence with the first position taking precedence.
The list is also used to set the lowest row of the headers in the table.  All rows
at that level and higher will be considered out of the table and will return undef
while setting the error instance.  If some of the header columns do not have values
then the instance will auto generate unique headers for each empty header column to
fill out the header ref. [ optionally: it is possible to pass a coderef at the end of
the list to scrub the headers so they make some sense.] When the headers are loaded
the top level information row of any pull for 'fetchrow_hashref' will be considered
the first row after the header row.  Any header build will not be tested again during
fetchrow_hashref the content columns will be matched to the header columns by position.
for example;

	my $scrubber = sub{
		my $input = $_[0];
		$input =~ s/\n//g if $input;
		$input =~ s/\s/_/g if $input;
		return $input;
	};
	$self->set_headers( 2, 1, $scrubber ); # Called internally as $new_value = $scrubber->( $old_value );
	# Returns/stores the headers set at row 2 and 1 with values from row 2 taking precedence
	#  Then it scrubs the values by removing newlines and replacing spaces with underscores.

B<Accepts:> a list of row numbers (modified as needed by the attribute state of
L<Spreadsheet::Reader::ExcelXML/count_from_zero>) and an optional L<closure
|http://www.perl.com/pub/2002/05/29/closure.html>.  See the attribute
L<Spreadsheet::Reader::ExcelXML/count_from_zero> to understand which rows are
used when the @header_row_list is called.

B<Returns:> an array ref of the built headers for review.

=back

=head3 get_last_header_row

=over

B<Definition:> This returns the final row of headers in the sheet.  The return value is
in the context of the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero>.  It is
determined by the function 'set_headers'.

B<Accepts:> nothing

B<Returns:> the last (largest) row number used in the coallated header.

=back

=head3 header_row_set

=over

B<Definition:> This predicate will indicate if any header build has occured from the
method 'set_headers'.

B<Accepts:> nothing

B<Returns:> Boolean on off for set headers (1 = headers are set)

=back

=head3 fetchrow_hashref( $row )

=over

B<Definition:> This function is used to return a hashref representing the data in the
specified row.  If no $row value is passed it will return the 'next' row of data.  A call
to this function without L<setting|/set_headers( @header_row_list )> the headers first
will return 'undef' and set the error instance.

B<Accepts:> a target $row number for return values or undef meaning 'next'  See the
attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero> to understand which rows
are targeted by $row.

B<Returns:> a hash ref of the values for that row.  This function ignores the attribute
L<group_return_type|Spreadsheet::Reader::ExcelXML/group_return_type> when it is
set to 'instance' and returns 'value's instead.  See also the attributes
L<min_header_col|/min_header_col> and L<max_header_col|/max_header_col> to pare the
start and end columns of the returned hash ref.

=back

=head3 set_custom_formats( $format_ref )

=over

B<Definition:> This package will generate value conversions that generally match the
numerical conversions set in the Excel spreadsheet.  However, it may be that you want
to convert the unformatted values for certain cells, rows, or columns in some user
defined way.  The simplest way to do this is by storing an
L<Excel custom number format string
|https://support.office.com/en-au/article/Create-or-delete-a-custom-number-format-78f2a361-936b-4c03-8772-09fab54be7f4>
in this instance using 'set_custom_formats' against either a CellID, a Row Number, or a
Column letter. As an example you could say;

	$worksheet->set_custom_formats( {
	    A => '# ?/?',
	} );

And any subsequent call for a $cell->value from column 'A' will attempt to convert the
raw xml contents of that cell to an integer and fraction combination with one position
in the denominator or less (an integer only).  If the cell is text then it will act as
a pass-through.  Where there is overlap between the formats the instance will select
one based on the following priority; cellID, column letter, row number.

For the truly adventurous you can build an object instance that has the two following
methods; 'assert_coerce' and 'display_name'.  Then add it to the attribute as above.

=over

B<A Complicated Example:> Building a converter on the fly from L<Type::Tiny
|Type::Tiny::Manual::Libraries> (or use L<MooseX::Types>)

	use DateTimeX::Format::Excel;
	use DateTime::Format::Flexible;
	use Type::Coercion;
	use Type::Tiny;
	my @args_list  = ( system_type => 'apple_excel' );
	my $num_converter  = DateTimeX::Format::Excel->new( @args_list );

	# build conversion subroutines (number and strings to DateTime objects)
	my $string_via = sub{
	      my $str = $_[0];
	      return DateTime::Format::Flexible->parse_datetime( $str );
	};
	my $num_via	= sub{
	      my $num = $_[0];
	      return $num_converter->parse_datetime( $num );
	};

	# Combine conversion subroutines into a coercion object!
	#  (Note numbers are attempted first)
	my $date_time_from_value = Type::Coercion->new(
		type_coercion_map => [ Num, $num_via, Str, $string_via, ],
	);

	# Install the coercion in a type that ensures it passes through a DateTime check
	$date_time_type = Type::Tiny->new(
	   name       => 'Custom_date_type',
	   constraint => sub{ ref($_) eq 'DateTime' },
	   coercion   => $date_time_from_value,
	);

	# Chained coercions! to handle first the $date_time_from_value coercion
	#    and then build a specific date string output
	$string_type = Type::Tiny->new(
	   name       => 'YYYYMMDD',
	   constraint => sub{
	      !$_ or (
	         $_ =~ /^\d{4}\-(\d{2})-(\d{2})$/ and
	         $1 > 0 and $1 < 13 and $2 > 0 and $2 < 32
	      )
	   },
	   coercion => Type::Coercion->new(
	   type_coercion_map =>[
	      $date_time_type->coercibles, sub{
	         my $tmp = $date_time_type->coerce( $_ );
	         $tmp->format_cldr( 'yyyy-MM-dd' )
	      },
	   ],
	), );

	# Then set the coercions in the worksheet for targeted positions
	$worksheet->set_custom_formats( {
	    E10 => $date_time_type,
	    10  => $string_type,
	    D14 => $string_type,
	} );

=back

B<Accepts:> a set of $key => $value pairs where the $key can either be a
row number, a column letter, or a cell ID.  The $value must either be a
string that complies with excel custom number formatting conventions or
an object instance with two methods 'display_name' and 'assert_coerce'.

B<Returns:> nothing

=back

=head3 has_custom_format( $key )

=over

B<Definition:> This is a test to see if a custom format is stored for $key.

B<Accepts:> $key

B<Returns:> a boolean where 1 = formats exist

=back

=head3 get_custom_format( $key )

=over

B<Definition:> This will retrieve the $value_ref of the custom format stored
against the given $key.  For formats saved as Excel custom format strings this
will return a package built object instance that performs the conversion
indicated by the custom format string.

B<Accepts:> $key

B<Returns:> a $value_ref for the stored format object

=back

=head3 get_custom_formats

=over

B<Definition:> This returns a hashref of all stored custom formats

B<Accepts:> nothing

B<Returns:> a hashref of all custom formats

=back

=head2 Attributes

These are attributes of the built instance.  Most of these are provided as metadata for
the specific parsed sheet and should be provided by the object that builds the worksheet
instance.  (The workbook)  However, a few can be set after worksheet creation to affect the
data retreival results.  These attributes are presented first. The end of the list is the
attribute that stores a reference to the workbook.  Follow the link in thats attribute
documentation to learn a tricksy way to adjust several workbook level settings with the
worksheet instance.

=head3 min_header_col

=over

B<Definition:> This attribute affects the hashref that is returned in the method
L<fetchrow_hashref|/fetchrow_hashref( $row )>.    This attribute tells fetchrow_hashref
what column to use to start the hash ref build.  This attribute (input)
does respond to the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero>.

B<Default:> undef (which is equivalent to the minimum column of the sheet)

B<Range:> The minimum column of the sheet to or less than the
L<max_header_col|/max_header_col>

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_min_header_col>

=over

B<Definition:> returns the value stored in the attribute

=back

B<set_min_header_col>

=over

B<Definition:> Sets a new value for the attribute

=back

B<has_min_header_col>

=over

B<Definition:> Indicates if the attribute has a stored value

=back

=back

=back

=head3 max_header_col

=over

B<Definition:> This attribute affects the hashref that is returned in the method
L<fetchrow_hashref|/fetchrow_hashref( $row )>.  This attribute tells fetchrow_hashref
what column to use to end the hash ref build.  This attribute (input) does respond to
the attribute L<Spreadsheet::Reader::ExcelXML/count_from_zero>.

B<Default:> undef (equal to the maximum column of the sheet)

B<Range:> The maximum column of the sheet to or less than the
L<min_header_col|/min_header_col>

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_max_header_col>

=over

B<Definition:> returns the value stored in the attribute

=back

B<set_max_header_col>

=over

B<Definition:> Sets a new value for the attribute

=back

B<has_max_header_col>

=over

B<Definition:> Indicates if the attribute has a stored value

=back

=back

=back

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
the file instance and should lock the file)

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

=head3 sheet_type

=over

B<Definition:> This is the sheet 'type' which will always be 'worksheet'
(as opposed to chartsheet)

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_sheet_type>

=over

B<Definition:> returns the value stored in the attribute (worsheet)

=back

=back

=back

=head3 sheet_rel_id

=over

B<Definition:> This is the relId of the sheet listed in the XML of the .xlsx file.
You probably don't care and you should never set this value.

B<attribute methods> Methods provided to adjust this attribute

=over

B<rel_id>

=over

B<Definition:> returns the value stored in the attribute

=back

=back

=back

=head3 sheet_id

=over

B<Definition:> This is the Id of the sheet listed in the XML of the .xlsx file.
I beleive this to be the number used in vbscript to reference the sheet.  You
should never set this value.

B<attribute methods> Methods provided to adjust this attribute

=over

B<sheet_id>

=over

B<Definition:> returns the value stored in the attribute

=back

=back

=back

=head3 sheet_position

=over

B<Definition:> This is the visual sheet position in the .xlsx file.
You should never set this value.

B<attribute methods> Methods provided to adjust this attribute

=over

B<position>

=over

B<Definition:> returns the value stored in the attribute

=back

=back

=back

=head3 sheet_name

=over

B<Definition:> This is the visual sheet name in the .xlsx file
on the tab.  You should never set this value.

B<attribute methods> Methods provided to adjust this attribute

=over

B<get_name>

=over

B<Definition:> returns the value stored in the attribute

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

B<Default:> a Spreadsheet::Reader::ExcelXML::Workbook instance

B<attribute methods> Methods used to change the workbook instance

=over

B<set_workbook_inst>

=over

B<Definition:> Sets the attribute with a new workbook instance

=back

=back

B<Delegated attribute methods> Since this list can float please L<follow the link
|Spreadsheet::Reader::ExcelXML::XMLReader/Delegated Methods (required)>
to the documented delegations in that file.

=back

=head1 SUPPORT

=over

L<github Spreadsheet::Reader::ExcelXML/issues
|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>

=back

=head1 TODO

=over

B<1.> Nothing L<Yet|https://github.com/jandrew/p5-spreadsheet-reader-excelxml/issues>!

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

#########1#########2 main pod documentation end  5#########6#########7#########8#########9
