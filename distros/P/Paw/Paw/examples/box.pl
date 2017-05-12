#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# see also perldoc Paw::Box

use Curses;
use Paw;
use Paw::Button;
use Paw::Box;
use Paw::Window;

($columns, $rows)=Paw::init_widgetset;

$win = Paw::Window->new(quit_key=>KEY_F(10), height=>$rows, width=>$columns, statusbar=>1, orientation=>"grow");
$vbox0 = Paw::Box->new(direction=>"v", parent=>$win, name=>"vbox0", orientation=>"topleft");
$vbox1 = Paw::Box->new(direction=>"v", parent=>$win, name=>"vbox1", orientation=>"topleft");
$hbox0 = Paw::Box->new(direction=>"h", parent=>$win, name=>"hbox0", orientation=>"topleft");
$hbox1 = Paw::Box->new(direction=>"h", parent=>$win, name=>"hbox1", orientation=>"topleft");


###########################################
# creating all the buttons
###########################################
my $b1 = Paw::Button->new(text=>"1", callback=>(\&add_butt), name=>"1" );
$b1->set_border();
my $b2 = Paw::Button->new(text=>"2", callback=>(\&del_butt), name=>"2" );
$b2->set_border();
my $b3 = Paw::Button->new(text=>"3", callback=>(\&add_butt), name=>"3" );
$b3->set_border();
my $b4 = Paw::Button->new(text=>"4", callback=>(\&del_butt), name=>"4" );
$b4->set_border();
my $b5 = Paw::Button->new(text=>"5", callback=>(\&add_butt), name=>"5" );
$b5->set_border();
my $b6 = Paw::Button->new(text=>"6", callback=>(\&del_butt), name=>"6" );
$b6->set_border();
my $b7 = Paw::Button->new(text=>"7", callback=>(\&add_butt), name=>"7" );
$b7->set_border();
my $b8 = Paw::Button->new(text=>"8", callback=>(\&del_butt), name=>"8" );
$b8->set_border();

$win->abs_move_curs(new_y=>1); # hm..

###########################################
# 7 Buttons building an I
###########################################
$vbox1->put($b2);
$vbox1->put($b3);
$vbox1->put($b4);
$hbox0->put($b1);
$hbox0->put($vbox1);
$hbox0->put($b5);
$vbox0->put($hbox0);    
$hbox1->put($b6);
$hbox1->put($b7);
$hbox1->put($b8);
$vbox0->put($hbox1);

$win->put($vbox0);
###########################################


###########################################
# 7 Buttons building an H
###########################################
#$vbox0->put($b1);
#$hbox1->put($b2);
#$hbox1->put($b3);
#$vbox0->put($hbox1);
#$vbox0->put($b4);
#$hbox0->put($vbox0);
#$vbox1->put($b5);
#$vbox1->put($b6);
#$vbox1->put($b7);
#$hbox0->put($vbox1);

#$win->put($hbox0);
###########################################

$win->raise();

#
# the callback section.
# nothing will happen here.
# Code is just for example (btw, a lousy example)
#
sub add_butt {
    my $this = shift;
}

sub del_butt {
    my $this = shift;
}
