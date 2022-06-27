package Regexp::Sudoku::Utils;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Exporter ();

our @ISA    = qw [Exporter];
our @EXPORT = qw [$SENTINEL $DEFAULT_SIZE $NR_OF_DIGITS $NR_OF_LETTERS
                  $NR_OF_LETTERS $NR_OF_SYMBOLS $ANTI_KING $ANTI_KNIGHT
                  $MAIN_DIAGONAL $MINOR_DIAGONAL  
                  cell_name cell_row_column all_pairs semi_debruijn_seq];

use Math::Sequence::DeBruijn;

our $SENTINEL       = "\n";

our $DEFAULT_SIZE   = 9;

our $NR_OF_DIGITS   =  9;
our $NR_OF_LETTERS  = 26;
our $NR_OF_SYMBOLS  = $NR_OF_DIGITS + $NR_OF_LETTERS;

our $ANTI_KNIGHT    = 1;
our $ANTI_KING      = 2;

our $MAIN_DIAGONAL  = 1;
our $MINOR_DIAGONAL = 2;


################################################################################
#
# sub cell_name ($row, $column)
#
# Given a row number and a cell number, return the name of the cell.
#
# TESTS: Utils/100-cell_name_row_column.t
#
################################################################################

sub cell_name ($row, $column) {
    "R" . $row . "C" . $column
}


################################################################################
#
# sub cell_row_column ($cell_name)
#
# Given the name of a cell, return its row and column.
# 
# TESTS: Utils/100-cell_name_row_column.t
#
################################################################################

sub cell_row_column ($name) {
    $name =~ /R([0-9]+)C([0-9]+)/ ? ($1, $2) : (0, 0)
}


################################################################################
#
# all_pairs ($set1, $set2)
#   
# Return a string which, foreach character $x from $set1, and $y from $set2,
# contains the substrings "$x$y" and "$y$x". Furthermore, the string will
# not contain any substring "$w$z", with $w and $z from the same set.
#
# Each set is given as a string.
#
# Note: this is *not* a method, as it's independent of any state.
#
# TESTS: Utils/150-all_pairs.t
#           
################################################################################
         
sub all_pairs ($set1, $set2) {
    my @chars1 = split // => $set1;
    my @chars2 = split // => $set2;
    my $out = "";
    foreach my $ch1 (@chars1) {
        foreach my $ch2 (@chars2) {
            $out .= "$ch1$ch2";
        }
    }
    $out .= $chars1 [0];
 
    $out;
}



################################################################################
#
# semi_debruijn_seq ($values, $allow_dups = 0)
#
# Return, for the given values, a De Bruijn sequence of size 2 with
#  1) Duplicates removed and
#  2) The first character copied to the end
#
# TESTS: Utils/130-semi_debruijn_seq.t
#
################################################################################

sub semi_debruijn_seq ($values, $allow_dups = 0) {
    state $cache;
    $$cache {$values, $allow_dups} //= do {
        my $seq = debruijn ($values, 2);
        $seq .= substr $seq, 0, 1;                    # Copy first char to
                                                      # the end.
        $seq  =~ s/(.)\g{1}/$1/g unless $allow_dups;  # Remove duplicates.
        $seq;
    };
}





1;


__END__

=pod

=head1 NAME

Regexp::Sudoku::Utils -- Utilities for Regexp::Sudoku

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
