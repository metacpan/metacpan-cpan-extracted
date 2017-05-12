use strict;
use warnings;
#use feature qw( say );

# Define constant Sudoku structures

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;     # cell objects      (1 .. 81)
our @rows;      # row objects       (1 .. 9)
our @cols;      # col objects       (1 .. 9)
our @blocks;    # block objects     (1 .. 9)
our @units;     # all unit objects	(0 .. 26)  rows, columns, and blocks
our @lines;     # all line objects	(0 .. 17)  rows and columns

package
    Games::Sudoku::Trainer::Const_structs;

use version; our $VERSION = qv('0.02');    # PBP

use Games::Sudoku::Trainer::Cell;
use Games::Sudoku::Trainer::Unit;

# globals of package Const_structs
# intersection of units
my ( $crossRowCol_ref, $crossRowBlock_ref, $crossColBlock_ref );

define_objects();

push( @units, @rows[ 1 .. 9 ], @cols[ 1 .. 9 ], @blocks[ 1 .. 9 ] );
@lines = @units[ 0 .. 17 ];

define_crossRowCol();
define_crossLineBlock();

sub define_objects {

    # build cell objects
    $#cells = 81;    #pre-allocate
    foreach my $idx ( 1 .. $#cells ) {
        $cells[$idx] = Games::Sudoku::Trainer::Cell->new($idx);
    }

    # build row objects
    foreach my $idx ( 1 .. 9 ) {
        $rows[$idx] = Games::Sudoku::Trainer::Row->new($idx);
    }

    # build col objects
    foreach my $idx ( 1 .. 9 ) {
        $cols[$idx] = Games::Sudoku::Trainer::Col->new($idx);
    }

    # build block objects
    foreach my $idx ( 1 .. 9 ) {
        $blocks[$idx] = Games::Sudoku::Trainer::Block->new($idx);
    }

    # reset all containers - replace indices by unit objects
    foreach my $cell (@cells) {
        next unless defined $cell;    # skip index 0
        my ( $row, $col, $block ) = $cell->get_Containers;
        $cell->set_Containers( [ $rows[$row], $cols[$col], $blocks[$block] ] );
    }

    # add Siblings property to cell objects
    define_siblings();
    return;
} ## end sub define_objects

sub define_crossRowCol {
    my @crosscells;

    foreach my $i ( 1 .. 9 ) {    # row index
        foreach my $j ( 1 .. 9 ) {    # col index
            $crosscells[$i][$j] = $rows[$i]->get_Member( $j - 1 );
        }
    }
    $crossRowCol_ref = \@crosscells;
    return;
}

sub define_crossLineBlock {
    my ( @crossRows, @crossCols );

    foreach my $j ( 1 .. 9 ) {        # block index
        foreach my $i ( 1 .. 9 ) {    # line index
            $crossRows[$i][$j] = [ () ];
            $crossCols[$i][$j] = [ () ];
        }
        my @bmembers = $blocks[$j]->get_Members;
        my $cell1    = $bmembers[0];
        my $row1     = $cell1->Row_num;            # row index
        my $col1     = $cell1->Col_num;            # col index
        foreach my $i ( 0 .. 2 ) {
            my $row      = $row1 + $i;                 # row index
            my @rmembers = $rows[$row]->get_Members;
            $crossRows[$row][$j] = [ @rmembers[ $col1 - 1 .. $col1 - 1 + 2 ] ];
        }
        foreach my $i ( 0 .. 2 ) {
            my $col      = $col1 + $i;                 # col index
            my @cmembers = $cols[$col]->get_Members;
            $crossCols[$col][$j] = [ @cmembers[ $row1 - 1 .. $row1 - 1 + 2 ] ];
        }
    }
    $crossRowBlock_ref = \@crossRows;
    $crossColBlock_ref = \@crossCols;
    return;
}

#======================================================
## Getters for access to the 3 constant 2-dim. arrays
## that hold the common cells in the crosssection of 2 units
#
# return the common cell of a row and a column (as an array)
#    my ($crosscell) = crossRowCol($row, $col);
#
sub crossRowCol {
    return _crossSect( @_, $crossRowCol_ref );
}

# return the common cells of a row and a block
#    my @crosscells = crossRowBlock($row, $block);
#
sub crossRowBlock {
    return _crossSect( @_, $crossRowBlock_ref );
}

# return the common cells of a column and a block
#    my @crosscells = crossColBlock($col, $block);
#
sub crossColBlock {
    return _crossSect( @_, $crossColBlock_ref );
}

sub _crossSect {
    my ( $unit1, $unit2, $crossSect_ref ) = @_;

    my ( $idx1, $idx2 );
    $idx1 = substr( $unit1->Name, 1 );
    $idx2 = substr( $unit2->Name, 1 );
    return ( $$crossSect_ref[$idx1][$idx2] );
}

#
#======================================================

sub define_siblings {
    my @siblings;
    use List::MoreUtils qw/uniq/;

    push @siblings, undef;
    foreach my $cell (@cells) {
        next unless $cell;
        my @tmp;
        foreach my $unit ( $cell->get_Containers ) {
            push @tmp, $unit->get_Members;
        }
        @tmp = uniq @tmp;
        push @siblings, [ grep $_ != $cell, @tmp ];    # remove $cell
    }
    Games::Sudoku::Trainer::Cell->set_Siblings( \@siblings );
    return;
}

1;
