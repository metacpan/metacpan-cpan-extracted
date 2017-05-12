use strict;
use warnings;

package
    Games::Sudoku::Trainer::Priorities;

use version; our $VERSION = qv('0.02');    # PBP

# globals
my @strategies;    # strategies arranged by current priorities

# build the strategy names and strategy functions arrays

my @default_strats = (    # arranged by default priorities
    'Hidden Single',
    'Naked Single',
    'Block-Line Interaction',
    'Line-Block Interaction',
    'Naked Pair',
    'Hidden Pair',
    'Bivalue Universal Grave',
    #	'Remote Pair',
    'X Wing',
    'Skyscraper',
    'Turbot Fish',
    'Unique Rectangle Type 1',
    'Two-String Kite',
    'Unique Rectangle Type 2',
    'XY Wing',
    'BLI and LBI',
);

# array of strategy function names, ordered by current priorities
my @strat_funcs;

set_strats( \@default_strats );

# define array of current priorities
# and array of strategy function names
#
sub set_strats {
    my $strats_ref = shift;

    @strategies = @$strats_ref;

    # replace upper by lower, special by '_'; prepend by '_'
    @strat_funcs = @strategies;
    @strat_funcs = map { tr/- A-Z/__a-z/; '_' . $_ } @strat_funcs;
    return;
}

# return ref to array of strategy function names
#   my $strats_ref = Games::Sudoku::Trainer::Priorities::strat_funcs_ref();
#
sub strat_funcs_ref { return \@strat_funcs }

# return copy of current priority array
#
sub copy_strats { return @strategies }

# return copy of default priority array
#
sub copy_default { return @default_strats }

1;
