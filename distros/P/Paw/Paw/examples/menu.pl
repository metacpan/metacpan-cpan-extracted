#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# see also perldoc Paw::Menu
use Curses;
use Paw;
use Paw::Label;
use Paw::Window;
use Paw::Menu;

#
# init the screen - allways the same.
#
($columns, $rows)=Paw::init_widgetset();

#
# create a window that fills the screen and grows if
# terminal size changes
#
$win=Paw::Window->new(quit_key=>KEY_F(10), height=>$rows, width=>$columns, statusbar=>1, orientation=>"grow");

#
# create a menu with the exciting Title "Menu 1". This Title will appear
# as label on the screen.
#
$men=Paw::Menu->new(title=>"Menu 1 ", border=>"shade");

#
# add menupoints with the their callback's (totally useless functions, except
# for demonstration how it works).
#
$men->add_menu_point("Beep", \&menu_beep);
$men->add_menu_point("Flash Screen", \&menu_flash);

#
# Put the menu on the window.
#
$win->put($men);

#
# create another menu. With 2 brandnew menupoints.
#
$men2=Paw::Menu->new(title=>"Menue 2 ", border=>"shade");
$men2->add_menu_point("Increment", \&menu_add);
$men2->add_menu_point("Decrement", \&menu_sub);

#
# hey ! Cool ! We put the new menu into the old menu ?! Yes, we do.
#
$men->add_menu_point($men2);
# data
$wert=10;
# a label
$label0=Paw::Label->new(text=>"Wert: $wert");
$win->abs_move_curs(new_x=>5, new_y=>10);
$win->put($label0);

$win->raise();

#
# Callbacks
#
sub menu_beep {
    beep();
}

sub menu_flash {
    flash();
}

sub menu_add {
    $label0->set_text("Wert: ".++$wert);
}

sub menu_sub {
    $label0->set_text("Wert: ".--$wert);
}
