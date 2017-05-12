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
# file of configuration tr1.pm
sub tr1 {
        use IO::File;
        if ($langue eq "") {
                # reading language in file conf.txt
                $filehandle = new IO::File; 
                my $retour = $filehandle->open("< conf.txt");
                if ($retour != 1) {
                        $langue = "en";
                        $filesortie = new IO::File;
                        $filesortie->open("> conf.txt") or die "impossible ouvrir conf";
                        $filesortie->write($langue, 2);
                        $filesortie->close; 
                }
                $filehandle->open("< conf.txt") or die "impossible d'ouvrir fichier conf"; 
                $filehandle->read($langue,2);
                $filehandle->close;        
        }
        #print $langue . "\n";
        my ($nomfr) = @_;
        if ($langue ne "fr") {
                $nomtr = traduction($langue,$nomfr);
        } else {
                $nomtr = $nomfr;
        } 
        #print $langue . " " . $nomfr . " " . $nomtr . "\n";
        return $nomtr;
}
1;

sub changelang {               # modification language in file conf.txt
        use IO::File; 
        ($langue) = @_;
        $filesortie = new IO::File;
        $filesortie->open("> conf.txt") or die "impossible ouvrir conf";
        $filesortie->write($langue, 2);
        $filesortie->close;
        $main->destroy;
        $main = MainWindow->new();
        menu();
        $frame0 = $main->Frame(-width => 500, -height => 200);
        $frame0->pack;
        $frame1 = $frame0->Frame->pack;
        $frame2 = $frame1->Frame->pack(-side=>'left');
        affichage();
        MainLoop;
}

sub traduction {                # translation
       @tab =  ("en", "Nouveau forum", "New forum",
                "en", "Nombre d'articles", "Number of articles",
                "en", "Numéro premier", "First number",
                "en", "Numéro dernier", "Last number",
                "en", "français", "french",
                "en", "anglais", "english", 
                "en", "Suivant", "Next",
                "en", "Sauvegarde", "Save",
                "en", "Terminé", "The end",
                "en", "Fichier", "File",
                "en", "Langues", "Languages",
                "en", "Quitter", "Exit",
                "en", "Un instant SVP", "One moment please",
                "en", "Article traité", "Treated article",
                "en", "Sélection?", "Selection?",
                "en", "Début", "Beginning"
       );
        my ($langue,$nomfr) = @_;
        $nomtr = $nomfr;
        for (my $it = 0; $it <= $#tab; $it = $it + 3) {
                if ($tab[$it] eq $langue and $tab[$it + 1] eq $nomfr) {
                        $nomtr = $tab[$it + 2];
                        last;
                }
        }
        #print $nomtr . "\n";
        return($nomtr);
} 