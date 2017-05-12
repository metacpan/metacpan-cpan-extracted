use strict;
use warnings;
#use feature qw( say );

# basic Sudoku structures
# don't panic - all basic Sudoku structures are constant
package main;
our @cells;    # cell objects		(1 .. 81)

package
    Games::Sudoku::Trainer::Check_pause;

use version; our $VERSION = qv('0.02');    # PBP

# This package checks whether a pause is requested at the current state
# of the puzzle.
# It is called from the Sudoku main loop (sub Run::_run_puzzle) when a change
# in the puzzle state (new value or exclusion of candidates) has been found.

# Check whether a pause is requested here
# If yes, wait in the pause until the 'Run' button is pushed
#   check_pause($found_info_ref);
#
sub check_pause {
    my $found_info_ref = shift;
    my $strategy       = $found_info_ref->[0];

    if ( _check_pause1($found_info_ref) ) {
        Games::Sudoku::Trainer::Pause->setInfo_ref($found_info_ref);
        Games::Sudoku::Trainer::Pause->setStrat($strategy);
		# enable the Details button		
        Games::Sudoku::Trainer::GUI::button_state( 'Details', 'enable' );
        if ( $found_info_ref->[1] eq 'insert' ) {
            Games::Sudoku::Trainer::GUI::set_status('Found a further value');
        }
        else {
            Games::Sudoku::Trainer::GUI::set_status('Excluded further candidates');
        }
        if ( Games::Sudoku::Trainer::Pause->Mode eq 'Trace a cell' ) {
            Games::Sudoku::Trainer::GUIpause_restrict::update_tracewindow(
                $found_info_ref);
        }
        else {
            pause();
        }
        Games::Sudoku::Trainer::GUI::set_status('');
        Games::Sudoku::Trainer::Pause->setStrat('');
        # disable the Details button
        Games::Sudoku::Trainer::GUI::button_state( 'Details', 'disable' );
    }
    return;
}

# Check the individual pause modes
#   returns true if a pause is needed
#   $bool = _check_pause1($found_info_ref);
#
sub _check_pause1 {
    my $found_info_ref = shift;
    my $strat          = $found_info_ref->[0];
    my $pause_mode     = Games::Sudoku::Trainer::Pause->Mode;
    $pause_mode or die "3\nNo pause mode";

    if ( $pause_mode eq 'non-stop' )    { return 0 }
    if ( $pause_mode eq 'single-step' ) { return 1 }
    if ( $pause_mode eq 'BLI and LBI' ) {
        return (
                 $strat eq 'Block-Line Interaction'
              or $strat eq 'Line-Block Interaction'
        );
    }
    if ( $pause_mode eq $strat ) { return 1 }

    if ( $pause_mode eq 'value found' ) {
        return _pause_value_found($found_info_ref);
    }

    if ( $pause_mode eq 'Trace a cell' ) {
        return _pause_trace_cell($found_info_ref);
    }
    return 0;
}

# check for pause mode "value found"
#   $bool = _pause_value_found($found_info_ref);
#   placed into a separate sub for better readability
#
sub _pause_value_found {
    my $found_info_ref = shift;

    $found_info_ref->[1] eq 'insert' or return 0;
    my $pause_restrict = Games::Sudoku::Trainer::Pause->Mode_restriction;
    $pause_restrict or return 1;    # anywhere
    my $cell = $found_info_ref->[3]->[1];
    if ( $pause_restrict eq $cell->Name() ) {    # at requested cell
        Games::Sudoku::Trainer::GUI::showmessage(
            -title   => 'Information',
            -message => 'Value found at cell ' . $pause_restrict
        );
        # revert to default pause mode
        Games::Sudoku::Trainer::GUI::set_pause_mode('default');
        return 1;
    }
    else {                                       # in requested unit
        my $unit;
        foreach my $container ( $cell->get_Containers ) {
            $unit = $container;
            last if $container->Name eq $pause_restrict;
        }
        return 0 if $unit->Name ne $pause_restrict;
        if ( $unit->active_Members == 1 ) {
            Games::Sudoku::Trainer::GUI::showmessage(
                -title   => 'Information',
                -message => 'All values found in unit '
                  . $unit->Name
                  . ".\nEnd of 'value found' mode"
            );
            # revert to default pause mode
            Games::Sudoku::Trainer::GUI::set_pause_mode('default');
        }
        return 1;
    }
} ## end sub _pause_value_found

# check for pause mode "trace a cell"
#   $bool = _pause_trace_cell($found_info_ref);
#   placed into a separate sub for better readability
#
sub _pause_trace_cell {
    my $found_info_ref = shift;

    my $pause_restrict = Games::Sudoku::Trainer::Pause->Mode_restriction;
    if ( $found_info_ref->[1] eq 'insert' ) {
        my $cell = $found_info_ref->[3]->[1];
        $cell->Name() eq $pause_restrict
          and return 1;    # value found for trace cell
        my @trace_units =
          Games::Sudoku::Trainer::Cell->by_name($pause_restrict)->get_Containers();
        my @cell_units = $cell->get_Containers();
        foreach ( 0 .. 2 ) {
            $cell_units[$_] == $trace_units[$_]
              and return 1;    # value found in same unit
        }
        return 0;              # trace cell not affected
    }
    else {
        # exclude cand.s: check whether there are exclusions in the trace cell
        my $exclude_info_ref = $found_info_ref->[3];
        my $tracename        = $pause_restrict;
        return map ( {
                $_ =~ /(\d+)-/;
                  my $cellname = $cells[$1]->Name;
                  $cellname =~ /$tracename/ ? ($cellname) : ()
        } @$exclude_info_ref );
    }
}

# enter resp. terminate the pause

{    # block for pause starter / terminater subs

    my $inpause = 0;

    sub pause {
        $inpause = 1;
        Games::Sudoku::Trainer::GUI::wait( \$inpause );
        return;
    }

    sub endpause {
        $inpause = 0;
        return;
    }
}

1;

