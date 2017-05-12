package Games::Sudoku::Trainer::Obstacle;

use strict;
use warnings;

use version; our $VERSION = qv('0.03');    # PBP

1;

__END__

=head1 NAME

Games::Sudoku::Trainer::Obstacle - get over an obstacle while solving a Sudoku puzzle

=head1 PURPOSE

This part of the documentation for SudokuTrainer aims at people that want 
to use SudokuTrainer to get over an obstacle while solving a Sudoku puzzle 
by the use of Sudoku solution strategies. If this isn't what you expected, 
please inspect section
L<Games::Sudoku::Trainer::General_info/GUIDE TO DOCUMENTATION>.

=head1 USAGE 

    perldoc Games::Sudoku::Trainer::Obstacle

=head1 DESCRIPTION

You are stuck in the middle of solving a Sudoku puzzle, and you don't know 
why. In the following sections, steps 1 to 3 describe the normal procedure
to find a continuation. Steps 1a and 1b give suggestions how to deal with
special situations that may occur in step 1.


                     +---------+
                  -->| Step 1a |-->
                 /   +---------+   \
                 |                  |
   +--------+    /                   \     +--------+    +--------+
   | Step 1 |---+---------------------+--->| Step 2 |--->| Step 3 |-->\
   +---+----+    \                   /     +--------+    +--------+    |
                 |                  |                        A         |
                 \   +---------+    |                        |         V
                  -->| Step 1b |-->/                         \--------/
                     +---------+                         (repeat train)


=head2 Step 1: See how far the trainer could solve the puzzle

You feed the puzzle to the Sudoku trainer to see whether it can help 
you. The first question is: Can the Sudoku trainer solve the puzzle, and 
which strategies does it use? You select
pause mode I<non-stop> and click the I<Run> button. You see that the puzzle 
got solved.
You select I<History | Summary> and look at the strategies used.

=head2 Step 1a: Change the priority list

In step 1 you see that the trainer solved the puzzle, but used a strategy 
that you don't know. Next find out how far it can go without this strategy. 
Restart the puzzle, select I<Strategies | Change>, move this strategy to 
the end of the priority list, then select I<< Pause mode | Strategy | 
<this strategy> >> and click the I<Run> button. There
are several possible outcomes:

=over 4

=item *

The trainer solved the puzzle without a pause. So now it got solved without
this strategy. Save the modified priority list in a file, then proceed to
step 2.

=item *

The trainer pauses, and there are values on the board that you didn't find.
So this strategy is needed to solve the puzzle, but you can train the 
strategies that are required to find all the values that you didn't find. 
Save the modified priority list in a file, then proceed to
step 2.

=item *

The trainer pauses, and all values on the board have also been found by you.
So you have solved the puzzle as far as possible without this
strategy. There is no help, you have to learn it.

=back

=head2 Step 1b: Work with a partial solution

The trainer couldn't solve the puzzle in step 1. Nevertheless you may still use
it to train a strategy. Compare your partial solution with that of the trainer. 
You found all values that the trainer did find? Sorry, then it cannot help you.
Otherwise proceed to step 2. Your puzzle will probably remain unsolved 
finally, but you got nearer to the solution and you trained at least
one strategy.


=head2 Step 2: Find the key point

You know all stategies that the trainer used to solve the puzzle. So you
want to watch the trainer while it finds the first value that you didn't
find. To do so, you have to pause the trainer at the B<key point>, i. e. 
at that state where all found values had also been found by you, but the next 
value will be a new one. This sounds trivial, but it isn't, since the
trainer proceeds in a sequence different from yours, and you hardly can
guess which value it will find next. 

Here are three alternative procedures for finding the key point:

=over 4

=item * Start from your partial solution

Enter your partial solution as the initial puzzle. This is often the quickest
way: you are immediately at the key point. However, there is one risk: maybe 
there is an error in your solution. Then you are on the wrong track.

=item * Look at the history

After step 1, select I<History | Details> and search for the key point in the
list.

=item * Step through I<Value found>

Select I<Pause mode | Value found | anywhere> and click the I<Run> button 
repeatedly until the new
value displayed (marked by a black rectangle around it) is one that you 
didn't find. Remember that the trainer is 
one value ahead, so the key point is the predecessor of this value 
(marked by a gray rectangle around it).

=back

Once you found the key point, write it down; you will need it in the next step.

=head2 Step 3: Train the next strategies, beginning at the key point

Obviously you need some training on the strategies that lead from the key
point to the next value, otherwise you would have found the next value by 
yourself.

Restart your puzzle, select I<Pause mode | Value found | at a cell>, enter 
the name of the key point, then click the I<Run> button. The trainer will 
pause at the key point. Now select I<Pause mode | single step> and click the 
I<Run> button. The trainer pauses at the next
successful strategy. Try to find it with minimum help by the I<Details> button, 
as is explained 
in section L<Games::Sudoku::Trainer::Training/Train the strategy>.
Then click again the I<Run> button and try on 
the next strategy, and repeat this until the next value is found. 

Repeat this whole step 
several times, trying to succeed with less help, until you are confident 
that you can find the first new value by yourself. Maybe you prefer to solve 
your puzzle first, but don't forget to return
to the trainer later.
