#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
#
# see also perldoc Paw::Textbox
use Paw;           # needed for widgets
use Curses;             # needed for getch() and more
use Paw::Textbox;
use Paw::Window;
use Paw::Scrollbar;


($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_BLACK, COLOR_YELLOW );

$win=Paw::Window->new(height=>$rows, width=>$columns);
$text = "first Line\nSecond Line\nblabla\nblablabla\nblupp\nvery creative :-)";
$box=Paw::Textbox->new(cursor_color=>2, text=>\$text, width=>30, height=>5, edit=>1);
$box->set_border();

#$sb=Paw::Scrollbar->new(widget=>$box);

$win->abs_move_curs(new_y=>2);
$win->put($box);
#$win->put($sb);
$win->raise();
