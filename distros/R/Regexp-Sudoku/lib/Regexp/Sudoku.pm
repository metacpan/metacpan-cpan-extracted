package Regexp::Sudoku;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022062101';

use lib qw [lib];

use Hash::Util::FieldHash qw [fieldhash];
use List::Util            qw [min max];

use Regexp::Sudoku::Utils;
use Regexp::Sudoku::Battenburg;
use Regexp::Sudoku::Quadruple;
use Regexp::Sudoku::Diagonal;
use Regexp::Sudoku::Parity;
use Regexp::Sudoku::Renban;
use Regexp::Sudoku::German_Whisper;

our @ISA = qw [
    Regexp::Sudoku::Battenburg
    Regexp::Sudoku::Quadruple
    Regexp::Sudoku::Diagonal
    Regexp::Sudoku::Parity
    Regexp::Sudoku::Renban
    Regexp::Sudoku::German_Whisper
];


fieldhash my %size;
fieldhash my %values;
fieldhash my %box_width;
fieldhash my %box_height;
fieldhash my %values_range;
fieldhash my %cell2houses;
fieldhash my %house2cells;
fieldhash my %clues;
fieldhash my %subject;
fieldhash my %pattern;
fieldhash my %constraints;


################################################################################
#
# new ($class)
#
# Create an uninitialized object.
#
################################################################################

sub new ($class) {bless \do {my $v} => $class}


################################################################################
#
# init_sizes ($self, $size)
#
# Initialize the sizes of the soduko.
#
# Calls init_size () and init_box () doing the work.
#
# TESTS: 010_size.t
#
################################################################################

sub init_sizes ($self, $args) {
    $self -> init_size ($args)
          -> init_box  ($args);
}


################################################################################
#
# init_size ($self, $size)
#
# Initialize the size of a sudoku. If the size is not given, use the default.
#
# TESTS: 010_size.t
#
################################################################################

sub init_size ($self, $args = {}) {
    $size {$self} = delete $$args {size} || $DEFAULT_SIZE;
    die "Size should not exceed $NR_OF_SYMBOLS\n"
               if $size {$self} > $NR_OF_SYMBOLS;
    $self;
}


################################################################################
#
# size ($self)
#
# Returns the size of the sudoku.
#
# TESTS: 010_size.t
#
################################################################################

sub size ($self) {
    $size {$self}
}


################################################################################
#
# init_values ($self, $args)
#
# Initializes the values. We calculate them from the range (1-9, A-Z),
# as many as needed.
#
# TESTS: 020_values.t
#
################################################################################

sub init_values ($self, $args = {}) {
    my $size   = $self -> size;
    my $values = join "" => 1 .. min $size, $NR_OF_DIGITS;
    if ($size > $NR_OF_DIGITS) {
        $values .= join "" =>
            map {chr (ord ('A') + $_ - $NR_OF_DIGITS - 1)}
                ($NR_OF_DIGITS + 1) .. min $size, $NR_OF_SYMBOLS;
    }

    $values {$self} = $values;
    $self -> init_values_range ($args);
    $self;
}


################################################################################
#
# init_value_ranges ($self, $args)
#
# Processes the values to turn them into ranges for use in a character class
#
# TESTS: 020_values.t
#
################################################################################

sub init_values_range ($self, $args = {}) {
    my @values = sort {$a cmp $b} $self -> values;
    my $size   = $self -> size;
    my $range  = "1-";

    if    ($size <  10) {$range .=         $values [-1];}
    elsif ($size == 10) {$range .= "9A";                }
    else                {$range .= "9A-" . $values [-1];}

    $values_range {$self} = $range;

    $self;
}


################################################################################
#
# values ($self)
#
# Return the set of values used in the sudoku. In list context, this will
# be an array of characters; in scalar context, a string.
#
# TESTS: 020_values.t
#
################################################################################

sub values ($self) {
    wantarray ? split // => $values {$self} : $values {$self};
}


################################################################################
#
# values_range ($self, $with_zero = 0)
#
# Return the set of values used in the sudoku, as ranges to be used in
# a character class. If $with_zero is true, we include '0' in the range
# as well. Note, '0' will *never* be an acceptable value.
#
# TESTS: 020_values.t
#
################################################################################

sub values_range ($self, $with_zero = 0) {
    my $range = $values_range {$self};
       $range =~ s/1/0/ if $with_zero;
       $range;
}


################################################################################
#
# init_box ($self, $args)
#
# Find the width and height of a box. If the size of the sudoku is a square,
# the width and height of a box are equal, and the square root of the size
# of the sudoku. Else, we'll find the most squarish width and height (with
# the width larger than the height). The width and height are stored as
# attributes. If they are already set, the function immediately returns.
#
# TESTS: 030-box.t
#
################################################################################

sub init_box ($self, $args = {}) {
    return if $box_height {$self} && $box_width {$self};
    my $size = $self -> size;
    my $box_height = int sqrt $size;
    $box_height -- while $size % $box_height;
    my $box_width  = $size / $box_height;

    $box_height {$self} = $box_height;
    $box_width  {$self} = $box_width;

    $self;
}


################################################################################
#
# box_height ($self)
# box_width  ($self)
#
# Return the height and width of a box in the sudoku. These methods will
# call $self -> box_init first, to calculate the values if necessary.
#
# TESTS: 030_values.t
#
################################################################################

sub box_height ($self) {
    $box_height {$self};
}

sub box_width ($self) {
    $box_width {$self};
}


################################################################################
#
# create_house ($self, $house_name, @cells)
#
# Create a house with the given name, containing the passed in cells.
#
# TESTS: 040-create_house.t
#
################################################################################

sub create_house ($self, $name, @cells) {
    for my $cell (@cells) {
        $cell2houses {$self} {$cell} {$name} = 1;
        $house2cells {$self} {$name} {$cell} = 1;
    }
    $self;
}


################################################################################
#
# init_rows ($self, $args)
#
# Initialize the rows in the sudoku. Calculates which cells belong to which
# rows, and calls create_house for each row. Called from init_houses.
# Rows are named "R1" .. "Rn", where n is the size of the sudoku.
#
# TESTS: 041-init_rows
#
################################################################################

sub init_rows ($self, $args = {}) {
    my $size = $self -> size;
    for my $r (1 .. $size) {
        my $row_name = "R$r";
        my @cells    = map {cell_name $r, $_} 1 .. $size;
        $self -> create_house ($row_name, @cells);
    }
    $self;
}


################################################################################
#
# init_columns ($self, $args)
#
# Initialize the columns in the sudoku. Calculates which cells belong to which
# columns, and calls create_house for each column. Called from init_houses.
# Columns are named "C1" .. "Cn", where n is the size of the sudoku.
#
# TESTS: 042-init_columns
#
################################################################################

sub init_columns ($self, $args = {}) {
    my $size = $self -> size;
    for my $c (1 .. $size) {
        my $col_name = "C$c";
        my @cells    = map {cell_name $_, $c} 1 .. $size;
        $self -> create_house ($col_name, @cells);
    }
    $self;
}


################################################################################
#
# init_boxes ($self, $args)
#
# Initialize the boxes in the sudoku. Calculates which cells belong to which
# boxes, and calls create_house for each box. Called from init_houses.
# Boxes are named "B1-1" .. "Bh-w" where we have h rows of w boxes.
#
# TESTS: 043-init_boxes
#
################################################################################

sub init_boxes ($self, $args = {}) {
    my $size       = $self -> size;
    my $box_width  = $self -> box_width;
    my $box_height = $self -> box_height;

    my $bc = $size / $box_width;
    my $br = $size / $box_height;
    for my $r (1 .. $br) {
        for my $c (1 .. $bc) {
            my $box_name = "B${r}-${c}";
            my $tlr = 1 + ($r - 1) * $box_height;
            my $tlc = 1 + ($c - 1) * $box_width;
            my @cells;
            for my $dr (1 .. $box_height) {
                for my $dc (1 .. $box_width) {
                    my $cell = cell_name $tlr + $dr - 1, $tlc + $dc - 1;
                    push @cells => $cell;
                }
            }
            $self -> create_house ($box_name, @cells);
        }
    }
    $self;
}


################################################################################
#
# init_houses ($self, $args)
#      init_rows    ($self)
#      init_columns ($self)
#      init_boxes   ($self)
#
# Calculate which cells go into which houses.
#
# Calls init_rows (), init_columns (), and init_boxes () to initialize
# the rows, columns and boxes. 
#
# TESTS: 045-init_houses.t
#
################################################################################

sub init_houses ($self, $args = {}) {
    $self -> init_rows     ($args)
          -> init_columns  ($args)
          -> init_boxes    ($args)
}


################################################################################
#
# set_nrc_houses ($self, $args)
#
# For NRC style puzzles, handle creating the houses.
#
# There are four NRC houses (9 x 9 Sudokus only):
#
#     . . .  . . .  . . .
#     . * *  * . *  * * .
#     . * *  * . *  * * .
#
#     . * *  * . *  * * .
#     . . .  . . .  . . .
#     . * *  * . *  * * .
#
#     . * *  * . *  * * .
#     . * *  * . *  * * .
#     . . .  . . .  . . .
#
#
# TESTS: 046-set_nrc_houses.t
#
################################################################################

sub set_nrc_houses ($self, $args = {}) {
    return $self unless $self -> size == $DEFAULT_SIZE;

    my @top_left = ([2, 2], [2, 6], [6, 2], [6, 6]);
    foreach my $i (keys @top_left) {
        my $top_left = $top_left [$i];
        my $house = "NRC" . ($i + 1);
        my @cells;
        foreach my $dr (0 .. 2) {
            foreach my $dc (0 .. 2) {
                my $cell = cell_name $$top_left [0] + $dr,
                                     $$top_left [1] + $dc;
                push @cells => $cell;
            }
        }
        $self -> create_house ($house, @cells);
    }

    $self;
}


################################################################################
#
# sub set_asterisk_house ($self, $args)
#
# An asterisk sudoku has an additional house: one cell from each box.
# This method initializes that house.
#
# An asterisk is defined for a 9 x 9 sudoku as follows:
#
#     . . .  . . .  . . .
#     . . .  . * .  . . .
#     . . *  . . .  * . .
#
#     . . .  . . .  . . .
#     . * .  . * .  . * .
#     . . .  . . .  . . .
#
#     . . *  . . .  * . .
#     . . .  . * .  . . .
#     . . .  . . .  . . .
#
# TESTS: 047-set_asterisk_house.t
#
################################################################################

sub set_asterisk_house ($self, $args = {}) {
    return $self unless $self -> size == $DEFAULT_SIZE;

    $self -> create_house ("AS" => map {cell_name @$_}
                                       [3, 3], [2, 5], [3, 7],
                                       [5, 2], [5, 5], [5, 8],
                                       [7, 3], [8, 5], [7, 7]);
}


################################################################################
#
# sub set_girandola_house ($self, $args)
#
# An girandola sudoku has an additional house: one cell from each box.
# This method initializes that house.
#
# An girandola is defined for a 9 x 9 sudoku as follows:
#
#     * . .  . . .  . . *
#     . . .  . * .  . . .
#     . . .  . . .  . . .
#
#     . . .  . . .  . . .
#     . * .  . * .  . * .
#     . . .  . . .  . . .
#
#     . . .  . . .  . . .
#     . . .  . * .  . . .
#     * . .  . . .  . . *
#
# TESTS: 048-set_girandola_house.t
#
################################################################################

sub set_girandola_house ($self) {
    return $self unless $self -> size == $DEFAULT_SIZE;

    $self -> create_house ("GR" => map {cell_name @$_}
                                       [1, 1], [2, 5], [1, 9],
                                       [5, 2], [5, 5], [5, 8],
                                       [9, 1], [8, 5], [9, 9]);
}

################################################################################
#
# sub set_center_dot_house ($self, $args)
#
# An center dot sudoku has an additional house: one cell from each box.
# This method initializes that house.
#
# A center dot is defined for a 9 x 9 sudoku as follows:
#
#     . . .  . . .  . . .
#     . * .  . * .  . * .
#     . . .  . . .  . . .
#
#     . . .  . . .  . . .
#     . * .  . * .  . * .
#     . . .  . . .  . . .
#
#     . . .  . . .  . . .
#     . * .  . * .  . * .
#     . . .  . . .  . . .
#
# TESTS: 049-set_center_dot_house.t
#
################################################################################

sub set_center_dot_house ($self) {
    my $width  = $self -> box_width;
    my $height = $self -> box_height;
    my $size   = $self -> size;

    #
    # We can only do center dots if boxes are odd sized width and heigth.
    #
    return $self unless $width % 2 && $height % 2;

    my $width_start  = ($width  + 1) / 2;
    my $height_start = ($height + 1) / 2;

    my @center_cells;
    for (my $x = $width_start; $x <= $size; $x += $width) {
        for (my $y = $height_start; $y <= $size; $y += $height) {
            push @center_cells => [$x, $y];
        }
    }

    $self -> create_house ("CD" => map {cell_name @$_} @center_cells);
}




################################################################################
#
# cell2houses ($self, $cell)
#
# Give the name of a cell, return the names of all the houses this cell
# is part off.
#
# TESTS: 040-houses.t
#
################################################################################

sub cell2houses ($self, $cell) {
    keys %{$cell2houses {$self} {$cell} || {}}
}


################################################################################
#
# house2cells ($self, $house)
#
# Give the name of a house, return the names of all the cells in this house.
#
# TESTS: 040-houses.t
#
################################################################################

sub house2cells ($self, $house) {
    keys %{$house2cells {$self} {$house} || {}}
}


################################################################################
#
# cells ($self, $sorted = 0)
#
# Return the names of all the cells in the sudoku.
#
# If we want the cells to be sorted, then we use the following priorities:
#    * Clues go first
#    * Odd/Even cells go next
#    * Then the other cells
#    * Ties are broken in the following fashion:
#        * The more clues seen, the better
#        * The smallest Renban area the cell is in, the better
#        * The more houses the cell is in, the better.
#        
# TESTS: 040-houses.t
#
################################################################################

sub cells  ($self, $sorted = 0) {
    my @cells = sort keys %{$cell2houses  {$self}};
    if ($sorted) {
        state $CELL_NAME    = 0;
        state $IS_CLUE      = $CELL_NAME    + 1;
        state $EVEN_ODD     = $IS_CLUE      + 1;
        state $CLUES_SEEN   = $EVEN_ODD     + 1;
        state $NR_OF_HOUSES = $CLUES_SEEN   + 1;
        state $RENBAN       = $NR_OF_HOUSES + 1;
        state $GERMAN       = $RENBAN       + 1;
        state $QUADRUPLE    = $GERMAN       + 1;

        #
        # For each cell, determine how many different clues it sees.
        #
        my %sees;
        foreach my $cell1 (@cells) {
            next if $self -> clue ($cell1);  # Don't care about clues
            foreach my $cell2 (@cells) {
                if ($self -> clue ($cell2) &&
                    $self -> must_differ ($cell1, $cell2)) {
                    $sees {$cell1} {$self -> clue ($cell2)} = 1;
                }
            }
        }

        @cells = map  {$$_ [$CELL_NAME]}
                 sort {$$b [$IS_CLUE]      <=> $$a [$IS_CLUE]        ||       
                       $$b [$EVEN_ODD]     <=> $$a [$EVEN_ODD]       ||      
                       $$b [$CLUES_SEEN]   <=> $$a [$CLUES_SEEN]     ||   
                       $$a [$RENBAN]       <=> $$b [$RENBAN]         ||
                       $$b [$GERMAN]       <=> $$a [$GERMAN]         ||
                       $$b [$QUADRUPLE]    <=> $$a [$QUADRUPLE]      ||
                       $$b [$NR_OF_HOUSES] <=> $$a [$NR_OF_HOUSES]   ||
                       $$a [$CELL_NAME]    cmp $$b [$CELL_NAME]}
                 map  {my $r = [];
                       $$r [$CELL_NAME]     =  $_;
                       $$r [$IS_CLUE]       =  $self -> clue ($_)    ? 1 : 0;
                       $$r [$EVEN_ODD]      =  $self -> is_even ($_) ||
                                               $self -> is_odd  ($_) ? 1 : 0;
                       $$r [$CLUES_SEEN]    =  keys (%{$sees {$_}    || {}});
                       $$r [$NR_OF_HOUSES]  =  $self -> cell2houses  ($_);
                       $$r [$GERMAN]        =  $self -> cell2germans ($_);
                       #
                       # Find the *smallest* renban the cell is in
                       #
                       $$r [$RENBAN]        =
                           (min map {scalar $self -> renban2cells ($_)}
                               $self -> cell2renbans ($_)) // $self -> size;

                       #
                       # Assign quadruple points for each cell. A cell
                       # gets points for each quadruple it is, and more
                       # points the more values are in the quadruple.
                       # More quadruples counts for more though.
                       #
                       $$r [$QUADRUPLE]     = 0;
                       foreach my $quadruple ($self -> cell2quadruples ($_)) {
                           $$r [$QUADRUPLE] += 10;
                           $$r [$QUADRUPLE] ++ for
                                $self -> quadruple_values ($quadruple);
                       }

                       $r}
                 @cells;
    }
    @cells;
}


################################################################################
#
# houses ($self)
#
# Return the names of all the houses in the sudoku.
#
# TESTS: 040-houses.t
#
################################################################################

sub houses ($self) {
    keys %{$house2cells  {$self}}
}


################################################################################
#
# set_clues ($self, $args)
#
# Take the supplied clues (if any!), and return a structure which maps cell
# names to clue values.
#
# The clues could be one of:
#   - A 2-d array, with false values indicating the cell doesn't have a clue.
#     A "." will also be consider to be not a clue.
#   - A string, newlines separating rows, and whitespace clues. A value
#     of 0 or "." indicates no clue.
#
# We wil populate the clues attribute, mapping cell names to clue values.
# Cells without clues won't be set.
#
# TESTS: 080-set_clues.t
#
################################################################################

sub set_clues ($self, $in_clues) {
    my $clues   = {};
    #
    # Turn a string into an array
    #
    if (!ref $in_clues) {
        my @rows  = grep {/\S/} split /\n/ => $in_clues;
        $in_clues = [map {[split]} @rows];
    }
    foreach my $r (keys @$in_clues) {
        foreach my $c (keys @{$$in_clues [$r]}) {
            my $val  = $$in_clues [$r] [$c];
            next if !$val || $val eq ".";
            my $cell = cell_name $r + 1, $c + 1;
            if    ($val eq 'e') {$self -> set_is_even ($cell)}
            elsif ($val eq 'o') {$self -> set_is_odd  ($cell)}
            else                {$$clues   {$cell} = $val}
        }
    }
    $clues   {$self} = $clues;

    $self;
}


################################################################################
#
# clues ($self)
#
# Return an hashref mapping cell names to clues.
#
# TESTS: 080-clues.t
#
################################################################################

sub clues ($self) {
    $clues {$self};
}


################################################################################
#
# clue ($self, $cell)
#
# Returns the clue in the given cell. If the cell does not have a clue,
# return false.
#
# TESTS: 080-clues.t
#
################################################################################

sub clue     ($self , $cell) {
    $clues   {$self} {$cell}
}


################################################################################
#
# set_anti_knight_constraint ($self)
# set_anti_king_constraint ($self)
#
# Set the anti knigt/anti king constraints for the sudoku.
#
# TESTS: 151-must-differ.t
#
################################################################################

sub set_anti_knight_constraint ($self) {
    $constraints {$self} {$ANTI_KNIGHT} = 1;
    $self;
}

sub set_anti_king_constraint ($self) {
    $constraints {$self} {$ANTI_KING} = 1;
    $self;
}



################################################################################
#
# init ($self, %args)
#
# Configure the Regexp::Sudoku object. 
#
# TESTS: *.t
#
################################################################################


sub init ($self, %args) {
    my $args = {%args};

    $self -> init_sizes  ($args)
          -> init_values ($args)
          -> init_houses ($args);

    if (keys %$args) {
        die "Unknown parameter(s) to init: " . join (", " => keys %$args)
                                             . "\n";
    }

    $self;
}


################################################################################
#
# make_clue_statement ($self, $cell, $value)
#
# Given a cell name, and a value, return a sub subject, and sub pattern
# which sets the capture '$cell' to '$value'
#
# TESTS: 110-make_clue_statement.t
#        120-make_cell_statement.t
#
################################################################################

sub make_clue_statement ($self, $cell) {
    my $value  = $self -> clue ($cell);
    my $subsub = $value;
    my $subpat = "(?<$cell>$value)";

    map {$_ . $SENTINEL} $subsub, $subpat;
}


################################################################################
#
# make_empty_statement ($cell)
#
# Given a cell name, return a sub subject and a sub pattern allowing the
# cell to pick up one of the values in the sudoku.
#
# TESTS: 100-make_empty_statement.t
#        120-make_cell_statement.t
#
################################################################################

sub make_empty_statement ($self, $cell, $method = "values") {
    my $subsub = $self -> $method;
    my $range  = $self -> values_range;
    my $subpat = "[$range]*(?<$cell>[$range])[$range]*";

    map {$_ . $SENTINEL} $subsub, $subpat;
}

sub make_any_statement  ($self, $cell) {
    $self -> make_empty_statement ($cell, "values")
}


################################################################################
#
# make_cell_statement ($cell)
#
# Given a cell name, return a subsubject and subpattern to set a value for
# this cell. Either the cell has a clue (and we dispatch to make_clue),
# or not (and we dispatch to make_empty).
#
# TESTS: 120-make_cell_statement.t
#
################################################################################

sub make_cell_statement ($self, $cell) {
    my $clue = $self -> clue ($cell);

      $self -> clue    ($cell) ? $self -> make_clue_statement ($cell)
    : $self -> is_even ($cell) ? $self -> make_even_statement ($cell)
    : $self -> is_odd  ($cell) ? $self -> make_odd_statement  ($cell)
    :                            $self -> make_any_statement  ($cell)
}



################################################################################
#
# make_diff_statement ($self, $cell1, $cell2)
#
# Given two cell names, return a sub subject and a sub pattern which matches
# iff the values in the cell differ.
#
# TESTS: 140-make_diff_statement.t
#
################################################################################

sub make_diff_statement ($self, $cell1, $cell2) {
    my $subsub = "";
    my @values = $self -> values;
    my $range  = $self -> values_range;

    my $seq = semi_debruijn_seq (scalar $self -> values);
    my $pat = "[$range]*\\g{$cell1}\\g{$cell2}[$range]*";

    map {$_ . $SENTINEL} $seq, $pat;
}


################################################################################
#
# must_differ ($self, $cell1, $cell2)
#
# Returns a true value if the two given cells must have different values.
#
# TESTS: 150-must_differ.t
#        151-must_differ.t
#
################################################################################

sub must_differ ($self, $cell1, $cell2) {
    my %seen;
    $seen {$_} ++ for $self -> cell2houses ($cell1),
                      $self -> cell2houses ($cell2);

    my $same_house   = grep {$_ > 1} values %seen;

    my ($r1, $c1)    = cell_row_column ($cell1);
    my ($r2, $c2)    = cell_row_column ($cell2);

    my $d_rows       = abs ($r1 - $r2);
    my $d_cols       = abs ($c1 - $c2);

    my $constraints = $constraints {$self};
    return $same_house
        || $$constraints {$ANTI_KNIGHT} && (($d_rows == 1 && $d_cols == 2) ||
                                            ($d_rows == 2 && $d_cols == 1))
        || $$constraints {$ANTI_KING}   &&   $d_rows == 1 && $d_cols == 1
        ? 1 : 0;
}


################################################################################
#
# init_subject_and_pattern ($self)
#
# Create the subject we're going to match against, and the pattern
# we use to match.
#
# TESTS: TODO
#
################################################################################

sub init_subject_and_pattern ($self) {
    return $self if $subject {$self} && $pattern {$self};

    my $subject = "";
    my $pattern = "";

    my @cells   = $self -> cells (1);

    my %seen;

    for my $i (keys @cells) {
        #
        # First the part which picks up a value for this cell
        #
        my $cell1 = $cells [$i];

        my ($subsub, $subpat) = $self -> make_cell_statement ($cell1);
        $subject .= $subsub;
        $pattern .= $subpat;

        $seen {$cell1} = 1;

        #
        # Now, for all the previous cells, if there are constraints
        # between them, add statements for each constraint.
        #
        for my $j (0 .. $i - 1) {
            my $cell2 = $cells [$j];
            #
            # If both cells are a clue, we don't need a restriction
            # between the cells.
            #
            next if $self -> clue ($cell1) && $self -> clue ($cell2);

            my ($subsub, $subpat) = ("", "");
            my  $differs = 0;
            my  @todo;

            if (my @renbans = $self -> same_renban ($cell1, $cell2)) {
                push @todo => "make_renban_statement";
                $differs = 1;
            }

            if ($self -> same_battenburg ($cell1, $cell2)) {
                push @todo => "make_battenburg_statement";
            }

            if ($self -> consecutive_in_german_whisper ($cell1, $cell2)) {
                push @todo => "make_german_whisper_statement";
                $differs = 1;
            }

            if (!$differs && $self -> must_differ ($cell1, $cell2)) {
                push @todo => "make_diff_statement";
            }

            foreach my $method (@todo) {
                my ($subsub, $subpat) = $self -> $method ($cell1, $cell2);
                $subject .= $subsub;
                $pattern .= $subpat;
            }
        }

        #
        # If the cell is part of an anti-Battenburg, and if the cell
        # is the last cell seen of that anti-Battenburg, add the
        # contraints.
        #
        foreach my $anti_battenburg ($self -> cell2anti_battenburgs ($cell1)) {
            my @cells = $self -> anti_battenburg2cells ($anti_battenburg);
            if (@cells == grep {$seen {$_}} @cells) {
                my ($subsub, $subpat) =
                    $self -> make_anti_battenburg_statement ($anti_battenburg);
                $subject .= $subsub;
                $pattern .= $subpat;
            }
        }

        #
        # If the cell is part of a quadruple constraint, and if the cell
        # is the last cell seen of this quadruple, add the constraints
        # for the quadruple.
        #
        foreach my $quadruple ($self -> cell2quadruples ($cell1)) {
            my @cells = $self -> quadruple2cells ($quadruple);
            if (@cells == grep {$seen {$_}} @cells) {
                my ($subsubs, $subpats) =
                    $self -> make_quadruple_statements ($quadruple);
                foreach my $i (keys @$subsubs) {
                    $subject .= $$subsubs [$i];
                    $pattern .= $$subpats [$i];
                }
            }
        }
    }

    $subject {$self} =       $subject;
    $pattern {$self} = "^" . $pattern . '$';

    $self;
}


################################################################################
#
# subject ($self)
#
# Return the subject we're matching against.
#
# TESTS: Test.pm
#
################################################################################

sub subject ($self) {
    $self -> init_subject_and_pattern;
    $subject {$self}
}


################################################################################
#
# pattern ($self)
#
# Return the pattern we're matching with.
#
# TESTS: Test.pm
#
################################################################################

sub pattern ($self) {
    $self -> init_subject_and_pattern;
    $pattern {$self}
}

1;


__END__
