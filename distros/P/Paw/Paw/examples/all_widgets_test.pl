#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
# Hardcore example (all widgets) - created just for internal use
# simple and good examples lay in PERL_PATH/Paw/examples/...
# don't use this ! don't read this ! don't eat this !
#
# No Boxes used ! Ugly Style at all !
# DO NOT TRY TO LEARN FROM THIS !
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
#
# 
# you've been warned

use Curses;
use Paw;
use Paw::Line;
use Paw::Button;
use Paw::Label;
use Paw::Menu;
use Paw::Window;
use Paw::Radiobutton;
use Paw::Listbox;
use Paw::Scrollbar;
use Paw::Text_entry;

($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_WHITE, COLOR_RED);

$base=200;

my $hline=Paw::Line->new(name=>"hl", char=>ACS_HLINE, length=>$columns-2, orientation=>"h");
#my $hline = new Paw::Line(name=>"hl", char=>ACS_HLINE, length=>$columns-2, orientation=>"h");
my $hline2=Paw::Line->new(name=>"hl", char=>ACS_HLINE, length=>12, orientation=>"h");
$label0=Paw::Label->new( name=>"test1", text=>"Base : $base");
$label2=Paw::Label->new( name=>"test2", text=>"Faktor 2 ");
$label3=Paw::Label->new( name=>"test3", text=>" Faktor 3 ");
$label4=Paw::Label->new( name=>"test4", text=>" Faktor 4 ");
$label44=Paw::Label->new( name=>"test4", text=>"LABEL");
$label5=Paw::Label->new( name=>"erg",   text=>"Ergebnis : $base");
#$label5->set_border();
$label6=Paw::Label->new( name=>"enter", text=>"Basis    : ");
$label7=Paw::Label->new( name=>"q", text=>"Testfenster");
$label8=Paw::Label->new( name=>"z", text=>"    F10 - Quit and F9 - switch to Pull Down Menu");
$label8->set_border("shade");

@l=("eins", "zwei", "drei", "vier");
$rb1=Paw::Radiobutton->new(name=>"n", labels=>\@l, direction=>"v");
$rb1->set_border("shade");
#@l2=("eins", "zwei", "drei", "vier");
#$rb2=Paw::Radiobutton->new(name=>"n", labels=>\@l2, direction=>"v", callback=>\&test2);

$listbox1=Paw::Listbox->new(name=>"jo", width=>18, height=>5);
#@lb_data=("jo1", "jo2", "jo3", "jo4", "jo5", "jo6", "jo7","jo8", "jo9", "jo10");
#$listbox1->add_row(\@lb_data);
for ( my $i=0; $i<10; $i++ ) {
    $listbox1->add_row("jo$i");
}

$listbox1->set_border("shade");
$sb=Paw::Scrollbar->new(widget=>$listbox1); 

$listbox2=Paw::Listbox->new(name=>"jojo", width=>8, height=>1);
$listbox2->add_row("jo1");
$listbox2->add_row("jo2");
$listbox2->add_row("jo3");
$listbox2->add_row("jo4");
$listbox2->add_row("jo5");
$listbox2->add_row("jo6");
$listbox2->add_row("jo7");

$butt1=Paw::Button->new(name=>"b1", callback=>\&button_callback);
$butt2=Paw::Button->new(name=>"b2", callback=>\&button_callback);
$butt3=Paw::Button->new(name=>"b3", callback=>\&button_callback);
$butt5=Paw::Button->new(name=>"b5", text=>"zum Testfenster", callback=>\&raise_win_button);
$butt5->set_border("shade");

$input1=Paw::Text_entry->new(name=>"ld1", text=>"200", width=>10, orientation=>"right", echo=>2);

$win2=Paw::Window->new(quit_key=>KEY_F(10), name=>"win2", abs_x=>1, abs_y=>1, height=>$rows-3, width=>$columns-2, color=>1, statusbar=>1, orientation=>"grow", time_function=>\&time_func);
$win3=Paw::Window->new(name=>"win3", abs_x=>11,abs_y=>6,height=>$rows-12,width=>$columns-17, color=>2, orientation=>"grow");

$win2->set_border();
$win3->set_border("shade");

$win2->abs_move_curs(new_x=>0,new_y=>0);
$men=Paw::Menu->new(name=>"Menu_Fenster1_links", title=>"Titel ", border=>"shade");
$men->add_menu_point("Testfenster", \&test1);
$men->add_menu_point("Point 2", \&test2);
$win2->put($men);

$men1=Paw::Menu->new(name=>"Menu_Fenster1_rechts", title=>"Titel2", border=>"shade");
$men1->add_menu_point("Point 11", \&test2);
$men1->add_menu_point("Point 22", \&test2);
$men1->add_menu_point($hline2);
#$men1->add_menu_point($rb2);
$men1->add_menu_point($label44);
#$men1->add_menu_point($listbox2);
$win2->put($men1);

$men2=Paw::Menu->new(name=>"Menu_Fenster2", title=>"Titel3", border=>"shade");
$men2->add_menu_point("fenster", \&test2);
$men2->add_menu_point("bla 2", \&test2);
$win3->put($men2);

$men3=Paw::Menu->new(name=>"Menu_im_pulldown_menu", title=>"Titel4", border=>"shade");
$men3->add_menu_point("bla", \&test2);
$men3->add_menu_point("blupp", \&test2);
$men->add_menu_point($men3);

#
# zweites Fenster
#
$win3->abs_move_curs(new_y=>1);
$win3->put($label7);
$input0=Paw::Text_entry->new(name=>"te0", text=>"deflt", width=>20, orientation=>"left", echo=>2);
$win3->abs_move_curs(new_y=>3);
$win3->put($input0);
$input0->set_border("shade");
$button0=Paw::Button->new(name=>"b0", text=>"zurueck", callback=>\&win3_close_button);
$win3->rel_move_curs(new_y=>1);
$button0->set_border("shade");
$win3->put($button0);
#
# zweites Fenster Ende
#



#
# erstes Fenster
#
$win2->abs_move_curs(new_y=>1);  # Cursor positionieren
$win2->put($hline);                       # Linie unter den Pulldowns
$win2->rel_move_curs(new_x=>6,new_y=>1);  # etwas Raum nach unten schaffen
$win2->put_dir("v");                      # vertikales Packen einschalten
$win2->put($label0);                      # "Base : ..."

$win2->put($label2);                      # "Faktor 2" 
$win2->put_dir("h");                      # horizontal packen
$win2->put($butt1);                       # Button fuer Faktor 2
$win2->put($label3);                      # Faktor 3
$win2->put($butt2);                       # Button fuer Faktor 3
$win2->put($label4);                      # Faktor 4
$win2->put($butt3);                       # Button fuer Faktor 4
   
$win2->put_dir("v");                      # vertikal packen
$win2->put($label5);                      # "Ergebnis : ..."

$win2->put($label6);                      # "Basis : "
$win2->put_dir("h");                      # horizontal packen
$win2->put($input1);                      # Eingabefeld fuer Basis
$win2->put_dir("v");                      # vertikal packen
$win2->rel_move_curs(new_x=>2,new_y=>2);  # etwas Raum nach unten schaffen 
$win2->put($butt5);                       # "ins Testfester" Button
$win2->rel_move_curs(new_x=>1);           # etwas Raum nach rechts schaffen 
$win2->put_dir("h");                      # horizontal packen
$win2->put($label8);                      # "q fuer Quit ...."
$win2->rel_move_curs(new_x=>1,new_y=>1);  # etwas Raum nach unten schaffen 
$win2->put_dir("v");                      # vertikal packen
$win2->put($rb1);                         # Radiobutton
$win2->put_dir("h");                      # horizontal packen
$win2->put($listbox1);                    # Listbox
$win2->put($sb);                          # Scrollbar fuer Listbox (buggy)

#
# erstes Fenster
#
$win2->raise();     # entering the main-loop at win2
endwin;



#
# callback routines only
#
sub test1 {
    $win3->raise();

    return;
}

sub test2 {
    flash;
    return;
}

sub button_callback {
    my $erg=$input1->get_text();      # Line entry auslesen
    $erg=$erg*2 if ( $butt1->is_pressed() );# blablabla ...
    $erg=$erg*3 if ( $butt2->is_pressed() );#
    $erg=$erg*4 if ( $butt3->is_pressed() );#
    $label5->set_text("Ergebnis : $erg");#
    $erg=$input1->get_text();         # Line entry auslesen
    $label0->set_text("Base : $erg");    #
}

sub raise_win_button {
    $win3->raise();            # Testfenster aktivieren
}

sub win3_close_button {
    $win3->close_win();
}

sub time_func {
    my $l8t = $label8->get_text();

    $label8->set_text( (substr($l8t, 1).substr($l8t, 0, 1)) );
}

