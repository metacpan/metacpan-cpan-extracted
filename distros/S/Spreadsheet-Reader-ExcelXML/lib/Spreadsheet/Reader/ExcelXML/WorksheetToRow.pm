package Spreadsheet::Reader::ExcelXML::WorksheetToRow;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.16.8');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::Reader::ExcelXML::WorksheetToRow-$VERSION";

use	5.010;
use	Moose::Role;
requires qw(
		not_end_of_file				advance_row_position		close_the_file
		build_row_data				start_the_file_over
	);#		current_row_node_parsed
use Clone 'clone';
use Carp qw( confess );
use Types::Standard qw(
		InstanceOf		ArrayRef		Maybe			HashRef
		Bool			Int
    );
use MooseX::ShortCut::BuildInstance qw ( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use lib	'../../../../lib';
###LogSD	use Log::Shiras::Telephone;

use Spreadsheet::Reader::ExcelXML::Row;
#~ use Data::Dumper;
#########1 Dispatch Tables & Package Variables    5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

has cache_positions =>(
		isa		=> Bool,
		reader	=> 'should_cache_positions',
		default	=> 1,
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub go_to_or_past_row{# Counting from 1!
	my( $self, $target_row ) = @_;
	my $current_row = $self->has_new_row_inst ? $self->get_new_row_number : 0;
	my $max_known_row = $self->_max_row_position_recorded - 1;# The array has position 0
	$target_row //= $current_row + 1;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::WorksheetToRow::go_to_or_past_row', );
	###LogSD		$phone->talk( level => 'info', message => [
	###LogSD			"Indexing the row forward to find row: $target_row",
	###LogSD			"From current row: $current_row",
	###LogSD			"..with max known row: $max_known_row",
	###LogSD			"..with position caching set to: " . $self->should_cache_positions ] );

	# Handle fully cached files with requested EOF here
	if( !$self->has_file and $target_row > $max_known_row ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD			"Having already processed the whole file requested row -$target_row- doesn't exist" ] );
		$self->_clear_new_row_inst;
		return 'EOF';
	}

	# Handle the known range of rows (by number only)
	my $fast_forward;
	my $next_known_target = $max_known_row < $target_row ? $max_known_row : $target_row;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Calculated next known target: $next_known_target", $self->_get_all_positions ] );
	while( ($next_known_target < $max_known_row) and !defined $self->_get_row_position( $next_known_target ) ){
		$next_known_target++;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Bumping next known target to: $next_known_target",
		###LogSD		"To find a known row" ] );
	}
	# Find the right fast forward amount
	if( $next_known_target >= $target_row ){
		if( $current_row == $next_known_target ){
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Asked for a row that has already been built and loaded: $next_known_target" ] );
			return $next_known_target;
		}elsif( $current_row > 0 and $current_row < $next_known_target ){
			$fast_forward = $self->_get_row_position( $next_known_target ) - $self->_get_row_position( $current_row );
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Target is forward so fast forward set to -$fast_forward- times to row: $next_known_target" ] );
			$self->_clear_new_row_inst;# Clear old tracking for cached case
		}elsif( $max_known_row > 0 ){
			if( !$self->should_cache_positions ){
				$self->start_the_file_over ;
				$fast_forward = $self->_get_row_position( $next_known_target ) + 1;
				###LogSD	$phone->talk( level => 'info', message => [
				###LogSD		"Target was backward so reset the file and fast forwarding " .
				###LogSD		"-$fast_forward- times to row: $next_known_target" ] );
			}
			$self->_clear_new_row_inst;# Clear old tracking especially for cached case
		}else{ # Handles the brand new file case
			$fast_forward = 0;
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"New file no fast forwarding to be done" ] );
			$next_known_target = $current_row;
		}
	}
	my $result = 1;
	if( $fast_forward and ( !$self->should_cache_positions or $max_known_row < $target_row ) ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Fast forwarding -$fast_forward- times to get to where we need to be in the file" ] );
		$result = $self->advance_row_position( $fast_forward );
	}
	$current_row = $next_known_target;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Current row is now set to: $current_row" ] );

	# Update/build the new row node/inst if you need something in the known range
	if( $current_row >= $target_row ){
		if( $self->should_cache_positions ){# Retrieve a known row
			###LogSD	$phone->talk( level => 'info', message => [
			###LogSD		"Using cached position for row: $current_row",
			###LogSD		"..stored in position: " . $self->_get_row_position( $current_row ), ] );
			###LogSD	$phone->talk( level => 'trace', message => [
			###LogSD		"Cached row stack:", $self->_get_row_inst_all ] );
			my	$row_node_ref = Spreadsheet::Reader::ExcelXML::Row->new(
					%{$self->_get_row_inst( $self->_get_row_position( $current_row ) )},
					###LogSD	log_space => $self->get_log_space,
				);
			$self->_set_new_row_inst( $row_node_ref );
			return $current_row;
		}else{# Build the row since caching is off
			my $full_row_ref = $self->build_row_data;
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"row build returned:", $full_row_ref ] );
			return $full_row_ref if !ref $full_row_ref;
			my $row_node_ref = Spreadsheet::Reader::ExcelXML::Row->new(
				%$full_row_ref,
				###LogSD	log_space => $self->get_log_space,
			);
			$self->_set_new_row_inst( $row_node_ref );
			###LogSD	$phone->talk( level => 'trace', message =>[
			###LogSD		"Finished building: $current_row", ] );
			return $current_row;
		}
	}

	# Handle processing unknown rows
	my $base_row_ref;
	my $current_row_position =
		$fast_forward ? $self->_get_row_position( $max_known_row ) :
		($current_row > 0) ? $self->_get_row_position( $current_row ) : -1;
	###LogSD	$phone->talk( level => 'info', message => [
	###LogSD		"Current row position for row -$current_row- is now: $current_row_position" ] );
	INITIALROWREAD: while( $result ){
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Need to read an additional unknown row since target row: $target_row",
		###LogSD		"..is still greater than current row: $current_row" ] );
		my $row_ref = $self->advance_row_position;
		###LogSD	$phone->talk( level => 'info', message => [
		###LogSD		"Current row top node is:", $row_ref ] );
		$current_row_position++;

		# Handle EOF
		if( !$row_ref or $self->not_end_of_file == 0 ){
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Already at the 'EOF' - returning failure", ] );

			# Adjust max row
			if( $self->_max_row > $self->_max_row_position_recorded - 1 ){
				$self->_set_max_row( $self->_max_row_position_recorded - 1 );
			}

			#close file if caching is on
			if( $self->should_cache_positions ){
				$self->close_the_file;
			}
			# Don't kill sharedStrings here since it might be used for other worksheets
			$self->_clear_new_row_inst;
			return 'EOF';
		}
		$result = 1;

		#build the row and manage it
		$current_row = $row_ref->{r};
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		"Attempting the full row build for row number: $current_row", ] );
		my $full_row_ref = $self->build_row_data;# Must-build is on since this is a used data set
		###LogSD	$phone->talk( level => 'trace', message =>[
		###LogSD		"row build returned:", $full_row_ref ] );
		if( $full_row_ref ){
			$self->_set_row_position( $current_row => $current_row_position  );
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Updated row position stack:", $self->_get_all_positions, ] );
			if( $self->should_cache_positions ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"Caching row position: $current_row_position", $row_ref->{r}, $full_row_ref->{row_number} ] );
				$self->_set_row_inst( $current_row_position => $full_row_ref );
				###LogSD	$phone->talk( level => 'trace', message =>[
				###LogSD		 "row node ref stack:", $self->_get_row_inst_all, ] );
			}
			if( $current_row >= $target_row ){
				###LogSD	$phone->talk( level => 'debug', message =>[
				###LogSD		"The row -$current_row- is greater than or equal to the target row: $target_row" ] );
				my $row_node_ref = Spreadsheet::Reader::ExcelXML::Row->new(
					%$full_row_ref,
					###LogSD	log_space => $self->get_log_space,
				);
				$self->_set_new_row_inst( $row_node_ref );
				# No need to increment $current_row_position here!!!
				last INITIALROWREAD;
			}else{
				###LogSD	$phone->talk( level => 'info', message =>[
				###LogSD		"Cached an intermediate row - moving on" ] );
			}
		}else{
			###LogSD	$phone->talk( level => 'debug', message =>[
			###LogSD		"Found an empty row - moving on" ] );
		}
	}

	###LogSD	$phone->talk( level => 'info', message =>[
	###LogSD		"Arrived at ( and built ) row: $current_row", ] );
	return $current_row;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _row_position_lookup =>(
		isa		=> ArrayRef[ Maybe[Int] ],
		traits	=>['Array'],
		default => sub{ [] },
		reader	=> '_get_all_positions',
		writer => '_set_all_positions',
		handles =>{
			_max_row_position_recorded => 'count',
			_get_row_position => 'get',
			_set_row_position => 'set',
		},
	);

has _new_row_inst =>(# For non cached sheets
		isa			=> InstanceOf[ 'Spreadsheet::Reader::ExcelXML::Row' ],
		reader		=> '_get_new_row_inst',
		writer		=> '_set_new_row_inst',
		clearer		=> '_clear_new_row_inst',
		predicate	=> 'has_new_row_inst',
		handles	=>{
			get_new_row_number 	=> 'get_row_number',
			get_new_column			=> 'get_the_column', # pass an Excel based column number (no next default) returns (cell|undef|EOR)
			get_new_next_value		=> 'get_the_next_value_position', # pass nothing returns next (cell|EOR)
			get_new_row_all			=> 'get_row_all',
			#~ _is_new_row_hidden		=> 'is_row_hidden',
			#~ _get_new_row_formats	=> 'get_row_format', # pass the desired format key
			#~ _get_new_last_value_col	=> 'get_last_value_column',
			#~ _get_new_row_end		=> 'get_row_end'
		},
	);

has _cached_row_insts =>(# For cached sheets
		isa			=> ArrayRef[HashRef],
		traits		=> ['Array'],
		reader		=> '_get_row_inst_all',
		clearer		=> '_clear_row_inst_all',
		default		=> sub{ [] },
		handles	=>{
			_get_row_inst 	=> 'get',
			_set_row_inst 	=> 'set',
		},
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;

1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::Reader::ExcelXML::WorksheetToRow - Builds row objects from
worksheet files

=head1 SYNOPSIS

See t\Spreadsheet\Reader\ExcelXML\09-worksheet_to_row.t

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own
excel parser.  To use the general package for excel parsing out of the box please review
the documentation for L<Workbooks|Spreadsheet::Reader::ExcelXML>,
L<Worksheets|Spreadsheet::Reader::ExcelXML::Worksheet>, and
L<Cells|Spreadsheet::Reader::ExcelXML::Cell>

This module provides the generic connection to individual worksheet files (not chartsheets)
for parsing xlsx(and xml) workbooks.  It does not provide a way to connect to L<chartsheets
|Spreadsheet::Reader::ExcelXML::Chartsheet>.  It does not provide the final view of a given
cell.  The final view of the cell is collated with the role (Interface)
L<Spreadsheet::Reader::ExcelXML::Worksheet>.  This reader extends the base reader class
L<Spreadsheet::Reader::ExcelXML::XMLReader>.  This module also uses a file type interpreter.
The functionality provided by those modules is not explained here.

For now this module reads each full row (with values) into a L<Spreadsheet::Reader::ExcelXML::Row>
instance.  It stores either the currently read row or all rows based on the
L<Spreadsheet::Reader::ExcelXML/cache_positions> setting for Worksheet_instance.
When a position past the end of the sheet is called the current row is cleared and an 'EOF'
or undef value is returned.  See L<Spreadsheet::Reader::ExcelXML/file_boundary_flags> for
more details.

I<All positions (row and column places and integers) at this level are stored and returned in count
from one mode!>

To replace this part in the package look in the raw code of
L<Spreadsheet::Reader::ExcelXML::Workbook> and adjust the 'worksheet_interface' key of the
$parser_modules variable.

=head2 requires

This module is a L<role|Moose::Manual::Roles> and as such only adds incremental methods and
attributes to some base class.  In order to use this role some base object methods are
required.  The requirments are listed below with links to the default provider.

=over

L<Spreadsheet::Reader::ExcelXML::FileWorksheet/advance_row_position( $element, [$iterations] )>

L<Spreadsheet::Reader::ExcelXML::FileWorksheet/build_row_data>

L<Spreadsheet::Reader::ExcelXML::XMLReader/not_end_of_file>

L<Spreadsheet::Reader::ExcelXML::XMLReader/start_the_file_over>

L<Spreadsheet::Reader::ExcelXML::XMLReader/close_the_file>

=back

=head2 Attributes

Data passed to new when creating an instance.  For access to the values in these
attributes see the listed 'attribute methods'. For general information on attributes see
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the
L<Methods|/Methods>.

=head3 cache_positions

=over

B<Definition:> This is a boolean value which controls whether the parser caches rows that
have been parsed or just stores the top level hash.  In general this should repsond to the
top level attribute L<Spreadsheet::Reader::ExcelXML/cache_positions>

B<Default:> 1 = caching on

B<Range:> (1|0)

B<attribute methods> Methods provided to adjust this attribute

=over

B<should_cache_positions>

=over

B<Definition:> return the attribute value

=back

=back

=back

=head2 Methods

These are the methods provided by this class for use within the package but are not intended
to be used by the end user.  Other private methods not listed here are used in the module but
not used by the package.  If the private method is listed here then replacement of this module
either requires replacing them or rewriting all the associated connecting roles and classes.

=head3 has_new_row_inst

=over

B<Definition:> Generally in the processing of a worksheet file there will be a currently
active row.  This row is stored as an object so elements of the row can be retrieved via
L<delegation|Moose::Manual::Delegation/NATIVE DELEGATION>

B<Accepts:> nothing

B<Returns:> (1|0) depending on the presence of a currently stored row

=back

=head3 get_new_row_number

=over

B<Definition:> This returns the row number (in count from 1 mode) for the currently stored
row.

B<Accepts:> nothing

B<Returns:> an integer $row

=back

=head3 get_new_column( $column )

=over

B<Definition:> This returns the column data for the selected $column.  If the request is
for a column with no data then it returns undef.  If the column is requested pased the
last column with data but before the end of the span it returns 'EOD'.  If the request is
for a column past the end of the span it returns 'EOF'.  THe request and return are all
handled in count from 1 context.

B<Accepts:> an integer $column number

B<Returns:> The cell contents for that column (or undef, 'EOD', or 'EOF')

=back

=head3 get_new_next_value

=over

B<Definition:> like get_new_column this will return one cell.  However, this method
will only return cells with content or 'EOR'.  The role keeps track of which one
was called last even it it was through get_new_column.

B<Accepts:> nothing

B<Returns:> the cell contents or 'EOR'

=back

=head3 get_new_row_all

=over

B<Definition:> This is returns an array ref of each of the values in the current row placed
in their 'count from 0' position.

B<Accepts:> nothing

B<Returns:> an array ref

=back

=head3 go_to_or_past_row( $row )

=over

B<Definition:> This will attempt to advance to the row provided by $row.  It will continue to
advance past that row until it arrives at a row with values or the end of the file.

B<Accepts:> $row (integer in count from 1 context)

B<Returns:> The actual row number that was arrived at (in count from 1 context)

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
