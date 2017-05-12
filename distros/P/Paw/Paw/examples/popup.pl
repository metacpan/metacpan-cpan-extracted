#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# see also perldoc Paw::Popup
use Paw; # needed for widgets
use Curses; # needed for getch() and more
use Paw::Popup;
use Paw::Button;
use Paw::Label;
use Paw::Window;


#
# init, you know.
#
($columns, $rows)=Paw::init_widgetset();

#
# create the array for the statusbar.
# then create a big window with F10 for Quit and the statusbar.
# The window will grow with the screen size 
#
@statusbar=("", "", "", "", "", "", "", "", "", "10=Quit");
$win=Paw::Window->new(quit_key=>KEY_F(10), height=>$rows, width=>$columns, statusbar=>\@statusbar, orientation=>"grow");

#
# create a button that will raise the popup-dialog
# we write it on the button, so everybody will know what will
# happen...
#
$button = Paw::Button->new(callback=>\&button_callback, text=>"Popup-Dialog");
# a beautiful border (okay, just a border)
$button->set_border();

#
# a label that tells you what to do or what has happend.
#
$label = Paw::Label->new(text=>"Enter Popup-Dialog");

#
# create the popup dialog.
# three lines of code for a complete dialog !
# first line  : the labels for the buttons.
# second line : the text that appears in the dialog box.
# third line  : the dialog box with a fixed height and width
#
@buttons = ( "Ok", "Cancel", "don't know" );
$text = ("This is a Popup-Dialog with some buttons.\nNow go ! Leave me alone.");
$pop = Paw::Popup->new( abs_y=>5,shade=>1, buttons=>\@buttons, text=>\$text );

$win->abs_move_curs(new_y=>1); #Bug =:-(

# put the button
$win->put($button);
# put the label
$win->put($label);
# run ...
$win->raise();


sub button_callback {
    my $number=$pop->draw();
    $label->set_text("you pushed button number $number");
    @statusbar=("you", "pushed", "$number", "", "", "", "", "", "", "10=Quit");
}
