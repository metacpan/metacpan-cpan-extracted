use strict;
use warnings;
#use feature qw( say );

# Class for pause-related values
#   A class without instances
#   This class has been introduced to reduce the number of global variables

package
    Games::Sudoku::Trainer::Pause;

use version; our $VERSION = qv('0.01');    # PBP

my $Mode             = '';                  # current pause mode
my $Mode_restriction = '';                  # restriction of current pause mode
my $Strat            = '';                  # strategy that caused this pause
my $Info_ref;    # ref to the info structure
                 # of the strat that caused this pause
                 # for details see doku of array @found
                 # at the top of file Strategies.pm

sub Mode             { return $Mode }              # getter for Mode
sub setMode          { $Mode = $_[1]; return }     # setter for Mode
sub Mode_restriction { return $Mode_restriction }  # getter for Mode_restriction

# setter for Mode_restriction
sub setMode_restriction {
    $Mode_restriction = $_[1];
    return;
}

sub Strat       { return $Strat }                  # getter for Strat
sub setStrat    { $Strat = $_[1]; return }         # setter for Strat
sub Info_ref    { return $Info_ref }               # getter for Info_ref
sub setInfo_ref { $Info_ref = $_[1]; return }      # setter for Info_ref

1;
