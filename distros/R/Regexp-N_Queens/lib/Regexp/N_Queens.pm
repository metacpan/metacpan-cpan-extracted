package Regexp::N_Queens;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use Hash::Util::FieldHash qw [fieldhash];

use lib qw [lib];

our $VERSION = '2023021701';

fieldhash my %size;
fieldhash my %pattern;
fieldhash my %subject;

my $queen  = "Q";
my $prefix = "Q";
my $sep    = ";";

my sub init_size;
my sub init_subject_and_pattern;
my sub name;
my sub all_groups;
my sub attacks;


################################################################################
#
# sub new ($class)
#
# Create a new, uninitialized object.
#
# IN:  $class: Package name
#
# OUT: Blessed object, uninitialized object
#
################################################################################

sub new ($class) {bless \do {my $v => $class}}


################################################################################
#
# sub init ($self, @args)
#
# Initialize the object.
#
# IN:  $self: Uninitialized object.
#      @args: Set of named parameters used to initialized the object.
#             We accept the following options:
#             - size => N: The size of the chess board (number of rows/columns)
#                          If no size parameter is given, the board will
#                          be assumed to have size 8, like a standard
#                          chess board.
#
#             As a special feature, the set of named parameter may also
#             be passed in as a hashref.
#
# OUT: Initialized object.
#
################################################################################

sub init ($self, @args) {
    my $args = @args == 1 && ref $args [0] eq "HASH" ? $args [0] : {@args};

    init_size ($self, $args);

    if (keys %$args) {
        die "Unknown parameter(s) to init: " . join (", " => keys %$args)
                                             . "\n";
    }

    $self;
}


################################################################################
#
# my sub init_size ($self, $args)
#
# Initialize the size of the board. This subroutine is called from init ().
# This is subroutine is lexical, and cannot be called from the outside.
#
# IN:  $self:  Current object
#      $args:  Hashref with parameters. Used (and then deleted) parameters:
#              - size => N: The size of the chess board (number of rows/columns)
#
# OUT: Current object
#
################################################################################

sub init_size ($self, $args) {
    $size {$self} = delete $$args {size} || 8;
    $self;
}


################################################################################
#
# sub size ($self)
#
# Return the size of the board.
#
# IN:  $self:  Current object
#
# OUT: Size of the board.
#
################################################################################

sub size ($self) {
    $size {$self}
}


################################################################################
#
# sub subject ($self)
#
# Return the subject to be matched against.
#
# IN:  $self:  Current object
#
# OUT: Subject
#
################################################################################

sub subject ($self) {
    init_subject_and_pattern ($self);
    $subject {$self};
}


################################################################################
#
# sub pattern ($self)
#
# Return the pattern to match against the subject.
#
# IN:  $self:  Current object
#
# OUT: Pattern
#
################################################################################

sub pattern ($self) {
    init_subject_and_pattern ($self);
    $pattern {$self};
}

################################################################################
#
# my sub name ($square)
#
# Return the name of the capture which captures the state of a square.
# This is a lexical sub, and not callable from the outside.
#
# IN:  $square: The square for which we want the name. A square is represented
#               as an 2-element array(ref), with an x and a y coordinate.
#
# OUT: Name of the capture.
#
################################################################################

sub name ($square) {
    join "_" => $prefix, @$square
}


################################################################################
#
# my sub all_groups (@squares)
#
# Give a list of squares, return a sub pattern, where we refer back to
# each capture group of said square. The sub pattern is terminated with
# a semi-colon.
#
# IN:  @squares: List of squares, where each square is represented by a
#                two element array, with an x and a y coordinate.
#
# OUT: A string with back references (\g{name}), terminated by a semi colon.
#
################################################################################

sub all_groups (@squares) {
    (join "" => map {my $name = name $_; "\\g{$name}"} @squares) . $sep
}


################################################################################
#
# my sub attacks ($sq1, $sq2)
#
# Returns true iff the two squares are a Queens move away from each other.
# That is, if both squares would contain a Queen, they will attack each other.
# This is a lexical sub, and not callable from the outside.
#
# IN:  $sq1, $sq2: The two squares of which we want to know whether they
#                  are in attacking range. Both squares are represented
#                  as 2-element arrays, with an x and a y coordinate.
#
# OUT: True if the squares are in attacking range, false otherwise.
#
################################################################################

sub attacks ($sq1, $sq2) {
    state $X = 0;
    state $Y = 1;
    return       $$sq1 [$X] == $$sq2 [$X]              || # Same column
                 $$sq1 [$Y] == $$sq2 [$Y]              || # Same row
    $$sq1 [$X] - $$sq2 [$X] == $$sq1 [$Y] - $$sq2 [$Y] || # Same diagonal
    $$sq1 [$X] - $$sq2 [$X] == $$sq2 [$Y] - $$sq1 [$Y]    # Same anti-diagonal
}


################################################################################
#
# my sub init_subject_and_pattern ($self)
#
# Calculate the subject and pattern. This method is called when the object
# is queried for either the subject or pattern. Once called, a second call
# will immediately return. As the subroutine is lexical, it cannot be 
# called from the outside.
#
# IN:  $self: Current object.
#
# OUT: Current object.
#
################################################################################

sub init_subject_and_pattern ($self) {
    return if $subject {$self} && $pattern {$self};

    my $subject = "";
    my $pattern = "";
    my $size    = $self -> size;

    #
    # Process each of the squares
    #
    my @previous_squares;
    foreach my $x (1 .. $size) {
        my @this_row;
        foreach my $y (1 .. $size) {
            my $this_square = [$x, $y];
            #
            # First, decide whether the square gets a Queen or not.
            # We capture this in a capture group ("Q_$x_$y"). If
            # we capture a 'Q', there is a Queen on the square, else
            # there is no Queen on the square.
            #
            my $this_group = name $this_square;
            $subject      .= "$queen$sep";
            $pattern      .= "(?<$this_group>$queen?)$queen?$sep";

            #
            # Now we compare this cell with each of the previous squares.
            # If they are a Queens move away (they can attack each other
            # if both of them have a Queen), the two squares may have at
            # most one Queen among them.
            #
            foreach my $previous_square (@previous_squares) {
                next unless attacks $this_square, $previous_square;
                my $prev_group = name $previous_square;
                $subject      .= "$queen$sep";
                $pattern      .= "\\g{$prev_group}\\g{$this_group}$queen?$sep";
            }
            push @previous_squares => $this_square;
            push @this_row         => $this_square;
        }
        #
        # We know there has to be exactly one Queen on each row.
        # Previous constraints already made sure we cannot have
        # more than one Queen, but it could have left us with 
        # no Queens at all. So, we add a constraint.
        #
        $subject .= "$queen$sep";
        $pattern .= all_groups @this_row;
        @this_row = ();
    }

    $subject {$self} =       $subject;
    $pattern {$self} = '^' . $pattern . '$';

    $self;
}


1;

__END__

=head1 NAME

Regexp::N_Queens - Abstract

=head1 SYNOPSIS

  use Regexp::N_Queens;

  my $N       = 8;
  my $solver  = Regexp::N_Queens:: -> new -> init (size => $N);
  my $subject = $solver -> subject;
  my $pattern = $solver -> pattern;
  if ($subject =~ $pattern) {
      foreach my $x (1 .. $N) {
          foreach my $y (1 .. $N) {
              print $+ {"Q_${x}_${y}"} ? "Q" : ".";
          }
          print "\n";
      }
  }
  else {
      say "No solution for an $N x $N board"
  }

=head1 DESCRIPTION

Solves the C<< N >>-Queens problem using a regular expression. The
C<< N >>-Queens problem asks you to place C<< N >> Queens on an 
C<< N x N >> chess board such that no two Queens attack each other.
There are solutions for each positive C<< N >>, except for C<< N == 2 >>
and C<< N == 3 >>.

After creating the solver object with C<< new >>, and initializing it
with C<< init >> (which takes a C<< size >> parameter indicating the size
of the board), the solver object can be queried by the methods
C<< subject >> and C<< pattern >>. Matching the pattern returned by
C<< pattern >> against the string returned by C<< subject >> solves the
C<< N >>-Queens problem: if there is a match, the Queens can be placed,
if there is no match, no solution exists.

If there is a match, the content of the board can be found in the
C<< %+ >> hash: for each square C<< (x, y) >> on the board, with
C<< 1 <= x, y <= N >>, we create a key C<< $key = "Q_${x}_${y}" >>.
We can now determine whether the field contain a Queen: if
C<< $+ {$key} >> is true, there is a Queen on the square, else, there
is no Queen.

Note that it doesn't matter in which corner of the board you place
the square C<< (1, 1) >>, nor which direction you give to C<< x >> and
C<< y >>, as each reflection and rotation of a solution to the
C<< N >>-Queens problem is also a solution.

=head1 BUGS

=head1 TODO

=over 2

=item * Perhaps sometime, write some tests.

=item * This isn't fast for larger C<< N >>. On the machine this module
was written on, it does sizes up to C<< 17 >>, and size C<< 19 >> in less
than 1 second, size C<< 18 >> in 3 seconds, size C<< 20 >> in 20 seconds,
size C<< 21 >> in 1 second, and it gets pretty bad for larger sizes.

Some optimizations may be possible.

=back

=head1 SEE ALSO

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Regexp-N_Queens.git >>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.freedom.nl >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2023 by Abigail.

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
