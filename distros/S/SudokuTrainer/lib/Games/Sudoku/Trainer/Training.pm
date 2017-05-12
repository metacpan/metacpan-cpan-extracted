package Games::Sudoku::Trainer::Training;

use strict;
use warnings;

use version; our $VERSION = qv('0.02');    # PBP

1;

__END__

=head1 NAME

Games::Sudoku::Trainer::Training - train a certain Sudoku strategy

=head1 PURPOSE

This part of the documentation for B<SudokuTrainer> aims at people that want 
to use SudokuTrainer to train a certain Sudoku strategy. If this isn't what 
you expected, please inspect section 
L<Games::Sudoku::Trainer::General_info/GUIDE TO DOCUMENTATION>.

=head1 USAGE 

    perldoc Games::Sudoku::Trainer::Training


=head1 THE MENU BAR 

=over 4

=item * File

Here you may save the current or the initial Sudoku puzzle, save or load
the priority list, or terminate SudokuTrainer.

=item * Pause Mode

Here you select the condition that shall cause SudokuTrainer to enter a
pause. For pause mode I<Value found> the pause may be restricted to
a unit or a cell.

During a pause you may inspect the current state of the puzzle, use
the menus (e. g. to change the pause mode), or try to detect the current 
successful strategy. A click on the I<Run> button terminates the pause.

=item * Priorities

Here you may adapt the priority list to your preferences by moving a selected 
strategy (or a range of strategies) up or down. 
You may also reload the default priority list.

=item * History

Here you may review the history of the current SudokuTrainer session.
The last find is not yet reflected in the history.

=over 4

=item * Summary

Shows counts of all used strategies, ordered by priority.

=item * Overview

Shows the sequence of all used strategies.

=item * Details

Shows all used strategies and the clues that helped to detect them.

=back

=item * View

Here you may toggle the display of the active and/or excluded
candidates of the cells (positive resp. negative candidate list).

=back

=head1 TRAINING A SUDOKU STRATEGY

=head2 Prerequites

B<SudokuTrainer> is not a Sudoku teacher, so you have to know the strategy which
you want to train. You also need an initial puzzle where SudokuTrainer will make use
of that strategy when solving it. If in doubt, you may select pause mode I<non-
stop>, press I<Run> and then inspect the list of I<History | Summary>.

At the start of SudokuTrainer you are offered the choice 
C<Read example file> (see section 
"OPTIONS" in the dokumentation for B<SudokuTrainer> 
(use "perldoc sudokutrainer.pl").
Here you may select a puzzle from a collection of examples
that are included in the distribution. These puzzles are named by the lowest 
(probably most difficult) strategy that SudokuTrainer uses for solving it.

=head2 The priority loop

SudokuTrainer starts each search for a successful strategy at the strategy 
with the highest priority. If this isn't 
successful, it tries the strategy with the next lower priority, and repeats 
this until a priority is successful. Then SudokuTrainer applies the changes to the
puzzle that result from the find, then restarts the priority loop
at the strategy with the highest priority.

SudokuTrainer enters a pause when it finds a condition that matches the 
current pause mode. It displays the current successful strategy, but
does't update the display further. A found value isn't inserted on the
board, the history isn't up to date, nothing.

SudokuTrainer leaves the pause when you click on the I<Run> button.

=head2 Pause at the training strategy

Call menu I<Pause mode | Strategy> and select the training 
strategy from the list, then  the I<Run> button. SudokuTrainer pauses
when it first finds the selected strategy. It's time to train.

=head2 Train the strategy

You know that the displayed puzzle board is now in a state where it's possible to
detect the strategy. So it's recommended that you try to find it without further
help. If you succeed - congratulations! If you don't, you may click the
I<Show details> button, which opens the Details window. It's recommended 
here that you ask for only one
more clue at a time, then try again to find the training strategy. At latest 
after all clues are uncovered you should be able to detect the strategy.
SudokuTrainer cannot help you further.

After you found the strategy, rerun the initial puzzle and try to find the
training strategy with less additional clues. If this works, try a later
occurence of this strategy in the same puzzle or use a different initial puzzle.

=head1 REMARKS ABOUT STRATEGIES

=head2 I<Full house>

I<Full house> is the easiest of all strategies. On the other hand, it isn't needed. 
Without I<Full house>, these patterns would be caught by I<Hidden Single> or 
I<Naked Single> (whichever comes first).

For efficiency reasons, SudokuTrainer treats I<Full house> specially. As a 
consequence,
it cannot be moved off the top position in the priority list.

=head2 I<Hidden Single>

When a digit is found which occurs only once as a candidate in a unit,
it is taken as a I<Hidden Single>, without checking whether there are other candidates
in that cell. This is probably what most Sudoku players do also. When 
you don't like this behaviour (since the candidate isn't actually hidden 
when it is the only one in this cell), give I<Naked Single> a higher 
priority than I<Hidden Single>.

=head2 I<Hidden Single> and I<Naked Single>

These two strategies are (apart from I<Full house>) the workhorses of SudokuTrainer.
So you should keep them near the top of the priority list.

=head2 I<Block-Line Interaction> and I<Line-Block Interaction>

At the end of the priority list you see an entry named I<BLI and LBI>. There
exists no strategy with this name. The background of this is as follows:

Strategies I<Block-Line Interaction> and I<Line-Block Interaction> are processed 
by a common algorithm, scanning all blocks in turn. If a matching
pattern is found, a small final check is done to decide which strategy
has been found, and the opposite one is ignored.

If you you proceed in a similar way when solving a Sudoku puzzle, you
may interchange I<Block-Line Interaction> and I<Line-Block Interaction>
on one side and I<BLI and LBI> on the other in the priority list. The net result
is that both strategies get caught with the same priority. The algorithm still
reports the hits by their real names. The solution path of a puzzle
may become amazingly different.

There is also a pause mode named I<BLI and LBI>. It selects a pause
for strategies I<Block-Line Interaction> and I<Line-Block Interaction>. These are the
only strategies that can be selected for a pause at the same time. The
pseudo-strategy I<BLI and LBI> and the pause mode I<BLI and LBI> may be used 
completely independent of each other.

=head2 I<Skyscraper>, I<Turbot Fish>, and I<Two-String Kite>

These strategies seem to use very similar patterns in the puzzle.
I observed very often that the first of them was successful in a 
certain situation, whichever strategy it was.

=head2 Changing priorities

In general, easy strategies should be near the top of the priority list, 
while very difficult ones should be near the bottom. This will adapt the 
behaviour of SudokuTrainer to the proceeding of the user to some degree. 
Don't expect much from these changes however.

On the other hand, don't try to adapt your proceeding to the behaviour
of SudokuTrainer. B<You> have intuition, so use it.

The default priority list is based on the assumption that candidate lists 
are rarely
used while working with SudokuTrainer. With the help of candidate lists 
several strategies are 
much easier to detect and hence might be moved up in the priority list. 
This includes all strategies named I<Naked xxx> and all strategies 
that deal with cells that have exactly two candidates.
When you often use the candidate lists while working with SudokuTrainer, 
you may save your special priority list for this purpose.

=head1 UNDERSTAND THE EXCLUSION OF CANDIDATES

While working with the trainer, it may happen that the trainer makes use
of the fact that a certain candidate is excluded already, but you cannot
find out how it got excluded.

You restart the puzzle, select I<Pause mode | trace a cell>, and enter the
name of the affected cell. The I<Trace> window pops up. It shows the state
of the candidates of the trace cell. Inspect the candidates that already got 
excluded by the preset values of the initial puzzle, then click the I<Run>
button. The trainer will pause whenever a candidate of the trace cell gets
excluded. In contrast to normal pauses, the Trace window shows immediately the 
excluded candidates. Your current aim is not the training of a strategy, but
the understanding of certain candidate exclusions. So if you are interested 
in details of the current strategy, don't hesitate to uncover all clues 
at once.

=head1 SUPPORTED STRATEGIES

This version of SudokuTrainer supports 15 strategies.
See the README file that is delivered with this distribution for a 
complete list.
