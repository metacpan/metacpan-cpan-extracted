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
# rechservernews.pl    research on waiter of news 
sub rechservernews {
        use Tk;
        use News::Pictures::tr1;
        # Definition of main window 
        $mainr = MainWindow->new();
        menuservernews();
        $framer0 = $mainr->Frame();
        $framer0->pack;
        $framer1 = $framer0->Frame->pack;
        my ($nomserver, $select, $code) = @_;
        accesservernews($nomserver, $select);
        return $forum;
        MainLoop;
}
1;

sub menuservernews {              # Fabrication menu
        
        $menubar = $mainr->Frame;
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
        $mainr->bind('<Control-q>' => [\&fin]);
}

sub accesservernews {
        if ($accesnews ne "OK") {
                use News::Pictures::server;         # focus on zone for seizure
                use Net::NNTP::Client;
                my ($nomserver, $code) = @_;
                $server = Net::NNTP->new($nomserver)
                        or die "Connexion $nomserver impossible\n";
                $#list = -1;
                @group_description = %{$server->newsgroups($select)}
                        or die "On ne peut atteindre newsgroup $select\n";
                for (my $i = 0; $i <= $#group_description; $i = $i + 2) {
                        $listr[$i / 2] = $group_description[$i]; 
                }
                $accesnews = "OK";
        }
        $select = "";
        #$framer2 = $framer1->Frame->pack;
        $framer2 = $framer1->Frame(-width => 150, -height => 100)->pack;
        $framer21 = $framer2->Frame(-width => 150, -height => 20)->pack;
        $entryselect = $framer21->Entry(-width => 40, -font => "Nimbus 15")
                ->pack(-side=>'left');
        $entryselect->focus;                      #focus on zone for seizure
        $framer21->Label(-text => tr1("Selection?"),
                -font => "Nimbus 15")->pack(-side=>'left');
        $entryselect->bind('<Key-Return>', \&selectforum);
        $framer22 = $framer2->Frame(-width => 150, -height => 100)->pack;
        affichservernews($select);
}

sub affichservernews {
        my ($select, $code) = @_;
        my $y = 0;
        $#list = -1;
        # selection 
        for (my $i = 0; $i <=$#listr; $i++) {
                if ($listr[$i] =~ $select) {
                        $list[$y] = $listr[$i];
                        $y++;
                }
        }
        $framer22->destroy;
        $framer22 = $framer2->Frame(-width => 150, -height => 150)->pack;
        $lst = $framer22->Listbox(-width => 30, -height => 15);
        my $scroll = $framer22->Scrollbar(-command => ['yview', $lst]);
        $lst->configure(-yscrollcommand => ['set', $scroll]);
        $lst->pack(-side =>'left', -fill => 'both', -expand => 1);
        $scroll->pack(-side => 'right', -fill => 'y');
        $lst->insert('end', @list);
        $mainr->bind('<Double-1>', \&finr);
}

sub selectforum {
        my $select = $entryselect->get;
        $select =~ s/^\s+//;      # delete spaces beginning and end
        #print "select $select \n";
        affichservernews($select);
}

sub finr {
        use News::Pictures::editnews;
        # index = selection range
        @index = $lst->curselection();
        $forum = $list[$index[0]];
        #print "finr $forum\n";
        $labelnews = "";
        $mainr->destroy;
        $frame2->destroy;
        affichage($forum); 
}