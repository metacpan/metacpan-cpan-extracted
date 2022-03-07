package Regexp::Sudoku;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022030401';

use Hash::Util::FieldHash qw [fieldhash];
use List::Util            qw [min max];
use Math::Sequence::DeBruijn;

use Exporter ();

my $DEFAULT_SIZE   = 9;
my $SENTINEL       = "\n";
my $CLAUSE_LIST    = ",";

my $NR_OF_DIGITS   =  9;
my $NR_OF_LETTERS  = 26;
my $NR_OF_SYMBOLS  = $NR_OF_DIGITS + $NR_OF_LETTERS;

my $ANTI_KNIGHT    = 1;
my $ANTI_KING      = 2;

my $MAIN_DIAGONAL  = 1;
my $MINOR_DIAGONAL = 2;

fieldhash my %size;
fieldhash my %values;
fieldhash my %evens;
fieldhash my %odds;
fieldhash my %box_width;
fieldhash my %box_height;
fieldhash my %values_range;
fieldhash my %cell2houses;
fieldhash my %house2cells;
fieldhash my %clues;
fieldhash my %is_even;
fieldhash my %is_odd;
fieldhash my %subject;
fieldhash my %pattern;
fieldhash my %constraints;
fieldhash my %renban2cells;
fieldhash my %cell2renbans;


my sub has_bit ($vec) {$vec =~ /[^\x{00}]/}


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
# sub cell_name ($row, $column)
#
# Given a row number and a cell number, return the name of the cell.
#
# TESTS: 090-cell_name_row_column.t
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
# TESTS: 090-cell_name_row_column.t
#
################################################################################

sub cell_row_column ($name) {
    $name =~ /R([0-9]+)C([0-9]+)/ ? ($1, $2) : (0, 0)
}


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
# Returns the size of the sudoku. If there is no size supplied, use 
# the default (9).
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

    my $evens = do {my $i = 1; join "" => grep {$i = !$i} split // => $values};
    my $odds  = do {my $i = 0; join "" => grep {$i = !$i} split // => $values};

    $values {$self} = $values;
    $evens  {$self} = $evens;
    $odds   {$self} = $odds;

    $self -> init_values_range ($args);
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
# evens ($self)
#
# Return the set of even values used in the sudoku. In list context, this will
# be an array of characters; in scalar context, a string.
#
# TESTS: 020_values.t
#
################################################################################

sub evens ($self) {
    wantarray ? split // => $evens  {$self} : $evens  {$self};
}


################################################################################
#
# odds ($self)
#
# Return the set of odd values used in the sudoku. In list context, this will
# be an array of characters; in scalar context, a string.
#
# TESTS: 020_values.t
#
################################################################################

sub odds  ($self) {
    wantarray ? split // => $odds   {$self} : $odds   {$self};
}


################################################################################
#
# values_range ($self)
#
# Return the set of values used in the sudoku, as ranges to be used in
# a character class. Calls $self -> values () to get the values.
#
# TESTS: 020_values.t
#
################################################################################

sub values_range ($self) {
    $values_range {$self}
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
# TESTS: 050-set_diagonals.t
#        051-set_diagonals.t
#        052-set_diagonals.t
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
# cells ($self)
#
# Return the names of all the cells in the sudoku.
#
# TESTS: 040-houses.t
#
################################################################################

sub cells  ($self, $sorted = 0) {
    my @cells = sort keys %{$cell2houses  {$self}};
    if ($sorted) {
        state $CELL_NAME    = 0;
        state $IS_CLUE      = $CELL_NAME  + 1;
        state $EVEN_ODD     = $IS_CLUE    + 1;
        state $CLUES_SEEN   = $EVEN_ODD   + 1;
        state $NR_OF_HOUSES = $CLUES_SEEN + 1;

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
                       $$b [$NR_OF_HOUSES] <=> $$a [$NR_OF_HOUSES]   ||
                       $$a [$CELL_NAME]    cmp $$b [$CELL_NAME]}
                 map  {my $r = [];
                       $$r [$CELL_NAME]     =  $_;
                       $$r [$IS_CLUE]       =  $self -> clue ($_)    ? 1 : 0;
                       $$r [$EVEN_ODD]      =  $self -> is_even ($_) ||
                                               $self -> is_odd  ($_) ? 1 : 0;
                       $$r [$CLUES_SEEN]    =  keys (%{$sees {$_}    || {}});
                       $$r [$NR_OF_HOUSES]  =  $self -> cell2houses ($_);
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
    my $is_even = {};
    my $is_odd  = {};
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
            if    ($val eq 'e') {$$is_even {$cell} = 1}
            elsif ($val eq 'o') {$$is_odd  {$cell} = 1}
            else                {$$clues   {$cell} = $val}
        }
    }
    $clues   {$self} = $clues;
    $is_even {$self} = $is_even;
    $is_odd  {$self} = $is_odd;

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
# is_even ($self, $cell)
# is_odd  ($self, $cell)
#
# Returns wether the cell is given to be even/odd. 
#
# TESTS: 081-is_even_odd.t
#
################################################################################

sub is_even  ($self,  $cell) {
    $is_even {$self} {$cell}
}
sub is_odd   ($self,  $cell) {
    $is_odd  {$self} {$cell}
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
# set_renban ($self, @cells)
#
# Initialize any renban lines/areas
#
# TESTS: 170-set_renban.t
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
# TESTS: 170-set_renban.t
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
# TESTS: 170-set_renban.t
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
# TESTS: 171-same_renban.t
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
sub make_even_statement ($self, $cell) {
    $self -> make_empty_statement ($cell, "evens")
}
sub make_odd_statement  ($self, $cell) {
    $self -> make_empty_statement ($cell, "odds")
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
# semi_debruijn_seq
#
# Return, for the given values, a De Bruijn sequence of size 2 with
#  1) Duplicates removed and
#  2) The first character copied to the end
#
# TESTS: 130-semi_debruijn_seq.t
#
################################################################################

sub semi_debruijn_seq ($self, $values = $values {$self}) {
    state $cache;
    $$cache {$values} //= do {
        my $seq = debruijn ($values, 2);
        $seq .= substr $seq, 0, 1;  # Copy first char to the end.
        $seq  =~ s/(.)\g{1}/$1/g;   # Remove duplicates.
        $seq;
    };
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
# TESTS: 140-make_renban_statement.t
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

    my $seq = $self -> semi_debruijn_seq;
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

    for my $i (keys @cells) {
        #
        # First the part which picks up a value for this cell
        #
        my $cell1 = $cells [$i];

        my ($subsub, $subpat) = $self -> make_cell_statement ($cell1);
        $subject .= $subsub;
        $pattern .= $subpat;

        #
        # Now, for all the previous cells, if there is a constraint
        # between them, add a clause for them.
        #
        for my $j (0 .. $i - 1) {
            my $cell2 = $cells [$j];
            #
            # If both cells are a clue, we don't need a restriction
            # between the cells.
            #
            next if $self -> clue ($cell1) && $self -> clue ($cell2);

            my ($subsub, $subpat);

            if (my @renbans = $self -> same_renban ($cell1, $cell2)) {
                ($subsub, $subpat) = $self -> make_renban_statement
                                                 ($cell1, $cell2);
            }
            elsif ($self -> must_differ ($cell1, $cell2)) {
                ($subsub, $subpat) = $self -> make_diff_statement
                                                 ($cell1, $cell2);
            }

            if ($subsub && $subpat) {
                $subject .= $subsub;
                $pattern .= $subpat;
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
=begin html

<style>
    ul#index::before {
        content:                  "Regexp::Sudoku";
        font-size:                            300%;
        font-family:                     monospace;
        font-weight:                          bold;
        text-align:                         center;
        line-height:                           2em;
        margin-left:                           30%;
        margin-top:                           -1em;
    }
    ul#index li ul li ul li {
        font-family:                     monospace;
    }
    html {
        margin-left:                            5%;
        margin-right:                          10%;
    }
    h1 {
        margin-left:                           -4%;
    }
    h2 {
        margin-left:                           -3%;
    }
    h3 {
        margin-left:                           -2%;
    }
    pre {
        background:                          black;
        padding-top:                           1em;
        padding-bottom:                        1em;
        border-radius:                         1em;
    }
    pre code {
        color:                          lightgreen;
    }
</style>

=end html

=head1 NAME

Regexp::Sudoku - Solve Sudokus with regular expressions.

=head1 SYNOPSIS

 use Regexp::Sudoku;
 my $sudoku = Regexp::Sudoku:: -> new -> init
                                      -> set_clues (<<~ '--');
     5 3 .  . 7 .  . . .
     6 . .  1 9 5  . . .
     . 9 8  . . .  . 6 .

     8 . .  . 6 .  . . 3
     4 . .  8 . 3  . . 1
     7 . .  . 2 .  . . 6

     . 6 .  . . .  2 8 .
     . . .  4 1 9  . . 5
     . . .  . 8 .  . 7 9
     --

 my $subject = $sudoku -> subject;
 my $pattern = $sudoku -> pattern;

 if ($subject =~ $pattern) {
    for my $row (1 .. 9) {
        for my $col (1 .. 9) {
            print $+ {"R${r}C${c}"}, " ";
        }
        print "\n";
    }
 }

=head1 DESCRIPTION

This module takes a Sudoku (or variant) as input, calculates a subject
and pattern, such that, if the pattern is matched agains the subject,
the match succeeds if, and only if, the Sudoku has a solution. And if
it has a solution C<< %+ >> is populated with the values of the cells of
the solved Sudoku.

After constructing, initializing and constructing a Sudoku object using
C<< new >>, C<< init >> and various C<< set_* >> methods (see below),
the object can be queried
with C<< subject >> and C<< pattern >>. C<< subject >> returns 
a string, while C<< pattern >> returns a pattern (as a string).

Once the subject has been matched against the pattern, 81 (or rather
C<< N ** 2 >> for an C<< N x N >> Sudoku) named captures will be set:
C<< R1C1 >> .. C<< R1C9 >> .. C<< R9C1 >> .. C<< R9C9 >>. These correspond
to the values of the cells of a solved Sudoku, where the cell in the
top left is named C<< R1C1 >>, the cell in the top right C<< R1C9 >>,
the cell in the bottom left C<< R9C1 >> and the cell in the bottom right
C<< R9C9 >>. In general, the cell on row C<< r >> and column C<< c >>
is named C<< RrCc >>. Named captures are available in C<< %+ >>
(see L<< perlvar >>).

For regular, C<< 9 x 9 >> Sudokus, one would just call C<< new >>,
C<< init >> and C<< set_clues >>. Various variants need to call
different methods.

Unless specified otherwise, all the methods below return the object
it was called with; this methods can be chained.

=head2 Main methods

=head3 C<< new () >>

This is a I<< class >> method called on the C<< Regexp::Sudoku >>
package. It takes no arguments, and just returns an uninitialized
object. (Basically, it just calls C<< bless >> for you).

=head3 C<< init () >>

C<< init >> initializes the Sudoku object. This method B<< must >> 
be called on the return value of C<< new >> before calling any other
methods.

C<< init >> takes one, optional, (named) argument.

=over 4

=item C<< size => INTEGER >>

Usually, Sudokus are C<< 9 x 9 >>. For a Sudoku of a different size,
we need to pass in the size. Smallest size for which Sudokus exist,
is C<< 4 >>. Largest size we accept is C<< 35 >>. For a Sudoku with
a size exceeding 9, we will letters as values. (So, for a C<< 12 x 12 >>
Sudoku, we have C<< 1 .. 9, 'A', 'B' >> as values.)

The size directly influences the size of the boxes (the rectangles where
each of the numbers appears exactly once). For a size C<< N >>, the size
of a box will be those integers C<< p >> and C<< q >> where C<< N = p * q >>,
and which minimizes C<< abs (p - q) >>. Common sizes lead to the following
box sizes:

    size (N x N) | box size (width x height)
    =============+==========================
          4 *    |      2 x 2
          6      |      3 x 2
          8      |      4 x 2
          9 *    |      3 x 3  (Default)
         10      |      5 x 2
         12      |      4 x 3
         15      |      5 x 3
         16 *    |      4 x 4
         24      |      6 x 4
         25 *    |      5 x 5
         30      |      6 x 5
         35      |      7 x 5

Sizes which are perfect squares (marked with C<< * >> in the table above)
lead to square boxes.

A size which is a prime number leads to boxes which are identical to
rows -- you would need to configure different boxes.

=back

=head3 C<< set_clues (STRING | ARRAYREF) >>

The C<< set_clues >> method is used to pass in the clues (aka givens)
of a Suduko. Most Sudokus will have at least one clue, but there are
a few variants which allow clueless Sudokus. For a standard C<< 9 x 9 >>
Sudoku, the minimum amount of clues is 17.

The clues are either given as a string, or a two dimensional arrayref. 

In the case of a string, rows are separated by newlines, and values
in a row by whitespace. The first line of the string corresponds
with the first row of the Sudoku, the second line with the second 
row, etc. In each line, the first value corresponds with the first
cell of that row, the second value with the second cell, etc.
In case of an arrayref, the array consists of arrays of values. Each
array corresponds with a row, and each element of the inner arrays
corresponds with a cell.

The values have the following meaning:

=over 4

=item C<< '1' .. '9', 'A' .. 'Z' >>

This corresponds to a clue/given in the corresponding cell. For standard
Sudokus, we use C<< '1' .. '9' >>. Smaller Sudokus use less digits.
For Sudokus greater than C<< 9 x 9 >>, capital letters are used, up to 
C<< 'Z' >> for a C<< 35 x 35 >> Sudoku.

=item C<< '.' >>, C<< 0 >>, C<< "" >>, C<< undef >>

These values indicate the Sudoku does not have a clue for the corresponding
cell: the cell is blank. C<< "" >> and C<< undef >> can only be used
if the array form is being used.

=item C<< 'e' >>

This indicates the cell should have an I<< even >> number in its solution.
(Note that C<< 'E' >> indicates a clue (if the size is at least C<< 15 x 15 >>),
and is different from C<< 'e' >>).

=item C<< 'o' >>

This indicates the cell should have an I<< odd >> number in its solution.
(Note that C<< 'O' >> indicates a clue (if the size is at least C<< 25 x 25 >>),
and is different from C<< 'o' >>).

=back

=head2 Additional Houses

A I<< house >> is a region which 
contains each of the numbers C<< 1 .. 9 >> (or C<< 1 .. N >> for an
C<< N x N >> sized Sudoku) exactly once. With a standard Sudoku, each
row, each column, and each C<< 3 x 3 >> box is a house.

Some variants have additional houses, next to the rows, columns and boxes.
In this section, we describe the methods which can be used to configure
the Sukodu to have additional houses.

=head3 C<< set_nrc_houses () >>

An I<< NRC >> Sudoku has four additional houses, indicated below with
the numbers C<< 1 .. 4 >>. This variant is only defined for C<< 9 x 9 >>
Sudokus:

    . . .  . . .  . . .
    . 1 1  1 . 2  2 2 .
    . 1 1  1 . 2  2 2 .

    . 1 1  1 . 2  2 2 .
    . . .  . . .  . . .
    . 3 3  3 . 4  4 4 .

    . 3 3  3 . 4  4 4 .
    . 3 3  3 . 4  4 4 .
    . . .  . . .  . . .

Calling the C<< set_nrc_houses () >> sets up those houses.

The NRC Sudoku is named after the Dutch newspaper
L<< NRC|https://www.nrc.nl/ >>, which first publishes such a Sudoku
and still publishes one L<< daily|https://www.nrc.nl/sudoku/ >>.
It is also known under
the names I<< Windoku >> and I<< Hyper Sudoku >>.

=head3 C<< set_asterisk_house () >>

An I<< asterisk >> Sudoku has an additional house, roughly in the
shape of an asterisk, as indicated below. This variant is only defined
for C<< 9 x 9 >> Sudokus:

    . . .  . . .  . . .
    . . .  . * .  . . .
    . . *  . . .  * . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . *  . . .  * . .
    . . .  . * .  . . .
    . . .  . . .  . . .

Calling the C<< set_asterisk_house () >> sets up those houses.

=head3 C<< set_girandola_house () >>

An I<< girandola >> Sudoku has an additional house, roughly in the
shape of a I<< windmill pinwheel >> (a childs toy), as indicated below.
This variant is only defined for C<< 9 x 9 >> Sudokus:

    * . .  . . .  . . *
    . . .  . * .  . . .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . . .  . * .  . . .
    * . .  . . .  . . *

Calling the C<< set_girandola_house () >> sets up those houses.

=head3 C<< set_center_dot_house () >>

A I<< center dot >> house is an additional house which consists of
all the center cell of all the boxes. This is only defined for Sudokus
where the boxes have odd sizes. (Sizes C<< 9 >>, C<< 15 >>, C<< 25 >>,
and C<< 35 >>; see the table with sizes above). For a C<< 9 x 9 >>
Sudoku, this looks like:

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

Calling the C<< set_center_dot_house () >> sets up those houses.



=head2 Diagonals

A common constraint used in variant Sudokus is uniqueness of one
or more diagonals: all the values on each of the marked diagonals 
should be unique.

The I<< main >> diagonal of a Sudoku is the diagonal which runs
from the top left to the bottom right. The I<< minor >> diagonal
the diagonal which runs from the top right to the bottom left.


    \ . .  . . .  . . .            . . .  . . .  . . /
    . \ .  . . .  . . .            . . .  . . .  . / .
    . . \  . . .  . . .            . . .  . . .  / . .

    . . .  \ . .  . . .            . . .  . . /  . . .
    . . .  . \ .  . . .            . . .  . / .  . . .
    . . .  . . \  . . .            . . .  / . .  . . .

    . . .  . . .  \ . .            . . /  . . .  . . .
    . . .  . . .  . \ .            . / .  . . .  . . .
    . . .  . . .  . . \            / . .  . . .  . . .

      Main  Diagonal                 Minor Diagonal


A I<< super >> diagonal is a diagonal which parallel and above
of the main or minor diagonal. A I<< sub >> diagonal is a diagonal
which runs parallel and below the main or minor diagonal.
Super and sub diagonals have an I<< offset >>, indicating their
distance from the main or minor diagonal. The super and sub diagonal
directly next to the main and minor diagonals have an offset of 1.
The maximum offset for an C<< N x N >> Sudoku is C<< N - 1 >>, although
such an offset reduces the diagonal to a single cell.

    . \ .  . . .  . . .            . . .  . . .  . / .
    . . \  . . .  . . .            . . .  . . .  / . .
    \ . .  \ . .  . . .            . . .  . . /  . . /

    . \ .  . \ .  . . .            . . .  . / .  . / .
    . . \  . . \  . . .            . . .  / . .  / . .
    . . .  \ . .  \ . .            . . /  . . /  . . .

    . . .  . \ .  . \ .            . / .  . / .  . . .
    . . .  . . \  . . \            / . .  / . .  . . .
    . . .  . . .  \ . .            . . /  . . .  . . .

   Super and sub diagonals       Super and sub diagonals
    off the main diagonal         off the minor diagonal


In total, an C<< N x N >> Sudoku can have C<< 4 * N - 2 >> diagonals
(34 for a standard C<< 9 x 9 >> Sudoku).

There will be a method to set uniqness for each possible diagonal.

=head3 C<< set_diagonal_main () >>

This method sets a uniqness constraint on the I<< main diagonal >>.

=head3 C<< set_diagonal_minor () >>

This method sets a uniqness constraint on the I<< minor diagonal >>.

=head3 C<< set_diagonal_main_super_1 () .. set_diagonal_main_super_34 () >>

These methods set uniqness constraints on I<< super diagonals >> 
parallel to the main diagonal, with the given offset. If the 
offset equals or exceeds the size of the Sudoku, the diagonal
falls completely outside of the Sudoku, and hence, does not add
a constraint.

=head3 C<< set_diagonal_main_sub () .. set_diagonal_main_sub () >>

These methods set uniqness constraints on I<< sub diagonals >> 
parallel to the main diagonal, with the given offset. If the 
offset equals or exceeds the size of the Sudoku, the diagonal
falls completely outside of the Sudoku, and hence, does not add
a constraint.

=head3 C<< set_diagonal_minor_super_1 () .. set_diagonal_minor_super_34 () >>

These methods set uniqness constraints on I<< super diagonals >> 
parallel to the minor diagonal, with the given offset. If the 
offset equals or exceeds the size of the Sudoku, the diagonal
falls completely outside of the Sudoku, and hence, does not add
a constraint.

=head3 C<< set_diagonal_minor_sub () .. set_diagonal_minor_sub () >>

These methods set uniqness constraints on I<< sub diagonals >> 
parallel to the minor diagonal, with the given offset. If the 
offset equals or exceeds the size of the Sudoku, the diagonal
falls completely outside of the Sudoku, and hence, does not add
a constraint.


=head2 Crosses and other diagonal sets

It is quite common for variants which have constraints on diagonals
to do so in a symmetric fashion. To avoid having to call multiple
C<< set_diagonal_* >> methods, we provide a bunch of wrappers which
set uniqness constraints on two or more diagonals.

=head3 C<< set_cross () >>

A common variant has uniqness constraints for both the main and minor
diagonal -- this variant is widely known under the name I<< X-Sudoku >>.
C<< set_cross () >> sets the uniqness constraints for both the main
and minor diagonals:

    \ . .  . . .  . . /
    . \ .  . . .  . / .
    . . \  . . .  / . .

    . . .  \ . /  . . .
    . . .  . X .  . . .
    . . .  / . \  . . .

    . . /  . . .  \ . .
    . / .  . . .  . \ .
    / . .  . . .  . . \

     Cross constraints


=head3 C<< set_cross_1 () .. set_cross_34 () >>

Each of the C<< set_cross_N () >> methods enable a uniqness constraint
on B<< four >> diagonals: the I<< super >> and I<< sub >> diaganols
(relative to both the main and minor diagonals) with offset C<< N >>.
Note that if C<< N >> is equal, or exceeds the size of the Sudoku, 
all the diagonals lie fully outside the Sudoku, rendering the method
useless.

=head3 C<< set_diagonal_double () >>

This method enables a uniqness constraints on the diagonals parallel,
and directly next to the main and minor diagonals. This is method is
equivalent to C<< set_cross_1 >>.

    . \ .  . . .  . / .
    \ . \  . . .  / . /
    . \ .  \ . /  . / .

    . . \  . X .  / . .
    . . .  X . X  . . .
    . . /  . X .  \ . .

    . / .  / . \  . \ .
    / . /  . . .  \ . \
    . / .  . . .  . \ .

      Diagonal Double


=head3 C<< set_diagonal_triple () >>

This methods enables uniqness constraints on six diagonals: the main
and minor diagonals, and the diagonals parallel to them, and directly
next to them. Calling this method is equivalent to calling both
C<< set_cross () >> and C<< set_diagonal_double () >>.

    \ \ .  . . .  . / /
    \ \ \  . . .  / / /
    . \ \  \ . /  / / .

    . . \  X X X  / . .
    . . .  X X X  . . .
    . . /  X X X  \ . .

    . / /  / . \  \ \ .
    / / /  . . .  \ \ \
    / / .  . . .  . \ \

      Diagonal Triple

=head3 C<< set_argyle () >>

The I<< Argyle Sudoku >> variant has uniqness constraints on
B<< eight >> diagonals. This is named after a L<< pattern consisting of
lozenges|https://en.wikipedia.org/wiki/Argyle_(pattern) >>, which
itself was named after the tartans of the 
L<< Clan Cambell |https://en.wikipedia.org/wiki/Clan_Campbell >>
in Argyll in the Scottish highlands.

Calling C<< set_argyle () >> is equivalent to calling 
C<< set_cross_1 () >> and C<< set_cross_4 () >>.

    . \ .  . ^ .  . / .
    \ . \  / . \  / . /
    . \ /  \ . /  \ / .

    . / \  . X .  / \ .
    < . .  X . X  . . >
    . \ /  . X .  \ / .

    . / \  / . \  / \ .
    / . /  \ . /  \ . \
    . / .  . V .  . \ .

       Argyle Pattern



=head2 Global constraints

There are Sudoku variants which enable specific constraints on
all the cells in the Sudoku.

=head3 C<< set_anti_knight_constraint () >>

An I<< anti knight >> constraint implies that two cells which are
a knights move (as in classical Chess) apart must have different values.
(A knights move
is first two cells in an orthognal direction, then one cell
perpendicular). For each cell, this puts a restriction to up to
eight different cells. In the diagram below, C<< * >> marks all
the cells which are a knights move away from the cell marked C<< O >>.

    . . .  . . .  . . .
    . . .  . . .  . . .
    . . *  . * .  . . .

    . * .  . . *  . . .
    . . .  O . .  . . .
    . * .  . . *  . . .

    . . *  . * .  . . .
    . . .  . . .  . . .
    . . .  . . .  . . .

   Anti Knight Constraint


=head3 C<< set_anti_king_constraint () >>

Also known as the I<< no touch constraint >>.

An I<< anti king >> constraint implies that two cells which are
a kings move (as in classical Chess) apart must have different values.
(A kings move is one step in any of the eight directions).

For each cell, this puts a restriction to up to
eight different cells. Four of them are already restricted
because they are one the same row or columns. And at least
one kings move will end in the same box. So, this restriction
is far less restrictive than the anti knights move restriction.

In the diagram below, C<< * >> marks all
the cells which are a kings move away from the cell marked C<< O >>.

    . . .  . . .  . . .
    . . .  . . .  . . .
    . . .  . . .  . . .

    . . *  * * .  . . .
    . . *  O * .  . . .
    . . *  * * .  . . .

    . . .  . . .  . . .
    . . .  . . .  . . .
    . . .  . . .  . . .

   Anti King Constraint

=head2 Retricted lines and areas

=head3 C<< set_renban (LIST) >>

A I<< Renban >> line (or area) consist of a number of cells where all
the values should form a consecutive sets of numbers. The numbers do
not have to be in order. For example, a Renban area of size four may
contain the numbers C<< 5-7-4-6 >> or C<< 2-3-4-5 >>, but not 
C<< 2-3-5-6 >>. 

This method takes a list of cell names as argument, where each name
is of the form C<< RxCy >>, with C<< 1 <= x, y <= N >>, where C<< N >>
is the size of the Sudoku.

No validation of cell names is performed. Names which aren't of the
form C<< RxCy >>, or which are outside of the Sudoku have no effect.
A Renban area with more cells than the size of the Sudoku leads to
an unsolvable Sudoku.

This method can be called more than once, and should be called more
than once if a Sudoku has more than one Renban line/area.

=head1 BUGS

There are no known bugs.

=head1 TODO

=over 2

=item *

Disjoint Groups

=item *

Jigsaw

=item *

Battenburg

=item *

Greater Than

=over 2

=item *

Thermo

=item *

Slow Thermo

=item *

Rossini

=back

=item *

Consecutive Sudoku

=over 2

=item *

Non-consecutive Sudoku

=back

=item *

Kropki

=over 2

=item *

Absolute difference = 1

=item *

Other differences

=item *

Ratio 1:2

=item *

Other ratios

=back

=item *

XV Sudoku

=item *

CL Sudoku

=item *

Outsize Sudoku

=item *

Young Tableaux

=item *

Palindromes

=item *

Renban lines

=over 2

=item *

Nabner

=back

=item *

German Whisper

=item *

Clones

=item *

Quadruple

=item *

Killer Sudoku

=item *

Little Killer Sudoku

=item *

Frame Sudoku

=item *

Arrow Sudoku

=item *

Sandwich

=item *

Clock Sudoku

=back

=head1 SEE ALSO

L<< Regexp::Sudoku::Constants >>.

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
