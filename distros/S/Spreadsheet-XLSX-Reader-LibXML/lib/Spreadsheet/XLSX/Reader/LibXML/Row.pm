package Spreadsheet::XLSX::Reader::LibXML::Row;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::Row-$VERSION";

$| = 1;
use 5.010;
use Moose;
use MooseX::StrictConstructor;
use MooseX::HasDefaults::RO;
use Carp qw( confess );
use Clone qw( clone );
use Types::Standard qw(
		ArrayRef			Int						Bool
		HashRef
    );
use lib	'../../../../../lib';
###LogSD	use Log::Shiras::Telephone;
###LogSD	use Log::Shiras::UnhideDebug;
###LogSD	with 'Log::Shiras::LogSpace';
###LogSD	sub get_class_space{ 'Row' }

#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9

#~ has	error_inst =>(
		#~ isa			=> InstanceOf[ 'Spreadsheet::XLSX::Reader::LibXML::Error' ],
		#~ clearer		=> '_clear_error_inst',
		#~ reader		=> '_get_error_inst',
		#~ required	=> 1,
		#~ handles =>[ qw(
			#~ error set_error clear_error set_warnings if_warn
		#~ ) ],
	#~ );

has row_number =>(
		isa			=> Int,
		reader		=> 'get_row_number',
		required	=> 1,
	);

has row_span =>(
		isa			=> ArrayRef[ Int ],
		traits		=> ['Array'],
		writer		=> 'set_row_span',
		predicate	=> 'has_row_span',
		required 	=> 1,
		handles 	=>{
			get_row_start => [ 'get' => 0 ],
			get_row_end   => [ 'get' => 1 ],
		},
	);

has row_last_value_column =>(
		isa		=> Int,
		reader	=> 'get_last_value_column',
	);

has row_formats =>(
		isa		=> HashRef,
		traits	=> ['Hash'],
		writer	=> 'set_row_formts',
		handles =>{
			get_row_format => 'get',
		},
	);

has column_to_cell_translations =>(
		isa			=> ArrayRef,
		traits		=>[ 'Array' ],
		#~ required	=> 1,
		handles	=>{
			get_position_for_column => 'get',
		},
	);

has row_value_cells =>(
		isa			=> ArrayRef,
		traits		=>[ 'Array' ],
		reader		=> 'get_row_value_cells',
		#~ required	=> 1,
		handles	=>{
			get_cell_position => 'get',
			total_cell_positions => 'count',
		},
	);

#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub get_the_column{
	my ( $self, $desired_column ) = @_;
	confess "Desired column required" if !defined $desired_column;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 
	###LogSD					($self->get_all_space . '::get_the_column' ), );
	###LogSD		$phone->talk( level => 'debug', message =>[  
	###LogSD			 "Getting the cell value at column: $desired_column", ] );
	my	$max_column = $self->get_row_end;
	if( $desired_column > $max_column ){
		###LogSD	$phone->talk( level => 'debug', message =>[  
		###LogSD			"Requested column -$desired_column- is past the end of the row", ] );
		return 'EOR';
	}
	my	$value_position = $self->get_position_for_column( $desired_column );
	if( !defined $value_position ){
		###LogSD	$phone->talk( level => 'debug', message =>[  
		###LogSD			"No cell value stored for column: $desired_column", ] );
		return undef;
	}
	my $return_cell = $self->get_cell_position( $value_position );
	###LogSD	$phone->talk( level => 'debug', message =>[  
	###LogSD		"Returning the cell:", $return_cell, ] );
	#~ $self->_set_reported_column( $desired_column );
	$self->_set_reported_position( $value_position );
	return clone( $return_cell );
}

sub get_the_next_value_position{
	my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 
	###LogSD					($self->get_all_space . '::get_the_next_value_column' ), );
	###LogSD		$phone->talk( level => 'debug', message =>[  
	###LogSD			 "Returning the next value position in this row as available", ] );
	my $next_position = defined $self->_get_reported_position ? ($self->_get_reported_position + 1) : 0;
	if( $next_position == $self->total_cell_positions ){# Counting from zero vs counting from 1
		###LogSD	$phone->talk( level => 'debug', message =>[  
		###LogSD		"Already reported the last value position" ] );
		return 'EOR';
	}
	my $return_cell = $self->get_cell_position( $next_position );
	#~ $self->_set_reported_column( $return_cell->{cell_col} );
	$self->_set_reported_position( $next_position );
	###LogSD	$phone->talk( level => 'debug', message =>[  
	###LogSD		"Returning the cell:", $return_cell, ] );
	return clone( $return_cell );
}

sub get_row_all{
	my ( $self, ) = @_;
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space => 
	###LogSD					($self->get_all_space . '::get_row_all' ), );
	###LogSD		$phone->talk( level => 'debug', message =>[  
	###LogSD			 "Getting an array ref of all the cells in the row by column position", ] );
	
	my $return_ref;
	for my $cell ( @{$self->get_row_value_cells} ){
		$return_ref->[$cell->{cell_col} - 1] = clone $cell;
	}
	###LogSD	$phone->talk( level => 'debug', message =>[  
	###LogSD		"Returning the row ref:", $return_ref, ] );
	return $return_ref;
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9

has _reported_position =>(
		isa			=> Int,
		reader		=> '_get_reported_position',
		writer		=> '_set_reported_position',
	);

#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose;
__PACKAGE__->meta->make_immutable;
	
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::Row - XLSX Row data class

=head1 DESCRIPTION

This documentation is written to explain ways to use this module when writing your own excel 
parser.  To use the general package for excel parsing out of the box please review the 
documentation for L<Workbooks|Spreadsheet::XLSX::Reader::LibXML>,
L<Worksheets|Spreadsheet::XLSX::Reader::LibXML::Worksheet>, and 
L<Cells|Spreadsheet::XLSX::Reader::LibXML::Cell>

This module provides the basic storage and manipulation of row data (for worksheet files).  
It does not provide the final view of a given cell.  The final view of the cell is collated 
with the role (Interface) L<Spreadsheet::XLSX::Reader::LibXML::Worksheet>.

I<All positions (row and column places and integers) at this level are stored and returned in count 
from one mode!>

Modification of this module probably means a rework of the Worksheet level module 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow>.  Review the attributes 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_old_row_inst> and 
L<Spreadsheet::XLSX::Reader::LibXML::XMLReader::WorksheetToRow/_new_row_inst> for more 
details.

=head2 Attributes

Data passed to new when creating an instance.  For access to the values in these 
attributes see the listed 'attribute methods'. For general information on attributes see 
L<Moose::Manual::Attributes>.  For ways to manage the instance when opened see the 
L<Public Methods|/Public Methods>.
	
=head3 row_number

=over

B<Definition:> Stores the row number of the row data in count from 1

B<Default:> none

B<Range:> positive integers > 0

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<get_row_number>

=over

B<Definition:> return the attribute value

=back

=back

=back

=head3 row_span

=over

B<Definition:> Stores an array ref of two integers representing the start and end columns in count from 1

B<Default:> none

B<Range:> [ 2 positive integers > 0 ]

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<set_row_span>

=over

B<Definition:> sets the attribute

=back

B<has_row_span>

=over

B<Definition:> predicate for the attribute

=back

=back

L<trait|Moose::Manual::Delegation/NATIVE DELEGATION> ['Array']

B<delegated methods> - (L<curried|Moose::Manual::Delegation/CURRYING>)

=over

B<get_row_start> => [ 'get' => 0 ], # Get the first position

B<get_row_end> => [ 'get' => 1 ], # Get the second position

=back

=back
	
=head3 row_last_value_column

=over

B<Definition:> Stores the column with a value in it in count from 1

B<Default:> none

B<Range:> positive integers > 0

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<get_last_value_column>

=over

B<Definition:> return the attribute value

=back

=back

=back

=head3 row_formats

=over

B<Definition:> this is an open ended hashref with format values stored for the row

B<Default:> none

B<Range:> a hash ref

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<set_row_formats>

=over

B<Definition:> sets the attribute

=back

=back

L<trait|Moose::Manual::Delegation/NATIVE DELEGATION> ['Hash']

B<delegated methods>

=over

B<get_row_format> => 'get'

=back

=back

=head3 row_value_cells

=over

B<Definition:> Stores an array ref of information about cells with values 
for that row (in order).  The purpose of only storing the values is to allow 
for 'next_value' calls.  The actual position of the cell column is stored in 
the cell hash and the attribute L<column_to_cell_translations|/column_to_cell_translations>.

B<Default:> an ArrayRef[HashRef] with at least one column HashRef set

B<Range:> ArrayRef[HashRef]

B<attribute methods> Methods provided to adjust this attribute
		
=over

B<get_row_value_cells>

=over

B<Definition:> gets the stored attribute value

=back

=back

L<trait|Moose::Manual::Delegation/NATIVE DELEGATION> ['Array']

B<delegated methods>

=over

B<get_cell_position> => 'get'

B<total_cell_positions> => 'count'

=back

=back

=head3 column_to_cell_translations

=over

B<Definition:> only cells with values are stored but you may want to 
know if a cell has a value based on a column number or you may want to 
know where the contents of a cell containing values are base on a column 
number.  This attribute stores that lookup table.

B<Default:> an ArrayRef with at least one column position set

B<Range:> ArrayRef

L<trait|Moose::Manual::Delegation/NATIVE DELEGATION> ['Array']

B<delegated methods>

=over

B<get_position_for_column> => 'get'

=back

=back

=head2 Methods

These are the methods provided by this class for use within the package but are not intended 
to be used by the end user.  Other private methods not listed here are used in the module but 
not used by the package.  If the private method is listed here then replacement of this module 
either requires replacing them or rewriting all the associated connecting roles and classes.  
B<All methods here are assumed to be in count from 1 mode to since the role instances are meant 
to be managed in the background for the worksheet.>

=head3 get_the_column( $column )

=over

B<Definition:> This returns the value stored at the desired column position.  It also stores 
this position as the last column retrieved for any 'next_*' calls

B<Accepts:> $column (integer)

B<Returns:> a hashref of cell values at that column, undef for no values, or 'EOR' for positions 
past the end of the row.

=back

=head3 get_the_next_value_position

=over

B<Definition:> This returns the next set of cell values or 'EOR' for positions 
past the end of the row.  When a set of cell values is returned (not EOR) the new 'last' 
position is recorded.

B<Accepts:> nothing

B<Returns:> a hashref of key value pairs or 'EOR'

=back

=head3 get_row_all

=over

B<Definition:> This is a way to get an array of hashrefs that are positioned correctly B<in count 
from zero> locations for the row data.  Just value cells can be returned with 
L<get_row_value_cells|/get_row_value_cells>.  For cells with no value between the value cells undef 
is stored.  For cells past the last value even if they fall inside the row span no positions are 
created.

B<Accepts:> nothing

B<Returns:> an arrayref of hashrefs

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

=back

=head1 SEE ALSO

=over

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9