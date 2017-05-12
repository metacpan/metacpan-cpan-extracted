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
use Paw::Label;
use Paw::Popup;

#################################################
# Data Variable
#################################################
$provider_nr      = 0;
$msn              = 0;
$account_sync_ppp = '';
$passwort         = '';
$passwort_is_okay = 0;
$eigene_ip        = '';
$ip_p2p           = '';
$ip_dns           = '';

$ip_intern        = '';
$netmask_intern   = '';
$hostname         = '';
$domain           = '';

$fax_nr           = 0;

#################################################
# initialize widgetset
#################################################
($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_CYAN, COLOR_BLACK);    # Textentrys
init_pair(3, COLOR_WHITE, COLOR_MAGENTA); # Windows
init_pair(4, COLOR_WHITE, COLOR_RED);     # reenter Password

#################################################
# initialize all Windows
#################################################
$mask1_win=Paw::Window->new(abs_x=>int(($columns-60)/2), abs_y=>int(($rows-18)/2), height=>18, width=>60, color=>3, title=>'ISDN-Parameter', orientation=>'center');
$mask1_win->set_border('shade');
$mask2_win=Paw::Window->new(abs_x=>int(($columns-50)/2), abs_y=>int(($rows-15)/2), height=>15, width=>50, title=>'Netz-Parameter', color=>3, orientation=>'center');
$mask2_win->set_border('shade');
$mask3_win=Paw::Window->new(abs_x=>int(($columns-45)/2), abs_y=>int(($rows-12)/2), height=>11, width=>45, title=>'Fax-Parameter', color=>3, orientation=>'center');
$mask3_win->set_border('shade');
$reenter_win=Paw::Window->new(abs_x=>int(($columns-45)/2), abs_y=>int(($rows-12)/2), height=>13, width=>46, title=>'Passwort verifizieren', color=>4, orientation=>'center');
$reenter_win->set_border('shade');

#################################################
# Maske 1 - Widgets (ISDN-Parameter)
#################################################
$m1_vbox2=Paw::Box->new(name=>'m1_vbox2', direction=>'v', parent=>$mask1_win);
$m1_hbox0=Paw::Box->new(name=>'m1_hbox0', direction=>'h', parent=>$m1_vbox2);
$m1_hbox1=Paw::Box->new(name=>'m1_hbox1', direction=>'h', parent=>$m1_vbox2);
$m1_vbox0=Paw::Box->new(name=>'m1_vbox0', direction=>'v', parent=>$m1_hbox1);
$m1_vbox1=Paw::Box->new(name=>'m1_vbox1', direction=>'v', parent=>$m1_hbox0);

$m1_abbrechen=Paw::Button->new(text=>'Abbrechen', callback=>\&m1_abbrechen_cb);
$m1_abbrechen->set_border('shade');
$m1_weiter=Paw::Button->new(name=>'m1_weiter', text=>'Weiter', callback=>\&m1_weiter_cb);
$m1_weiter->set_border('shade');
$m1_hbox1->put($m1_abbrechen);
$m1_hbox1->rel_move_curs(new_x=>26);
$m1_hbox1->put($m1_weiter);

$m1_label1 = Paw::Label->new(text=>'Einwahlnummer des Providers : ');
$m1_label2 = Paw::Label->new(text=>'Eigene MSN                  : ');
$m1_label3 = Paw::Label->new(text=>'Benutzeraccount fuer syncPPP: ');
$m1_label4 = Paw::Label->new(text=>'Benutzerpasswort            : ');
$m1_label5 = Paw::Label->new(text=>'Eigene IP                   : ');
$m1_label6 = Paw::Label->new(text=>'IP Point2Point Partner      : ');
$m1_label7 = Paw::Label->new(text=>'IP DNS-Server des Providers : ');

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
$m1_entry4 = Paw::Text_entry->new(width=>18,color=>2, echo=>1, callback=>\&reenter_password_cb);
$m1_entry5 = Paw::Text_entry->new(width=>15,color=>2, max_length=>15);
$m1_entry6 = Paw::Text_entry->new(width=>15,color=>2, max_length=>15);
$m1_entry7 = Paw::Text_entry->new(width=>15,color=>2, callback=>\&m1_last_entry_cb, max_length=>15);

$m1_vbox1->put($m1_entry1);
$m1_vbox1->put($m1_entry2);
$m1_vbox1->put($m1_entry3);
$m1_vbox1->put($m1_entry4);
$m1_vbox1->put($m1_entry5);
#$m1_vbox1->put($m1_iphbox0);
$m1_vbox1->put($m1_entry6);
$m1_vbox1->put($m1_entry7);
$m1_hbox0->put($m1_vbox0);
$m1_hbox0->put($m1_vbox1);
$m1_hbox0->set_border('shade');

$m1_vbox2->put($m1_hbox0);
$m1_vbox2->rel_move_curs(new_y=>3);
$m1_vbox2->put($m1_hbox1);

$mask1_win->abs_move_curs(new_x=>5, new_y=>2);
$mask1_win->put($m1_vbox2);

#################################################
# Maske 2 - Widgets (Netz-Parameter)
#################################################
$m2_vbox2=Paw::Box->new(name=>'m2_vbox2', direction=>'v', parent=>$mask2_win);
$m2_hbox0=Paw::Box->new(name=>'m2_hbox0', direction=>'h', parent=>$m2_vbox2);
$m2_hbox1=Paw::Box->new(name=>'m2_hbox1', direction=>'h', parent=>$m2_vbox2);
$m2_vbox0=Paw::Box->new(name=>'m2_vbox0', direction=>'v', parent=>$m2_hbox1);
$m2_vbox1=Paw::Box->new(name=>'m2_vbox1', direction=>'v', parent=>$m2_hbox0);

$m2_weiter=Paw::Button->new(name=>'m2_weiter', text=>'Weiter', callback=>\&m2_weiter_cb);
$m2_weiter->set_border('shade');
$m2_zurueck=Paw::Button->new(text=>'Zurueck', callback=>\&m2_zurueck_cb);
$m2_zurueck->set_border('shade');
$m2_hbox1->put($m2_zurueck);
$m2_hbox1->rel_move_curs(new_x=>19);
$m2_hbox1->put($m2_weiter);

$m2_label1 = Paw::Label->new(text=>'IP-Adresse intern : ');
$m2_label2 = Paw::Label->new(text=>'Netzmaske intern  : ');
$m2_label3 = Paw::Label->new(text=>'Hostname          : ');
$m2_label4 = Paw::Label->new(text=>'Domainname        : ');

$m2_vbox0->put($m2_label1);
$m2_vbox0->put($m2_label2);
$m2_vbox0->put($m2_label3);
$m2_vbox0->put($m2_label4);

$m2_entry1 = Paw::Text_entry->new(width=>15,color=>2, max_length=>15);
$m2_entry2 = Paw::Text_entry->new(width=>15,color=>2, max_length=>15);
$m2_entry3 = Paw::Text_entry->new(width=>18,color=>2);
$m2_entry4 = Paw::Text_entry->new(width=>18,color=>2,callback=>\&m2_last_entry_cb);

$m2_vbox1->put($m2_entry1);
$m2_vbox1->put($m2_entry2);
$m2_vbox1->put($m2_entry3);
$m2_vbox1->put($m2_entry4);
$m2_hbox0->put($m2_vbox0);
$m2_hbox0->put($m2_vbox1);
$m2_hbox0->set_border('shade');

$m2_vbox2->put($m2_hbox0);
$m2_vbox2->rel_move_curs(new_y=>3);
$m2_vbox2->put($m2_hbox1);

$mask2_win->abs_move_curs(new_x=>5, new_y=>2);
$mask2_win->put($m2_vbox2);



#################################################
# Maske 3 - Widgets (Fax-Parameter)
#################################################
$m3_vbox2=Paw::Box->new(name=>'m3_vbox2', direction=>'v', parent=>$mask3_win);
$m3_hbox0=Paw::Box->new(name=>'m3_hbox0', direction=>'h', parent=>$m3_vbox2);
$m3_hbox1=Paw::Box->new(name=>'m3_hbox1', direction=>'h', parent=>$m3_vbox2);
$m3_vbox0=Paw::Box->new(name=>'m3_vbox0', direction=>'v', parent=>$m3_hbox1);
$m3_vbox1=Paw::Box->new(name=>'m3_vbox1', direction=>'v', parent=>$m3_hbox0);

$m3_weiter=Paw::Button->new(name=>'m3_weiter',text=>'Ende', callback=>\&m3_weiter_cb);
$m3_weiter->set_border('shade');
$m3_zurueck=Paw::Button->new(text=>'zurueck', callback=>\&m3_zurueck_cb);
$m3_zurueck->set_border('shade');
$m3_hbox1->put($m3_zurueck);
$m3_hbox1->rel_move_curs(new_x=>18);
$m3_hbox1->put($m3_weiter);

$m3_label1 = Paw::Label->new(text=>'Your own Fax : ');
$m3_vbox0->put($m3_label1);

$m3_entry1 = Paw::Text_entry->new(width=>18,color=>2, callback=>\&m3_last_entry_cb);
$m3_vbox1->put($m3_entry1);

$m3_hbox0->put($m3_vbox0);
$m3_hbox0->put($m3_vbox1);
$m3_hbox0->set_border('shade');

$m3_vbox2->put($m3_hbox0);
$m3_vbox2->rel_move_curs(new_y=>3);
$m3_vbox2->put($m3_hbox1);

$mask3_win->abs_move_curs(new_x=>5, new_y=>2);
$mask3_win->put($m3_vbox2);

#################################################
# reenter Password - Widgets
#################################################
$reenter_text = Paw::Label->new(text=>'Please reenter the password');
$reenter_entry0 = Paw::Text_entry->new(name=>'reenter_entry', width=>18,color=>2, echo=>1);
$reenter_entry0->set_border();
$reenter_zurueck=Paw::Button->new(text=>'Cancel', callback=>\&reenter_zurueck_cb);
$reenter_zurueck->set_border('shade');
$reenter_weiter=Paw::Button->new(text=>'Ok', callback=>\&reenter_ok_cb);
$reenter_weiter->set_border('shade');

$reenter_win->put_dir('v');
$reenter_win->abs_move_curs(new_y=>3, new_x=>6);
$reenter_win->put($reenter_text);
$reenter_win->rel_move_curs(new_y=>1, new_x=>7);
$reenter_win->put($reenter_entry0);

$reenter_win->rel_move_curs(new_x=>-5);
$reenter_win->put($reenter_weiter);
$reenter_win->put_dir('h');
$reenter_win->rel_move_curs(new_x=>7);
$reenter_win->put($reenter_zurueck);


$mask1_win->raise();

#################################################
# callback routines
#################################################
#
# Maske 1
#
sub mask1_cb {
    $mask1_win->raise();

    return;
}

# when you are leaving the Window with the 'Ok' button,
# all text-entrys will be read out and the stored in global
# variables
sub m1_weiter_cb {
    $provider_nr      = $m1_entry1->get_text();
    $msn              = $m1_entry2->get_text();;
    $account_sync_ppp = $m1_entry3->get_text();;
    $passwort         = $m1_entry4->get_text();;
    $eigene_ip        = $m1_entry5->get_text();;
    $ip_p2p           = $m1_entry6->get_text();;
    $ip_dns           = $m1_entry7->get_text();;

    $mask1_win->close_win();
    $mask2_win->raise();
}

sub m1_abbrechen_cb {
    $mask1_win->close_win();
}

sub m1_last_entry_cb {
    my $this = shift;
    my $key = shift;
    if ( $key eq "\t" or $key eq "\n" or $key eq KEY_DOWN ) {
        $mask1_win->set_focus('m1_weiter');
    }
    return $key;
}


#
# Maske 2
#
sub mask2_cb {
    $mask2_win->raise();

    return;
}

# when you are leaving the Window with the 'Ok' button,
# all text-entrys will be read out and the stored in global
# variables
sub m2_weiter_cb {
    $ip_intern      = $m2_entry1->get_text();;
    $netmask_intern = $m2_entry2->get_text();;
    $hostname       = $m2_entry3->get_text();;
    $domain         = $m2_entry4->get_text();;
    $mask2_win->close_win();
    $mask3_win->raise();
}

sub m2_zurueck_cb {
    $mask2_win->close_win();
    $mask1_win->raise();
}

sub m2_last_entry_cb {
    my $this = shift;
    my $key = shift;
    if ( $key eq "\t" or $key eq "\n" or $key eq KEY_DOWN ) {
        $mask2_win->set_focus('m2_weiter');
    }
    return $key;
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
sub m3_weiter_cb {
    $fax_nr = $m2_entry1->get_text();;
    $mask3_win->close_win();
}

sub m3_zurueck_cb {
    $mask3_win->close_win();
    $mask2_win->raise();
}
sub m3_last_entry_cb {
    my $this = shift;
    my $key = shift;
    if ( $key eq "\t" or $key eq "\n" or $key eq KEY_DOWN ) {
        $mask3_win->set_focus('m3_weiter');
    }
    return $key;
}

#
# reenter Maske
#

#
# callback for the reenter passwod text entry.
#
sub reenter_ok_cb {
    my $re_password=$reenter_entry0->get_text(); #read the reentered password
    $passwort = $m1_entry4->get_text();          #read the old password
    if ( $re_password eq $passwort ) {           #are they equal ?
        $reenter_win->close_win();               #yes, they are equal.
        $passwort_is_okay=1;                     #password is okay.
        return;
    }                    
    else {                                       #damn, passwords are not equal
        my @buttons = ( "Ok" );
        my $text = "The reentered password is not equal to your first entered password.\nPlease reenter password.";
        my $pop = Paw::Popup->new( width=>35, height=>10, buttons=>\@buttons, text=>\$text );
        $pop->draw();
        $reenter_win->set_focus('reenter_entry');
        $reenter_entry0->set_text('');
        $passwort_is_okay=0;
        return;
    }
}

sub reenter_zurueck_cb {
    $m1_entry4->set_text('');
    $passwort = $m1_entry4->get_text();
    $reenter_win->close_win();
}

#
# callback for the password text entry
#
sub reenter_password_cb {
    my $this = shift;
    my $key  = shift;

    my $re_password=$reenter_entry0->get_text(); #read the reentered password.
    $passwort = $m1_entry4->get_text();;         #read the old password
    # passwod is no longer "okay" if it hs changed.
    $passwort_is_okay=0 if ( not $re_password eq $passwort );
    # if you are leaving the password entry and the password is not okay
    # a reenter popup appears.
    if ( not $passwort_is_okay and ($key eq KEY_DOWN or $key eq KEY_UP or $key eq "\t" or $key eq "\n" ) ) {
        $reenter_win->raise();
    }
    return $key; # you must do that !
}
