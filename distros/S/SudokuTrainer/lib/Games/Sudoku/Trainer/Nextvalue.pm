package Games::Sudoku::Trainer::Nextvalue;

use strict;
use warnings;

use version; our $VERSION = qv('0.02');    # PBP

1;

__END__

=head1 NAME

Games::Sudoku::Trainer::Nextvalue - get some new value while solving a Sudoku puzzle

=head1 PURPOSE

This part of the documentation for SudokuTrainer aims at people that 
just want some new value to get over an obstacle while solving a Sudoku 
puzzle. If this isn't what you expected, please inspect section
L<Games::Sudoku::Trainer::General_info/GUIDE TO DOCUMENTATION>.

=head1 USAGE 

    perldoc Games::Sudoku::Trainer::Nextvalue

=head1 INTRODUCTION

I presume that you like to solve Sudoku puzzles, but don't proceed 
"professionally" by applying Sudoku solution strategies. Instead you 
search intuitively for cells where only one digit remains allowed. 
Sometimes it happens that after a while you cannot assign a further 
digit to a cell. Here this program SudokuTrainer can often help you.

=head1 ENTER THE SUDOKU PUZZLE

When starting SudokuTrainer you have to enter the Sudoku puzzle for 
which you need help. Therefore you select the option C<Insert manually>. 
If you cannot find out how the input works, you may read the 
documentation of B<enter_presets.pl> (use "perldoc enter_presets.pl"). 
When finished with the input you click the Button 
I<Done> and thus reach the main window of SudokuTrainer. There you 
should save the entered puzzle first, just in case you need it again later. 
For this you use the menu C<< File -> Save initial puzzle >>. You may catch 
up this step at any time lateron.

=head1 EDIT A SUDOKU PUZZLE

You may use the option C<Insert manually> also for editing a stored Sudoku 
puzzle, e. g. for correcting an error. For this you click the Button 
I<Edit puzzle> while the Sudoku board is empty, then select the file of the 
puzzle. The changed puzzle is then used as a new puzzle.

=head1 FIND A NEW VALUE

This is easy if you have entered all already known values, i. e. the preset 
values as well as the already found ones. Select menu 
C<< Pause mode -> value found -> anywhere >> and click the I<Run> Button. 
SudokuTrainer finds the first new value, but displays nothing but the 
strategy that found it. Click the I<Run> Button again. SudokuTrainer finds 
the next new value, and in addition displays the previous one with a black 
frame around it. With this value you may try to solve 
your Sudoku puzzle further.

The only problem is: One of the values that you found might be wrong. Then 
the new value given by SudokuTrainer is uncertain. You can check this 
afterwards: Select menu C<< Pause mode -> non-stop >> and click the I<Run> Button 
once. When your puzzle gets solved completely now, everything is ok. If not, 
one of your values might be wrong. Here a stepwise procedure is required.

Either start from scratch and enter only the preset values of your puzzle, or 
remove all values that you found, as described in section 
L<EDIT A SUDOKU PUZZLE|/EDIT A SUDOKU PUZZLE>. Then select menu 
C<< Pause mode -> value found -> anywhere >> repeatedly until the value displayed 
in the black frame wasn't already found by you. With this value you may try 
to solve your Sudoku puzzle further.

=head1 THE EASIEST STRATEGIES

At the start of this document I presumed that you don't know about Sudoku 
solution strategies. This isn't really true. You use at least intuitivily the 
easiest strategies, maybe without knowing their names. I will show them here shortly.

=head2 Full house

In a unit there is only one cell left free. So the still remaining value 
belongs to this cell.

=head2 Hidden single

In a unit a certain candidate is permitted in one cell only. So this candidate 
belongs to this cell. In this cell there are usually further candidates, 
among which this value is hidden.

=head2 Naked single

In a cell there is only one candidate permitted. So this is the value for this 
cell. This strategy is considerably more rarely than the first ones, and it is 
distinctly more difficult to find. Some Sudoku friends maintain a candidate list 
for this. The SudokuTrainer will save you a lot of hard work, when you use 
the menu C<View> to display the internal candidate list.

=head2 Make use of the History

The knowledge of these three easiest strategies opens a further option of getting 
help by SudokuTrainer: Use the preset values only when entering the Sudoku puzzle, 
select menu C<< Pause mode -> non-stop >> and click the I<Run> Button. When then 
the list C<< History -> Summary >> consists of only these three strategies, you will 
know that you truely can solve your Sudoku puzzle completely by yourself. When 
I<Naked single> is there too, you may look up at C<< History -> Overview >> the steps 
where you have to pay attention to this strategy.



