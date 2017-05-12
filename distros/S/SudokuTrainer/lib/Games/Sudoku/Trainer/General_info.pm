package Games::Sudoku::Trainer::General_info;

use version; our $VERSION = qv('0.02');    # PBP

1;

__END__

=head1 NAME

SudokuTrainer

This program helps to train the detection of successful Sudoku solution strategies.
It may also be used to get over an obstacle in a partially solved Sudoku puzzle.

=head1 VERSION

This documentation refers to SudokuTrainer version 0.01.5.

=head1 PURPOSE

SudokuTrainer helps the user in solving classical 9x9 Sudoku puzzles.
It does this in two areas:

1. Help to train a Sudoku strategy

2. Help to overcome an obstacle while solving a Sudoku puzzle

SudokuTrainer is not a Sudoku teacher.
The user must know the strategy that he wants to train.
People who don't know about Sudoku strategies may still use SudokuTrainer for 
the second purpose, just to get a new value for continuation.

=head1 USAGE

C<sudokutrainer [Sudoku_file] [--prio=priority-list]>

=head1 OPTIONS

=over 4

=item * Sudoku_file

The path of a Sudoku file to be used for training.

If this option is omitted,
SudokuTrainer will ask for it.
You will get the following choices:

    Read from file
    Insert manually
    Read example file

A doubleclick on a choice will select it and 
close the selection window. When you select the choice 
I<Insert manually> the utility program
B<enter_presets.pl> gets started. To see the documentation of 
it, use "perldoc enter_presets.pl". 
After you entered the initial puzzle manually, 
you should better save it. Chances are good that 
you will need it several times. Corrections to 
the initial puzzle can also be made with 
B<enter_presets.pl>.

=item * --prio=priority-list

The path to a file where a I<priority list> has been stored.

=back

=head1 TERMINOLOGY

=over 4

=item * cell

A cell is one of the 81 squares in a Sudoku board that will each finally
show a digit from 1 to 9.

=item * row

A row is a horizontal line of 9 cells. Rows are numbered from 1 to 9,
top to bottom.

=item * column

A column is a vertical line of 9 cells. Columns are numbered from 1 to 9,
left to right.

=item * block

A block is one of the 9 3x3 subsquares of a Sudoku board. Blocks are
numbered according to the following scheme:

    1 2 3
    4 5 6
    7 8 9

=item * line

A line is either a row or a column.

=item * unit

A unit is either a line or a block.

=item * candidate

A digit is a candidate of a cell if it is currently not yet forbidden
to use it as the value of the cell.

For more difficult Sudoku puzzles it may be helpful to inspect a list of
all still possible (or already excluded) candidates. You may 
view the internal candidate list of SudokuTrainer for this purpose 
(see section L<Games::Sudoku::Trainer::Training/View>).

=item * strategy

A strategy is a systematic collection of patterns which 
the player of a Sudoku puzzle tries to detect in the 
current state of the puzzle. The strategy is named 
successful if its detection allows for the exclusion of 
one or more candidates from some cells.

=item * priority

Each strategy has a priority assigned. The priorities give 
the sequence in which SudokuTrainer tries the stragegies. 
Stragegies that are considered as easy by the user are 
usually assigned a high priority.

A B<priority list> is a list of all strategies (exept 
I<Full house>), ordered by their priorities. The user may 
rearrange the strategies, thus changing their priorities 
(see section L<Games::Sudoku::Trainer::Training/Priorities>). 
He may also save the priority list for later reuse.

=back


=head1 NAMES OF CELLS AND UNITS

These names are used in communications with the user.

=over 4

=item * units

Units are named by a character that gives the unit type 
(I<r> for row, I<c> for column, I<b> for block), 
followed by the unit number. 
E. g. c1 is the leftmost column of the Sudoku board.

=item * cells

Cells are named by concatenating the names of the 
row and column that cross at the cell. 
E. g. r1c9 is the upper right cell of the Sudoku board.

=back



=head1 GUIDE TO DOCUMENTATION

The documentation for SudokuTrainer is broken up into sections:

=head2 General information

This is the document you are currently reading. It describes 
basic usage and the terminology that is needed for the 
communication with SudokuTrainer.

=head2 Train a strategy

The document L<Games::Sudoku::Trainer::Training> describes the 
operation of SudokuTrainer from a user point of view.

SudokuTrainer has a list of all strategies that it knows 
about. Easy strategies are near the top, the most difficult 
ones near the end of this list. SudokuTrainer starts the 
solution of a given puzzle with the easiest strategy and 
proceeds until it finds the strategy that the user wants 
to train. Here it pauses without showing the find. 
It's time to train.

=head2 Overcome an obstacle

The document L<Games::Sudoku::Trainer::Obstacle> 
describes how the user 
lets SudokuTrainer find the next value step by step. He can 
comprehend each step with minimum help by SudokuTrainer.

=head2 Get a further value

The document L<Games::Sudoku::Trainer::Nextvalue> 
describes how the user 
lets SudokuTrainer find value by value, until the find 
hasn't been found by the user before.
So it's above all well suited for users that aren't 
familiar with Sudoku strategies.

=head1 FILE FORMAT OF SUDOKU PUZZLES

The Sudoku files of the trainer are ASCII text files.

The B<input> format for Sudoku puzzles is rather flexible. At the 
top of the file,
lines starting with "#" are ignored (comment lines). In the puzzle itself,
there need not be 9 lines with 9 characters each: newlines are ignored.
The digits 1 - 9 represent known values. Exept for the blank, any other 
printable ASCII character is taken as a placeholder for an unknown value.
Blanks are taken as placeholders only when there are no other placeholders,
otherwise they are ignored. The sum of known values and placeholders must 
amount to 81. When the "#" is used as a placeholder, it is recommended 
that the comment lines are followed by an empty line.

On B<output>, "-" is used as the placeholder. The puzzle is stored as a 9x9 
grid, with blanks and empty lines added to separate the 3x3 subsquares 
for better human readability.

=head1 DIAGNOSTICS

Error messages are displayed in a message window. The window title shows 
the error type:

=over 4

=item * User error

The user made an error when running the trainer (e. g. entered an invalid 
cell name). In most cases he may correct his error.

=item * Data error

An error has been detected in the puzzle (e. g. a cell without a value and 
without candidates).

=item * Code error

A contradiction has been found in the internal state of the puzzle.


=item * Problem

These errors come from other sources, e. g. Perl/Tk or the Perl interpreter.

=back

Perl/Tk shows some of its error messages in its own message window.

The I<Run> button gets disabled when it's of no use to continue. The user
may still save files or investigate the history.

=head1 DEPENDENCIES

In addition to modules that are distributed with perl, the trainer
needs the following modules (available from CPAN):

=over 1

=item * L<http://search.cpan.org/perldoc?Tk> (PerlE<sol>Tk)

=item * L<http://search.cpan.org/perldoc?List::MoreUtils>

=back

=head1 TO DO

=over 1

=item * Add more strategies

=item * Add a restart feature

=back

=head1 BUGS

Please report any bugs or feature requests to bug-SudokuTrainer [at] rt.cpan.org, 
or through the web interface at 
https://rt.cpan.org/Public/Bug/Report.html?Queue=SudokuTrainer.

Please include the following material in the bug report:

=over 4

=item * 

the error message

=item * 

the puzzle (preferedly in its initial state)

=item * 

the priority list, if different from the default

=item * 

any output in the shell window (normally there is none, exept
for code errors)

=back

=head1 AUTHOR

Klaus Wittrock  (<Wittrock [at] cpan.org>)

=head1 ACKNOWLEDGEMENT

Alex Becker pointed out to me several passages in the code that
urgently needed improvement. He also encourages me repeatedly to
use more OO techniques.

=head1 LICENCE AND COPYRIGHT

Copyright 2014 Klaus Wittrock. All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

