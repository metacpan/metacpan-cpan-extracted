use strict;
use warnings;

#-----------------------------------------------------------------------
# change priorities dialog
#-----------------------------------------------------------------------

package
    Games::Sudoku::Trainer::GUIprio;

use version; our $VERSION = qv('0.01');    # PBP

my $mw;    # main window

# Show and process the priorities list
# When done, recreate the priorities list
# and the array of strategy function names
# Callback of menu Priorities|Change
#   change_prios($mw);
#
sub change_prios {
    $mw = shift;
    require Tk::DialogBox;
    my $db = $mw->DialogBox(
        -title          => 'Change Strategy Priorities',
        -buttons        => [qw/Ok Cancel/],
        -default_button => 'Cancel',
    );
    my $lb =
      $db->Listbox( -height => 20, -width => 0, -selectmode => 'multiple' )
      ->pack();
    my $but_fr = $db->Frame()->pack();
    $but_fr->Button(
        -text    => 'Fast Up',
        -command => sub { _move_sel( $lb, -5 ) }
    )->pack( -side => 'left' );
    $but_fr->Button( -text => 'Up', -command => sub { _move_sel( $lb, -1 ) } )
      ->pack( -side => 'left' );
    $but_fr->Button(
        -text    => 'Down',
        -command => sub { _move_sel( $lb, +1 ) }
    )->pack( -side => 'left' );
    $but_fr->Button(
        -text    => 'Fast Down',
        -command => sub { _move_sel( $lb, +5 ) }
    )->pack( -side => 'left' );
    $but_fr->Label()->pack( -side => 'left' );    # separator
    $but_fr->Button(
        -text    => 'Default',
        -command => sub { _insert_default($lb) }
    )->pack( -side => 'left' );
    $lb->delete( 0, 'end' );
    $lb->insert( 'end', Games::Sudoku::Trainer::Priorities::copy_strats() );
    my $answer = $db->Show();
    $answer or return;    # user hit the kill button of the title bar
    $answer eq 'Cancel' and return;
    my @strats = $lb->get( 0, 'end' );
    Games::Sudoku::Trainer::Priorities::set_strats( \@strats );
    return;
} ## end sub change_prios

# move a block of selected strategies up or down in the Listbox
#   callback of the Up/Down buttons
#
sub _move_sel {
    my ( $lb, $amount ) = @_;
    my @selidxs = $lb->curselection();

    @selidxs or do {
        Games::Sudoku::Trainer::Run::user_err(
		  "Please select the strategies to be moved");
        return;
    };
    $selidxs[-1] - $selidxs[0] == $#selidxs or do {
        Games::Sudoku::Trainer::Run::user_err(
		  "The selection must be contiguous");
        return;
    };
    my @movethem = $lb->get( $selidxs[0], $selidxs[-1] );
    if ( $amount < 0 ) {
        my $endpos = $selidxs[0] + $amount;
        $endpos < 0 and $amount -= $endpos;
        return if $amount == 0;
    }
    else {
        my $lastpos = $selidxs[-1] + $amount;
        my $excess  = $lastpos - $lb->size() + 1;
        $excess > 0 and $amount -= $excess;
        return if $amount == 0;
    }
    $lb->delete( $selidxs[0], $selidxs[-1] );
    $lb->insert( $selidxs[0] + $amount, @movethem );
    $lb->see( $selidxs[0] + $amount );

    # reselect the moved lines for further move
    $lb->selectionSet( $selidxs[0] + $amount, $selidxs[-1] + $amount );
    return;
} ## end sub _move_sel

# insert the default priority list into the Listbox
#   callback of the 'Default' button
#
sub _insert_default {
    my $lb = shift;

    $lb->delete( 0, 'end' );
    $lb->insert( 'end', Games::Sudoku::Trainer::Priorities::copy_default() );
    return;
}

1;
