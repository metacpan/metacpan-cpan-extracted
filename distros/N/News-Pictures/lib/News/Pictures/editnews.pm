#* Copyright (C) 2009 Christian Guine
# * This program is free software; you can redistribute it and/or modify it
# * under the terms of the GNU General Public License as published by the Free
# * Software Fondation; either version 2 of the License, or (at your option)
# * any later version.
# * This program is distributed in the hope that it will be useful, but WITHOUT
# * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# * more details.
# * You should have received a copy of the GNU General Public License along with
# * this program; if not, write to the Free Software Foundation, Inc., 59
# * Temple Place - Suite 330, Boston, MA 02111-1307, USA.
# */
# editnews.pm      Edition news photos
sub editnews {
        use Tk;
        use News::Pictures::tr1;
        use News::Pictures::server;
        server();       # Recovery shape
        # Definition of main window 
        $main = MainWindow->new();
        opendir(DIR, "./");
        rewinddir DIR;
        @dir1 = ();
        @dir1 = readdir DIR;
        while (@dir1) {
                if ($dir1[0] eq "photo1") {
                        last;
                }
                shift @dir1;
        }
        if ($dir1[0] ne "photo1") {
                mkdir "photo1", 0777 or die "Ne peut creer repertoire photo1";
        }
        $accesnews = "";
        menu();
        $frame0 = $main->Frame();
        $frame0->pack;
        $frame1 = $frame0->Frame->pack;
        $labelnews = "";
        $nomnews = $news;
        $forum = $nomforum;
        affichage();
        MainLoop;
}
1;

sub menu {              # menu
        
        $menubar = $main->Frame;
        $menubar->pack(
                -fill => 'x');
        # File menu
        my $fichiermenu = $menubar->Menubutton(-text => tr1('Fichier'));
        $fichiermenu->pack(
                '-side' => 'left');

        # Exit         
        $fichiermenu->command(
                -label          => tr1('Quitter'),
                -command        => [\&fin],
                -accelerator    => 'Ctrl+q'
        );
        # Language Menu
        my $languemenu = $menubar->Menubutton(-text => tr1('Langues'));
        $languemenu->pack(
                '-side' => 'left');
        # selection of languages
        $languemenu->radiobutton(-label => tr1('français'),
                -command => [\&changelang,"fr"]);        
        $languemenu->radiobutton(-label => tr1('anglais'),
                -command => [\&changelang,"en"]);   
        $main->bind('<Control-q>' => [\&fin]);
}

sub affichage {         # billing name forum or seizure of forum name
        use News::Pictures::server;
        server();       # Recovery shape
        $frame2 = $frame1->Frame(-width => 150, -height => 700)->pack;
        $frame20 = $frame2->Frame(-width => 150, -height => 10)->pack;
        $frame20->Label(-text => tr1("News") . ": ", -font => "Nimbus 15")->pack(-side => 'left');
        $entrynomnews = $frame20->Entry(-width => 40, -font => "Nimbus 15")
                ->pack(-side=>'left');
        $entrynomnews->insert(0,$nomnews);  # insertion name news
        $frame21 = $frame2->Frame(-width => 150, -height => 10)->pack;
        if ($labelnews ne "") {         # Billing name forum
                $frame21->Label(-text => $labelnews,
                        -width => 70,
                        -font => "Nimbus 15")->pack(-side=>'left');
        } else {                        # Windows grabbed forum name
                $entrynews = $frame21->Entry(-width => 40, -font => "Nimbus 15")
                        ->pack(-side=>'left');
                $entrynews->insert(0,$forum);  # insertion forum name
                $entrynews->focus;                      #focus on zone for seizure
        }
        my $Button212 = $frame21->Button(-text=>tr1('Nouveau forum'), -command => [\&nouveauforum])
                ->pack(-side=>'left');
        #billing of the caracteristiques of the forum
        $frame23 = $frame2->Frame(-width => 150, -height => 200)->pack;
        $frame231 = $frame23->Frame(-width => 150, -height => 10)->pack;
        $frame231->Button(-text => tr1("OK"), -command => [\&trait],
                -height => 5,
                -font => "Nimbus 15")->pack(-side => 'left');
        $main->bind('<Key-Return>', => [\&trait]);
}

sub trait {             # Extract forum name
        if ($labelnews eq "") {
                # forum seizure
                $nomnews = $entrynomnews->get;
                $nomnews =~ s/^\s+//;      # delete spaces beginning and end
                # saisie news
                $labelnews = $entrynews->get;
                $labelnews =~ s/^\s+//;      # delete spaces beginning and end
                #print "labelnews $labelnews \n";
                $frame2->destroy;
                affichage();
                traitement();
        } else {
                traitement();
        }
}

sub nouveauforum {
        # new forum seizure
        use News::Pictures::rechservernews;
        use News::Pictures::server;
        server();
        # forum seizure
        $nomnews = $entrynomnews->get;
        $nomnews =~ s/^\s+//;      # delete spaces beginning and end
        $frame23 = $frame2->Frame(-width => 150, -height => 100)->pack;
        $frame23->Label(-text => tr1("Un instant SVP"),
                -font => "Nimbus 15")->pack;
        $main->update;
        $forum = rechservernews($nomnews);
        $labelnews = "";
        #print "forum = $forum\n";
        $frame2->destroy;
        affichage($forum);           
}

sub traitement {
        # accès news
        use Net::NNTP::Client;
        use IO::File;
        use News::Pictures::server;
        server();
        # Forum Access
        $client = new Net::NNTP::Client($nomnews,
                'server' => $nomnews, 'port' => 119,
                );
        ($nb_articles, $premier, $dernier, $nomgroupe) = 
                $client->group($labelnews);
        $frame231->destroy; 
        $frame232 = $frame23->Frame(-width => 100)->pack;
        $frame232->Label(-text => tr1("Nombre d'articles"),
                -font => "Nimbus 15")->pack(-side => 'left');       
        $frame232->Label(-text => $nb_articles,
                -font => "Nimbus 15")->pack(-side => 'left');
        $frame232->Label(-text => tr1("Numéro premier"),
                -font => "Nimbus 15")->pack(-side => 'left');
        $entrypremier = $frame232->Entry(-font => "Nimbus 10", -width => 8)
                ->pack(-side=>'left'); 
        $entrypremier->insert(0,$premier);
        $frame232->Label(-text => tr1("Numéro dernier"),
                -font => "Nimbus 15")->pack(-side => 'left');       
        $entrydernier = $frame232->Entry(-font => "Nimbus 10", -width => 8)
                ->pack(-side=>'left'); 
        $entrydernier->insert(0,$dernier);
        $frame233 = $frame23->Frame(-width => 100, -height => 100)->pack;
        my $Button233 = $frame233->Button(-text=>tr1('Début'), -command => [\&debut])
                ->pack(-side=>'left');
        $frame24 = $frame2->Frame(-width => 100, -height => 100)->pack; # picture preparation
        $frame24->Label(-text => " ",
                -height => 200,
                -font => "Nimbus 15")->pack(-side => 'left');
        $main->bind('<Key-Return>', => [\&debut]);
}

sub debut {
        # we read first message
        $cpt = $premier;
        my $cpt1 = $entrypremier->get;
        $dernier = $entrydernier->get;
        foreach ($premier..$cpt1) {     # we skip the first articles possibly 
                                        # if the number of the first article was changed
                $client->next();
                #print "cpt $cpt\n";
                $cpt++;
        }
        $cpt2 = $cpt;
        suivant();
}

sub suivant {
        # we read next message with image
        use Convert::UU qw(uudecode uuencode);
        $cpt3 = 0;            
        while ($cpt <= $dernier) {              # Treatment articles of the message
                $#art = -1;
                @art = @{$client->article()};   # we put articles in stacks
                #print "cptsuiv $cpt\n";
                # deleting articles till the beginning of picture
                shift @art while @art and $art[0] !~ /^begin (.*\.jpg)/;   
                $type = $1;     # Recovery picture name
                $type =~ m/... (.*)/;
                $fic = $1;      # Recovery of name
                # Deleting article end
                shift @art while @art and $art[0] =~ /^\end/;
                $gif = "";
                $decode = "";
                while (@art) {          # concatenation articles image
                        $gif = $gif . $art[0];
                        shift @art;
                }
                $decode = uudecode($gif);       # decoding UU image
                if ($decode ne "") {
                        affichimage();
                        #print "Content-type: $type\n\n";
                        $cpt++;
                        # reading next article
                        $client->next();
                        # Stop foreach if we find picture
                        last;
                }
                $cpt3++;
                if ($cpt3 > 10) {
                        patiente();
                        $cpt3 = 0;
                        $cpt++;
                        # reading next article
                        $client->next();
                        # Stop foreach
                        last;
                }
                $cpt++;
                $client->next();        # Lecture message suivant
        }
        # Stop if end forum
        if ($cpt > $dernier) {
                affichimage();
        }
}

sub affichimage {
        # billing picture
        use IO::File;
        $G = new IO::File;
        #use Tk::Photo;
        use Tk::JPEG;
        use Tk;
        # stocking temporary picture
        $G->open(">photo1/tmp.jpg") or die "Probleme à  l'ouverture de $type !";
        $G->print($decode);
        $G->close;
        # Billing picture
        $frame24->destroy;
        $frame233->destroy;
        # Billing next button and save
        $frame233 = $frame23->Frame(-width => 100, -height => 100)->pack;
        if ($cpt <= $dernier) {
                my $label2331 = $frame233->Label(-text => ("Article : " . $cpt . "                             "),
                        -font => "Nimbus 5")->pack(-side=>'left');
                my $Button2331 = $frame233->Button(-text=>tr1('Suivant'), -command => [\&suivant])
                        ->pack(-side=>'left');
                my $Button2332 = $frame233->Button(-text=>tr1('Sauvegarde'), -command => [\&sauvegarde])
                        ->pack(-side=>'left');
        }
        $frame24 = $frame2->Frame(-width => 200, -height => 500)->pack;
        if ($cpt > $dernier) {
                $frame24->Label(-text => tr1("Terminé"),
                        -font => "Nimbus 30")->pack;
        } else {
                # Billing picture
                my $photo = $frame24->Photo(-format => 'jpeg',
                        -file => 'photo1/tmp.jpg');
                my $recalphoto = $frame24->Photo;
                $photo->update;
                my $recalheight = $photo->height;
                my $recalwidth = $photo->width;
                print ("largeur " . $recalwidth . " hauteur " . $recalheight . "\n");
                # calibration of image
                my $coefx = int($recalwidth / 500);
                my $coefy = int($recalheight / 300);
                if ($coefx < $coefy) {
                        $coef = $coefx + 1;
                } else {
                        $coef = $coefy + 1;
                }
                $recalphoto->copy($photo,
                        -subsample => ($coef,
                                $coef),
                                );
                $frame24->Label(-image => $recalphoto,
                        -borderwidth => 2,
                        -relief => 'sunken',
                        )->pack(-padx => 5, -pady => 5);
                #my $photo = $frame24->Photo(-format => 'jpeg',
                 #           -file   => 'photo1/tmp.jpg');
                #$frame24->Label(-image => $photo)->pack(-padx => 5, -pady => 5);
        }
        #print "suivant\n";
}

sub sauvegarde {
        # Save picture in file
        use IO::File;
        $G = new IO::File;
        $G->open(">photo1/$fic") or die "Probleme à  l'ouverture de $type !";
        $G->print($decode);
        $G->close;
        suivant();
}

sub fin {
        # Stop 
        $main->destroy;
}

sub patiente {
        # Billing number of article for waiting
        #print "patiente\n";
        $frame24->destroy;
        $frame233->destroy;
        # Billing next buttons and save
        $frame233 = $frame23->Frame(-width => 100, -height => 100)->pack;
        $frame233->Label(-text => tr1("Article traité"),
                        -font => "Nimbus 15")->pack(-side => 'left');
        $frame233->Label(-text => $cpt,
                        -font => "Nimbus 15")->pack(-side => 'left');
        $frame24 = $frame2->Frame(-width => 200, -height => 500)->pack;
        $frame24->Label(-text => " ",
                -height => 200,
                -font => "Nimbus 15")->pack(-side => 'left');
        $main->bind('<Key-Return>', => [\&suivant]); # Specification of event 
        $main->update;                  #we force billing
        $main->eventGenerate('<Key-Return>');  #we generate event to pass to next phase
}