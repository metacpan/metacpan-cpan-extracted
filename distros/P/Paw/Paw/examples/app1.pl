#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
use Curses;
use Paw;
use Paw::Button;
use Paw::Text_entry;
use Paw::Box;
use Paw::Window;
use Paw::Line;
use Paw::Label;



#################################################
# Data Storage
#################################################
$provider_nr = 0;
$msn = 0;
$account_sync_ppp = "";
$passwort = "";
$eigene_ip = "";
$ip_p2p = "";
$ip_dns = "";

$ip_intern = "";
$netmask_intern = "";
$hostname = "";
$domain = "";

$fax_nr = 0;

#################################################
# Initialisation
#################################################
($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_CYAN, COLOR_BLACK);
init_pair(3, COLOR_WHITE, COLOR_MAGENTA);

#################################################
# Global Widgets
#################################################
$main_win=Paw::Window->new(height=>$rows, width=>$columns, color=>1, orientation=>"grow");
$mask1_win=Paw::Window->new(abs_x=>int(($columns-60)/2), abs_y=>int(($rows-18)/2), height=>18, width=>60, color=>3, title=>"ISDN-Parameter");
$mask1_win->set_border("shade");
$mask2_win=Paw::Window->new(abs_x=>int(($columns-50)/2), abs_y=>int(($rows-15)/2), height=>15, width=>50, title=>"Netz-Parameter");
$mask2_win->set_border("shade");
$mask3_win=Paw::Window->new(abs_x=>int(($columns-50)/2), abs_y=>int(($rows-15)/2), height=>15, width=>50, title=>"Fax-Parameter");
$mask3_win->set_border("shade");

#################################################
# Main Window - Widgets
#################################################
$main_vbox0=Paw::Box->new(direction=>"v", orientation=>"center");
$main_hbox0=Paw::Box->new(direction=>"h", orientation=>"center");
$main_butt1=Paw::Button->new(text=>"ISDN-Parameter", callback=>\&mask1_cb);
$main_butt1->set_border();
$main_butt2=Paw::Button->new(text=>"Netz-Parameter", callback=>\&mask2_cb);
$main_butt2->set_border();
$main_butt3=Paw::Button->new(text=>"Fax-Parameter ", callback=>\&mask3_cb);
$main_butt3->set_border();
$main_line1=Paw::Line->new(length=>40);

$main_ok=Paw::Button->new(text=>"Save and Exit", callback=>\&main_ok_cb);
$main_ok->set_border();
$main_cancel=Paw::Button->new(text=>"Exit without saving", callback=>\&main_cancel_cb);
$main_cancel->set_border();

$main_vbox0->rel_move_curs(new_x=>11, new_y=>1);
$main_vbox0->put($main_butt1);
$main_vbox0->put($main_butt2);
$main_vbox0->put($main_butt3);
$main_vbox0->rel_move_curs(new_x=>-11);
$main_vbox0->put($main_line1);

$main_hbox0->put($main_ok);
$main_hbox0->put($main_cancel);

$main_vbox0->put($main_hbox0);
$main_vbox0->set_border("shade");

$main_win->abs_move_curs(new_x=>($columns-40)/2,new_y=>($rows-13)/2);
$main_win->put($main_vbox0);

#################################################
# Maske 1 - Widgets
#################################################
$m1_vbox2=Paw::Box->new(name=>"m1_vbox2", direction=>"v", parent=>$mask1_win);
$m1_hbox0=Paw::Box->new(name=>"m1_hbox0",direction=>"h", parent=>$m1_vbox2);
$m1_hbox1=Paw::Box->new(name=>"m1_hbox1",direction=>"h", parent=>$m1_vbox2);
$m1_vbox0=Paw::Box->new(name=>"m1_vbox0",direction=>"v", parent=>$m1_hbox1);
$m1_vbox1=Paw::Box->new(name=>"m1_vbox1",direction=>"v", parent=>$m1_hbox0);

$m1_ok=Paw::Button->new(text=>"Ok", callback=>\&m1_ok_cb);
$m1_ok->set_border("shade");
$m1_cancel=Paw::Button->new(text=>"Cancel", callback=>\&m1_cancel_cb);
$m1_cancel->set_border("shade");
$m1_hbox1->put($m1_ok);
$m1_hbox1->rel_move_curs(new_x=>32);
$m1_hbox1->put($m1_cancel);

$m1_label1 = Paw::Label->new(text=>"Einwahlnummer des Providers : ");
$m1_label2 = Paw::Label->new(text=>"Eigene MSN                  : ");
$m1_label3 = Paw::Label->new(text=>"Benutzeraccount fuer syncPPP: ");
$m1_label4 = Paw::Label->new(text=>"Benutzerpasswort            : ");
$m1_label5 = Paw::Label->new(text=>"Eigene IP                   : ");
$m1_label6 = Paw::Label->new(text=>"IP Point2Point Partner      : ");
$m1_label7 = Paw::Label->new(text=>"IP DNS-Server des Providers : ");

$m1_vbox0->put($m1_label1);
$m1_vbox0->put($m1_label2);
$m1_vbox0->put($m1_label3);
$m1_vbox0->put($m1_label4);
$m1_vbox0->put($m1_label5);
$m1_vbox0->put($m1_label6);
$m1_vbox0->put($m1_label7);

$m1_entry1 = Paw::Text_entry->new(width=>18,color=>2);
$m1_entry2 = Paw::Text_entry->new(width=>18,color=>2);
$m1_entry3 = Paw::Text_entry->new(width=>18,color=>2);
$m1_entry4 = Paw::Text_entry->new(width=>18,color=>2, echo=>1);
$m1_entry5 = Paw::Text_entry->new(width=>18,color=>2);
$m1_entry6 = Paw::Text_entry->new(width=>18,color=>2);
$m1_entry7 = Paw::Text_entry->new(width=>18,color=>2);

$m1_vbox1->put($m1_entry1);
$m1_vbox1->put($m1_entry2);
$m1_vbox1->put($m1_entry3);
$m1_vbox1->put($m1_entry4);
$m1_vbox1->put($m1_entry5);
$m1_vbox1->put($m1_entry6);
$m1_vbox1->put($m1_entry7);
$m1_hbox0->put($m1_vbox0);
$m1_hbox0->put($m1_vbox1);
$m1_hbox0->set_border("shade");

$m1_vbox2->put($m1_hbox0);
$m1_vbox2->rel_move_curs(new_y=>3);
$m1_vbox2->put($m1_hbox1);

$mask1_win->abs_move_curs(new_x=>5, new_y=>2);
$mask1_win->put($m1_vbox2);

#################################################
# Maske 2 - Widgets
#################################################
$m2_vbox2=Paw::Box->new(name=>"m2_vbox2", direction=>"v", parent=>$mask2_win);
$m2_hbox0=Paw::Box->new(name=>"m2_hbox0",direction=>"h", parent=>$m2_vbox2);
$m2_hbox1=Paw::Box->new(name=>"m2_hbox1",direction=>"h", parent=>$m2_vbox2);
$m2_vbox0=Paw::Box->new(name=>"m2_vbox0",direction=>"v", parent=>$m2_hbox1);
$m2_vbox1=Paw::Box->new(name=>"m2_vbox1",direction=>"v", parent=>$m2_hbox0);

$m2_ok=Paw::Button->new(text=>"Ok", callback=>\&m2_ok_cb);
$m2_ok->set_border("shade");
$m2_cancel=Paw::Button->new(text=>"Cancel", callback=>\&m2_cancel_cb);
$m2_cancel->set_border("shade");
$m2_hbox1->put($m2_ok);
$m2_hbox1->rel_move_curs(new_x=>23);
$m2_hbox1->put($m2_cancel);

$m2_label1 = Paw::Label->new(text=>"IP-Adresse intern : ");
$m2_label2 = Paw::Label->new(text=>"Netzmaske intern  : ");
$m2_label3 = Paw::Label->new(text=>"Rechnername       : ");
$m2_label4 = Paw::Label->new(text=>"Domainname        : ");

$m2_vbox0->put($m2_label1);
$m2_vbox0->put($m2_label2);
$m2_vbox0->put($m2_label3);
$m2_vbox0->put($m2_label4);

$m2_entry1 = Paw::Text_entry->new(width=>18,color=>2);
$m2_entry2 = Paw::Text_entry->new(width=>18,color=>2);
$m2_entry3 = Paw::Text_entry->new(width=>18,color=>2);
$m2_entry4 = Paw::Text_entry->new(width=>18,color=>2);

$m2_vbox1->put($m2_entry1);
$m2_vbox1->put($m2_entry2);
$m2_vbox1->put($m2_entry3);
$m2_vbox1->put($m2_entry4);
$m2_hbox0->put($m2_vbox0);
$m2_hbox0->put($m2_vbox1);
$m2_hbox0->set_border("shade");

$m2_vbox2->put($m2_hbox0);
$m2_vbox2->rel_move_curs(new_y=>3);
$m2_vbox2->put($m2_hbox1);

$mask2_win->abs_move_curs(new_x=>5, new_y=>2);
$mask2_win->put($m2_vbox2);



#################################################
# Maske 3 - Widgets
#################################################
$m3_vbox2=Paw::Box->new(name=>"m3_vbox2", direction=>"v", parent=>$mask3_win);
$m3_hbox0=Paw::Box->new(name=>"m3_hbox0",direction=>"h", parent=>$m3_vbox2);
$m3_hbox1=Paw::Box->new(name=>"m3_hbox1",direction=>"h", parent=>$m3_vbox2);
$m3_vbox0=Paw::Box->new(name=>"m3_vbox0",direction=>"v", parent=>$m3_hbox1);
$m3_vbox1=Paw::Box->new(name=>"m3_vbox1",direction=>"v", parent=>$m3_hbox0);

$m3_ok=Paw::Button->new(text=>"Ok", callback=>\&m3_ok_cb);
$m3_ok->set_border("shade");
$m3_cancel=Paw::Button->new(text=>"Cancel", callback=>\&m3_cancel_cb);
$m3_cancel->set_border("shade");
$m3_hbox1->put($m3_ok);
$m3_hbox1->rel_move_curs(new_x=>23);
$m3_hbox1->put($m3_cancel);

$m3_label1 = Paw::Label->new(text=>"Eigene Faxnummer : ");
$m3_vbox0->put($m3_label1);

$m3_entry1 = Paw::Text_entry->new(width=>18,color=>2);
$m3_vbox1->put($m3_entry1);

$m3_hbox0->put($m3_vbox0);
$m3_hbox0->put($m3_vbox1);
$m3_hbox0->set_border("shade");

$m3_vbox2->put($m3_hbox0);
$m3_vbox2->rel_move_curs(new_y=>3);
$m3_vbox2->put($m3_hbox1);

$mask3_win->abs_move_curs(new_x=>5, new_y=>2);
$mask3_win->put($m3_vbox2);


$main_win->raise();

#################################################
# callback routines only
#################################################

#
# Main Win
#
sub main_cancel_cb {
    $main_win->close_win();
    
    return;
}
sub main_ok_cb {
    $main_win->close_win();

    print $provider_nr;
    print $msn;
    print $account_sync_ppp;
    print $passwort;
    print $eigene_ip;
    print $ip_p2p;
    print $ip_dns;

    print $ip_intern;
    print $netmask_intern;
    print $hostname;
    print $domain;

    print $fax_nr;

    return;
}


#
# Maske 1
#
sub mask1_cb {
    $mask1_win->raise();

    return;
}

# when you are leaving the Window with the "Ok" button,
# all text-entrys will be read out and the stored in global
# variables
sub m1_ok_cb {
    $provider_nr      = $m1_entry1->get_text();
    $msn              = $m1_entry2->get_text();;
    $account_sync_ppp = $m1_entry3->get_text();;
    $passwort         = $m1_entry4->get_text();;
    $eigene_ip        = $m1_entry5->get_text();;
    $ip_p2p           = $m1_entry6->get_text();;
    $ip_dns           = $m1_entry7->get_text();;
    $mask1_win->close_win();
}

sub m1_cancel_cb {
    $mask1_win->close_win();
}

#
# Maske 2
#
sub mask2_cb {
    $mask2_win->raise();

    return;
}

# when you are leaving the Window with the "Ok" button,
# all text-entrys will be read out and the stored in global
# variables
sub m2_ok_cb {
    $ip_intern      = $m2_entry1->get_text();;
    $netmask_intern = $m2_entry2->get_text();;
    $hostname       = $m2_entry3->get_text();;
    $domain         = $m2_entry4->get_text();;
    $mask2_win->close_win();
}

sub m2_cancel_cb {
    $mask2_win->close_win();
}


#
# Maske 3
#
sub mask3_cb {
    $mask3_win->raise();

    return;
}

# when you are leaving the Window with the "Ok" button,
# all text-entrys will be read out and the stored in global
# variables
sub m3_ok_cb {
    $fax_nr = $m2_entry1->get_text();;
    $mask3_win->close_win();
}
sub m3_cancel_cb {
    $mask3_win->close_win();
}
