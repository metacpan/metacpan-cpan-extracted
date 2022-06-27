package Regexp::Sudoku::German_Whisper;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022061901';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

fieldhash my %german2cells;
fieldhash my %cell2germans;

use List::Util qw [min max];


################################################################################
#
# set_german_whisper ($self, @cells)
#
# Initialize any German whisper lines/areas
#        
# TESTS: German_Whisper/100-set_german_whisper.t
#
################################################################################

sub set_german_whisper ($self, @cells) {
    if (@cells == 1 && "ARRAY" eq ref @cells) {
        @cells = @{$cells [0]}
    }               

    my $name = "GW-" . (1 + keys %{$german2cells {$self} || {}});

    my $i = 0;
    foreach my $cell (@cells) {   
        $cell2germans {$self} {$cell} {$name} = ++ $i;
        $german2cells {$self} {$name} {$cell} =     1;
    }

    $self;
}
                       

################################################################################
#
# cell2renbans ($self, $cell)
#
# Return a list of German Whispers a cell belongs to.
#
# TESTS: German_Whisper/100-set_german_whisper.t
#
################################################################################
                       
sub cell2germans ($self, $cell) {
    keys %{$cell2germans {$self} {$cell} || {}}
}


################################################################################
# 
# german2cells ($self, $cell)
# 
# Return a list of cells in a German Whisper.
#
# TESTS: German_Whisper/100-set_german_whisper.t
#
################################################################################
        
sub german2cells ($self, $german) {
    keys %{$german2cells {$self} {$german} || {}}
}


################################################################################
#
# consecutive_in_german_whisper ($self, $cell1, $cell2)
#
# Return true, if and only if, $cell1 and $cell2 are consecutive cells
# on a German Whispers line.
#       
# TESTS: German_Whisper/110-consecutive_in_german_whisper.t
#
################################################################################

sub consecutive_in_german_whisper ($self, $cell1, $cell2) {
    #
    # First get the German Whispers to which both cells belong.
    #
    my %seen;
       $seen {$_} ++ for $self -> cell2germans ($cell1),
                         $self -> cell2germans ($cell2);

    #
    # Now, for each German Whisper both belong, check whether they
    # are consecutive.
    #
    foreach my $german (keys %seen) {
        next unless $seen {$german} > 1;
        return 1 if abs ($cell2germans {$self} {$cell1} {$german} -
                         $cell2germans {$self} {$cell2} {$german}) == 1
    }
    return 0;
}


################################################################################
#
# make_german_statement ($self, $cell1, $cell2)
#
# Given two cell names, which are assumed to be consecutive in the same
# German Whisper, return a sub subject and a sub pattern, which matches iff
# the difference between the cells is at least half de size of the Sudoku.
# 
# TESTS: German_Whisper/120-make_renban_statement.t
#
################################################################################
 
sub make_german_whisper_statement ($self, $cell1, $cell2) {
    #
    # All statements will be the same, so use "state"
    #
    state  $subsub = do {
        my  $size   = $self -> size;
        my  $diff   = $size % 2 ? ($size + 1) / 2 : ($size / 2) + 1;
        my  @values = $self -> values;
        my $subject = "";
        foreach my $i (keys @values) {
            foreach my $j (keys @values) {
                next unless abs ($i - $j) >= $diff;
                $subject .= $values [$i] . $values [$j];
            }
        }

        $subject . $SENTINEL
    };

    my $range   =   $self -> values_range ();
    my $pair    =  "(?:[$range][$range])";
    my $subpat  =  "$pair*\\g{$cell1}\\g{$cell2}$pair*" . $SENTINEL;

    return ($subsub, $subpat);
}
 

__END__

=pod

=head1 NAME

Regexp::Sudoku::German_Whisper -- German_Whisper related method

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
