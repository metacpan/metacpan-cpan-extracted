package Regexp::Sudoku::Battenburg;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

fieldhash my %battenburg2cells;
fieldhash my %cell2battenburgs;
fieldhash my %anti_battenburg2cells;
fieldhash my %cell2anti_battenburgs;

use List::Util qw [min max];

        
################################################################################
#
# set_battenburg ($self, @cells)
#
# Set one or more Battenburg constraints. For each constraint, we give
# the top left cell. (Multiple cells mean *different* constraints, not
# the cells of a single constraint)
#
# TESTS: Battenburg/100-set_battenburg.t
#
################################################################################
            
sub set_battenburg ($self, @cells) {
    foreach my $name (@cells) {
        #
        # Calculate all the cells of the constraint
        #
        my ($r, $c) = cell_row_column ($name);
        my @cells = (cell_name ($r,     $c), cell_name ($r,     $c + 1),
                     cell_name ($r + 1, $c), cell_name ($r + 1, $c + 1));
        foreach my $cell (@cells) {  
            $cell2battenburgs {$self} {$cell} {$name} = 1;
            $battenburg2cells {$self} {$name} {$cell} = 1;
        }
    }
    $self;
}
    
    
################################################################################
#
# set_anti_battenburg ($self, @cells)
#
# Set one or more anti Battenburg constraints. For each constraint, we give
# the top left cell. (Multiple cells mean *different* constraints, not
# the cells of a single constraint)
#
# TESTS: Battenburg/105-set_anti_battenburg.t
#
################################################################################
            
sub set_anti_battenburg ($self, @cells) {
    foreach my $name (@cells) {
        #
        # Calculate all the cells of the constraint
        #
        my ($r, $c) = cell_row_column ($name);
        my @cells = (cell_name ($r,     $c), cell_name ($r,     $c + 1),
                     cell_name ($r + 1, $c), cell_name ($r + 1, $c + 1));
        foreach my $cell (@cells) {  
            $cell2anti_battenburgs {$self} {$cell} {$name} = 1;
            $anti_battenburg2cells {$self} {$name} {$cell} = 1;
        }
    }
    $self;
}
    
    
################################################################################
#
# cell2battenburgs ($self, $cell)
#
# Return a list of Battenburgs a cell belongs to.
#
# TESTS: Battenburg/100-set_battenburg.t
#
################################################################################
 
sub cell2battenburgs ($self, $cell) {
    keys %{$cell2battenburgs {$self} {$cell} || {}}
}
  

################################################################################
#
# cell2anti_battenburgs ($self, $cell)
#
# Return a list of anti-Battenburgs a cell belongs to.
#
# TESTS: Battenburg/105-set_anti_battenburg.t
#
################################################################################
 
sub cell2anti_battenburgs ($self, $cell) {
    keys %{$cell2anti_battenburgs {$self} {$cell} || {}}
}
  

################################################################################
#
# battenburg2cells ($self, $name)
#
# Return a list of cells in a Battenburg.
#
# TESTS: Battenburg/100-set_battenburg.t
#
################################################################################
        
sub battenburg2cells ($self, $name) {
    keys %{$battenburg2cells {$self} {$name} || {}}
}
            

################################################################################
#
# anti_battenburg2cells ($self, $name)
#
# Return a list of cells in an anti-Battenburg.
#
# TESTS: Battenburg/105-set_anti_battenburg.t
#
################################################################################
        
sub anti_battenburg2cells ($self, $name) {
    keys %{$anti_battenburg2cells {$self} {$name} || {}}
}
 

################################################################################
#
# same_battenburg ($self, $cell1, $cell2)
#
# Return a list of Battenburgs to which both $cell1 and $cell2 belong.
# In scalar context, returns the number of Battenburgs the cells both belong.
#
# TESTS: Battenburg/110-same_battenburg.t
#
################################################################################

sub same_battenburg ($self, $cell1, $cell2) {
    my %seen;
    $seen {$_} ++ for $self -> cell2battenburgs ($cell1),
                      $self -> cell2battenburgs ($cell2);

    grep {$seen {$_} > 1} keys %seen;
}
 

################################################################################
#
# same_anti_battenburg ($self, $cell1, $cell2)
#
# Return a list of anti-Battenburgs to which both $cell1 and $cell2 belong.
# In scalar context, returns the number of anti-battenburgs the cells
# both belong.
#
# TESTS: Battenburg/115-same_anti_battenburg.t
#
################################################################################

sub same_anti_battenburg ($self, $cell1, $cell2) {
    my %seen;
    $seen {$_} ++ for $self -> cell2anti_battenburgs ($cell1),
                      $self -> cell2anti_battenburgs ($cell2);

    grep {$seen {$_} > 1} keys %seen;
}


################################################################################
#
# make_battenburg_statement ($self, $cell1, $cell2)
#           
# Return a statement which implements a Battenburg constraint between
# the two cells. We will assume the given cells belong to the same
# Battenburg contraint. If the cells are on the same row or column,
# the constraint is that they have a different parity. Else, the
# cells must have the same parity.
# 
# TESTS: Battenburg/120-make_battenburg_statement.t
# 
################################################################################

sub make_battenburg_statement ($self, $cell1, $cell2) {
    my ($r1, $c1) = cell_row_column ($cell1);
    my ($r2, $c2) = cell_row_column ($cell2);
    my ($subsub, $subpat);
    
    #
    # Case 1, cells are diagonally opposite.
    # Then the parity must be the same.
    #
    if ($r1 != $r2 && $c1 != $c2) {
        my $md = $self -> must_differ ($cell1, $cell2);
        return $self -> make_same_parity_statement ($cell1, $cell2, $md);
    }
    else {
        return $self -> make_different_parity_statement ($cell1, $cell2);
    }
}


################################################################################
#
# make_anti_battenburg_statement ($self, $anti_battenburg)
#           
# Return a (set of) statement(s) which implements the constraints 
# for an anti-Battenburg. This will be four constraints, of which
# only one needs to be true (exactly 1 is not possible, it's either 0,
# 2, or 4 -- but all we care about is that it's not 0).
# 
# TESTS: Battenburg/125-make_anti_battenburg_statement.t
# 
################################################################################

sub make_anti_battenburg_statement ($self, $anti_battenburg) {
    #
    # We will make use of the fact that an anti-Battenburg is 
    # identified with it's top-left cell. We can just calculate
    # the other cells.
    #
    my  $cell1    = $anti_battenburg;
    my ($r1, $c1) = cell_row_column ($cell1);   # Top-left
    my ($r2, $c2) = ($r1,     $c1 + 1);         # Top-right
    my ($r3, $c3) = ($r1 + 1, $c1 + 1);         # Bottom-right
    my ($r4, $c4) = ($r1 + 1, $c1);             # Bottom-left
    my  $cell2    = cell_name ($r2, $c2);
    my  $cell3    = cell_name ($r3, $c3);
    my  $cell4    = cell_name ($r4, $c4);

    my $subsub    = $self -> make_same_parity_subject;
    my $range     = $self -> values_range (1);
    my $subpat    = "[$range]*(?:\\g{$cell1}\\g{$cell2}|" .
                                "\\g{$cell2}\\g{$cell3}|" .
                                "\\g{$cell3}\\g{$cell4}|" .
                                "\\g{$cell4}\\g{$cell1})[$range]*";

    map {$_ . $SENTINEL} $subsub, $subpat;
}


__END__

=pod

=head1 NAME

Regexp::Sudoku::Battenburg -- Battenburg related methods

=head1 DESCRIPTION

This module is part of C<< Regexp::Sudoku >> and is not intended
as a standalone module.

See L<< Regexp::Sudoku >> for the documentation.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Regexp-Sudoku.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.freedom.nl >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2021-2022 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
