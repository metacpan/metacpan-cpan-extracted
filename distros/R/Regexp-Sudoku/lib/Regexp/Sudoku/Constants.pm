package Regexp::Sudoku::Constants;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022022401';

################################################################################
#
# Diagonals
#
# TESTS: Constants/100-diagonals.t
#
################################################################################

my   @tokens  =  qw [SUPER0 MINOR_SUPER0];
push @tokens  => map {($_, "MINOR_$_")} map {("SUB$_", "SUPER$_")} "", 1 .. 34;

my   @aliases =  qw [MAIN MINOR SUB0 MINOR_SUB0
                     SUB SUPER MINOR_SUP MINOR_SUPER];
my   @sets    =  qw [CROSS DOUBLE TRIPLE ARGYLE];
push @sets    => map {"CROSS$_"} 0 .. 34;

our  $ALL_DIAGONALS;

foreach my $i (keys @tokens) {
    no strict 'refs';
    no warnings 'once';
    vec ($ALL_DIAGONALS, $i, 1) = 1;
    vec (${$tokens [$i]} = "", $i, 1) = 1;
}

our $MAIN        = our $SUPER0;
our $MINOR       = our $MINOR_SUPER0;
our $SUB0        =     $SUPER0;
our $MINOR_SUB0  =     $MINOR_SUPER0;
our $SUPER       = our $SUPER1;
our $SUB         = our $SUB1;
our $MINOR_SUPER = our $MINOR_SUPER1;
our $MINOR_SUB   = our $MINOR_SUB1;

foreach my $i (0 .. 34) {
    no strict 'refs';
    no warnings 'once';
    ${"CROSS$i"} = ${"SUB$i"}   |. ${"MINOR_SUB$i"} |.
                   ${"SUPER$i"} |. ${"MINOR_SUPER$i"};
}

our $CROSS       = our $CROSS0;
our $DOUBLE      = our $CROSS1;
our $TRIPLE      = $CROSS  |.     $CROSS1;
our $ARGYLE      = $CROSS1 |. our $CROSS4;

# our $ALL_DIAGONALS   = "";
#     $ALL_DIAGONALS |.= $_ foreach @tokens;

################################################################################
#
# Houses
#
# TESTS: Constants/110-diagonals.t
#
################################################################################

vec (our $NRC        = "", 0, 1) = 1;
vec (our $ASTERISK   = "", 1, 1) = 1;
vec (our $GIRANDOLA  = "", 2, 1) = 1;
vec (our $CENTER_DOT = "", 3, 1) = 1;
     our $ALL_HOUSES = $NRC |. $ASTERISK |. $GIRANDOLA |. $CENTER_DOT;


################################################################################
#
# Constraints
#
# TESTS: Constants/120-constraints.t
#
################################################################################

vec (our $ANTI_KNIGHT     = "", 0, 1) = 1;
vec (our $ANTI_KING       = "", 1, 1) = 1;
     our $ALL_CONSTRAINTS = $ANTI_KNIGHT |. $ANTI_KING;


################################################################################
#
# Exporting the symbols
#
################################################################################

use Exporter ();
our @ISA         = qw [Exporter];
our %EXPORT_TAGS = (
    Diagonals    => [map {"\$$_"} @tokens, @aliases, @sets, "ALL_DIAGONALS"],
    Houses       => [qw [$NRC $ASTERISK $GIRANDOLA $CENTER_DOT $ALL_HOUSES]],
    Constraints  => [qw [$ANTI_KNIGHT $ANTI_KING $ALL_CONSTRAINTS]],
);
our @EXPORT_OK   = map {@$_} values %EXPORT_TAGS;
    $EXPORT_TAGS {All} = \@EXPORT_OK;


1;


__END__


=head1 NAME

Regexp::Sudoku::Constants - Constants related to Regexp::Sudoku

=head1 SYNOPSIS

 use Regexp::Sudoku;
 use Regexp::Sudoku::Constants qw [:Houses :Constraints :Diagonals];

 my $sudoku = Regexp::Sudoku:: -> new -> init (
    clues      => "...",
    diagonals  => $MAIN |. $MINOR,
    houses     => $NRC,
    constaints => $ANTI_KING;

=head1 DESCRIPTION

This module exports constants to be used to configure Sudoku variants
when using C<< Regexp::Sudoku >>.

All constants are bitmasks based on C<< vec >>. Constants are grouped
based on L<< Exporter >> tags; constants exported by the same tag
can be mixed using the bitwise operators: C<< |. >>, C<< &. >>
and C<< ~. >>.

There are three tags C<< :Houses >>, C<< :Constraints >> and
C<< :Diagonals >>. There is also the tag C<< :All >>, which can
be used to import all the constants.

We'll discuss the constants below, grouped by the tag which imports
them. (You can still import each constant individually if you wish
to do so).

=head2 C<< :Houses >>

These are used to signal the Sudoku variant uses additional houses.
For a description of each additional house, see
L<< Regexp::Sudoku >>.

The constants are used for the C<< houses >> parameter of the
C<< init >> function of C<< Regexp::Sudoku >>.

=over 2

=item C<< $NRC >>

This is for I<< NRC Sudokus >>; also called I<< Windokus >> or
I<< Hyper Sudokus >>.

=item C<< $ASTERISK >>

This is for I<< Asterisk Sudokus >>. 

=item C<< $GIRANDOLA >>

This is for I<< Girandola Sudokus >>. 

=item C<< $CENTER_DOT >>

This is for I<< center dot Sudokus >>.

=back

=head2 C<< :Constraints >>

These constants are used for the C<< constraints >> parameter, and
indicate which additionally constraints apply to the Sudoku variant.

=over 2

=item C<< $ANTI_KNIGHT >>

In an I<< Anti-Knight Sudoku >>, cells which are a Knights move away
(as in Chess) must be different.

=item C<< $ANTI_KING >>

In an I<< Anti-King Sudoku >>, cells which touch each other (including cells 
which only touch by their corners) must be different. These cells
corresponds with a Kings move in Chess. This type of Sudoku is also
known as a I<< No Touch Sudoku >>.

=back

=head2 C<< :Diagonals >>

Sudokus with constraints on I<< diagonals >> (the constraint being that
the cells on one or more diagonals should be different) are configured
with the C<< diagonals >> parameter, which takes one or more of the following
constants as argument. 

Note that there are many possible diagonals. For an C<< N x N >> Sudoku,
there are C<< 4 * N - 2 >> possible diagonals; for a standard C<< 9 x 9 >>
Sudoku, this means 34 possible diagonals. 

=over 2

=item C<< $MAIN >>

This is used if the cells on the main diagonal, running from the
top left to the bottom right, are all different. Aliases for 
C<< $MAIN >> and C<< $SUB0 >> and C<< $SUPER0 >>.

=item C<< $MINOR >>

This is used if the cells on the minor diagonal, running from the
bottom left to the top right, are all different. Aliases for 
C<< $MINOR >> and C<< $MINOR_SUB0 >> and C<< $MINOR_SUPER0 >>.

=item C<< $SUPER >>

The super diagonal is the diagonal which runs one cell above (or to the
right) of the main diagonal. This is an alias for C<< $SUPER1 >>.

=item C<< $SUB >>

The sub diagonal is the diagonal which runs one cell below (or to the
left) of the main diagonal. This is an alias for C<< $SUB1 >>.

=item C<< $MINOR_SUPER >>

The minor super diagonal is the diagonal which runs one cell above (or to the
left) of the minor diagonal. This is an alias for C<< $MINOR_SUPER1 >>.

=item C<< $MINOR_SUB >>

The minor sub diagonal is the diagonal which runs one cell below (or to the
right) of the main diagonal. This is an alias for C<< $MINOR_SUB1 >>.

=item C<< $SUPER1 .. $SUPER34 >>

C<< $SUPERM >> is the diagonal which runs parallel to the main diagonal,
C<< M >> cells above it (or to its right).

Note: If we have an C<< N x N >> Sudoku, then if C<< M >= N >>, 
this diagonal lies completely outside the Sudoku, and won't make any sense.
If C<< M == N - 1 >> the diagonal only contains a single cell (the one in
the top right corner), and will not contain any other cells to differ from.
For a standard C<< 9 x 9 >> Sudoku, the diagonals C<< $SUPER7 >>
and C<< $SUPER6 >> lie completely in the top right box, and hence, 
don't impose any additional constraints.

=item C<< $SUB1 .. $SUB34 >>

C<< $SUBM >> is the diagonal which runs parallel to the main diagonal,
C<< M >> cells below it (or to its left).

The Note above applies here as well.

=item C<< $MINOR_SUPER1 .. $MINOR_SUPER34 >>

C<< $MINOR_SUPERM >> is the diagonal which runs parallel to the minor diagonal,
C<< M >> cells above it (or to its left).

The Note above applies here as well.

=item C<< $MINOR_SUB1 .. $MINOR_SUB34 >>

C<< $MINOR_SUBM >> is the diagonal which runs parallel to the minor diagonal,
C<< M >> cells below it (or to its right).

The Note above applies here as well.

=item C<< $CROSS >>

This is a mask oring C<< $MAIN >> and C<< $MINOR >> together
(C<< $CROSS = $MAIN |. $MINOR >>). This is used to indicate cells
on both the main and minor diagonals should differ. This is a common
Sudoku variant, the I<< X-Sudoku >>. 

=item C<< $CROSS1 .. $CROSS34 >>

Each of those masks ors together the super, sub, minor super and minor sub
diagonals C<< M >> steps (for C<< $CROSSM >>) above/below the main and
minor diagonals. So, each C<< $CROSSM >> mask implies uniqueness 
constraints on four diagonals.

=item C<< $DOUBLE >>

This is an alias for C<< $CROSS1 >>, and is used for a Sudoku variant
where all the cells on the diagonals just next to the main and minor
diagonals should be unique.

=item C<< $TRIPLE >>

This mask combines C<< $CROSS >> and C<< $CROSS1 >> 
(C<< $TRIPLE = $CROSS |. $CROSS1 >>). This is used for the variant
where the cells on the six largest diagonals (the main and minor
diagonals, and the four right next to them) should be unique.

=item C<< $ARGYLE >>

This mask combines C<< $CROSS1 >> and C<< $CROSS4 >> and is used
for the I<< Argyle Sudoku >> variant. The eight diagonals of this
mask form a pattern known as an I<< argyle >> pattern.

=back

=head1 BUGS

There are no known bugs.

=head1 SEE ALSO

L<< Regexp::Sudoku >>.

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

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
