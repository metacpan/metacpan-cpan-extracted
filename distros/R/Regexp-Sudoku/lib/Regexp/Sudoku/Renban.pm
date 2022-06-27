package Regexp::Sudoku::Renban;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

fieldhash my %renban2cells;
fieldhash my %cell2renbans;

use List::Util qw [min max];


################################################################################
#
# set_renban ($self, @cells)
#
# Initialize any renban lines/areas
#        
# TESTS: Renban/100-set_renban.t
#
################################################################################

sub set_renban ($self, @cells) {
    if (@cells == 1 && "ARRAY" eq ref @cells) {
        @cells = @{$cells [0]}
    }               

    my $name = "REN-" . (1 + keys %{$renban2cells {$self} || {}});

    foreach my $cell (@cells) {   
        $cell2renbans {$self} {$cell} {$name} = 1;
        $renban2cells {$self} {$name} {$cell} = 1;
    }

    $self;
}
                       

################################################################################
#
# cell2renbans ($self, $cell)
#
# Return a list of renbans a cell belongs to.
#
# TESTS: Renban/100-set_renban.t
#
################################################################################
                       
sub cell2renbans ($self, $cell) {
    keys %{$cell2renbans {$self} {$cell} || {}}
}


################################################################################
# 
# renban2cells ($self, $cell)
# 
# Return a list of cells in a renban.
#
# TESTS: Renban/100-set_renban.t
#
################################################################################
        
sub renban2cells ($self, $renban) {
    keys %{$renban2cells {$self} {$renban} || {}}
}


################################################################################
#
# same_renban ($self, $cell1, $cell2)
#
# Return a list of renbans to which both $cell1 and $cell2 belong.
# In scalar context, returns the number of renbans the cells both belong.
#       
# TESTS: Renban/110-same_renban.t
#
################################################################################

sub same_renban ($self, $cell1, $cell2) {
    my %seen;
       $seen {$_} ++ for $self -> cell2renbans ($cell1),
                         $self -> cell2renbans ($cell2);
    grep {$seen {$_} > 1} keys %seen;
}


################################################################################
#
# make_renban_statement ($self, $cell1, $cell2)
#
# Given two cell names, which are assumed to be in the same renban,
# return a sub subject and a sub pattern, which makes iff the difference
# between the cells is less than the size of the renban.
# 
# For now, we assume no pair of different size renbans intersect more
# than once.
# 
# TESTS: Renban/120-make_renban_statement.t
#
################################################################################
 
sub make_renban_statement ($self, $cell1, $cell2) {
    my ($name)  = $self -> same_renban ($cell1, $cell2);
    my  $size   = $self -> renban2cells ($name);
    my  @values = $self -> values;
    my  $subsub = "";
    my  $subpat = "";

    for (my $i = 0; $i < @values; $i ++) {
        my $d1 = $values [$i];
        for (my $j = max (0, $i - $size + 1);
                $j < min ($i + $size, scalar @values); $j ++) {
            next if $i == $j;
            my $d2 = $values [$j];
            $subsub .= "$d1$d2";
       }
    }
  
    my $range = $self -> values_range ();
    my $pair  = "(?:[$range][$range])";
                       
    $subpat   = "$pair*\\g{$cell1}\\g{$cell2}$pair*";

    map {$_ . $SENTINEL} $subsub, $subpat;
}
 

__END__

=pod

=head1 NAME

Regexp::Sudoku::Renban -- Renban related method

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
