use Irssi;
use Irssi::UI;
use Net::Gadu;
use MIME::Base64;
use vars qw($VERSION $MINNGVER %IRSSI);
use strict;


# irssi_gg.pl <- irssi script which allow connect to Gadu-Gadu protocol inside irssi.
# 
# Copyright (C) 2002-2005 Marcin Krzy¿anowski
# http://krzak.linux.net.pl
# 
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the GNU Lesser General Public License as published by 
# the Free Software Foundation; either version 2 of the License, or 
# (at your option) any later version. 
# 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details. 
# 
# You should have received a copy of the GNU Lesser General Public License 
# along with this program; if not, write to the Free Software 
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 


$VERSION="0.2";
$MINNGVER="0.8";

%IRSSI = (
    authors     => 'Marcin Krzyzanowski',
    name        => 'irssi_gg',
    description => 'Allow to communicate via Gadu-Gadu (www.gadu-gadu.pl) instant messanger in irssi',
    license     => 'Public Domain',
    changed	=> 'Sun Jun 16 20:24:57 2002'
);

Irssi::theme_register([
    'ggerr', '%CGG ZONK: %b$0%n',
    'gginfo','%CGG INFO: %n$0',
    'gghelp','%CGG HELP: $0%n',
    'ggmsg' ,'%B$0 %b[%n$1%b]%n $2%n'
]);

Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"Eksperymentalny modul obslugujacy gadu-gadu (www.gadu-gadu.pl) dla irssi (www.irssi.org)");
Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"Aby zobaczyc dostepne komendy wpisz /help gadu-gadu");

if ($Net::Gadu::VERSION < $MINNGVER) { 
    print_err("Masz za stara wersje Net::Gadu (".$Net::Gadu::VERSION."), wymagana $MINNGVER");
    print_err("Sprawdz http://krzak.linux.net.pl/perl/perlgadu.html");
    }

my $gg = new Net::Gadu(async=>1);
my ($eventloop_tag,$ping_tag,$gg_win);
my ($uin,$password);
my %nicks = ();
my $server;


sub print_err {
    my ($txt) = @_;
    Irssi::printformat(MSGLEVEL_NOTICES,'ggerr',$txt);
}

sub read_config {
    #czytam config z ~/.gg/config
    my $configfile = $ENV{'HOME'}."/.gg/config";
    if (!(-e $configfile)) { 
	print_err("A gdzie masz plik konfiguracyjny ?");
        print_err("Spodziewam sie pliku $configfile o formacie :");
        print_err("uin 11111");
        print_err("password laSGvdtgGA=");
    }

    open(F,"<".$configfile);
    while (my $l=<F>)  {
        my @kv = split(/ /,$l);
        $kv[1] =~ s/\n//g;
        if ($kv[0] eq "uin") {  $uin = $kv[1] }
        if ($kv[0] eq "password") {  $password = MIME::Base64::decode($kv[1]); }
        }
    close(F);
    
    #czytam userow z ~/.gg/userlist
    my $usersfile = $ENV{'HOME'}."/.gg/userlist";
    if (-e $configfile) { 
        open(F,"<".$usersfile);
        while (my $l=<F>)  {
            $l =~ s/\n|\r//g;
            my @uv = split(/;/,$l);
            my $nick = $uv[3];
            if ($nick eq "") { $nick = $uv[2]; }
            if ($nick eq "") { $nick = $uv[0].$uv[1]; }
            if ($nick eq "") { $nick = $uv[6]; }
            $nicks{$uv[6]} = $nick;
            }
        close(F);
    }
}


sub check_session {
    if ((!defined($gg)) || (!defined($gg->{session}))) { return(0); }
    return(1);
}

read_config();
#############################


sub gg_ping {
    if (!check_session()) { return; }
    $gg->ping();
}

sub eventloop {
    my $gu = shift;
#    if (!check_session()) { return; }

    if ($gu->check_event() == 1) {
    
	my $e = $gu->get_event();

	my $type = $e->{type};

	if ($type == $Net::Gadu::EVENT_MSG) {
		$e->{message} =~ s/\r\n//g;
		my $nick = $e->{sender};
		if (exists($nicks{$e->{sender}})) { $nick = $nicks{$e->{sender}} };
		Irssi::printformat(MSGLEVEL_MSGS,'ggmsg',"<-",$nick,$e->{message});
		return;
	}
	    
	if ($type == $Net::Gadu::EVENT_CONN_SUCCESS) {
		Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',"polaczenie udane gratuluje");
    		$ping_tag = Irssi::timeout_add(10000,\&gg_ping,$gg);
    		$gu->notify();
	        $gu->set_available();
		return;
	}

	if ($type == $Net::Gadu::EVENT_DISCONNECT) {
		Irssi::timeout_remove($eventloop_tag);
		Irssi::timeout_remove($ping_tag);
		Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',"nastapilo rozlaczenie");
		return;
	}
	
	if ($type == $Net::Gadu::EVENT_CONN_FAILED) {
		Irssi::timeout_remove($eventloop_tag);
		Irssi::timeout_remove($ping_tag);
		Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',"nastapilo rozlaczenie");
		return;
	}
    }
}


#sub cmd_gglogin {
#    my ($data,$server,$witem) = @_;
#    $gg_win = Irssi::Windowitem::window_create($witem,1);
#    $gg_win->set_active();
#    $gg->login($uin,$password); 
#    $to_tag = Irssi::timeout_add(1000,\&timeout_input,$gg);
#    $ping_tag = Irssi::timeout_add(10000,\&gg_ping,$gg);
#    return;
#} 

Irssi::command_bind('finduin','cmd_finduin','gg');
sub cmd_finduin {
    my ($uin) = @_;
    my $res = $gg->search_uin($uin,1);
    if (@{$res}->[0]->{active} == 1) {
	Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',$uin." jest nie zalogowany");
    } else { 
	Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',$uin." jest zalogowany");
    }
}

Irssi::command_bind('list','cmd_list','gg');
sub cmd_list {
	foreach my $n (keys %nicks) {
    	    my $res = $gg->search_uin($n,1);
	    if (@{$res}->[0]->{active} == 1) {
			Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',$nicks{$n}." $n zalogowany");
		} else {
			Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',$nicks{$n}." $n nie zalogowany");
		}
	}
}

Irssi::command_bind('active','cmd_active','gg');
sub cmd_active {
	foreach my $n (keys %nicks) {
	    my $res = $gg->search_uin($n,1);
	    if (@{$res}->[0]->{active} == 1) {
		Irssi::printformat(MSGLEVEL_NOTICES,'gginfo',$nicks{$n}." $n zalogowany");
		}
	}   
}

Irssi::command_bind('ggmsg','cmd_ggmsg','gg');
sub cmd_ggmsg {
    my ($data,$ser,$witem) = @_;
    if (!check_session()) { return; }
    $server = $ser;
    my $add = "";
    my @d = split(/ /,$data);
    my $uin = $d[0];
    my $msg = substr($data,length($uin)+1);
    my $nick = $uin;
    
    if ($uin =~ m/[0-9]/) { # podany UIN
	if (exists($nicks{$uin})) { $nick = $nicks{$uin} };
    } else { # podany NICK
	if (scalar( grep(/$nick/,%nicks) ) > 0 ) {
	    foreach my $n (keys %nicks) { if ($nicks{$n} =~ m/$nick/) { $uin = $n; $add = " ($uin)";last; } }
	} else {
	    print_err("$nick nie jest na liscie znanych mi osob sprawdz plik ~/.gg/userlist");
	    return;
	}
    }

    Irssi::printformat(MSGLEVEL_MSGS,'ggmsg',"->",$nick.$add,$msg);
#    if (!check_session()) { return; }
    $gg->send_message_chat($uin,$msg);
}


Irssi::command_bind('away','cmd_ggaway','gg');
sub cmd_ggaway {
    my ($data) = @_;
    if (!check_session()) { return; }
    if (($data eq "")) {    $gg->set_available(); }
    if (($data ne "")) {    $gg->set_busy(); }
}

Irssi::command_bind('help','cmd_help','gg');
sub cmd_help {
    my ($data) = @_;
    
    if ($data =~ /gadu\-gadu/i) {
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"Eksperymentalny modul obslugujacy gadu-gadu (www.gadu-gadu.pl) dla irssi (www.irssi.org)");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"Korzysta z modulu Net::Gadu (http://krzak.linux.net.pl/perl/perlgadu.html)");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"Autor : Marcin Krzyzanowski <krzak\@hakore.com>\n");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/connect gadu-gadu - loguje do serwera gadu-gadu, UIN pobiera z HOME/.gg/config");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/away              - ustawia stan na dostepny lub zajety");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/finduin UIN       - sprawdza czy UIN jest zalogowany do serwera gadu-gadu");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/ggmsg UIN MSG     - wysyla MSG do UIN (UIN moze byc liczba lub wpisem z listy w ~/.gg/userlist np. /ggmsg Felek czesc)");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/quit              - wylogowuje rowniez z gadu-gadu");
	Irssi::printformat(MSGLEVEL_NOTICES,'gghelp',"/help gadu-gadu    - pomoc");
	Irssi::signal_stop();
    }
    
}

Irssi::command_bind('connect','cmd_connect','gg');
sub cmd_connect {
    my ($data,$pass) = @_;

    if ($data =~ /gadu\-gadu/i) {
	$gg->login($uin,$password); 
	$eventloop_tag = Irssi::timeout_add(1000,\&eventloop,$gg);
	Irssi::signal_stop();
	}
}


Irssi::command_bind('quit','cmd_quit','gg');
sub cmd_quit {
    if (check_session()) { $gg->logoff(); }
}

Irssi::signal_add('complete word',\&complete_word);
sub complete_word {
    my ($complist,$window,$word,$linestart,$want_space) = @_;
    if ($linestart =~ /ggmsg/) {
	foreach my $n (keys %nicks) { 
	    if ($nicks{$n} =~ m/^$word/i) { 
		push(@{$complist},$nicks{$n}); 
		}
	    }
	}
    if ($linestart =~ /connect/) {
	if ($word =~ m/g/) { push(@{$complist},"gadu-gadu"); }
    }

    if ($linestart =~ /help/) {
	if ($word =~ m/g/) { push(@{$complist},"gadu-gadu"); }
    }
}
