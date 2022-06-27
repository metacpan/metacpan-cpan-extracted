package Regexp::Sudoku::Quadruple;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022062001';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

fieldhash my %quadruple2cells;
fieldhash my %cell2quadruples;
fieldhash my %quadruple;

        
################################################################################
#
# set_quadruples ($self, %quadruples)
#
# Set one or more quadruple constraints. For each constraint, we give
# the top left as the key, and an arrayref of values as the value.
#
# TESTS: Quadruple/100-set_quadruples.t
#
################################################################################
            
sub set_quadruples ($self, %quadruples) {
    foreach my $cell (keys %quadruples) {
        #
        # Calculate all the cells of the constraint
        #
        my  $name   = "Q-$cell";
        my ($r, $c) = cell_row_column ($cell);
        my @cells   = (cell_name ($r,     $c), cell_name ($r,     $c + 1),
                       cell_name ($r + 1, $c), cell_name ($r + 1, $c + 1));
        foreach my $cell (@cells) {  
            $cell2quadruples {$self} {$cell} {$name} = 1;
            $quadruple2cells {$self} {$name} {$cell} = 1;
        }
        $quadruple {$self} {$name} = $quadruples {$cell};
    }
    $self;
}
    
    
    
################################################################################
#
# cell2quadruples ($self, $cell)
#
# Return a list of quadruples a cell belongs to.
#
# TESTS: Quadruple/100-set_quadruples.t
#
################################################################################
 
sub cell2quadruples ($self, $cell) {
    sort keys %{$cell2quadruples {$self} {$cell} || {}}
}
  

################################################################################
#
# quadruple2cells ($self, $name)
#
# Return a list of cells in a quadruple.
#
# TESTS: Quadruple/100-set_quadruples.t
#
################################################################################
        
sub quadruple2cells ($self, $name) {
    sort keys %{$quadruple2cells {$self} {$name} || {}}
}


################################################################################
#
# quadruple_values ($name)
#
# Return the values for this quadruple
#
# TESTS: Quadruple/100-set_quadruples.t
#
################################################################################

sub quadruple_values ($self, $name) {
    my @values = @{$quadruple {$self} {$name}};
    wantarray ? @values : \@values;
}



################################################################################
#
# make_quadruple_statements ($self, $name) 
#           
# Return a set of statements which implements a quadruple constraint for
# the set of cells belonging to the quadruple.
# 
# TESTS: Quadruple/110-make_quadruple_statements.t
# 
################################################################################

sub make_quadruple_statements ($self, $name) {
    my ($subsub, $subpat) = ([], []);
    
    #
    # First, get the values, and count how often each of them
    # occurs (which will be once or twice)
    #
    my %value_count;
       $value_count {$_} ++ for $self -> quadruple_values ($name);

    #
    # Get the cells for this quadruple.
    #
    my @cells = $self -> quadruple2cells ($name);

    #
    # Now, we need a statement for each *different* value. 
    # The patterns for each statement will be the same, the
    # subjects will differ.
    #
    my $pat = join "" => map {"\\g{$_}?"} @cells;

    foreach my $value (keys %value_count) {
        push @$subsub => ($value x $value_count {$value}) . $SENTINEL;
        push @$subpat =>  $pat                            . $SENTINEL;
    }

    ($subsub, $subpat);
}



__END__

=pod

=head1 NAME

Regexp::Sudoku::Quadruple -- Quadruple related methods

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
