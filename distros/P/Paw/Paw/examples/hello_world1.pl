#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
use Paw; # needed for widgets
use Curses; # needed for getch() and more
use Paw::Window;
use Paw::Label;

####################################################
# init_widgetset is the initialisation
# and is needed always.
# The $columns and $rows scalar contains
# the height and width of the screen
####################################################
($columns, $rows)=Paw::init_widgetset;

###################################################
# well, we need a window to put some stuff in it.
# height and width is the full screen (in this example)
###################################################
#$win=Paw::Window->new(height=>$rows, width=>$columns);

###################################################
# another example for a window
###################################################
#$win=Paw::Window->new(abs_x=>10, abs_y=>5, height=>$rows-10 , width=>$columns-20);

###################################################
# now you can quit with F10
###################################################
#init_pair(2, COLOR_WHITE, COLOR_RED);
#$win=Paw::Window->new(quit_key=>KEY_F(10), abs_x=>10, abs_y=>5, height=>$rows-10 , width=>$columns-20, color=>2);
#$win->set_border();

###################################################
# okay, thats's enough for the beginning
###################################################
$win0=Paw::Window->new(abs_y=>1, abs_x=>1,height=>$rows-3, width=>$columns-2);
$win0->set_border();
init_pair(2, COLOR_WHITE, COLOR_RED);
$win=Paw::Window->new(abs_x=>10, abs_y=>5, height=>$rows-10 , width=>$columns-20, color=>2);
$win->set_border("shade");
($wcols, $wrows, $wcolor)=$win->get_window_parameter();
$wcolor = $wcolor; #avoid warning
$win->abs_move_curs(new_x=>$wcols/2-5, new_y=>$wrows/2);
$win0->close_win(); # window will never get focus
$win0->raise();

###################################################
# a label. Simple and stupid.
###################################################
$label=Paw::Label->new( text=>"Hello World" );
#$label->set_border("shade");

###################################################
# put the label into the window.
###################################################
$win->put($label);

###################################################
# okay, thats all - let's start
###################################################
$win->raise();
