use strict;
use warnings;
#use feature qw( say );

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)
our @rows;     # row objects		(1 .. 9)

#package
#    Games::Sudoku::Trainer::Cell;
package Games::Sudoku::Trainer::Cell;

use version; our $VERSION = qv('0.02');    # PBP

# constructor for cell objects
#
sub new {
    my $class    = shift;
    my $cell_idx = shift;    # cell index (1 .. 81)

    my $row   = int( ( $cell_idx - 1 ) / 9 ) + 1;
    my $col   = ( $cell_idx - 1 ) % 9 + 1;
    my $block = int( ( $col - 1 ) / 3 ) + 3 * int( ( $row - 1 ) / 3 ) + 1;

    # Property Siblings is not in this list. Its construction must be
    # delayed (in module Const_structs) until all cells are created
    my @props = (    # cell properties
        'Name',       "r${row}c$col",
        'Cell_num',   $cell_idx,
        'Row_num',    $row,
        'Col_num',    $col,
        'Block_num',  $block,
        'Value',      0,                # init. Value
        'Candidates', '123456789',      # init. cand.s string (all digits)
             # placeholders for the unit objects containing this cell
             # The objects are inserted by sub set_Containers
             # after all Unit objects are created
        'Containers', [ $row, $col, $block ]
    );
    my $self = {@props};
    return bless $self, $class;
}

# Standard getters
#
sub Name       { return $_[0]->{Name} }
sub Cell_num   { return $_[0]->{Cell_num} }
sub Row_num    { return $_[0]->{Row_num} }
sub Col_num    { return $_[0]->{Col_num} }
sub Block_num  { return $_[0]->{Block_num} }
sub Value      { return $_[0]->{Value} }
sub Candidates { return $_[0]->{Candidates} }

# Getter for arrays (return a copy of the array)
sub get_Containers { return @{ $_[0]->{Containers} } }

# setter for Containers (called from Const_structs::define_objects)
#
sub set_Containers {
    my $self = shift;
    my ($new_val) = @_;

    $self->{Containers} = $new_val;
    return;
}

# setter for Siblings property
#   called from Const_structs::define_siblings
#
sub set_Siblings {
    my $class    = shift;
    my $sibl_ref = shift;

    foreach my $i ( 1 .. 81 ) {
        $cells[$i]->{Siblings} = $sibl_ref->[$i];
    }
    return;
}

# return ref to the active siblings (siblings with candidates
# - value not yet found) of this cell
#	$sibl_ref = $cell->get_Siblings_ref;
#
sub get_Siblings_ref {    # getter for Siblings
    my $self = shift;

    return [ grep { $_->Candidates } @{ $self->{Siblings} } ];
}

# return all common active siblings of 2 cells
#   my @com_sibs = common_sibs->($cell1, $cell2);
#
sub common_sibs {
    my $class = shift;
    my ( $cell1, $cell2 ) = @_;

    return map( {
            my $sib2 = $_;
              grep ( { $_ == $sib2 } @{ $cell1->get_Siblings_ref } )
            ? $_
            : ()
    } @{ $cell2->get_Siblings_ref } );
}

# Insert passed digit as value for this cell
# Exclude all cands of this cell
# Exclude this digit as cand in all siblings
#   $cell->insert_digit($digit);
#
sub insert_digit {
    my $self  = shift;
    my $digit = shift;

    $digit
      or die "3\nInvalid digit ", defined $digit ? $digit : '', " passed\n ";
    my $val = $self->Value;
    return if ( $val == $digit );    # found already
         # '\n ' at end of die message starts the location info on a new line
    $val > 0
      and die "3\nDigit $digit not allowed in cell ", $self->Name,
      ",\n has already value $val\n ";
    $self->has_candidate($digit) or Games::Sudoku::Trainer::Pause->Mode eq 'in_preset'
      ## error in preset values will be caught during verify
      or
      die( "3\nDigit $digit not allowed in empty cell ", $self->Name, "\n " );
    $self->_set_Value($digit);
    foreach my $digt ( 1 .. 9 ) {
        my $ok = $self->exclude_candidate($digt);
    }
    $self->_exclude_candidates($digit);
    return;
}

# exclude a candidate for a cell
#    $cell->exclude_candidate($cand_digit);
#
sub exclude_candidate {
    my $self   = shift;
    my ($digt) = @_;
    my $ok     = $self->{Candidates} =~ s/$digt//;
    $ok or return 0;    # already done (no error)

    # adjust the cand. count in all containers
    foreach my $sibl_unit ( $self->get_Containers ) {
        $sibl_unit->remove_Cand_cell( $digt, $self );
    }
    # change color on the board
    Games::Sudoku::Trainer::GUI::exclude_cand( $self, $digt );
    return 1;
}

# Count the candidates of this cell
#	$cands_count = $cell->cands_count;
#
sub cands_count {
    my $self = shift;

    return length( $self->Candidates );
}

# check whether this cell has this digit as cand.
#   bool = $cell->has_candidate($cand_digit);
#
sub has_candidate {
    my $self       = shift;
    my $cand_digit = shift;

    return $self->Candidates =~ /$cand_digit/;
}

# return the cell object for a given name
#	$cell = Games::Sudoku::Trainer::Cell->by_name($cell_name);
#
sub by_name {
    my $self = shift;
    my $name = shift;

    unless ( defined $name ) {
        my @trace = caller(0);
        Games::Sudoku::Trainer::Run::code_err(
            "Undefined cell name provided\nby file $trace[1], line $trace[2]\n"
        );
        Games::Sudoku::Trainer::GUI::quit();
    }
    my ( $rownum, $colnum ) = ( $name =~ /^r(\d)c(\d)$/ );
    unless ($colnum) {
        my @trace = caller(0);
        Games::Sudoku::Trainer::Run::code_err(
		  "Invalid cell row or column number provided"
          . "\nby file $trace[1], line $trace[2]\n"
		);
        Games::Sudoku::Trainer::GUI::quit();
    }
    return Games::Sudoku::Trainer::Cell->by_pos( $rownum, $colnum );
}

# return the cell object for a given row/column position
#	$cell = Games::Sudoku::Trainer::Cell->by_pos($rownum, $colnum);
#
sub by_pos {
    ( undef, my $rownum, my $colnum ) = @_;

    $rownum or $colnum or do {

        # direct call of code_err avoids the silly error window of Perl/Tk
        my @trace = caller(0);
        Games::Sudoku::Trainer::Run::code_err(
		  "Invalid cell row or column number provided"
          . "\nby file $trace[1], line $trace[2]\n"
		);
        Games::Sudoku::Trainer::GUI::quit();
    };
    return $cells[ 9 * ( $rownum - 1 ) + $colnum ];
}

#--------------------------------------
#  Private subs below this line - do not call from outside
#--------------------------------------

sub _set_Value {    # setter for Value
    my $self = shift;
    my ($new_val) = @_;

    $self->{Value} = $new_val;
    return;
}

# Exclude all candidates in this cell (it just got a value)
# Exclude the new value from the candidate list in all sibling cells
#	$cell->_exclude_candidates($digit);
#
sub _exclude_candidates {
    my $self  = shift;
    my $digit = shift;

    foreach my $unit ( $self->get_Containers ) {

        # all digits are no longer candidates in this unit
        foreach my $digt ( 1 .. 9 ) {
            $unit->remove_Cand_cell( $digt, $self )
              if $self->has_candidate($digt);
##?? ohne if??
        }
    }

    my $sibl_ref = $self->get_Siblings_ref;
    foreach my $sibl_cell (@$sibl_ref) {
        next unless $sibl_cell->has_candidate($digit);    # is no cand. cell
        $sibl_cell->exclude_candidate($digit);
        $sibl_cell->Candidates

          # error in preset values will be caught during verify
          or Games::Sudoku::Trainer::Pause->Mode eq 'in_preset'
          or die(
            "1\nInsertion of digit $digit in cell ",
            $self->Name, "\ncaused exclusion of the last candidate in cell ",
            $sibl_cell->Name, "\n"
          );
    }
    return;
}

1;
