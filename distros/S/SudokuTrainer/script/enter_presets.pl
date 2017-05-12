#!/usr/bin/perl
use strict;
use warnings;
#use feature 'say';

use Tk;
use Tk::Balloon;

use version; our $VERSION = qv('0.01.2');    # PBP

# Usage:
# perl enter_presets.pl

my $tinysize = 10;    # size of a tiny square (pixels)
my $mw;               # the MainWindow
my @sudoku_fields;    # the fields (button widgets) of the sudoku game
my @sudoku_digits;    # the digits displayed on the button widgets
my $fieldsize;        # size of a sudoku field
my $activefield_index = -1;  # the currently active sudoku field
my $clickfield;              # the toplevel which covers the active sudoku field
                             # for clicking
my @tiny_fields = (undef);   # the tiny squares of the
                             # clickfield (indexed 1 .. 9)
my $valuecount  = 0;         # count of entered values
my $edit_b;                  # the edit button

{
    $#sudoku_digits = 80;                      # speedup: preallocate space
    $fieldsize = 3 * ( $tinysize + 1 ) - 1;    # size of sudoku field
    my $totalsize = 9 * ( $fieldsize + 1 ) - 1;
    $mw = MainWindow->new();
    create_sudoku($totalsize);

    # create bottom row

    my $but_fr = $mw->Frame()->pack( -side => 'bottom', -fill => 'x' );

    # make clickfield invisible while mouse is over the bottom frame
    $but_fr->bind( '<Enter>', sub { $clickfield->withdraw } );

    # create edit button
    $edit_b = $but_fr->Button( -text => 'Edit puzzle', -command => \&read_edit )
      ->pack( -side => 'left', -pady => 3 );
    my $edit_tip = $mw->Balloon();
    $edit_tip->attach( $edit_b, -balloonmsg => 'Edit an existing puzzle' );

    # create Done button
    $but_fr->Button(
        -text    => 'Done',
        -command => sub { write_result(); Tk::exit() }
    )->pack( -side => 'left', -padx => 10, -pady => 3 );

    # create Cancel button
    $but_fr->Button( -text => 'Cancel', -command => sub { Tk::exit() } )
      ->pack( -side => 'left' );

    # create value count labels
    $but_fr->Label( -text => 'values' )->pack( -side => 'right' );
    $but_fr->Label(
        -textvariable => \$valuecount,
        -width        => 2,
        -anchor       => 'e'
    )->pack( -side => 'right' );

    # set window size
    my $size_y = $totalsize + $edit_b->reqheight + 6;
    $mw->geometry("${totalsize}x$size_y");
    $mw->resizable( 0, 0 );    # freeze window size
    create_clickfield();

    # On Windows XP, the sudoku window likes to hide itself behind the "DOS"
    # shell window at the moment where the clickfield pops up for the 2nd time.
    # This can be avoided by
    # $mw->raise() or $mw->focus() or $sudoku_fields[any]->focus().
    # Set the initial focus to the 1st field
    $sudoku_fields[0]->focus();

    MainLoop();
    exit 1;
}

sub create_sudoku {
    my $totalsize = shift;

    foreach my $i ( 0 .. 8 ) {
        foreach my $j ( 0 .. 8 ) {
            create_field( $j, $i );
        }
    }

    # draw block separator lines
    foreach my $pos ( 3, 6 ) {
        my $where = $pos * ( $fieldsize + 1 ) - 1;
        $mw->Frame(
            -width      => 1,
            -height     => $totalsize,
            -background => 'black'
        )->place( -x => $where, -y => 0 );
        $mw->Frame(
            -width      => $totalsize,
            -height     => 1,
            -background => 'black'
        )->place( -x => 0, -y => $where );
    }
    return;
}

# create a sudoku field
#
sub create_field {
    my ( $w, $h ) = my ( $w_num, $h_num ) = @_;    # pos. num.s of sudoku field
    my $field_index = $w + 9 * $h;                 # index of sudoku field
    $w *= $fieldsize + 1;                          # pos. of sudoku field
    $h *= $fieldsize + 1;                          #

    my $space = $mw->Frame( -width => $fieldsize, -height => $fieldsize )
      ->place( -x => $w, -y => $h );
    $space->packPropagate(0);                      # prevent resizing the frame
    my $fieldID = $space->Button()->pack( -fill => 'both', -expand => 1 );
    push( @sudoku_fields, $fieldID );

    # mouse and keyboard bindings

    $fieldID->bind( '<Enter>', [ \&move_clickfield, $field_index ] );
    foreach my $digit ( 1 .. 9 ) {
        #alpha keypad
        $fieldID->bind(
            "<Key-$digit>" => [ \&change_digit, $field_index, $digit ] );

        #numeric keypad
        $fieldID->bind(
            "<KP_$digit>" => [ \&change_digit, $field_index, $digit ] );
    }
    # delete digit
    foreach my $key (qw/0 KP_0 space Delete/) {
        $fieldID->bind( "<$key>" => [ \&change_digit, $field_index ] );
    }
    $fieldID->bind( "<Key-Up>"    => [ \&move_focus, $w_num,     $h_num - 1 ] );
    $fieldID->bind( "<Key-Down>"  => [ \&move_focus, $w_num,     $h_num + 1 ] );
    $fieldID->bind( "<Key-Left>"  => [ \&move_focus, $w_num - 1, $h_num ] );
    $fieldID->bind( "<Key-Right>" => [ \&move_focus, $w_num + 1, $h_num ] );
    return;
}

# move focus to neighbouring sudoku field
# callback of the arrow keys
#
sub move_focus {
    my ( $fieldID, $w_new, $h_new ) = @_;

    $clickfield->withdraw;    # make clickfield invisible
    $w_new %= 9;              # end-around
    $h_new %= 9;
    $sudoku_fields[ $w_new + 9 * $h_new ]->focus();
    return;
}

# delete resp. replace sudoku digit
# callback of some keys (alpha or numeric keypad)
# also called from change_my_digit and read_edit
#
sub change_digit {
    my ( $fieldID, $field_index, $digit_num ) = @_;

    $clickfield->withdraw;    # make clickfield invisible
    if ($digit_num) {
        # replace old digit
        $sudoku_digits[$field_index] or $valuecount++;
        $fieldID->configure( -text => $digit_num );
        $sudoku_digits[$field_index] = $digit_num;
        $valuecount == 1 and $edit_b->configure( -state => 'disabled' );
    }
    else {
        # delete old digit
        $fieldID->configure( -text => '' );
        $sudoku_digits[$field_index] = undef;
        $valuecount--;
        $valuecount == 0 and $edit_b->configure( -state => 'normal' );
    }
    return;
}

sub create_clickfield {
    $clickfield = $mw->Toplevel( -width => $fieldsize, -height => $fieldsize );
    $clickfield->overrideredirect(1);    # suppress window frame
    foreach my $i ( 0 .. 2 ) {
        foreach my $j ( 0 .. 2 ) {
            create_tinysquare( $j, $i );
        }
    }
    $clickfield->withdraw;   # make clickfield invisible
    return;
}

sub create_tinysquare {
    my ( $w, $h ) = my ( $w_num, $h_num ) = @_;    # pos. num.s of tiny square
    $w *= $tinysize + 1;                           # pos. of tiny square
    $h *= $tinysize + 1;                           #

    my $space = $clickfield->Frame( -width => $tinysize, -height => $tinysize )
      ->place( -x => $w, -y => $h );
    $space->packPropagate(0);                      # prevent resizing the frame
    my $tiny = $space->Button(
        -relief     => 'flat',
        -background => 'black',
        -command    => [ \&change_my_digit, $w_num + 3 * $h_num + 1 ],
    )->pack( -fill => 'both', -expand => 1 );
    push( @tiny_fields, $tiny );
    return;
}

# position the clickfield over the entered sudoku field
# callback of the <Enter> event
#
sub move_clickfield {
    my ( $fieldID, $field_index ) = @_;   # ID and index of button to be covered

    # ignore re-entering the active field
    # (this happens when withdrawing the clickfield)

    # Color change and popup required when returning from the bottom row,
    # so no return in this case
    return
      if (  $field_index == $activefield_index
        and $clickfield->state eq 'normal' );

    $activefield_index = $field_index;
    $clickfield->withdraw;    # make clickfield invisible

    # mark the tiny square of the current digit by a different color
    foreach my $tiny ( @tiny_fields[ 1 .. 9 ] ) {
        $tiny->configure(
            -background       => 'black',
            -activebackground => 'black'
        );
    }
    if ( ( my $digit = $sudoku_digits[$activefield_index] ) ) {
        $tiny_fields[$digit]->configure(
            -background       => 'red',
            -activebackground => 'orange'
        );
    }
    $clickfield->configure( -popover => $fieldID );
    $clickfield->Popup();    # make clickfield visible
    return;
}

# delete resp. replace old digit of the active sudoku field
# callback of the tiny squares
#
sub change_my_digit {
    my $digit_num = shift;    # digit of the clicked tiny square

    my $fieldID = $sudoku_fields[$activefield_index];
    my $olddigit = $sudoku_digits[$activefield_index] || '';
    if ( $olddigit eq $digit_num ) { $digit_num = undef }
    change_digit( $fieldID, $activefield_index, $digit_num );
    return;
}

# write the entered sudoku puzzle to STDOUT
# callback of the 'Done' button
#
sub write_result {
    # placeholder for unknown digits in sudoku output files
    my $unknown_digit = '-';

    my @alldigits = map( { defined $_ ? $_ : $unknown_digit } @sudoku_digits );
    unless (-t) {
        print @alldigits, "\n";    # output for sudoku trainer
        return;
    }
    for ( my $pos = 0 ; $pos < $#sudoku_digits ; $pos += 9 ) {

        # for better human readability
        if ( $pos > 0 and $pos % 27 == 0 ) { print "\n" }
        printf "%s%s%s %s%s%s %s%s%s\n", ( @alldigits[ $pos .. $pos + 8 ] );
    }
    return;
}

# read a sudoku puzzle for editing
# callback of the 'Edit puzzle' button
#
sub read_edit {
    my $editname = $mw->getOpenFile;
    use Encode;
    $editname = encode( 'iso-8859-1', $editname );
    return unless $editname;
    open( my $edit, '<', $editname ) or die("can't open $editname: $!");
    my @game = <$edit>;
    close($edit);
    while ( $game[0] =~ /^#/ ) { shift @game }; # ignore preceeding comment lines
    my $gamestring = join( '', @game );
    $gamestring =~ s/\n//g;                     # ignore newlines
                                                # ignore whitespace
    if ( length($gamestring) > 81 ) { $gamestring =~ s/\s//g }
    $gamestring =~ tr/[1-9]/-/c;    # convert all placeholders to '-'
    @game = split( '', $gamestring );

    # insert the puzzle values into the board
    foreach my $field_index ( 0 .. 80 ) {
        my $digit_num = $game[$field_index];
        next if $digit_num eq '-';
        change_digit( $sudoku_fields[$field_index], $field_index, $digit_num );
    }
    return;
}

__END__

=head1 NAME

B<enter_presets> - enter the initial values of a Sudoku puzzle.

=head1 VERSION 

This documentation refers to B<enter_presets> version 0.01.2

=head1 USAGE 

This program is called internally by 
B<SudokuTrainer> when
the user selects the option I<Enter manually> to create the initial puzzle.

=head1 DESCRIPTION 

B<enter_presets> initially displays an empty Sudoku board. Values may be 
entered via the mouse or via the keyboard.

=head2 Input via the mouse

When the mouse cursor enters a cell of the board, this cell gets covered
by a 3x3 grid of tiny squares. Each square corresponds to one of the digits 
1 to 9. If the cell already contains a value, the corresponding square is
shown in red. 

Clicking on one of the black squares inserts the corresponding
digit as the value of the cell. So you can select a cell and a digit with
a single mouse click (I am very proud on this invention). Any previous
value of the cell will be replaced. 
Clicking on the red square will remove the corresponding 
value from the cell.

=head2 Input via the keyboard 

The input focus may be moved to an adjacent cell by the I<arrow> keys (end
around). A value may be entered in the active cell by the keys I<1> to I<9> (on the
alpha or numeric keypad). This will replace any previous value in the cell.
A value may be deleted by the keys I<0>, I<Delete>, or the I<Space bar>.

Pressing any of the supported keys will also hide the 3x3 grid.

=head1 EDIT AN EXISTING PUZZLE

You may use B<enter_presets> to edit an existing puzzle, 
e. g. to correct an error. While the board is
empty, click the I<Edit puzzle> button and select the puzzle.

=head1 TERMINATING THE PROGRAM 

B<enter_presets> may be terminated by activation of the I<Done> button or by 
the I<Cancel> button. In the latter case
no output is generated.

=head1 MANUAL INVOCATION 

If you like to play Sudoku on a board that is as intelligent as a sheet
of paper, B<enter_presets> is a nice choice. Invoke it by entering

    perl path/to/enter_presets.pl > mypuzzle.sudo

on the command line. The output file may be used as the initial puzzle
of the trainer.

=head1 SEE ALSO 

The dokumentation for B<SudokuTrainer> (use "perldoc sudokutrainer.pl").

=head1 DEPENDENCIES 

=over 1

=item * L<http://search.cpan.org/perldoc?Tk> (PerlE<sol>Tk)

=back

=head1 BUGS

Please report any bugs or feature requests to bug-SudokuTrainer [at] rt.cpan.org, 
or through the web interface at 
https://rt.cpan.org/Public/Bug/Report.html?Queue=SudokuTrainer.

Patches are welcome.

=head1 AUTHOR

Klaus Wittrock  (Wittrock [at] cpan.org)

=head1 LICENCE AND COPYRIGHT

Copyright 2014 Klaus Wittrock. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

