#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# see also perldoc Paw::Listbox

use Curses;
use Paw;
use Paw::Button;
use Paw::Text_entry;
use Paw::Listbox;
use Paw::Window;
use Paw::Scrollbar;


($columns, $rows)=Paw::init_widgetset;

@statusbar=("", "", "", "", "", "", "", "", "", "10=Quit");
$win = Paw::Window->new(quit_key=>KEY_F(10), height=>$rows, width=>$columns, statusbar=>\@statusbar, orientation=>"grow");

init_pair(2, COLOR_BLACK, COLOR_BLUE);
# generate buttons with labels and border
my $add_b = Paw::Button->new(text=>"Add", callback=>(\&add_butt) );
$add_b->set_border("shade");

my $del_b = Paw::Button->new(text=>"Delete", callback=>(\&del_butt) );
$del_b->set_border("shade");

$edit = Paw::Text_entry->new(width=>19, echo=>2, text=>"test");
$edit->set_border("shade");

# generate a listbox with border - self explaining.
$box  = Paw::Listbox->new(width=>19, height=>$rows-13, colored=>1);
$sb   = Paw::Scrollbar->new(widget=>$box);

#
# Fill the box with 500 lines of data.
# my 2 Cent, disable the scrollbar to boost performance
#
for ( my $i=0; $i<500; $i++ ) {
    $box->add_row("jo$i",($i&4)?(2):(1));
}
$box->set_border("shade");

#
# put the other widgets
#
# add button
#
$win->abs_move_curs(new_y=>1);
$win->put($add_b);
#
# add button
#
$win->rel_move_curs(new_x=>2);
$win->put_dir("h");
$win->rel_move_curs(new_x=>2);
$win->put($del_b);
#
# del button
#
$win->put_dir("v");
$win->abs_move_curs(new_y=>2);
$win->put($edit);
#
# the listbox button
#
$win->rel_move_curs(new_y=>2);
$win->put($box);
#
# and the break ... I mean, the scrollbar
# (needs some speed improvements)
#
$win->put($sb);

# we are entering the main-loop now.
$win->raise();

# leaving the programm

#
# the callback section.
#
sub add_butt {
    my $this = shift;
    
    my $data = $edit->get_text();
    $box->add_row($data,1);
    return;
}

sub del_butt {
    my $this = shift;

    @pushed=$box->get_pushed_rows("linenumbers");
    $box->del_row($pushed[0]) if ( @pushed );
}

