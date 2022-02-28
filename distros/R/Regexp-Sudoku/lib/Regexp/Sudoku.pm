package Regexp::Sudoku;

use 5.028;
use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

our $VERSION = '2022022401';

use Hash::Util::FieldHash qw [fieldhash];
use List::Util            qw [min];
use Math::Sequence::DeBruijn;
use Regexp::Sudoku::Constants qw [:Diagonals :Houses :Constraints];

use Exporter ();

my $DEFAULT_SIZE   = 9;
my $SENTINEL       = "\n";
my $CLAUSE_LIST    = ",";

my $NR_OF_DIGITS   =  9;
my $NR_OF_LETTERS  = 26;
my $NR_OF_SYMBOLS  = $NR_OF_DIGITS + $NR_OF_LETTERS;


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
fieldhash my %houses;
fieldhash my %constraints;


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
# Depending on the parameters, it may call:
#   - init_nrc_houses () 
#   - init_asterisk_house ()
#
# TESTS: 045-init_houses.t
#
################################################################################

sub init_houses ($self, $args = {}) {
    my $houses = $houses {$self} = delete $$args {houses} || "";
    if (has_bit ($houses &. ~. $ALL_HOUSES) ||
         length ($houses =~ s/\x{00}*$//r) > length ($ALL_HOUSES)) {
        my $out = "";
        my $r = $houses &. ~. $ALL_HOUSES;
        for (my $i = 0; $i < 8 * length ($r); $i ++) {
            $out .= vec ($r, $i, 1) ? 1 : 0;
        }
        die sprintf "Unknown house(s): %s\n", $out;
    }

    $self -> init_rows             ($args)
          -> init_columns          ($args)
          -> init_boxes            ($args)
          -> init_nrc_houses       ($args)
          -> init_asterisk_house   ($args)
          -> init_girandola_house  ($args)
          -> init_center_dot_house ($args);
}


################################################################################
#
# init_nrc_houses ($self, $args)
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
# TESTS: 046-init_nrc_houses.t
#
################################################################################

sub init_nrc_houses ($self, $args = {}) {
    return $self unless $self -> size == $DEFAULT_SIZE &&
                 has_bit ($houses {$self} &. $NRC);

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
# sub init_asterisk_house ($self, $args)
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
# TESTS: 047-init_asterisk_house.t
#
################################################################################

sub init_asterisk_house ($self, $args = {}) {
    return $self unless $self -> size == $DEFAULT_SIZE &&
                 has_bit ($houses {$self} &. $ASTERISK);

    $self -> create_house ("AS" => map {cell_name @$_}
                                       [3, 3], [2, 5], [3, 7],
                                       [5, 2], [5, 5], [5, 8],
                                       [7, 3], [8, 5], [7, 7]);
}


################################################################################
#
# sub init_girandola_house ($self, $args)
#
# An asterisk sudoku has an additional house: one cell from each box.
# This method initializes that house.
#
# An asterisk is defined for a 9 x 9 sudoku as follows:
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
# TESTS: 048-init_girandola_house.t
#
################################################################################

sub init_girandola_house ($self, $args = {}) {
    return $self unless $self -> size == $DEFAULT_SIZE &&
                 has_bit ($houses {$self} &. $GIRANDOLA);

    $self -> create_house ("GR" => map {cell_name @$_}
                                       [1, 1], [2, 5], [1, 9],
                                       [5, 2], [5, 5], [5, 8],
                                       [9, 1], [8, 5], [9, 9]);
}

################################################################################
#
# sub init_center_dot_house ($self, $args)
#
# An asterisk sudoku has an additional house: one cell from each box.
# This method initializes that house.
#
# An asterisk is defined for a 9 x 9 sudoku as follows:
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
# TESTS: 049-init_center_dot_house.t
#
################################################################################

sub init_center_dot_house ($self, $args = {}) {
    my $width  = $self -> box_width;
    my $height = $self -> box_height;
    my $size   = $self -> size;

    #
    # We can only do center dots if boxes are odd sized width and heigth.
    #
    return $self unless $width % 2 && $height % 2 &&
                 has_bit ($houses {$self} &. $CENTER_DOT);

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
# sub init_diagonals ($self, $args)
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
# TESTS: 050-init_diagonals.t
#
################################################################################


sub init_diagonals ($self, $args = {}) {
    my $diagonals = delete $$args {diagonals} or return $self;

    if (has_bit ($diagonals &. ~. $ALL_DIAGONALS) ||
        length ($diagonals =~ s/\x{00}*$//r) > length ($ALL_DIAGONALS)) {
        my $out = "";
        my $r = $diagonals &. ~. $ALL_DIAGONALS;
        for (my $i = 0; $i < 8 * length ($r); $i ++) {
            $out .= vec ($r, $i, 1) ? 1 : 0;
        }
        die sprintf "Unknown diagonal(s): %s\n", $out;
    }

    my $size = $self -> size;

    #
    # Top left to bottom right
    #
    if (has_bit ($diagonals &. $MAIN)) {
        $self -> create_house ("DM" => map {cell_name $_, $_} 1 .. $size)
    }

    #
    # Bottom left to top right
    #
    if (has_bit ($diagonals &. $MINOR)) {
        $self -> create_house ("Dm" => map {cell_name $size - $_ + 1, $_}
                                                              1 .. $size)
    }

    #
    # Offsets
    #
    foreach my $s (1 .. $size - 1) {
        my ($sub, $super, $minor_sub, $minor_super) = do {
            no strict 'refs';
            (${"SUB$s"}, ${"SUPER$s"}, ${"MINOR_SUB$s"}, ${"MINOR_SUPER$s"});
        };
        if (has_bit ($diagonals &. $super)) {
            my $name = "DMS$s";
            $self -> create_house ($name =>
                            map {cell_name $_, $_ + $s} 1 .. $size - $s);
        }
        if (has_bit ($diagonals &. $sub)) {
            my $name = "DMs$s";
            $self -> create_house ($name =>
                            map {cell_name $_, $_ - $s} 1 + $s .. $size);
        }
        if (has_bit ($diagonals &. $minor_super)) {
            my $name = "DmS$s";
            $self -> create_house ($name =>
                     map {cell_name $size - $_ + 1, $_ - $s} 1 + $s .. $size);
        }
        if (has_bit ($diagonals &. $minor_sub)) {
            my $name = "Dms$s";
            $self -> create_house ($name =>
                     map {cell_name $size - $_ + 1, $_ + $s} 1 .. $size - $s);
        }
    }

    $self
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
# init_clues ($self, $args)
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
# TESTS: 080-clues.t
#
################################################################################

sub init_clues ($self, $args) {
    my $in_clues = delete $$args {clues} or return $self;

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
# init_constraints ($self, $args)
#
# Set the constraints for the sudoku. Die if the constrainst do not validate.
#
# TESTS: 060-constraints.t
#
################################################################################

sub init_constraints ($self, $args = {}) {
    my $constraints = $constraints {$self} = delete $$args {constraints} || "";
    if (has_bit ($constraints &. ~. $ALL_CONSTRAINTS) ||
         length ($constraints =~ s/\x{00}*$//r) > length ($ALL_CONSTRAINTS)) {
        my $out = "";
        my $r = $constraints &. ~. $ALL_CONSTRAINTS;
        for (my $i = 0; $i < 8 * length ($r); $i ++) {
            $out .= vec ($r, $i, 1) ? 1 : 0;
        }
        die sprintf "Unknown constraint(s) %s\n", $out;
    }

    $self;
}


################################################################################
#
# constraints ($self)
#
# Return the constraints set for this sudoku.
#
# TESTS: 060-constraints.t
#
################################################################################

sub constraints ($self) {
    $constraints {$self} || 0;
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

    $self -> init_sizes       ($args)
          -> init_values      ($args)
          -> init_houses      ($args)
          -> init_diagonals   ($args)
          -> init_constraints ($args)
          -> init_clues       ($args);

    if (keys %$args) {
        die "Unknown parameter(s) to init: " . join (", " => keys %$args)
                                             . "\n";
    }

    $self;
}


################################################################################
#
# make_clue ($self, $cell, $value)
#
# Given a cell name, and a value, return a sub subject, and sub pattern
# which sets the capture '$cell' to '$value'
#
# TESTS: 110-make_clue.t
#        120-make_cell.t
#
################################################################################

sub make_clue ($self, $cell) {
    my $value  = $self -> clue ($cell);
    my $subsub = $value;
    my $subpat = "(?<$cell>$value)";

    map {$_ . $SENTINEL} $subsub, $subpat;
}


################################################################################
#
# make_empty ($cell)
#
# Given a cell name, return a sub subject and a sub pattern allowing the
# cell to pick up one of the values in the sudoku.
#
# TESTS: 100-make_empty.t
#        120-make_cell.t
#
################################################################################

sub make_empty ($self, $cell, $method = "values") {
    my $subsub = $self -> $method;
    my $range  = $self -> values_range;
    my $subpat = "[$range]*(?<$cell>[$range])[$range]*";

    map {$_ . $SENTINEL} $subsub, $subpat;
}

sub make_any  ($self, $cell) {$self -> make_empty ($cell, "values")}
sub make_even ($self, $cell) {$self -> make_empty ($cell, "evens")}
sub make_odd  ($self, $cell) {$self -> make_empty ($cell, "odds")}


################################################################################
#
# make_cell ($cell)
#
# Given a cell name, return a subsubject and subpattern to set a value for
# this cell. Either the cell has a clue (and we dispatch to make_clue),
# or not (and we dispatch to make_empty).
#
# TESTS: 120-make_cell.t
#
################################################################################

sub make_cell ($self, $cell) {
    my $clue = $self -> clue ($cell);

      $self -> clue    ($cell) ? $self -> make_clue ($cell)
    : $self -> is_even ($cell) ? $self -> make_even ($cell)
    : $self -> is_odd  ($cell) ? $self -> make_odd  ($cell)
    :                            $self -> make_any  ($cell)
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
# make_diff_clause ($self, $cell1, $cell2)
#
# Given two cell names, return a sub subject and a sub pattern which matches
# iff the values in the cell differ.
#
# TESTS: 140-make_diff_clause.t
#
################################################################################

sub make_diff_clause ($self, $cell1, $cell2) {
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

    my $same_house = grep {$_ > 1} values %seen;

    my ($r1, $c1)    = cell_row_column ($cell1);
    my ($r2, $c2)    = cell_row_column ($cell2);
    my  $constraints = $self -> constraints;

    my $d_rows    = abs ($r1 - $r2);
    my $d_cols    = abs ($c1 - $c2);

    return $same_house
        || has_bit ($constraints &. $ANTI_KNIGHT) &&
                                             (($d_rows == 1 && $d_cols == 2)  ||
                                              ($d_rows == 2 && $d_cols == 1))
        || has_bit ($constraints &. $ANTI_KING)   &&
                                               $d_rows == 1 && $d_cols == 1
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

        my ($subsub, $subpat) = $self -> make_cell ($cell1);
        $subject .= $subsub;
        $pattern .= $subpat;

        #
        # Now, for all the previous cells, if they must differ,
        # add a clause for that.
        #
        for my $j (0 .. $i - 1) {
            my $cell2 = $cells [$j];
            #
            # If both cells are a clue, we don't need a restriction
            # between the cells.
            #
            next if $self -> clue ($cell1) && $self -> clue ($cell2);

            if ($self -> must_differ ($cell1, $cell2)) {
                my ($subsub, $subpat) =
                             $self -> make_diff_clause ($cell1, $cell2);
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

__END__

=head1 NAME

Regexp::Sudoku - Solve Sudokus with regular expressions.

=head1 SYNOPSIS

 use Regexp::Sudoku;
 my $sudoku = Regexp::Sudoku:: -> new -> init (clues <<~ '--')
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

This module takes a sudoku (or variant) as input, calculates a subject
and pattern, such that, if the pattern is matched agains the subject,
the match succeeds if, and only if, the sudoku has a solution. And if
it has a solution C<< %+ >> is populated with the values of the cells of
the solved sudoku.

After constructing and initializing a sudoku object using
C<< new >> and C<< init >> (see below), the object can be queried
with C<< subject >> and C<< pattern >>. C<< subject >> returns 
a string, while C<< pattern >> returns a pattern (as a string).

Once the subject has been matched against the pattern, 81 (or rather
C<< N ** 2 >> for an C<< N x N >> sudoku) named captures will be set:
C<< R1C1 >> .. C<< R1C9 >> .. C<< R9C1 >> .. C<< R9C9 >>. These correspond
to the values of the cells of a solved sudoku, where the cell in the
top left is named C<< R1C1 >>, the cell in the top right C<< R1C9 >>,
the cell in the bottom left C<< R9C1 >> and the cell in the bottom right
C<< R9C9 >>. In general, the cell on row C<< r >> and column C<< c >>
is named C<< RrCc >>. Named captures are available in C<< %+ >>
(see L<< perlvar/%{^CAPTURE} >>).

The C<< init >> method takes the following named parameters:

=head2 C<< clues => STRING | ARRAYREF >>

The C<< clues >> parameter is used to pass in the clue (aka givens)
of a suduko. The clues are either given as a string, or a two
dimensional arrayref. 

In the case of a string, rows are separated by newlines, and values
in a row by whitespace. The first line of the string corresponds
with the first row of the sudoku, the second line with the second 
row, etc. In each line, the first value corresponds with the first
cell of that row, the second value with the second cell, etc.
In case of an arrayref, the array consists of arrays of values. Each
array corresponds with a row, and each element of the inner arrays
corresponds with a cell.

The values have the following meaning:

=over 2

=item C<< '1' .. '9', 'A' .. 'Z' >>

This corresponds to a clue/given in the corresponding cell. For standard
sudokus, we use C<< '1' .. '9' >>. Smaller sudokus use less digits.
For sudokus greater than C<< 9 x 9 >>, capital letters are used, up to 
C<< 'Z' >> for a C<< 35 x 35 >> sudoku.

=item C<< '.' >>, C<< 0 >>, C<< "" >>, C << undef >>

These values indicate the sudoku does not have a clue for the corresponding
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

=head2 C<< size => INTEGER >>

This is used to indicate the size of a sudoku. The default size is a
C<< 9 x 9 >> sudoku. A size which exceeds C<< 35 >> is a fatal error.

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

=head2 C<< houses => MASK >>

For sudoku variants with extra houses, this parameter is used to indicate
which extra I<< houses >> are used. A I<< house >> is a region which 
contains each of the numbers C<< 1 .. 9 >> (or C<< 1 .. N >> for an
C<< N x N >> sized sudoku) exactly once. With a standard sudoku, each
row, each column, and each C<< 3 x 3 >> box is a house.

We recognize the following values (imported from
L<< Regexp::Sudoku::Constants >>):

=over 2

=item C<< $NRC >>

An I<< NRC >> sudoku has four additional houses, indicated below with
the numbers C<< 1 .. 4 >>. This variant is only defined for C<< 9 x 9 >>
sudokus:

    . . .  . . .  . . .
    . 1 1  1 . 2  2 2 .
    . 1 1  1 . 2  2 2 .

    . 1 1  1 . 2  2 2 .
    . . .  . . .  . . .
    . 3 3  3 . 4  4 4 .

    . 3 3  3 . 4  4 4 .
    . 3 3  3 . 4  4 4 .
    . . .  . . .  . . .

The NRC sudoku is named after the Dutch newspaper
L<< NRC|https://www.nrc.nl/ >>, which first publishes such a sudoku
and still publishes one L<< daily|https://www.nrc.nl/sudoku/ >>.
It is also known under
the names I<< Windoku >> and I<< Hyper Sudoku >>.

=item C<< $ASTERISK >>

An I<< asterisk >> sudoku has an additional house, roughly in the
shape of an asterisk, as indicated below. This variant is only defined
for C<< 9 x 9 >> sudokus:

    . . .  . . .  . . .
    . . .  . * .  . . .
    . . *  . . .  * . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . *  . . .  * . .
    . . .  . * .  . . .
    . . .  . . .  . . .

=item C<< $GIRANDOLA >>

An I<< girandola >> sudoku has an additional house, roughly in the
shape of a I<< windmill pinwheel >> (a childs toy), as indicated below.
This variant is only defined for C<< 9 x 9 >> sudokus:

    * . .  . . .  . . *
    . . .  . * .  . . .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . . .  . * .  . . .
    * . .  . . .  . . *

=item C<< $CENTER_DOT >>

A I<< center dot >> house is an additional house which consists of
all the center cell of all the boxes. This is only defined for sudokus
where the boxes have odd sizes. (Sizes C<< 9 >>, C<< 15 >>, C<< 25 >>,
and C<< 35 >>; see the table with sizes above). For a C<< 9 x 9 >>
sudoku, this looks like:

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

    . . .  . . .  . . .
    . * .  . * .  . * .
    . . .  . . .  . . .

=back

=head2 C<< diagonals => MASK >>

The C<< diagonals >> parameter is used to indicate the sudoku has
one or more constraints on diagonals: all values on the given
diagonal(s) should be unique. There are many possible diagonals
(34 for a C<< 9 x 9 >> sudoku, in general, C<< 4 * N - 2 >> for
an C<< N x N >> sudoku. For a full explanation of all diagonals,
see L<< Regexp::Sudoku::Constants >>.

Here, we will list a couple of the most common ones:

=over 2

=item C<< $MAIN >>

The main diagonal is the diagonal which runs from the top left to
the bottom right. All values on this diagonal should be unique.

    * . .  . . .  . . .
    . * .  . . .  . . .
    . . *  . . .  . . .

    . . .  * . .  . . .
    . . .  . * .  . . .
    . . .  . . *  . . .

    . . .  . . .  * . .
    . . .  . . .  . * .
    . . .  . . .  . . *

=item C<< $MINOR >>

The minor diagonal is the diagonal which runs from the bottom left to
the top right. All values on this diagonal should be unique.

    . . .  . . .  . . *
    . . .  . . .  . * .
    . . .  . . .  * . .

    . . .  . . *  . . .
    . . .  . * .  . . .
    . . .  * . .  . . .

    . . *  . . .  . . .
    . * .  . . .  . . .
    * . .  . . .  . . .


=item C<< $CROSS >>

This is a combination of main and minor diagonal constaints. The values
on each of diagonals should be unique. 

    * . .  . . .  . . *
    . * .  . . .  . * .
    . . *  . . .  * . .

    . . .  * . *  . . .
    . . .  . * .  . . .
    . . .  * . *  . . .

    . . *  . . .  * . .
    . * .  . . .  . * .
    * . .  . . .  . . *


=item C<< $DOUBLE >>

C<< $DOUBLE >> is used for a sudoku variant with four diagonals
having unique values: the diagonals just above/below the main and
minor diagonals:

    . * .  . . .  . * .
    * . *  . . .  * . *
    . * .  * . *  . * .

    . . *  . * .  * . .
    . . .  * . *  . . .
    . . *  . * .  * . .

    . * .  * . *  . * .
    * . *  . . .  * . *
    . * .  . . .  . * .


=item C<< $ARGYLE >>

I<< Argyle >> sudokus have eight diagonals on which the values
should be unique. This is named after a L<< pattern consisting of
lozenges|https://en.wikipedia.org/wiki/Argyle_(pattern) >>, which
itself was named after the tartans of the 
L<< Clan Cambell |https://en.wikipedia.org/wiki/Clan_Campbell >>
in Argyll in the Scottish highlands.


    . 1 .  . 5 .  . 3 .
    2 . 1  6 . 5  3 . 4
    . 2 6  1 . 3  5 4 .

    . 6 2  . 1 .  4 5 .
    6 . .  2 . 1  . . 5
    . 7 3  . 2 .  1 8 .

    . 3 7  4 . 2  8 1 .
    3 . 4  7 . 8  2 . 1
    . 4 .  . 7 .  . 2 .

=back

=head2 C<< constraints => MASK >>

Some variants have additional constraints, which apply to all cells
in the sudoku. We recognize the following values (imported from
L<< Regexp::Sudoku::Constants >>):

=over 2

=item C<< $ANTI_KNIGHT >>

An I<< anti knight >> constraint implies that two cells which are
a knights move apart must have different values. (A knights move
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


=item C<< $ANTI_KING >>

Also known as the I<< no touch constraint >>.

An I<< anti king >> constraint implies that two cells which are
a king move apart must have different values. (A kings move
is one step in any of the eight directions).

For each cell, this puts a restriction to up to
eight different cells. Four of them are already restricted
because they are one the same row or columns. And at least
one kings move will end in the same box. So, this restriction
is far restrictive than the anti knights move restriction.

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

=back

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
