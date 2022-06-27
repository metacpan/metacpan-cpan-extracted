package Regexp::Sudoku::Parity;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

fieldhash my %evens;
fieldhash my %odds;
fieldhash my %is_even;
fieldhash my %is_odd;

use List::Util qw [min max];



################################################################################
#
# init_evens_odds ($self)
#
# Initialize the even and odd values of the sudoku. Only called when we're
# actually needing the even or odds values.
#
# TESTS: Parity/010_evens_odds.t
#
################################################################################

sub init_even_odds ($self) {
    return $self if $evens {$self} || $odds {$self};

    my $values = $self -> values;

    my $evens = do {my $i = 1; join "" => grep {$i = !$i} split // => $values};
    my $odds  = do {my $i = 0; join "" => grep {$i = !$i} split // => $values};

    $evens  {$self} = $evens;
    $odds   {$self} = $odds;

    $self;
}



################################################################################
#
# evens ($self)
#
# Return the set of even values used in the sudoku. In list context, this will
# be an array of characters; in scalar context, a string.
#
# TESTS: Parity/010_evens_odds.t
#
################################################################################

sub evens ($self) {
    $self -> init_even_odds;
    wantarray ? split // => $evens  {$self} : $evens  {$self};
}


################################################################################
#
# odds ($self)
#
# Return the set of odd values used in the sudoku. In list context, this will
# be an array of characters; in scalar context, a string.
#
# TESTS: Parity/010_evens_odds.t
#
################################################################################

sub odds  ($self) {
    $self -> init_even_odds;
    wantarray ? split // => $odds   {$self} : $odds   {$self};
}


################################################################################
#
# set_is_even ($self, $cell) {
# set_is_odd  ($self, $cell) {
#     is_even ($self, $cell)
#     is_odd  ($self, $cell)
#
# Set whether a cell is to be even/odd, or return this.
#
# TESTS: Parity/100-is_even_odd.t
#
################################################################################

sub set_is_even ($self, $cell) {$is_even {$self} {$cell} = 1; $self;}
sub set_is_odd  ($self, $cell) {$is_odd  {$self} {$cell} = 1; $self;}
sub     is_even ($self, $cell) {$is_even {$self} {$cell}}
sub     is_odd  ($self, $cell) {$is_odd  {$self} {$cell}}


################################################################################
#
# make_even_statement ($cell)
# make_odd_statement  ($cell)
#
# Given a cell name, return a sub subject and a sub pattern allowing the
# cell to pick up one of the even or odd values in the sudoku.
#
# TESTS: Parity/200-make_even_odd_statement.t
#               120-make_cell_statement.t
#
################################################################################

sub make_even_statement ($self, $cell) {
    $self -> make_empty_statement ($cell, "evens")
}
sub make_odd_statement  ($self, $cell) {
    $self -> make_empty_statement ($cell, "odds")
}
 

################################################################################
#
# make_same_parity_statement ($self, $cell1, $cell2, $must_differ = 0)
#
# Return a statement which forces the two cells to have the same parity
# (so, both cells are either even, or both cells are odd). Optionally,
# we can also force the cells to be different.
#
# TESTS: Parity/200-make_same_parity_statement.t
#
################################################################################

sub make_same_parity_subject ($self, $must_differ = 0) {
    my $e = semi_debruijn_seq (scalar $self -> evens, !$must_differ);
    my $o = semi_debruijn_seq (scalar $self -> odds,  !$must_differ);
    "${e}0${o}";
}

sub make_same_parity_statement ($self, $cell1, $cell2, $must_differ = 0) {
    my $range  = $self -> values_range (1);
    my $subpat = "[$range]*\\g{$cell1}\\g{$cell2}[$range]*";

    map {$_ . $SENTINEL} $self -> make_same_parity_subject ($must_differ),
                         $subpat;
}


################################################################################
#
# make_different_parity_statement ($self, $cell1, $cell2)
#
# Return a statement which forces the two cells to have different parity.
# (so, one cell is odd, the other even).
#
# TESTS: Parity/210-make_different_parity_statement.t
#
################################################################################

sub make_different_parity_statement ($self, $cell1, $cell2) {
    my $range  = $self -> values_range ();
    my $subsub = all_pairs (scalar $self -> evens, scalar $self -> odds);
    my $subpat = "[$range]*\\g{$cell1}\\g{$cell2}[$range]*";

    map {$_ . $SENTINEL} $subsub, $subpat;
}



__END__

=pod

=head1 NAME

Regexp::Sudoku::Parity -- Parity related methods

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
