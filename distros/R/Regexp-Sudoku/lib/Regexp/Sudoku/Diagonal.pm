package Regexp::Sudoku::Diagonal;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Hash::Util::FieldHash qw [fieldhash];
use Regexp::Sudoku::Utils;

################################################################################
#
# sub init_diagonal ($self, $args)
#
# If we have diagonals, it means cells on one or more diagonals
# should differ. This method initializes the houses for that.
#
# The main diagonal for a 9 x 9 sudoku is defined as follows:
#
#     * . .  . . .  . . .
#     . * .  . . .  . . .
#     . . *  . . .  . . .
#
#     . . .  * . .  . . .
#     . . .  . * .  . . .
#     . . .  . . *  . . .
#
#     . . .  . . .  * . .
#     . . .  . . .  . * .
#     . . .  . . .  . . *
#
# The minor diagonal for a 9 x 9 sudoku is defined as follows:
# 
#     . . .  . . .  . . *
#     . . .  . . .  . * .
#     . . .  . . .  * . .
#
#     . . .  . . *  . . .
#     . . .  . * .  . . .
#     . . .  * . .  . . .
#     
#     . . *  . . .  . . .
#     . * .  . . .  . . .
#     * . .  . . .  . . .
#     
# TESTS: Diagonal/100-set_diagonals.t
#        Diagonal/101-set_diagonals.t
#        Diagonal/102-set_diagonals.t
#     
################################################################################
 
my sub init_diagonal ($self, $type, $offset = 0) {
    my $size = $self -> size;

    return $self if $offset >= $size;

    my @cells;
    for (my ($r, $c) = $type == $MAIN_DIAGONAL
                        ? ($offset >= 0 ? (1,               1 + $offset)
                                        : (1 - $offset,     1))
                        : ($offset >= 0 ? ($size,           1 + $offset)
                                        : ($size + $offset, 1));
        0 < $r && $r <= $size && 0 < $c && $c <= $size;
        ($r, $c) = $type == $MAIN_DIAGONAL ? ($r + 1, $c + 1)
                                           : ($r - 1, $c + 1)) {
        push @cells => cell_name ($r, $c);
    }

    my $name;
    if ($type == $MAIN_DIAGONAL) {
        $name = "DM";
        if ($offset) {   
            $name .= $offset > 0 ? "S" : "s";
            $name .= "-" . abs ($offset);
        }
    }
    else {
        $name = "Dm";
        if ($offset) {   
            $name .= $offset < 0 ? "S" : "s";
            $name .= "-" . abs ($offset);
        }
    }

    $self -> create_house ($name => @cells);
}

sub set_diagonal_main ($self) {
    init_diagonal ($self, $MAIN_DIAGONAL);
}
sub set_diagonal_minor ($self) {
    init_diagonal ($self, $MINOR_DIAGONAL);
}     
sub set_cross ($self) {
    $self -> set_diagonal_main
          -> set_diagonal_minor
}
sub set_diagonal_double ($self) {
    $self -> set_cross_1
}
sub set_diagonal_triple ($self) {
    $self -> set_cross_1
          -> set_cross
}
sub set_argyle ($self) {
    $self -> set_cross_1
          -> set_cross_4
}
                                           
        
foreach my $offset (1 .. $NR_OF_SYMBOLS - 1) {
    no strict 'refs';
    
    *{"set_diagonal_main_super_$offset"} =  sub ($self) {
        init_diagonal ($self, $MAIN_DIAGONAL,    $offset);
    };
            
    *{"set_diagonal_main_sub_$offset"} =  sub ($self) {
        init_diagonal ($self, $MAIN_DIAGONAL,  - $offset);
    };
    
    *{"set_diagonal_minor_super_$offset"} =  sub ($self) {
        init_diagonal ($self, $MINOR_DIAGONAL, - $offset);
    };
            
    *{"set_diagonal_minor_sub_$offset"} =  sub ($self) {
        init_diagonal ($self, $MINOR_DIAGONAL,   $offset);
    };
    
    *{"set_cross_$offset"} =  sub ($self) {
        init_diagonal ($self, $MAIN_DIAGONAL,    $offset);
        init_diagonal ($self, $MAIN_DIAGONAL,  - $offset);
        init_diagonal ($self, $MINOR_DIAGONAL, - $offset);
        init_diagonal ($self, $MINOR_DIAGONAL,   $offset);
    };
}
      
1;

__END__

=pod

=head1 NAME

Regexp::Sudoku::Diagonal -- Diagonal related method

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
